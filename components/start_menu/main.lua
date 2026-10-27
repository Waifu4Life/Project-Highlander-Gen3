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

  function M.refresh()
    local StartMenu = require("src.ui.game3.start_menu")
    G.active = false
    G.slots = nil
    if not (StartMenu.open and S.flag("start_enabled")) then return end
    if StartMenu._kind ~= "normal" or StartMenu._tutorial then return end
    local slots = L.fromEntries(StartMenu.ENTRIES, S.order())
    if not slots then return end
    G.slots = slots
    G.orderKey = tostring(S.get("start_order"))
    G.active = true
    -- keep the game's remembered cursor (pret start_menu.c sStartMenuCursorPos)
    G.cursor = nil
    for i = 1, L.SLOTS do
      local s = slots[i]
      if s and s.index == StartMenu.cursor then G.cursor = i break end
    end
    G.cursor = G.cursor or L.firstFilled(slots)
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
    local key = tostring(S.get("start_order"))
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

    -- PokéBox entry (also shown in the native list when the grid is OFF)
    mod.hooks:wrap("ui.start_menu.items", function(nextFn, game, items)
      items = nextFn(game, items) or items or {}
      if StartMenu._kind == "normal" and not StartMenu._tutorial and S.flag("pokebox")
          and hasParty(StartMenu._session) and not hasId(items, "pokebox") then
        local entry = { id = "pokebox", label = "POKéBOX",
          onSelect = function(_, session) openPokebox(session or StartMenu._session) end }
        local at = #items
        for i, item in ipairs(items) do
          if type(item) == "table" and item.id == "exit" then at = i break end
        end
        table.insert(items, math.max(1, at), entry)
      end
      return items
    end)

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
      D.barText(S.flag("clock") and D.clockText(StartMenu._session) or "MENU", nil)
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
