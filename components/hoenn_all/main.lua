-- FILL HOENN REGIONAL DEX (Ruby / Sapphire / Emerald only). The Hoenn
-- counterpart of Fill Kanto Regional Dex. Every option is On by default.
--
--   GET A SPECIAL WISH      every Hoenn Pokémon up to #200 caught: Mom saw a
--                           little floating Pokémon go up to your room. JIRACHI
--                           (Lv5) leads you outside. In Emerald, an item ball
--                           with the AURORA TICKET is left where it was.
--                           In Ruby/Sapphire (with Emerald installed) the ticket
--                           and Birth Island come from Emerald: see birth_island.lua.
--   GET ALL STARTERS        8 badges: Birch offers the last starter on the lab
--                           table. Champion, with LATIAS or LATIOS first in the
--                           party: Birch gives a baby of your rival's starter.
--   GET EON TICKET          Champion and LATIAS or LATIOS caught: Dad (Petalburg
--                           Gym) hands over the EON TICKET (Southern Island).
--   GET OTHER BOX LEGENDARY Ruby/Sapphire. Champion, RAYQUAZA caught and both
--                           RAYQUAZA and your game's weather legend in the 1st
--                           and 2nd slots: the other one waits deep in the Cave
--                           of Origin (Lv45).
--   GET OTHER DEEP SEA ITEM 8 badges, Storage Key used and the Scanner already
--                           traded: Captain Stern trades the other Deep Sea item
--                           for the Storage Key.
--   GET OTHER FOSSIL        Ruby/Sapphire. 8 badges, your fully evolved fossil
--                           Pokémon first in the party: the Devon scientist gives
--                           you the other one (Lv20).
--   GET OTHER GAME EXCLUSIVES  Ruby/Sapphire: each version exclusive has a 50%
--                           chance to be the other version's counterpart.
--                           Emerald: Seviper/Solrock have a 50% chance to be
--                           Zangoose/Lunatone, and Surskit, Meditite, Medicham and
--                           Roselia get Ruby/Sapphire's own slots (read from your
--                           installed Ruby or Sapphire).
--   INFINITE TRIES FOR RARE PKMN  the Regis, the weather trio, Latias/Latios
--                           (Southern Island and roaming), Jirachi, Deoxys, Mew,
--                           Lugia, Ho-Oh and Sudowoodo stay when they aren't
--                           caught.
--   ROAMING HUNTER          on the roaming Latias/Latios's route, every encounter
--                           is it, and it never flees.
--   TRADE WITH LINK C.      the GameCube in your room trade-evolves KADABRA,
--                           HAUNTER, GRAVELER, MACHOKE, POLIWHIRL / SLOWPOKE (King's
--                           Rock), ONIX / SCYTHER (Metal Coat), SEADRA (Dragon
--                           Scale), PORYGON (Up-Grade) and CLAMPERL (Deep Sea
--                           Tooth / Deep Sea Scale), once each.
--
-- Progress is kept in the save file (mod.save).
return function(ctx)
  local S = ctx.settings
  local H = { installed = false }

  local function on(key) return S.get(key) == true end
  local function warn(what, err)
    if ctx.mod.log then ctx.mod.log:warn("hoenn all %s: %s", what, tostring(err)) end
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
  local function hoenn() return S.HOENN[version()] == true end
  local function rs() local v = version() return v == "ruby" or v == "sapphire" end
  local function emerald() return version() == "emerald" end
  H.hoenn, H.rs = hoenn, rs

  -- per save
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

  -- National Dex numbers -> the game's own species ids
  local NAT = {
    KADABRA = 64, MACHOKE = 67, GRAVELER = 75, SEADRA = 117, MEW = 151,
    POLIWHIRL = 61, SLOWPOKE = 79, HAUNTER = 93, ONIX = 95, SCYTHER = 123, PORYGON = 137,
    SUDOWOODO = 185, LUGIA = 249, HO_OH = 250,
    TREECKO = 252, SCEPTILE = 254, TORCHIC = 255, BLAZIKEN = 257, MUDKIP = 258, SWAMPERT = 260,
    LOTAD = 270, LOMBRE = 271, SEEDOT = 273, NUZLEAF = 274, SURSKIT = 283,
    SABLEYE = 302, MAWILE = 303, MEDITITE = 307, MEDICHAM = 308, ROSELIA = 315,
    ZANGOOSE = 335, SEVIPER = 336, LUNATONE = 337, SOLROCK = 338,
    LILEEP = 345, CRADILY = 346, ANORITH = 347, ARMALDO = 348, CLAMPERL = 366, HUNTAIL = 367, GOREBYSS = 368,
    REGIROCK = 377, REGICE = 378, REGISTEEL = 379, LATIAS = 380, LATIOS = 381,
    KYOGRE = 382, GROUDON = 383, RAYQUAZA = 384, JIRACHI = 385, DEOXYS = 386,
  }
  local spCache = {}
  local function SP(name)
    if spCache[name] then return spCache[name] end
    local Pokemon = req("src.core.game3.pokemon")
    local nat = NAT[name]
    local id
    if Pokemon and Pokemon.speciesFromNational and nat then
      local ok, v = pcall(Pokemon.speciesFromNational, nat)
      id = ok and tonumber(v) or nil
    end
    if id then spCache[name] = id end
    return id
  end

  -- ------------------------------------------------------------- flags / vars

  local function store()
    local Space = req("src.core.game3.scripting.space")
    return Space and Space.store
  end

  local function flagTable()
    local Flags = req("src.core.game3.scripting.flags")
    if not (Flags and Flags.active) then return nil end
    local ok, t = pcall(Flags.active, session())
    return ok and t or nil
  end
  local function flagId(name)
    local t = flagTable()
    return t and t.IDS and t.IDS[name] or nil
  end
  local function flagName(id)
    local t = flagTable()
    return t and t.NAMES and t.NAMES[tonumber(id)] or nil
  end

  local function flag(name)
    local Flags = req("src.core.game3.scripting.flags")
    local id, st = flagId(name), store()
    if not (Flags and id and st) then return false end
    local ok, v = pcall(Flags.getFlag, st, nil, id)
    return ok and v == true
  end
  local function setFlagId(id, value)
    local Flags = req("src.core.game3.scripting.flags")
    local st = store()
    if Flags and id and st then pcall(Flags.setFlag, st, nil, id, value) end
    if not value then
      local sess = session()
      if sess and type(sess.flags) == "table" then sess.flags[id], sess.flags[tostring(id)] = nil, nil end
    end
  end
  local function setFlag(name, value)
    local id = flagId(name)
    if id then setFlagId(id, value ~= false) end
    return id ~= nil
  end
  local function var(id)
    local Flags = req("src.core.game3.scripting.flags")
    local st = store()
    if not (Flags and st) then return 0 end
    local ok, v = pcall(Flags.getVar, st, nil, id)
    return ok and tonumber(v) or 0
  end

  local function allBadges()
    for i = 1, 8 do
      if not flag(string.format("FLAG_BADGE%02d_GET", i)) then return false end
    end
    return true
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
    local Pokemon = req("src.core.game3.pokemon")
    if mon and (mon.isEgg or mon.egg) then return true end
    if Pokemon and Pokemon.isEgg then
      local ok, v = pcall(Pokemon.isEgg, mon)
      return ok and v == true
    end
    return false
  end
  local function partySpecies(i)
    local party = (session() or {}).party or {}
    local mon = party[i]
    if not mon or isEgg(mon) then return nil end
    return speciesOf(mon)
  end
  local function heldItem(mon)
    return tonumber(mon and (mon.heldItem or mon.item)) or 0
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
  local function female()
    local g = (session() or {}).gender
    return g == 1 or g == "female" or g == "F" or g == "girl"
  end
  -- the rival is the other one of Brendan / May
  local function rival() return female() and "BRENDAN" or "MAY" end
  local function rivalHe() return female() and "he" or "she" end
  local function rivalHis() return female() and "his" or "her" end
  -- the player's own house (Brendan's when you're a boy, May's when a girl)
  local function houseKey() return female() and "MAYS_HOUSE" or "BRENDANS_HOUSE" end

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

  -- ------------------------------------------------------------- items

  local function itemId(name) return constId("items", name) end
  local function bagDo(fn, name)
    local sess, Bag, id = session(), req("src.core.game3.bag"), itemId(name)
    if not (sess and sess.bag and Bag and id and Bag[fn]) then return false end
    local ok, v = pcall(Bag[fn], sess.bag, id, 1)
    return ok and v ~= false
  end
  local function hasItem(name)
    local sess, Bag, id = session(), req("src.core.game3.bag"), itemId(name)
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

  -- ------------------------------------------------------------- giving Pokémon

  -- returns "party" | "pc" | "fail", and the Pokémon given
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

  -- gives the Pokémon with the fanfare, the "received" line and the nickname
  -- prompt; after(true) once it's given, after(false) when there was no room
  local function giveAndSay(species, level, after)
    local where, mon = giveMon(species, level)
    if where == "fail" then
      say("There's no room for it...", function() if after then after(false) end end)
      return false
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
  local function gfx(name) return constId("event_objects", "OBJ_EVENT_GFX_" .. name) end
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
    return O and tostring(O._mapId or ""):upper() == mapId()
  end

  local function spawnObject(lid, x, y, graphicsId, movementType)
    local O = objects()
    if not O or O._byId[lid] or not graphicsId then return nil end
    local defs = {}
    for i, d in ipairs(O._defs or {}) do defs[i] = d end
    defs[#defs + 1] = { localId = lid, index = lid, x = x, y = y, graphicsId = graphicsId,
      movementType = movementType or 8, elevation = 3, flag = 0, trainerType = 0 }
    O._defs = defs
    local ok, err = pcall(O.addObject, lid)
    if not ok then warn("spawn " .. tostring(lid), err) return nil end
    return O._byId[lid]
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
    if O.at(x, y) then return false end
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

  local function currentDef()
    local Map = req("src.core.game3.map")
    return Map and Map.currentDef and Map.currentDef() or nil
  end

  -- ------------------------------------------------------------- scripts
  -- NPCs that have no sprite of their own are recognised by what their
  -- script (read from the ROM) checks.

  local function scripts()
    local Space = req("src.core.game3.scripting.space")
    return Space and Space.vm and Space.vm.scripts
  end

  local FLAG_OPS = { checkflag = true, setflag = true, clearflag = true }
  local function scriptUsesFlag(key, want, depth, seen)
    local all = scripts()
    local list = all and key and all[key]
    if type(list) ~= "table" or seen[key] or not want then return false end
    seen[key] = true
    for _, row in ipairs(list) do
      if type(row) == "table" then
        if FLAG_OPS[row.op] and tonumber(row.flag or row[1]) == want then return true end
        if depth > 0 then
          for _, v in pairs(row) do
            if type(v) == "string" and all[v] and scriptUsesFlag(v, want, depth - 1, seen) then return true end
          end
        end
      end
    end
    return false
  end
  local function npcUsesFlag(eo, name)
    local key = eo and eo.def and eo.def.scriptKey
    return key and scriptUsesFlag(key, flagId(name), 3, {}) or false
  end

  -- every text a script (and the scripts it jumps to) shows, upper-case
  local function scriptText(key, depth, seen, out)
    local all = scripts()
    local list = all and key and all[key]
    if type(list) ~= "table" or seen[key] then return out end
    seen[key] = true
    local Space = req("src.core.game3.scripting.space")
    local vm = Space and Space.vm
    local Opcodes = req("src.core.game3.scripting.opcodes")
    local TextIR = req("src.core.game3.scripting.text_ir")
    local function add(ptr)
      if ptr == nil or not (vm and vm.getText and TextIR) then return end
      local ok, ir = pcall(function()
        if type(ptr) == "string" then return vm:getText(ptr) end
        return (Opcodes and Opcodes.key and vm:getText(Opcodes.key(ptr))) or vm:getText(ptr)
      end)
      if ok and ir then
        local okT, s = pcall(TextIR.toTextBox, ir, {})
        if okT and type(s) == "string" then out[#out + 1] = s:upper() end
      end
    end
    for _, row in ipairs(list) do
      if type(row) == "table" then
        if row.op == "message" then add(row.ptr or row[1])
        elseif row.op == "loadword" then add(row[2]) end
        if depth > 0 then
          for _, v in pairs(row) do
            if type(v) == "string" and all[v] then scriptText(v, depth - 1, seen, out) end
          end
        end
      end
    end
    return out
  end
  local function scriptSays(key, ...)
    local text = table.concat(scriptText(key, 2, {}, {}), " "):gsub("%s+", "")
    for _, word in ipairs({ ... }) do
      if text:find(word, 1, true) then return true end
    end
    return false
  end

  -- the background event (sign, machine...) on a tile of the current map
  local function bgEventAt(x, y)
    local def = currentDef()
    local events = def and def.bgEvents
    if not events then
      local Space = req("src.core.game3.scripting.space")
      local sess = session()
      local ev = Space and Space.bundle and Space.bundle.events and sess and Space.bundle.events[sess.map]
      events = ev and ev.bgEvents
    end
    for _, ev in ipairs(events or {}) do
      if tonumber(ev.x) == x and tonumber(ev.y) == y and ev.scriptKey then return ev end
    end
  end

  -- ------------------------------------------------------------- frame tasks

  local LOCK = "ph3_hoenn_all"
  local function runSteps(steps, onDone)
    local Task = req("src.core.game3.task")
    local Field = req("src.core.game3.field")
    if Field and Field.lock then Field.lock(LOCK) end
    local i, started, frames = 1, false, 0
    local function finish()
      if Field and Field.unlock then Field.unlock(LOCK) end
      if onDone then onDone() end
    end
    if not (Task and Task.spawn) then finish() return end
    Task.spawn(function()
      local st = steps[i]
      if not st then finish() return true end
      if not started then
        started, frames = true, 0
        local ok, err = pcall(st.start)
        if not ok then warn("step", err) i, started = i + 1, false end
        return false
      end
      frames = frames + 1
      local ok, done = pcall(st.wait, frames)
      if not ok then warn("step", done) done = true end
      if done then i, started = i + 1, false end
      return false
    end)
  end

  local function fadeStep(toBlack)
    return {
      start = function()
        local Fade = req("src.ui.game3.fade")
        if Fade and Fade.begin and Fade.MODE then
          Fade.begin(toBlack and Fade.MODE.TO_BLACK or Fade.MODE.FROM_BLACK, 1, function() end)
        end
      end,
      wait = function(frames) return frames >= 18 end,
    }
  end

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

  -- ================================================================ GET ALL STARTERS

  -- VAR_STARTER_MON: 0 Treecko, 1 Torchic, 2 Mudkip. The rival takes the one
  -- strong against yours; the last one stays in Birch's bag.
  local STARTERS = {
    [0] = { mine = "TREECKO", rival = "TORCHIC", left = "MUDKIP" },
    [1] = { mine = "TORCHIC", rival = "MUDKIP", left = "TREECKO" },
    [2] = { mine = "MUDKIP", rival = "TREECKO", left = "TORCHIC" },
  }
  local FINAL = { TREECKO = "SCEPTILE", TORCHIC = "BLAZIKEN", MUDKIP = "SWAMPERT" }
  local function starters()
    local id = constId("vars", "VAR_STARTER_MON") or 0x4023
    return STARTERS[var(id)] or STARTERS[0]
  end

  -- the ball on the lab table (spot marked on the user's screenshot)
  local BALL_LID, BALL_X, BALL_Y = 0x71, 6, 1

  local function ballWanted()
    return on("hoenn_starters") and sget("hgk_birch_offered") and not sget("hgk_ball_taken")
  end

  -- JOHTO POKéMON HELPER's Johto starters wait until this has nothing to say
  function H.birchWants()
    if not on("hoenn_starters") then return false end
    if champion() and sget("hgk_ball_taken") and not sget("hgk_baby") then
      local lead = partySpecies(1)
      if lead and (lead == SP("LATIAS") or lead == SP("LATIOS")) then return true end
    end
    if allBadges() and not sget("hgk_birch_offered") then return true end
    if sget("hgk_birch_offered") and not sget("hgk_ball_taken") then return true end
    return false
  end

  local function talkBirch(eo)
    if not on("hoenn_starters") then return false end
    local st = starters()
    -- 3rd starter: Champion, Latias or Latios first in the party
    if champion() and sget("hgk_ball_taken") and not sget("hgk_baby") then
      local lead = partySpecies(1)
      if lead and (lead == SP("LATIAS") or lead == SP("LATIOS")) then
        face(eo)
        say("My goodness, this is the legendary Eon POKéMON " .. monName(lead) .. "!\f"
          .. "I never thought I'd live to see it, but there it is. Thank you so much for showing it to me.\f"
          .. "As a little token of my appreciation, I'd like to give you this POKéMON that " .. rival()
          .. " brought me after " .. rivalHe() .. " bred " .. rivalHis() .. " " .. FINAL[st.rival] .. ".", function()
            giveAndSay(SP(st.rival), 5, function(given) if given then sset("hgk_baby", true) end end)
          end)
        return true
      end
    end
    -- 2nd starter: all 8 badges
    if allBadges() and not sget("hgk_birch_offered") then
      sset("hgk_birch_offered", true)
      face(eo)
      say("Incredible, not too many people managed to get all the HOENN badges this quickly.\f"
        .. "You've come a long way from going on that initial delivery with that starter that I gave you.\f"
        .. "Speaking of which, how about raising that last POKéMON over there on the table?\f"
        .. "This will help complete your POKéDEX.")
      return true
    end
    if sget("hgk_birch_offered") and not sget("hgk_ball_taken") then
      face(eo)
      local O = objects()
      if O and not O._byId[BALL_LID] then
        -- the ball isn't on the table: Birch hands it over himself
        say("Here, take it.", function()
          giveAndSay(SP(st.left), 5, function(given) if given then sset("hgk_ball_taken", true) end end)
        end)
        return true
      end
      say("Go on, take it, it's not like I had anyone else claim a starter since you left on your adventure.\f"
        .. "Oh, and don't worry, I won't tell " .. rival() .. " that I gave you a second one. It will be our little secret.")
      return true
    end
    return false
  end

  local function talkBall(eo)
    if not ballWanted() then return false end
    local st = starters()
    local sp = SP(st.left)
    local where = giveMon(sp, 5)
    if where == "fail" then say("There's no room for it...") return true end
    sset("hgk_ball_taken", true)
    hideObject(eo)
    -- giveMon already gave it; the rest of giveAndSay by hand
    local sess = session()
    local mon = where == "party" and sess and sess.party and sess.party[#sess.party] or nil
    fanfare("MUS_OBTAIN_ITEM")
    say(playerName() .. " received " .. monName(sp) .. "!", function()
      nickname(mon, sp, function()
        if where == "pc" then say(monName(sp) .. " was sent to the PC.") end
      end)
    end)
    return true
  end

  -- ================================================================ GET OTHER DEEP SEA ITEM

  -- the Deep Sea item you picked: the bag, what we saw in it before, or the
  -- Clamperl evolution in your Pokédex
  local function otherDeepSea()
    if hasItem("ITEM_DEEP_SEA_TOOTH") then return "ITEM_DEEP_SEA_SCALE" end
    if hasItem("ITEM_DEEP_SEA_SCALE") then return "ITEM_DEEP_SEA_TOOTH" end
    local seen = sget("hgk_deepsea_had")
    if seen == "ITEM_DEEP_SEA_TOOTH" then return "ITEM_DEEP_SEA_SCALE" end
    if seen == "ITEM_DEEP_SEA_SCALE" then return "ITEM_DEEP_SEA_TOOTH" end
    -- the one you evolved a Clamperl with
    local tail, byss = caught(SP("HUNTAIL")), caught(SP("GOREBYSS"))
    if tail and not byss then return "ITEM_DEEP_SEA_SCALE" end
    if byss and not tail then return "ITEM_DEEP_SEA_TOOTH" end
    return nil
  end

  local function deepSeaReady()
    return on("hoenn_deepsea") and allBadges() and flag("FLAG_USED_STORAGE_KEY")
      and flag("FLAG_EXCHANGED_SCANNER") and not sget("hgk_deepsea_done")
  end

  local function giveDeepSea(item)
    if not bagDo("add", item) then say("Your BAG is full...") return end
    bagDo("remove", "ITEM_STORAGE_KEY")
    sset("hgk_deepsea_done", true)
    fanfare("MUS_OBTAIN_ITEM")
    local name = item == "ITEM_DEEP_SEA_TOOTH" and "DEEPSEATOOTH" or "DEEPSEASCALE"
    say(playerName() .. " received the " .. name .. "!\f"
      .. "Thank you so much, my friend. This will be a great piece in my collection.")
  end

  local function talkStern(eo)
    if not deepSeaReady() then return false end
    face(eo)
    local prompt = sget("hgk_deepsea_asked") and "Did you change your mind?"
      or ("Hey friend, I forgot to ask you earlier, but did you happen to get the STORAGE KEY when you went to the "
        .. "ABANDONED SHIP?\fOh, you did!! Great!\fThen would you trade it to me for the other DEEP SEA item "
        .. "that you didn't pick earlier?")
    sset("hgk_deepsea_asked", true)
    ask(prompt, function(yes)
      if not yes then say("But why? You don't need it.") return end
      local item = otherDeepSea()
      if item then giveDeepSea(item) return end
      -- nothing tells which one you took: let the player say
      ask("Which one did you pick earlier... the DEEPSEASCALE?", function(scale)
        giveDeepSea(scale and "ITEM_DEEP_SEA_TOOTH" or "ITEM_DEEP_SEA_SCALE")
      end)
    end)
    return true
  end

  -- ================================================================ GET OTHER FOSSIL (RS)

  local function talkScientist(eo)
    if not (rs() and on("hoenn_fossil")) or sget("hgk_fossil_done") then return false end
    if not (allBadges() and flag("FLAG_RECEIVED_FOSSIL_MON")) then return false end
    local lead = partySpecies(1)
    local give
    if lead == SP("CRADILY") then give = SP("ANORITH")
    elseif lead == SP("ARMALDO") then give = SP("LILEEP") end
    if not (lead and give) then return false end
    local base = lead == SP("CRADILY") and "LILEEP" or "ANORITH"
    face(eo)
    say("Well now, what do you have there? Is this the fully evolved form of the " .. base
      .. " that I revived for you? Incredible, I've never seen it before!\f"
      .. "Tell you what, some explorer brought me this other fossil that got buried deep into the sands, "
      .. "and I revived it. I would like you to have it.", function()
        giveAndSay(give, 20, function(given) if given then sset("hgk_fossil_done", true) end end)
      end)
    return true
  end

  -- ================================================================ GET EON TICKET

  local function talkNorman(eo)
    if not on("hoenn_eon") or sget("hgk_eon_done") then return false end
    if not champion() or not (caught(SP("LATIAS")) or caught(SP("LATIOS"))) then return false end
    if hasItem("ITEM_EON_TICKET") then sset("hgk_eon_done", true) return false end
    face(eo)
    local name = playerName()
    say(name .. "! Good to see you! There's a letter here for you, " .. name .. ".", function()
      if not bagDo("add", "ITEM_EON_TICKET") then say("Your BAG is full...") return end
      sset("hgk_eon_done", true)
      -- Ruby/Sapphire's harbor checks FLAG_SYS_HAS_EON_TICKET, Emerald's
      -- FLAG_ENABLE_SHIP_SOUTHERN_ISLAND (only the one the game has is set)
      setFlag("FLAG_SYS_HAS_EON_TICKET")
      setFlag("FLAG_ENABLE_SHIP_SOUTHERN_ISLAND")
      fanfare("MUS_OBTAIN_ITEM")
      say("Obtained the EON TICKET.\f" .. name .. " put away the EON TICKET in the KEY ITEMS POCKET.\f"
        .. "It appears to be a ferry ticket, but I've never seen one like it before.\f"
        .. "You should visit LILYCOVE and ask about it there.")
    end)
    return true
  end

  -- ================================================================ TRADE WITH LINK C.

  -- keyed by what it evolves into (Clamperl has two)
  local TRADE = {
    { from = "KADABRA", into = 65, key = "hgk_linkc_kadabra" },
    { from = "HAUNTER", into = 94, key = "hgk_linkc_haunter" },
    { from = "GRAVELER", into = 76, key = "hgk_linkc_graveler" },
    { from = "MACHOKE", into = 68, key = "hgk_linkc_machoke" },
    { from = "POLIWHIRL", into = 186, key = "hgk_linkc_politoed", item = "ITEM_KINGS_ROCK" },
    { from = "SLOWPOKE", into = 199, key = "hgk_linkc_slowking", item = "ITEM_KINGS_ROCK" },
    { from = "ONIX", into = 208, key = "hgk_linkc_steelix", item = "ITEM_METAL_COAT" },
    { from = "SCYTHER", into = 212, key = "hgk_linkc_scizor", item = "ITEM_METAL_COAT" },
    { from = "SEADRA", into = 230, key = "hgk_linkc_seadra", item = "ITEM_DRAGON_SCALE" },
    { from = "PORYGON", into = 233, key = "hgk_linkc_porygon2", item = "ITEM_UP_GRADE" },
    { from = "CLAMPERL", into = 367, key = "hgk_linkc_clamperl_tooth", item = "ITEM_DEEP_SEA_TOOTH" },
    { from = "CLAMPERL", into = 368, key = "hgk_linkc_clamperl_scale", item = "ITEM_DEEP_SEA_SCALE" },
  }

  local function tradeRow(mon)
    if not mon or isEgg(mon) then return nil end
    local sp = speciesOf(mon)
    for _, t in ipairs(TRADE) do
      if SP(t.from) == sp and not sget(t.key) and (not t.item or heldItem(mon) == itemId(t.item)) then
        return t
      end
    end
  end

  local function partyHasTrade()
    for _, mon in ipairs((session() or {}).party or {}) do
      if tradeRow(mon) then return true end
    end
    return false
  end

  local function tradeStep(sent, received)
    local TradeScene = req("src.core.game3.trade_scene")
    return {
      start = function()
        if not (TradeScene and TradeScene.play) then return end
        TradeScene.play(sent, received, nil, { otName = "LINK C." })
      end,
      wait = function()
        if not (TradeScene and TradeScene.step) then return true end
        if not TradeScene.isOpen() then return true end
        return TradeScene.step() == true
      end,
    }
  end

  local function evolveStep(mon, target, sess)
    local Scene = req("src.ui.game3.evolution_scene")
    local Evolution = req("src.core.game3.evolution")
    local shown = false
    return {
      start = function()
        if Scene and Scene.start and target then
          shown = pcall(Scene.start, mon, target, { canStop = false, session = sess, bag = sess.bag, via = "trade" })
        end
        if not shown and target and Evolution and Evolution.apply then
          pcall(Evolution.apply, mon, target, sess, sess.bag, "trade")
        end
      end,
      wait = function(frames)
        if not shown then return true end
        return frames > 2 and not (Scene.isOpen and Scene.isOpen())
      end,
    }
  end

  local function linkCopy(mon)
    local copy = {}
    for k, v in pairs(mon) do copy[k] = v end
    copy.nickname = ""
    copy.ot, copy.otName = "LINK C.", "LINK C."
    copy.otId = 31415
    copy.heldItem, copy.item = 0, 0
    return copy
  end

  -- Link C.'s own Pokémon evolves on his side too (it was traded), so the
  -- trade back shows it evolved. Only the trade scene ever sees this copy.
  local function evolveCopy(copy, target)
    if not (copy and tonumber(target)) then return end
    copy.species = tonumber(target)
    if copy.speciesId ~= nil then copy.speciesId = tonumber(target) end
    copy.name = nil
  end

  local ONLY = "I only trade KADABRA, HAUNTER, GRAVELER or MACHOKE.\f"
    .. "Or POLIWHIRL or SLOWPOKE holding a KING'S ROCK, ONIX or SCYTHER holding a METAL COAT, "
    .. "SEADRA holding a DRAGON SCALE, PORYGON holding an UP-GRADE,\f"
    .. "or CLAMPERL holding a DEEPSEATOOTH or a DEEPSEASCALE."

  local function tradeEvolve(slot)
    local sess = session()
    local mon = sess and sess.party and sess.party[slot]
    local row = tradeRow(mon)
    if not row then say(ONLY) return end
    local Evolution = req("src.core.game3.evolution")
    -- tradeTarget also uses up the held item, like a real trade
    local target = Evolution and Evolution.tradeTarget and Evolution.tradeTarget(mon, sess)
    if not target then say(ONLY) return end
    local his = linkCopy(mon)
    say("Okay, connect the cable like so!", function()
      runSteps({ fadeStep(true), tradeStep(mon, his), evolveStep(mon, target, sess) }, function()
        evolveCopy(his, speciesOf(mon) or target)
        say("OK, now let's trade back.", function()
          runSteps({ fadeStep(true), tradeStep(his, mon) }, function()
            sset(row.key, true)
            say("Thank you, friend.")
          end)
        end)
      end)
    end)
  end

  local function talkGameCube()
    if not on("hoenn_linkc") or not partyHasTrade() then return false end
    say("Someone is communicating with you through your GameCube's online connection.", function()
      ask("My name is LINK C. and I have these POKéMON that I really love, but they can only evolve via trading.\f"
        .. "Now, I don't want to give them away after they evolve, I want them back, hence why I'll only trade "
        .. "for the same kind of POKéMON. That way, I know I'll get them back.\fWhat do you say, want to trade?", function(yes)
          if not yes then say("OK, some other time then.") return end
          local PartyMenu = req("src.ui.game3.party_menu")
          local sess = session()
          if not (PartyMenu and sess and sess.party and sess.party[1]) then return end
          local picked = false
          PartyMenu.show(sess.party, nil, {
            mode = "choose", session = sess,
            onSelect = function(slot)
              picked = true
              if tonumber(slot) then tradeEvolve(tonumber(slot)) else say("OK, some other time then.") end
            end,
            onClose = function()
              local Task = req("src.core.game3.task")
              local frames = 0
              local function check()
                frames = frames + 1
                if frames < 2 then return false end
                if not picked then say("OK, some other time then.") end
                return true
              end
              if Task and Task.spawn then Task.spawn(check) end
            end,
          })
        end)
    end)
    return true
  end

  -- ================================================================ GET OTHER BOX LEGENDARY (RS)

  local BOX_LID = 0x74
  local function boxInfo()
    if version() == "ruby" then return { mine = "GROUDON", other = "KYOGRE", gfx = "KYOGRE_1" } end
    return { mine = "KYOGRE", other = "GROUDON", gfx = "GROUDON_1" }
  end
  local function boxWanted()
    if not (rs() and on("hoenn_box")) or sget("hgk_box_done") then return false end
    if sget("hgk_box_open") then return true end
    if not (champion() and caught(SP("RAYQUAZA"))) then return false end
    local b = boxInfo()
    local a, c = partySpecies(1), partySpecies(2)
    local ray, mine = SP("RAYQUAZA"), SP(b.mine)
    return (a == ray and c == mine) or (a == mine and c == ray)
  end

  local function placeBox()
    if not mapId():find("CAVE_OF_ORIGIN_B4F") then return end
    local O = objects()
    if not O or O._byId[BOX_LID] or not mapLoaded() then return end
    local b = boxInfo()
    -- the spot of your own legend (its object is hidden once it's caught)
    local x, y
    for _, def in ipairs(O._defs or {}) do
      local g = tonumber(def.graphicsId or def.graphics)
      if g and (g == gfx("KYOGRE_1") or g == gfx("GROUDON_1") or g == gfx("KYOGRE_2") or g == gfx("GROUDON_2")) then
        x, y = tonumber(def.x), tonumber(def.y)
      end
    end
    if not x then
      local def = currentDef()
      if not def then return end
      x, y = nearestFree(math.floor((tonumber(def.width) or 20) / 2), math.floor((tonumber(def.height) or 20) / 2), 0, 6)
    end
    if x and spawnObject(BOX_LID, x, y, gfx(b.gfx), 8) then
      sset("hgk_box_open", true)
      info("other box legendary: %s placed at %d,%d", b.other, x, y)
    end
  end

  local function talkBox(eo)
    local b = boxInfo()
    local sp = SP(b.other)
    face(eo)
    cry(sp)
    wildBattle(sp, 45, function(got)
      if got then
        sset("hgk_box_done", true)
        hideObject(eo)
      elseif not on("hoenn_limited") then
        sset("hgk_box_done", true) -- one try only
        hideObject(eo)
      end
    end)
    return true
  end

  -- BIRTH ISLAND (Ruby/Sapphire): components/hoenn_all/birth_island.lua
  local BI = ctx.birthIslandFactory({ version = version, ctx = ctx, req = req, rs = rs, info = info, warn = warn, session = session, sget = sget, sset = sset, mapId = mapId, objects = objects, spawnObject = spawnObject, hideObject = hideObject, face = face, ask = ask, say = say, cry = cry, wildBattle = wildBattle, SP = SP, gfx = gfx, on = on, now = now, mapLoaded = mapLoaded })
  H.birthIsland = BI



  -- ================================================================ GET A SPECIAL WISH

  local JIRACHI_LID, AURORA_LID = 0x72, 0x73

  local function regionalCaughtTo(maxNum)
    local sess = session()
    local Dex = req("src.core.game3.dex")
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
    return found >= maxNum
  end

  local wishCheckAt, wishOk = 0, false
  local function wishEligible()
    if not on("hoenn_wish") or sget("hgk_jirachi_caught") then return false end
    if sget("hgk_wish_hint") then return true end
    local t = now()
    if t >= wishCheckAt then
      wishCheckAt = t + 2
      wishOk = regionalCaughtTo(200)
    end
    return wishOk
  end

  local function talkMom(eo)
    if sget("hgk_wish_hint") or not wishEligible() then return false end
    face(eo)
    sset("hgk_wish_hint", true)
    say("Oh, honey, you're just in time!\fA cute little floating POKéMON just came into the house and went "
      .. "upstairs into your room.\fIt didn't look dangerous, it just looked curious.")
    return true
  end

  -- Jirachi has no overworld sprite in any Gen 3 game: its object is drawn
  -- with Wilds of Hoenn's HGSS sheet (assets/sprites/jirachi.png, 18 frames
  -- of 32x32, same layout as Wilds of Hoenn's actor renderer).
  local jirachiImg, jirachiQuads = nil, nil
  local FRAME = { down = 0, up = 1, left = 2, right = 2 }
  local function jirachiImage()
    if jirachiImg == nil then
      jirachiImg = false
      local ok, img = pcall(function() return ctx.mod.assets:image("assets/sprites/jirachi.png") end)
      if ok and img then
        jirachiImg = img
        if img.setFilter then pcall(img.setFilter, img, "nearest", "nearest") end
        local iw, ih = img:getDimensions()
        jirachiQuads = {}
        for i = 0, 17 do jirachiQuads[i] = love.graphics.newQuad(0, i * 32, 32, 32, iw, ih) end
      else
        warn("jirachi sprite", img)
      end
    end
    return jirachiImg or nil
  end

  local function drawJirachi(a, camX, camY)
    local img = jirachiImage()
    if not img then return end
    local facing = a.facing or "down"
    local q = jirachiQuads[FRAME[facing] or 0]
    local bob = math.floor(math.sin(now() * 4) * 1.5 + 0.5)
    local x = math.floor((a.x or 0) - (camX or 0)) - 8
    local y = math.floor((a.y or 0) - (camY or 0)) - 16 - 2 + bob
    love.graphics.setColor(1, 1, 1, 1)
    if facing == "right" then
      love.graphics.draw(img, q, x + 32, y, 0, -1, 1)
    else
      love.graphics.draw(img, q, x, y)
    end
  end

  local function dressJirachi(eo)
    if not eo then return end
    eo.foreign = eo.foreign or { ph3Jirachi = true }
    eo.draw = drawJirachi
  end

  local function spawnJirachi(x, y)
    -- any graphics id works for the object itself; it's drawn with our sheet
    local eo = spawnObject(JIRACHI_LID, x, y, gfx("ITEM_BALL"), 8)
    dressJirachi(eo)
  end

  local function doorOutside()
    local def = currentDef()
    if not def then return nil end
    local want = houseKey() .. "_1F"
    for _, wp in ipairs(def.warps or {}) do
      for _, v in pairs(wp) do
        if type(v) == "string" and v:upper():find(want, 1, true) then return tonumber(wp.x), tonumber(wp.y) end
      end
    end
  end

  local function placeWish()
    local map = mapId()
    local O = objects()
    if not O or not mapLoaded() then return end
    local def = currentDef()
    if not def then return end
    local inRoom = map:find(houseKey() .. "_2F", 1, true)
    local outside = map:match("LITTLEROOT_TOWN$")
    if not O._byId[JIRACHI_LID] and not sget("hgk_jirachi_caught") then
      if inRoom and sget("hgk_wish_hint") and not sget("hgk_jirachi_outside") then
        local w, h = tonumber(def.width) or 10, tonumber(def.height) or 8
        local x, y = nearestFree(math.floor(w / 2), math.floor(h / 2), 0, 6)
        if x then spawnJirachi(x, y) end
      elseif outside and sget("hgk_jirachi_outside") then
        local dx, dy = doorOutside()
        if not dx then dx, dy = math.floor((tonumber(def.width) or 20) / 2), math.floor((tonumber(def.height) or 20) / 2) end
        local x, y = nearestFree(dx, dy + 2, 0, 4)
        if x then spawnJirachi(x, y) end
      end
    elseif O._byId[JIRACHI_LID] then
      dressJirachi(O._byId[JIRACHI_LID])
    end
    -- Emerald: the item ball with the Aurora Ticket, where Jirachi was
    if (emerald() or BI.available()) and outside and sget("hgk_jirachi_caught") and not sget("hgk_aurora_taken")
        and not O._byId[AURORA_LID] then
      local x, y = tonumber(sget("hgk_jirachi_x")), tonumber(sget("hgk_jirachi_y"))
      if x and y then spawnObject(AURORA_LID, x, y, gfx("ITEM_BALL"), 8) end
    end
  end

  -- Jirachi circles around you a few times, then flies down and out
  local function jirachiLeaves(eo)
    local P = req("src.core.game3.player")
    if not (eo and P) then return end
    local ring = { { 0, -1 }, { 1, -1 }, { 1, 0 }, { 1, 1 }, { 0, 1 }, { -1, 1 }, { -1, 0 }, { -1, -1 } }
    local FACE = { "down", "left", "left", "up", "up", "right", "right", "down" }
    local px, py = P.cellX or 0, P.cellY or 0
    local step = 0
    local total = #ring * 3
    runSteps({ {
      start = function() cry(SP("JIRACHI")) end,
      wait = function(frames)
        if frames % 5 ~= 0 then return false end
        step = step + 1
        local r = ring[(step - 1) % #ring + 1]
        eo.cellX, eo.cellY = px + r[1], py + r[2]
        eo.px, eo.py = eo.cellX * 16, eo.cellY * 16
        eo.facing = FACE[(step - 1) % #ring + 1]
        -- you turn to follow it
        if r[1] == 0 then P.facing = r[2] < 0 and "up" or "down"
        elseif r[2] == 0 then P.facing = r[1] < 0 and "left" or "right" end
        return step >= total
      end,
    } }, function()
      sset("hgk_jirachi_outside", true)
      hideObject(eo)
      say("The little POKéMON circled around you, then flew downstairs and out of the house!")
    end)
  end

  local function talkJirachi(eo)
    local map = mapId()
    if map:find(houseKey() .. "_2F", 1, true) then
      jirachiLeaves(eo)
      return true
    end
    local sp = SP("JIRACHI")
    cry(sp)
    wildBattle(sp, 5, function(got)
      if got then
        sset("hgk_jirachi_caught", true)
        sset("hgk_jirachi_x", eo.cellX)
        sset("hgk_jirachi_y", eo.cellY)
        hideObject(eo)
      elseif not on("hoenn_limited") then
        sset("hgk_jirachi_caught", true) -- one try only (no ticket left behind)
        sset("hgk_aurora_taken", true)
        hideObject(eo)
      end
    end)
    return true
  end

  local function talkAurora(eo)
    local added
    if rs() then added = BI.giveTicket() else added = bagDo("add", "ITEM_AURORA_TICKET") end
    if not added then say("Your BAG is full...") return true end
    sset("hgk_aurora_taken", true)
    hideObject(eo)
    setFlag("FLAG_RECEIVED_AURORA_TICKET")
    setFlag("FLAG_ENABLE_SHIP_BIRTH_ISLAND")
    fanfare("MUS_OBTAIN_ITEM")
    say(playerName() .. " found an AURORA TICKET!\f" .. playerName()
      .. " put away the AURORA TICKET in the KEY ITEMS POCKET.")
    return true
  end

  -- ================================================================ talk dispatch

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

  local function tryTalk()
    if not hoenn() then return false end
    local P = req("src.core.game3.player")
    local O = objects()
    if not (P and O) then return false end
    local d = DELTA[P.facing or "down"] or DELTA.down
    local fx, fy = P.cellX + d[1], P.cellY + d[2]
    local map = mapId()
    local eo = O.at(fx, fy)
    if eo then
      local lid, g = eo.localId, gfxOf(eo)
      if BI.isOurs(map) then return BI.talk(eo) end
      -- Ruby/Sapphire's Lilycove harbor: Birth Island with the Aurora Ticket
      if rs() and map:find("LILYCOVE_CITY_HARBOR", 1, true) and BI.hasTicket()
          and (g == gfx("SAILOR") or npcUsesFlag(eo, "FLAG_SYS_HAS_EON_TICKET")) then
        return BI.talkFerry(eo, function()
          local Field = req("src.core.game3.field")
          local Runtime = req("src.core.game3.runtime")
          if Field and H.origInteract then pcall(H.origInteract, Runtime and Runtime._game) end
        end)
      end
      if lid == JIRACHI_LID then return talkJirachi(eo) end
      if lid == AURORA_LID then return talkAurora(eo) end
      if lid == BOX_LID then return talkBox(eo) end
      if lid == BALL_LID then return talkBall(eo) end
      if map:find("PROFESSOR_BIRCHS_LAB", 1, true) and g == gfx("PROF_BIRCH") then return talkBirch(eo) end
      if map:find("PETALBURG_CITY_GYM", 1, true) and g == gfx("NORMAN") then return talkNorman(eo) end
      if map:find(houseKey() .. "_1F", 1, true) and g == gfx("MOM") then return talkMom(eo) end
      if map:find("DEVON_CORP", 1, true) and rs() and on("hoenn_fossil") and not sget("hgk_fossil_done")
          and npcUsesFlag(eo, "FLAG_RECEIVED_FOSSIL_MON") then
        return talkScientist(eo)
      end
      if map:find("SLATEPORT", 1, true) and deepSeaReady() and npcUsesFlag(eo, "FLAG_EXCHANGED_SCANNER") then
        return talkStern(eo)
      end
      return false
    end
    -- the GameCube in your room (a background event, not an object)
    if map:find(houseKey() .. "_2F", 1, true) and on("hoenn_linkc") then
      local ev = bgEventAt(fx, fy)
      if ev and scriptSays(ev.scriptKey, "GAMECUBE") then return talkGameCube() end
    end
    return false
  end

  -- ================================================================ GET OTHER GAME EXCLUSIVES

  local PAIRS = {
    ruby = { { "SEEDOT", "LOTAD" }, { "NUZLEAF", "LOMBRE" }, { "MAWILE", "SABLEYE" },
      { "ZANGOOSE", "SEVIPER" }, { "SOLROCK", "LUNATONE" } },
    emerald = { { "SEVIPER", "ZANGOOSE" }, { "SOLROCK", "LUNATONE" } },
  }
  PAIRS.sapphire = PAIRS.ruby
  local ADD = { "SURSKIT", "MEDITITE", "MEDICHAM", "ROSELIA" } -- Emerald: Ruby/Sapphire slots

  local otherCache = {}
  local function otherOf(sp)
    local v = version()
    local list = PAIRS[v]
    if not list then return nil end
    local t = otherCache[v]
    if not t then
      t = {}
      for _, p in ipairs(list) do
        local a, b = SP(p[1]), SP(p[2])
        if a and b then t[a], t[b] = b, a end
      end
      if next(t) then otherCache[v] = t end
    end
    return t[tonumber(sp)]
  end

  -- Pokédex LOCATION tab: the species a wild slot of `sp` can turn into
  function H.swapFor(sp)
    if not (hoenn() and on("hoenn_exclusive")) then return nil end
    return otherOf(sp)
  end

  -- ------- Emerald: Ruby/Sapphire's own slots for the four missing ones

  local LAND_W = { 20, 20, 10, 10, 10, 10, 5, 5, 4, 4, 1, 1 }
  local WATER_W = { 60, 30, 5, 4, 1 }
  local addOriginal = setmetatable({}, { __mode = "k" })
  local addState = nil
  local rsData, rsTried = nil, false

  local function loadRsTables()
    if rsTried then return rsData end
    rsTried = true
    local GameVersion = req("src.core.GameVersion")
    local CacheFs = req("src.import.CacheFs")
    local CachePaths = req("src.core.game3.cache_paths")
    if not (GameVersion and CacheFs and CacheFs.readAt) then return nil end
    local root = (CachePaths and CachePaths.CACHE_ROOT) or "data/generated/gba"
    for _, v in ipairs({ "ruby", "sapphire" }) do
      local ok, data = pcall(function()
        local inf = GameVersion.info(v)
        local src = CacheFs.readAt(((inf and inf.cachePrefix) or "") .. root .. "/encounters.lua")
        if not src then return nil end
        return assert(load(src, "@" .. v .. " encounters", "t", {}))()
      end)
      if ok and type(data) == "table" then
        rsData = { tables = data, version = v }
        info("emerald exclusives: using %s's encounter tables", v)
        return rsData
      end
    end
    info("emerald exclusives: Ruby/Sapphire not installed, Surskit/Meditite/Medicham/Roselia not added")
    return nil
  end

  local function restoreAdds()
    for slot, o in pairs(addOriginal) do
      slot.species, slot.minLevel, slot.maxLevel = o.species, o.minLevel, o.maxLevel
      addOriginal[slot] = nil
    end
  end

  local function applyAdds()
    local Enc = req("src.core.game3.encounters")
    local tables = Enc and Enc._tables
    if type(tables) ~= "table" then return end
    local want = emerald() and on("hoenn_exclusive")
    local state = tostring(tables) .. "|" .. tostring(version()) .. "|" .. tostring(want)
    if state == addState then return end
    addState = state
    restoreAdds()
    if not want or not next(tables) then return end
    local data = loadRsTables()
    local C = req("src.core.game3.constants")
    if not (data and C) then return end
    local okR, rc = pcall(C.of, data.version)
    local okE, ec = pcall(C.of, "emerald")
    if not (okR and okE) then return end
    -- Ruby/Sapphire "group:num" -> map name -> Emerald "group:num"
    local rsName = {}
    for name, row in pairs(rc.map_groups.byName or {}) do
      if type(row) == "table" then rsName[row.group .. ":" .. row.num] = name end
    end
    local emTables = {}
    for _, t in pairs(tables) do
      if type(t) == "table" and t.mapGroup then
        local k = t.mapGroup .. ":" .. t.mapNum
        emTables[k] = emTables[k] or {}
        local list, dup = emTables[k], false
        for _, x in ipairs(list) do if x == t then dup = true end end
        if not dup then list[#list + 1] = t end
      end
    end
    local addSet = {}
    for _, n in ipairs(ADD) do local id = SP(n) if id then addSet[id] = true end end
    local done, changed = {}, 0
    for _, rt in pairs(data.tables) do
      if type(rt) == "table" and rt.mapGroup then
        local rk = rt.mapGroup .. ":" .. rt.mapNum
        local name = rsName[rk]
        local erow = name and ec.map_groups.byName[name]
        if erow and not done[rk] then
          done[rk] = true
          for _, et in ipairs(emTables[erow.group .. ":" .. erow.num] or {}) do
            for _, area in ipairs({ "land", "water" }) do
              local rs_ = type(rt[area]) == "table" and rt[area].slots
              local em = type(et[area]) == "table" and et[area].slots
              local weights = area == "land" and LAND_W or WATER_W
              if type(rs_) == "table" and type(em) == "table" then
                for i, rslot in ipairs(rs_) do
                  local sp = tonumber(rslot.species)
                  if sp and addSet[sp] then
                    local present = false
                    for _, e in ipairs(em) do if tonumber(e.species) == sp then present = true end end
                    if not present or (em[i] and tonumber(em[i].species) ~= sp and not addOriginal[em[i]]) then
                      local function count(s)
                        local n = 0
                        for _, e in ipairs(em) do if tonumber(e.species) == s then n = n + 1 end end
                        return n
                      end
                      -- a slot whose Pokémon is still in another slot of this area,
                      -- the closest in weight to Ruby/Sapphire's slot
                      local pick, best
                      for j, e in ipairs(em) do
                        local s = tonumber(e.species)
                        if s and s ~= sp and not addSet[s] and not addOriginal[e] and count(s) >= 2 then
                          local diff = math.abs((weights[j] or 0) - (weights[i] or 0)) + (j == i and -1 or 0)
                          if not best or diff < best then pick, best = j, diff end
                        end
                      end
                      local slot = pick and em[pick]
                      if slot then
                        addOriginal[slot] = { species = slot.species, minLevel = slot.minLevel, maxLevel = slot.maxLevel }
                        slot.species, slot.minLevel, slot.maxLevel = sp, rslot.minLevel, rslot.maxLevel
                        changed = changed + 1
                        info("emerald exclusives: %s %s slot %d -> %s Lv%s-%s", tostring(name), area, pick,
                          monName(sp), tostring(rslot.minLevel), tostring(rslot.maxLevel))
                      else
                        info("emerald exclusives: %s %s: no free slot for %s", tostring(name), area, monName(sp))
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    info("emerald exclusives: %d slots added", changed)
  end

  function H.refreshTables()
    local ok, err = pcall(applyAdds)
    if not ok then warn("emerald slots", err) end
  end

  local function installAdds()
    local Enc = require("src.core.game3.encounters")
    local origLoad = Enc.loadFromMod
    Enc.loadFromMod = function(...)
      local r = { origLoad(...) }
      addState = nil
      H.refreshTables()
      return (table.unpack or unpack)(r)
    end
    local origTableFor = Enc.tableFor
    Enc.tableFor = function(...)
      H.refreshTables()
      return origTableFor(...)
    end
    Enc.table_for = Enc.tableFor
  end

  local function encSpecies(enc)
    if type(enc) ~= "table" then return nil end
    local id = tonumber(enc.species or enc.speciesId)
    if not id and enc.species then
      local Pokemon = req("src.core.game3.pokemon")
      local ok, v = pcall(Pokemon.speciesFromName, enc.species)
      id = ok and tonumber(v) or nil
    end
    return id
  end

  local function installWohFilter()
    local find = ctx.mod and ctx.mod.find
    local woh = type(find) == "function" and find("wilds_of_hoenn") or nil
    local ex = woh and woh.exports
    if not (ex and type(ex.addSpawnFilter) == "function") then return false end
    ex.addSpawnFilter("project_highlander_gen3_hoenn", function(enc)
      local sp = encSpecies(enc)
      local other = sp and H.swapFor(sp)
      if other and rand() < 0.5 then enc.species, enc.speciesId = other, other end
      return enc
    end)
    info("wilds of hoenn: spawn filter added (hoenn exclusives)")
    return true
  end

  -- ================================================================ INFINITE TRIES FOR RARE PKMN

  -- the words in the names of the flags that hide / mark each one as beaten
  local RARE = {
    REGIROCK = { "REGIROCK" }, REGICE = { "REGICE" }, REGISTEEL = { "REGISTEEL" },
    KYOGRE = { "KYOGRE", "LEGEND_MON" }, GROUDON = { "GROUDON", "LEGEND_MON" }, RAYQUAZA = { "RAYQUAZA" },
    LATIAS = { "LATIAS_OR_LATIOS", "LATIOS_OR_LATIAS" }, LATIOS = { "LATIAS_OR_LATIOS", "LATIOS_OR_LATIAS" },
    JIRACHI = { "JIRACHI" }, DEOXYS = { "DEOXYS" }, MEW = { "MEW" }, LUGIA = { "LUGIA" },
    HO_OH = { "HO_OH" }, SUDOWOODO = { "SUDOWOODO" },
  }
  local function rareWords(sp)
    for name, words in pairs(RARE) do
      if SP(name) == sp then return words end
    end
  end

  local stay = nil -- { words, since, name, blocked = { [flagId] = true } }

  local function blockedFlag(id)
    local name = flagName(id)
    if type(name) ~= "string" then return false end
    if not (name:find("^FLAG_HIDE_") or name:find("^FLAG_DEFEATED_") or name:find("^FLAG_BATTLED_")) then return false end
    for _, w in ipairs(stay.words) do
      if name:find(w, 1, true) then return true end
    end
    return false
  end

  local function tickStay()
    if not stay then return end
    local Space = req("src.core.game3.scripting.space")
    if Space and Space.vm and Space.vm.isRunning and Space.vm:isRunning() then return end
    local Field = req("src.core.game3.field")
    if Field and Field.locked then return end
    if now() - stay.since < 0.5 then return end
    local s = stay
    stay = nil
    for id in pairs(s.blocked) do setFlagId(id, false) end
  end

  local function installStay()
    local Ops = require("src.core.game3.scripting.ops_a")
    local origDispatch = Ops.dispatch
    Ops.dispatch = function(vm, row, ...)
      if stay and type(row) == "table" then
        if row.op == "removeobject" then
          info("infinite tries: kept %s on the map", tostring(stay.name))
          return false
        end
        if row.op == "setflag" then
          local id = tonumber(row.flag or row[1])
          if id and blockedFlag(id) then
            stay.blocked[id] = true
            return false
          end
        end
      end
      return origDispatch(vm, row, ...)
    end
    local TextIR = require("src.core.game3.scripting.text_ir")
    local origText = TextIR.toTextBox
    TextIR.toTextBox = function(...)
      local r = { origText(...) }
      if stay and type(r[1]) == "string" then
        local low = r[1]:lower()
        if low:find("flew away") or low:find("disappeared") or low:find("vanished") then
          r[1] = tostring(stay.name) .. " is still here!"
        end
      end
      return (table.unpack or unpack)(r)
    end
  end

  -- the roaming Latias / Latios stays roaming after a battle that isn't a catch
  local function installRoamer()
    local Roamer = require("src.core.game3.roamer")
    local origEnd = Roamer.onBattleEnd
    Roamer.onBattleEnd = function(sess, foeState, result, ...)
      local r = sess and type(sess.roamer) == "table" and sess.roamer or nil
      local wasActive = r and r.active
      local out = { origEnd(sess, foeState, result, ...) }
      local ok, err = pcall(function()
        if not (hoenn() and on("hoenn_limited") and wasActive and r and not r.active) then return end
        local Natives = req("src.core.game3.scripting.natives")
        local code = Natives and Natives.outcome_to_code and Natives.outcome_to_code(result)
        if code == 7 or isCatch(result) then return end
        r.active = true
        if (tonumber(r.hp) or 0) <= 0 then
          local Pokemon = req("src.core.game3.pokemon")
          local okS, stats = pcall(Pokemon.calcStats, r.species, r.level, r.ivs, {}, r.personality)
          r.hp = (okS and stats and tonumber(stats.maxHp)) or 1
          r.status = 0
        end
        info("infinite tries: the roaming %s keeps roaming", monName(r.species))
      end)
      if not ok then warn("roamer stay", err) end
      return (table.unpack or unpack)(out)
    end

    -- ROAMING HUNTER: on its route, every encounter is the roamer
    local origTry = Roamer.tryEncounter
    Roamer.tryEncounter = function(sess, map, ...)
      local okH, mon = pcall(function()
        if not (hoenn() and on("hoenn_roamer")) then return nil end
        local rr = sess and type(sess.roamer) == "table" and sess.roamer or nil
        if not (rr and rr.active and rr.map == map) then return nil end
        local m = Roamer.instance(sess)
        local MR = req("src.mods.Runtime")
        if m and MR and MR.wants and MR.wants("roamer.encountered") then
          MR.emit("roamer.encountered", { index = 1, slot = rr, species = rr.species, level = rr.level, mapId = map })
        end
        return m
      end)
      if okH and mon then return mon end
      return origTry(sess, map, ...)
    end
  end

  -- ROAMING HUNTER: it never runs from the battle
  local function installNoFlee()
    local Ai = require("src.core.game3.battle.ai")
    local function noRun(st, id, act)
      if not (type(act) == "table" and act.kind == "run" and type(st) == "table" and st.roamer) then return act end
      if not (hoenn() and on("hoenn_roamer")) then return act end
      local State = req("src.core.game3.battle.state")
      local b = State and State.battler and State.battler(st, id or 1)
      local moves = b and b.mon and b.mon.moves or {}
      local usable = {}
      for i = 1, 4 do
        local mv = moves[i]
        if mv ~= nil and mv ~= 0 and mv ~= "" then
          local pp = type(mv) == "table" and tonumber(mv.pp) or nil
          if pp == nil or pp > 0 then usable[#usable + 1] = i end
        end
      end
      if #usable == 0 then
        return { kind = "move", move = "STRUGGLE", user = "enemy", battler = act.battler }
      end
      local slot = usable[math.floor(rand() * #usable) + 1]
      return { kind = "move", move = moves[slot], slot = slot, user = "enemy", battler = act.battler }
    end
    local origAction = Ai.chooseAction
    Ai.chooseAction = function(st, id, ...)
      local act = origAction(st, id, ...)
      local ok, out = pcall(noRun, st, id, act)
      return ok and out or act
    end
    local origMove = Ai.chooseMove
    Ai.chooseMove = function(st, opts, ...)
      local act = origMove(st, opts, ...)
      local ok, out = pcall(noRun, st, type(opts) == "table" and opts.battler or 1, act)
      return ok and out or act
    end
  end

  local function installBattles()
    local BB = require("src.core.game3.battle_bridge")
    local orig = BB.startWild
    BB.startWild = function(mod, game, enc, opts, ...)
      opts = opts or {}
      local ok = pcall(function()
        if not hoenn() or type(enc) ~= "table" then return end
        local sp = encSpecies(enc)
        local scripted = opts.wildScripted or opts.legendary or opts.oldManTutorial
        local locked = opts.speciesLocked or opts.wildsOfHoenn
        local roamer = opts.roamer or enc.roamer
        if on("hoenn_exclusive") and not scripted and not locked and not roamer and sp then
          local other = otherOf(sp)
          if other and rand() < 0.5 then enc.species, enc.speciesId = other, other end
        end
        -- static rare Pokémon of the game's own scripts (ours handle themselves)
        local words = sp and not roamer and not opts.ph3Own and rareWords(sp)
        if on("hoenn_limited") and words then
          local done = opts.done
          opts.done = function(result, ...)
            if not isCatch(result) then
              stay = { words = words, since = now(), name = monName(sp), blocked = {} }
              info("infinite tries: %s not caught (%s), it stays", monName(sp), tostring(result))
            end
            if done then return done(result, ...) end
          end
        end
      end)
      if not ok then warn("battle", "options skipped") end
      return orig(mod, game, enc, opts, ...)
    end
  end

  -- ================================================================ ticks

  local spawnedFor = nil
  local function tickSpawns()
    if not hoenn() then return end
    local O = objects()
    if not O then return end
    local map = mapId()
    if spawnedFor ~= map then spawnedFor = map end
    if not mapLoaded() then return end
    -- starter ball on the lab table
    if map:find("PROFESSOR_BIRCHS_LAB", 1, true) and ballWanted() and not O._byId[BALL_LID] then
      spawnObject(BALL_LID, BALL_X, BALL_Y, gfx("ITEM_BALL"), 8)
    end
    if boxWanted() then placeBox() end
    if on("hoenn_wish") or sget("hgk_wish_hint") then placeWish() end
    if BI.isOurs(map) then BI.tick() end
    -- remember which Deep Sea item the bag held
    if not sget("hgk_deepsea_had") then
      if hasItem("ITEM_DEEP_SEA_TOOTH") then sset("hgk_deepsea_had", "ITEM_DEEP_SEA_TOOTH")
      elseif hasItem("ITEM_DEEP_SEA_SCALE") then sset("hgk_deepsea_had", "ITEM_DEEP_SEA_SCALE") end
    end
  end

  local tickAt = 0
  local function installField()
    local Field = require("src.core.game3.field")
    local origInteract = Field.interact
    H.origInteract = origInteract
    Field.interact = function(game, ...)
      if hoenn() and fieldReady() then
        local ok, done = pcall(tryTalk)
        if not ok then warn("talk", done) end
        if ok and done then return true end
      end
      return origInteract(game, ...)
    end
    local origUpdate = Field.update
    Field.update = function(...)
      local r = { origUpdate(...) }
      if hoenn() then
        local ok, err = pcall(tickStay)
        if not ok then warn("stay", err) end
        local okA, errA = pcall(applyAdds)
        if not okA then warn("emerald slots", errA) end
        if rs() then
          local okB, errB = pcall(BI.frame)
          if not okB then warn("birth island", errB) end
        end
        local t = now()
        if t >= tickAt and Field.running and fieldReady() then
          tickAt = t + 0.1
          local okS, errS = pcall(tickSpawns)
          if not okS then warn("spawns", errS) end
        end
      end
      return (table.unpack or unpack)(r)
    end
  end

  -- ================================================================ install

  local done = {}
  function H.install()
    if not done["woh filter"] then
      local ok, found = pcall(installWohFilter)
      if ok and found then done["woh filter"] = true elseif not ok then warn("woh filter", found) end
    end
    if H.installed then return end
    local all = true
    for _, s in ipairs({ { "battles", installBattles }, { "stay", installStay }, { "roamer", installRoamer },
        { "no flee", installNoFlee }, { "slots", installAdds }, { "field", installField },
        { "birth island", BI.install } }) do
      if not done[s[1]] then
        local ok, err = pcall(s[2])
        if ok then done[s[1]] = true else all = false warn(s[1], err) end
      end
    end
    H.installed = all
  end

  return H
end
