-- Pokédex: SELECT on a Pokémon's entry page opens the 2nd screen (STATS /
-- FAMILY / MOVES / LOCATION). START still plays the cry. Always on. Shows for
-- seen and caught Pokémon (the entry page only exists for those).
return function(ctx)
  local P = { installed = false }
  local S = ctx.settings
  local function loadLocal(rel)
    local src = assert(ctx.mod:read(rel))
    return assert(load(src, "@" .. tostring(ctx.mod.path) .. "/" .. rel))()
  end

  local D, Screen

  -- the Pokémon on the entry page, or nil when not on an entry page
  local ENTRY_WORDS = { "data", "entry", "info", "detail", "page" }
  local LIST_WORDS = { "list", "select", "menu", "search", "grid", "registration", "area", "size", "cry" }
  local STATE_KEYS = { "screen", "page", "view", "state", "mode", "subScreen", "subscreen", "phase", "scene" }
  local SPECIES_KEYS = { "_regSpecies", "selectedSpecies", "species", "currentSpecies", "infoSpecies",
    "_species", "dexSpecies", "monSpecies", "speciesId", "selected", "dexNum" }

  local function looksLike(s, words)
    for _, w in ipairs(words) do if s:find(w, 1, true) then return true end end
    return false
  end

  -- Ruby/Sapphire/Emerald: src.ui.game3.rse.pokedex pushes a Host table on the
  -- UI stack; its view (Host._s) is on the entry page when page == INFO and the
  -- info input task is running.
  local okR, RseDex = pcall(require, "src.ui.game3.rse.pokedex")
  if not (okR and type(RseDex) == "table" and type(RseDex.Host) == "table") then RseDex = nil end

  local function rseView(mod)
    return RseDex and mod == RseDex.Host and RseDex.Host._s or nil
  end

  local function entrySpecies(mod)
    if RseDex and mod == RseDex.Host then
      local v = RseDex.Host._s
      if type(v) ~= "table" or v.shown == false then return nil end
      if v.page ~= RseDex.PAGE.INFO or v.fn ~= "infoInput" then return nil end
      local info = v.info
      if type(info) ~= "table" or info.scrolling or not tonumber(info.dexNum) then return nil end
      if v.pal and v.pal.fadeActive and v.pal:fadeActive() then return nil end
      local ok, sp = pcall(RseDex.speciesOf, info.dexNum)
      return (ok and tonumber(sp) and sp > 0) and sp or nil
    end
    -- FireRed/LeafGreen: the entry page is screen "data"
    if mod.screen == "data" then
      local v = tonumber(mod._regSpecies) or tonumber(mod.selectedSpecies)
      return (v and v > 0) and v or nil
    end
    -- other Pokédex screens: any state field naming an entry/info page
    local onEntry = false
    for _, k in ipairs(STATE_KEYS) do
      local v = mod[k]
      if type(v) == "string" then
        local s = v:lower()
        if looksLike(s, ENTRY_WORDS) and not looksLike(s, LIST_WORDS) then onEntry = true break end
      end
    end
    if not onEntry then return nil end
    for _, k in ipairs(SPECIES_KEYS) do
      local v = mod[k]
      if type(v) == "table" then v = v.species or v.id end
      v = tonumber(v)
      if v and v > 0 and v < 1000 then return v end
    end
    for k, v in pairs(mod) do
      if type(k) == "string" and k:lower():find("species") and tonumber(v) then
        local n = tonumber(v)
        if n > 0 and n < 1000 then return n end
      end
    end
    return nil
  end
  P.entrySpecies = entrySpecies

  -- When SELECT does nothing on a Pokédex screen we don't know, write what the
  -- screen holds to ph3_dex_debug.txt (the game's save folder) so it can be fixed.
  local dumped = false
  local function dump(mod, name)
    if dumped then return end
    dumped = true
    pcall(function()
      local lines = { "Project Highlander Gen3 - Pokedex screen: " .. tostring(name) }
      local keys = {}
      for k in pairs(mod) do keys[#keys + 1] = tostring(k) end
      table.sort(keys)
      for _, k in ipairs(keys) do
        local v = mod[k]
        local t = type(v)
        local shown = (t == "string" or t == "number" or t == "boolean") and tostring(v) or t
        lines[#lines + 1] = k .. " = " .. shown
      end
      love.filesystem.write("ph3_dex_debug.txt", table.concat(lines, "\n"))
      if ctx.mod.log then ctx.mod.log:warn("dex: wrote ph3_dex_debug.txt to %s", tostring(love.filesystem.getSaveDirectory())) end
    end)
  end

  local function dexOf(mod)
    local v = rseView(mod)
    if v and type(v.dex) == "table" then return v.dex end
    if type(mod._dex) == "table" then return mod._dex end
    local session = mod._session
    if type(session) == "table" and type(session.dex) == "table" then return session.dex end
    local g = S.game and S.game()
    return g and g.session and g.session.dex or nil
  end

  -- same once-per-frame input pattern as the bag's sort menu, so screens that
  -- read the d-pad outside handleInput (Ruby/Sapphire/Emerald) are covered
  local tickAt = -1
  local function now() return (love.timer and love.timer.getTime()) or 0 end
  local function tick(passed)
    local t = now()
    if t - tickAt < 0.004 then return end
    tickAt = t
    local g = S.game and S.game()
    local input = (g and type(g.input) == "table" and g.input.wasPressed and g.input) or passed
    if input then Screen.input(input) end
  end

  -- "SELECT 2ND SCREEN" hint, drawn exactly like the game's own "START CRY":
  -- the ROM's SELECT button icon and the bar's small white font
  local FrlgFont = require("src.ui.game3.frlg_font")
  local HINT_COLORS = { fg = { 1, 1, 1, 1 }, shadow = { 98 / 255, 98 / 255, 98 / 255, 1 } }
  local LABELS = { "{SELECT_BUTTON}2ND SCREEN", "{SELECT_BUTTON}2ND SCRN", "{SELECT_BUTTON}MORE" }
  -- Ruby/Sapphire have no button icons: the word is printed instead
  local LABELS_RS = { "SELECT 2ND SCREEN", "SELECT 2ND SCRN", "SELECT MORE" }
  local function rsDex()
    local v = S.version()
    return v == "ruby" or v == "sapphire"
  end
  local function labels() return rsDex() and LABELS_RS or LABELS end
  local function measure(t)
    local ok, w = pcall(FrlgFont.measure, t, { small = true })
    return (ok and tonumber(w)) or 60
  end
  -- draws the longest label that fits before maxRight; returns its width
  local function drawHint(x, y, maxRight)
    for _, label in ipairs(labels()) do
      local w = measure(label)
      if not maxRight or x + w <= maxRight then
        FrlgFont.draw(label, x, y, { small = true, colors = HINT_COLORS })
        return w
      end
    end
    return 0
  end
  P.drawHint = drawHint

  local function hook(mod, name)
    if type(mod) ~= "table" or mod._ph3DexHooked then return end
    mod._ph3DexHooked = true

    local function jump(sp)
      local v = rseView(mod)
      if v then
        pcall(function()
          local nat = D.national(sp)
          local List = require("src.ui.game3.rse.pokedex_list")
          for i = 0, (v.list and v.list.count or 0) - 1 do
            local it = List.item(v.list, i)
            if it.dexNum == nat and it.seen then
              v.selected = i
              v.info.scrolling, v.info.monDone, v.info.bgLoaded, v.info.skipCry = true, false, false, false
              break
            end
          end
        end)
        return
      end
      mod.selectedSpecies = sp
      if mod._regSpecies then mod._regSpecies = sp end
      if type(mod.dataPage) == "number" then mod.dataPage = 1 end
      pcall(function()
        local Audio = require("src.core.game3.audio")
        if Audio.playCry then Audio.playCry(sp) end
      end)
    end

    if type(mod.handleInput) == "function" then
      local orig = mod.handleInput
      mod.handleInput = function(input, ...)
        local ok, consumed = pcall(function()
          if Screen.open and Screen.owner == mod then
            if mod.open == false or (RseDex and mod == RseDex.Host and not RseDex.Host._s) then
              Screen.close() return false
            end
            tick(input)
            return true
          end
          if input and input.wasPressed and input:wasPressed("select") then
            local sp = entrySpecies(mod)
            if not sp and name ~= "pokedex" and name ~= "rse_pokedex" then dump(mod, name) end
            if sp then
              Screen.show(sp, dexOf(mod), jump)
              Screen.owner = mod
              tickAt = now() -- the SELECT that opened it must not also close it
              return true
            end
          end
          return false
        end)
        if ok and consumed then return end
        if not ok and ctx.mod.log then ctx.mod.log:warn("dex input (%s): %s", name, tostring(consumed)) end
        return orig(input, ...)
      end
    end

    for _, fn in ipairs({ "update", "tick" }) do
      if type(mod[fn]) == "function" then
        local orig = mod[fn]
        mod[fn] = function(...)
          if Screen.open and Screen.owner == mod then pcall(tick, nil) return end
          return orig(...)
        end
      end
    end

    if type(mod.draw) == "function" then
      local orig = mod.draw
      mod.draw = function(...)
        if Screen.open and Screen.owner == mod then
          if mod.open == false or (RseDex and mod == RseDex.Host and not RseDex.Host._s) then
            Screen.close() return orig(...)
          end
          local ok, err = pcall(Screen.draw)
          if ok then return end
          if ctx.mod.log then ctx.mod.log:warn("dex screen draw: %s", tostring(err)) end
          Screen.close()
        end
        local r = { orig(...) }
        if name ~= "pokedex" and mod.open ~= false and entrySpecies(mod) then
          pcall(function()
            -- Ruby/Sapphire's small font prints about 8 px under y and a bit
            -- wider: more room, and the text raised into the box
            local rsf = rsDex()
            local pad = rsf and 10 or 6
            local w = measure(labels()[1]) + pad
            local x, y = 238 - w, 16
            love.graphics.push("all")
            love.graphics.setColor(0.22, 0.32, 0.55, 1)
            love.graphics.rectangle("fill", x, y, w, 13, 2, 2)
            love.graphics.setColor(0.70, 0.80, 0.97, 1)
            love.graphics.rectangle("fill", x + 1, y + 1, w - 2, 11, 2, 2)
            love.graphics.pop()
            drawHint(x + (rsf and 5 or 3), y - (rsf and 6 or 1))
          end)
        end
        return (table.unpack or unpack)(r)
      end
    end

    if type(mod.close) == "function" then
      local orig = mod.close
      mod.close = function(...)
        if Screen.owner == mod then Screen.close() end
        return orig(...)
      end
    end
  end

  local function isDexName(name)
    name = tostring(name or ""):lower()
    return name:find("dex", 1, true) and not name:find("index", 1, true) and not name:find("chrome")
      and not name:find("data") and not name:find("rating") and not name:find("core")
      and not name:find("ph3") and not name:find("highlander")
  end

  function P.install()
    if P.installed then return end
    D = loadLocal("components/pokedex/data.lua")(ctx)
    Screen = loadLocal("components/pokedex/screen.lua")(ctx, D)
    P.screen = Screen
    P.installed = true

    if RseDex then hook(RseDex.Host, "rse_pokedex") end

    local okK, Pokedex = pcall(require, "src.ui.game3.pokedex")
    if okK and type(Pokedex) == "table" then
      hook(Pokedex, "pokedex")
      local okC, Chrome = pcall(require, "src.ui.game3.pokedex_chrome")
      if okC and type(Chrome) == "table" and type(Chrome.drawControlInfoLeft) == "function" then
        local pendingX, pendingY = nil, nil
        local function onEntry()
          return Pokedex.open and Pokedex.screen == "data" and not Screen.open
        end
        local function widthOf(str)
          local ok, w = pcall(function() return Chrome.measureControlInfo and Chrome.measureControlInfo(str) end)
          return (ok and tonumber(w)) or measure(str)
        end
        local origLeft = Chrome.drawControlInfoLeft
        Chrome.drawControlInfoLeft = function(str, startX, y, ...)
          local r = origLeft(str, startX, y, ...)
          if onEntry() and (tonumber(startX) or 0) <= 16 then
            pendingX, pendingY = (tonumber(startX) or 8) + widthOf(str) + 4, y or 146
          end
          return r
        end
        if type(Chrome.drawControlInfo) == "function" then
          local origRight = Chrome.drawControlInfo
          Chrome.drawControlInfo = function(str, rightX, y, ...)
            local r = origRight(str, rightX, y, ...)
            if pendingX and onEntry() then
              local startOfRight = (tonumber(rightX) or 236) - widthOf(str)
              pcall(drawHint, pendingX, pendingY, startOfRight - 3)
            end
            pendingX = nil
            return r
          end
        end
      end
    end

    -- Ruby/Sapphire/Emerald: any other Pokédex screen, found when it opens or is drawn
    local okSt, Stack = pcall(require, "src.ui.game3.stack")
    local checked = setmetatable({}, { __mode = "k" })
    local okU, UiPass = pcall(require, "src.ui.game3.ui_pass")
    if okU and type(UiPass) == "table" and type(UiPass.drawUi) == "function" then
      local origUi, lastScan = UiPass.drawUi, -10
      UiPass.drawUi = function(...)
        local t = now()
        if t - lastScan > 1 then
          lastScan = t
          pcall(function()
            for k, v in pairs(package.loaded) do
              if type(k) == "string" and k:find("src.ui", 1, true) and type(v) == "table"
                  and not v._ph3DexHooked and isDexName(k)
                  and (type(v.handleInput) == "function" or type(v.draw) == "function") then
                hook(v, k)
                if ctx.mod.log and ctx.mod.log.info then ctx.mod.log:info("dex hooks on '%s'", k) end
              end
            end
          end)
        end
        return origUi(...)
      end
    end
    if okSt and type(Stack) == "table" then
      local function consider(mod, id)
        if type(mod) ~= "table" or mod._ph3DexHooked or checked[mod] then return end
        checked[mod] = true
        local name = tostring(id or "")
        for k, v in pairs(package.loaded) do if v == mod then name = name .. " " .. k break end end
        if isDexName(name) then
          hook(mod, name)
          if ctx.mod.log and ctx.mod.log.info then ctx.mod.log:info("dex hooks on '%s'", name) end
        end
      end
      if type(Stack.push) == "function" then
        local origPush = Stack.push
        Stack.push = function(id, mod, ...)
          local r = origPush(id, mod, ...)
          pcall(consider, mod, id)
          return r
        end
      end
      if type(Stack.drawOrder) == "function" then
        local origOrder = Stack.drawOrder
        Stack.drawOrder = function(...)
          local order = origOrder(...)
          pcall(function()
            for _, layer in ipairs(order or {}) do
              if type(layer) == "table" and type(layer.mod) == "table" and not layer.mod._ph3DexHooked then
                consider(layer.mod, layer.id)
              end
            end
          end)
          return order
        end
      end
    end
  end

  return P
end
