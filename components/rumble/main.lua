-- Rumble sub-menu (Project Highlander Gen3's own; not the Gen 1/2 Controller Rumble).
--
-- The controller rumbles when a move hits in battle. It goes off on the game's
-- hit sound -- the moment the target blinks on screen -- so it's in time with
-- the hit. The sound is panned to the target's side, which tells whose
-- Pokémon was hit (singles and doubles).
--   * Not very effective: one light tap. Effective: one solid pulse.
--     Super effective: two strong pulses. No effect: no sound, so no rumble.
--   * INTENSITY changes both strength and length (Low / Medium / High).
--   * Your Pokémon hit: the left motor leads. You hit the foe: the right motor.
--   * Every connected controller that can rumble. With none (phone), the
--     device's own vibration is used on Android / iOS.
--
--   * Battle start: one pulse before a wild battle, two before a trainer
--     battle (as the battle transition starts).
--
-- Options (INTENSITY first, then alphabetical): BEFORE TRAINER BATTLE (On),
-- BEFORE WILD BATTLE (On), INTENSITY (Off / Low / Medium / High, Medium; Off
-- replaces the old ENABLE toggle), PRESS SELECT TO TEST (Not Very Effective /
-- Effective / Super Effective), WHEN I GET HIT (On), WHEN I HIT (On).
return function(ctx)
  local S = ctx.settings
  local R = { installed = false }

  -- Each intensity changes strength AND length: the Steam Deck's motors and
  -- most pads feel little difference in strength alone, and phone vibration
  -- only knows length.
  R.INTENSITIES = {
    { id = "off", label = "OFF", scale = 0, length = 0 },
    { id = "low", label = "LOW", scale = 0.40, length = 0.6 },
    { id = "medium", label = "MEDIUM", scale = 0.75, length = 1.0 },
    { id = "high", label = "HIGH", scale = 1.0, length = 1.6 },
  }

  local function intensityIndex()
    local v = S.get("rumble_intensity")
    -- saves from before 1.65.0: ENABLE Off becomes INTENSITY Off
    if S.get("rumble_enabled") == false then
      S.set("rumble_enabled", true)
      S.set("rumble_intensity", "off")
      v = "off"
    end
    for i, it in ipairs(R.INTENSITIES) do if it.id == v then return i end end
    return 3
  end
  local function enabled() return R.INTENSITIES[intensityIndex()].id ~= "off" end

  function R.intensityLabel()
    return R.INTENSITIES[intensityIndex()].label
  end

  function R.stepIntensity(dir)
    local i = intensityIndex()
    i = (i - 1 + (dir or 1)) % #R.INTENSITIES + 1
    S.set("rumble_intensity", R.INTENSITIES[i].id)
  end

  -- Each hit kind is a different pattern, not just a different strength:
  --   not very effective: one light, very short tap
  --   effective:          one solid pulse
  --   super effective:    a strong pulse, a short gap, then a second one
  -- pulses = { { strength (0-1), seconds, delay before it }, ... }
  local BY_NAME = {
    SE_NOT_EFFECTIVE = { id = 12, pulses = { { 0.30, 0.05, 0 } } },
    SE_EFFECTIVE = { id = 13, pulses = { { 0.70, 0.14, 0 } } },
    SE_SUPER_EFFECTIVE = { id = 14, pulses = { { 1.00, 0.16, 0 }, { 1.00, 0.24, 0.10 } } },
  }
  local PATTERN = {}

  local function clamp(v) return math.max(0, math.min(1, v)) end

  local function phone()
    local ok, os = pcall(function() return love.system.getOS() end)
    return ok and (os == "Android" or os == "iOS")
  end

  -- returns true if at least one controller rumbled
  local function padRumble(left, right, time)
    if not (love and love.joystick and love.joystick.getJoysticks) then return false end
    local ok, pads = pcall(love.joystick.getJoysticks)
    if not ok or type(pads) ~= "table" then return false end
    local any = false
    for _, pad in ipairs(pads) do
      local okS, supported = pcall(pad.isVibrationSupported, pad)
      if okS and supported then
        local okV, done = pcall(pad.setVibration, pad, left, right, time)
        if okV and done ~= false then any = true end
      end
    end
    return any
  end

  local function now() return (love.timer and love.timer.getTime()) or 0 end

  local function fire(gotHit, strength, time)
    -- below this, many motors don't spin up at all
    local strong = math.max(0.20, clamp(strength))
    time = math.max(0.05, time)
    local soft = clamp(strong * 0.35)
    local left, right = soft, strong
    if gotHit then left, right = strong, soft end
    if padRumble(left, right, time) then return end
    if phone() and love.system and love.system.vibrate then
      pcall(love.system.vibrate, time)
    end
  end

  -- pulses waiting for their turn (the second hit of a super effective one)
  local queue = {}

  function R.tick()
    if #queue == 0 then return end
    local t = now()
    local i = 1
    while i <= #queue do
      local q = queue[i]
      if t >= q.at then
        table.remove(queue, i)
        pcall(fire, q.gotHit, q.strength, q.time)
      else
        i = i + 1
      end
    end
  end

  function R.pulse(gotHit, pattern, forceIt)
    local it = forceIt or R.INTENSITIES[intensityIndex()]
    if it.id == "off" then return end
    local t, at = now(), 0
    for _, p in ipairs(pattern.pulses) do
      local strength, time, delay = p[1] * it.scale, p[2] * it.length, p[3]
      if at == 0 and delay == 0 then
        fire(gotHit, strength, time)
        at = time
      else
        -- starts after the previous pulse ends plus its gap
        at = at + delay
        queue[#queue + 1] = { at = t + at, gotHit = gotHit, strength = strength, time = time }
        at = at + time
      end
    end
  end

  -- ------- PRESS SELECT TO TEST (Rumble Settings): Left/Right or A picks the
  -- hit kind, SELECT plays it at the current INTENSITY. Works even with
  -- ENABLE off, so you can feel it before turning rumble on.
  R.TESTS = {
    { key = "SE_NOT_EFFECTIVE", label = "NOT VERY EFF." },
    { key = "SE_EFFECTIVE", label = "EFFECTIVE" },
    { key = "SE_SUPER_EFFECTIVE", label = "SUPER EFF." },
  }
  local testIndex = 2

  function R.testLabel() return R.TESTS[testIndex].label end

  function R.stepTest(dir)
    testIndex = (testIndex - 1 + (dir or 1)) % #R.TESTS + 1
  end

  function R.pattern(name) return BY_NAME[name] or BY_NAME.SE_EFFECTIVE end

  -- with INTENSITY Off, the test plays at Medium so it can still be felt
  function R.test()
    local it = R.INTENSITIES[intensityIndex()]
    if it.id == "off" then it = R.INTENSITIES[3] end
    R.pulse(false, R.pattern(R.TESTS[testIndex].key), it)
  end

  local function onSe(id, opts)
    if not enabled() then return end
    local pattern = PATTERN[tonumber(id) or -1]
    if not pattern then return end
    -- only the battle's hit sound carries a pan (left = your side, right = foe)
    local pan = type(opts) == "table" and tonumber(opts.pan) or nil
    if not pan or pan == 0 then return end
    local gotHit = pan < 0
    if gotHit and not S.flag("rumble_when_hit") then return end
    if not gotHit and not S.flag("rumble_when_hitting") then return end
    R.pulse(gotHit, pattern)
  end

  function R.install()
    if R.installed then return end
    local Audio = require("src.core.game3.audio")
    local SE = require("src.core.game3.se_ids")
    R.installed = true
    -- the ids the game itself uses (12/13/14 in all five games)
    for name, p in pairs(BY_NAME) do PATTERN[tonumber(SE[name]) or p.id] = p end
    local mod = ctx.mod
    if mod.hooks and mod.hooks.wrap then
      pcall(function()
        mod.hooks:wrap("core.update", function(nextFn, game, dt, ...)
          pcall(R.tick)
          return nextFn(game, dt, ...)
        end)
      end)
    end
    -- BEFORE WILD / TRAINER BATTLE: when the battle (and its transition) starts
    local BB = require("src.core.game3.battle_bridge")
    local origStart = BB.start
    local lastStart = -10
    BB.start = function(m, game, foe, opts, ...)
      local ok, err = pcall(function()
        if not enabled() or now() - lastStart < 1.5 then return end
        local wild = type(opts) == "table" and opts.wild == true
        if wild and S.flag("rumble_wild") then
          lastStart = now()
          R.pulse(false, BY_NAME.SE_EFFECTIVE)
        elseif not wild and S.flag("rumble_trainer") then
          lastStart = now()
          R.pulse(false, BY_NAME.SE_SUPER_EFFECTIVE)
        end
      end)
      if not ok and ctx.mod.log then ctx.mod.log:warn("rumble battle start: %s", tostring(err)) end
      return origStart(m, game, foe, opts, ...)
    end

    local origPlay = Audio.playSe
    Audio.playSe = function(id, opts, ...)
      local okR, resolved = pcall(SE.resolve, id)
      local ok, err = pcall(onSe, okR and resolved or id, opts)
      if not ok and ctx.mod.log then ctx.mod.log:warn("rumble: %s", tostring(err)) end
      return origPlay(id, opts, ...)
    end
  end

  return R
end
