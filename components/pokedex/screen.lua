-- Pokédex 2nd screen: STATS / FAMILY / MOVES / LOCATION tabs (SELECT on a
-- Pokémon's entry page). Same look as the bag's SORT BY menu: themed title
-- bar, cream panels, highlight bands with the game's cursor arrow.
return function(ctx, D)
  local M = { open = false }
  local S, Themes = ctx.settings, ctx.themes
  local FrlgFont = require("src.ui.game3.frlg_font")
  local okSC, SummaryChrome = pcall(require, "src.ui.game3.summary_chrome")
  if not okSC then SummaryChrome = nil end

  local TABS = { "STATS", "FAMILY", "MOVES", "LOCATION" }
  local CREAM = { 0.99, 0.97, 0.89, 1 }
  local INK = FrlgFont.STDPAL[2] or { 0.38, 0.38, 0.38, 1 }
  local INK_SHADOW = FrlgFont.STDPAL[3] or { 0.84, 0.84, 0.80, 1 }

  local function se(id) pcall(function() require("src.core.game3.audio").playSe(id) end) end

  local function palette()
    return (Themes.resolve(S.themeChoice(), S.version()))
  end

  local function opts(fg, shadow, small, maxW)
    return { small = small, maxWidth = maxW or 240,
      colors = { fg = fg or INK, shadow = shadow or INK_SHADOW, bg = FrlgFont.STDPAL[0] } }
  end
  local function width(t, o)
    local ok, w = pcall(FrlgFont.measure, t, o)
    return (ok and tonumber(w)) or #t * 5
  end
  -- Ruby/Sapphire's small font prints about 4 px lower than FireRed's (the
  -- layout here is FireRed's): raise it so it sits in its boxes and bands.
  local function rsFont()
    local v = S.version()
    return v == "ruby" or v == "sapphire"
  end
  local function text(t, x, y, o)
    if type(o) == "table" and o.small and rsFont() then y = y - 4 end
    pcall(FrlgFont.draw, t, x, y, o)
  end
  local function right(t, rx, y, o) text(t, rx - width(t, o), y, o) end
  local function centre(t, cx, y, o) text(t, cx - math.floor(width(t, o) / 2), y, o) end
  local function color(c, a) love.graphics.setColor(c[1], c[2], c[3], a or c[4] or 1) end

  local function cursorAt(x, y)
    if rsFont() then y = y - 2 end -- Ruby/Sapphire's arrow sits lower in its tile
    pcall(function() require("src.ui.game3.window").cursorPx(x, y) end)
  end

  -- Gen 3 type ids (both regions)
  local TYPE_BY_ID = { [0] = "NORMAL", "FIGHTING", "FLYING", "POISON", "GROUND", "ROCK", "BUG", "GHOST",
    "STEEL", "MYSTERY", "FIRE", "WATER", "GRASS", "ELECTRIC", "PSYCHIC", "ICE", "DRAGON", "DARK" }
  local SHORT = { FIGHTING = "FIGHT", ELECTRIC = "ELECTR", PSYCHIC = "PSYCHC", MYSTERY = "???" }

  local function typeKey(t)
    if type(t) == "string" then
      local up = t:upper()
      if ctx.typeColors.COLORS[up] then return up end
    end
    return TYPE_BY_ID[tonumber(t) or 0] or "NORMAL"
  end

  -- One badge style in all five games: the type's colour with its name. (The
  -- FireRed/LeafGreen badge sheet as loaded here paints some badges in two
  -- types' colours, e.g. FLYING and POISON.)
  local function typeBadge(t, x, y)
    local key = typeKey(t)
    local r, g, b = ctx.typeColors.rgb(key)
    love.graphics.setColor(r * 0.55, g * 0.55, b * 0.55, 1)
    love.graphics.rectangle("fill", x, y, 32, 12, 3, 3)
    love.graphics.setColor(r, g, b, 1)
    love.graphics.rectangle("fill", x + 1, y + 1, 30, 10, 2, 2)
    love.graphics.setColor(math.min(1, r + 0.18), math.min(1, g + 0.18), math.min(1, b + 0.18), 1)
    love.graphics.rectangle("fill", x + 2, y + 1, 28, 1)
    local label = SHORT[key] or key
    local o = opts({ 1, 1, 1, 1 }, { r * 0.4, g * 0.4, b * 0.4, 1 }, true, 32)
    text(label, x + math.floor((32 - width(label, o)) / 2), y - 2, o)
  end

  local function icon(sp, x, y, known)
    local entry = D.Pokemon and D.Pokemon.icon and select(2, pcall(D.Pokemon.icon, sp))
    if type(entry) ~= "table" or not entry.image then return end
    local frame = math.floor(((love.timer and love.timer.getTime()) or 0) * 4) % (entry.frames or 1)
    local q = entry.quads and (entry.quads[frame] or entry.quads[0])
    if known then love.graphics.setColor(1, 1, 1, 1) else love.graphics.setColor(0.15, 0.15, 0.18, 1) end
    if q then love.graphics.draw(entry.image, q, x, y) else love.graphics.draw(entry.image, x, y) end
  end

  -- ------- state

  function M.show(species, dex, onJump)
    M.open, M.species, M.dex, M.onJump = true, species, dex, onJump
    M.tab = M.tab or 1
    M.sel, M.scroll, M.detail, M.sortOpen, M.sortCursor = 1, 0, nil, false, 1
    M.sortMode = M.sortMode or "location"
    M.cache = {}
    se(5)
  end

  function M.close() M.open = false; M.cache = nil end

  local function seen(sp)
    local okDex, Dex = pcall(require, "src.core.game3.dex")
    if okDex and Dex and Dex.isSeen and M.dex then
      local ok, v = pcall(Dex.isSeen, M.dex, sp)
      if ok then return v == true end
    end
    return true
  end

  local function data(key, fn)
    M.cache = M.cache or {}
    if M.cache[key] == nil then
      local ok, v = pcall(fn, M.species)
      M.cache[key] = ok and v or false
      if not ok and ctx.mod.log then ctx.mod.log:warn("dex %s: %s", key, tostring(v)) end
    end
    return M.cache[key] or nil
  end

  local function familyData() return data("family", D.family) end
  local function movesData() return data("moves", D.moves) end
  local function locData()
    local rows = data("loc", D.locations)
    if rows and M.sortedAs ~= M.sortMode then D.sortLocations(rows, M.sortMode); M.sortedAs = M.sortMode end
    return rows
  end

  -- ------- input (true = consumed)

  local LIST_ROWS = 8

  local function selectable(rows, i) return rows[i] and not rows[i].header end

  local function stepList(rows, dir)
    local n = #rows
    if n == 0 then return end
    local i = M.sel
    for _ = 1, n do
      i = i + dir
      if i < 1 then i = n elseif i > n then i = 1 end
      if selectable(rows, i) then break end
    end
    M.sel = i
    if M.sel <= M.scroll then M.scroll = M.sel - 1 end
    if M.sel > M.scroll + LIST_ROWS then M.scroll = M.sel - LIST_ROWS end
    -- show a section header above its first row
    if M.scroll > 0 and rows[M.scroll] and rows[M.scroll].header and M.sel == M.scroll + 1 then
      M.scroll = M.scroll - 1
    end
    M.scroll = math.max(0, math.min(M.scroll, math.max(0, n - LIST_ROWS)))
    se(5)
  end

  -- d-pad Left/Right: jump a page up/down
  local function pageList(rows, dir)
    local n = #rows
    if n == 0 then return end
    local target = math.max(1, math.min(n, M.sel + dir * LIST_ROWS))
    if not selectable(rows, target) then
      local step = dir > 0 and 1 or -1
      local t = target
      while rows[t] and not selectable(rows, t) do t = t + step end
      if not rows[t] then
        t = target
        while rows[t] and not selectable(rows, t) do t = t - step end
      end
      target = rows[t] and t or M.sel
    end
    if target == M.sel then return end
    M.sel = target
    M.scroll = math.max(0, math.min(M.scroll + dir * LIST_ROWS, math.max(0, n - LIST_ROWS)))
    if M.sel <= M.scroll then M.scroll = M.sel - 1 end
    if M.sel > M.scroll + LIST_ROWS then M.scroll = M.sel - LIST_ROWS end
    se(5)
  end

  local function firstSelectable(rows)
    for i = 1, #rows do if selectable(rows, i) then return i end end
    return 1
  end

  local function switchTab(dir)
    M.tab = (M.tab - 1 + dir) % #TABS + 1
    M.sel, M.scroll, M.detail = 1, 0, nil
    if TABS[M.tab] == "MOVES" then M.sel = firstSelectable(movesData() or {}) end
    if TABS[M.tab] == "FAMILY" then
      local fam = familyData()
      if fam then for i, m in ipairs(fam.flat) do if m.species == M.species then M.sel = i end end end
    end
    se(5)
  end

  function M.input(input)
    if not M.open then return false end
    local p = function(k) return input:wasPressed(k) end
    -- sort popup (LOCATION)
    if M.sortOpen then
      local n = #D.SORTS
      if p("up") then M.sortCursor = (M.sortCursor - 2) % n + 1; se(5)
      elseif p("down") then M.sortCursor = M.sortCursor % n + 1; se(5)
      elseif p("a") then
        M.sortMode = D.SORTS[M.sortCursor].id
        M.sortOpen, M.sel, M.scroll = false, 1, 0
        se(5)
      elseif p("b") or p("start") then M.sortOpen = false; se(5) end
      return true
    end
    -- move details
    if M.detail then
      if p("a") or p("b") then M.detail = nil; se(5) end
      return true
    end
    if p("b") then M.close(); se(5) return true end
    if p("l") then switchTab(-1) return true end
    if p("r") then switchTab(1) return true end
    local tab = TABS[M.tab]
    if tab == "FAMILY" then
      local fam = familyData()
      local n = fam and #fam.flat or 0
      if n > 0 then
        if p("up") then M.sel = (M.sel - 2) % n + 1; se(5)
        elseif p("down") then M.sel = M.sel % n + 1; se(5)
        elseif p("a") then
          local m = fam.flat[M.sel]
          if m and m.species ~= M.species and seen(m.species) then
            local jump = M.onJump
            M.close()
            if jump then jump(m.species) end
          else
            se(5)
          end
        end
      end
    elseif tab == "MOVES" then
      local rows = movesData() or {}
      if p("up") then stepList(rows, -1)
      elseif p("down") then stepList(rows, 1)
      elseif p("left") then pageList(rows, -1)
      elseif p("right") then pageList(rows, 1)
      elseif p("a") and selectable(rows, M.sel) then
        M.detail = D.move(rows[M.sel].id); se(5)
      end
    elseif tab == "LOCATION" then
      local rows = locData() or {}
      if p("up") and #rows > 0 then stepList(rows, -1)
      elseif p("down") and #rows > 0 then stepList(rows, 1)
      elseif p("left") and #rows > 0 then pageList(rows, -1)
      elseif p("right") and #rows > 0 then pageList(rows, 1)
      elseif p("a") then
        M.sortOpen = true
        for i, s in ipairs(D.SORTS) do if s.id == M.sortMode then M.sortCursor = i end end
        se(5)
      end
    elseif tab == "STATS" then
      if p("a") then
        pcall(function()
          local Audio = require("src.core.game3.audio")
          if Audio.playCry then Audio.playCry(M.species) end
        end)
      end
    end
    return true
  end

  -- ------- drawing

  local PX, PY, PW, PH = 4, 36, 232, 108

  local function panel(x, y, w, h, fill, border)
    color(border or { 0.22, 0.22, 0.25, 1 })
    love.graphics.rectangle("fill", x, y, w, h, 4, 4)
    color(fill or CREAM)
    love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2, 3, 3)
  end

  local function band(x, y, w, h, pal)
    color(pal.light, 0.55)
    love.graphics.rectangle("fill", x, y, w, h, 3, 3)
    color(pal.main)
    love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1, 3, 3)
  end

  local function scrollMarks(total, scroll, visible, pal)
    if total <= visible then return end
    local x = PX + PW - 7
    color(pal.main)
    if scroll > 0 then love.graphics.polygon("fill", x - 3, PY + 7, x + 3, PY + 7, x, PY + 3) end
    if scroll + visible < total then
      love.graphics.polygon("fill", x - 3, PY + PH - 7, x + 3, PY + PH - 7, x, PY + PH - 3)
    end
  end

  local function drawStats(pal)
    local st = data("stats", D.stats)
    -- picture
    panel(PX + 4, PY + 4, 70, 70, { 1, 1, 1, 1 })
    pcall(function()
      local pic = D.Pokemon.frontPic and D.Pokemon.frontPic(M.species)
      if pic and pic.image then love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(pic.image, PX + 7, PY + 7) end
    end)
    local small = opts(nil, nil, true, 90)
    if not st then text("No data.", PX + 84, PY + 6, opts()) return end
    -- Ruby/Sapphire: one row higher so the three lines stay in the panel
    local y = PY + (rsFont() and 73 or 76)
    if st.catchRate then text(("CATCH RATE %d"):format(st.catchRate), PX + 6, y, small); y = y + 9 end
    if st.baseExp then text(("BASE EXP %d"):format(st.baseExp), PX + 6, y, small); y = y + 9 end
    if st.growth then text(st.growth, PX + 6, y, small) end
    -- base stats
    local sx = PX + 82
    text("BASE STATS", sx, PY + 1, opts(pal.main, nil, true))
    right(("TOTAL %d"):format(st.total), PX + PW - 6, PY + 1, opts(nil, nil, true))
    for i, r in ipairs(st.rows) do
      local ry = PY + 13 + (i - 1) * 11
      text(r[1], sx, ry, small)
      right(tostring(r[2]), sx + 70, ry, small)
      local bx, bw = sx + 74, PW - (sx + 74 - PX) - 8
      color({ 0.25, 0.25, 0.28, 1 })
      love.graphics.rectangle("fill", bx, ry + 5, bw, 5, 2, 2)
      local v = r[2]
      local c = v < 50 and { 0.93, 0.33, 0.25 } or v < 80 and { 0.97, 0.62, 0.20 }
        or v < 100 and { 0.95, 0.85, 0.20 } or v < 120 and { 0.40, 0.80, 0.30 } or { 0.20, 0.72, 0.80 }
      color(c)
      love.graphics.rectangle("fill", bx + 1, ry + 6, math.max(1, math.floor((bw - 2) * math.min(1, v / 180))), 3, 1, 1)
    end
    if #st.abilities > 0 then
      text(#st.abilities > 1 and "ABILITIES" or "ABILITY", sx, PY + 81, opts(pal.main, nil, true))
      text(table.concat(st.abilities, ", "), sx + 6, PY + 91, opts(nil, nil, true, PW - (sx - PX) - 10))
    end
  end

  local function drawFamily(pal)
    local fam = familyData()
    if not fam or #fam.flat <= 1 then
      centre("This POKéMON does not evolve.", PX + PW / 2, PY + PH / 2 - 8, opts())
      return
    end
    local stages = #fam.stages
    local colW = math.floor((PW - 8) / stages)
    for s = 1, stages do
      local list = fam.stages[s]
      local compact = #list > 3
      local cardH = compact and math.floor((PH - 8) / #list) or 32
      local totalH = cardH * #list
      local top = PY + math.floor((PH - totalH) / 2)
      for i, m in ipairs(list) do
        local cx, cy = PX + 4 + (s - 1) * colW, top + (i - 1) * cardH
        local known = seen(m.species)
        local isSel = fam.flat[M.sel] == m
        if isSel then band(cx + 2, cy + 1, colW - 4, cardH - 2, pal) end
        if m.species == M.species then
          color(pal.main); love.graphics.rectangle("fill", cx + 3, cy + 2, 2, cardH - 4)
        end
        local name = known and D.name(m.species) or "?????"
        local nameX = cx + (compact and 8 or 34)
        if not compact then icon(m.species, cx + 2, cy - 2, known) end
        text(name, nameX, cy + (compact and -2 or 1), opts(nil, nil, true, colW - (nameX - cx) - 2))
        if m.method then
          text(m.method, nameX, cy + (compact and 6 or 11), opts(pal.main, nil, true, colW - (nameX - cx) - 2))
        end
      end
      if s > 1 then
        local ax = PX + 4 + (s - 1) * colW - 2
        color(pal.main)
        love.graphics.polygon("fill", ax - 3, PY + PH / 2 - 4, ax - 3, PY + PH / 2 + 4, ax + 1, PY + PH / 2)
      end
    end
  end

  local function drawMoveList(pal)
    local rows = movesData() or {}
    if #rows == 0 then centre("No moves.", PX + PW / 2, PY + 40, opts()) return end
    local small = opts(nil, nil, true, 120)
    for vi = 1, LIST_ROWS do
      local i = M.scroll + vi
      local r = rows[i]
      if not r then break end
      local ry = PY + 4 + (vi - 1) * 13
      if r.header then
        color(pal.main)
        love.graphics.rectangle("fill", PX + 6, ry + 1, PW - 22, 11, 3, 3)
        text(r.header, PX + 10, ry - 2, opts({ 1, 1, 1, 1 }, { pal.dark[1], pal.dark[2], pal.dark[3], 1 }, true))
      else
        if i == M.sel then band(PX + 6, ry, PW - 22, 13, pal); cursorAt(PX + 8, ry - 1) end
        text(r.source, PX + 18, ry - 2, opts(pal.main, nil, true))
        text(r.name, PX + 56, ry - 2, small)
        typeBadge(r.type, PX + PW - 52, ry + 1)
      end
    end
    scrollMarks(#rows, M.scroll, LIST_ROWS, pal)
  end

  local function drawMoveDetail(pal)
    local d = M.detail
    local W, H = 176, 100
    local x, y = math.floor((240 - W) / 2), math.floor((160 - H) / 2)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x + 3, y + 3, W, H, 5, 5)
    panel(x, y, W, H, CREAM, pal.dark)
    color(pal.main)
    love.graphics.rectangle("fill", x + 2, y + 2, W - 4, 14, 4, 4)
    love.graphics.rectangle("fill", x + 2, y + 10, W - 4, 6)
    text(d.name, x + 8, y + 1, opts({ 1, 1, 1, 1 }, { pal.dark[1], pal.dark[2], pal.dark[3], 1 }))
    typeBadge(d.type, x + W - 38, y + 3)
    local small = opts(nil, nil, true)
    local function stat(label, v, cx)
      text(label, cx, y + 18, opts(pal.main, nil, true))
      text(v, cx, y + 27, small)
    end
    stat("POWER", d.power > 1 and tostring(d.power) or "---", x + 8)
    stat("ACCURACY", d.accuracy > 0 and tostring(d.accuracy) or "---", x + 62)
    stat("PP", tostring(d.pp), x + 130)
    local okW, wrapped = pcall(FrlgFont.wrap, d.desc or "", W - 16, { small = true })
    local lineY = y + 42
    for line in tostring(okW and wrapped or d.desc or ""):gmatch("[^\n]+") do
      text(line, x + 8, lineY, small)
      lineY = lineY + 10
      if lineY > y + H - 12 then break end
    end
  end

  local function drawLocations(pal)
    local rows = locData() or {}
    if #rows == 0 then
      centre("Not found in the wild.", PX + PW / 2, PY + PH / 2 - 8, opts())
      return
    end
    local small = opts(nil, nil, true, 84)
    local PILL_X, PILL_W = PX + 102, 54
    for vi = 1, LIST_ROWS do
      local i = M.scroll + vi
      local r = rows[i]
      if not r then break end
      local ry = PY + 4 + (vi - 1) * 13
      if i == M.sel then band(PX + 6, ry, PW - 14, 13, pal); cursorAt(PX + 8, ry - 1) end
      text(r.loc, PX + 18, ry - 2, small)
      local k = D.KINDS[r.kind] or D.KINDS.grass
      color(k[2])
      love.graphics.rectangle("fill", PILL_X, ry + 1, PILL_W, 11, 3, 3)
      local pillText = opts({ 1, 1, 1, 1 }, { 0, 0, 0, 0.30 }, true, PILL_W)
      text(k[1], PILL_X + math.floor((PILL_W - width(k[1], pillText)) / 2), ry - 2, pillText)
      local lv = r.lo == r.hi and ("LV %d"):format(r.lo) or ("LV %d-%d"):format(r.lo, r.hi)
      text(lv, PILL_X + PILL_W + 6, ry - 2, small)
      local rate = tonumber(r.rate) or 0
      local rateText = (rate % 1 == 0) and ("%d%%"):format(rate) or ("%.1f%%"):format(rate)
      right(rateText, PX + PW - 10, ry - 2, small)
    end
    scrollMarks(#rows, M.scroll, LIST_ROWS, pal)
  end

  local function drawSortPopup(pal)
    local n = #D.SORTS
    local W, H = 132, 18 + n * 14 + 14
    local x, y = math.floor((240 - W) / 2), math.floor((160 - H) / 2)
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle("fill", x + 3, y + 3, W, H, 5, 5)
    panel(x, y, W, H, CREAM, pal.dark)
    color(pal.main)
    love.graphics.rectangle("fill", x + 2, y + 2, W - 4, 14, 4, 4)
    love.graphics.rectangle("fill", x + 2, y + 10, W - 4, 6)
    centre("SORT BY", x + W / 2, y + 1, opts({ 1, 1, 1, 1 }, { pal.dark[1], pal.dark[2], pal.dark[3], 1 }))
    for i, s in ipairs(D.SORTS) do
      local ry = y + 18 + (i - 1) * 14
      if i == M.sortCursor then band(x + 5, ry, W - 10, 14, pal); cursorAt(x + 8, ry) end
      if s.id == M.sortMode then color(pal.main); love.graphics.circle("fill", x + W - 12, ry + 7, 2.5) end
      text(s.label, x + 18, ry, opts(nil, nil, true))
    end
    centre("A PICK    B BACK", x + W / 2, y + H - 15, opts(nil, nil, true))
  end

  function M.draw()
    if not M.open then return end
    local pal = palette()
    love.graphics.push("all")
    -- backdrop with a soft grid
    color(pal.dark)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    color(pal.main, 0.18)
    for gx = 0, 240, 8 do love.graphics.rectangle("fill", gx, 0, 1, 160) end
    for gy = 0, 160, 8 do love.graphics.rectangle("fill", 0, gy, 240, 1) end
    -- title bar
    color(pal.main)
    love.graphics.rectangle("fill", 0, 0, 240, 20)
    color(pal.light)
    love.graphics.rectangle("fill", 0, 20, 240, 1)
    icon(M.species, 2, -9, true)
    local title = ("No.%03d  %s"):format(D.national(M.species), D.name(M.species))
    text(title, 34, 2, opts({ 1, 1, 1, 1 }, { pal.dark[1], pal.dark[2], pal.dark[3], 1 }))
    local types = D.types(M.species)
    for i = #types, 1, -1 do typeBadge(types[i], 240 - 4 - (#types - i + 1) * 34, 4) end
    -- tabs
    for i, name in ipairs(TABS) do
      local tx, tw = 4 + (i - 1) * 58, 56
      if i == M.tab then
        color(CREAM); love.graphics.rectangle("fill", tx, 23, tw, 14, 3, 3)
        color(pal.main); love.graphics.rectangle("fill", tx, 23, tw, 2, 1, 1)
        centre(name, tx + tw / 2, 21, opts(pal.main, nil, true))
      else
        color(pal.main, 0.55); love.graphics.rectangle("fill", tx, 24, tw, 12, 3, 3)
        centre(name, tx + tw / 2, 21, opts({ 1, 1, 1, 0.9 }, { 0, 0, 0, 0.3 }, true))
      end
    end
    -- panel
    panel(PX, PY, PW, PH, CREAM, pal.light)
    local tab = TABS[M.tab]
    if tab == "STATS" then drawStats(pal)
    elseif tab == "FAMILY" then drawFamily(pal)
    elseif tab == "MOVES" then drawMoveList(pal)
    elseif tab == "LOCATION" then drawLocations(pal) end
    -- footer hint
    local hints = {
      STATS = "LB/RB TAB    A CRY    B BACK",
      FAMILY = "LB/RB TAB    U/D SELECT    A VIEW    B BACK",
      MOVES = "LB/RB TAB    U/D/L/R MOVE    A DETAILS    B BACK",
      LOCATION = "LB/RB TAB    U/D/L/R MOVE    A SORT    B BACK",
    }
    centre(hints[tab], 120, 145, opts({ 1, 1, 1, 0.95 }, { 0, 0, 0, 0.4 }, true))
    if M.detail then drawMoveDetail(pal) end
    if M.sortOpen then drawSortPopup(pal) end
    love.graphics.pop()
  end

  return M
end
