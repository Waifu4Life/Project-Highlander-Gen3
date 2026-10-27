-- JOHTO POKéMON HELPER, FireRed / LeafGreen part. Loaded by
-- components/johto/main.lua, which hands over its helpers in D.
return function(D)
  local K = {}
  local on, warn, info, req, now, rand = D.on, D.warn, D.info, D.req, D.now, D.rand
  local session, version, kanto = D.session, D.version, D.kanto
  local sget, sset = D.sget, D.sset
  local say, ask, fanfare, cry, se = D.say, D.ask, D.fanfare, D.cry, D.se
  local objects, gfx, gfxOf, face, hideObject = D.objects, D.gfx, D.gfxOf, D.face, D.hideObject
  local ctx = D.ctx

  local function johto(sp) sp = tonumber(sp) return sp ~= nil and sp >= 152 and sp <= 251 end

  -- ================================================================ GET OTHER GAME EXCLUSIVES
  -- FireRed and LeafGreen share every map and every slot layout; only some
  -- species differ. Each slot of yours that holds a different Pokémon in the
  -- other game (read from that game's installed cache), where either one is a
  -- Johto Pokémon, becomes a "dual" slot: 50% yours, 50% the other game's, at
  -- the other game's levels. The slots are re-rolled every frame and right
  -- before every encounter roll, so the wild battle, Wilds of Hoenn's visible
  -- Pokémon and fishing all get the coin flip.
  -- If the other game isn't installed, a short list of known pairs swaps at
  -- 50% when the battle starts instead.

  local FALLBACK = { { 198, 200 }, { 211, 223 }, { 225, 215 }, { 227, 226 } } -- Murkrow/Misdreavus, Qwilfish/Remoraid, Delibird/Sneasel, Skarmory/Mantine
  local FALLBACK_OTHER = {}
  for _, p in ipairs(FALLBACK) do FALLBACK_OTHER[p[1]], FALLBACK_OTHER[p[2]] = p[2], p[1] end

  local otherData, otherFor = nil, nil
  local function loadOther()
    local v = version()
    if otherFor == v then return otherData end
    otherFor = v
    local o = v == "firered" and "leafgreen" or "firered"
    otherData = D.readOtherLua(o, "encounters.lua")
    info("johto exclusives: %s", otherData and ("using " .. o .. "'s encounter tables") or (o .. " not installed, using the fallback pairs"))
    return otherData
  end

  local duals = setmetatable({}, { __mode = "k" }) -- slot table -> { a, b }
  local dualList = {}
  local exState = nil
  local useFallback = false

  local function restoreDuals()
    for _, d in ipairs(dualList) do
      d.slot.species, d.slot.minLevel, d.slot.maxLevel = d.a.species, d.a.minLevel, d.a.maxLevel
      duals[d.slot] = nil
    end
    dualList = {}
  end

  local function applyExclusives()
    local Enc = req("src.core.game3.encounters")
    local tables = Enc and Enc._tables
    if type(tables) ~= "table" then return end
    local want = kanto() and on("johto_exclusive")
    local state = tostring(tables) .. "|" .. tostring(version()) .. "|" .. tostring(want)
    if state == exState then return end
    exState = state
    restoreDuals()
    useFallback = false
    if not want or not next(tables) then return end
    local other = loadOther()
    if not other then useFallback = true return end
    local mine, theirs = D.tablesByMap(tables), D.tablesByMap(other)
    for k, t in pairs(mine) do
      local ot = theirs[k]
      if ot then
        for _, area in ipairs(D.AREAS) do
          local ms, os = D.slotsOf(t[area]), D.slotsOf(ot[area])
          if ms and os then
            for i, slot in ipairs(ms) do
              local o = os[i]
              local a, b = tonumber(type(slot) == "table" and slot.species), tonumber(type(o) == "table" and o.species)
              if a and b and a ~= b and (johto(a) or johto(b)) and not duals[slot] then
                local d = {
                  slot = slot,
                  a = { species = slot.species, minLevel = slot.minLevel, maxLevel = slot.maxLevel },
                  b = { species = o.species, minLevel = o.minLevel or slot.minLevel, maxLevel = o.maxLevel or slot.maxLevel },
                }
                duals[slot] = d
                dualList[#dualList + 1] = d
              end
            end
          end
        end
      end
    end
    info("johto exclusives: %d slots shared with the other game", #dualList)
  end

  local function flip()
    for _, d in ipairs(dualList) do
      local pick = rand() < 0.5 and d.b or d.a
      d.slot.species, d.slot.minLevel, d.slot.maxLevel = pick.species, pick.minLevel, pick.maxLevel
    end
  end

  function K.refreshTables()
    local ok, err = pcall(applyExclusives)
    if not ok then warn("exclusives", err) end
  end
  function K.dualOf(slot)
    if not (kanto() and on("johto_exclusive")) then return nil end
    return duals[slot]
  end

  local function installEncounters()
    local Enc = require("src.core.game3.encounters")
    local origLoad = Enc.loadFromMod
    Enc.loadFromMod = function(...)
      local r = { origLoad(...) }
      exState = nil
      dualList = {}
      K.refreshTables()
      return (table.unpack or unpack)(r)
    end
    local function before(name)
      local orig = Enc[name]
      if type(orig) ~= "function" then return end
      Enc[name] = function(...)
        if kanto() then
          K.refreshTables()
          pcall(flip)
        end
        return orig(...)
      end
    end
    for _, name in ipairs({ "onStep", "rollFishing", "rollRocks", "rollSweetScent", "rollLand", "rollWater" }) do before(name) end
    local origTableFor = Enc.tableFor
    Enc.tableFor = function(...)
      if kanto() then K.refreshTables() end
      return origTableFor(...)
    end
    Enc.table_for = Enc.tableFor
  end

  -- fallback (other game not installed): swap at the start of the battle
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
  local function installFallbackSwap()
    local BB = require("src.core.game3.battle_bridge")
    local orig = BB.startWild
    BB.startWild = function(mod, game, enc, opts, ...)
      pcall(function()
        if not (kanto() and on("johto_exclusive") and useFallback and type(enc) == "table") then return end
        opts = opts or {}
        if opts.wildScripted or opts.legendary or opts.oldManTutorial or opts.speciesLocked
            or opts.wildsOfHoenn or opts.roamer or enc.roamer then return end
        local sp = encSpecies(enc)
        local other = sp and FALLBACK_OTHER[sp]
        if other and rand() < 0.5 then enc.species, enc.speciesId = other, other end
      end)
      return orig(mod, game, enc, opts, ...)
    end
    local find = ctx.mod and ctx.mod.find
    local woh = type(find) == "function" and find("wilds_of_hoenn") or nil
    local ex = woh and woh.exports
    if ex and type(ex.addSpawnFilter) == "function" then
      ex.addSpawnFilter("project_highlander_gen3_johto", function(e)
        if kanto() and on("johto_exclusive") and useFallback then
          local sp = encSpecies(e)
          local other = sp and FALLBACK_OTHER[sp]
          if other and rand() < 0.5 then e.species, e.speciesId = other, other end
        end
        return e
      end)
    end
  end

  -- ================================================================ GET ALL ROAMING BEASTS / ROAMING HUNTER
  -- The game keeps one roamer (session.roamer). The other two beasts live in
  -- the save (mod.save "jph_roamers") with the same fields, move on every map
  -- change like the first one, and the one you run into is swapped in as the
  -- game's roamer, so the battle and its end work as usual.

  local RAIKOU, ENTEI, SUICUNE = 243, 244, 245
  local BEASTS = { RAIKOU, ENTEI, SUICUNE }
  local CHOICE = { [ENTEI] = 0, [RAIKOU] = 1, [SUICUNE] = 2 } -- Roamer.speciesForStarter
  local origInit, origMove = nil, nil
  local creating = false

  local function extras()
    local e = sget("jph_roamers")
    return type(e) == "table" and e or nil
  end

  local function ensureExtras(sess)
    if creating or not (kanto() and on("johto_beasts")) then return end
    local r = sess and sess.roamer
    if type(r) ~= "table" or not tonumber(r.species) then return end
    local list = extras() or {}
    local have = { [tonumber(r.species)] = true }
    for _, x in ipairs(list) do if type(x) == "table" then have[tonumber(x.species) or 0] = true end end
    local added = 0
    creating = true
    for _, sp in ipairs(BEASTS) do
      if not have[sp] then
        local keep = sess.roamer
        local ok, err = pcall(origInit, sess, CHOICE[sp])
        if ok and type(sess.roamer) == "table" and sess.roamer ~= keep then
          list[#list + 1] = sess.roamer
          have[sp] = true
          added = added + 1
        elseif not ok then
          warn("beasts", err)
        end
        sess.roamer = keep
      end
    end
    creating = false
    if added > 0 then
      sset("jph_roamers", list)
      info("roaming beasts: %d more beast(s) now roam Kanto", added)
    end
  end

  local function swapIn(sess, i)
    local list = extras()
    if not (sess and list and list[i]) then return end
    local cur = sess.roamer
    sess.roamer = list[i]
    list[i] = cur
    sset("jph_roamers", list)
  end

  -- the game only moves its roamer while it's active: keep an active one in front
  local function promote(sess)
    sess = sess or session()
    if not (sess and kanto() and on("johto_beasts")) then return end
    local r = sess.roamer
    if type(r) == "table" and r.active then return end
    for i, x in ipairs(extras() or {}) do
      if type(x) == "table" and x.active then swapIn(sess, i) return end
    end
  end

  local function encounterNow(sess, map)
    local Roamer = req("src.core.game3.roamer")
    local m = Roamer and Roamer.instance(sess)
    local r = sess.roamer
    local MR = req("src.mods.Runtime")
    if m and MR and MR.wants and MR.wants("roamer.encountered") then
      MR.emit("roamer.encountered", { index = 1, slot = r, species = r.species, level = r.level, mapId = map })
    end
    return m
  end

  local function installRoamers()
    local Roamer = require("src.core.game3.roamer")
    local Rng = require("src.core.game3.rng")
    origInit = Roamer.init
    Roamer.init = function(sess, ...)
      local out = { origInit(sess, ...) }
      if not creating then
        local ok, err = pcall(ensureExtras, sess)
        if not ok then warn("beasts", err) end
      end
      return (table.unpack or unpack)(out)
    end

    origMove = Roamer.move
    Roamer.move = function(sess, reason, map, ...)
      local out = { origMove(sess, reason, map, ...) }
      if kanto() and on("johto_beasts") and type(sess) == "table" then
        for _, x in ipairs(extras() or {}) do
          if type(x) == "table" and x.active then
            local keep = sess.roamer
            sess.roamer = x
            local ok, err = pcall(origMove, sess, reason, map)
            sess.roamer = keep
            if not ok then warn("beast move", err) end
          end
        end
      end
      return (table.unpack or unpack)(out)
    end

    local origCont = Roamer.onContinue
    if origCont then
      Roamer.onContinue = function(sess, map, ...)
        local out = { origCont(sess, map, ...) }
        if kanto() and on("johto_beasts") and type(sess) == "table" then
          for _, x in ipairs(extras() or {}) do
            if type(x) == "table" and x.active then
              local keep = sess.roamer
              sess.roamer = x
              pcall(origCont, sess, map)
              sess.roamer = keep
            end
          end
        end
        return (table.unpack or unpack)(out)
      end
    end

    local origTry = Roamer.tryEncounter
    Roamer.tryEncounter = function(sess, map, ...)
      if not kanto() or type(sess) ~= "table" then return origTry(sess, map, ...) end
      local okH, mon = pcall(function()
        local hunter = on("johto_roamer")
        local r = sess.roamer
        if hunter and type(r) == "table" and r.active and r.map == map then return encounterNow(sess, map) end
        if not on("johto_beasts") then return nil end
        local cfg = Roamer.config(sess)
        local odds = cfg and tonumber(cfg.encounterOdds) or 4
        for i, x in ipairs(extras() or {}) do
          if type(x) == "table" and x.active and x.map == map then
            if hunter or (Rng.Random() % odds) == 0 then
              swapIn(sess, i)
              return encounterNow(sess, map)
            end
          end
        end
        return nil
      end)
      if not okH then warn("beast encounter", mon) end
      if okH and mon then return mon end
      return origTry(sess, map, ...)
    end

    -- INFINITE TRIES FOR RARE PKMN (Fill Kanto Regional Dex): a roaming beast
    -- that isn't caught keeps roaming (vanilla FireRed/LeafGreen loses it for
    -- good when it faints)
    local origEnd = Roamer.onBattleEnd
    Roamer.onBattleEnd = function(sess, foeState, result, ...)
      local r = sess and type(sess.roamer) == "table" and sess.roamer or nil
      local wasActive = r and r.active
      local out = { origEnd(sess, foeState, result, ...) }
      local ok, err = pcall(function()
        if not kanto() then return end
        if on("kanto_limited") and wasActive and r and not r.active then
          local Natives = req("src.core.game3.scripting.natives")
          local code = Natives and Natives.outcome_to_code and Natives.outcome_to_code(result)
          if not (code == 7 or D.isCatch(result)) then
            r.active = true
            if (tonumber(r.hp) or 0) <= 0 then
              local Pokemon = req("src.core.game3.pokemon")
              local okS, stats = pcall(Pokemon.calcStats, r.species, r.level, r.ivs, {}, r.personality)
              r.hp = (okS and stats and tonumber(stats.maxHp)) or 1
              r.status = 0
            end
            info("infinite tries: the roaming %s keeps roaming", D.monName(r.species))
          end
        end
        promote(sess)
      end)
      if not ok then warn("beast end", err) end
      return (table.unpack or unpack)(out)
    end
  end

  -- ROAMING HUNTER: a roaming beast never runs from the battle
  local function installNoFlee()
    local Ai = require("src.core.game3.battle.ai")
    local function noRun(st, id, act)
      if not (type(act) == "table" and act.kind == "run" and type(st) == "table" and st.roamer) then return act end
      if not (kanto() and on("johto_roamer")) then return act end
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
    local origMoveAi = Ai.chooseMove
    Ai.chooseMove = function(st, opts, ...)
      local act = origMoveAi(st, opts, ...)
      local ok, out = pcall(noRun, st, type(opts) == "table" and opts.battler or 1, act)
      return ok and out or act
    end
  end

  -- ================================================================ OBTAIN MYSTIC TICKET

  local MYSTIC_ID, AURORA_ID = 370, 371
  local function itemName(id, fallback)
    local ItemsData = req("src.core.game3.items_data")
    local ok, n = pcall(function() return ItemsData.displayName(id) end)
    return (ok and type(n) == "string" and n ~= "") and n:upper() or fallback
  end

  local function beastsInFront()
    local want = { [RAIKOU] = true, [ENTEI] = true, [SUICUNE] = true }
    for i = 1, 3 do
      local sp = D.partySpecies(i)
      if not (sp and want[sp]) then return false end
      want[sp] = nil
    end
    return next(want) == nil
  end

  local function talkMom(eo)
    if not on("johto_mystic") or sget("jph_mystic_done") then return false end
    -- GET ??? (Fill Kanto Regional Dex) goes first
    local KA = ctx.kantoAll
    if KA and KA.momWants then
      local ok, wants = pcall(KA.momWants)
      if ok and wants then return false end
    end
    if not beastsInFront() then return false end
    if D.hasItemId(MYSTIC_ID) then sset("jph_mystic_done", true) return false end
    face(eo)
    local name = itemName(MYSTIC_ID, "MYSTICTICKET")
    say("Honey, there was a letter in the mail for you, there you go.", function()
      if not D.bagAdd(MYSTIC_ID) then say("Your BAG is full...") return end
      sset("jph_mystic_done", true)
      D.setFlag("FLAG_RECEIVED_MYSTIC_TICKET")
      D.setFlag("FLAG_ENABLE_SHIP_NAVEL_ROCK")
      fanfare("MUS_OBTAIN_KEY_ITEM")
      say("Obtained the " .. name .. "!\f" .. D.playerName() .. " put the " .. name
        .. " away in the KEY ITEMS POCKET.")
    end)
    return true
  end

  -- ================================================================ GUARDIAN OF THE FOREST

  local CELEBI, LUGIA, HO_OH = 251, 249, 250
  local CELEBI_LID, AURORA_LID = 0x7B, 0x7C
  -- the five dirt patches on the user's Viridian Forest map (16 px tiles)
  local SPOTS = { { 26, 24 }, { 9, 31 }, { 20, 60 }, { 17, 7 }, { 41, 22 } }
  local celebi = { pos = {}, showAt = nil }

  local function celebiWanted()
    return on("johto_celebi") and not sget("jph_celebi_done") and D.caught(LUGIA) and D.caught(HO_OH)
  end
  local function stage()
    local s = tonumber(sget("jph_celebi_stage")) or 1
    if s < 1 then s = 1 elseif s > #SPOTS then s = #SPOTS end
    return s
  end
  local function spotFor(s)
    if celebi.pos[s] then return celebi.pos[s][1], celebi.pos[s][2] end
    local c = SPOTS[s]
    local x, y = D.nearestFree(c[1], c[2], 0, 4)
    if x then celebi.pos[s] = { x, y } end
    return x, y
  end
  local function celebiGfx() return gfx("CELEBI", 146) end
  local function ballGfx() return gfx("ITEM_BALL", 92) end

  local function celebiGone(eo)
    sset("jph_celebi_done", true)
    sset("jph_celebi_x", eo.cellX)
    sset("jph_celebi_y", eo.cellY)
    hideObject(eo)
  end

  local function talkCelebi(eo)
    local s = stage()
    cry(CELEBI)
    if s < #SPOTS then
      local lines = {
        "The little POKéMON looks at you playfully...\fIt vanished! It seems to want you to follow it!",
        "There it is! CELEBI giggles...\fIt vanished again! Where did it go this time?",
        "CELEBI is having fun!\fIt vanished again!",
        "CELEBI does a little twirl...\fIt vanished again! It's almost done playing!",
      }
      hideObject(eo)
      se("SE_M_TELEPORT")
      sset("jph_celebi_stage", s + 1)
      celebi.showAt = now() + 0.6
      say(lines[s] or lines[#lines])
      return true
    end
    D.wildBattle(CELEBI, 10, function(got)
      if got then
        celebiGone(eo)
      elseif not on("kanto_limited") then
        celebiGone(eo) -- one try only; the ticket is still left behind
      end
    end)
    return true
  end

  local function talkAurora(eo)
    if not D.bagAdd(AURORA_ID) then say("Your BAG is full...") return true end
    sset("jph_aurora_taken", true)
    hideObject(eo)
    D.setFlag("FLAG_RECEIVED_AURORA_TICKET")
    D.setFlag("FLAG_ENABLE_SHIP_BIRTH_ISLAND")
    local name = itemName(AURORA_ID, "AURORATICKET")
    fanfare("MUS_OBTAIN_KEY_ITEM")
    say(D.playerName() .. " found an " .. name .. "!\f" .. D.playerName() .. " put the " .. name
      .. " away in the KEY ITEMS POCKET.")
    return true
  end

  local forestFor = nil
  local function tickForest(map)
    if not map:find("VIRIDIAN_FOREST", 1, true) then forestFor = nil return end
    local O = objects()
    if not (O and D.mapLoaded()) then return end
    if forestFor ~= map then forestFor, celebi.pos, celebi.showAt = map, {}, nil end
    if celebiWanted() then
      local eo = O._byId[CELEBI_LID]
      local x, y = spotFor(stage())
      if not eo then
        if x then D.spawnObject(CELEBI_LID, x, y, celebiGfx(), 8) end
      elseif eo.hidden and celebi.showAt and now() >= celebi.showAt and x then
        celebi.showAt = nil
        D.placeObject(eo, x, y)
      end
    elseif sget("jph_celebi_done") and not sget("jph_aurora_taken") and not O._byId[AURORA_LID] then
      local x, y = tonumber(sget("jph_celebi_x")), tonumber(sget("jph_celebi_y"))
      if x and y then D.spawnObject(AURORA_LID, x, y, ballGfx(), 8) end
    end
  end

  -- ================================================================ dispatch

  function K.talk(eo, map)
    local lid = eo.localId
    if lid == CELEBI_LID and map:find("VIRIDIAN_FOREST", 1, true) and celebiWanted() then return talkCelebi(eo) end
    if lid == AURORA_LID and map:find("VIRIDIAN_FOREST", 1, true) then return talkAurora(eo) end
    if map:find("PLAYERS_HOUSE_1F", 1, true) and gfxOf(eo) == gfx("MOM", 88) then return talkMom(eo) end
    return false
  end

  function K.frame()
    if #dualList > 0 then flip() end
  end

  local beastsAt = 0
  function K.tick(map)
    K.refreshTables()
    local t = now()
    if t >= beastsAt then
      beastsAt = t + 1
      local sess = session()
      if sess then
        pcall(ensureExtras, sess)
        pcall(promote, sess)
      end
    end
    tickForest(map)
  end

  K.installers = {
    { "johto encounters", installEncounters },
    { "johto fallback swap", installFallbackSwap },
    { "johto roamers", installRoamers },
    { "johto no flee", installNoFlee },
  }

  return K
end
