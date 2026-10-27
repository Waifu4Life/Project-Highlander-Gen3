-- QOL > UNLIMITED PP
--   The player's moves never lose PP. Every move a battler uses goes through
--   Engine.resolveMove; the player side's PP is noted before and put back
--   after, so normal use, Pressure, Spite and Grudge never lower it. PP that
--   goes up during a move (Leppa Berry) is kept.
--   Moves already at 0 PP count as usable while you pick and while they run.
--   Player side only (your partner in a multi battle too); link battles
--   keep the normal rules so both games stay in step.
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

  local function on(st)
    return S.get("unlimited_pp") == true and st ~= nil and not st.link
  end

  local function playerMons(st)
    local State = mreq("src.core.game3.battle.state")
    local out, seen = {}, {}
    local function add(b)
      local mon = b and b.side == "player" and b.mon
      if type(mon) == "table" and type(mon.pp) == "table" and not seen[mon] then
        seen[mon] = true
        out[#out + 1] = mon
      end
    end
    if State and State.battler then
      for id = 0, 3 do add(State.battler(st, id)) end
    end
    add(st.player)
    return out
  end

  local function hasMove(mon, i)
    local mv = mon.moves and mon.moves[i]
    return mv ~= nil and mv ~= 0 and mv ~= ""
  end

  -- Lift 0-PP moves to 1; returns the list needed to undo it exactly.
  local function lift(st)
    local saved = {}
    for _, mon in ipairs(playerMons(st)) do
      for i = 1, 4 do
        local v = tonumber(mon.pp[i])
        if v ~= nil then
          local lifted = v
          if v <= 0 and hasMove(mon, i) then
            lifted = 1
            mon.pp[i] = 1
          end
          saved[#saved + 1] = { mon = mon, i = i, raw = v, lifted = lifted }
        end
      end
    end
    return saved
  end

  local function restore(saved)
    for index = #saved, 1, -1 do
      local s = saved[index]
      local cur = tonumber(s.mon.pp[s.i])
      if cur == nil or cur <= s.lifted then s.mon.pp[s.i] = s.raw end
    end
  end

  local function guarded(st, fn, ...)
    if not on(st) then return fn(...) end
    local saved = lift(st)
    local res = pack(pcall(fn, ...))
    restore(saved)
    if not res[1] then error(res[2], 0) end
    return unpackN(res, 2)
  end

  function P.install()
    patch("unlimited_pp_moves", function()
      local Engine = require("src.core.game3.battle.engine")
      local orig = Engine.resolveMove
      assert(type(orig) == "function", "Engine.resolveMove missing")
      Engine.resolveMove = function(user, target, moveId, slot, adapter, st, ...)
        return guarded(st, orig, user, target, moveId, slot, adapter, st, ...)
      end
    end)

    patch("unlimited_pp_select", function()
      local Commands = require("src.core.game3.battle.commands")
      local names = { "selectionError", "playerAction" }
      for _, name in ipairs(names) do
        assert(type(Commands[name]) == "function", "Commands." .. name .. " missing")
      end
      for _, name in ipairs(names) do
        local orig = Commands[name]
        Commands[name] = function(st, ...)
          return guarded(st, orig, st, ...)
        end
      end
    end)
  end

  return P
end
