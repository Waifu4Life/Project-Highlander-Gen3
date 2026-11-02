-- SAFARI ZONE (Kanto and Hoenn; the three games share the battle code)
--   UNLIMITED BALLS: a thrown Safari Ball is given straight back, so the
--                    count never goes down and "out of Safari Balls" never
--                    ends the game.
--   NO RUNNING AWAY: the wild Pokemon's chance to flee is always 0. Bait,
--                    Rocks, Pokeblocks and Go Near still change the catch
--                    odds as usual.
-- INFINITE SAFARI STEPS is in field.lua.
return function(ctx, patch)
  local P = {}
  local S = ctx.settings

  function P.install()
    patch("safari_no_run", function()
      local Rules = require("src.core.game3.battle.rules")
      local orig = Rules.safari and Rules.safari.fleeRate
      assert(type(orig) == "function", "Rules.safari.fleeRate missing")
      Rules.safari.fleeRate = function(sf, ...)
        if S.flag("safari_no_run") then return 0 end
        return orig(sf, ...)
      end
    end)

    patch("safari_unlimited_balls", function()
      local Catching = require("src.core.game3.battle.catching")
      local orig = Catching.tryCatch
      assert(type(orig) == "function", "Catching.tryCatch missing")
      -- the game takes the ball off just before it calls tryCatch
      Catching.tryCatch = function(item, target, st, ...)
        if S.flag("safari_unlimited_balls") and type(st) == "table" and st.safari
            and type(st.safariState) == "table" then
          local sf = st.safariState
          sf.balls = (tonumber(sf.balls) or 0) + 1
          local ok, Battle = pcall(require, "src.core.game3.battle")
          if ok and type(Battle) == "table" and type(Battle.safariSyncBalls) == "function" then
            pcall(Battle.safariSyncBalls, st)
          end
        end
        return orig(item, target, st, ...)
      end
    end)
  end

  return P
end
