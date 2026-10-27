-- Drawing for the grid Start Menu and the Sort Menu (240x160 GBA space).
-- Look: Gen V dark panels + Gen VI rounded buttons and round icon badges.
return function(ctx)
  local D = {}
  local L = ctx.layout
  local S = ctx.settings
  local Themes = ctx.themes

  local FrlgFont = require("src.ui.game3.frlg_font")
  local CLEAR = FrlgFont.STDPAL[0]
  local WHITE_TEXT = { fg = { 1, 1, 1, 1 }, shadow = { 0.18, 0.18, 0.22, 1 }, bg = CLEAR }
  local BAR_TEXT = { fg = { 1, 1, 1, 1 }, shadow = { 0, 0, 0, 0.45 }, bg = CLEAR }

  local function setc(c, a)
    love.graphics.setColor(c[1], c[2], c[3], a or c[4] or 1)
  end

  local function now()
    local ok, t = pcall(function() return love.timer.getTime() end)
    return ok and t or os.clock()
  end

  -- ------- icons (built once from the 14x14 maps)

  local icons = {}
  local function icon(id)
    if icons[id] ~= nil then return icons[id] or nil end
    local set = ctx.iconMaps
    local map = set.icons[id] or set.icons.mods
    local size = set.size or 16
    local ok, img = pcall(function()
      local data = love.image.newImageData(size, size)
      for y, row in ipairs(map) do
        for x = 1, #row do
          local c = set.palette[row:sub(x, x)]
          if c then data:setPixel(x - 1, y - 1, c[1], c[2], c[3], 1) end
        end
      end
      local image = love.graphics.newImage(data)
      image:setFilter("nearest", "nearest")
      return image
    end)
    icons[id] = ok and img or false
    return ok and img or nil
  end

  -- ------- theme

  function D.theme(session)
    return (Themes.resolve(S.themeChoice(session), S.version(session)))
  end

  -- ------- clock text

  local WDAY = { "Sun.", "Mon.", "Tue.", "Wed.", "Thu.", "Fri.", "Sat." }

  local function deviceClock()
    local t = os.date("*t")
    return string.format("%s %04d-%02d-%02d %02d:%02d",
      WDAY[t.wday] or "", t.year, t.month, t.day, t.hour, t.min)
  end

  local function gameClock(session)
    local ok, text = pcall(function()
      local Rtc = require("src.core.game3.rtc")
      if not Rtc.enabled(session) then return nil end
      local info = Rtc.getInfo(session)
      local offset = (type(session) == "table" and session.localTimeOffset) or Rtc.newTime(0, 0, 0, 0)
      local t = Rtc.calcTimeDifferenceRtc(info, offset)
      return string.format("In-Game  Day %d  %02d:%02d", tonumber(t.days) or 0,
        tonumber(t.hours) or 0, tonumber(t.minutes) or 0)
    end)
    return ok and text or nil
  end

  -- FireRed/LeafGreen: device clock. Hoenn: alternates device / in-game every 5s.
  function D.clockText(session)
    if S.isHoenn(session) and math.floor(now() / 5) % 2 == 1 then
      local g = gameClock(session)
      if g then return g end
    end
    return deviceClock()
  end

  -- ------- frame

  function D.background(theme)
    setc(theme.dark)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    -- grid pattern (Gen V notebook), tinted with the theme so it shows on every theme
    setc(theme.light, 0.16)
    for y = L.TOP_BAR + 8, 160, 8 do love.graphics.rectangle("fill", 0, y, 240, 1) end
    setc(theme.light, 0.10)
    for x = 4, 240, 8 do love.graphics.rectangle("fill", x, L.TOP_BAR, 1, 160 - L.TOP_BAR) end
    -- top bar
    setc(theme.main)
    love.graphics.rectangle("fill", 0, 0, 240, L.TOP_BAR)
    love.graphics.setColor(1, 1, 1, 0.18)
    love.graphics.rectangle("fill", 0, 0, 240, 1)
    setc(theme.light)
    love.graphics.rectangle("fill", 0, L.TOP_BAR - 1, 240, 1)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, L.TOP_BAR, 240, 1)
  end

  function D.barText(left, right)
    if left and left ~= "" then
      FrlgFont.draw(left, 5, 1, { colors = BAR_TEXT })
    end
    if right and right ~= "" then
      local ok, w = pcall(FrlgFont.measure, right, { small = true })
      w = ok and tonumber(w) or (#right * 5)
      FrlgFont.draw(right, 235 - w, 2, { colors = BAR_TEXT, small = true })
    end
    love.graphics.setColor(1, 1, 1, 1)
  end

  -- ------- tiles

  local BODY = { 0.10, 0.10, 0.13 }
  local BODY_SEL = { 0.18, 0.18, 0.23 }
  local EDGE = { 0.42, 0.42, 0.50 }

  -- state: { selected = bool, held = bool, lifted = bool }
  function D.tile(slot, index, theme, state)
    local x, y, w, h = L.rect(index)
    state = state or {}
    if state.lifted then y = y - 2 end
    local r = 6
    love.graphics.setColor(0, 0, 0, 0.40)
    love.graphics.rectangle("fill", x + 1, y + 2, w, h, r, r)
    setc(state.selected and BODY_SEL or BODY, 0.97)
    love.graphics.rectangle("fill", x, y, w, h, r, r)
    love.graphics.setColor(1, 1, 1, 0.06) -- Gen VI gloss
    love.graphics.rectangle("fill", x + 2, y + 2, w - 4, math.floor(h / 2) - 2, r - 2, r - 2)
    love.graphics.setLineWidth(1)
    setc(state.selected and theme.light or EDGE)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1, r, r)
    if state.selected or state.held then
      local pulse = 0.55 + 0.45 * math.abs(math.sin(now() * 3))
      love.graphics.setLineWidth(2)
      setc(state.held and theme.light or theme.main, pulse)
      love.graphics.rectangle("line", x - 1, y - 1, w + 2, h + 2, r + 1, r + 1)
      love.graphics.setLineWidth(1)
    end
    -- coloured icon
    local img = icon(slot.extra and "mods" or slot.id)
    if img then
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(img, x + 6, y + math.floor((h - 16) / 2))
    end
    FrlgFont.draw(slot.label or "", x + 27, y + 5, { colors = WHITE_TEXT })
    love.graphics.setColor(1, 1, 1, 1)
  end

  function D.grid(slots, cursor, theme, opts)
    opts = opts or {}
    for i = 1, L.SLOTS do
      local slot = slots[i]
      if slot then
        local held = opts.held == i
        D.tile(slot, i, theme, {
          selected = (i == cursor) and not held,
          held = held, lifted = held,
        })
      end
    end
  end

  -- ------- native "RETURN TO MAIN MENU?" prompt, drawn over the grid
  function D.exitPrompt(StartMenu)
    local Chrome = require("src.ui.game3.chrome")
    local Window = require("src.ui.game3.window")
    local RomText = require("src.core.game3.rom_text")
    local okS, Strings = pcall(require, "src.core.Strings")
    local text = "RETURN TO MAIN\nMENU?"
    if okS and type(Strings) == "function" then text = Strings(text) end
    love.graphics.setColor(1, 1, 1, 1)
    Chrome.dialogueFrame()
    FrlgFont.draw(text, 2 * 8 + 4, 15 * 8 + 2, { linePitch = 15, colors = FrlgFont.COLOR.NORMAL })
    local popX, popY = 21, 9
    local d = StartMenu._data
    if d and d.drawCursor then
      Window.stdFrame(Window.template(popX, popY, 5, 4))
      local cur = StartMenu._confirmCursor == 1 and 0 or 1
      FrlgFont.draw(RomText.plain("gText_Yes"), popX * 8, popY * 8, { colors = FrlgFont.COLOR.NORMAL })
      FrlgFont.draw(RomText.plain("gText_No"), popX * 8, popY * 8 + 16, { colors = FrlgFont.COLOR.NORMAL })
      require("src.ui.game3.rs.menu_cursor").draw(popX * 8, popY * 8 + cur * 16, 40)
      return
    end
    Window.stdFrame(Window.template(popX, popY, 6, 4))
    local rowY1, rowY2 = popY * 8 + 2, popY * 8 + 18
    Window.cursorPx(popX * 8 + 1, (StartMenu._confirmCursor == 1) and rowY1 or rowY2)
    FrlgFont.draw(RomText.plain("gText_Yes"), popX * 8 + 9, rowY1, { colors = FrlgFont.COLOR.NORMAL })
    FrlgFont.draw(RomText.plain("gText_No"), popX * 8 + 9, rowY2, { colors = FrlgFont.COLOR.NORMAL })
  end

  return D
end
