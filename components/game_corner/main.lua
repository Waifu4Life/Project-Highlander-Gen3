-- Game Corner sub-menu (same options as Project Highlander Gen 1/2).
--
--   2X COINS FOR CASH  the coin clerk gives 100 coins for ¥1,000 and 1000 coins
--                      for ¥10,000 (the game: 50 / 500). Her lines and menu say
--                      100 / 1000 while it's on.
--   SLOT ODDS          NORMAL / GENEROUS / LUCKY
--   BIGGER PAYOUTS     every slot win pays double (coins still stop at 9,999)
--   ALL LUCKY MACHINES every machine plays like the luckiest one
--
-- FireRed/LeafGreen (Celadon) -- src/core/game3/slot_machine.lua:
--   Each spin draws a "bias" (which win the reels may steer toward) from the
--   machine's table; about half the spins draw none and can't win. The 22
--   machines use 6 tables; table 5 is the luckiest (one machine).
--   GENEROUS draws twice and keeps the better bias (no-win spins about 24%
--   instead of 49%, Rocket/7 about twice as often); LUCKY draws four times
--   (no-win spins about 6%, Rocket/7 about 4x as often).
-- Ruby/Sapphire/Emerald (Mauville) -- src/core/game3/rse/slot_machine.lua:
--   Each spin may draw a special bias (7s / Reel Time) and a regular one
--   (Power, Azurill, Lotad, Cherry, Replay). Machines are rated 0 (unluckiest)
--   to 5 (luckiest), and each visit may be a "lucky game".
--   GENEROUS gives each draw a second try when it comes up empty, LUCKY three
--   more tries. ALL LUCKY MACHINES plays every machine as the luckiest (5)
--   in a lucky game.
return function(ctx)
  local S = ctx.settings
  local G = { installed = false }

  G.ODDS = {
    { id = "normal", label = "NORMAL", draws = 1 },
    { id = "generous", label = "GENEROUS", draws = 2 },
    { id = "lucky", label = "LUCKY", draws = 4 },
  }

  local function oddsIndex()
    local v = S.get("slot_odds")
    for i, o in ipairs(G.ODDS) do if o.id == v then return i end end
    return 1
  end
  local function draws() return G.ODDS[oddsIndex()].draws end
  local function on(key) return S.get(key) == true end

  function G.oddsLabel() return G.ODDS[oddsIndex()].label end
  function G.stepOdds(dir)
    local i = oddsIndex()
    i = (i - 1 + (dir or 1)) % #G.ODDS + 1
    S.set("slot_odds", G.ODDS[i].id)
  end

  local function warn(what, err)
    if ctx.mod.log then ctx.mod.log:warn("game corner %s: %s", what, tostring(err)) end
  end

  local function session()
    local ok, Runtime = pcall(require, "src.core.game3.runtime")
    if ok and type(Runtime) == "table" and Runtime.getSession then
      local okS, s = pcall(Runtime.getSession)
      if okS and type(s) == "table" then return s end
    end
  end

  -- ------------------------------------------------------------- FireRed / LeafGreen

  local function installKanto()
    local Model = require("src.core.game3.slot_machine")
    local LUCKIEST = (tonumber(Model.NUM_MACHINE_CLASSES) or 6) - 1
    local ROCKET = Model.PAYOUT and Model.PAYOUT.ROCKET or 5

    local origNew = Model.newState
    Model.newState = function(machineIdx, ...)
      if on("slot_all_lucky") then machineIdx = LUCKIEST end
      return origNew(machineIdx, ...)
    end

    local origBias = Model.calcBias
    Model.calcBias = function(st, ...)
      local best = origBias(st, ...)
      local n = draws()
      if n > 1 and type(st) == "table" then
        -- a Rocket/7 bias that's still in play is kept by the game: leave it
        for _ = 2, n do
          if (tonumber(st.machineBias) or 0) >= ROCKET then break end
          local kept = st.machineBias
          st.machineBias = 0
          local again = origBias(st, ...)
          if (tonumber(again) or 0) < (tonumber(kept) or 0) then st.machineBias = kept end
        end
        best = st.machineBias
      end
      return best
    end

    local origPayout = Model.calcPayout
    Model.calcPayout = function(st, ...)
      local r = origPayout(st, ...)
      if on("slot_bigger_payouts") and type(st) == "table" and (tonumber(st.payout) or 0) > 0 then
        st.payout = math.min(9999, st.payout * 2)
      end
      return r
    end
  end

  -- ------------------------------------------------------------- Ruby / Sapphire / Emerald

  local function installHoenn()
    local Slots = require("src.core.game3.rse.slot_machine")
    local LUCKIEST = 5 -- SLOT_MACHINE_LUCKIEST

    local origInit = Slots.init
    Slots.init = function(self, machineId, coins, ...)
      if on("slot_all_lucky") then machineId = LUCKIEST end
      local r = { origInit(self, machineId, coins, ...) }
      if on("slot_all_lucky") then self.luckyGame = true end
      return (table.unpack or unpack)(r)
    end

    local origSpecial = Slots.shouldTrySpecialBias
    Slots.shouldTrySpecialBias = function(self, ...)
      for _ = 1, draws() do
        if origSpecial(self, ...) then return true end
      end
      return false
    end

    local origWhichSpecial = Slots.trySelectBiasSpecial
    Slots.trySelectBiasSpecial = function(self, ...)
      local which
      for _ = 1, draws() do
        which = origWhichSpecial(self, ...)
        if which ~= 3 then return which end -- 3 = none
      end
      return which
    end

    local origRegular = Slots.trySelectBiasRegular
    Slots.trySelectBiasRegular = function(self, ...)
      local which
      for _ = 1, draws() do
        which = origRegular(self, ...)
        if which ~= 5 then return which end -- 5 = none
      end
      return which
    end

    local origCheck = Slots.checkMatch
    Slots.checkMatch = function(self, ...)
      local r = { origCheck(self, ...) }
      if on("slot_bigger_payouts") and (tonumber(self.payout) or 0) > 0 then
        self.payout = math.min(Slots.MAX_COINS or 9999, self.payout * 2)
      end
      return (table.unpack or unpack)(r)
    end

    local origApply = Slots.applyMatchResults
    Slots.applyMatchResults = function(self, ...)
      local r = { origApply(self, ...) }
      -- a Red 7 jackpot ends the lucky game; All Lucky keeps it going
      if on("slot_all_lucky") then self.luckyGame = true end
      return (table.unpack or unpack)(r)
    end
  end

  -- ------------------------------------------------------------- 2X Coins for Cash

  local PRICE = { [1000] = true, [10000] = true }
  local AMOUNT = { [50] = 100, [500] = 1000 }

  local function rowAmount(vm, row)
    local n = tonumber(row and (row[1] or row.amount))
    if n and n >= 0x4000 then
      local okF, Flags = pcall(require, "src.core.game3.scripting.flags")
      if okF then
        local ok, v = pcall(Flags.getVar, vm.store, vm.ctx, n)
        n = ok and tonumber(v) or nil
      end
    end
    return n
  end

  -- the clerk's purchase: addcoins 50/500 next to checkmoney/removemoney 1000/10000
  local function isClerkPurchase(vm, row)
    local pc = vm and vm.ctx and vm.ctx.pc
    local list = pc and vm.scripts and vm.scripts[pc.listKey]
    if type(list) ~= "table" then return false end
    -- the pc has already moved past this row
    local here = (tonumber(pc.index) or 1) - 1
    for i = here - 4, here + 4 do
      local r = list[i]
      if i ~= here and type(r) == "table" and (r.op == "removemoney" or r.op == "checkmoney") then
        if PRICE[rowAmount(vm, r) or -1] then return true end
      end
    end
    return false
  end

  local function installCoins()
    local Ops = require("src.core.game3.scripting.ops_a")
    local origDispatch = Ops.dispatch
    Ops.dispatch = function(vm, row, ...)
      if type(row) == "table" and row.op == "addcoins" and on("coins_2x") then
        local ok, doubled = pcall(function()
          local n = rowAmount(vm, row)
          if AMOUNT[n or -1] and isClerkPurchase(vm, row) then
            local copy = {}
            for k, v in pairs(row) do copy[k] = v end
            copy[1], copy.amount = AMOUNT[n], row.amount and AMOUNT[n] or nil
            return copy
          end
        end)
        if not ok then warn("coins", doubled) end
        if ok and doubled then return origDispatch(vm, doubled, ...) end
      end
      return origDispatch(vm, row, ...)
    end
  end

  -- the clerk's lines and menu say 100 / 1000 (only in the Game Corner itself)
  local function inGameCorner()
    local s = session()
    local map = s and tostring(s.map or "") or ""
    if map == "" then
      local okM, Map = pcall(require, "src.core.game3.map")
      map = okM and type(Map) == "table" and tostring(Map.current or "") or ""
    end
    map = map:upper()
    return map:find("GAME_?CORNER") ~= nil and map:find("PRIZE") == nil
  end

  local function retext(text, anywhere)
    if type(text) ~= "string" or not on("coins_2x") then return text end
    if not text:find("[Cc][Oo][Ii][Nn]") then return text end
    if not anywhere and not inGameCorner() then return text end
    local function swap(pre, num, rest)
      local to = AMOUNT[tonumber(num)]
      if not to then return nil end
      return pre .. tostring(to) .. rest
    end
    text = ("\0" .. text):gsub("([^%d,])(%d+)(%s+[Cc][Oo][Ii][Nn])", swap)
    return (text:sub(2))
  end
  G.retext = retext

  local function installText()
    local TextIR = require("src.core.game3.scripting.text_ir")
    if type(TextIR.toTextBox) == "function" then
      local orig = TextIR.toTextBox
      TextIR.toTextBox = function(...)
        local r = { orig(...) }
        local ok, t = pcall(retext, r[1])
        if ok then r[1] = t end
        return (table.unpack or unpack)(r)
      end
    end
    local Choice = require("src.ui.game3.choice")
    local origMulti = Choice.multi
    Choice.multi = function(options, ...)
      if type(options) == "table" and on("coins_2x") then
        local copy, changed = {}, false
        for i, o in ipairs(options) do
          local ok, t = pcall(retext, o)
          copy[i] = ok and t or o
          if copy[i] ~= o then changed = true end
        end
        if changed then options = copy end
      end
      return origMulti(options, ...)
    end
  end

  -- the clerk's price list (50 COINS / ¥1,000, 500 COINS / ¥10,000) is not a
  -- plain choice list: FireRed/LeafGreen draw it in the Prize Corner window
  -- (src/ui/game3/prize_corner.lua, list 27) with the price in its own column
  local function installPriceList()
    local Prize = require("src.ui.game3.prize_corner")
    local LIST = tonumber(Prize.LIST_COIN_PURCHASE) or 27
    local origShow = Prize.show
    Prize.show = function(opts, ...)
      if type(opts) == "table" and tonumber(opts.listId) == LIST and on("coins_2x")
          and type(opts.labels) == "table" then
        local ok, labels = pcall(function()
          local out = {}
          for i, lab in ipairs(opts.labels) do
            if type(lab) == "table" then
              local c = {}
              for k, v in pairs(lab) do c[k] = v end
              c.label, c.name = retext(c.label, true), retext(c.name, true)
              out[i] = c
            else
              out[i] = retext(lab, true)
            end
          end
          return out
        end)
        if ok then
          local copy = {}
          for k, v in pairs(opts) do copy[k] = v end
          copy.labels = labels
          opts = copy
        else
          warn("price list", labels)
        end
      end
      return origShow(opts, ...)
    end
  end

  -- ------------------------------------------------------------- install

  local done = {}
  function G.install()
    if G.installed then return end
    local steps = {
      { "kanto slots", installKanto },
      { "hoenn slots", installHoenn },
      { "coins", installCoins },
      { "text", installText },
      { "price list", installPriceList },
    }
    local all = true
    for _, s in ipairs(steps) do
      if not done[s[1]] then
        local ok, err = pcall(s[2])
        if ok then done[s[1]] = true else all = false warn(s[1], err) end
      end
    end
    G.installed = all
  end

  return G
end
