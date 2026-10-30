-- Sort Menu: arrange the Start Menu items. A = pick up / place (swap),
-- B = drop / done, SELECT = default order. EXIT stays in the bottom-right of
-- the last page. Other mods' items are sorted too (more than nine items: pages).
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
    if not S.flag("pokebox") then set.pokebox = nil end
    if not S.isHoenn(session) then set.pokenav = nil end
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
      slotFor[id] = { id = id, label = id == "trainer" and playerLabel(Sort._session) or L.label(id) }
    end
    local extraKeys = {}
    for _, x in ipairs(extras()) do
      slotFor[x.key] = x.slot
      extraKeys[#extraKeys + 1] = x.key
    end
    -- the saved order, plus extras it doesn't know yet (at the end, before EXIT)
    local full, inFull = S.order(), {}
    for _, key in ipairs(full) do inFull[key] = true end
    for _, key in ipairs(extraKeys) do
      if not inFull[key] then full[#full + 1] = key; inFull[key] = true end
    end
    local visible, list = {}, {}
    for _, key in ipairs(full) do
      if slotFor[key] then
        visible[#visible + 1] = key
        list[#list + 1] = slotFor[key]
      end
    end
    Sort._full, Sort._visible = full, visible
    Sort._slots = L.fromList(list, { id = "exit", label = L.label("exit"), fixed = true })
  end

  local function save()
    -- write the visible order back into the shared list, keeping hidden ids in place
    local set = {}
    for _, id in ipairs(Sort._visible) do set[id] = true end
    local out, k = {}, 1
    for _, id in ipairs(Sort._full) do
      if set[id] then
        out[#out + 1] = Sort._visible[k]
        k = k + 1
      else
        out[#out + 1] = id
      end
    end
    S.setOrder(out)
  end

  function Sort.show(opts)
    opts = opts or {}
    Sort.open = true
    Sort._session = opts.session
    Sort._onClose = opts.onClose
    Sort._held = nil
    build()
    Sort.cursor = L.firstFilled(Sort._slots)
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

  local function movable(i)
    local s = Sort._slots[i]
    return s and not s.fixed
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
        if movable(Sort.cursor) then
          local a, b = Sort._held, Sort.cursor
          Sort._visible[a], Sort._visible[b] = Sort._visible[b], Sort._visible[a]
          save()
          build()
          Sort.cursor = b
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
