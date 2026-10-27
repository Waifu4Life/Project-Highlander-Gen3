-- JOHTO POKéMON HELPER (all five Gen 3 games). Not a National Dex in one game:
-- it helps players who fill it by trading between the Gen 3 games.
-- Every option is On by default. Each game only shows its own rows.
--
--   FireRed / LeafGreen (components/johto/kanto.lua)
--     GET OTHER GAME EXCLUSIVES  each wild slot where the other game has a
--                           different Johto Pokémon (read from your installed
--                           other game) has a 50% chance to be the other game's.
--     GET ALL ROAMING BEASTS     Raikou, Entei and Suicune all roam Kanto.
--     ROAMING HUNTER             on a roaming beast's route, every encounter is
--                           it, and it never flees.
--     OBTAIN MYSTIC TICKET       the three beasts in your 1st, 2nd and 3rd slots:
--                           Mom has a letter for you (Navel Rock).
--     GUARDIAN OF THE FOREST     Lugia and Ho-Oh caught: Celebi plays follow the
--                           leader in Viridian Forest, then leaves the AURORA
--                           TICKET (Birth Island).
--   Ruby / Sapphire / Emerald (components/johto/hoenn.lua)
--     GET EMERALD GAME EXCLUSIVES (R/S)  Champion: Emerald's Safari Zone 5/6
--                           Johto Pokémon, plus Smeargle and Sudowoodo, spread
--                           over the four Safari Zone areas.
--     EXTRAS IN SAFARI ZONE 5&6 (E)  Smeargle and Sudowoodo in the two new areas.
--     GET ALL JOHTO STARTERS     complete Hoenn Dex: Birch lets you take all
--                           three Johto starters (R/S: Emerald's lab table).
--   Always on: Metal Coat, King's Rock, Dragon Scale and Up-Grade at $20,000
--   after the Champion (Lilycove Dept. Store 2F / Celadon Dept. Store 4F),
--   components/johto/shops.lua.
return function(ctx)
  local S = ctx.settings
  local J = { installed = false }
  local D = { ctx = ctx, S = S, J = J }

  local function on(key) return S.get(key) == true end
  local function warn(what, err)
    if ctx.mod.log then ctx.mod.log:warn("johto %s: %s", what, tostring(err)) end
  end
  local function info(fmt, ...)
    if ctx.mod.log then pcall(ctx.mod.log.info, ctx.mod.log, fmt, ...) end
  end
  local function req(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
  end
  local function now()
    return (love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
  end
  local function rand()
    return (love and love.math and love.math.random) and love.math.random() or math.random()
  end
  local function session()
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.getSession then
      local ok, s = pcall(Runtime.getSession)
      if ok and type(s) == "table" then return s end
    end
  end
  local function version() return S.version(session()) end
  local function kanto() local v = version() return v == "firered" or v == "leafgreen" end
  local function hoenn() return S.HOENN[version()] == true end
  local function rs() local v = version() return v == "ruby" or v == "sapphire" end
  local function emerald() return version() == "emerald" end

  local function sget(key)
    local ok, v = pcall(function() return ctx.mod.save:get(key) end)
    return ok and v or nil
  end
  local function sset(key, v)
    pcall(function() ctx.mod.save:set(key, v) end)
  end

  -- ------------------------------------------------------------- constants

  local function consts()
    local C = req("src.core.game3.constants")
    if not C then return nil end
    local ok, c = pcall(C.of, version())
    return ok and c or nil
  end
  local function constId(kind, name)
    local c = consts()
    local t = c and c[kind]
    return t and t.byName and t.byName[name] or nil
  end
  local function gfx(name, fallback) return constId("event_objects", "OBJ_EVENT_GFX_" .. name) or fallback end

  -- national number -> the game's species id (the same below #252)
  local spCache = {}
  local function SPN(nat)
    if spCache[nat] then return spCache[nat] end
    local Pokemon = req("src.core.game3.pokemon")
    local id
    if Pokemon and Pokemon.speciesFromNational then
      local ok, v = pcall(Pokemon.speciesFromNational, nat)
      id = ok and tonumber(v) or nil
    end
    id = id or (nat <= 251 and nat or nil)
    if id then spCache[nat] = id end
    return id
  end

  -- ------------------------------------------------------------- flags / vars

  local function store()
    local Space = req("src.core.game3.scripting.space")
    return Space and Space.store
  end
  local function flagId(name)
    local Flags = req("src.core.game3.scripting.flags")
    if not Flags then return nil end
    if Flags.active then
      local ok, t = pcall(Flags.active, session())
      if ok and t and t.IDS and t.IDS[name] then return t.IDS[name] end
    end
    local id = Flags.IDS and Flags.IDS[name]
    return id or constId("flags", name)
  end
  local function flagById(id)
    local Flags = req("src.core.game3.scripting.flags")
    local st = store()
    if not (Flags and id and st) then return false end
    local ok, v = pcall(Flags.getFlag, st, nil, id)
    return ok and v == true
  end
  local function flag(name) return flagById(flagId(name)) end
  local function setFlagId(id, value)
    local Flags = req("src.core.game3.scripting.flags")
    local st = store()
    if Flags and id and st then pcall(Flags.setFlag, st, nil, id, value ~= false) end
    if value == false then
      local sess = session()
      if sess and type(sess.flags) == "table" then sess.flags[id], sess.flags[tostring(id)] = nil, nil end
    end
  end
  local function setFlag(name, value)
    local id = flagId(name)
    if id then setFlagId(id, value) end
    return id ~= nil
  end
  local function var(id)
    local Flags = req("src.core.game3.scripting.flags")
    local st = store()
    if not (Flags and st and id) then return 0 end
    local ok, v = pcall(Flags.getVar, st, nil, id)
    return ok and tonumber(v) or 0
  end
  local function champion() return flag("FLAG_SYS_GAME_CLEAR") end

  -- ------------------------------------------------------------- game state

  local function mapId()
    local sess = session()
    local m = sess and sess.map
    if not m then
      local Map = req("src.core.game3.map")
      m = Map and Map.current
    end
    return tostring(m or ""):upper()
  end
  local function speciesOf(mon)
    if type(mon) ~= "table" then return nil end
    local Pokemon = req("src.core.game3.pokemon")
    if Pokemon and Pokemon.speciesOf then
      local ok, v = pcall(Pokemon.speciesOf, mon)
      if ok and tonumber(v) then return tonumber(v) end
    end
    return tonumber(mon.species or mon.speciesId)
  end
  local function isEgg(mon)
    if mon and (mon.isEgg or mon.egg) then return true end
    local Pokemon = req("src.core.game3.pokemon")
    if Pokemon and Pokemon.isEgg then
      local ok, v = pcall(Pokemon.isEgg, mon)
      return ok and v == true
    end
    return false
  end
  local function partySpecies(i)
    local mon = ((session() or {}).party or {})[i]
    if not mon or isEgg(mon) then return nil end
    return speciesOf(mon)
  end
  local function monName(species)
    local Pokemon = req("src.core.game3.pokemon")
    local ok, n = pcall(Pokemon.name, species)
    return (ok and n) and tostring(n):upper() or "POKéMON"
  end
  local function playerName()
    local sess = session() or {}
    local n = sess.name or sess.playerName
    return (type(n) == "string" and n ~= "") and n or "PLAYER"
  end
  local function caught(sp)
    local sess = session()
    local Dex = req("src.core.game3.dex")
    if not (sess and sess.dex and Dex and sp) then return false end
    local ok, c = pcall(Dex.isCaught, sess.dex, sp)
    return ok and c == true
  end
  local function registerCaught(sp)
    local sess = session()
    local Dex = req("src.core.game3.dex")
    if sess and sess.dex and Dex and Dex.handleSetPokedexFlag then
      pcall(Dex.handleSetPokedexFlag, sess.dex, sp, false)
      pcall(Dex.handleSetPokedexFlag, sess.dex, sp, true)
    end
  end

  -- every regional Pokémon up to maxNum caught (checked at most every 2 s)
  local regionalAt, regionalOk = 0, false
  local function regionalComplete(maxNum)
    local t = now()
    if t < regionalAt then return regionalOk end
    regionalAt = t + 2
    local sess = session()
    local Dex = req("src.core.game3.dex")
    regionalOk = false
    if not (sess and sess.dex and Dex and Dex.regionalNumber) then return false end
    local found = 0
    for sp = 1, 440 do
      local ok, n = pcall(Dex.regionalNumber, sp, version())
      n = ok and tonumber(n) or nil
      if n and n >= 1 and n <= maxNum then
        found = found + 1
        if not caught(sp) then return false end
      end
    end
    regionalOk = found >= maxNum
    return regionalOk
  end

  -- ------------------------------------------------------------- items

  local function itemId(name) return constId("items", name) end
  local function bagAdd(id)
    local sess, Bag = session(), req("src.core.game3.bag")
    if not (sess and sess.bag and Bag and id) then return false end
    local ok, v = pcall(Bag.add, sess.bag, id, 1)
    return ok and v ~= false
  end
  local function hasItemId(id)
    local sess, Bag = session(), req("src.core.game3.bag")
    if not (sess and sess.bag and Bag and id) then return false end
    local ok, v = pcall(Bag.has, sess.bag, id, 1)
    return ok and v == true
  end

  -- ------------------------------------------------------------- text

  local MAX_W = 208
  local function wrap(text)
    local FrlgFont = req("src.ui.game3.frlg_font")
    local function width(s)
      if FrlgFont and FrlgFont.measure then
        local ok, w = pcall(FrlgFont.measure, s)
        if ok and tonumber(w) then return tonumber(w) end
      end
      return #s * 6
    end
    local pages = {}
    for para in (text .. "\f"):gmatch("(.-)\f") do
      local lines, line = {}, ""
      for word in para:gmatch("%S+") do
        local try = line == "" and word or (line .. " " .. word)
        if line ~= "" and width(try) > MAX_W then
          lines[#lines + 1] = line
          line = word
        else
          line = try
        end
      end
      if line ~= "" then lines[#lines + 1] = line end
      for i = 1, #lines, 2 do
        pages[#pages + 1] = lines[i] .. (lines[i + 1] and ("\n" .. lines[i + 1]) or "")
      end
    end
    return table.concat(pages, "\f")
  end
  local function say(text, cb)
    local Message = req("src.ui.game3.message")
    if not Message then if cb then cb() end return end
    Message.show(wrap(text), { done = cb })
  end
  local function ask(text, cb)
    local Message = req("src.ui.game3.message")
    local Choice = req("src.ui.game3.choice")
    if not (Message and Choice) then cb(false) return end
    Message.show(wrap(text), {
      hold = true,
      done = function()
        Choice.yesNo(function(yes)
          Message.close()
          cb(yes == true or yes == 1)
        end)
      end,
    })
  end
  local function fanfare(id)
    pcall(function() require("src.core.game3.audio").playFanfare(id or "MUS_OBTAIN_ITEM") end)
  end
  local function cry(sp)
    pcall(function() require("src.core.game3.audio").playCry(sp) end)
  end
  local function se(name)
    pcall(function() require("src.core.game3.audio").playSe(require("src.core.game3.se_ids")[name]) end)
  end

  -- ------------------------------------------------------------- giving Pokémon

  local function giveMon(species, level)
    local sess = session()
    local Party = req("src.core.game3.party")
    if not (sess and Party and Party.giveMonToPlayer and species) then return "fail" end
    local ok, code, mon = pcall(Party.giveMonToPlayer, sess, species, level or 5)
    code = ok and tonumber(code) or nil
    if code == (Party.MON_GIVEN_TO_PARTY or 0) then registerCaught(species) return "party", mon end
    if code == (Party.MON_GIVEN_TO_PC or 1) then registerCaught(species) return "pc", mon end
    return "fail"
  end
  local function nickname(mon, species, after)
    local done = function() if after then after() end end
    if type(mon) ~= "table" then done() return end
    ask("Do you want to give a nickname to the " .. monName(species) .. " you received?", function(yes)
      if not yes then done() return end
      local Naming = req("src.ui.game3.naming")
      local Pokemon = req("src.core.game3.pokemon")
      if not (Naming and Naming.open) then done() return end
      local okT, title = pcall(Naming.monTitle, Pokemon.name(species))
      local ok, err = pcall(Naming.open, {
        template = "CAUGHT_MON", maxLen = 10, species = species,
        seed = monName(species), title = okT and title or nil, session = session(),
        onDone = function(nick)
          if type(nick) == "string" and nick ~= "" and nick:upper() ~= monName(species) then
            mon.nickname = nick
          end
          done()
        end,
      })
      if not ok then warn("naming", err) done() end
    end)
  end
  -- after(true) once given, after(false) when there was no room
  local function giveAndSay(species, level, after)
    local where, mon = giveMon(species, level)
    if where == "fail" then
      say("There's no room for it...", function() if after then after(false) end end)
      return false
    end
    if not mon and where == "party" then
      local sess = session()
      mon = sess and sess.party and sess.party[#sess.party] or nil
    end
    fanfare("MUS_OBTAIN_ITEM")
    say(playerName() .. " received " .. monName(species) .. "!", function()
      nickname(mon, species, function()
        if where == "pc" then
          say(monName(species) .. " was sent to the PC.", function() if after then after(true) end end)
        elseif after then
          after(true)
        end
      end)
    end)
    return true
  end

  -- ------------------------------------------------------------- objects

  local function objects() return req("src.core.game3.objects") end
  local function gfxOf(eo)
    return tonumber(eo and (eo.graphicsId or (eo.def and (eo.def.graphicsId or eo.def.gfx))))
  end
  local function hideObject(eo)
    local O = objects()
    if O and eo and eo.localId then pcall(O.removeObject, eo.localId) end
  end
  local function face(eo)
    local O = objects()
    if O and eo and eo.localId then pcall(O.facePlayer, eo.localId) end
  end
  local function mapLoaded()
    local O = objects()
    return O and tostring(O._mapId or "") ~= "" and tostring(O._mapId or ""):upper() == mapId()
  end
  local function currentDef()
    local Map = req("src.core.game3.map")
    return Map and Map.currentDef and Map.currentDef() or nil
  end

  -- a new object of ours, or the one already made (shown again if hidden)
  local function spawnObject(lid, x, y, graphicsId, movementType)
    local O = objects()
    if not O or not graphicsId then return nil end
    local eo = O._byId[lid]
    if eo then return eo end
    local defs = {}
    for i, d in ipairs(O._defs or {}) do defs[i] = d end
    defs[#defs + 1] = { localId = lid, index = lid, x = x, y = y, graphicsId = graphicsId,
      movementType = movementType or 8, elevation = 3, flag = 0, trainerType = 0 }
    O._defs = defs
    local ok, err = pcall(O.addObject, lid)
    if not ok then warn("spawn " .. tostring(lid), err) return nil end
    return O._byId[lid]
  end
  -- puts one of our objects on a cell and shows it
  local function placeObject(eo, x, y)
    if not eo then return end
    eo.cellX, eo.cellY = x, y
    eo.px, eo.py = x * 16, y * 16
    eo.homeX, eo.homeY = x, y
    if eo.def then eo.def.x, eo.def.y, eo.def.hidden = x, y, false end
    eo.hidden, eo.visible = false, true
  end

  local function freeCell(x, y)
    local C = req("src.core.game3.collision")
    local O = objects()
    local P = req("src.core.game3.player")
    if not (C and O) then return false end
    if P and P.cellX == x and P.cellY == y then return false end
    local okW, walk = pcall(C.isWalkable, x, y)
    if not (okW and walk) then return false end
    if C.isWater and C.isWater(x, y) then return false end
    if C.warpAt and C.warpAt(x, y) then return false end
    local other = O.at(x, y)
    if other and not other.hidden then return false end
    return true
  end
  local function nearestFree(cx, cy, minR, maxR)
    for r = minR, maxR do
      for dy = -r, r do
        for dx = -r, r do
          if math.abs(dx) + math.abs(dy) == r and freeCell(cx + dx, cy + dy) then return cx + dx, cy + dy end
        end
      end
    end
  end

  -- ------------------------------------------------------------- battles

  local function isCatch(result)
    if result == 7 then return true end -- B_OUTCOME_CAUGHT
    local r = tostring(result or ""):lower()
    return r == "caught" or r == "catch"
  end
  local function wildBattle(species, level, done)
    local Runtime = req("src.core.game3.runtime")
    local BB = req("src.core.game3.battle_bridge")
    if not (Runtime and BB) then return end
    local ok, err = pcall(BB.startWild, Runtime._mod, Runtime._game, { species = species, level = level }, {
      legendary = true, ph3Own = true,
      done = function(result) if done then done(isCatch(result), result) end end,
    })
    if not ok then warn("battle", err) end
  end

  -- ------------------------------------------------------------- other games' caches

  local function readOtherLua(v, rel)
    local GameVersion = req("src.core.GameVersion")
    local CacheFs = req("src.import.CacheFs")
    local CachePaths = req("src.core.game3.cache_paths")
    if not (GameVersion and CacheFs and CacheFs.readAt) then return nil end
    local root = (CachePaths and CachePaths.CACHE_ROOT) or "data/generated/gba"
    local ok, data = pcall(function()
      local prefix
      if GameVersion.cachePrefix then
        local okP, p = pcall(GameVersion.cachePrefix, v)
        if okP then prefix = p end
      end
      if not prefix then
        local inf = GameVersion.info(v)
        prefix = (inf and inf.cachePrefix) or ""
      end
      local src = CacheFs.readAt(prefix .. root .. "/" .. rel)
      if type(src) == "string" and src:byte(1) == 0x78 and love and love.data and love.data.decompress then
        local okZ, out = pcall(love.data.decompress, "string", "zlib", src)
        if okZ then src = out end
      end
      if not src then return nil end
      return assert(load(src, "@" .. v .. " " .. rel, "t", {}))()
    end)
    return ok and type(data) == "table" and data or nil
  end

  -- ------------------------------------------------------------- shared encounter helpers

  local AREAS = { "land", "grass", "water", "rocks", "rock_smash", "fishing" }
  local function slotsOf(area)
    if type(area) ~= "table" then return nil end
    local s = area.slots or area.mons
    if type(s) == "table" then return s end
    if #area > 0 then return area end
  end
  local function tablesByMap(tables)
    local out = {}
    for _, t in pairs(tables or {}) do
      if type(t) == "table" and t.mapGroup and t.mapNum then
        local k = tostring(t.mapGroup) .. ":" .. tostring(t.mapNum)
        out[k] = out[k] or t
      end
    end
    return out
  end

  -- ------------------------------------------------------------- hand over to the parts

  for k, v in pairs({
    on = on, warn = warn, info = info, req = req, now = now, rand = rand, session = session,
    version = version, kanto = kanto, hoenn = hoenn, rs = rs, emerald = emerald,
    sget = sget, sset = sset, constId = constId, gfx = gfx, SPN = SPN,
    flagId = flagId, flagById = flagById, flag = flag, setFlag = setFlag, setFlagId = setFlagId, var = var,
    champion = champion, mapId = mapId, speciesOf = speciesOf, isEgg = isEgg, partySpecies = partySpecies,
    monName = monName, playerName = playerName, caught = caught, registerCaught = registerCaught,
    regionalComplete = regionalComplete, itemId = itemId, bagAdd = bagAdd, hasItemId = hasItemId,
    wrap = wrap, say = say, ask = ask, fanfare = fanfare, cry = cry, se = se,
    giveMon = giveMon, nickname = nickname, giveAndSay = giveAndSay,
    objects = objects, gfxOf = gfxOf, hideObject = hideObject, face = face, mapLoaded = mapLoaded,
    currentDef = currentDef, spawnObject = spawnObject, placeObject = placeObject,
    freeCell = freeCell, nearestFree = nearestFree, isCatch = isCatch, wildBattle = wildBattle,
    readOtherLua = readOtherLua, AREAS = AREAS, slotsOf = slotsOf, tablesByMap = tablesByMap,
  }) do D[k] = v end

  local function loadPart(rel)
    local source, readErr = ctx.mod:read(rel)
    assert(source, tostring(readErr or (rel .. " is missing")))
    local chunk, compileErr = load(source, "@" .. tostring(ctx.mod.path) .. "/" .. rel)
    assert(chunk, compileErr)
    return chunk()(D)
  end
  local K = loadPart("components/johto/kanto.lua")
  local HN = loadPart("components/johto/hoenn.lua")
  local SH = loadPart("components/johto/shops.lua")
  J.kanto, J.hoenn, J.shops = K, HN, SH

  -- Pokédex LOCATION tab: { a = {species, minLevel, maxLevel}, b = {...} } for a
  -- slot that is each one half the time (FireRed/LeafGreen exclusives)
  function J.dualOf(slot) return K.dualOf(slot) end
  function J.refreshTables()
    pcall(K.refreshTables)
    pcall(HN.refreshTables)
  end

  -- ------------------------------------------------------------- talk / ticks

  local DELTA = { up = { 0, -1 }, down = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }
  local function fieldReady()
    local Field = req("src.core.game3.field")
    if not (Field and Field.running) or Field.locked then return false end
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.uiBusy and Runtime.uiBusy() then return false end
    local Space = req("src.core.game3.scripting.space")
    if Space and Space.vm and Space.vm.isRunning and Space.vm:isRunning() then return false end
    local P = req("src.core.game3.player")
    if not P or P.moving then return false end
    return true
  end
  D.fieldReady = fieldReady

  local function tryTalk()
    local P = req("src.core.game3.player")
    local O = objects()
    if not (P and O) then return false end
    local d = DELTA[P.facing or "down"] or DELTA.down
    local eo = O.at(P.cellX + d[1], P.cellY + d[2])
    if not eo or eo.hidden then return false end
    if kanto() then return K.talk(eo, mapId()) end
    if hoenn() then return HN.talk(eo, mapId()) end
    return false
  end

  local function installField()
    local Field = require("src.core.game3.field")
    local origInteract = Field.interact
    Field.interact = function(game, ...)
      if fieldReady() then
        local ok, done = pcall(tryTalk)
        if not ok then warn("talk", done) end
        if ok and done then return true end
      end
      return origInteract(game, ...)
    end
    local tickAt = 0
    local origUpdate = Field.update
    Field.update = function(...)
      local r = { origUpdate(...) }
      local okF, errF = pcall(function()
        if kanto() then K.frame() elseif hoenn() then HN.frame() end
      end)
      if not okF then warn("frame", errF) end
      local t = now()
      if t >= tickAt and Field.running and fieldReady() then
        tickAt = t + 0.1
        local ok, err = pcall(function()
          if kanto() then K.tick(mapId()) elseif hoenn() then HN.tick(mapId()) end
        end)
        if not ok then warn("tick", err) end
      end
      return (table.unpack or unpack)(r)
    end
  end

  local done = {}
  function J.install()
    if J.installed then return end
    local all = true
    local steps = { { "field", installField } }
    for _, s in ipairs(K.installers or {}) do steps[#steps + 1] = s end
    for _, s in ipairs(HN.installers or {}) do steps[#steps + 1] = s end
    for _, s in ipairs(SH.installers or {}) do steps[#steps + 1] = s end
    for _, s in ipairs(steps) do
      if not done[s[1]] then
        local ok, err = pcall(s[2])
        if ok then done[s[1]] = true else all = false warn(s[1], err) end
      end
    end
    J.installed = all
  end

  return J
end
