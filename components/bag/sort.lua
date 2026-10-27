-- Bag sort menu (START in the bag, all five games), same choices as
-- Project Highlander Gen 1/2:
--   CATEGORY ASC / CATEGORY DESC: Project Highlander's own category order
--     (DESC is the same list upside down); ties by name.
--     ITEMS:      HP healing (weak to strong, then revives), status healing,
--                 HP + status (Full Restore), PP healing, held & battle-
--                 enhancing items, valuable / sellable items, battle / misc
--                 items (X items, Poké Doll, mail...), stat-boosting items &
--                 vitamins, evolution stones, repels & dungeon items.
--     KEY ITEMS:  bikes, map, Teachy TV, rods, cases / pouches / jars,
--                 fossils & amber, keys, passes & tickets, everything else.
--     POKé BALLS: Poké Ball, Great Ball, Ultra Ball, Master Ball, the rest.
--     Other pockets (Hoenn TMs/HMs and berries) keep the game's number order.
--   NAMES A-Z / NAMES Z-A: by name.
-- Every pocket is sorted at once (FireRed/LeafGreen: the TM CASE and BERRY
-- POUCH keep the game's own order). Quantities and the selected item are kept.
return function(ctx, deps)
  local M = { open = false, cursor = 1 }
  local S, Themes = ctx.settings, ctx.themes
  local ItemsData, FrlgFont = deps.ItemsData, deps.FrlgFont

  M.CHOICES = {
    { label = "CATEGORY ASC", kind = "category" },
    { label = "CATEGORY DESC", kind = "category", descending = true },
    { label = "NAMES A-Z", kind = "name" },
    { label = "NAMES Z-A", kind = "name", descending = true },
  }

  local KEEP_ORDER = { TM_CASE = true, BERRY_POUCH = true }

  local function se(id)
    pcall(function() require("src.core.game3.audio").playSe(id) end)
  end

  local function itemNumber(id)
    local ok, n = pcall(ItemsData.toNumericId, id)
    return (ok and tonumber(n)) or tonumber(id) or 100000
  end

  -- Category order, by the item numbers all five Gen 3 games share.
  -- Each inner list is one group, already in its own order.
  local GROUPS = {
    -- ---- ITEMS
    -- HP healing, weak to strong (Potion 20, Berry Juice 20, Fresh Water 50,
    -- Super Potion 50, Energy Powder 50, Soda Pop 60, Lemonade 80, Moomoo Milk
    -- 100, Hyper Potion 200, Energy Root 200, Max Potion), then the revives
    { 13, 44, 26, 22, 30, 27, 28, 29, 21, 31, 20, 24, 33, 25, 45 },
    -- status healing (Antidote, Paralyze Heal, Awakening, Burn Heal, Ice Heal,
    -- Blue/Yellow/Red Flute, Heal Powder, Full Heal, Lava Cookie)
    { 14, 18, 17, 15, 16, 39, 40, 41, 32, 23, 38 },
    -- HP + status
    { 19 },
    -- PP healing
    { 34, 35, 36, 37 },
    -- held & battle-enhancing items (Bright Powder ... Stick, the scarves)
    (function()
      local t = {}
      for n = 179, 225 do t[#t + 1] = n end
      for n = 254, 258 do t[#t + 1] = n end
      return t
    end)(),
    -- valuable / sellable, cheapest first (Tiny Mushroom, Pearl, Stardust,
    -- Big Mushroom, Big Pearl, Star Piece, Nugget), then Heart Scale, Shoal
    -- Salt/Shell and the shards
    { 103, 106, 108, 104, 107, 109, 110, 111, 46, 47, 48, 49, 50, 51 },
    -- battle / misc (Guard Spec., Dire Hit, X items, Poké Doll, Fluffy Tail, mail)
    { 73, 74, 75, 76, 77, 78, 79, 80, 81,
      121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132 },
    -- stat-boosting & vitamins (HP Up, Protein, Iron, Calcium, Zinc, Carbos,
    -- Rare Candy, PP Up, PP Max)
    { 63, 64, 65, 67, 70, 66, 68, 69, 71 },
    -- evolution stones (Fire, Water, Thunder, Leaf, Moon, Sun)
    { 95, 97, 96, 98, 94, 93 },
    -- repels & dungeon items (Repel, Super Repel, Max Repel, Escape Rope,
    -- White Flute, Black Flute)
    { 86, 83, 84, 85, 43, 42 },

    -- ---- KEY ITEMS
    -- bikes (Bicycle, Mach Bike, Acro Bike)
    { 360, 259, 272 },
    -- map
    { 361 },
    -- Teachy TV
    { 366 },
    -- rods
    { 262, 263, 264 },
    -- cases / pouches / jars (TM Case, Berry Pouch, Coin Case, Powder Jar,
    -- Pokéblock Case, Soot Sack)
    { 364, 365, 260, 372, 273, 270 },
    -- fossils & amber (Helix, Dome, Old Amber, Root, Claw)
    { 357, 358, 354, 286, 287 },
    -- keys (Secret, Card, Lift, Basement, Room 1/2/4/6, Storage)
    { 351, 355, 356, 271, 281, 282, 283, 284, 285 },
    -- passes & tickets (S.S. Ticket, Tri-Pass, Rainbow Pass, Contest Pass,
    -- Eon/Mystic/Aurora Ticket)
    { 265, 367, 368, 266, 275, 370, 371 },
    -- (everything else in KEY ITEMS: after these, in number order)

    -- ---- POKé BALLS (Poké, Great, Ultra, Master, then the rest)
    { 4, 3, 2, 1, 5, 6, 7, 8, 9, 10, 11, 12 },
  }

  local RANK = {}
  for g, list in ipairs(GROUPS) do
    for i, n in ipairs(list) do
      if RANK[n] == nil then RANK[n] = g * 1000 + i end
    end
  end

  -- position in the category order; anything not listed goes after the
  -- listed items of its pocket, in the game's number order
  local function categoryRank(num)
    return RANK[num] or (100000 + num)
  end

  local function itemName(id)
    for _, fn in ipairs({ ItemsData.displayName, ItemsData.name }) do
      if type(fn) == "function" then
        local ok, n = pcall(fn, id)
        if ok and type(n) == "string" and n ~= "" then return n:lower() end
      end
    end
    local ok, info = pcall(ItemsData.info, id)
    if ok and type(info) == "table" and type(info.name) == "string" then return info.name:lower() end
    return tostring(id):lower()
  end

  local function sortSlots(slots, kind, descending)
    local entries = {}
    for i, slot in ipairs(slots) do
      local num = itemNumber(slot.id)
      entries[i] = { slot = slot, num = categoryRank(num), name = itemName(slot.id), i = i }
    end
    table.sort(entries, function(a, b)
      if kind == "category" and a.num ~= b.num then
        if descending then return a.num > b.num end
        return a.num < b.num
      end
      if a.name ~= b.name then
        if descending then return a.name > b.name end
        return a.name < b.name
      end
      return a.i < b.i
    end)
    for i, e in ipairs(entries) do slots[i] = e.slot end
  end

  local function rowsOf(menu)
    if type(menu.list) ~= "function" then return nil end
    local ok, rows = pcall(menu.list)
    return ok and type(rows) == "table" and rows or nil
  end

  function M.apply(menu, bag, choice)
    if type(bag) ~= "table" or type(bag.pockets) ~= "table" then return false end
    local rows = rowsOf(menu)
    local selected = rows and type(menu.cursor) == "number" and rows[menu.cursor]
    local selectedId = type(selected) == "table" and selected.id or nil
    local hoenn = S.isHoenn()
    for pocket, slots in pairs(bag.pockets) do
      if type(slots) == "table" and (hoenn or not KEEP_ORDER[pocket]) then
        sortSlots(slots, choice.kind, choice.descending)
      end
    end
    -- keep the legacy mirror / any cached list in step
    for _, fn in ipairs({ "rebuildStacks", "refresh" }) do
      if type(deps.Bag[fn]) == "function" then pcall(deps.Bag[fn], bag) end
    end
    for _, fn in ipairs({ "refresh", "refreshList", "rebuild", "reload", "rebuildList" }) do
      if type(menu[fn]) == "function" then pcall(menu[fn]) end
    end
    -- the cursor stays on the item it was on
    local after = rowsOf(menu)
    if after and selectedId ~= nil then
      for i, row in ipairs(after) do
        if type(row) == "table" and row.id == selectedId then menu.cursor = i break end
      end
    end
    return true
  end

  function M.show()
    M.open, M.cursor = true, 1
    se(5)
  end

  function M.close()
    M.open = false
  end

  -- true = the press was ours
  function M.input(menu, bag, input)
    if not M.open then return false end
    local n = #M.CHOICES
    if input:wasPressed("up") then
      M.cursor = (M.cursor - 2) % n + 1; se(5)
    elseif input:wasPressed("down") then
      M.cursor = M.cursor % n + 1; se(5)
    elseif input:wasPressed("a") then
      local ok, err = pcall(M.apply, menu, bag, M.CHOICES[M.cursor])
      if not ok and ctx.mod.log then ctx.mod.log:warn("bag sort: %s", tostring(err)) end
      M.open = false
      pcall(function()
        local Se = require("src.core.game3.se_ids")
        if Se and Se.SE_BAG_POCKET then require("src.core.game3.audio").playSe(Se.SE_BAG_POCKET) end
      end)
    elseif input:wasPressed("b") or input:wasPressed("start") then
      M.open = false
      se(5)
    end
    return true
  end

  -- ------- drawing: a framed panel with a themed title bar, a highlight band
  -- on the chosen row, and a hint line at the bottom

  local W, ROW = 120, 16
  local function textOpts(fg, shadow, small)
    return { small = small, maxWidth = W,
      colors = { fg = fg, shadow = shadow, bg = FrlgFont.STDPAL[0] } }
  end

  function M.draw()
    if not M.open then return end
    local pal = (Themes.resolve(S.themeChoice(), S.version()))
    local main, light, dark = pal.main, pal.light, pal.dark
    local n = #M.CHOICES
    local H = 18 + n * ROW + 14
    local x, y = math.floor((240 - W) / 2), math.floor((160 - H) / 2)
    love.graphics.push("all")
    -- dim the bag behind
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    -- shadow + frame
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x + 3, y + 3, W, H, 5, 5)
    love.graphics.setColor(dark[1], dark[2], dark[3], 1)
    love.graphics.rectangle("fill", x, y, W, H, 5, 5)
    love.graphics.setColor(0.99, 0.97, 0.89, 1)
    love.graphics.rectangle("fill", x + 2, y + 2, W - 4, H - 4, 4, 4)
    -- title bar
    love.graphics.setColor(main[1], main[2], main[3], 1)
    love.graphics.rectangle("fill", x + 2, y + 2, W - 4, 14, 4, 4)
    love.graphics.rectangle("fill", x + 2, y + 10, W - 4, 6)
    love.graphics.setColor(light[1], light[2], light[3], 1)
    love.graphics.rectangle("fill", x + 2, y + 16, W - 4, 1)
    local title = "SORT BY"
    local tOpts = textOpts({ 1, 1, 1, 1 }, { dark[1], dark[2], dark[3], 1 })
    local okT, tw = pcall(FrlgFont.measure, title, tOpts)
    FrlgFont.draw(title, x + math.floor((W - ((okT and tonumber(tw)) or 40)) / 2), y + 1, tOpts)
    -- rows
    local normal = textOpts(FrlgFont.STDPAL[2], FrlgFont.STDPAL[3])
    for i, choice in ipairs(M.CHOICES) do
      local ry = y + 18 + (i - 1) * ROW
      if i == M.cursor then
        love.graphics.setColor(light[1], light[2], light[3], 0.55)
        love.graphics.rectangle("fill", x + 5, ry + 1, W - 10, ROW - 2, 3, 3)
        love.graphics.setColor(main[1], main[2], main[3], 1)
        love.graphics.rectangle("line", x + 5.5, ry + 1.5, W - 11, ROW - 3, 3, 3)
        love.graphics.setColor(1, 1, 1, 1)
        pcall(function()
          local Window = require("src.ui.game3.window")
          Window.cursorPx(x + 9, ry + 1)
        end)
      end
      FrlgFont.draw(choice.label, x + 18, ry + 1, normal)
    end
    -- hint
    local hint = "A SORT    B CANCEL"
    local hOpts = textOpts(FrlgFont.STDPAL[2], FrlgFont.STDPAL[3], true)
    local okH, hw = pcall(FrlgFont.measure, hint, hOpts)
    FrlgFont.draw(hint, x + math.floor((W - ((okH and tonumber(hw)) or 80)) / 2), y + H - 16, hOpts)
    love.graphics.pop()
  end

  return M
end
