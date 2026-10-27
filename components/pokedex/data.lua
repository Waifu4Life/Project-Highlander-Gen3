-- Data for the Pokédex 2nd screen, read from the game's own tables.
return function(ctx)
  local D = {}
  local S = ctx.settings

  local function req(name)
    local ok, m = pcall(require, name)
    return ok and type(m) == "table" and m or nil
  end

  local Pokemon = req("src.core.game3.pokemon")
  D.Pokemon = Pokemon

  local function call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b = pcall(fn, ...)
    if ok then return a, b end
    return nil
  end

  function D.name(sp)
    local n = Pokemon and call(Pokemon.name, sp)
    return (type(n) == "string" and n ~= "") and n or ("#" .. tostring(sp))
  end

  function D.national(sp)
    return tonumber(Pokemon and call(Pokemon.national, sp)) or tonumber(sp) or 0
  end

  function D.types(sp)
    local t = Pokemon and call(Pokemon.types, sp) or { 0, 0 }
    local a, b = tonumber(t[1]) or 0, tonumber(t[2]) or 0
    if b == a then return { a } end
    return { a, b }
  end

  -- ------- stats

  local GROWTH = { [0] = "MEDIUM FAST", "ERRATIC", "FLUCTUATING", "MEDIUM SLOW", "FAST", "SLOW" }

  function D.stats(sp)
    local s = Pokemon and call(Pokemon.stats, sp)
    if type(s) ~= "table" then return nil end
    local function pick(key, i) return tonumber(s[key]) or tonumber(s[i]) or 0 end
    -- pret order in the table: hp, atk, def, spe, spa, spd
    local rows = {
      { "HP", pick("hp", 1) }, { "ATTACK", pick("atk", 2) }, { "DEFENSE", pick("def", 3) },
      { "SP. ATK", pick("spa", 5) }, { "SP. DEF", pick("spd", 6) }, { "SPEED", pick("spe", 4) },
    }
    local total = 0
    for _, r in ipairs(rows) do total = total + r[2] end
    local meta = Pokemon and call(Pokemon.speciesMeta, sp) or {}
    local abilities = {}
    local ab = Pokemon and call(Pokemon.abilities, sp) or {}
    for i = 1, 2 do
      local id = tonumber(ab[i]) or 0
      if id > 0 then
        local n = call(Pokemon.abilityName, id)
        if type(n) == "string" and n ~= "" and n ~= abilities[1] then abilities[#abilities + 1] = n end
      end
    end
    local growth = tonumber(meta.growthRate)
    return {
      rows = rows, total = total,
      catchRate = tonumber(meta.catchRate),
      baseExp = tonumber(call(Pokemon.expYield, sp)) or tonumber(meta.expYield),
      growth = growth and GROWTH[growth % 6] or nil,
      abilities = abilities,
    }
  end

  -- ------- family

  local parents = nil -- target -> { species, evo }
  local function buildParents()
    parents = {}
    local count = 0
    local manifest = Pokemon and Pokemon._manifest
    local n = tonumber(manifest and manifest.numSpecies) or 412
    for sp = 1, n + 20 do
      local evos = call(Pokemon.evolutions, sp)
      if type(evos) == "table" then
        for _, evo in ipairs(evos) do
          local target = tonumber(evo.target or evo[3])
          if target and target > 0 and not parents[target] then
            parents[target] = { species = sp, evo = evo }
            count = count + 1
          end
        end
      end
    end
    return count
  end

  local function itemName(id)
    local ok, ItemsData = pcall(require, "src.core.game3.items_data")
    if ok and ItemsData and ItemsData.displayName then
      local okN, n = pcall(ItemsData.displayName, id)
      if okN and type(n) == "string" then return n end
    end
    return "ITEM " .. tostring(id)
  end

  function D.methodText(evo)
    local m = tonumber(evo.method or evo[1]) or 0
    local p = tonumber(evo.param or evo[2]) or 0
    if m == 1 then return "FRIENDSHIP"
    elseif m == 2 then return "FRIENDSHIP DAY"
    elseif m == 3 then return "FRIENDSHIP NIGHT"
    elseif m == 4 or m == 13 then return ("LV %d"):format(p)
    elseif m == 5 then return "TRADE"
    elseif m == 6 then return "TRADE w/ " .. itemName(p)
    elseif m == 7 then return itemName(p)
    elseif m == 8 then return ("LV %d HIGH ATK"):format(p)
    elseif m == 9 then return ("LV %d EVEN STATS"):format(p)
    elseif m == 10 then return ("LV %d HIGH DEF"):format(p)
    elseif m == 11 or m == 12 then return ("LV %d (RANDOM)"):format(p)
    elseif m == 14 then return ("LV %d (FREE SLOT)"):format(p)
    elseif m == 15 then return ("BEAUTY %d"):format(p)
    end
    return "?"
  end

  -- { stages = { {member, ...}, ... }, flat = { member... } }, member = { species, method, stage }
  function D.family(sp)
    if not parents then buildParents() end
    local root, guard = sp, 0
    while parents[root] and guard < 5 do root = parents[root].species; guard = guard + 1 end
    local stages, flat = {}, {}
    local function add(species, stage, method)
      stages[stage] = stages[stage] or {}
      local m = { species = species, stage = stage, method = method }
      table.insert(stages[stage], m)
      flat[#flat + 1] = m
      if stage < 4 then
        local evos = call(Pokemon.evolutions, species)
        if type(evos) == "table" then
          local seen = {}
          for _, evo in ipairs(evos) do
            local target = tonumber(evo.target or evo[3])
            if target and target > 0 and not seen[target] then
              seen[target] = true
              add(target, stage + 1, D.methodText(evo))
            end
          end
        end
      end
    end
    add(root, 1, nil)
    -- order: stage by stage
    table.sort(flat, function(a, b)
      if a.stage ~= b.stage then return a.stage < b.stage end
      local ia, ib
      for i, m in ipairs(stages[a.stage]) do if m == a then ia = i end if m == b then ib = i end end
      return (ia or 0) < (ib or 0)
    end)
    return { stages = stages, flat = flat, root = root }
  end

  -- ------- moves

  local function moveInfo(id)
    local def = Pokemon and call(Pokemon.battleMove, id) or nil
    local name = Pokemon and call(Pokemon.moveName, id)
    if type(name) ~= "string" or name == "" then name = def and def.name or ("MOVE " .. tostring(id)) end
    return name, def
  end

  function D.move(id)
    local name, def = moveInfo(id)
    local desc
    local okSD, SummaryData = pcall(require, "src.core.game3.summary_data")
    if okSD and SummaryData and SummaryData.moveDescription then
      local okD, d = pcall(SummaryData.moveDescription, id, name)
      if okD and type(d) == "string" then desc = d end
    end
    def = def or {}
    return {
      id = id, name = name, type = def.type or def.kind or "NORMAL",
      power = tonumber(def.power) or 0, accuracy = tonumber(def.accuracy) or 0,
      pp = tonumber(def.pp) or 0, desc = desc or "",
    }
  end

  -- rows: { header = "LEVEL UP" } or { source = "LV 7", id = moveId, name, type }
  function D.moves(sp)
    local rows = {}
    local function section(title, list)
      if #list == 0 then return end
      rows[#rows + 1] = { header = title }
      for _, r in ipairs(list) do rows[#rows + 1] = r end
    end
    local function row(source, id)
      local name, def = moveInfo(id)
      return { source = source, id = id, name = name, type = def and (def.type or def.kind) or "NORMAL" }
    end
    -- level up
    local lv = {}
    local learnset = Pokemon and call(Pokemon.learnset, sp) or {}
    for _, e in ipairs(learnset) do
      local level = tonumber(e[1] or e.level) or 0
      local id = tonumber(e[2] or e.move) or 0
      if id > 0 then
        local r = row(level <= 1 and "LV  1" or ("LV %2d"):format(level), id)
        r.level = level
        lv[#lv + 1] = r
      end
    end
    table.sort(lv, function(a, b) return a.level < b.level end)
    section("LEVEL UP", lv)
    -- TM / HM
    local tm = {}
    if Pokemon and type(Pokemon.canLearnTmIndex) == "function" then
      for idx = 0, 57 do
        if call(Pokemon.canLearnTmIndex, sp, idx) then
          local id = tonumber(call(Pokemon.moveFromTmItem, 289 + idx))
          if id and id > 0 then
            tm[#tm + 1] = row(idx < 50 and ("TM%02d"):format(idx + 1) or ("HM%02d"):format(idx - 49), id)
          end
        end
      end
    end
    section("TM / HM", tm)
    -- move tutors
    local tutor = {}
    local MoveLearn = req("src.core.game3.move_learn")
    if MoveLearn and type(MoveLearn.canLearnTutorMove) == "function" then
      local count = tonumber(MoveLearn.TUTOR_MOVE_COUNT) or 15
      local seen = {}
      for t = 0, count + 3 do
        if call(MoveLearn.canLearnTutorMove, sp, t) then
          local id = tonumber(call(MoveLearn.tutorMove, t))
          if id and id > 0 and not seen[id] then
            seen[id] = true
            tutor[#tutor + 1] = row("TUTOR", id)
          end
        end
      end
    end
    section("MOVE TUTOR", tutor)
    -- egg moves (from the first form of the family, like breeding)
    local egg = {}
    local root = sp
    pcall(function() root = D.family(sp).root or sp end)
    local list = Pokemon and (call(Pokemon.eggMoves, sp) or call(Pokemon.eggMoves, root)) or nil
    if type(list) == "table" then
      for _, id in ipairs(list) do
        id = tonumber(id)
        if id and id > 0 then egg[#egg + 1] = row("EGG", id) end
      end
    end
    section("EGG MOVES", egg)
    return rows
  end

  -- ------- locations

  local LAND = { 20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1 }
  local WATER = { 60, 30, 5, 4, 1 }
  local RODS = {
    { kind = "old", from = 1, weights = { 70, 30 } },
    { kind = "good", from = 3, weights = { 60, 20, 20 } },
    { kind = "super", from = 6, weights = { 40, 40, 15, 4, 1 } },
  }

  D.KINDS = {
    grass = { "GRASS", { 0.20, 0.70, 0.25 } },
    cave = { "CAVE", { 0.50, 0.50, 0.56 } },
    inside = { "INSIDE", { 0.55, 0.42, 0.70 } },
    surf = { "SURF", { 0.15, 0.35, 0.80 } },
    rock = { "ROCK SMASH", { 0.62, 0.40, 0.16 } },
    old = { "OLD ROD", { 0.30, 0.62, 0.90 } },
    good = { "GOOD ROD", { 0.20, 0.52, 0.84 } },
    super = { "SUPER ROD", { 0.10, 0.40, 0.74 } },
  }

  local function slotsOf(area)
    if type(area) ~= "table" then return nil end
    return area.slots or area.mons or (#area > 0 and area) or nil
  end

  local function slotSpecies(e)
    if type(e) ~= "table" then return nil end
    return tonumber(e.species or e.speciesId or e[1])
  end

  local function slotLevels(e)
    local lo = tonumber(e.minLevel or e.min or e.level or e[2]) or 0
    local hi = tonumber(e.maxLevel or e.max or e.level or e[3] or e[2]) or lo
    if hi < lo then lo, hi = hi, lo end
    return lo, hi
  end

  local placeCache = {}

  local function pretty(key)
    local name = tostring(key):upper()
    for _, pre in ipairs({ "MAP_", "FR_", "LG_", "EM_", "RS_", "RU_", "SA_", "E_", "R_", "S_" }) do
      if name:sub(1, #pre) == pre then name = name:sub(#pre + 1) break end
    end
    name = name:gsub("_", " "):gsub("ROUTE ?(%d+)", "ROUTE %1"):gsub("%s+", " ")
    return name
  end

  -- the map id the encounter key stands for ("0:17" and pret names included)
  local function canonical(key)
    local MapCatalog = req("src.import.gba.map_catalog")
    local s = tostring(key)
    if MapCatalog then
      local g, n = s:match("^(%d+):(%d+)$")
      if g and MapCatalog.mapIdFor then
        local ok, id = pcall(MapCatalog.mapIdFor, tonumber(g), tonumber(n))
        if ok and id then return id end
      end
      if MapCatalog.resolve then
        local ok, id = pcall(MapCatalog.resolve, s)
        if ok and type(id) == "string" then return id end
      end
    end
    return s
  end

  local function placeName(key)
    if placeCache[key] then return placeCache[key] end
    local id = canonical(key)
    local g = S.game and S.game()
    local maps = g and g.data and g.data.maps
    local def = maps and (maps[id] or maps[key]) or nil
    local name
    local sec = def and tonumber(def.regionMapSectionId or def.region_map_section_id or def.mapsec)
    if S.isHoenn() then
      local Mapsec = req("src.ui.game3.rse.mapsec")
      if Mapsec and sec then
        local ok, n = pcall(Mapsec.name, sec)
        if ok and type(n) == "string" and n:find("%S") then name = n end
      end
    else
      local Sections = req("src.import.gba.map_sections_extract")
      if Sections and Sections.getPlaceName then
        local ok, n = pcall(Sections.getPlaceName, id, sec)
        if ok and type(n) == "string" and n ~= "" and n ~= id and n ~= tostring(key) and not n:find("^%d+:%d+$") then
          name = n
        end
      end
    end
    if not name then name = pretty(id) end
    placeCache[key] = { name = name, def = def }
    return placeCache[key]
  end

  local CAVE_WORDS = { "CAVE", "TUNNEL", "MT%.", "MT ", "MOUNT", "VICTORY ROAD", "SEAFOAM", "DEN", "CHAMBER",
    "RUINS", "ROCK", "ISLAND CAVE", "GRANITE", "METEOR", "DESERT UNDERPASS", "SHOAL", "SEAFLOOR", "CAVERN",
    "TRENCH", "PATH", "DIGLETT", "BERRY FOREST" }
  local INSIDE_WORDS = { "TOWER", "MANSION", "PLANT", "HIDEOUT", "SHIP", "S.S.", "HOUSE", "GYM", "LAB" }

  local function landKind(place)
    local def = place.def
    local mt = def and (def.mapType or def.type)
    if type(mt) == "string" then
      local u = mt:upper()
      if u:find("UNDERGROUND") then return "cave" end
      if u:find("INDOOR") then return "inside" end
    elseif tonumber(mt) == 5 then return "cave"
    elseif tonumber(mt) == 8 then return "inside" end
    local n = " " .. place.name:upper() .. " "
    if n:find("FOREST") and not n:find("BERRY") then return "grass" end
    for _, w in ipairs(INSIDE_WORDS) do if n:find(w, 1, true) then return "inside" end end
    for _, w in ipairs(CAVE_WORDS) do if n:find(w) then return "cave" end end
    return "grass"
  end

  -- rows: { loc, kind, lo, hi, rate }
  function D.locations(sp)
    local Enc = req("src.core.game3.encounters")
    if not Enc then return {} end
    pcall(Enc.ensureLoaded)
    -- GET OTHER GAME EXCLUSIVES (Fill Kanto / Fill Hoenn Regional Dex): every
    -- slot of an exclusive has a 50% chance to be the other game's counterpart,
    -- so the Pokémon is found at half rate in its own slots and in its
    -- counterpart's slots.
    local KA = ctx.kantoAll
    if S.isHoenn() and ctx.hoennAll then KA = ctx.hoennAll end
    if KA and KA.refreshTables then pcall(KA.refreshTables) end
    local JO = ctx.johto
    if JO and JO.refreshTables then pcall(JO.refreshTables) end
    local other, share = nil, 1
    if KA and KA.swapFor then
      local ok, o = pcall(KA.swapFor, sp)
      if ok and tonumber(o) then other, share = tonumber(o), 0.5 end
    end
    local tables = Enc._tables
    if type(tables) ~= "table" then return {} end
    local merged = {}
    local function add(key, kind, lo, hi, rate)
      local place = placeName(key)
      if kind == "land" then kind = landKind(place) end
      local id = place.name .. "|" .. kind
      local r = merged[id]
      if not r then
        r = { loc = place.name, kind = kind, lo = lo, hi = hi, rate = rate }
        merged[id] = r
      else
        r.lo, r.hi = math.min(r.lo, lo), math.max(r.hi, hi)
        r.rate = math.max(r.rate, rate)
      end
    end
    local function scan(key, area, kind, weights, from)
      local slots = slotsOf(area)
      if not slots then return end
      local rate, lo, hi = 0, 999, 0
      for i, w in ipairs(weights) do
        local e = slots[(from or 1) + i - 1]
        -- JOHTO POKéMON HELPER: a slot shared with the other game is each half the time
        local dual = JO and JO.dualOf and type(e) == "table" and JO.dualOf(e) or nil
        if dual then
          for _, alt in ipairs({ dual.a, dual.b }) do
            local s = slotSpecies(alt)
            if s and (s == sp or s == other) then
              rate = rate + w * 0.5 * share
              local a, b = slotLevels(alt)
              lo, hi = math.min(lo, a), math.max(hi, b)
            end
          end
        else
          local s = slotSpecies(e)
          if s and (s == sp or s == other) then
            rate = rate + w * share
            local a, b = slotLevels(e)
            lo, hi = math.min(lo, a), math.max(hi, b)
          end
        end
      end
      if rate > 0 then add(key, kind, lo, hi, rate) end
    end
    for key, t in pairs(tables) do
      if type(t) == "table" then
        scan(key, t.land or t.grass, "land", LAND)
        scan(key, t.water, "surf", WATER)
        scan(key, t.rocks or t.rock_smash, "rock", WATER)
        if t.fishing then
          for _, rod in ipairs(RODS) do scan(key, t.fishing, rod.kind, rod.weights, rod.from) end
        end
      end
    end
    local out = {}
    for _, r in pairs(merged) do out[#out + 1] = r end
    return out
  end

  local function natKey(s)
    return tostring(s or ""):upper():gsub("%d+", function(d) return ("%05d"):format(tonumber(d)) end)
  end

  D.SORTS = {
    { id = "location", label = "LOCATION" },
    { id = "location_rev", label = "REVERSE LOCATION" },
    { id = "level", label = "LEVEL" },
    { id = "level_rev", label = "REVERSE LEVEL" },
    { id = "rate", label = "RATE" },
    { id = "rate_rev", label = "REVERSE RATE" },
  }

  function D.sortLocations(rows, mode)
    table.sort(rows, function(a, b)
      local la, lb = natKey(a.loc), natKey(b.loc)
      if mode == "location_rev" then if la ~= lb then return la > lb end
      elseif mode == "level" then if a.lo ~= b.lo then return a.lo < b.lo end
      elseif mode == "level_rev" then if a.lo ~= b.lo then return a.lo > b.lo end
      elseif mode == "rate" then if a.rate ~= b.rate then return a.rate < b.rate end
      elseif mode == "rate_rev" then if a.rate ~= b.rate then return a.rate > b.rate end
      end
      if la ~= lb then return la < lb end
      return a.kind < b.kind
    end)
    return rows
  end

  return D
end
