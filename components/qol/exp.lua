-- QOL > ALWAYS BOOSTED EXP
--   Every Pokémon gets the traded-Pokémon EXP bonus (x1.5, "a boosted").
--   Only the EXP side is changed (Experience.recipientOpts); the obedience
--   check uses its own trade test, so nothing starts disobeying and the
--   Trainer ID is never touched. A multi-battle partner's Pokémon are left
--   alone, like the game does.
--
-- QOL > MODERN EXP SHARING (same idea as Project Highlander Gen 1/2)
--   After the normal award, every other living party Pokémon gets half of a
--   battler's share (Lucky Egg, trainer and boosted bonuses still apply).
--   Instead of one "gained EXP" line each, one line says
--   "The others gained ... EXP. Points!". Their level-ups, stat windows and
--   new moves still show. Pokédude tutorial battles stay vanilla.
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
  local function pack(...) return { n = select("#", ...), ... } end
  local function unpackN(t, i) return (table.unpack or unpack)(t, i, t.n) end

  local BENCH_MARK = "\0PH3BENCH\0"

  local function boostedOn() return S.get("always_boosted_exp") == true end
  local function shareOn() return S.get("modern_exp_share") == true end

  local function partyIndexOf(st, mon)
    for i, m in ipairs((st and st.playerParty) or {}) do
      if m == mon then return i end
    end
    return nil
  end

  local function isPartnerMon(st, mon)
    if not (st and st.playerHalf) then return false end
    local i = partyIndexOf(st, mon)
    return i ~= nil and i > st.playerHalf
  end

  -- Species can be numbers or names ("CHARMANDER"); the game's helpers decide.
  local function alive(mon)
    if type(mon) ~= "table" or (tonumber(mon.hp) or 0) <= 0 then return false end
    local Pokemon = mreq("src.core.game3.pokemon")
    local sp
    if Pokemon and Pokemon.speciesOf then
      local ok, v = pcall(Pokemon.speciesOf, mon)
      sp = ok and tonumber(v) or nil
    end
    sp = sp or tonumber(mon.species or mon.speciesId)
    if sp == nil and (mon.species or mon.speciesId) ~= nil then sp = -1 end
    if not sp or sp == 0 or sp == 412 or mon.isEgg or mon.egg then return false end
    if Pokemon and Pokemon.isEgg then
      local ok, egg = pcall(Pokemon.isEgg, mon)
      if ok and egg then return false end
    end
    return true
  end

  function P.install()
    patch("always_boosted_exp", function()
      local Experience = require("src.core.game3.battle.experience")
      local orig = Experience.recipientOpts
      assert(type(orig) == "function", "Experience.recipientOpts missing")
      Experience.recipientOpts = function(st, mon, ...)
        local r = orig(st, mon, ...)
        if boostedOn() and type(r) == "table" and not isPartnerMon(st, mon) then
          r.traded = true
        end
        return r
      end
    end)

    patch("modern_exp_share", function()
      local Experience = require("src.core.game3.battle.experience")
      local ExpSeq = require("src.core.game3.battle.exp_seq")
      local BattleText = require("src.core.game3.battle.battle_text")
      local Pokemon = require("src.core.game3.pokemon")
      local origAward = Experience.awardFoe
      local origBegin = ExpSeq.begin
      assert(type(origAward) == "function" and type(origBegin) == "function", "EXP functions missing")

      -- Same "sent in" rule as Experience.awardFoe (pokefirered battle_script_commands.c:3123).
      local function sentInSet(st, foeBattler, opts)
        local sentIn = {}
        if opts and opts.partyIndices then
          for _, pi in ipairs(opts.partyIndices) do sentIn[pi] = true end
        elseif foeBattler.participants and next(foeBattler.participants) then
          for pi in pairs(foeBattler.participants) do sentIn[pi] = true end
        elseif st.player and st.player.mon and (tonumber(st.player.mon.hp) or 0) > 0 then
          sentIn[st.player.partyIndex or 1] = true
        end
        return sentIn
      end

      local function onField(st, pi)
        local absent = st.absent or {}
        local b0 = st.player
        local b2 = st.double and st.battlers and st.battlers[2] or nil
        if b0 and b0.partyIndex == pi and not absent[0] then return b0, 0 end
        if b2 and b2.partyIndex == pi and not absent[2] then return b2, 2 end
        return nil, 0
      end

      Experience.awardFoe = function(st, foeBattler, opts, ...)
        local out = origAward(st, foeBattler, opts, ...)
        if not shareOn() or type(out) ~= "table" or not st or not foeBattler
            or st.pokedude or st.link then
          return out
        end
        local ok, err = pcall(function()
          local party = st.playerParty or {}
          local awarded = {}
          for _, e in ipairs(out) do
            if e.partyIndex then awarded[e.partyIndex] = true end
          end
          local sentIn = sentInSet(st, foeBattler, opts)
          local viaSentIn = 0
          for i = 1, 6 do
            if sentIn[i] and alive(party[i]) then viaSentIn = viaSentIn + 1 end
          end
          local foeMon = foeBattler.mon
          local foeSpecies = foeBattler.species or (foeMon and (foeMon.species or foeMon.speciesId))
          local foeLevel = math.max(1, tonumber((foeMon and foeMon.level) or foeBattler.level) or 1)
          local isTrainer = opts and opts.trainer
          if isTrainer == nil then isTrainer = not st.wild end
          local calculated = math.floor(Experience.expYield(foeSpecies) * foeLevel / 7)
          local base = math.floor(math.floor(calculated / math.max(1, viaSentIn)) / 2)
          if base < 1 then base = 1 end
          local friendshipCtx = { mapSec = Pokemon.currentMapSec and Pokemon.currentMapSec(st.session) or nil }
          for pi = 1, 6 do
            local mon = party[pi]
            if mon and not awarded[pi] and alive(mon)
                and (tonumber(mon.level) or 1) < Experience.MAX_LEVEL
                and not (st.playerHalf and pi > st.playerHalf) then
              local per = Experience.recipientOpts(st, mon) or {}
              local amount = base
              if per.luckyEgg then amount = math.floor(amount * 150 / 100) end
              if isTrainer then amount = math.floor(amount * 150 / 100) end
              if per.traded then amount = math.floor(amount * 150 / 100) end
              if Pokemon.gainEVs then Pokemon.gainEVs(mon, foeSpecies) end
              local result = Experience.apply(mon, amount)
              if Pokemon.adjustFriendship and Pokemon.FRIENDSHIP_EVENT_GROW_LEVEL then
                for _ = 1, #(result.levels or {}) do
                  Pokemon.adjustFriendship(mon, Pokemon.FRIENDSHIP_EVENT_GROW_LEVEL, friendshipCtx)
                end
              end
              local fieldB, getter = onField(st, pi)
              if fieldB then
                fieldB.mon = mon
                fieldB.fainted = (tonumber(mon.hp) or 0) <= 0
              end
              out[#out + 1] = {
                mon = mon,
                partyIndex = pi,
                battler = fieldB,
                expGetterBattlerId = getter,
                amount = amount,
                boosted = per.traded and true or false,
                result = result,
                _ph3Bench = true,
              }
            end
          end
        end)
        if not ok and ctx.mod.log then pcall(ctx.mod.log.warn, ctx.mod.log, "modern exp share: %s", tostring(err)) end
        return out
      end

      -- One "The others gained ..." line instead of one line per benched Pokémon.
      ExpSeq.begin = function(awards, pushMsg, thenMsgs, opts, ...)
        local gainedOrder, bench, first, boosted = {}, 0, nil, false
        for _, e in ipairs(awards or {}) do
          local gained = (e.result and e.result.gained) or e.amount or 0
          if gained > 0 then
            gainedOrder[#gainedOrder + 1] = e
            if e._ph3Bench then
              bench = bench + 1
              first = first or gained
              if e.boosted then boosted = true end
            end
          end
        end
        if bench == 0 then return origBegin(awards, pushMsg, thenMsgs, opts, ...) end

        local origGet = BattleText.get
        local n = 0
        BattleText.get = function(id, fill, ...)
          if id == "STRINGID_PKMNGAINEDEXP" then
            n = n + 1
            local e = gainedOrder[n]
            if e and e._ph3Bench then return BENCH_MARK end
          end
          return origGet(id, fill, ...)
        end
        local res = pack(pcall(origBegin, awards, pushMsg, thenMsgs, opts, ...))
        BattleText.get = origGet
        if not res[1] then error(res[2], 0) end

        local steps = ExpSeq._steps
        if type(steps) == "table" then
          local okT, summary = pcall(origGet, "STRINGID_PKMNGAINEDEXP", {
            buff1 = "The others",
            buff2 = origGet(boosted and "STRINGID_ABOOSTED" or "STRINGID_EMPTYSTRING4"),
            buff3 = tostring(first or 0),
          })
          if not okT then summary = "The others gained\n" .. tostring(first or 0) .. " EXP. Points!" end
          local kept, placed = {}, false
          for _, step in ipairs(steps) do
            if step.kind == "msg" and step.data and step.data.text == BENCH_MARK then
              if not placed then
                placed = true
                step.data.text = summary
                kept[#kept + 1] = step
              end
            else
              kept[#kept + 1] = step
            end
          end
          ExpSeq._steps = kept
        end
        return unpackN(res, 2)
      end
    end)
  end

  return P
end
