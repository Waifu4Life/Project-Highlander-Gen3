-- JOHTO POKéMON HELPER, Ruby / Sapphire / Emerald part. Loaded by
-- components/johto/main.lua, which hands over its helpers in D.
return function(D)
  local H = {}
  local on, warn, info, req, now = D.on, D.warn, D.info, D.req, D.now
  local session, version, hoenn, rs, emerald = D.session, D.version, D.hoenn, D.rs, D.emerald
  local sget, sset = D.sget, D.sset
  local say, ask = D.say, D.ask
  local objects, gfx, gfxOf, face, hideObject = D.objects, D.gfx, D.gfxOf, D.face, D.hideObject
  local ctx = D.ctx

  -- ================================================================ SAFARI ZONE
  -- GET EMERALD GAME EXCLUSIVES (Ruby/Sapphire, Champion): the Johto Pokémon of
  -- Emerald's Safari Zone 5 and 6 (levels read from your installed Emerald) are
  -- split four by four over Ruby/Sapphire's four areas, plus Smeargle and
  -- Sudowoodo (one each). EXTRAS IN SAFARI ZONE 5&6 (Emerald): Smeargle in the
  -- Northeast area, Sudowoodo in the Southeast one. A new Pokémon only takes a
  -- slot whose Pokémon is still in another slot of that area (or in another
  -- Safari area), the closest in rate to its Emerald slot.

  local JOHTO16 = { 163, 165, 167, 179, 190, 191, 194, 204, 207, 209, 213, 216, 224, 228, 234, 241 }
  local SMEARGLE, SUDOWOODO = 235, 185
  local RS_ZONES = { "26:0", "26:1", "26:2", "26:3" } -- Northwest, Northeast, Southwest, Southeast
  local EM_EXT = { "26:12", "26:13" } -- Safari Zone Northeast (5) and Southeast (6)
  local LAND_W = { 20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1 }
  local WATER_W = { 60, 30, 5, 4, 1 }
  local FISH_W = { 70, 30, 60, 20, 20, 40, 40, 15, 4, 1 }
  local function rod(i) if i <= 2 then return 1 elseif i <= 5 then return 2 end return 3 end
  local function weightOf(area, i)
    if area == "land" or area == "grass" then return LAND_W[i] or 1 end
    if area == "fishing" then return FISH_W[i] or 1 end
    return WATER_W[i] or 1
  end

  local original = setmetatable({}, { __mode = "k" })
  local safState = nil
  local emData, emTried = nil, false
  local function loadEmerald()
    if emTried then return emData end
    emTried = true
    emData = D.readOtherLua("emerald", "encounters.lua")
    info("johto safari: %s", emData and "using Emerald's encounter tables" or "Emerald not installed, nothing added")
    return emData
  end

  local function restoreSafari()
    for slot, o in pairs(original) do
      slot.species, slot.minLevel, slot.maxLevel = o.species, o.minLevel, o.maxLevel
      original[slot] = nil
    end
  end

  local function applySafari()
    local Enc = req("src.core.game3.encounters")
    local tables = Enc and Enc._tables
    if type(tables) ~= "table" then return end
    local v = version()
    local want = false
    if rs() then want = on("johto_emerald") and D.champion()
    elseif emerald() then want = on("johto_extras") end
    local state = tostring(tables) .. "|" .. tostring(v) .. "|" .. tostring(want)
    if state == safState then return end
    safState = state
    restoreSafari()
    if not want or not next(tables) then return end
    local mine = D.tablesByMap(tables)

    local newSet = { [SMEARGLE] = true, [SUDOWOODO] = true }
    for _, sp in ipairs(JOHTO16) do newSet[sp] = true end
    local zoneKeys = rs() and RS_ZONES or EM_EXT
    -- species found anywhere in the Safari Zone (a slot of it can go)
    local function inOtherZone(sp, exceptKey)
      for _, k in ipairs(zoneKeys) do
        local t = mine[k]
        if t and k ~= exceptKey then
          for _, area in ipairs(D.AREAS) do
            for _, e in ipairs(D.slotsOf(t[area]) or {}) do
              if tonumber(e.species) == sp and not original[e] then return true end
            end
          end
        end
      end
      return false
    end

    local changed = 0
    local function place(key, area, sp, src, minL, maxL)
      local t = mine[key]
      local slots = t and D.slotsOf(t[area])
      if not slots then return false end
      local function count(s)
        local n = 0
        for _, e in ipairs(slots) do if tonumber(e.species) == s and not original[e] then n = n + 1 end end
        return n
      end
      local want = weightOf(area, src)
      local pick, best
      for pass = 1, 2 do
        for j, e in ipairs(slots) do
          local s = tonumber(e.species)
          if s and not original[e] and not newSet[s] and (area ~= "fishing" or rod(j) == rod(src)) then
            local okSlot = count(s) >= 2 or (pass == 2 and inOtherZone(s, key))
            if okSlot then
              local diff = math.abs(weightOf(area, j) - want) + (j == src and -0.5 or 0)
              if not best or diff < best then pick, best = j, diff end
            end
          end
        end
        if pick then break end
      end
      local e = pick and slots[pick]
      if not e then
        info("johto safari: %s %s: no free slot for %s", key, area, D.monName(sp))
        return false
      end
      original[e] = { species = e.species, minLevel = e.minLevel, maxLevel = e.maxLevel }
      e.species = sp
      if minL then e.minLevel, e.maxLevel = minL, maxL or minL end
      changed = changed + 1
      info("johto safari: %s %s slot %d -> %s Lv%s-%s", key, area, pick, D.monName(sp),
        tostring(e.minLevel), tostring(e.maxLevel))
      return true
    end

    if emerald() then
      place("26:12", "land", SMEARGLE, 7)
      place("26:13", "land", SUDOWOODO, 7)
      info("johto safari: %d slots added", changed)
      return
    end

    -- Ruby/Sapphire
    local em = loadEmerald()
    if not em then return end
    local emMap = D.tablesByMap(em)
    local apps = {} -- species -> area -> { index, min, max } (its best Emerald slot)
    for _, k in ipairs(EM_EXT) do
      local t = emMap[k]
      if t then
        for _, area in ipairs(D.AREAS) do
          for i, e in ipairs(D.slotsOf(t[area]) or {}) do
            local sp = tonumber(e.species)
            if sp and newSet[sp] then
              apps[sp] = apps[sp] or {}
              local cur = apps[sp][area]
              if not cur or weightOf(area, i) > weightOf(area, cur.i) then
                apps[sp][area] = { i = i, min = tonumber(e.minLevel), max = tonumber(e.maxLevel) }
              end
            end
          end
        end
      end
    end
    local counts = { 0, 0, 0, 0 }
    local function leastZone(filter)
      local best
      for z = 1, #RS_ZONES do
        if (not filter or filter(z)) and (not best or counts[z] < counts[best]) then best = z end
      end
      return best
    end
    for _, sp in ipairs(JOHTO16) do
      local a = apps[sp]
      if a then
        local z = leastZone(function(zz)
          local t = mine[RS_ZONES[zz]]
          if not t then return false end
          for area in pairs(a) do if D.slotsOf(t[area]) then return true end end
          return false
        end)
        local placed = false
        if z then
          for area, s in pairs(a) do
            if place(RS_ZONES[z], area, sp, s.i, s.min, s.max) then placed = true end
          end
        end
        if not placed then
          -- no matching area anywhere (rock smash...): the land of the emptiest area
          z = leastZone(function(zz) return mine[RS_ZONES[zz]] ~= nil end)
          local _, s = next(a)
          if z and s and place(RS_ZONES[z], "land", sp, math.min(s.i, 12), s.min, s.max) then placed = true end
        end
        if placed and z then counts[z] = counts[z] + 1 end
      else
        info("johto safari: %s isn't in Emerald's Safari Zone 5/6", D.monName(sp))
      end
    end
    for _, sp in ipairs({ SMEARGLE, SUDOWOODO }) do
      local z = leastZone(function(zz) return mine[RS_ZONES[zz]] ~= nil end)
      if z and place(RS_ZONES[z], "land", sp, 7) then counts[z] = counts[z] + 1 end
    end
    info("johto safari: %d slots added", changed)
  end

  function H.refreshTables()
    local ok, err = pcall(applySafari)
    if not ok then warn("safari", err) end
  end

  local function installSafari()
    local Enc = require("src.core.game3.encounters")
    local origLoad = Enc.loadFromMod
    Enc.loadFromMod = function(...)
      local r = { origLoad(...) }
      safState = nil
      for k in pairs(original) do original[k] = nil end
      H.refreshTables()
      return (table.unpack or unpack)(r)
    end
    local origTableFor = Enc.tableFor
    Enc.tableFor = function(...)
      if hoenn() then H.refreshTables() end
      return origTableFor(...)
    end
    Enc.table_for = Enc.tableFor
  end

  -- ================================================================ GET ALL JOHTO STARTERS

  local CHIKORITA, CYNDAQUIL, TOTODILE = 152, 155, 158
  local STARTERS = { CHIKORITA, CYNDAQUIL, TOTODILE }
  local BALL_LIDS = { [CHIKORITA] = 0x78, [CYNDAQUIL] = 0x79, [TOTODILE] = 0x7A }
  local LID_SP = { [0x78] = CHIKORITA, [0x79] = CYNDAQUIL, [0x7A] = TOTODILE }
  local HIDE = {
    [CHIKORITA] = "FLAG_HIDE_LITTLEROOT_TOWN_BIRCHS_LAB_POKEBALL_CHIKORITA",
    [CYNDAQUIL] = "FLAG_HIDE_LITTLEROOT_TOWN_BIRCHS_LAB_POKEBALL_CYNDAQUIL",
    [TOTODILE] = "FLAG_HIDE_LITTLEROOT_TOWN_BIRCHS_LAB_POKEBALL_TOTODILE",
  }

  local function got(sp) return sget("jst_got_" .. sp) == true end
  local function anyGot() for _, sp in ipairs(STARTERS) do if got(sp) then return true end end return false end
  local function allGot() for _, sp in ipairs(STARTERS) do if not got(sp) then return false end end return true end
  local function inLab(map) return map:find("PROFESSOR_BIRCHS_LAB", 1, true) ~= nil end

  -- remember every Johto starter handed over in the lab (Emerald's own script too)
  local function installGiveHook()
    local Party = require("src.core.game3.party")
    local orig = Party.giveMonToPlayer
    Party.giveMonToPlayer = function(sess, species, ...)
      local out = { orig(sess, species, ...) }
      pcall(function()
        local sp = tonumber(species)
        if hoenn() and sp and BALL_LIDS[sp] and inLab(D.mapId()) then
          local code = tonumber(out[1])
          if code == (Party.MON_GIVEN_TO_PARTY or 0) or code == (Party.MON_GIVEN_TO_PC or 1) then
            sset("jst_got_" .. sp, true)
          end
        end
      end)
      return (table.unpack or unpack)(out)
    end
  end

  local function takeBall(eo, sp, flagIdToSet)
    ask("Do you want the " .. D.monName(sp) .. "?", function(yes)
      if not yes then return end
      D.giveAndSay(sp, 5, function(given)
        if not given then return end
        sset("jst_got_" .. sp, true)
        if flagIdToSet then D.setFlagId(flagIdToSet, true) end
        hideObject(eo)
      end)
    end)
  end

  -- ------- Emerald: Birch's own lines say "take all three"

  local TEXTS = {
    LittlerootTown_ProfessorBirchsLab_Text_CompletedDexChoosePokemon =
      "Oh, {PLAYER}! You've completed the HOENN POKéDEX!\\pThat's an incredible achievement!\\p"
      .. "I'd like to reward you with these three rare POKéMON from the JOHTO region.\\p"
      .. "You've earned them all, so go ahead and take all three!",
    LittlerootTown_ProfessorBirchsLab_Text_CanHaveAnyOneOfRarePokemon =
      "Go ahead, {PLAYER}, they're all yours.\\pTake all three of them!",
  }
  local textKeys, textMine, textOrig = nil, {}, {}
  local function emTextKeys()
    if textKeys then return textKeys end
    textKeys = {}
    local Syms = req("src.import.gba.syms")
    local Opcodes = req("src.core.game3.scripting.opcodes")
    if not (Syms and Opcodes) then return textKeys end
    local ok, S = pcall(Syms.of, "emerald")
    if not ok then return textKeys end
    for name in pairs(TEXTS) do
      local okA, addr = pcall(S.addr, name)
      if okA and addr then textKeys[name] = Opcodes.key(addr) end
    end
    return textKeys
  end
  local function applyTexts()
    local Space = req("src.core.game3.scripting.space")
    local vm = Space and Space.vm
    if not (vm and type(vm.text) == "table") then return end
    local want = emerald() and on("johto_starters")
    local TextIR = req("src.core.game3.scripting.text_ir")
    for name, key in pairs(emTextKeys()) do
      local cur = vm.text[key]
      if want then
        if not textMine[name] and TextIR then
          local okT, ir = pcall(TextIR.fromAscii, TEXTS[name])
          if okT then textMine[name] = ir end
        end
        if textMine[name] and cur ~= textMine[name] then
          textOrig[name] = cur or false
          vm.text[key] = textMine[name]
        end
      elseif textMine[name] and cur == textMine[name] then
        vm.text[key] = textOrig[name] or nil
      end
    end
  end

  -- ------- Emerald: the balls on the table

  local function emBallSpecies(eo)
    local f = tonumber(eo and eo.def and (eo.def.flag or eo.def.flagId))
    if not f then return nil end
    for sp, name in pairs(HIDE) do
      if D.flagId(name) == f then return sp, f end
    end
  end

  local function talkEmeraldBall(eo)
    local sp, f = emBallSpecies(eo)
    if not sp then
      sp = LID_SP[eo.localId]
      if not sp then return false end
      f = D.flagId(HIDE[sp])
    end
    if got(sp) then return false end
    -- the first one goes through Emerald's own script (picture, nickname...)
    if not anyGot() then return false end
    takeBall(eo, sp, f)
    return true
  end

  local function tickEmeraldLab()
    local O = objects()
    if not (O and D.mapLoaded()) then return end
    if not (on("johto_starters") and anyGot()) or allGot() then return end
    for _, sp in ipairs(STARTERS) do
      if not got(sp) then
        local f = D.flagId(HIDE[sp])
        local shown, def = false, nil
        for _, lid in ipairs(O._order or {}) do
          local eo = O._byId[lid]
          if eo and eo.def and tonumber(eo.def.flag or eo.def.flagId) == f then
            def = eo.def
            if not eo.hidden then shown = true end
          end
        end
        if not def then
          for _, d in ipairs(O._defs or {}) do
            if tonumber(d.flag or d.flagId) == f then def = d end
          end
        end
        if not shown and def and not O._byId[BALL_LIDS[sp]] then
          D.spawnObject(BALL_LIDS[sp], tonumber(def.x), tonumber(def.y), gfx("ITEM_BALL"), 8)
        end
      end
    end
  end

  -- ------- Ruby/Sapphire: Emerald's lab table and three balls

  local function readEmRaw(rel)
    local GameVersion = req("src.core.GameVersion")
    local CacheFs = req("src.import.CacheFs")
    local CachePaths = req("src.core.game3.cache_paths")
    if not (GameVersion and CacheFs and CacheFs.readAt) then return nil end
    local root = (CachePaths and CachePaths.CACHE_ROOT) or "data/generated/gba"
    local prefix = "emerald/"
    if GameVersion.cachePrefix then
      local ok, p = pcall(GameVersion.cachePrefix, "emerald")
      if ok and p then prefix = p end
    end
    local ok, b = pcall(CacheFs.readAt, prefix .. root .. "/" .. rel)
    b = ok and type(b) == "string" and b or nil
    if b and b:byte(1) == 0x78 and love and love.data and love.data.decompress then
      local okZ, out = pcall(love.data.decompress, "string", "zlib", b)
      if okZ and type(out) == "string" then b = out end
    end
    return b
  end

  local tableDelta, tableTried = nil, false
  local function norm(s) return (tostring(s or ""):upper():gsub("[^%w]", "")) end
  local function loadTableDelta()
    if tableTried then return tableDelta end
    tableTried = true
    local files = D.readOtherLua("emerald", "native/layout_files.lua")
    local withKey, baseKey
    for _, v in pairs(files or {}) do
      local n = norm(v)
      if n:find("BIRCHSLAB", 1, true) then
        if n:find("TABLE", 1, true) then withKey = withKey or v else baseKey = baseKey or v end
      end
    end
    local NativePack = req("src.import.gba.native_pack")
    if not (withKey and baseKey and NativePack) then
      info("johto starters: Emerald's lab-with-table layout not found (Emerald installed?)")
      return nil
    end
    local a = readEmRaw("native/layouts/" .. baseKey .. ".mid")
    local b = readEmRaw("native/layouts/" .. withKey .. ".mid")
    local da = a and NativePack.decodeMidLayout(a)
    local db = b and NativePack.decodeMidLayout(b)
    if not (da and db and da.width == db.width and da.height == db.height) then
      info("johto starters: couldn't read Emerald's lab layouts")
      return nil
    end
    local cells = {}
    for i = 1, db.width * db.height do
      local ca, cb = da.cells[i], db.cells[i]
      if cb and (not ca or ca.mid ~= cb.mid or ca.coll ~= cb.coll or ca.elev ~= cb.elev) then
        cells[#cells + 1] = { x = (i - 1) % db.width, y = math.floor((i - 1) / db.width), mid = cb.mid, coll = cb.coll, elev = cb.elev }
      end
    end
    tableDelta = { width = db.width, height = db.height, cells = cells }
    info("johto starters: Emerald's lab table (%d tiles) from %s", #cells, tostring(withKey))
    return tableDelta
  end

  local applied = setmetatable({}, { __mode = "k" })
  local function applyTable()
    local delta = loadTableDelta()
    if not delta or #delta.cells == 0 then return false end
    local def = D.currentDef()
    local layout = def and def.midLayout
    if not (layout and layout.applyOverride and layout.cellAt) then return false end
    if applied[layout] then return true end
    if tonumber(layout.width) ~= delta.width or tonumber(layout.height) ~= delta.height then
      info("johto starters: the lab sizes differ (%sx%s / %dx%d), no table", tostring(layout.width), tostring(layout.height), delta.width, delta.height)
      applied[layout] = true
      return false
    end
    for _, c in ipairs(delta.cells) do layout:applyOverride(c.x, c.y, c.mid, c.coll, c.elev) end
    applied[layout] = true
    local Runtime = req("src.core.game3.runtime")
    local game = Runtime and Runtime._game
    local map = (session() or {}).map
    local Field = package.loaded["src.core.game3.field"]
    if Field and Field._overrideLayouts and map then Field._overrideLayouts[map] = layout end
    local Collision = package.loaded["src.core.game3.collision"]
    if Collision and Collision.bindMap and game and map then pcall(Collision.bindMap, game, map, def) end
    local FieldView = package.loaded["src.core.game3.field_view"]
    if FieldView then FieldView._nativeDirty = true end
    return true
  end

  -- three spots along the front edge of the table (fallback: in front of Birch)
  local ballSpots = nil
  local function spotsFor()
    if ballSpots then return ballSpots end
    local delta = loadTableDelta()
    local front = {}
    if delta then
      local maxY = -1
      for _, c in ipairs(delta.cells) do
        if (tonumber(c.coll) or 0) ~= 0 and c.y > maxY then maxY = c.y end
      end
      for _, c in ipairs(delta.cells) do
        if (tonumber(c.coll) or 0) ~= 0 and c.y == maxY then front[#front + 1] = c.x end
      end
      table.sort(front)
      if #front >= 3 then
        local mid = front[math.floor((#front + 1) / 2)]
        ballSpots = { { front[1], maxY }, { mid, maxY }, { front[#front], maxY } }
        return ballSpots
      end
    end
    local O = objects()
    local bx, by = 6, 4
    for _, lid in ipairs(O and O._order or {}) do
      local eo = O._byId[lid]
      if eo and gfxOf(eo) == gfx("PROF_BIRCH") then bx, by = eo.cellX, eo.cellY end
    end
    ballSpots = { { bx - 1, by + 2 }, { bx, by + 2 }, { bx + 1, by + 2 } }
    return ballSpots
  end

  local labFor = nil
  local function tickRsLab(map)
    local O = objects()
    if not (O and D.mapLoaded()) then return end
    if labFor ~= map then labFor, ballSpots = map, nil end
    if not (on("johto_starters") and sget("jst_offered")) then return end
    pcall(applyTable)
    if allGot() then return end
    local spots = spotsFor()
    for i, sp in ipairs(STARTERS) do
      if not got(sp) and not O._byId[BALL_LIDS[sp]] and spots[i] then
        D.spawnObject(BALL_LIDS[sp], spots[i][1], spots[i][2], gfx("ITEM_BALL"), 8)
      end
    end
  end

  local function talkRsBirch(eo)
    if not on("johto_starters") or allGot() then return false end
    local HA = ctx.hoennAll
    if HA and HA.birchWants then
      local ok, wants = pcall(HA.birchWants)
      if ok and wants then return false end
    end
    if not D.regionalComplete(200) then return false end
    face(eo)
    if not sget("jst_offered") then
      sset("jst_offered", true)
      say("Oh, " .. D.playerName() .. "! You've completed the HOENN POKéDEX!\fThat's an incredible achievement!\f"
        .. "A friend of mine in the JOHTO region sent me these three rare POKéMON.\f"
        .. "I've put them on the table over there. You've earned them all, so go ahead and take all three!",
        function() pcall(applyTable) end)
      return true
    end
    say("Go ahead, " .. D.playerName() .. ", they're all yours. Take all three of them!")
    return true
  end

  -- ================================================================ dispatch

  function H.talk(eo, map)
    if not inLab(map) or not on("johto_starters") then return false end
    local lid = eo.localId
    if emerald() then
      if LID_SP[lid] or emBallSpecies(eo) then return talkEmeraldBall(eo) end
      return false
    end
    if rs() then
      local sp = LID_SP[lid]
      if sp then
        if got(sp) then return false end
        takeBall(eo, sp, nil)
        return true
      end
      if gfxOf(eo) == gfx("PROF_BIRCH") then return talkRsBirch(eo) end
    end
    return false
  end

  function H.frame() end

  local textAt = 0
  function H.tick(map)
    H.refreshTables()
    local t = now()
    if emerald() and t >= textAt then
      textAt = t + 0.5
      local ok, err = pcall(applyTexts)
      if not ok then warn("birch texts", err) end
    end
    if inLab(map) then
      if emerald() then tickEmeraldLab() elseif rs() then tickRsLab(map) end
    end
  end

  H.installers = {
    { "johto safari", installSafari },
    { "johto give hook", installGiveHook },
  }

  return H
end
