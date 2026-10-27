-- QOL > REMATCH ANYONE, ANYTIME (same concept as Project Highlander Gen 1/2)
--   Talk to a trainer you already beat: "Would you like a rematch?"
--   * YES: you battle them again. Their Pokémon are all at the level of the
--     lowest-level Pokémon in your party, evolved for that level, with the
--     moves they would know at that level.
--   * NO: they say their usual after-battle line.
--   Works for regular trainers, gym leaders and others whose battle continues
--   into a script. After a rematch win that script is skipped (no second
--   badge or TM); you just get their after-battle line. Winning or losing,
--   the trainer stays "beaten". Scripted fights without a talk (no intro
--   text), the early rival battle, and the game's own VS Seeker / Match Call
--   rematches are left alone.
return function(ctx, patch)
  local P = {}
  local S = ctx.settings
  -- The mod sandbox has no `package` table; require hands back the game's
  -- real (already loaded) modules.
  local function mreq(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
    return nil
  end

  local ALLOWED = {
    SINGLE = true,
    CONTINUE_SCRIPT = true,
    CONTINUE_SCRIPT_NO_MUSIC = true,
    DOUBLE = true,
    CONTINUE_SCRIPT_DOUBLE = true,
    CONTINUE_SCRIPT_DOUBLE_NO_MUSIC = true,
  }

  local bypass = {}      -- trainer flag ids that read as "not beaten" while the battle is set up
  local scaling = false  -- Trainers.foeFromId scales parties while true
  local pendingId = nil  -- accepted rematch: scale this trainer's team when its battle starts

  local function on() return S.get("rematch_anyone") == true end

  local function session()
    local Runtime = mreq("src.core.game3.runtime")
    return Runtime and Runtime.getSession and Runtime.getSession() or nil
  end

  local function logInfo(fmt, ...)
    local log = ctx.mod.log
    if log and log.info then pcall(log.info, log, fmt, ...) end
  end

  -- Lowest level in a party. Species can be numbers or names ("CHARMANDER"),
  -- so the game's own helpers decide what is a real (non-egg) Pokémon.
  local function partyLowest(party)
    if type(party) ~= "table" then return nil end
    local Pokemon = mreq("src.core.game3.pokemon")
    local min
    for _, mon in ipairs(party) do
      if type(mon) == "table" then
        local sp
        if Pokemon and Pokemon.speciesOf then
          local ok, v = pcall(Pokemon.speciesOf, mon)
          sp = ok and tonumber(v) or nil
        end
        sp = sp or tonumber(mon.species or mon.speciesId)
        if sp == nil and (mon.species or mon.speciesId) ~= nil then sp = -1 end -- a name we couldn't map: still a Pokémon
        local egg = mon.isEgg or mon.egg
        if not egg and Pokemon and Pokemon.isEgg then
          local ok, v = pcall(Pokemon.isEgg, mon)
          egg = ok and v or false
        end
        local lv = tonumber(mon.level)
        if lv and sp and sp ~= 0 and sp ~= 412 and not egg then
          if not min or lv < min then min = lv end
        end
      end
    end
    return min
  end

  local function lowestLevel(battleParty)
    local min = partyLowest(battleParty)
    if not min then
      local sess = session()
      min = partyLowest(sess and sess.party)
    end
    if not min then
      local Field = mreq("src.core.game3.field")
      min = partyLowest(Field and Field._session and Field._session.party)
    end
    return math.max(1, math.min(100, min or 5))
  end

  -- Evolve for the level, like the Gen 1/2 rematches.
  --   Level evolutions at their level; one-stone evolutions from Lv 30;
  --   trade and Beauty evolutions from Lv 30; friendship evolutions from Lv 32.
  --   Several stone choices (Eevee) or Shedinja: no guess, it stays.
  local function evolveFor(species, level)
    local Pokemon = require("src.core.game3.pokemon")
    local current = species
    for _ = 1, 3 do
      local rows = Pokemon.evolutions(current) or {}
      local levelInto, itemInto, itemCount, tradeInto, happyInto, beautyInto
      itemCount = 0
      for _, evo in ipairs(rows) do
        local m = tonumber(evo.method or evo[1]) or 0
        local param = tonumber(evo.param or evo[2]) or 0
        local into = tonumber(evo.target or evo[3]) or 0
        if into ~= 0 then
          if (m == 4 or (m >= 8 and m <= 13)) and param <= level then
            levelInto = levelInto or into
          elseif m == 7 then
            itemCount = itemCount + 1
            itemInto = into
          elseif m == 5 or m == 6 then
            tradeInto = tradeInto or into
          elseif m >= 1 and m <= 3 then
            happyInto = happyInto or into
          elseif m == 15 then
            beautyInto = beautyInto or into
          end
        end
      end
      local nextSp = levelInto
      if not nextSp and level >= 30 and itemCount == 1 then nextSp = itemInto end
      if not nextSp and level >= 30 then nextSp = tradeInto end
      if not nextSp and level >= 30 then nextSp = beautyInto end
      if not nextSp and level >= 32 then nextSp = happyInto end
      if not nextSp or nextSp == current then break end
      current = nextSp
    end
    return current
  end

  local function scaleFoe(foe, level)
    if type(foe) ~= "table" or type(foe.party) ~= "table" then return foe end
    level = level or lowestLevel()
    for _, mon in ipairs(foe.party) do
      if type(mon) == "table" then
        mon._ph3OrigSpecies = mon._ph3OrigSpecies or tonumber(mon.species) or 1
        local okE, sp = pcall(evolveFor, mon._ph3OrigSpecies, level)
        mon.species = (okE and sp) or mon._ph3OrigSpecies
        mon.level = level
        mon.moves = nil -- the battle gives the level-up moves for this species/level
        mon.pp, mon.maxPp = nil, nil
      end
    end
    local lead = foe.party[1]
    if lead then
      foe.species, foe.level, foe.moves = lead.species, lead.level, nil
    end
    foe._ph3Rematch = level
    logInfo("rematch: trainer %s team set to Lv %d", tostring(foe.trainerId), level)
    return foe
  end

  local function battleTypeName(battleType)
    local ok, name = pcall(function()
      return require("src.core.game3.scripting.opcodes").active():trainerBattleType(battleType)
    end)
    return ok and name or nil
  end

  local function ask(onAnswer)
    local Message = require("src.ui.game3.message")
    local Choice = require("src.ui.game3.choice")
    Message.show("Would you like a rematch?", function()
      Choice.yesNo(function(yes)
        if not yes then
          Message.close()
          onAnswer(false)
          return
        end
        Message.close()
        onAnswer(true)
      end)
    end)
  end

  function P.install()
    patch("rematch_flags", function()
      local Flags = require("src.core.game3.scripting.flags")
      local orig = Flags.getFlag
      assert(type(orig) == "function", "Flags.getFlag missing")
      Flags.getFlag = function(store, c, id, ...)
        if next(bypass) ~= nil and bypass[tonumber(id) or -1] then return false end
        return orig(store, c, id, ...)
      end
    end)

    patch("rematch_party", function()
      local Trainers = require("src.core.game3.scripting.trainers")
      local orig = Trainers.foeFromId
      assert(type(orig) == "function", "Trainers.foeFromId missing")
      Trainers.foeFromId = function(trainerId, ...)
        local foe = orig(trainerId, ...)
        if scaling or (pendingId and tonumber(trainerId) == pendingId) then
          local ok, scaled = pcall(scaleFoe, foe)
          if ok then return scaled end
        end
        return foe
      end
    end)

    -- Last stop before the battle is built: whatever path made the team
    -- (inline trainerbattle, dotrainerbattle, Hoenn natives), an accepted
    -- rematch gets its team scaled here.
    -- Last stops before the battle is built: whatever path made the team
    -- (inline trainerbattle, dotrainerbattle, Hoenn natives), an accepted
    -- rematch gets its team scaled here.
    local function scaleForBattle(foe, trainerId, battleParty)
      local id = pendingId
      if not id or type(foe) ~= "table" then return false end
      local fid = tonumber(trainerId) or tonumber(foe.trainerId)
      if fid ~= id then return false end
      local level = lowestLevel(battleParty)
      if foe._ph3Rematch ~= level then
        local ok, err = pcall(scaleFoe, foe, level)
        if not ok and ctx.mod.log then pcall(ctx.mod.log.warn, ctx.mod.log, "rematch scaling: %s", tostring(err)) end
      end
      return true
    end

    patch("rematch_bridge", function()
      local BattleBridge = require("src.core.game3.battle_bridge")
      local orig = BattleBridge.start
      assert(type(orig) == "function", "BattleBridge.start missing")
      BattleBridge.start = function(m, game, foe, opts, ...)
        if type(opts) == "table" and not opts.wild then scaleForBattle(foe, opts.trainerId) end
        return orig(m, game, foe, opts, ...)
      end
    end)

    patch("rematch_battle", function()
      local Battle = require("src.core.game3.battle.init")
      local orig = Battle.start
      assert(type(orig) == "function", "Battle.start missing")
      Battle.start = function(opts, ...)
        if type(opts) == "table" and not opts.wild and not opts.link then
          if scaleForBattle(opts.foe, opts.trainerId, opts.playerParty) then
            pendingId = nil
            -- a ready-made team list would bypass foe.party; rebuild it from foe.party
            if type(opts.foeParty) == "table" then
              logInfo("rematch: battle had its own team list (%d)", #opts.foeParty)
            end
          end
        end
        return orig(opts, ...)
      end
    end)

    patch("rematch_talk", function()
      local Ops = require("src.core.game3.scripting.ops_a")
      local Flags = require("src.core.game3.scripting.flags")
      local Trainers = require("src.core.game3.scripting.trainers")
      local orig = Ops.dispatch
      local unhooked = Ops.dispatchUnhooked
      assert(type(orig) == "function", "Ops.dispatch missing")

      Ops.dispatch = function(vm, row, ...)
        if type(row) ~= "table" or row.op ~= "trainerbattle" or not on() then
          return orig(vm, row, ...)
        end
        local c, store = vm and vm.ctx, vm and vm.store
        local trainerId = tonumber(row.trainer or row[1]) or 0
        local battleType = tonumber(row.type) or 0
        if not c or trainerId <= 0 or not ALLOWED[battleTypeName(battleType) or ""] then
          return orig(vm, row, ...)
        end
        local fid = Flags.trainerFlagId(trainerId)
        local beaten = false
        pcall(function() beaten = Flags.getFlag(store, c, fid) and true or false end)
        local t = beaten and Trainers.get(trainerId) or nil
        if not (t and type(t.party) == "table" and #t.party > 0) then
          return orig(vm, row, ...)
        end

        local extra = { ... }
        local answer = nil
        pendingId = nil
        c.mode = "native"
        c.status = "waiting"
        c.nativePoll = function()
          if answer == nil then return false end
          c.nativePoll = nil
          c.mode = "bytecode"
          c.status = "running"
          local useRow = row
          if answer then
            -- skip the "beaten" script after a win (no second badge/TM)
            useRow = {}
            for k, v in pairs(row) do useRow[k] = v end
            useRow.eventScript = nil
            bypass[fid] = true
            scaling = true
            pendingId = trainerId
          end
          local ok, yield = pcall(orig, vm, useRow, (table.unpack or unpack)(extra))
          bypass[fid] = nil
          scaling = false
          if not ok then error(yield, 0) end
          -- orig either set up its own wait (battle) or fell through to the
          -- after-battle script; in both cases the VM continues from here.
          if yield then return false end
          return true
        end
        if unhooked then pcall(unhooked, vm, { op = "faceplayer" }) end
        local okAsk = pcall(ask, function(yes) answer = yes end)
        if not okAsk then answer = false end
        return true
      end
    end)
  end

  return P
end
