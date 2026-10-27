-- Shortcuts sub-menu (same as Project Highlander Gen 1/2).
--
-- Ball Shortcuts (BALL SHORTCUTS row, Off by default): in a wild battle's
-- FIGHT / BAG / POKéMON / RUN menu, SELECT + a direction throws the ball set
-- for that direction. Never in the Safari Zone, against trainers, in link,
-- double, Frontier/Pyramid or scripted (Old Man, Wally, Pokédude) battles.
-- A red "PokéBall Shortcuts Active" note shows while it can be used.
--
-- Item Shortcuts (ITEM SHORTCUTS row, On by default): up to three Key Items
-- (ITEM SHORTCUT 1-3, saved per save file) listed in a box when SELECT is
-- pressed in the overworld. With none set, SELECT keeps the game's own
-- registered item. Ruby/Sapphire/Emerald also offer TOWN MAP, which opens
-- the PokéNav map straight away; closing it goes back to the overworld.
-- With PokéMoves > Instant TMs/HMs on, the same box also lists the party's
-- field moves (Sweet Scent, Teleport, Dig, Secret Power, Fly, Flash).
return function(ctx)
  local S = ctx.settings
  local M = { installed = false }

  local function req(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
    return nil
  end

  -- ------------------------------------------------------------- balls

  -- Master Ball (1) and Safari Ball (5) are never offered.
  M.BALLS = {
    { id = 0, label = "NONE" },
    { id = 4, label = "POKé BALL" },
    { id = 3, label = "GREAT BALL" },
    { id = 2, label = "ULTRA BALL" },
    { id = 6, label = "NET BALL" },
    { id = 7, label = "DIVE BALL" },
    { id = 8, label = "NEST BALL" },
    { id = 9, label = "REPEAT BALL" },
    { id = 10, label = "TIMER BALL" },
    { id = 11, label = "LUXURY BALL" },
    { id = 12, label = "PREMIER BALL" },
  }
  local BALL_INDEX = {}
  for i, b in ipairs(M.BALLS) do BALL_INDEX[b.id] = i end

  -- Up, Down, Left, Right (controller order, not alphabetical).
  M.DIRS = {
    { dir = "up", key = "select_up", label = "SELECT W/ UP" },
    { dir = "down", key = "select_down", label = "SELECT W/ DOWN" },
    { dir = "left", key = "select_left", label = "SELECT W/ LEFT" },
    { dir = "right", key = "select_right", label = "SELECT W/ RIGHT" },
  }

  local function ballFor(key)
    local v = tonumber(S.get(key)) or 0
    if not BALL_INDEX[v] then v = 0 end
    return v
  end

  function M.ballLabel(key)
    return M.BALLS[BALL_INDEX[ballFor(key)]].label
  end

  function M.stepBall(key, dir)
    local i = BALL_INDEX[ballFor(key)] or 1
    i = (i - 1 + (dir or 1)) % #M.BALLS + 1
    S.set(key, M.BALLS[i].id)
  end

  local function session()
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.getSession then
      local ok, s = pcall(Runtime.getSession)
      if ok and type(s) == "table" then return s end
    end
    local g = S.game and S.game()
    return g and g.session or nil
  end

  local function owned(sess, id)
    local Bag = req("src.core.game3.bag")
    if not (Bag and sess and sess.bag) then return false end
    local ok, has = pcall(Bag.has, sess.bag, id, 1)
    return ok and has == true
  end

  -- ------------------------------------------------------------- battle

  local Ui

  local function eligible()
    if not S.flag("ball_shortcuts") then return false end
    if not Ui then return false end
    local st = Ui._st
    if type(st) ~= "table" then return false end
    if not st.wild or st.safari or st.link or st.double or st.multi then return false end
    if st.over or st.oldManTutorial or st.pokedude or Ui._wally then return false end
    local Kinds = req("src.core.game3.battle.kinds")
    if Kinds and Kinds.has then
      for _, k in ipairs({ "frontier", "trainerHill", "pokedude", "safari" }) do
        local ok, has = pcall(Kinds.has, st, k)
        if ok and has then return false end
      end
    end
    local sess = Ui._session or session()
    local Pyramid = req("src.core.game3.rse.frontier.pyramid")
    if sess and Pyramid and Pyramid.inPyramid then
      local ok, inside = pcall(Pyramid.inPyramid, sess)
      if ok and inside then return false end
    end
    local Safari = req("src.core.game3.safari")
    if sess and Safari and Safari.isActive then
      local ok, on = pcall(Safari.isActive, sess)
      if ok and on then return false end
    end
    return true
  end
  M.eligible = eligible

  local function comboDir(input)
    if not (input and input.wasPressed and input.isDown) then return nil end
    local selDown, selNew = input:isDown("select"), input:wasPressed("select")
    if not (selDown or selNew) then return nil end
    for _, d in ipairs(M.DIRS) do
      if (selDown and input:wasPressed(d.dir)) or (selNew and input:isDown(d.dir)) then
        return d
      end
    end
    return nil
  end

  local function tryThrow(input)
    if Ui._mode ~= "menu" or not eligible() then return false end
    local d = comboDir(input)
    if not d then return false end
    local id = ballFor(d.key)
    local sess = Ui._session or session()
    if id == 0 or not owned(sess, id) then return false end
    local BagMenu = req("src.ui.game3.bag_menu")
    if BagMenu and BagMenu.partyAndStorageFull then
      local okF, full = pcall(BagMenu.partyAndStorageFull, sess)
      if okF and full then
        local RomText = req("src.ui.game3.rom_text") or req("src.core.game3.rom_text")
        local text = "The BOX is full."
        if RomText and RomText.box then
          local key = (RomText.has and RomText.has("gOtherText_BoxIsFull")) and "gOtherText_BoxIsFull" or "gText_BoxFull"
          local okT, t = pcall(RomText.box, key)
          if okT and t then text = t end
        end
        Ui._selCmd, Ui._selReturn, Ui._mode = nil, "menu", "selmsg"
        Ui.push(text)
        return true
      end
    end
    pcall(function() require("src.core.game3.audio").playSe(5) end)
    -- same command the BAG's USE on a ball hands the battle
    Ui._pendingCommand = { kind = "bag", user = "player", itemId = id }
    Ui._mode = "none"
    return true
  end

  -- red note, top-left above the foe's healthbox
  local NOTE = "PokéBall Shortcuts Active"
  local function drawNote()
    if Ui._mode ~= "menu" or not eligible() then return end
    local FrlgFont = req("src.ui.game3.frlg_font")
    if not (FrlgFont and FrlgFont.draw) then return end
    local opts = { small = true, maxWidth = 236, colors = {
      fg = { 0.86, 0.10, 0.12, 1 }, shadow = { 0.98, 0.72, 0.72, 1 },
      bg = { 1, 1, 1, 0 } } }
    local okW, tw = pcall(FrlgFont.measure, NOTE, opts)
    tw = (okW and tonumber(tw)) or #NOTE * 5
    -- Ruby/Sapphire draw this text with their own, taller font: a taller
    -- box and the text raised so it sits inside it
    local v = S.version()
    local rs = v == "ruby" or v == "sapphire"
    local boxH, textY = 12, -1
    if rs then boxH, textY = 15, -5 end
    love.graphics.push("all")
    love.graphics.setColor(0.22, 0.22, 0.25, 0.85)
    love.graphics.rectangle("fill", 1, 1, tw + 8, boxH)
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.rectangle("fill", 2, 2, tw + 6, boxH - 2)
    FrlgFont.draw(NOTE, 5, textY, opts)
    love.graphics.pop()
  end

  -- ------------------------------------------------------------- key items

  -- normalised names (upper case, letters/digits only, é → E)
  local function norm(name)
    name = tostring(name or ""):gsub("é", "E"):gsub("É", "E"):upper()
    return (name:gsub("[^%w]", ""))
  end

  local ALLOWED = {
    kanto = { "TOWNMAP", "BICYCLE", "ITEMFINDER", "OLDROD", "GOODROD", "SUPERROD",
      "VSSEEKER", "BERRYPOUCH", "TMCASE" },
    hoenn = { "ACROBIKE", "MACHBIKE", "ITEMFINDER", "OLDROD", "GOODROD", "SUPERROD",
      "GOGOGGLES", "DEVONSCOPE", "WAILMERPAIL", "POKEBLOCKCASE" },
  }
  M.NAV_MAP = "POKENAV_MAP"

  local idCache = {}
  local function allowedIds(sess)
    local v = S.version(sess)
    if idCache[v] then return idCache[v] end
    local ItemsData = req("src.core.game3.items_data")
    local want = {}
    for i, n in ipairs(ALLOWED[S.isHoenn(sess) and "hoenn" or "kanto"]) do want[n] = i end
    local list = {}
    if ItemsData and ItemsData.info then
      for n = 255, 380 do
        local ok, info = pcall(ItemsData.info, n)
        local key = ok and info and norm(info.name)
        if key and want[key] and not list[want[key]] then list[want[key]] = n end
      end
    end
    local out = {}
    for i = 1, #ALLOWED[S.isHoenn(sess) and "hoenn" or "kanto"] do
      if list[i] then out[#out + 1] = list[i] end
    end
    if #out > 0 then idCache[v] = out end
    return out
  end

  local function hasPokenav(sess)
    local Flags = req("src.core.game3.scripting.flags")
    local Space = req("src.core.game3.scripting.space")
    local store = Space and Space.store
    if not (store and Flags and Flags.getFlag) then return false end
    local Screens = req("src.ui.game3.screens")
    local okI, T = pcall(function() return Screens.flags(sess) end)
    local id = okI and T and T.IDS and T.IDS["SYS_POKENAV_GET"]
    if id == nil then return false end
    local ok, on = pcall(Flags.getFlag, store, nil, id)
    return ok and on == true
  end

  local function name(id)
    if type(id) == "table" then return id.label end -- Instant TMs/HMs field move
    if id == M.NAV_MAP then return "TOWN MAP" end
    local ItemsData = req("src.core.game3.items_data")
    local ok, n = pcall(ItemsData.displayName, id)
    return (ok and n) and tostring(n):upper() or tostring(id)
  end

  local function usable(sess, id)
    if id == M.NAV_MAP then return S.isHoenn(sess) and hasPokenav(sess) end
    for _, n in ipairs(allowedIds(sess)) do
      if n == id then return owned(sess, id) end
    end
    return false
  end

  -- per save file (mod.save), with a per-game fallback before a save exists
  local function slotKey(slot) return "item_shortcut_" .. slot end
  local function getSlot(sess, slot)
    local ok, v = pcall(function() return ctx.mod.save:get(slotKey(slot)) end)
    if not ok then v = nil end
    if v == nil then v = S.get(slotKey(slot) .. "_" .. S.version(sess)) end
    if v == M.NAV_MAP then return v end
    v = tonumber(v)
    return (v and v > 0) and v or nil
  end
  local function setSlot(sess, slot, v)
    local ok = pcall(function() ctx.mod.save:set(slotKey(slot), v or false) end)
    if not ok then S.set(slotKey(slot) .. "_" .. S.version(sess), v or false) end
  end

  function M.slotLabel(sess, slot)
    sess = sess or session()
    local v = getSlot(sess, slot)
    return v and name(v) or "NONE"
  end

  function M.stepSlot(sess, slot, dir)
    sess = sess or session()
    local choices = { false }
    for _, n in ipairs(allowedIds(sess)) do
      if owned(sess, n) then choices[#choices + 1] = n end
    end
    if S.isHoenn(sess) and hasPokenav(sess) then choices[#choices + 1] = M.NAV_MAP end
    local cur, i = getSlot(sess, slot) or false, 1
    for k, c in ipairs(choices) do if c == cur then i = k break end end
    i = (i - 1 + (dir or 1)) % #choices + 1
    setSlot(sess, slot, choices[i] or nil)
  end

  -- PokéNav straight to its map; leaving the map closes the PokéNav.
  local function openNavMap(sess, game)
    local Screens = req("src.ui.game3.screens")
    local okN, Nav = pcall(function() return Screens.get("pokenav", sess) end)
    if not (okN and Nav and Nav.show) then return end
    local s = Nav.show({ session = sess, game = game })
    if type(s) ~= "table" then return end
    if type(s.openMap) == "function" then
      -- Ruby/Sapphire
      local origSet = s.setMenu
      s.setMenu = function(self, menu, ...)
        if self.__phMapOnly and menu == "main" then
          self.feature = nil
          self.__phMapOnly = nil
          return self:shutdown()
        end
        return origSet(self, menu, ...)
      end
      s.__phMapOnly = true
      s:openMap()
    elseif type(s.setActiveMenu) == "function" then
      -- Emerald
      local origActive = s.setActiveMenu
      local MENU = Nav.MENU or {}
      s.setActiveMenu = function(self, id, ...)
        if not self.__phOpened and id == MENU.MAIN_MENU then
          self.__phOpened = true
          return origActive(self, MENU.REGION_MAP, ...)
        elseif self.__phOpened then
          self:shutdown()
          return true
        end
        return origActive(self, id, ...)
      end
    end
  end

  -- the game's own registered-item SELECT, lent one item for one call
  local nativeSelect
  local function useItem(game, id)
    local sess = game and game.session
    if not sess then return end
    if type(id) == "table" then
      -- PokéMoves > Instant TMs/HMs
      local PM = ctx.pokemoves
      if PM and PM.useMenuMove then
        local ok, err = pcall(PM.useMenuMove, game, id.move)
        if not ok and ctx.mod.log then ctx.mod.log:warn("instant move: %s", tostring(err)) end
      end
      return
    end
    if id == M.NAV_MAP then return openNavMap(sess, game) end
    local real = game.input
    local fake = setmetatable({
      wasPressed = function(_, b) return b == "select" end,
    }, { __index = function(_, k)
      local v = real and real[k]
      if type(v) == "function" then
        return function(_, ...) return v(real, ...) end
      end
      return v
    end })
    local proxy = setmetatable({ input = fake }, { __index = game })
    local saved = sess.registeredItem
    sess.registeredItem = id
    local ok, err = pcall(nativeSelect, proxy)
    sess.registeredItem = saved
    if not ok and ctx.mod.log then ctx.mod.log:warn("item shortcut: %s", tostring(err)) end
  end

  -- same tests the game runs before a registered item may be used
  local function fieldFree(game)
    local sess = game.session
    local Map = req("src.core.game3.map")
    local Union = req("src.core.game3.link.union_room")
    if Map and Union and Union.isUnionMap then
      local ok, u = pcall(Union.isUnionMap, Map.current)
      if ok and u then return false end
    end
    local Link = package.loaded and package.loaded["src.core.game3.link"] or nil
    if type(Link) == "table" and Link.link ~= nil and Link.inLinkRoom and Link.inLinkRoom() == true then return false end
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.uiBusy and Runtime.uiBusy() then return false end
    local Field = req("src.core.game3.field")
    if Field and (Field.locked or (Field.isLocked and Field.isLocked())) then return false end
    local P = req("src.core.game3.player")
    if P and P.boulderPush then return false end
    if S.isHoenn(sess) then
      local Pike = req("src.core.game3.rse.frontier.pike")
      local Pyramid = req("src.core.game3.rse.frontier.pyramid")
      if Pike and Pike.inBattlePike and Pike.inBattlePike(sess) then return false end
      if Pyramid and Pyramid.inPyramid and Pyramid.inPyramid(sess) then return false end
    end
    return true
  end

  local pendingUse, menuOpen = nil, false
  local LOCK = "ph3_item_shortcuts"

  -- ------------------------------------------------------------- themed box
  -- The SELECT box uses the game's own window frame (FireRed/LeafGreen's
  -- red one, Ruby/Sapphire/Emerald's gray one). While this box is the one on
  -- screen, its frame (and Ruby/Sapphire's highlight outline) is recoloured
  -- with the Start Menu theme: the frame keeps its native shape and shading,
  -- dark pixels take the theme's dark, mid ones its main, light ones its
  -- light colour. White (the inside) and the text are left alone. Every
  -- other menu of the game keeps its normal frame.
  local ourLabels = nil
  local themeShader, shaderFailed = nil, false

  local SHADER_SRC = [[
    extern vec3 cDark;
    extern vec3 cMain;
    extern vec3 cLight;
    vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
      vec4 p = Texel(tex, tc) * color;
      if (p.a <= 0.0) return p;
      float mn = min(p.r, min(p.g, p.b));
      if (mn > 0.93) return p;
      float l = dot(p.rgb, vec3(0.299, 0.587, 0.114));
      vec3 c;
      if (l < 0.40) {
        c = mix(cDark, cMain, clamp((l - 0.12) / 0.28, 0.0, 1.0));
      } else if (l < 0.72) {
        c = mix(cMain, cLight, (l - 0.40) / 0.32);
      } else {
        c = mix(cLight, vec3(1.0), clamp((l - 0.72) / 0.21, 0.0, 1.0) * 0.55);
      }
      return vec4(c, p.a);
    }
  ]]

  local function themedNow()
    if not ourLabels then return false end
    -- (package.loaded is empty inside the mod sandbox: require is the way in)
    local Choice = req("src.ui.game3.choice")
    return Choice and Choice.active and Choice.options == ourLabels or false
  end

  local function shader()
    if themeShader or shaderFailed then return themeShader end
    local ok, sh = pcall(love.graphics.newShader, SHADER_SRC)
    if ok and sh then
      themeShader = sh
    else
      shaderFailed = true
      if ctx.mod.log then ctx.mod.log:warn("select box theme shader: %s", tostring(sh)) end
    end
    return themeShader
  end

  local function rgb(c) return { c[1], c[2], c[3] } end

  -- runs fn(...) with the theme recolour on, if this box is open
  local function themed(fn, ...)
    if not themedNow() or not ctx.themes then return fn(...) end
    local sh = shader()
    if not sh then return fn(...) end
    local pal = ctx.themes.resolve(S.themeChoice(), S.version())
    local okS = pcall(function()
      sh:send("cDark", rgb(pal.dark))
      sh:send("cMain", rgb(pal.main))
      sh:send("cLight", rgb(pal.light))
    end)
    if not okS then return fn(...) end
    local prev = love.graphics.getShader()
    love.graphics.setShader(sh)
    local r = { pcall(fn, ...) }
    love.graphics.setShader(prev)
    if not r[1] then error(r[2], 0) end
    return (table.unpack or unpack)(r, 2)
  end

  local function openMenu(game, list)
    local Choice = req("src.ui.game3.choice")
    local Display = req("src.core.game3.display")
    local Field = req("src.core.game3.field")
    if not Choice then return false end
    local labels = {}
    for i, id in ipairs(list) do labels[i] = name(id) end
    labels[#labels + 1] = "CANCEL"
    ourLabels = labels
    menuOpen = true
    if Field and Field.lock then Field.lock(LOCK) end
    pcall(function() require("src.core.game3.audio").playSe(5) end)
    local cols = (Display and tonumber(Display.COLS)) or 30
    -- more than 9 rows don't fit the 160-pixel screen: two columns
    local layout = { left = cols, top = 1, maxRight = cols - 1 }
    if #labels > 9 then layout.cols = 2 end
    Choice.multi(labels, 0, function(idx)
      menuOpen = false
      ourLabels = nil
      if Field and Field.unlock then Field.unlock(LOCK) end
      idx = tonumber(idx)
      if idx and idx >= 0 and idx < #list then pendingUse = list[idx + 1] end
    end, layout)
    return true
  end

  local function handleSelect(game)
    if pendingUse then
      local id = pendingUse
      pendingUse = nil
      useItem(game, id)
      return true
    end
    if menuOpen then
      local Choice = req("src.ui.game3.choice")
      if Choice and Choice.active then return true end
      menuOpen = false
      ourLabels = nil
      local Field = req("src.core.game3.field")
      if Field and Field.unlock then Field.unlock(LOCK) end
    end
    local itemsOn = S.flag("item_shortcuts")
    local movesOn = ctx.pokemoves and ctx.pokemoves.instantOn and ctx.pokemoves.instantOn()
    if not itemsOn and not movesOn then return false end
    local input = game and game.input
    if not (input and input.wasPressed and input:wasPressed("select")) then return false end
    local sess = game.session
    if not sess then return false end
    local list = {}
    if itemsOn then
      for slot = 1, 3 do
        local id = getSlot(sess, slot)
        if id and usable(sess, id) then list[#list + 1] = id end
      end
    end
    -- PokéMoves > Instant TMs/HMs: field moves below the items
    if movesOn and ctx.pokemoves.selectMoves then
      local okM, moves = pcall(ctx.pokemoves.selectMoves, sess)
      if okM and type(moves) == "table" then
        for _, m in ipairs(moves) do list[#list + 1] = m end
      elseif not okM and ctx.mod.log then
        ctx.mod.log:warn("instant moves: %s", tostring(moves))
      end
    end
    if #list == 0 then return false end
    if not fieldFree(game) then return true end
    return openMenu(game, list)
  end

  -- ------------------------------------------------------------- install

  function M.install()
    if M.installed then return end
    Ui = require("src.core.game3.battle.ui")
    local Game3 = require("src.core.Game3")
    M.installed = true

    local origInput = Ui.handleInput
    Ui.handleInput = function(input, ...)
      local okT, thrown = pcall(tryThrow, input)
      if not okT and ctx.mod.log then ctx.mod.log:warn("ball shortcut: %s", tostring(thrown)) end
      return origInput(input, ...)
    end

    local origDraw = Ui.draw
    Ui.draw = function(...)
      local r = { origDraw(...) }
      local ok, err = pcall(drawNote)
      if not ok and ctx.mod.log then ctx.mod.log:warn("ball note: %s", tostring(err)) end
      return (table.unpack or unpack)(r)
    end

    -- themed SELECT box: the frame (all games) and Ruby/Sapphire's highlight
    local okC, Chrome = pcall(require, "src.ui.game3.chrome")
    if okC and type(Chrome) == "table" and Chrome.stdFrame then
      local origFrame = Chrome.stdFrame
      Chrome.stdFrame = function(...) return themed(origFrame, ...) end
    end
    local okR, RsCursor = pcall(require, "src.ui.game3.rs.menu_cursor")
    if okR and type(RsCursor) == "table" and RsCursor.draw then
      local origCursor = RsCursor.draw
      RsCursor.draw = function(...) return themed(origCursor, ...) end
    end

    nativeSelect = Game3._handleRegisteredItem
    Game3._handleRegisteredItem = function(self, ...)
      local ok, handled = pcall(handleSelect, self)
      if not ok and ctx.mod.log then ctx.mod.log:warn("item shortcuts: %s", tostring(handled)) end
      if ok and handled then return end
      return nativeSelect(self, ...)
    end
  end

  return M
end
