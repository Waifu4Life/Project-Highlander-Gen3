-- EXTRA TYPES (MECHANICS > EXTRA TYPES), all five Gen 3 games.
--
--   FAIRY TYPE MOVES  Charm, Moonlight and Sweet Kiss become Fairy, and seven
--                     Fairy TMs (TM51-57) are handed out by an extra Nurse Joy
--                     in seven Pokémon Centers. Off: those moves are Normal,
--                     the Joys are gone; TMs already received stay and teach.
--   FAIRY TYPE PKMN   Clefairy, Jigglypuff, Mr. Mime, Togepi, Marill, Ralts,
--                     Azurill, Mawile and their families get their Gen 6
--                     Fairy typing. Off: the game's own typing.
--
-- The FAIRY type itself (index 23, special, Gen 6 matchups) is always in the
-- type chart; nothing uses it while both settings are off. Every change is
-- live: the next battle, screen or map uses the new settings.
return function(ctx, D)
  local S = ctx.settings
  local X = { installed = false, D = D }

  local function warn(what, err)
    if ctx.mod.log then pcall(ctx.mod.log.warn, ctx.mod.log, "extra types %s: %s", what, tostring(err)) end
  end
  local function req(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
  end
  local function on(key) return S.get(key) == true end
  function X.movesOn() return on("fairy_moves") end
  function X.pkmnOn() return on("fairy_pkmn") end

  local FAIRY = D.FAIRY
  local MOVE_OF_TM, ITEM_OF_TM, TM_OF_ITEM, MOVE_BY_NUM = {}, {}, {}, {}
  for _, m in ipairs(D.MOVES) do
    m.num = D.MOVE_BASE + (m.tm - 50)
    m.item = D.ITEM_BASE + (m.tm - 50)
    MOVE_OF_TM[m.tm], ITEM_OF_TM[m.tm], TM_OF_ITEM[m.item] = m, m.item, m.tm
    MOVE_BY_NUM[m.num] = m
  end
  X.MOVE_BY_NUM = MOVE_BY_NUM

  -- the TMs, in number order: { number, item, move }
  function X.tmList()
    local out = {}
    for _, m in ipairs(D.MOVES) do out[#out + 1] = { number = m.tm, item = m.item, move = m.num } end
    return out
  end

  local function ourItem(id)
    local num = tonumber(id)
    if not num and id ~= nil then
      local ItemsData = req("src.core.game3.items_data")
      local s = tostring(id):upper()
      local n = tonumber(s:match("^TM_?(%d+)$") or "")
      if n and ITEM_OF_TM[n] then return n end
      if ItemsData and ItemsData._byName then num = ItemsData._byName[s] end
    end
    return num and TM_OF_ITEM[num] or nil
  end
  X.tmOfItem = ourItem

  -- ================================================================ the type

  local TYPE_NUM = {
    NORMAL = 0, FIGHTING = 1, FLYING = 2, POISON = 3, GROUND = 4, ROCK = 5, BUG = 6,
    GHOST = 7, STEEL = 8, FIRE = 10, WATER = 11, GRASS = 12, ELECTRIC = 13,
    PSYCHIC = 14, ICE = 15, DRAGON = 16, DARK = 17, FAIRY = FAIRY,
  }

  local typesState = { ours = nil, base = nil, busy = false }
  local origUse, origClear

  -- Adds the Fairy rows to whatever chart is in use (the game's, or another
  -- mod's), keeping Foresight's rows after the -1 marker.
  local function extendTypes()
    local Types = req("src.core.game3.battle.types")
    if not (Types and origUse) or typesState.busy then return end
    local base = Types.TABLE
    if base == typesState.ours then base = typesState.base end
    local ours = {}
    local function add(a, d, m) ours[#ours + 1] = a; ours[#ours + 1] = d; ours[#ours + 1] = m end
    local have = {}
    local i, marker = 1, nil
    while i <= #base do
      local a, d, m = base[i], base[i + 1], base[i + 2]
      if a == -1 then marker = i break end
      add(a, d, m)
      have[a .. ">" .. d] = true
      i = i + 3
    end
    for _, r in ipairs(D.FAIRY_ROWS) do
      local a, d = TYPE_NUM[r[1]], TYPE_NUM[r[2]]
      if not have[a .. ">" .. d] then add(a, d, r[3]) end
    end
    add(-1, -1, 0)
    if marker then
      for j = marker + 3, #base, 3 do add(base[j], base[j + 1], base[j + 2]) end
    end
    local physical = {}
    for k, v in pairs(Types.PHYSICAL or {}) do physical[k] = v end
    physical[FAIRY] = nil
    local names = {}
    local Progression = req("src.core.game3.progression")
    if Progression and Progression.typeNameFor then
      for n = 0, 255 do
        local okN, nm = pcall(Progression.typeNameFor, n)
        if okN and nm then names[n] = nm end
      end
    end
    names[FAIRY] = "FAIRY"
    typesState.busy = true
    local ok, err = pcall(origUse, { table = ours, physical = physical, names = names })
    typesState.busy = false
    if not ok then warn("type chart", err) return end
    typesState.ours, typesState.base = ours, base
  end

  local function installTypes()
    local Types = require("src.core.game3.battle.types")
    if Types._phExtraTypes then return end
    Types._phExtraTypes = true
    Types.ID.FAIRY = FAIRY
    origUse, origClear = Types.useOverlay, Types.clearOverlay
    -- another overlay (a mod's type chart) or going back to the game's: the
    -- Fairy rows go on top again
    Types.useOverlay = function(overlay, ...)
      local r = { origUse(overlay, ...) }
      if not typesState.busy then pcall(extendTypes) end
      return (table.unpack or unpack)(r)
    end
    Types.clearOverlay = function(...)
      local r = { origClear(...) }
      if not typesState.busy then pcall(extendTypes) end
      return (table.unpack or unpack)(r)
    end
    extendTypes()
    -- colour keys for COLORED MOVE NAMES and the Pokédex badges
    if ctx.typeColors and ctx.typeColors.BY_ID then ctx.typeColors.BY_ID[FAIRY] = "FAIRY" end
  end

  -- ================================================================ moves

  local function moveRow(m)
    return {
      effect = m.effect, power = m.power, type = X.movesOn() and FAIRY or 0,
      accuracy = m.accuracy, pp = m.pp, secondaryChance = m.chance,
      target = m.target, priority = m.priority or 0, flags = m.flags,
    }
  end

  local oldTypes = {} -- [move num] = the game's own type

  -- writes the move rows into one table of rows (the battle's and the
  -- Pokémon module's are two different tables)
  local function writeRows(rows)
    if type(rows) ~= "table" then return end
    for _, m in ipairs(D.MOVES) do
      local row = rows[m.num]
      if type(row) ~= "table" then
        rows[m.num] = moveRow(m)
      else
        row.type = X.movesOn() and FAIRY or 0
      end
    end
    for _, num in ipairs(D.OLD_FAIRY_MOVES) do
      local row = rows[num]
      if type(row) == "table" then
        if oldTypes[num] == nil and row.type ~= FAIRY then oldTypes[num] = row.type end
        row.type = X.movesOn() and FAIRY or (oldTypes[num] or 0)
      end
    end
  end

  local function writeNames()
    local Pokemon = req("src.core.game3.pokemon")
    if Pokemon then
      for _, m in ipairs(D.MOVES) do
        if type(Pokemon._moveNames) == "table" then Pokemon._moveNames[m.num] = m.name end
        if type(Pokemon._romMoveNames) == "table" then Pokemon._romMoveNames[m.num] = m.name end
      end
    end
    local Moves = req("src.core.game3.battle.moves")
    if Moves and Moves.BY_NUM then
      if not Moves._numByName and Moves.numForName then pcall(Moves.numForName, "POUND") end
      for _, m in ipairs(D.MOVES) do
        Moves.BY_NUM[m.num] = m.id
        if type(Moves._numByName) == "table" then
          Moves._numByName[m.id] = m.num
          Moves._numByName[(m.name:upper():gsub("%s+", "_"):gsub("-", "_"))] = m.num
        end
      end
    end
  end

  function X.applyMoves()
    local Pokemon = req("src.core.game3.pokemon")
    local Moves = req("src.core.game3.battle.moves")
    if Pokemon and Pokemon._battleMoves then writeRows(Pokemon._battleMoves) end
    if Moves and Moves._rom then writeRows(Moves._rom) end
    writeNames()
  end

  local function installMoves()
    local Pokemon = require("src.core.game3.pokemon")
    local Moves = require("src.core.game3.battle.moves")
    -- the tables are rebuilt when a game's data is (re)loaded
    if Pokemon.onReload then Pokemon.onReload(function() pcall(X.applyMoves); pcall(X.applyPkmn) end, "ph3_extra_types") end
    if Moves.onReload then Moves.onReload(function() pcall(X.applyMoves) end, "ph3_extra_types") end
    pcall(Moves.romReady)
    X.applyMoves()

    -- Draining Kiss heals 3/4 of the damage (the game's drain is 1/2)
    local Hit = require("src.core.game3.battle.effects.hit")
    local State = require("src.core.game3.battle.state")
    if not Hit._phExtraTypes then
      Hit._phExtraTypes = true
      local kiss = nil
      local origRun = Hit.run
      Hit.run = function(M, ...)
        local num = M and M.move and tonumber(M.move.numId)
        local m = num and MOVE_BY_NUM[num]
        if not (m and m.drain) then return origRun(M, ...) end
        local before = kiss
        kiss = M
        local r = { pcall(origRun, M, ...) }
        kiss = before
        if not r[1] then error(r[2], 0) end
        return (table.unpack or unpack)(r, 2)
      end
      local origHeal = State.heal
      State.heal = function(battler, amount, ...)
        if kiss and battler == kiss.user and tonumber(kiss.hpDealt) then
          local m = MOVE_BY_NUM[tonumber(kiss.move.numId)]
          local half = math.max(1, math.floor(kiss.hpDealt / 2))
          if m and amount == half then
            amount = math.max(1, math.floor(kiss.hpDealt * m.drain))
          end
          kiss = nil
        end
        return origHeal(battler, amount, ...)
      end
    end

    -- summary / TM descriptions
    local SummaryData = req("src.core.game3.summary_data")
    if SummaryData and not SummaryData._phExtraTypes then
      SummaryData._phExtraTypes = true
      local Strings = req("src.core.Strings")
      local origDesc = SummaryData.moveDescription
      SummaryData.moveDescription = function(moveId, moveName, ...)
        local m = MOVE_BY_NUM[tonumber(moveId) or -1]
        if m then
          if Strings then
            local ok, s = pcall(Strings, m.text)
            if ok and type(s) == "string" then return s end
          end
          return m.text
        end
        return origDesc(moveId, moveName, ...)
      end
    end

    -- animations: borrowed from an older move
    local Anim = req("src.core.game3.battle.anim")
    if Anim and Anim.scriptForMove and not Anim._phExtraTypes then
      Anim._phExtraTypes = true
      local origScript = Anim.scriptForMove
      Anim.scriptForMove = function(moveId, ...)
        local num = tonumber(moveId)
        if not num and type(moveId) == "string" and Moves.numForName then
          local ok, n = pcall(Moves.numForName, moveId)
          num = ok and n or nil
        end
        local m = num and MOVE_BY_NUM[num]
        if m then return origScript(m.animFrom, ...) end
        return origScript(moveId, ...)
      end
    end
  end

  -- ================================================================ TMs

  local LEARN = nil -- [tm] = { [species] = true }
  local function learners()
    if LEARN then return LEARN end
    local Pokemon = req("src.core.game3.pokemon")
    if not (Pokemon and Pokemon.speciesFromNational) then return {} end
    local out = {}
    for tm, list in pairs(D.LEARNERS) do
      local set = {}
      for _, nat in ipairs(list) do
        local ok, sp = pcall(Pokemon.speciesFromNational, nat)
        if ok and tonumber(sp) then set[tonumber(sp)] = true end
      end
      out[tm] = set
    end
    -- species data not loaded yet: try again next time
    if next(out[51] or {}) ~= nil then LEARN = out end
    return out
  end

  function X.canLearn(species, tm)
    local set = learners()[tm]
    return set ~= nil and set[tonumber(species) or -1] == true
  end

  local function writeItems()
    local ItemsData = req("src.core.game3.items_data")
    if not ItemsData then return false end
    pcall(ItemsData.ensureLoaded)
    local byId = ItemsData._byId
    if type(byId) ~= "table" then return false end
    local template = byId[289] or {}
    for _, m in ipairs(D.MOVES) do
      local e = {}
      for k, v in pairs(template) do e[k] = v end
      e.name = ("TM%02d"):format(m.tm)
      e.itemId = m.item
      e.price = 3000
      e.description = m.text
      e.fieldUse = e.fieldUse or "tm"
      e.pocket = e.pocket or "TM_CASE"
      byId[m.item] = e
      if type(ItemsData._byName) == "table" then
        for _, k in ipairs({ ("TM%02d"):format(m.tm), ("TM_%02d"):format(m.tm), ("TM%d"):format(m.tm), ("TM_%d"):format(m.tm) }) do
          ItemsData._byName[k] = m.item
        end
      end
    end
    return true
  end

  local function installItems()
    local ItemsData = require("src.core.game3.items_data")
    local Pokemon = require("src.core.game3.pokemon")
    if ItemsData._phExtraTypes then return end
    ItemsData._phExtraTypes = true
    -- the pack is reloaded when the game changes: the TMs go back in
    local origInstallPack = ItemsData.installPack
    ItemsData.installPack = function(pack, ...)
      local r = { origInstallPack(pack, ...) }
      pcall(writeItems)
      return (table.unpack or unpack)(r)
    end
    local origIsTm = ItemsData.isTm
    ItemsData.isTm = function(id, ...)
      if ourItem(id) then return true end
      return origIsTm(id, ...)
    end
    local origTmNumber = ItemsData.tmNumber
    ItemsData.tmNumber = function(id, ...)
      local tm = ourItem(id)
      if tm then return tm end
      return origTmNumber(id, ...)
    end
    local origMoveFrom = Pokemon.moveFromTmItem
    Pokemon.moveFromTmItem = function(itemId, ...)
      local tm = ourItem(itemId)
      if tm then return MOVE_OF_TM[tm].num end
      return origMoveFrom(itemId, ...)
    end
    local origCanLearn = Pokemon.canLearnTmItem
    Pokemon.canLearnTmItem = function(species, itemId, ...)
      local tm = ourItem(itemId)
      if tm then return X.canLearn(species, tm) end
      return origCanLearn(species, itemId, ...)
    end
    writeItems()
  end

  -- ================================================================ typings

  local origTypes = {} -- [species] = { t1, t2 } as the game has it

  function X.applyPkmn()
    local Pokemon = req("src.core.game3.pokemon")
    if not (Pokemon and type(Pokemon._types) == "table") then return end
    local onNow = X.pkmnOn()
    for nat, typing in pairs(D.FAIRY_PKMN) do
      local okS, sp = pcall(Pokemon.speciesFromNational, nat)
      sp = okS and tonumber(sp) or nil
      local cur = sp and Pokemon._types[sp]
      if cur then
        if origTypes[sp] == nil and not (cur[1] == FAIRY or cur[2] == FAIRY) then
          origTypes[sp] = { cur[1], cur[2] }
        end
        local want
        if onNow then
          local a = TYPE_NUM[typing[1]] or 0
          local b = TYPE_NUM[typing[2] or typing[1]] or a
          want = { a, b }
        else
          local o = origTypes[sp]
          want = o and { o[1], o[2] } or { cur[1], cur[2] }
        end
        if cur[1] ~= want[1] or cur[2] ~= want[2] then Pokemon._types[sp] = want end
      end
    end
  end

  -- ================================================================ type pictures

  local fairySheets = setmetatable({}, { __mode = "k" })
  -- Ruby/Sapphire/Emerald summary: the move type sheet gets a FAIRY frame
  -- at index 23 (right after the five contest categories)
  local function sheetWithFairy(img)
    if fairySheets[img] ~= nil then return fairySheets[img] or img end
    fairySheets[img] = false
    local ok, canvas = pcall(function()
      local w, h = img:getDimensions()
      local fh = 16
      local c = love.graphics.newCanvas(w, math.max(h, (FAIRY + 1) * fh))
      c:setFilter("nearest", "nearest")
      love.graphics.push("all")
      love.graphics.setCanvas(c)
      love.graphics.origin()
      love.graphics.setScissor()
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, 0, 0)
      ctx.typeColors.drawBadge("FAIRY", 0, FAIRY * fh + 2)
      love.graphics.pop()
      return c
    end)
    if ok and canvas then fairySheets[img] = canvas return canvas end
    warn("fairy icon", canvas)
    return img
  end

  local function isFairy(t)
    return tonumber(t) == FAIRY or (type(t) == "string" and t:upper() == "FAIRY")
  end

  local function installPictures()
    -- FireRed/LeafGreen summary, TM Case, move relearner
    local SummaryChrome = req("src.ui.game3.summary_chrome")
    if SummaryChrome and SummaryChrome.drawTypeBadge and not SummaryChrome._phExtraTypes then
      SummaryChrome._phExtraTypes = true
      local orig = SummaryChrome.drawTypeBadge
      SummaryChrome.drawTypeBadge = function(t, x, y, ...)
        if isFairy(t) then ctx.typeColors.drawBadge("FAIRY", x, y) return end
        return orig(t, x, y, ...)
      end
    end
    local PokedexChrome = req("src.ui.game3.pokedex_chrome")
    if PokedexChrome and PokedexChrome.drawTypeBadge and not PokedexChrome._phExtraTypes then
      PokedexChrome._phExtraTypes = true
      local orig = PokedexChrome.drawTypeBadge
      PokedexChrome.drawTypeBadge = function(t, x, y, ...)
        if isFairy(t) then ctx.typeColors.drawBadge("FAIRY", x, y) return end
        return orig(t, x, y, ...)
      end
    end
    -- FireRed/LeafGreen TM Case disc: pink like the Psychic one
    local TmCaseChrome = req("src.ui.game3.tm_case_chrome")
    if TmCaseChrome and TmCaseChrome.drawDisc and not TmCaseChrome._phExtraTypes then
      TmCaseChrome._phExtraTypes = true
      local orig = TmCaseChrome.drawDisc
      TmCaseChrome.drawDisc = function(t, ...)
        if tonumber(t) == FAIRY then t = TYPE_NUM.PSYCHIC end
        return orig(t, ...)
      end
    end
    -- Ruby/Sapphire/Emerald summary sheet
    local Kit = req("src.ui.game3.rse.scene_kit")
    if Kit and Kit.image and not Kit._phExtraTypes then
      Kit._phExtraTypes = true
      local orig = Kit.image
      Kit.image = function(path, ...)
        local img = orig(path, ...)
        if img and type(path) == "string" and path:find("summary/move_types%.png$") then
          return sheetWithFairy(img)
        end
        return img
      end
    end
    -- Ruby/Sapphire/Emerald bag: FAIRY badge, and the TM icon of TM04 (pink)
    local BagChrome = req("src.ui.game3.rse.bag_chrome")
    if BagChrome and not BagChrome._phExtraTypes then
      BagChrome._phExtraTypes = true
      if BagChrome.drawMenuInfoIcon then
        local orig = BagChrome.drawMenuInfoIcon
        BagChrome.drawMenuInfoIcon = function(iconId, x, y, ...)
          if tonumber(iconId) == FAIRY then ctx.typeColors.drawBadge("FAIRY", x, y) return true end
          return orig(iconId, x, y, ...)
        end
      end
      if BagChrome.drawItemIcon then
        local orig = BagChrome.drawItemIcon
        BagChrome.drawItemIcon = function(index, ...)
          if TM_OF_ITEM[tonumber(index) or -1] then index = 292 end
          return orig(index, ...)
        end
      end
    end
  end

  -- ================================================================ Nurse Joy

  local function session()
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.getSession then
      local ok, s = pcall(Runtime.getSession)
      if ok and type(s) == "table" then return s end
    end
  end
  local function mapId()
    local sess = session()
    local m = sess and sess.map
    if not m then
      local Map = req("src.core.game3.map")
      m = Map and Map.current
    end
    return tostring(m or ""):upper()
  end
  local function flat(s) return (tostring(s or ""):upper():gsub("[^%w]", "")) end

  local function gotSet()
    local ok, v = pcall(function() return ctx.mod.save:get("ph3x_tms_got") end)
    return (ok and type(v) == "table") and v or {}
  end
  function X.received(tm) return gotSet()[tostring(tm)] == true end
  local function markReceived(tm)
    local t = {}
    for k, v in pairs(gotSet()) do t[k] = v end
    t[tostring(tm)] = true
    pcall(function() ctx.mod.save:set("ph3x_tms_got", t) end)
  end

  -- the Joy for this map, or nil: { tm, x, y }
  function X.nurseHere(map)
    local list = S.isHoenn(session()) and D.NURSES.hoenn or D.NURSES.kanto
    local m = flat(map or mapId())
    for _, n in ipairs(list) do
      if m == n.map or m:sub(-#n.map) == n.map and #m - #n.map <= 4 then
        return { tm = n.tm, x = n.x or list.x, y = n.y or list.y }
      end
    end
  end

  local function objects() return req("src.core.game3.objects") end
  local function mapLoaded()
    local O = objects()
    return O and tostring(O._mapId or ""):upper() == mapId()
  end

  local MAX_W = 208
  local function wrap(text)
    local FrlgFont = req("src.ui.game3.frlg_font")
    local function width(s)
      if FrlgFont and FrlgFont.measure then
        local ok, w = pcall(FrlgFont.measure, s)
        if ok and tonumber(w) then return tonumber(w) end
      end
      return #s * 6
    end
    local pages = {}
    for para in (text .. "\f"):gmatch("(.-)\f") do
      local lines, line = {}, ""
      for word in para:gmatch("%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if line ~= "" and width(try) > MAX_W then
          lines[#lines + 1] = line
          line = word
        else
          line = try
        end
      end
      if line ~= "" then lines[#lines + 1] = line end
      for i = 1, #lines, 2 do
        pages[#pages + 1] = lines[i] .. (lines[i + 1] and ("\n" .. lines[i + 1]) or "")
      end
    end
    return table.concat(pages, "\f")
  end
  local function say(text, cb)
    local Message = req("src.ui.game3.message")
    if not Message then if cb then cb() end return end
    Message.show(wrap(text), { done = cb })
  end
  local function fanfare()
    local Audio = req("src.core.game3.audio")
    if not Audio then return end
    if not pcall(Audio.playFanfare, "MUS_OBTAIN_TMHM") then pcall(Audio.playFanfare, "MUS_OBTAIN_ITEM") end
  end
  local function playerName()
    local sess = session() or {}
    local n = sess.name or sess.playerName
    return (type(n) == "string" and n ~= "") and n or "PLAYER"
  end

  -- "had" | "full" | "given"
  function X.giveTm(tm)
    if X.received(tm) then return "had" end
    local sess, Bag = session(), req("src.core.game3.bag")
    if not (sess and sess.bag and Bag) then return "full" end
    writeItems()
    local ok, v = pcall(Bag.add, sess.bag, ITEM_OF_TM[tm], 1)
    if not ok or v == false then return "full" end
    markReceived(tm)
    return "given"
  end

  local function talkNurse(eo, n)
    local O = objects()
    if O and eo and eo.localId then pcall(O.facePlayer, eo.localId) end
    if X.received(n.tm) then say(D.TEXT.bye) return true end
    say(D.TEXT.gift, function()
      local result = X.giveTm(n.tm)
      if result == "full" then say(D.TEXT.full) return end
      local Pokemon = req("src.core.game3.pokemon")
      local moveName = Pokemon and Pokemon.moveName(MOVE_OF_TM[n.tm].num) or MOVE_OF_TM[n.tm].name
      fanfare()
      say(D.TEXT.got:format(playerName(), ("TM%02d"):format(n.tm), moveName), function()
        say(D.TEXT.bye)
      end)
    end)
    return true
  end

  local function nurseGfx(O)
    for _, d in ipairs(O._defs or {}) do
      if tonumber(d.x) == 7 and tonumber(d.y) == 2 and d.graphicsId then return d.graphicsId, d.elevation end
    end
    local C = req("src.core.game3.constants")
    local okC, c = pcall(function() return C.of(S.version(session())) end)
    local t = okC and c and c.event_objects
    return t and t.byName and t.byName.OBJ_EVENT_GFX_NURSE or nil, 3
  end

  local function spawnNurse(n)
    local O = objects()
    local lid = D.NURSE_LID
    if not O or O._byId[lid] then return end
    local g, elev = nurseGfx(O)
    if not g then return end
    local defs = {}
    for i, d in ipairs(O._defs or {}) do defs[i] = d end
    defs[#defs + 1] = { localId = lid, index = lid, x = n.x, y = n.y, graphicsId = g,
      movementType = 8, elevation = elev or 3, flag = 0, trainerType = 0, phExtraTypes = true }
    O._defs = defs
    local ok, err = pcall(O.addObject, lid)
    if not ok then warn("nurse", err) end
  end

  local function removeNurse()
    local O = objects()
    local eo = O and O._byId and O._byId[D.NURSE_LID]
    if eo and eo.def and eo.def.phExtraTypes then pcall(O.removeObject, D.NURSE_LID) end
  end

  local function fieldReady()
    local Field = req("src.core.game3.field")
    if not (Field and Field.running) or Field.locked then return false end
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.uiBusy and Runtime.uiBusy() then return false end
    local Space = req("src.core.game3.scripting.space")
    if Space and Space.vm and Space.vm.isRunning and Space.vm:isRunning() then return false end
    local P = req("src.core.game3.player")
    if not P or P.moving then return false end
    return true
  end

  function X.tickNurse()
    if not mapLoaded() then return end
    local n = X.nurseHere()
    if n and X.movesOn() then spawnNurse(n) else removeNurse() end
  end

  local DELTA = { up = { 0, -1 }, down = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }
  local function tryTalk()
    if not X.movesOn() then return false end
    local n = X.nurseHere()
    if not n then return false end
    local P, O = req("src.core.game3.player"), objects()
    if not (P and O) then return false end
    local eo = O._byId and O._byId[D.NURSE_LID]
    if not (eo and eo.def and eo.def.phExtraTypes) then return false end
    local facing = P.facing or "down"
    local d = DELTA[facing] or DELTA.down
    local fx, fy = P.cellX + d[1], P.cellY + d[2]
    -- she stands on the floor beside the PC: talk to her face to face
    if not (fx == n.x and fy == n.y) then return false end
    return talkNurse(eo, n)
  end

  local tickAt = 0
  local function installField()
    local Field = require("src.core.game3.field")
    if Field._phExtraTypes then return end
    Field._phExtraTypes = true
    local origInteract = Field.interact
    Field.interact = function(game, ...)
      if fieldReady() then
        local ok, done = pcall(tryTalk)
        if not ok then warn("talk", done) end
        if ok and done then return true end
      end
      return origInteract(game, ...)
    end
    local origUpdate = Field.update
    Field.update = function(...)
      local r = { origUpdate(...) }
      local now = (love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
      if now >= tickAt and Field.running then
        tickAt = now + 0.1
        local ok, err = pcall(X.tickNurse)
        if not ok then warn("nurse tick", err) end
      end
      return (table.unpack or unpack)(r)
    end
  end

  -- ================================================================ settings

  -- Everything at once, after a setting changed or a game was loaded.
  function X.apply()
    pcall(extendTypes)
    local ok1, e1 = pcall(X.applyMoves)
    if not ok1 then warn("moves", e1) end
    local ok2, e2 = pcall(X.applyPkmn)
    if not ok2 then warn("typings", e2) end
    pcall(X.tickNurse)
  end

  local done = {}
  function X.install()
    if X.installed then return end
    local all = true
    for _, s in ipairs({ { "types", installTypes }, { "moves", installMoves }, { "items", installItems },
        { "pictures", installPictures }, { "field", installField } }) do
      if not done[s[1]] then
        local ok, err = pcall(s[2])
        if ok then done[s[1]] = true else all = false warn(s[1], err) end
      end
    end
    pcall(X.applyPkmn)
    X.installed = all
  end

  return X
end
