-- BATTLE SCREEN > STATUS CONDITION RESET (Off by default)
--   Like Pokémon Legends: Arceus: when a battle ends, every Pokémon in your
--   party loses its status condition (poison, burn, paralysis, sleep,
--   freeze). HP and fainted Pokémon are left as they are.
--   The game copies the battle party back into your party through
--   Party.applyBattleFields (battle_bridge.lua writeback), once per Pokémon,
--   right before battle.ended. The status is cleared just after that copy.
--   Link battles never go through that copy, so they keep the normal rules.
return function(ctx, patch)
  local P = {}
  local S = ctx.settings

  local function mreq(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
    return nil
  end

  local function on()
    if S.get("status_reset") ~= true then return false end
    local B = mreq("src.core.game3.battle")
    local st = B and B.getState and B.getState() or nil
    return not (type(st) == "table" and st.link)
  end

  local function clear(mon)
    if type(mon) ~= "table" then return end
    mon.status = nil
    mon.sleep = nil
    if mon.sleepTurns ~= nil then mon.sleepTurns = nil end
    if mon.statusAilment ~= nil then mon.statusAilment = nil end
    if mon.status1 ~= nil then mon.status1 = 0 end
    if mon.statusNum ~= nil then mon.statusNum = 0 end
  end

  function P.install()
    patch("status_reset", function()
      local Party = require("src.core.game3.party")
      local orig = Party.applyBattleFields
      assert(type(orig) == "function", "Party.applyBattleFields missing")
      if Party._ph3StatusReset then return end
      Party._ph3StatusReset = true
      Party.applyBattleFields = function(mon, fields, ...)
        orig(mon, fields, ...)
        if on() then clear(mon) end
      end
    end)
  end

  return P
end
