-- Party menu (Pokémon screen) additions for all five Gen 3 games. Always on.
--   * SELECT quick switch: SELECT on a Pokémon starts the game's own SWITCH
--     straight away ("Move to where?"); A or SELECT on the second Pokémon
--     swaps them, B cancels.
--   * A menu order: SUMMARY (Stats), ROLE, SWITCH, ITEM (or MAIL), RELEARN,
--     HM field moves, other (TM) field moves, CANCEL. ROLE comes from Wilds of
--     Hoenn, RELEARN from a later mod; they only show when those mods add them.
--   * More than 8 entries in the A menu: 8 are shown at a time with a scroll
--     bar and small up/down arrows when there's more above or below.
--
-- Working with other mods (Wilds of Hoenn's ROLE row):
--   * the list is reordered IN PLACE (same table), so a mod that remembers the
--     list it already edited doesn't add its row again;
--   * prebuilt row texts (PartyMenu._actionTexts = { list, texts }) are moved
--     along with their rows, and handed over in slices while scrolling;
--   * submenus (ROLE > Follow / Forage / Fight / Back) are a different list and
--     are left alone.
return function(ctx)
  local P = { installed = false, scroll = 0, fieldList = nil }
  local PartyMenu, Chrome, FrlgFont

  local VISIBLE = 8

  local HM = {
    CUT = true, FLY = true, SURF = true, STRENGTH = true, FLASH = true,
    ["ROCK SMASH"] = true, WATERFALL = true, DIVE = true,
  }
  local TM = {
    TELEPORT = true, DIG = true, ["MILK DRINK"] = true, SOFTBOILED = true,
    ["SWEET SCENT"] = true, ["SECRET POWER"] = true,
  }

  local function norm(act)
    local s = tostring(act or ""):upper():gsub("_", " ")
    return s
  end

  -- labels may carry extra glyphs after the word (Wilds of Hoenn's "ROLE ▶")
  local function startsWith(a, word)
    return a == word or a:sub(1, #word + 1) == word .. " " or
      (a:sub(1, #word) == word and not a:sub(#word + 1, #word + 1):match("[%w]"))
  end

  local function rank(act)
    local a = norm(act)
    if a == "SUMMARY" or a == "STATS" then return 1 end
    if startsWith(a, "ROLE") then return 2 end
    if a == "SWITCH" then return 3 end
    if a == "ITEM" or a == "MAIL" then return 4 end
    if startsWith(a, "RELEARN") then return 6 end
    if a == "CANCEL" then return 9 end
    if HM[a] then return 7 end
    if TM[a] then return 8 end
    local fm = PartyMenu._fieldMoveNames
    if type(fm) == "table" and fm[act] then return 8 end
    return 5 -- anything else another mod adds: after ITEM, before RELEARN
  end

  local function indexOf(list, value)
    for i, v in ipairs(list) do if v == value then return i end end
  end

  -- the overworld A menu: a plain list of strings with SUMMARY, CANCEL and ITEM/MAIL
  local function isFieldList(list)
    if type(list) ~= "table" then return false end
    local n = #list
    if n < 3 or n > 24 then return false end
    for i = 1, n do if type(list[i]) ~= "string" then return false end end
    return indexOf(list, "SUMMARY") ~= nil and indexOf(list, "CANCEL") ~= nil
      and (indexOf(list, "ITEM") ~= nil or indexOf(list, "MAIL") ~= nil)
  end

  -- prebuilt texts that belong to this exact list (or nil)
  local function textsFor(list)
    local t = PartyMenu._actionTexts
    if type(t) == "table" and t.list == list and type(t.texts) == "table" then return t end
  end

  -- Stable in-place sort of the field A menu; the cursor stays on its entry.
  local function sortActions()
    local list = PartyMenu.ACTIONS
    if list ~= P.fieldList or not isFieldList(list) then return end
    local keyed = {}
    for i, act in ipairs(list) do keyed[i] = { act = act, r = rank(act), i = i } end
    table.sort(keyed, function(x, y)
      if x.r ~= y.r then return x.r < y.r end
      return x.i < y.i
    end)
    local changed = false
    for i, k in ipairs(keyed) do if k.i ~= i then changed = true break end end
    if not changed then return end

    local cur = PartyMenu.actionCursor or 1
    local texts = textsFor(list)
    local oldTexts = texts and texts.texts
    for i, k in ipairs(keyed) do list[i] = k.act end
    if oldTexts then
      local moved = {}
      for i, k in ipairs(keyed) do moved[i] = oldTexts[k.i] end
      texts.texts = moved
    end
    for i, k in ipairs(keyed) do
      if k.i == cur then PartyMenu.actionCursor = i break end
    end
  end

  local function se(id)
    pcall(function() require("src.core.game3.audio").playSe(id) end)
  end

  local function partyCount()
    local party = PartyMenu._party
    local n = 0
    if type(party) == "table" then
      for i = 1, 6 do if party[i] then n = i end end
    end
    return n
  end

  local function nativeReady()
    if PartyMenu._pokedude or PartyMenu._hpAnim then return false end
    local okS, Summary = pcall(require, "src.ui.game3.summary_menu")
    if okS and type(Summary) == "table" and Summary.isOpen and Summary.isOpen() then return false end
    return true
  end

  local FAKE_A = {
    wasPressed = function(_, key) return key == "a" end,
    isDown = function() return false end,
  }

  -- remember the overworld list when the A menu opens from the party list
  local function track(before)
    local now = PartyMenu.mode
    if now == "action" and before == "list" then
      P.fieldList, P.scroll, P.touched = PartyMenu.ACTIONS, 0, false
    elseif now ~= "action" then
      P.fieldList = nil
    end
    if P.fieldList and now == "action" then
      sortActions()
      -- until the player moves the cursor, it stays on the first entry (SUMMARY),
      -- even when another mod adds a row after the menu opened
      if not P.touched and PartyMenu.ACTIONS == P.fieldList then PartyMenu.actionCursor = 1 end
    end
  end

  -- ------- input

  local function handleInput(input, ...)
    local before = PartyMenu.mode
    if input and nativeReady() and input:wasPressed("select") then
      if before == "list" then
        local cur = PartyMenu.cursor or 1
        if cur >= 1 and cur <= partyCount() and PartyMenu._party[cur] then
          se(5)
          PartyMenu.switchFrom = cur
          PartyMenu.mode = "switch"
          return
        end
      elseif before == "switch" and PartyMenu.switchFrom then
        -- SELECT on the second Pokémon finishes the switch, like A
        return P.orig.handleInput(FAKE_A)
      end
    end
    if before == "action" and input and P.fieldList then
      for _, k in ipairs({ "up", "down", "a", "b" }) do
        if input:wasPressed(k) then P.touched = true break end
      end
    end
    P.orig.handleInput(input, ...)
    track(before)
  end

  -- ------- drawing (scroll bar for more than 8 entries)

  local lastFrame = nil
  local function capture(name)
    local orig = Chrome[name]
    if type(orig) ~= "function" then return end
    Chrome[name] = function(...)
      if P.capturing then
        local a = { ... }
        if name == "userFrame" then lastFrame = { a[2], a[3], a[4], a[5] }
        else lastFrame = { a[1], a[2], a[3], a[4] } end
      end
      return orig(...)
    end
  end

  local function tri(cx, y, up, color)
    love.graphics.setColor(color[1], color[2], color[3], 1)
    if up then
      love.graphics.polygon("fill", cx - 3, y + 3, cx + 3, y + 3, cx, y)
    else
      love.graphics.polygon("fill", cx - 3, y, cx + 3, y, cx, y + 3)
    end
  end

  local function drawScroll(total, scroll)
    local f = lastFrame or { 19, 3, 10, 16 }
    local T = 8
    local L, Top, W, H = tonumber(f[1]) or 19, tonumber(f[2]) or 3, tonumber(f[3]) or 10, tonumber(f[4]) or 16
    local cx = (L + W) * T - 4
    local top, bottom = Top * T, (Top + H) * T
    local dark = (FrlgFont and FrlgFont.STDPAL and FrlgFont.STDPAL[2]) or { 0.38, 0.38, 0.38, 1 }
    local light = (FrlgFont and FrlgFont.STDPAL and FrlgFont.STDPAL[3]) or { 0.84, 0.84, 0.80, 1 }
    local t = love.timer and love.timer.getTime() or 0
    local bob = (math.floor(t * 3) % 2 == 0) and 0 or 1

    love.graphics.push("all")
    local trackTop, trackBottom = top + 9, bottom - 9
    local trackH = trackBottom - trackTop
    love.graphics.setColor(light[1], light[2], light[3], 1)
    love.graphics.rectangle("fill", cx - 1, trackTop, 3, trackH)
    local thumbH = math.max(6, math.floor(trackH * VISIBLE / total + 0.5))
    local maxScroll = total - VISIBLE
    local thumbY = trackTop + math.floor((trackH - thumbH) * (scroll / maxScroll) + 0.5)
    love.graphics.setColor(dark[1], dark[2], dark[3], 1)
    love.graphics.rectangle("fill", cx - 1, thumbY, 3, thumbH)
    if scroll > 0 then tri(cx + 0.5, top + 2 - bob, true, dark) end
    if scroll < maxScroll then tri(cx + 0.5, bottom - 5 + bob, false, dark) end
    love.graphics.pop()
  end

  local function draw(...)
    local list = PartyMenu.ACTIONS
    local total = type(list) == "table" and #list or 0
    if P.broken or not (PartyMenu.open and PartyMenu.mode == "action" and total > VISIBLE) then
      return P.orig.draw(...)
    end
    for i = 1, total do if type(list[i]) ~= "string" then return P.orig.draw(...) end end

    local cur = PartyMenu.actionCursor or 1
    local maxScroll = total - VISIBLE
    if cur <= P.scroll then P.scroll = cur - 1 end
    if cur > P.scroll + VISIBLE then P.scroll = cur - VISIBLE end
    P.scroll = math.max(0, math.min(P.scroll, maxScroll))

    local slice = {}
    for i = 1, VISIBLE do slice[i] = list[P.scroll + i] end
    local texts = PartyMenu._actionTexts
    local own = textsFor(list)
    if own then
      local sub = {}
      for i = 1, VISIBLE do sub[i] = own.texts[P.scroll + i] end
      PartyMenu._actionTexts = { list = slice, texts = sub }
    end
    PartyMenu.ACTIONS = slice
    PartyMenu.actionCursor = cur - P.scroll
    lastFrame, P.capturing = nil, true
    local ok, err = pcall(P.orig.draw, ...)
    P.capturing = false
    PartyMenu.ACTIONS = list
    PartyMenu.actionCursor = cur
    PartyMenu._actionTexts = texts
    if not ok then
      -- never leave a blank menu: stop scrolling and let the game draw it
      P.broken = true
      if ctx.mod.log then ctx.mod.log:warn("party scroll disabled: %s", tostring(err)) end
      return P.orig.draw(...)
    end

    local okS, errS = pcall(drawScroll, total, P.scroll)
    if not okS and ctx.mod.log then ctx.mod.log:warn("party scroll: %s", tostring(errS)) end
  end

  function P.install()
    if P.installed then return end
    PartyMenu = require("src.ui.game3.party_menu")
    Chrome = require("src.ui.game3.chrome")
    FrlgFont = require("src.ui.game3.frlg_font")
    P.installed = true
    P.orig = { handleInput = PartyMenu.handleInput, draw = PartyMenu.draw, show = PartyMenu.show,
      update = PartyMenu.update }

    capture("stdFrame")
    capture("fixedStdFrame")
    capture("userFrame")

    PartyMenu.show = function(...)
      P.scroll, P.fieldList = 0, nil
      return P.orig.show(...)
    end
    PartyMenu.handleInput = function(input, ...)
      local args = { ... }
      local ok, err = pcall(handleInput, input, (table.unpack or unpack)(args))
      if not ok and ctx.mod.log then ctx.mod.log:warn("party input: %s", tostring(err)) end
    end
    -- other mods may add rows during update (Wilds of Hoenn's ROLE): put them in place
    if type(P.orig.update) == "function" then
      PartyMenu.update = function(...)
        local before = PartyMenu.mode
        local a, b, c = P.orig.update(...)
        pcall(track, before)
        return a, b, c
      end
    end
    PartyMenu.draw = function(...)
      -- a mod wrapping update after us still edits the list before it's drawn
      pcall(track, PartyMenu.mode)
      return draw(...)
    end
  end

  return P
end
