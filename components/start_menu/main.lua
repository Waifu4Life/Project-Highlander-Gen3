-- Grid Start Menu: takes over the NORMAL overworld menu only. Safari Zone,
-- Union Room, link rooms, Battle Pyramid/Pike, multi-partner rooms and the
-- Emerald tutorial keep the game's own text menu.
return function(ctx)
  local M = { installed = false }
  local S, L, D = ctx.settings, ctx.layout, ctx.draw
  local mod = ctx.mod

  local G = { active = false, slots = nil, cursor = 1 }
  M.state = G

  local function se(id)
    pcall(function()
      require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").resolve(id))
    end)
  end
  M.se = se

  local function hasParty(session)
    local party = type(session) == "table" and session.party or nil
    return type(party) == "table" and #party > 0
  end

  local function openPokebox(session)
    -- Bill's PC > MOVE POKéMON; closing it returns straight to this Start Menu
    local BoxStorageUI = require("src.ui.game3.box_storage_ui")
    BoxStorageUI.show({ session = session, subMode = "move", onClose = function() end })
  end

  local function hasId(items, id)
    for _, item in ipairs(items or {}) do
      if type(item) == "table" and item.id == id then return true end
    end
    return false
  end

  -- CUSTOM RENAME names are drawn exactly as typed (Decapitalize skips them)
  function M.syncNames()
    local keep = {}
    for _, name in pairs(S.names()) do keep[name] = true end
    if ctx.decap then ctx.decap.keep = keep end
  end

  -- ------- other mods' Options pages as Start Menu items (like Gen 1/2)
  -- Every row another mod adds to the OPTIONS menu that opens something,
  -- and PROJECT HIGHLANDER itself, is a Start Menu item: it opens OPTIONS
  -- straight on that page, and backing out of the page closes OPTIONS
  -- again. Like other mods' items they can be sorted, hidden, renamed and
  -- given an icon; they all show until hidden.

  local FAKE_A = {
    wasPressed = function(_, k) return k == "a" end,
    isDown = function() return false end,
    isPressed = function() return false end,
  }
  local optPending, optWatch = nil, nil

  local function optionPages(menu)
    return menu._pages or (type(menu._st) == "table" and menu._st.pages) or nil
  end

  -- a row's key: its id, else its label
  function M.rowKey(r)
    if type(r) ~= "table" then return nil end
    if r.id ~= nil then return tostring(r.id) end
    if r.label ~= nil then return "L_" .. tostring(r.label) end
    return nil
  end

  -- the rows seen in OPTIONS (core/options_hub.lua remembers them, so mods
  -- that add theirs late, like Wilds of Hoenn, are there too), the ones
  -- mods hand over right now, and PROJECT HIGHLANDER
  function M.optionRows(game)
    local out, seen = {}, {}
    local function add(key, label)
      if key and not seen[key] and key ~= "ph3_hub" then
        seen[key] = true
        out[#out + 1] = { id = key, label = label }
      end
    end
    for _, r in ipairs(S.optionRows()) do add(r.key, r.label) end
    local okR, Runtime = pcall(require, "src.mods.Runtime")
    if okR and type(Runtime) == "table" and type(Runtime.call) == "function" then
      local ok, rows = pcall(Runtime.call, "ui.options.rows", function(_, r) return r end, game, {})
      if ok and type(rows) == "table" then
        for _, r in ipairs(rows) do
          if type(r) == "table" and type(r.activate) == "function" then
            add(M.rowKey(r), tostring(r.label or r.id or "?"))
          end
        end
      end
    end
    out[#out + 1] = { id = "ph3_hub", label = "HIGHLANDER" }
    return out
  end

  -- once the menu takes input: put its cursor on the row and press A
  function M.pumpOptionRow()
    local p = optPending
    if not p then return end
    local menu = p.menu
    p.tries = p.tries + 1
    if p.tries > 120 then optPending = nil return end
    local pages = optionPages(menu)
    if not (type(pages) == "table" and pages[1]) then return end
    local top = pages[#pages]
    optPending = nil
    local at
    for i, r in ipairs(top.rows or {}) do
      if M.rowKey(r) == p.id then at = i break end
    end
    if not at then return end
    top.index = at
    local before = #pages
    if menu._state ~= nil then
      -- Ruby/Sapphire: their Options fade in and take no input until then,
      -- so open the row now, before the first frame: the fade-in shows the
      -- page straight away instead of flashing the Options menu first
      local row = top.rows[at]
      if type(row.activate) ~= "function" then return end
      row.activate({ session = menu._session, game = menu._game, options = menu._engine })
    else
      if menu.cursor ~= nil then menu.cursor = at end
      menu.handleInput(FAKE_A)
    end
    local after = optionPages(menu)
    if type(after) == "table" and #after > before then optWatch = { menu = menu, depth = #after } end
  end

  local function openOptionRow(rowId, session)
    local Screens = require("src.ui.game3.screens")
    local menu = Screens.get("option", session)
    if not (type(menu) == "table" and type(menu.show) == "function") then return end
    menu.show({ session = session })
    optPending = { menu = menu, id = rowId, tries = 0 }
    pcall(M.pumpOptionRow) -- FR/LG and Emerald take input at once
  end

  local function watchOptions(menu)
    if optPending and optPending.menu == menu then pcall(M.pumpOptionRow) end
    local w = optWatch
    if not (w and w.menu == menu) then return end
    local open = true
    if type(menu.isOpen) == "function" then
      local ok, o = pcall(menu.isOpen)
      open = ok and o and true or false
    end
    local pages = optionPages(menu)
    if not open or type(pages) ~= "table" then
      optWatch = nil
    elseif #pages < w.depth then
      -- backed out of the page: straight back to the Start Menu
      optWatch = nil
      pcall(menu.close)
    end
  end

  -- ------- START MENU SETTINGS > HIDE ITEMS / CUSTOM RENAME rows

  local function byLabel(a, b)
    return tostring(a.label):upper() < tostring(b.label):upper()
  end

  -- POKéBOX, MODS and other mods' items (the ones seen in the Start Menu so far)
  function M.hideItems()
    local out = { { key = "mods", label = L.label("mods") },
      { key = "pokebox", label = L.label("pokebox") } }
    for _, it in ipairs(S.iconItems()) do
      out[#out + 1] = { key = S.extraKey(it.key), label = it.label }
    end
    table.sort(out, byLabel)
    return out
  end

  -- every item of this game's Start Menu, hidden ones and EXIT included
  function M.renameItems(session)
    local out = {}
    for _, id in ipairs(S.DEFAULT_ORDER) do
      if id ~= "pokenav" or S.isHoenn(session) then
        out[#out + 1] = { key = id, label = L.label(id) }
      end
    end
    for _, it in ipairs(S.iconItems()) do
      out[#out + 1] = { key = S.extraKey(it.key), label = it.label }
    end
    out[#out + 1] = { key = "exit", label = L.label("exit") }
    table.sort(out, byLabel)
    return out
  end

  M.MAX_NAME = 10

  -- the game's own keyboard; an empty name puts the usual one back
  function M.rename(key, session)
    local Naming = require("src.ui.game3.naming")
    local function done(name)
      if type(name) == "string" then
        S.setName(key, name)
        M.syncNames()
      end
    end
    local ok = pcall(Naming.open, { template = "BOX", title = "NAME?", maxLen = M.MAX_NAME,
      session = session, onDone = done })
    if not ok then
      pcall(Naming.open, { title = "NAME?", maxLen = M.MAX_NAME, session = session, onDone = done })
    end
  end

  function M.refresh()
    pcall(M.syncNames)
    local StartMenu = require("src.ui.game3.start_menu")
    G.active = false
    G.slots = nil
    if not (StartMenu.open and S.flag("start_enabled")) then return end
    if StartMenu._kind ~= "normal" or StartMenu._tutorial then return end
    local slots = L.fromEntries(StartMenu.ENTRIES, S.order())
    if not slots then return end
    G.slots = slots
    G.orderKey = S.orderRaw()
    G.active = true
    -- keep the game's remembered cursor (pret start_menu.c sStartMenuCursorPos)
    G.cursor = nil
    for i = 1, L.total(slots) do
      local s = slots[i]
      if s and s.index == StartMenu.cursor then G.cursor = i break end
    end
    G.cursor = G.cursor or L.firstFilled(slots)
    -- other mods' items, so OPTIONS > START MENU SETTINGS > CUSTOM ICONS lists them
    local seen = {}
    for i = 1, L.total(slots) do
      local s = slots[i]
      if s and s.extra then seen[#seen + 1] = { key = s.iconKey, label = s.label } end
    end
    if #seen > 0 then pcall(S.rememberIconItems, seen) end
    -- full-screen layer: the overworld is not drawn behind the grid
    local Stack = require("src.ui.game3.stack")
    for _, layer in ipairs(Stack._layers or {}) do
      if layer.id == "start" then
        layer.fullscreen = function() return G.active and StartMenu.open end
      end
    end
  end

  local function gridActive(StartMenu)
    if not (G.active and StartMenu.open and G.slots ~= nil) then return false end
    if not S.flag("start_enabled") then return false end
    -- the order can change in OPTIONS while the menu is still open underneath
    local key = S.orderRaw()
    if G.orderKey ~= key then
      G.orderKey = key
      local slots = L.fromEntries(StartMenu.ENTRIES, S.order())
      if not slots then return false end
      G.slots = slots
      if not L.filled(slots, G.cursor) then G.cursor = L.firstFilled(slots) end
    end
    return true
  end

  local function nativeInput(StartMenu, input)
    if input:wasPressed("up") then StartMenu.move(-1)
    elseif input:wasPressed("down") then StartMenu.move(1)
    elseif input:wasPressed("a") then StartMenu.confirm()
    elseif input:wasPressed("b") or input:wasPressed("start") then
      if StartMenu.cancel then StartMenu.cancel() else StartMenu.close() end
    end
  end

  function M.install()
    if M.installed then return end
    local StartMenu = require("src.ui.game3.start_menu")
    M.installed = true
    pcall(M.syncNames)

    -- PokéBox entry (also shown in the native list when the grid is OFF)
    mod.hooks:wrap("ui.start_menu.items", function(nextFn, game, items)
      items = nextFn(game, items) or items or {}
      if StartMenu._kind == "normal" and not StartMenu._tutorial and S.flag("pokebox")
          and not S.isHidden("pokebox")
          and hasParty(StartMenu._session) and not hasId(items, "pokebox") then
        local entry = { id = "pokebox", label = "POKéBOX",
          onSelect = function(_, session) openPokebox(session or StartMenu._session) end }
        local at = #items
        for i, item in ipairs(items) do
          if type(item) == "table" and item.id == "exit" then at = i break end
        end
        table.insert(items, math.max(1, at), entry)
      end
      if StartMenu._kind == "normal" and not StartMenu._tutorial then
        local okO, rows = pcall(M.optionRows, game or StartMenu._game)
        for _, r in ipairs(okO and rows or {}) do
          local id = "opt:" .. r.id
          if not hasId(items, id) then
            local rowId = r.id
            local entry = { id = id, label = r.label,
              onSelect = function(_, session) openOptionRow(rowId, session or StartMenu._session) end }
            local at = #items
            for i, item in ipairs(items) do
              if type(item) == "table" and item.id == "exit" then at = i break end
            end
            table.insert(items, math.max(1, at), entry)
          end
        end
      end
      return items
    end)

    for _, name in ipairs({ "src.ui.game3.option_menu", "src.ui.game3.rse.option_menu", "src.ui.game3.rs.option_menu" }) do
      local okM, menu = pcall(require, name)
      if okM and type(menu) == "table" and type(menu.update) == "function" and not menu._ph3Shortcut then
        menu._ph3Shortcut = true
        local origUpdate = menu.update
        menu.update = function(...)
          local r = { origUpdate(...) }
          pcall(watchOptions, menu)
          return (table.unpack or unpack)(r)
        end
      end
    end

    -- SAVE inside the Start Menu: the game's own save screen (same prompts, same
    -- save routine) is shown on top of the grid instead of hiding it, and after
    -- "<name> saved the game." you're back on the Start Menu, not the overworld.
    local okSave, SaveMenu = pcall(require, "src.ui.game3.save_menu")
    if okSave and type(SaveMenu) == "table" and type(SaveMenu.show) == "function" then
      local origSaveShow, origSaveConfirm, origSaveClose = SaveMenu.show, SaveMenu.confirm, SaveMenu.close
      SaveMenu.show = function(opts, ...)
        local fromMenu = StartMenu.open and gridActive(StartMenu)
        local r = origSaveShow(opts, ...)
        if fromMenu then
          SaveMenu._ph3InMenu = true
          pcall(function()
            local Stack = require("src.ui.game3.stack")
            for i = #Stack._layers, 1, -1 do
              local layer = Stack._layers[i]
              if layer.mod == SaveMenu then layer.hideBelow = false break end
            end
          end)
        end
        return r
      end
      if type(origSaveConfirm) == "function" then
        SaveMenu.confirm = function(...)
          if SaveMenu._ph3InMenu and SaveMenu._phase == "saved" then
            -- the game would close the Start Menu here; stay on it instead
            return SaveMenu.close()
          end
          return origSaveConfirm(...)
        end
      end
      if type(origSaveClose) == "function" then
        SaveMenu.close = function(...)
          SaveMenu._ph3InMenu = nil
          return origSaveClose(...)
        end
      end
    end

    local origShow = StartMenu.show
    StartMenu.show = function(opts)
      local result = origShow(opts)
      local ok, err = pcall(M.refresh)
      if not ok then
        G.active = false
        if mod.log then mod.log:warn("start menu grid off: %s", tostring(err)) end
      end
      return result
    end

    local origDraw = StartMenu.draw
    StartMenu.draw = function(...)
      if not gridActive(StartMenu) then return origDraw(...) end
      love.graphics.push("all")
      local theme = D.theme(StartMenu._session)
      D.background(theme)
      D.barText(D.clockText(StartMenu._session) or "MENU",
        D.pageText(G.slots, G.cursor))
      D.grid(G.slots, G.cursor, theme)
      love.graphics.pop()
      if StartMenu._confirmExit then D.exitPrompt(StartMenu) end
    end

    StartMenu.handleInput = function(input)
      if not input then return end
      if not gridActive(StartMenu) then return nativeInput(StartMenu, input) end
      if StartMenu._confirmExit then
        if input:wasPressed("left") or input:wasPressed("right") then
          StartMenu.move(1)
          return
        end
        return nativeInput(StartMenu, input)
      end
      local before = G.cursor
      if input:wasPressed("up") then G.cursor = L.move(G.slots, G.cursor, 0, -1)
      elseif input:wasPressed("down") then G.cursor = L.move(G.slots, G.cursor, 0, 1)
      elseif input:wasPressed("left") then G.cursor = L.move(G.slots, G.cursor, -1, 0)
      elseif input:wasPressed("right") then G.cursor = L.move(G.slots, G.cursor, 1, 0)
      elseif input:wasPressed("select") then
        se("SE_SELECT")
        ctx.sort.show({ session = StartMenu._session, onClose = function()
          pcall(M.refresh)
        end })
        return
      elseif input:wasPressed("a") then
        local slot = G.slots[G.cursor]
        if slot then
          StartMenu.cursor = slot.index
          StartMenu.confirm()
        end
        return
      elseif input:wasPressed("b") or input:wasPressed("start") then
        if StartMenu.cancel then StartMenu.cancel() else StartMenu.close() end
        return
      end
      if G.cursor ~= before then
        local slot = G.slots[G.cursor]
        if slot then StartMenu.cursor = slot.index end
        se("SE_SELECT")
      end
    end
  end

  return M
end
