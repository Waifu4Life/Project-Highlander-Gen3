-- Grid model: 2 columns x 5 rows, slot 10 is always EXIT.
return function(ctx)
  local L = {}
  L.COLS, L.ROWS = 2, 5
  L.SLOTS = L.COLS * L.ROWS
  L.EXIT_SLOT = L.SLOTS

  -- 240x160 GBA space: 16px top bar, then five 25px rows.
  L.TOP_BAR = 16
  local X0, COL_GAP, Y0, ROW_H, ROW_GAP = 5, 6, 20, 25, 3
  L.TILE_W = math.floor((240 - X0 * 2 - COL_GAP) / 2)
  L.TILE_H = ROW_H

  function L.rect(slot)
    local col = (slot - 1) % L.COLS
    local row = math.floor((slot - 1) / L.COLS)
    return X0 + col * (L.TILE_W + COL_GAP), Y0 + row * (ROW_H + ROW_GAP), L.TILE_W, L.TILE_H
  end

  L.LABELS = {
    pokedex = "POKéDEX", pokemon = "POKéMON", bag = "BAG", pokebox = "POKéBOX",
    save = "SAVE", option = "OPTIONS", mods = "MODS", pokenav = "POKéNAV", exit = "EXIT",
  }

  function L.label(id, fallback)
    return L.LABELS[id] or fallback or tostring(id):upper()
  end

  -- Build the ten slots from the menu's live entries. Returns nil when the
  -- entries do not fit (more than nine items besides EXIT, or no EXIT).
  function L.fromEntries(entries, order)
    local exitEntry, exitIndex
    local byId, extras = {}, {}
    for index, e in ipairs(entries or {}) do
      if type(e) == "table" then
        if e.id == "exit" then
          exitEntry, exitIndex = e, index
        elseif e.id and ctx.settings.KNOWN[e.id] and not byId[e.id] then
          byId[e.id] = { entry = e, index = index }
        else
          extras[#extras + 1] = { entry = e, index = index }
        end
      end
    end
    if not exitEntry then return nil end
    local slots = {}
    for _, id in ipairs(order) do
      local hit = byId[id]
      if hit then
        slots[#slots + 1] = { id = id, entry = hit.entry, index = hit.index,
          label = L.label(id, hit.entry.label) }
      end
    end
    for _, x in ipairs(extras) do
      slots[#slots + 1] = { id = x.entry.id or "extra", entry = x.entry, index = x.index,
        label = tostring(x.entry.label or x.entry.id or "?"), extra = true }
    end
    if #slots > L.SLOTS - 1 then return nil end
    local out = {}
    for i = 1, L.SLOTS - 1 do out[i] = slots[i] or false end
    out[L.EXIT_SLOT] = { id = "exit", entry = exitEntry, index = exitIndex, label = L.label("exit") }
    return out
  end

  local function filled(slots, i)
    return slots[i] and slots[i] ~= false
  end

  function L.firstFilled(slots)
    for i = 1, L.SLOTS do if filled(slots, i) then return i end end
    return L.EXIT_SLOT
  end

  -- Grid navigation that skips empty slots.
  function L.move(slots, cursor, dx, dy)
    local col = (cursor - 1) % L.COLS
    local row = math.floor((cursor - 1) / L.COLS)
    if dy ~= 0 then
      for step = 1, L.ROWS - 1 do
        local r = ((row + dy * step) % L.ROWS + L.ROWS) % L.ROWS
        local i = r * L.COLS + col + 1
        if filled(slots, i) then return i end
      end
      return cursor
    end
    if dx ~= 0 then
      local other = ((col + dx) % L.COLS + L.COLS) % L.COLS
      local direct = row * L.COLS + other + 1
      if filled(slots, direct) then return direct end
      -- nearest filled row in the other column
      for dist = 1, L.ROWS - 1 do
        for _, r in ipairs({ row - dist, row + dist }) do
          if r >= 0 and r < L.ROWS then
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
