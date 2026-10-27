-- Bill's PC (Move Pokémon) additions for all five Gen 3 games.
--   * SELECT toggles AUTO-GRAB: A picks a Pokémon up at once (like A > MOVE).
--   * MULTIPLE in the A menu: mark several Pokémon (A marks/unmarks), then
--     press A on a slot to move the whole group there: an empty box slot, or
--     the other side (party <-> box) where Pokémon already there are swapped.
--     B ends the multiple selection. Auto-Grab ends when the PC closes.
--   * BOX EXCLUSIVE (QOL toggle): the d-pad no longer changes boxes; use L/R
--     or A on the box name > SWITCH BOX.
return function(ctx)
  local P = { installed = false, autoGrab = false }
  local S = ctx.settings

  local UI, Storage, Presentation, RsStorage, RomText, Pokemon, FrlgFont, Window, Strings
  local menu = nil   -- our extended A menu: { items = {...}, native = {...}, cursor = n }
  local marks = nil  -- multiple selection: list of { mon, loc, boxId, slot }

  local GRAB = { 0.30, 0.90, 0.42 }
  local MARK = { 1.00, 0.62, 0.12 }

  local function se(id)
    pcall(function()
      local Se = require("src.core.game3.se_ids")
      require("src.core.game3.audio").playSe(type(id) == "string" and Se[id] or id)
    end)
  end

  local function isRs() return RsStorage.matches(UI._session) end

  local function text(rsName, sharedKey, fallback)
    local ok, t = pcall(function()
      if isRs() then return RsStorage.text(rsName) end
      return RomText.plain(sharedKey)
    end)
    if ok and type(t) == "string" and t ~= "" then return t end
    return fallback
  end

  local function message(t)
    UI._status, UI.mode = t, "message"
    se("SE_FAILURE")
  end

  local function returnMode()
    return (UI._actionSource == "party" or UI.drawerOpen) and "party_drawer" or "browse"
  end

  local function observed(fn)
    local p = UI._presentation
    local before = p and Presentation.capture(UI)
    fn()
    if p and UI.open then pcall(p.observe, p, before, Presentation.capture(UI)) end
  end

  local FAKE_A = {
    wasPressed = function(_, key) return key == "a" end,
    isDown = function() return false end,
  }

  -- what the cursor points at: mon, loc, boxId, slot (slot nil = not a mon slot)
  local function target()
    local session = UI._session
    local storage = Storage.ensure(session)
    if UI.mode == "party_drawer" then
      local i = UI.partyCursor or 1
      if i >= 1 and i <= 6 then return session.party and session.party[i], "party", nil, i end
      return nil
    end
    local s = UI.cursorSlot
    if s and s >= 1 and s <= Storage.IN_BOX_COUNT and storage then
      local b = storage.currentBox or 1
      local box = storage.boxes[b]
      return box and box.mons[s], "box", b, s
    end
    return nil
  end

  -- ------- AUTO-GRAB

  local function grab(mon, loc, boxId, slot)
    local session = UI._session
    if isRs() and loc == "party" and not RsStorage.canRemoveParty(session, slot) then
      return message(text("LastPoke", "gText_JustOnePkmn", "That's your last POKéMON!"))
    end
    local picked = Storage.pickUpMon(session, loc, slot, boxId)
    if not picked then
      return message(text("LastPoke", "gText_JustOnePkmn", "That's your last POKéMON!"))
    end
    UI._actionSource = loc
    UI._actionTarget = { mon = mon, loc = loc, boxId = boxId, slot = slot }
    UI.holdingMon = picked
    UI.holdingSource = { loc = loc, boxId = boxId, slot = slot }
    UI._holdingOrigin = UI.holdingSource
    se(5)
  end

  -- ------- MULTIPLE

  local function partyIndex(mon)
    for i, m in ipairs(UI._session.party or {}) do if m == mon then return i end end
  end

  local function liveMarks()
    if not marks then return {} end
    local storage = Storage.ensure(UI._session)
    local out = {}
    for _, m in ipairs(marks) do
      if m.loc == "party" then
        if partyIndex(m.mon) then out[#out + 1] = m end
      else
        local box = storage and storage.boxes[m.boxId]
        if box and box.mons[m.slot] == m.mon then out[#out + 1] = m end
      end
    end
    marks = out
    return out
  end

  local function isMarked(mon)
    for i, m in ipairs(marks or {}) do if m.mon == mon then return i end end
  end

  local function toggleMark(mon, loc, boxId, slot)
    local list = liveMarks()
    if list[1] and list[1].loc ~= loc then se("SE_FAILURE") return end
    local i = isMarked(mon)
    if i then table.remove(marks, i)
    else marks[#marks + 1] = { mon = mon, loc = loc, boxId = boxId, slot = slot } end
    se(5)
  end

  local function alive(mon)
    local ok, yes = pcall(function()
      return (tonumber(Pokemon.speciesOf(mon)) or 0) ~= 0 and not Pokemon.isEgg(mon)
        and (tonumber(mon.hp) or 0) > 0
    end)
    return ok and yes
  end

  local LAST = function() return text("LastPoke", "gText_JustOnePkmn", "That's your last POKéMON!") end
  local function noRoom()
    local t = "There isn't enough room."
    return (Strings and Strings(t)) or t
  end

  -- RS cannot box a Pokémon holding MAIL
  local function mailBlocked(mons)
    if not isRs() then return false end
    for _, mon in ipairs(mons) do
      if RsStorage.hasMail(mon) then
        message(text("PleaseRemoveMail", "gText_JustOnePkmn", "Please remove the MAIL."))
        return true
      end
    end
    return false
  end

  -- the party that would result must keep a Pokémon (RS: one that can battle)
  local function partyOk(newParty)
    if #newParty < 1 then return false end
    if not isRs() then return true end
    for _, mon in ipairs(newParty) do if alive(mon) then return true end end
    return false
  end

  -- Place the group at the cursor.
  --   box  -> same box side: fills the empty slots from the cursor onward.
  --   box  -> party: takes party slots from the cursor on; party members already
  --                  there are swapped into the marked Pokémon's box slots.
  --   party -> box : takes box slots from the cursor on; Pokémon already there
  --                  are swapped into the marked Pokémon's party places.
  local function placeGroup(loc, boxId, slot)
    local session = UI._session
    local storage = Storage.ensure(session)
    local list = liveMarks()
    if #list == 0 then se("SE_FAILURE") return end
    local side = list[1].loc
    local party = session.party or {}
    session.party = party
    local marked = {}
    for _, m in ipairs(list) do marked[m.mon] = true end
    local heal = function(mon) pcall(Storage.fullHealMon, mon, session) end

    if side == "party" and loc == "party" then se("SE_FAILURE") return end

    if side == "box" and loc == "box" then
      local box = storage.boxes[boxId]
      local free = {}
      for s = slot, Storage.IN_BOX_COUNT do
        local occupant = box.mons[s]
        if occupant == nil or marked[occupant] then free[#free + 1] = s end
      end
      if #free < #list then return message(noRoom()) end
      for _, m in ipairs(list) do storage.boxes[m.boxId].mons[m.slot] = nil end
      for i, m in ipairs(list) do heal(m.mon); box.mons[free[i]] = m.mon end

    elseif side == "box" and loc == "party" then
      local k = math.min(slot, #party + 1)
      if k + #list - 1 > 6 then
        return message(text("PartyFull", "gText_YourPartysFull", "Your party's full!"))
      end
      local newParty, outgoing = {}, {}
      for i, mon in ipairs(party) do newParty[i] = mon end
      for i, m in ipairs(list) do
        local di = k + i - 1
        local other = newParty[di]
        if other then outgoing[#outgoing + 1] = other end
        newParty[di] = m.mon
      end
      if mailBlocked(outgoing) then return end
      if not partyOk(newParty) then return message(LAST()) end
      for i, m in ipairs(list) do
        local di = k + i - 1
        local other = party[di]
        if other then heal(other) end
        storage.boxes[m.boxId].mons[m.slot] = other
        party[di] = m.mon
      end

    else -- party -> box
      local box = storage.boxes[boxId]
      if slot + #list - 1 > Storage.IN_BOX_COUNT then return message(noRoom()) end
      local mons = {}
      for _, m in ipairs(list) do mons[#mons + 1] = m.mon end
      if mailBlocked(mons) then return end
      local newParty = {}
      local swapIn = {}
      for i, m in ipairs(list) do swapIn[m.mon] = box.mons[slot + i - 1] end
      for _, mon in ipairs(party) do
        if marked[mon] then
          if swapIn[mon] then newParty[#newParty + 1] = swapIn[mon] end
        else
          newParty[#newParty + 1] = mon
        end
      end
      if not partyOk(newParty) then return message(LAST()) end
      for i, m in ipairs(list) do heal(m.mon); box.mons[slot + i - 1] = m.mon end
      for i = #party, 1, -1 do party[i] = nil end
      for i, mon in ipairs(newParty) do party[i] = mon end
    end
    Storage.compactParty(session.party)
    marks = nil
    se("SE_BAG_POCKET")
  end

  -- ------- extended A menu (native items + MULTIPLE before CANCEL)

  local MENU_TEXT = { CANCEL = 0, STORE = 1, WITHDRAW = 2, MOVE = 3, SUMMARY = 6, RELEASE = 7,
    ["SWITCH BOX"] = 9, WALLPAPER = 10, TAKE = 12 }

  local function label(act)
    if act == "MULTI" then return "MULTIPLE" end
    local ok, t = pcall(function()
      if isRs() then return RsStorage.menuText(act) end
      return RomText.at("sMenuTexts", MENU_TEXT[act])
    end)
    return ok and t or act
  end

  local function openMenu()
    local native = UI._activeActions
    if type(native) ~= "table" then return end
    local items = {}
    for _, act in ipairs(native) do items[#items + 1] = act end
    local at = #items + 1
    for i, act in ipairs(items) do if act == "CANCEL" then at = i break end end
    table.insert(items, at, "MULTI")
    menu = { items = items, native = native, cursor = 1 }
  end

  local function menuInput(input)
    if UI.mode ~= "action_menu" then menu = nil return false end
    local n = #menu.items
    if input:wasPressed("up") then menu.cursor = (menu.cursor - 2) % n + 1; se(5)
    elseif input:wasPressed("down") then menu.cursor = menu.cursor % n + 1; se(5)
    elseif input:wasPressed("a") then
      local act = menu.items[menu.cursor]
      if act == "MULTI" then
        local t = UI._actionTarget
        menu = nil
        observed(function()
          UI.mode = returnMode()
          marks = {}
          if t and t.mon then
            marks[1] = { mon = t.mon, loc = t.loc, boxId = t.boxId, slot = t.slot }
          end
          se(5)
        end)
      else
        local index = 1
        for i, a in ipairs(menu.native) do if a == act then index = i break end end
        menu = nil
        UI.actionCursor = index
        P.orig.handleInput(FAKE_A)
      end
    elseif input:wasPressed("b") then
      menu = nil
      P.orig.handleInput(input)
    end
    return true
  end

  -- ------- drawing

  local function frame(cx, cy, color, alpha)
    love.graphics.setLineWidth(2)
    love.graphics.setColor(color[1], color[2], color[3], alpha or 1)
    love.graphics.rectangle("line", cx - 12, cy - 12, 24, 24, 4, 4)
    love.graphics.setLineWidth(1)
  end

  local function pill(t, color)
    local w = 0
    local ok, m = pcall(FrlgFont.measure, t, { small = true })
    w = (ok and tonumber(m) or #t * 5) + 8
    love.graphics.setColor(0.08, 0.08, 0.10, 0.85)
    love.graphics.rectangle("fill", 2, 2, w, 13, 4, 4)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    love.graphics.rectangle("line", 2.5, 2.5, w - 1, 12, 4, 4)
    FrlgFont.draw(t, 6, 2, { small = true,
      colors = { fg = { 1, 1, 1, 1 }, shadow = { 0, 0, 0, 0.5 }, bg = FrlgFont.STDPAL[0] } })
  end

  local function drawMenu()
    local items = menu.items
    if isRs() then
      local width = 0
      for _, act in ipairs(items) do width = math.max(width, math.ceil(FrlgFont.measure(label(act)) / 8)) end
      local left, top = 29 - width, 15 - #items * 2
      Window.userFrame(Window.template(left, top, width, #items * 2))
      for i, act in ipairs(items) do Window.printPx(label(act), left * 8, (top + (i - 1) * 2) * 8) end
      require("src.ui.game3.rs.menu_cursor").draw(left * 8, (top + (menu.cursor - 1) * 2) * 8, width * 8)
      return
    end
    local menuLeft, menuTop, textLeft = 13, 5, 114
    if UI._actionSource == "party" or UI.drawerOpen then menuLeft, menuTop, textLeft = 11, 4, 98 end
    Window.stdFrame(Window.template(menuLeft, menuTop, 10, #items * 2))
    for i, act in ipairs(items) do
      local yPx = (menuTop * 8 + 2) + (i - 1) * 16
      if i == menu.cursor then Window.cursorPx(textLeft - 8, yPx) end
      Window.printPx(label(act), textLeft, yPx)
    end
  end

  local function drawExtras()
    local browsing = UI.mode == "browse" or UI.mode == "party_drawer"
    local inDrawer = UI.mode == "party_drawer"
    love.graphics.push("all")
    if marks then
      local storage = Storage.ensure(UI._session)
      local pulse = 0.65 + 0.35 * math.abs(math.sin((love.timer and love.timer.getTime() or 0) * 4))
      for _, m in ipairs(liveMarks()) do
        if m.loc == "box" and not UI.drawerOpen and storage and m.boxId == storage.currentBox then
          local cx, cy = Presentation.iconCoords("box", m.slot)
          frame(cx, cy, MARK, pulse)
        elseif m.loc == "party" and inDrawer then
          local i = partyIndex(m.mon)
          if i then
            local cx, cy = Presentation.iconCoords("party", i)
            frame(cx, cy, MARK, pulse)
          end
        end
      end
      if browsing then pill(("%d MARKED  B: END"):format(#marks), MARK) end
    elseif P.autoGrab and browsing and UI.subMode == "move" then
      if not UI.holdingMon then
        local _, loc, _, slot = target()
        if slot then
          local cx, cy = Presentation.iconCoords(loc, slot)
          frame(cx, cy, GRAB, 1)
        end
      end
      pill("AUTO-GRAB", GRAB)
    end
    love.graphics.pop()
    if menu and UI.mode == "action_menu" then drawMenu() end
  end

  -- ------- input

  local function handleInput(input)
    if not (input and UI.open) then return P.orig.handleInput(input) end
    local p = UI._presentation
    if p and p:busy() then return P.orig.handleInput(input) end
    if not UI.open then P.autoGrab = false end
    if menu then
      if menuInput(input) then return end
    end
    local browsing = UI.mode == "browse" or UI.mode == "party_drawer"
    local moveMode = UI.subMode == "move"

    if browsing and moveMode then
      if marks then
        if input:wasPressed("b") then
          marks = nil
          se(5)
          return
        end
        if input:wasPressed("a") then
          local mon, loc, boxId, slot = target()
          if slot then
            observed(function()
              local first = liveMarks()[1]
              if mon and (not first or first.loc == loc) then toggleMark(mon, loc, boxId, slot)
              else placeGroup(loc, boxId, slot) end
            end)
            return
          end
        end
        if input:wasPressed("select") then return end
      else
        if input:wasPressed("select") and not UI.holdingMon then
          P.autoGrab = not P.autoGrab
          se(5)
          return
        end
        if input:wasPressed("a") and not UI.holdingMon then
          local mon, loc, boxId, slot = target()
          if mon and P.autoGrab then
            observed(function() grab(mon, loc, boxId, slot) end)
            return
          end
          if mon then
            P.orig.handleInput(input)
            if UI.mode == "action_menu" then openMenu() end
            return
          end
        end
      end
    end

    -- BOX EXCLUSIVE: the d-pad stays inside the current box
    if UI.mode == "browse" and S.get("box_exclusive") == true then
      local left, right = input:wasPressed("left"), input:wasPressed("right")
      if left or right then
        local s = UI.cursorSlot
        if s == 0 then return end
        if s and s >= 1 and s <= Storage.IN_BOX_COUNT then
          local col, row = (s - 1) % 6, math.floor((s - 1) / 6)
          if left and col == 0 then
            observed(function() UI.cursorSlot = row * 6 + 6; se(5) end)
            return
          elseif right and col == 5 then
            observed(function() UI.cursorSlot = row * 6 + 1; se(5) end)
            return
          end
        end
      end
    end

    return P.orig.handleInput(input)
  end

  function P.install()
    if P.installed then return end
    UI = require("src.ui.game3.box_storage_ui")
    Storage = require("src.core.game3.storage")
    Presentation = require("src.ui.game3.storage_presentation")
    RsStorage = require("src.ui.game3.rs.storage_policy")
    RomText = require("src.core.game3.rom_text")
    Pokemon = require("src.core.game3.pokemon")
    FrlgFont = require("src.ui.game3.frlg_font")
    Window = require("src.ui.game3.window")
    local okS, St = pcall(require, "src.core.Strings")
    Strings = okS and type(St) == "function" and St or nil
    P.installed = true
    P.orig = { handleInput = UI.handleInput, draw = UI.draw, show = UI.show, close = UI.close }

    UI.show = function(opts, ...)
      menu, marks, P.autoGrab = nil, nil, false
      return P.orig.show(opts, ...)
    end
    UI.close = function(...)
      local result = P.orig.close(...)
      if not UI.open then menu, marks, P.autoGrab = nil, nil, false end
      return result
    end
    UI.handleInput = function(input)
      local ok, err = pcall(handleInput, input)
      if not ok then
        menu, marks = nil, nil
        if ctx.mod.log then ctx.mod.log:warn("PC input: %s", tostring(err)) end
      end
    end
    UI.draw = function(...)
      P.orig.draw(...)
      if UI.open then
        local ok, err = pcall(drawExtras)
        if not ok and ctx.mod.log then ctx.mod.log:warn("PC draw: %s", tostring(err)) end
      end
    end
  end

  return P
end
