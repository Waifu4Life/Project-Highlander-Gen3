-- Sort Menu: arrange the Start Menu items. A = pick up / place (swap),
-- B = drop / done, SELECT = default order. Like Gen1+2, a tile can be put on
-- an empty tile, leaving a gap behind that the Start Menu keeps (saved as "-");
-- there is always at least one empty tile. EXIT can be moved like any other
-- tile; until it is, it stays in the bottom-right of the last page (SELECT
-- puts it back there). Other mods' items are sorted
-- too (more than nine items: pages).
return function(ctx)
  local S, L, D = ctx.settings, ctx.layout, ctx.draw
  local Sort = { isMenu = true, open = false }

  local function se(id)
    pcall(function()
      require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").resolve(id))
    end)
  end

  local function playerLabel(session)
    local name = type(session) == "table" and (session.name or session.playerName) or nil
    name = tostring(name or "PLAYER")
    local ok, FrlgFont = pcall(require, "src.ui.game3.frlg_font")
    if ok and FrlgFont.truncate then name = FrlgFont.truncate(name, 7) end
    return name:upper()
  end

  -- built-in items this game can show (whether or not they are unlocked yet)
  local function available(session)
    local set = {}
    for _, id in ipairs(S.DEFAULT_ORDER) do set[id] = true end
    if not S.flag("pokebox") or S.isHidden("pokebox") then set.pokebox = nil end
    if not S.isHoenn(session) then set.pokenav = nil end
    if S.isHidden("mods") then set.mods = nil end
    return set
  end

  -- other mods' items: the ones in the open Start Menu, else the ones seen
  -- before (CUSTOM ICONS keeps that list)
  local function extras()
    local out = {}
    local G = ctx.startMenu and ctx.startMenu.state
    if G and G.active and G.slots then
      for i = 1, L.total(G.slots) do
        local s = G.slots[i]
        if s and s.extra then
          out[#out + 1] = { key = s.orderKey or S.extraKey(s.iconKey), slot = {
            id = s.id, entry = s.entry, label = s.label, extra = true, iconKey = s.iconKey } }
        end
      end
      return out
    end
    for _, it in ipairs(S.iconItems()) do
      out[#out + 1] = { key = S.extraKey(it.key), slot = {
        id = "extra", label = it.label, extra = true, iconKey = it.key,
        entry = { label = it.label, id = it.key:match("^ID_(.+)$") } } }
    end
    return out
  end

  local function build()
    local set = available(Sort._session)
    local slotFor = {}
    for id in pairs(set) do
      slotFor[id] = { id = id, label = L.tileLabel(id,
        id == "trainer" and playerLabel(Sort._session) or L.label(id)) }
    end
    local exitSlot = { id = "exit", label = L.tileLabel("exit", L.label("exit")) }
    slotFor.exit = exitSlot
    local extraKeys = {}
    for _, x in ipairs(extras()) do
      if not S.isHidden(x.key) then
        x.slot.label = L.tileLabel(x.key, x.slot.label)
        slotFor[x.key] = x.slot
        extraKeys[#extraKeys + 1] = x.key
      end
    end
    -- the saved order, plus extras it doesn't know yet (at the end, before EXIT)
    local full, inFull = S.order(), {}
    for _, key in ipairs(full) do inFull[key] = true end
    local exitLast = full[#full] == "exit" and table.remove(full)
    for _, key in ipairs(extraKeys) do
      if not inFull[key] then full[#full + 1] = key; inFull[key] = true end
    end
    if exitLast then full[#full + 1] = exitLast end
    -- the tiles shown here, in order ("-" = an empty tile), none empty at the end
    local visible = {}
    for _, key in ipairs(full) do
      if slotFor[key] or key == S.GAP then visible[#visible + 1] = key end
    end
    while visible[#visible] == S.GAP do visible[#visible] = nil end
    Sort._full, Sort._slotFor = full, slotFor
    -- Every tile gets a key. EXIT not in the order yet: it sits on the
    -- bottom-right tile of the last page, as on the Start Menu. Like Gen1+2,
    -- there is always at least one empty tile to move something into (a
    -- page of empty tiles is added when there isn't).
    local pinned = not inFull.exit
    Sort._exitPinned = pinned
    local total = math.max(1, math.ceil((#visible + (pinned and 1 or 0)) / L.PAGE)) * L.PAGE
    local keys = {}
    for i = 1, total do keys[i] = visible[i] or S.GAP end
    if pinned then keys[total] = "exit" end
    local free = false
    for i = 1, total do if keys[i] == S.GAP then free = true break end end
    if not free then
      for i = total + 1, total + L.PAGE do keys[i] = S.GAP end
      total = total + L.PAGE
    end
    Sort._keys = keys
    local slots = { total = total }
    for i = 1, total do
      slots[i] = keys[i] == S.GAP and { id = "gap", gap = true } or slotFor[keys[i]]
    end
    Sort._slots = slots
  end

  -- Write the tiles back as the saved order: empty tiles as "-", none at the
  -- end. A pinned EXIT that wasn't moved stays out of the order (so it keeps
  -- following the bottom-right tile); once moved, it stays where it was put.
  -- Items this game doesn't show stay at the same tile number.
  local function save(keys, keepPinned)
    local tiles = {}
    for i = 1, #keys do
      tiles[i] = (keepPinned and keys[i] == "exit") and S.GAP or keys[i]
    end
    while tiles[#tiles] == S.GAP do tiles[#tiles] = nil end
    local after, n = {}, 0 -- hidden ids, by the number of shown tiles before them
    for _, id in ipairs(Sort._full) do
      if id == S.GAP or Sort._slotFor[id] then
        n = n + 1
      else
        after[n] = after[n] or {}
        table.insert(after[n], id)
      end
    end
    local out = {}
    local function hidden(i)
      for _, id in ipairs(after[i] or {}) do out[#out + 1] = id end
      after[i] = nil
    end
    hidden(0)
    for i, id in ipairs(tiles) do
      out[#out + 1] = id
      hidden(i)
    end
    for i = #tiles + 1, n do hidden(i) end
    while out[#out] == S.GAP do out[#out] = nil end
    S.setOrder(out)
  end

  -- swap two tiles (one may be empty); returns the tile the held one is on now
  local function swap(a, b)
    local keys = {}
    for i, k in ipairs(Sort._keys) do keys[i] = k end
    local exitMoved = keys[a] == "exit" or keys[b] == "exit"
    keys[a], keys[b] = keys[b], keys[a]
    local moved = keys[b]
    save(keys, Sort._exitPinned and not exitMoved)
    build()
    for i, k in ipairs(Sort._keys) do if k == moved then return i end end
    return b
  end

  local function firstItem()
    for i = 1, L.total(Sort._slots) do
      local s = Sort._slots[i]
      if s and not s.gap then return i end
    end
    return 1
  end

  function Sort.show(opts)
    opts = opts or {}
    Sort.open = true
    Sort._session = opts.session
    Sort._onClose = opts.onClose
    Sort._held = nil
    build()
    Sort.cursor = firstItem()
    require("src.ui.game3.stack").push("ph3_sort", Sort, { hideBelow = true, fullscreen = true })
    se("SE_WIN_OPEN")
  end

  function Sort.close()
    Sort.open = false
    require("src.ui.game3.stack").pop("ph3_sort")
    local cb = Sort._onClose
    Sort._onClose = nil
    se("SE_SELECT")
    if cb then pcall(cb) end
  end

  function Sort.isOpen() return Sort.open end

  -- an empty tile can't be picked up, but a held tile can be put on one
  local function movable(i)
    local s = Sort._slots[i]
    return s and not s.gap
  end

  function Sort.handleInput(input)
    if not (input and Sort.open) then return end
    local before = Sort.cursor
    if input:wasPressed("up") then Sort.cursor = L.move(Sort._slots, Sort.cursor, 0, -1)
    elseif input:wasPressed("down") then Sort.cursor = L.move(Sort._slots, Sort.cursor, 0, 1)
    elseif input:wasPressed("left") then Sort.cursor = L.move(Sort._slots, Sort.cursor, -1, 0)
    elseif input:wasPressed("right") then Sort.cursor = L.move(Sort._slots, Sort.cursor, 1, 0)
    elseif input:wasPressed("a") then
      if not Sort._held then
        if movable(Sort.cursor) then
          Sort._held = Sort.cursor
          se("SE_SELECT")
        else
          se("SE_FAILURE")
        end
      else
        if Sort._slots[Sort.cursor] then
          Sort.cursor = swap(Sort._held, Sort.cursor)
          Sort._held = nil
          se("SE_SELECT")
        else
          se("SE_FAILURE")
        end
      end
      return
    elseif input:wasPressed("select") then
      S.resetOrder()
      Sort._held = nil
      build()
      se("SE_SELECT")
      return
    elseif input:wasPressed("b") or input:wasPressed("start") then
      if Sort._held then
        Sort._held = nil
        se("SE_SELECT")
      else
        Sort.close()
      end
      return
    end
    if Sort.cursor ~= before then se("SE_SELECT") end
  end

  function Sort.update() end

  function Sort.draw()
    if not Sort.open then return end
    love.graphics.push("all")
    local theme = D.theme(Sort._session)
    D.background(theme)
    local page = D.pageText(Sort._slots, Sort.cursor)
    page = page and ("  " .. page) or ""
    D.barText("SORT MENU", (Sort._held and "A Place  B Cancel" or "A Pick Up  B Done  SELECT Reset") .. page)
    D.grid(Sort._slots, Sort.cursor, theme, { held = Sort._held })
    love.graphics.pop()
  end

  return Sort
end
