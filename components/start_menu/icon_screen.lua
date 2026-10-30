-- CUSTOM ICONS (OPTIONS > PROJECT HIGHLANDER > START MENU SETTINGS):
-- pick the icon other mods' Start Menu items show in the grid.
-- Page 1: the items (same tiles as the Start Menu). A opens the icon picker.
-- Picker: 8 x 4 coloured icon badges. A sets the icon, B goes back.
return function(ctx)
  local S, L, D = ctx.settings, ctx.layout, ctx.draw
  local Maps = ctx.iconMaps
  local Scr = { isMenu = true, open = false }

  local PCOLS, PROWS = 8, 4
  local PX0, PY0, PW, PH, PSTEP_X, PSTEP_Y = 6, 21, 26, 25, 29, 28

  local function se(id)
    pcall(function()
      require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").resolve(id))
    end)
  end

  -- items: those in the open Start Menu first, then every one seen before
  local function build()
    local list, seen = {}, {}
    local G = ctx.startMenu and ctx.startMenu.state
    if G and G.slots then
      for i = 1, L.total(G.slots) do
        local s = G.slots[i]
        if s and s.extra and not seen[s.iconKey] then
          seen[s.iconKey] = true
          list[#list + 1] = { label = s.label, entry = s.entry, iconKey = s.iconKey, extra = true }
        end
      end
    end
    for _, it in ipairs(S.iconItems()) do
      if not seen[it.key] then
        seen[it.key] = true
        list[#list + 1] = { label = it.label, iconKey = it.key, extra = true,
          entry = { label = it.label, id = it.key:match("^ID_(.+)$") } }
      end
    end
    local total = math.max(1, math.ceil(#list / L.PAGE)) * L.PAGE
    local slots = { total = total }
    for i = 1, total do slots[i] = list[i] or false end
    Scr._slots, Scr._count = slots, #list
  end

  function Scr.show(opts)
    opts = opts or {}
    Scr.open = true
    Scr._session = opts.session
    Scr._onClose = opts.onClose
    Scr._mode = "items"
    build()
    Scr.cursor = L.firstFilled(Scr._slots)
    require("src.ui.game3.stack").push("ph3_icons", Scr, { hideBelow = true, fullscreen = true })
    se("SE_WIN_OPEN")
  end

  function Scr.close()
    Scr.open = false
    require("src.ui.game3.stack").pop("ph3_icons")
    local cb = Scr._onClose
    Scr._onClose = nil
    se("SE_SELECT")
    if cb then pcall(cb) end
  end

  function Scr.isOpen() return Scr.open end

  local function current()
    return Scr._slots and Scr._slots[Scr.cursor] or nil
  end

  local function openPicker()
    local slot = current()
    if not slot then se("SE_FAILURE") return end
    Scr._mode = "pick"
    Scr._pick = 1
    local now = S.iconFor(slot.iconKey)
    for i, c in ipairs(Maps.choices) do
      if c[2] == now then Scr._pick = i break end
    end
    se("SE_SELECT")
  end

  local function pickInput(input)
    local n = #Maps.choices
    local i = Scr._pick
    local col, row = (i - 1) % PCOLS, math.floor((i - 1) / PCOLS)
    local rows = math.ceil(n / PCOLS)
    local before = i
    if input:wasPressed("left") then col = (col - 1) % PCOLS
    elseif input:wasPressed("right") then col = (col + 1) % PCOLS
    elseif input:wasPressed("up") then row = (row - 1) % rows
    elseif input:wasPressed("down") then row = (row + 1) % rows
    elseif input:wasPressed("a") then
      local slot, choice = current(), Maps.choices[i]
      if slot and choice then S.setIcon(slot.iconKey, choice[2]) end
      Scr._mode = "items"
      se("SE_SELECT")
      return
    elseif input:wasPressed("b") or input:wasPressed("start") then
      Scr._mode = "items"
      se("SE_SELECT")
      return
    end
    Scr._pick = math.min(n, row * PCOLS + col + 1)
    if Scr._pick ~= before then se("SE_SELECT") end
  end

  function Scr.handleInput(input)
    if not (input and Scr.open) then return end
    if Scr._mode == "pick" then return pickInput(input) end
    local before = Scr.cursor
    if Scr._count == 0 then
      if input:wasPressed("a") or input:wasPressed("b") or input:wasPressed("start") then Scr.close() end
      return
    end
    if input:wasPressed("up") then Scr.cursor = L.move(Scr._slots, Scr.cursor, 0, -1)
    elseif input:wasPressed("down") then Scr.cursor = L.move(Scr._slots, Scr.cursor, 0, 1)
    elseif input:wasPressed("left") then Scr.cursor = L.move(Scr._slots, Scr.cursor, -1, 0)
    elseif input:wasPressed("right") then Scr.cursor = L.move(Scr._slots, Scr.cursor, 1, 0)
    elseif input:wasPressed("a") then openPicker() return
    elseif input:wasPressed("select") then
      -- SELECT: back to AUTO
      local slot = current()
      if slot then S.setIcon(slot.iconKey, "auto") end
      se("SE_SELECT")
      return
    elseif input:wasPressed("b") or input:wasPressed("start") then
      Scr.close()
      return
    end
    if Scr.cursor ~= before then se("SE_SELECT") end
  end

  function Scr.update() end

  local function drawPicker(theme)
    local slot = current()
    D.barText(slot and slot.label or "ICON", "A Choose  B Back")
    local autoIcon = slot and D.autoIcon(tostring(slot.entry and slot.entry.id or "") .. " "
      .. tostring(slot.label or "") .. " " .. tostring(slot.iconKey or "")) or "mods"
    local chosen = slot and S.iconFor(slot.iconKey) or "auto"
    for i, c in ipairs(Maps.choices) do
      local col, row = (i - 1) % PCOLS, math.floor((i - 1) / PCOLS)
      local x, y = PX0 + col * PSTEP_X, PY0 + row * PSTEP_Y
      local id = c[2] == "auto" and autoIcon or c[2]
      D.badge(id, x, y, PW, PH, theme, i == Scr._pick)
      if c[2] == chosen then
        -- small dot on the icon in use
        love.graphics.setColor(theme.light[1], theme.light[2], theme.light[3], 1)
        love.graphics.circle("fill", x + PW - 4, y + 4, 2)
        love.graphics.setColor(1, 1, 1, 1)
      end
    end
    local c = Maps.choices[Scr._pick]
    local name = c and c[1] or ""
    if c and c[2] == "auto" then name = "AUTO (" .. (autoIcon:upper()) .. ")" end
    D.text(name, math.floor((240 - D.textWidth(name)) / 2), 143)
  end

  function Scr.draw()
    if not Scr.open then return end
    love.graphics.push("all")
    local theme = D.theme(Scr._session)
    D.background(theme)
    if Scr._mode == "pick" then
      drawPicker(theme)
    elseif Scr._count == 0 then
      D.barText("CUSTOM ICONS", "B Back")
      local a = "No items from other mods yet."
      local b = "Open the Start Menu once with them."
      D.text(a, math.floor((240 - D.textWidth(a)) / 2), 64)
      D.text(b, math.floor((240 - D.textWidth(b)) / 2), 80)
    else
      local page = D.pageText(Scr._slots, Scr.cursor)
      D.barText("CUSTOM ICONS", "A Choose  SELECT Auto" .. (page and ("  " .. page) or ""))
      D.grid(Scr._slots, Scr.cursor, theme)
    end
    love.graphics.pop()
  end

  return Scr
end
