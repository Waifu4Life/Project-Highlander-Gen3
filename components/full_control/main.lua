-- Full Control sub-menu (same as Project Highlander Gen 1/2, plus L and R).
--
-- While ENABLE is On, these binds replace the game's own button map
-- completely (keyboard, gamepad and raw joystick) and the stock
-- OPTIONS > CONTROLS page is hidden. Each button has one key and one pad
-- control; A on a row waits for a key or pad press (DELETE clears the row).
-- LEFT / RIGHT ANALOG FOR D-PAD make a stick walk. SELECT VISUAL COMBOS
-- (On) keeps the game's SELECT + face/shoulder display shortcuts; Off lets
-- those buttons act normally while SELECT is held.
return function(ctx)
  local S = ctx.settings
  local F = { installed = false }

  local function req(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
    return nil
  end

  -- controller order (rows are listed this way, not alphabetically)
  F.ROWS = {
    { id = "up", action = "up", label = "UP BUTTON", key = "up", pad = "dpup" },
    { id = "down", action = "down", label = "DOWN BUTTON", key = "down", pad = "dpdown" },
    { id = "left", action = "left", label = "LEFT BUTTON", key = "left", pad = "dpleft" },
    { id = "right", action = "right", label = "RIGHT BUTTON", key = "right", pad = "dpright" },
    { id = "a", action = "a", label = "A BUTTON", key = "z", pad = "a" },
    { id = "b", action = "b", label = "B BUTTON", key = "x", pad = "b" },
    { id = "start", action = "start", label = "START BUTTON", key = "escape", pad = "start" },
    { id = "select", action = "select", label = "SELECT BUTTON", key = "tab", pad = "back" },
    { id = "l", action = "l", label = "L BUTTON", key = "q", pad = "leftshoulder" },
    { id = "r", action = "r", label = "R BUTTON", key = "e", pad = "rightshoulder" },
    { id = "speedp", action = "speedUp", label = "SPEED+ BUTTON", key = "1", pad = "triggerright", speed = 1 },
    { id = "speedm", action = "speedDown", label = "SPEED- BUTTON", key = "0", pad = "triggerleft", speed = -1 },
  }

  function F.enabled() return S.get("fullctl_enabled") ~= false end
  local function analogLeft() return S.get("fullctl_analog_left") ~= false end
  local function analogRight() return S.get("fullctl_analog_right") == true end
  local function combos() return S.get("fullctl_select_combos") ~= false end

  local function bindOf(row)
    local k, p = S.get("fc_" .. row.id .. "_key"), S.get("fc_" .. row.id .. "_pad")
    if type(k) ~= "string" then k = row.key end
    if type(p) ~= "string" then p = row.pad end
    return k, p
  end

  -- ------------------------------------------------------------- labels

  local KEY_SHORT = {
    escape = "ESC", backspace = "BKSP", ["return"] = "ENTER", kpenter = "ENTER",
    space = "SPACE", rshift = "RSHIFT", lshift = "LSHIFT", lctrl = "LCTRL",
    rctrl = "RCTRL", lalt = "LALT", ralt = "RALT", up = "UP", down = "DOWN",
    left = "LEFT", right = "RIGHT", tab = "TAB",
  }
  local PAD_SHORT = {
    dpup = "D-UP", dpdown = "D-DN", dpleft = "D-LT", dpright = "D-RT",
    leftshoulder = "LB", rightshoulder = "RB", leftstick = "LS", rightstick = "RS",
    triggerleft = "LT", triggerright = "RT", back = "BACK", start = "START",
    guide = "GUIDE", a = "A", b = "B", x = "X", y = "Y",
    leftstick_up = "LS-U", leftstick_down = "LS-D", leftstick_left = "LS-L", leftstick_right = "LS-R",
    rightstick_up = "RS-U", rightstick_down = "RS-D", rightstick_left = "RS-L", rightstick_right = "RS-R",
    misc1 = "MISC", paddle1 = "P1", paddle2 = "P2", paddle3 = "P3", paddle4 = "P4",
    touchpad = "TPAD",
  }
  local function short(v, map)
    if not v or v == "" then return nil end
    local n = v:match("^joy(%d+)$")
    if n then return "JOY" .. n end
    return map[v] or v:upper():sub(1, 6)
  end

  function F.label(row)
    local k, p = bindOf(row)
    local ks, ps = short(k, KEY_SHORT), short(p, PAD_SHORT)
    if not ks and not ps then return "NONE" end
    if not ps then return "KEY " .. ks end
    if not ks then return "PAD " .. ps end
    return ks .. " / " .. ps
  end

  -- ------------------------------------------------------------- applying

  local POLLABLE = {
    a = true, b = true, x = true, y = true, back = true, guide = true, start = true,
    leftstick = true, rightstick = true, leftshoulder = true, rightshoulder = true,
    dpup = true, dpdown = true, dpleft = true, dpright = true,
    triggerleft = true, triggerright = true,
    leftstick_up = true, leftstick_down = true, leftstick_left = true, leftstick_right = true,
    rightstick_up = true, rightstick_down = true, rightstick_left = true, rightstick_right = true,
    misc1 = true, paddle1 = true, paddle2 = true, paddle3 = true, paddle4 = true,
    touchpad = true,
  }

  local function liveInput()
    local g = S.game and S.game()
    if g and g.input then return g, g.input end
    return g, req("src.core.Input")
  end

  -- replace whatever applyBindings built with our map only
  local function override(input)
    local GM = req("src.core.GamepadMap")
    local function norm(b)
      if GM and GM.normalizePad then return GM.normalizePad(b) or b end
      return b
    end
    local keys, pads, acts, explicit, joys, joyActs = {}, {}, {}, {}, {}, {}
    for _, row in ipairs(F.ROWS) do
      local k, p = bindOf(row)
      local jn = p ~= "" and tonumber(p:match("^joy(%d+)$")) or nil
      if row.speed then
        if jn then joyActs[jn] = row.action
        elseif p ~= "" then
          local b = norm(p)
          acts[b], explicit[b] = row.action, true
        end
      else
        if k ~= "" then keys[k] = row.action end
        if jn then joys[jn] = row.action
        elseif p ~= "" then pads[norm(p)] = row.action end
      end
    end
    for b in pairs(acts) do pads[b] = nil end
    local sticks = {}
    for _, d in ipairs({ "up", "down", "left", "right" }) do
      if analogLeft() then sticks["leftstick_" .. d], sticks["ls" .. d] = d, d end
      if analogRight() then sticks["rightstick_" .. d], sticks["rs" .. d] = d, d end
    end
    for b in pairs(pads) do sticks[b] = nil end
    for b in pairs(acts) do sticks[b] = nil end
    local poll = {}
    local canPoll = not (GM and GM.gamepadBindings and GM.NX_GAMEPAD_BINDINGS
      and GM.gamepadBindings() == GM.NX_GAMEPAD_BINDINGS)
    for b, action in pairs(pads) do
      if canPoll and POLLABLE[b] then
        local chord = false
        if combos() and GM and GM.displayChordDigit then chord = GM.displayChordDigit(b) ~= nil end
        poll[#poll + 1] = { button = b, btn = action, source = "pad:" .. b, chord = chord }
      end
    end
    input.keyBindings, input.padBindings, input.joyBindings = keys, pads, joys
    input.padActions, input.explicitPadActions, input.joyActions = acts, explicit, joyActs
    input.padPoll = poll
    input.effectiveStickBindings = sticks
    input.stickDir, input.rightStickDir = nil, nil
  end

  local applying = false
  function F.apply()
    local game, input = liveInput()
    if not (input and input.applyBindings) then return end
    applying = true
    -- stock first (also what Off goes back to), then ours on top when On
    local opts = game and type(game.options) == "table" and game.options or nil
    pcall(input.applyBindings, input, opts and opts.bindings or nil)
    applying = false
    if F.enabled() then pcall(override, input) end
  end

  -- ------------------------------------------------------------- capture

  local Cap = { isMenu = true, open = false }
  F.capture = Cap
  local CAP_ID = "ph3_fullctl_capture"

  local function store(row, field, value)
    S.set("fc_" .. row.id .. "_" .. field, value)
  end

  function Cap.show(row)
    local _, input = liveInput()
    if not (input and input.armCapture) then return end
    Cap.row, Cap.input, Cap.down, Cap.open = row, input, nil, true
    input:armCapture()
    require("src.ui.game3.stack").push(CAP_ID, Cap, { hideBelow = false })
  end

  local function finish(kind, value)
    local row, input = Cap.row, Cap.input
    Cap.open = false
    if kind == "clear" then
      store(row, "key", "")
      store(row, "pad", "")
    elseif kind == "key" then
      store(row, "key", value)
    elseif kind == "pad" then
      store(row, "pad", value)
    end
    if input then
      pcall(input.disarmCapture, input)
      if input.reset then pcall(input.reset, input) end
    end
    require("src.ui.game3.stack").pop(CAP_ID)
    pcall(function() require("src.core.game3.audio").playSe(5) end)
    F.apply()
  end

  local function skipPad(v)
    if analogLeft() and (v:find("^leftstick_") or v:find("^ls%a")) then return true end
    if analogRight() and (v:find("^rightstick_") or v:find("^rs%a")) then return true end
    return false
  end

  -- set on release (like the stock Controls page), so the press can't also
  -- reach the menu underneath
  function Cap.handleInput(input)
    if not Cap.open then return end
    input = Cap.input or input
    local take = input and input.takeCaptureEvents
    local ev = take and input:takeCaptureEvents()
    if type(ev) ~= "table" then return end
    for _, e in ipairs(ev) do
      local kind = e.kind == "joy" and "pad" or e.kind
      local value = e.kind == "joy" and ("joy" .. tostring(e.value)) or tostring(e.value)
      if kind == "key" and (value == "delete" or value == "kpdelete") then
        if e.phase == "pressed" then return finish("clear") end
      elseif (kind == "key" or kind == "pad") and not (kind == "pad" and skipPad(value)) then
        if e.phase == "pressed" and not Cap.down then
          Cap.down = { kind = kind, value = value }
        elseif e.phase == "released" and Cap.down
            and Cap.down.kind == kind and Cap.down.value == value then
          return finish(kind, value)
        end
      end
    end
  end

  function Cap.update() end

  function Cap.draw()
    if not Cap.open then return end
    local Chrome = req("src.ui.game3.chrome")
    local Window = req("src.ui.game3.window")
    local FrlgFont = req("src.ui.game3.frlg_font")
    if not (Chrome and Window) then return end
    local colors = FrlgFont and FrlgFont.COLOR and FrlgFont.COLOR.NORMAL
    Chrome.stdFrame(5, 9, 20, 6)
    local x, y = 5 * 8 + 4, 9 * 8 + 2
    Window.printPx("PRESS A KEY OR", x, y, { colors = colors })
    Window.printPx("GAMEPAD BUTTON", x, y + 15, { colors = colors })
    Window.printPx("DELETE CLEARS", x, y + 30, { colors = colors })
  end

  -- ------------------------------------------------------------- install

  function F.install()
    -- runs again on game.ready: re-apply with the loaded options
    if F.installed then return pcall(F.apply) end
    local Input = require("src.core.Input")
    local Game3 = require("src.core.Game3")
    F.installed = true

    -- every rebuild of the stock map (options load, CONTROLS commit...) is
    -- followed by ours while Full Control is On
    local origApply = Input.applyBindings
    Input.applyBindings = function(self, ...)
      local r = origApply(self, ...)
      if not applying and F.enabled() then pcall(override, self) end
      return r
    end

    -- SELECT VISUAL COMBOS Off: SELECT + a pad button never runs a display hotkey
    local origPad = Game3._padPressedBody
    Game3._padPressedBody = function(self, joystick, button, ...)
      if not (F.enabled() and not combos()) then return origPad(self, joystick, button, ...) end
      local GM = require("src.core.GamepadMap")
      local digit = GM.displayChordDigit
      GM.displayChordDigit = function() return nil end
      local ok, err = pcall(origPad, self, joystick, button, ...)
      GM.displayChordDigit = digit
      if not ok then error(err, 0) end
    end

    -- keyboard SPEED+ / SPEED- keys
    local origKey = Game3.keypressed
    Game3.keypressed = function(self, key, ...)
      local input = self and self.input
      if F.enabled() and not (input and input.captureArmed) then
        for _, row in ipairs(F.ROWS) do
          if row.speed then
            local k = bindOf(row)
            if k ~= "" and k == key and self._cycleSpeed then
              self:_cycleSpeed(row.speed)
              return
            end
          end
        end
      end
      return origKey(self, key, ...)
    end

    F.apply()
  end

  return F
end
