-- Grid model: 2 columns x 5 rows per page. EXIT always takes the bottom-right
-- tile of the LAST page; with more than nine items besides EXIT the grid gets
-- more pages (like the Gen 1/2 FULL SCREEN Start Menu).
return function(ctx)
  local L = {}
  L.COLS, L.ROWS = 2, 5
  L.SLOTS = L.COLS * L.ROWS -- tiles per page
  L.PAGE = L.SLOTS
  L.EXIT_SLOT = L.SLOTS     -- Sort Menu: one page, EXIT bottom-right

  -- 240x160 GBA space: 16px top bar, then five 25px rows.
  L.TOP_BAR = 16
  local X0, COL_GAP, Y0, ROW_H, ROW_GAP = 5, 6, 20, 25, 3
  L.TILE_W = math.floor((240 - X0 * 2 - COL_GAP) / 2)
  L.TILE_H = ROW_H

  -- slot -> rectangle on its own page
  function L.rect(slot)
    local onPage = (slot - 1) % L.PAGE
    local col = onPage % L.COLS
    local row = math.floor(onPage / L.COLS)
    return X0 + col * (L.TILE_W + COL_GAP), Y0 + row * (ROW_H + ROW_GAP), L.TILE_W, L.TILE_H
  end

  -- number of tiles in a slot table (always a whole number of pages)
  function L.total(slots)
    return (type(slots) == "table" and tonumber(slots.total)) or L.SLOTS
  end

  function L.pages(slots)
    return math.max(1, math.floor(L.total(slots) / L.PAGE))
  end

  function L.pageOf(slot)
    return math.floor(((slot or 1) - 1) / L.PAGE) + 1
  end

  L.LABELS = {
    pokedex = "POKéDEX", pokemon = "POKéMON", bag = "BAG", pokebox = "POKéBOX",
    save = "SAVE", option = "OPTIONS", mods = "MODS", pokenav = "POKéNAV", exit = "EXIT",
  }

  function L.label(id, fallback)
    return L.LABELS[id] or fallback or tostring(id):upper()
  end

  -- Build the slots from the menu's live entries in the saved order (built-in
  -- items and other mods' items alike); items the order doesn't mention yet
  -- follow in the game's order, then EXIT on the bottom-right tile of the
  -- last page. Returns nil only when the menu has no EXIT.
  function L.fromEntries(entries, order)
    local S = ctx.settings
    local exitEntry, exitIndex
    local byKey, native, keyCount = {}, {}, {}
    for index, e in ipairs(entries or {}) do
      if type(e) == "table" then
        if e.id == "exit" then
          exitEntry, exitIndex = e, index
        elseif e.id and S.KNOWN[e.id] and not byKey[e.id] then
          local slot = { id = e.id, entry = e, index = index, label = L.label(e.id, e.label) }
          byKey[e.id] = slot
          native[#native + 1] = e.id
        else
          local iconKey = S.iconKey(e)
          keyCount[iconKey] = (keyCount[iconKey] or 0) + 1
          if keyCount[iconKey] > 1 then iconKey = iconKey .. "_" .. keyCount[iconKey] end
          local key = S.extraKey(iconKey)
          byKey[key] = { id = e.id or "extra", entry = e, index = index,
            label = tostring(e.label or e.id or "?"), extra = true, iconKey = iconKey,
            orderKey = key }
          native[#native + 1] = key
        end
      end
    end
    if not exitEntry then return nil end
    local list, used = {}, {}
    for _, key in ipairs(order or {}) do
      if byKey[key] and not used[key] then
        list[#list + 1] = byKey[key]
        used[key] = true
      end
    end
    for _, key in ipairs(native) do
      if not used[key] then
        list[#list + 1] = byKey[key]
        used[key] = true
      end
    end
    local total = math.max(1, math.ceil((#list + 1) / L.PAGE)) * L.PAGE
    local out = { total = total }
    for i = 1, total - 1 do out[i] = list[i] or false end
    out[total] = { id = "exit", entry = exitEntry, index = exitIndex, label = L.label("exit") }
    return out
  end

  -- Slots from a list of { key, label, ... } (Sort Menu, CUSTOM ICONS):
  -- whole pages, optionally with a fixed tile on the last one.
  function L.fromList(list, lastTile)
    local used = #list + (lastTile and 1 or 0)
    local total = math.max(1, math.ceil(math.max(1, used) / L.PAGE)) * L.PAGE
    local out = { total = total }
    for i = 1, total do out[i] = list[i] or false end
    if lastTile then out[total] = lastTile end
    return out
  end

  local function filled(slots, i)
    return slots[i] and slots[i] ~= false
  end

  function L.firstFilled(slots)
    local total = L.total(slots)
    for i = 1, total do if filled(slots, i) then return i end end
    return total
  end

  -- Grid navigation that skips empty slots. Up/Down move a row in the same
  -- column and wrap round all pages; Left/Right switch column on the same
  -- row (or the nearest filled row on that page).
  function L.move(slots, cursor, dx, dy)
    local total = L.total(slots)
    local rows = math.floor(total / L.COLS)
    local col = (cursor - 1) % L.COLS
    local row = math.floor((cursor - 1) / L.COLS)
    if dy ~= 0 then
      for step = 1, rows - 1 do
        local r = ((row + dy * step) % rows + rows) % rows
        local i = r * L.COLS + col + 1
        if filled(slots, i) then return i end
      end
      return cursor
    end
    if dx ~= 0 then
      local other = ((col + dx) % L.COLS + L.COLS) % L.COLS
      local direct = row * L.COLS + other + 1
      if filled(slots, direct) then return direct end
      -- nearest filled row in the other column, on this page
      local top = math.floor(row / L.ROWS) * L.ROWS
      for dist = 1, L.ROWS - 1 do
        for _, r in ipairs({ row - dist, row + dist }) do
          if r >= top and r < top + L.ROWS then
            local i = r * L.COLS + other + 1
            if filled(slots, i) then return i end
          end
        end
      end
    end
    return cursor
  end

  L.filled = filled
  return L
end
