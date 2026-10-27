-- QOL > DISPLAY XP IN PARTY MENU (all five Gen 3 games, single party layout).
--   * Main (first) Pokémon: its box is taller; under the HP numbers comes an XP
--     bar and the XP numbers (XP into this level / XP this level needs).
--   * The other five: the HP numbers make room for an XP bar under the HP bar.
-- The XP frame is a copy of the game's own HP frame (from the slot picture),
-- relabelled "XP", with a blue fill. Drawn right after each slot, before the
-- menus and message boxes, so those still cover it.
return function(ctx)
  local X = { installed = false }
  local S = ctx.settings
  local PartyMenu, PartyChrome, Chrome, FrlgFont, SummaryData, Window, Display

  local EXTRA = 16 -- px the main box grows
  local STRETCH_ROW = 44 -- a plain row of the main box picture (below the HP numbers)
  -- pret sPartyBoxInfoRects: HP bar fill position inside each slot
  local FILL = { main = { 24, 35 }, wide = { 88, 10 } }
  local FILL_W = 48
  local BLUE_TOP = { 0.47, 0.85, 0.98, 1 }
  local BLUE = { 0.22, 0.63, 0.93, 1 }

  local function enabled()
    return S.flag("party_xp") and PartyMenu.open and PartyMenu._layout ~= "double"
      and PartyMenu.mode ~= "summary" and PartyMenu.mode ~= "oak"
  end

  -- ------- reading the slot pictures (once per picture)

  local cache = setmetatable({}, { __mode = "k" })

  local function lum(r, g, b) return 0.30 * r + 0.59 * g + 0.11 * b end
  local function isOrange(r, g, b) return r > 0.6 and g > 0.3 and r > b + 0.3 end

  local function imageData(entry)
    local w, h = entry.w or entry.image:getWidth(), entry.h or entry.image:getHeight()
    local canvas = love.graphics.newCanvas(w, h)
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.origin()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(entry.image, 0, 0)
    love.graphics.pop()
    return canvas:newImageData(), w, h
  end

  -- find the HP frame (dark outline) around the fill position, and the H of "HP"
  local function analyse(entry, kind)
    local data, w, h = imageData(entry)
    local fx, fy = FILL[kind][1], FILL[kind][2]
    local x0, x1 = math.max(0, fx - 22), math.min(w - 1, fx + FILL_W + 6)
    local y0, y1 = math.max(0, fy - 5), math.min(h - 1, fy + 7)
    local L, T, R, B
    for y = y0, y1 do
      for x = x0, x1 do
        local r, g, b, a = data:getPixel(x, y)
        if a > 0.5 and lum(r, g, b) < 0.38 then
          L = math.min(L or x, x); R = math.max(R or x, x)
          T = math.min(T or y, y); B = math.max(B or y, y)
        end
      end
    end
    if not (L and R - L >= FILL_W and B - T >= 3 and B - T <= 10) then return nil end
    local info = { L = L, T = T, W = R - L + 1, H = B - T + 1, fillDX = fx - L, fillDY = fy - T }

    -- the label: orange pixels left of the fill; the left letter is the H
    local cols = {}
    local oL, oT, oB
    for x = L, fx - 1 do
      for y = T, B do
        local r, g, b, a = data:getPixel(x, y)
        if a > 0.5 and isOrange(r, g, b) then
          cols[x] = true
          oL = math.min(oL or x, x); oT = math.min(oT or y, y); oB = math.max(oB or y, y)
        end
      end
    end
    if not oL then return info end
    local oR = oL
    for x = oL, fx - 1 do if cols[x] then oR = x end end
    local hR = oL
    while cols[hR + 1] do hR = hR + 1 end -- H ends at the first gap
    if hR - oL + 1 > math.ceil((oR - oL + 1) * 0.6) then
      hR = oL + math.floor((oR - oL + 1) / 2) - 1 -- letters touch: take the left half
    end
    local hx0, hx1 = oL, hR
    -- colours: orange from the H, background = most common non-orange pixel in its box
    local counts, orange = {}, nil
    for x = hx0, hx1 do
      for y = oT, oB do
        local r, g, b = data:getPixel(x, y)
        if isOrange(r, g, b) then
          orange = orange or { r, g, b, 1 }
        else
          local k = string.format("%.2f,%.2f,%.2f", r, g, b)
          counts[k] = (counts[k] or 0) + 1
        end
      end
    end
    local bg, best = nil, 0
    for k, n in pairs(counts) do
      if n > best then
        best = n
        local r, g, b = k:match("([^,]+),([^,]+),([^,]+)")
        bg = { tonumber(r), tonumber(g), tonumber(b), 1 }
      end
    end
    -- stroke width of the H's left leg
    local stroke = 0
    for x = hx0, hx1 do
      local r, g, b = data:getPixel(x, oT)
      if isOrange(r, g, b) then stroke = stroke + 1 else break end
    end
    info.letter = { x = hx0 - L, y = oT - T, w = hx1 - hx0 + 1, h = oB - oT + 1,
      stroke = math.max(1, math.min(2, stroke)), orange = orange, bg = bg or { 0.29, 0.29, 0.35, 1 } }
    return info
  end

  local function frameInfo(entry, kind)
    if not (entry and entry.image) then return nil end
    local c = cache[entry]
    if c == nil then
      local ok, info = pcall(analyse, entry, kind)
      c = ok and info or false
      cache[entry] = c
      if not ok and ctx.mod.log then ctx.mod.log:warn("party xp analyse: %s", tostring(info)) end
    end
    return c or nil
  end

  local function slotEntry(kind, selected)
    if kind == "main" then return selected and PartyChrome._slotMainSel or PartyChrome._slotMain end
    return selected and PartyChrome._slotWideSel or PartyChrome._slotWide
  end

  -- ------- drawing

  local function setColor(c) love.graphics.setColor(c[1], c[2], c[3], c[4] or 1) end

  local function drawX(px, py, letter)
    setColor(letter.bg)
    love.graphics.rectangle("fill", px, py, letter.w, letter.h)
    setColor(letter.orange or { 0.97, 0.69, 0.19, 1 })
    local w, h, t = letter.w, letter.h, letter.stroke
    for r = 0, h - 1 do
      local a = (h > 1) and math.floor(r * (w - t) / (h - 1) + 0.5) or 0
      love.graphics.rectangle("fill", px + a, py + r, t, 1)
      love.graphics.rectangle("fill", px + (w - t) - a, py + r, t, 1)
    end
  end

  local function drawFill(x, y, pct)
    local w = math.floor(FILL_W * math.max(0, math.min(1, pct)) + 0.5)
    if w <= 0 then return end
    setColor(BLUE_TOP)
    love.graphics.rectangle("fill", x, y, w, 1)
    setColor(BLUE)
    love.graphics.rectangle("fill", x, y + 1, w, 2)
  end

  -- an XP frame whose fill starts at (fillX, fillY) on screen
  -- Where the XP frame is copied from. The highlighted FIRST box is the reliable
  -- source: it is on screen as soon as the party opens (the cursor starts there)
  -- and its HP frame is the same art as the small boxes' (66 px: label + 48 px bar).
  -- Order: highlighted first box, highlighted small box, a highlighted first box
  -- loaded off-screen, then (last resort) the box's own picture.
  local function usable(entry, kind)
    return entry and entry.image and frameInfo(entry, kind) ~= nil
  end

  local function sourceEntry(kind)
    if usable(PartyChrome._slotMainSel, "main") then return PartyChrome._slotMainSel, "main" end
    if usable(PartyChrome._slotWideSel, "wide") then return PartyChrome._slotWideSel, "wide" end
    pcall(function()
      local canvas = love.graphics.newCanvas(160, 64)
      love.graphics.push("all")
      love.graphics.setCanvas(canvas)
      X.origSlot("main", 0, 0, true)
      love.graphics.pop()
    end)
    if usable(PartyChrome._slotMainSel, "main") then return PartyChrome._slotMainSel, "main" end
    return slotEntry(kind, false), kind
  end

  -- the frame without its four corner pixels, so the box behind shows there
  local function frameQuads(info, image)
    if info.quads then return info.quads end
    local iw, ih = image:getDimensions()
    local L, T, W, H = info.L, info.T, info.W, info.H
    info.quads = {
      { love.graphics.newQuad(L + 1, T, W - 2, 1, iw, ih), 1, 0 },
      { love.graphics.newQuad(L, T + 1, W, H - 2, iw, ih), 0, 1 },
      { love.graphics.newQuad(L + 1, T + H - 1, W - 2, 1, iw, ih), 1, H - 1 },
    }
    return info.quads
  end

  local function xpBar(_, kind, fillX, fillY, pct)
    local entry, fromKind = sourceEntry(kind)
    local info = frameInfo(entry, fromKind)
    love.graphics.push("all")
    if info then
      local dx, dy = fillX - info.fillDX, fillY - info.fillDY
      love.graphics.setColor(1, 1, 1, 1)
      for _, q in ipairs(frameQuads(info, entry.image)) do
        love.graphics.draw(entry.image, q[1], dx + q[2], dy + q[3])
      end
      if info.letter then drawX(dx + info.letter.x, dy + info.letter.y, info.letter) end
    else
      -- no picture to copy: a plain frame in the same spirit
      love.graphics.setColor(0.29, 0.29, 0.35, 1)
      love.graphics.rectangle("fill", fillX - 16, fillY - 2, FILL_W + 18, 7, 2, 2)
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.rectangle("fill", fillX, fillY, FILL_W, 3)
      pcall(FrlgFont.draw, "XP", fillX - 15, fillY - 6,
        { small = true, colors = { fg = { 0.97, 0.69, 0.19, 1 }, shadow = { 0.55, 0.35, 0.10, 1 }, bg = FrlgFont.STDPAL[0] } })
    end
    drawFill(fillX, fillY, pct)
    love.graphics.pop()
  end

  local function progress(mon)
    local ok, p = pcall(SummaryData.expProgress, mon)
    if ok and type(p) == "table" then return p end
  end

  -- ------- per-slot state during one PartyMenu.draw

  local frame = nil -- { index, pending, mainNums }

  local function finishSlot()
    local s = frame and frame.pending
    if not s then return end
    frame.pending = nil
    local mon = PartyMenu._party and PartyMenu._party[s.index]
    if type(mon) ~= "table" then return end
    local p = progress(mon)
    if not p then return end
    local pct = (p.level or 1) >= 100 and 1 or (p.progressPercent or 0)
    local entry = slotEntry(s.kind, s.selected)
    if s.kind == "main" then
      local fx, fy = s.px + FILL.main[1], s.py + FILL.main[2] + EXTRA
      xpBar(entry, "main", fx, fy, pct)
      -- numbers right-aligned under the bar, like the HP numbers above
      local nums = frame.mainNums
      local opts = {}
      for k, v in pairs((nums and nums.opts) or { small = true, colors = FrlgFont.COLOR.PARTY }) do opts[k] = v end
      opts.maxWidth = 120 -- the HP numbers are clipped to 24 px; ours need the room
      local text = (p.level or 1) >= 100 and "MAX"
        or string.format("%d/%d", tonumber(p.expProgress) or 0, tonumber(p.levelTotalExp) or 0)
      local okW, w = pcall(FrlgFont.measure, text, opts)
      local right = (nums and nums.right) or (fx + FILL_W + 2)
      local y = (nums and nums.y or (s.py + 36)) + EXTRA
      love.graphics.push("all")
      pcall(FrlgFont.draw, text, right - ((okW and tonumber(w)) or #text * 5), y, opts)
      love.graphics.pop()
    else
      -- Wipe the HP-number area first by redrawing the box's own picture there.
      -- FireRed/LeafGreen numbers are skipped anyway; Ruby/Sapphire/Emerald draw
      -- theirs another way, and their bottom row peeked out under the XP bar.
      if entry and entry.image then
        pcall(function()
          local iw, ih = entry.image:getDimensions()
          local x0, y0 = FILL.wide[1] - 16, FILL.wide[2] + 5
          if iw > x0 and ih > y0 then
            entry._ph3Wipe = entry._ph3Wipe or love.graphics.newQuad(x0, y0, iw - x0, ih - y0, iw, ih)
            love.graphics.push("all")
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(entry.image, entry._ph3Wipe, s.px + x0, s.py + y0)
            love.graphics.pop()
          end
        end)
      end
      xpBar(entry, "wide", s.px + FILL.wide[1], s.py + FILL.wide[2] + 7, pct)
    end
  end

  -- the main box, EXTRA px taller: top part, one plain row stretched, bottom part
  local function drawTallMain(entry, px, py)
    local img = entry.image
    local w, h = img:getDimensions()
    if h <= STRETCH_ROW + 1 then return false end
    local R = STRETCH_ROW
    local q = entry._ph3TallQuads
    if not q then
      q = { love.graphics.newQuad(0, 0, w, R, w, h), love.graphics.newQuad(0, R, w, 1, w, h),
        love.graphics.newQuad(0, R, w, h - R, w, h) }
      entry._ph3TallQuads = q
    end
    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, q[1], px, py)
    love.graphics.draw(img, q[2], px, py + R, 0, 1, EXTRA + 1)
    love.graphics.draw(img, q[3], px, py + R + EXTRA)
    love.graphics.pop()
    return true
  end

  local function isHpNumber(text)
    if type(text) ~= "string" then return false end
    return text:match("^%s*%d+%s*/%s*$") or text:match("^%s*/%s*%d+%s*$")
      or text:match("^%s*%d+%s*/%s*%d+%s*$")
  end

  function X.install()
    if X.installed then return end
    PartyMenu = require("src.ui.game3.party_menu")
    PartyChrome = require("src.ui.game3.party_chrome")
    Chrome = require("src.ui.game3.chrome")
    FrlgFont = require("src.ui.game3.frlg_font")
    SummaryData = require("src.core.game3.summary_data")
    X.installed = true
    local T = 8

    local origSlot = PartyChrome.drawSlot
    X.origSlot = origSlot
    PartyChrome.drawSlot = function(kind, tileLeft, tileTop, selected, hideHp, ...)
      if not frame then return origSlot(kind, tileLeft, tileTop, selected, hideHp, ...) end
      pcall(finishSlot)
      frame.index = frame.index + 1
      local result = origSlot(kind, tileLeft, tileTop, selected, hideHp, ...)
      local px, py = (tonumber(tileLeft) or 0) * T, (tonumber(tileTop) or 0) * T
      if (kind == "main" or kind == "wide") and not hideHp then
        local s = { index = frame.index, kind = kind, px = px, py = py, selected = selected and true or false }
        if kind == "main" then
          local entry = slotEntry("main", s.selected)
          local ok, tall = pcall(drawTallMain, entry, px, py)
          if not (ok and tall) then s = nil end
        end
        frame.pending = s
      end
      frame.slotKind = (frame.pending and frame.pending.kind) or nil
      return result
    end

    local origDraw = FrlgFont.draw
    FrlgFont.draw = function(text, x, y, opts, ...)
      local f = frame
      if f and f.slotKind and isHpNumber(text) then
        if f.slotKind == "wide" then return 0 end
        -- main: remember where the HP numbers end, for the XP numbers
        local okW, w = pcall(FrlgFont.measure, text, opts)
        local right = (tonumber(x) or 0) + ((okW and tonumber(w)) or 0)
        f.mainNums = { right = math.max(right, f.mainNums and f.mainNums.right or 0), y = y, opts = opts }
      end
      return origDraw(text, x, y, opts, ...)
    end

    -- anything drawn after the slots (menus, message box, CANCEL) closes the last slot
    local function closer(mod, name)
      local orig = mod[name]
      if type(orig) ~= "function" then return end
      mod[name] = function(...)
        if frame and frame.pending then
          pcall(finishSlot)
          frame.slotKind = nil
        end
        return orig(...)
      end
    end
    closer(Chrome, "stdFrame"); closer(Chrome, "fixedStdFrame"); closer(Chrome, "userFrame")
    closer(Chrome, "dialogueFrame"); closer(PartyChrome, "drawCancelButton")
    closer(PartyChrome, "drawConfirmButton")

    local outer = PartyMenu.draw
    PartyMenu.draw = function(...)
      if not enabled() then return outer(...) end
      frame = { index = 0 }
      local ok, err = pcall(outer, ...)
      pcall(finishSlot)
      frame = nil
      if not ok then error(err, 0) end
    end
  end

  return X
end
