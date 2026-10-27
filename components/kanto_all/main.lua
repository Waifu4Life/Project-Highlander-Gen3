-- FILL KANTO REGIONAL DEX (FireRed / LeafGreen only). Same rules as Project
-- Highlander's Gen1 Get All The Pokémon, for the Kanto Regional Dex, minus
-- Mr. Fuji's extra Eevee and the Karate Master's other fighter (breeding
-- covers those after the game). Every option is On by default.
--
--   GET ALL STARTERS        8 badges: Oak offers the last Poké Ball on his
--                           table. Champion, with MEWTWO first in the party:
--                           Oak gives a baby of your rival's starter.
--   GET OTHER FOSSIL        8 badges: Miguel (Mt. Moon B2F) trades the fossil
--                           you didn't pick for your S.S. TICKET.
--   GET OTHER GAME EXCLUSIVES  every wild Pokémon that's exclusive to one of
--                           the two games has a 50% chance to be the other
--                           game's counterpart (grass, water, fishing, rocks,
--                           Safari Zone). Electabuzz and Magmar, the one pair
--                           the games put in different places, get their own
--                           slots in both games instead (Power Plant Lv32/35,
--                           Mt. Ember Lv38/40). With Wilds of Hoenn 1.10.4+, the
--                           swap happens when a visible Pokémon appears, so
--                           you see the one you fight.
--   INFINITE TRIES FOR RARE PKMN  Articuno, Zapdos, Moltres, Mewtwo and both
--                           Snorlax stay where they are when a battle ends
--                           without catching them (beaten, ran, whited out),
--                           like Gen 1. Only a catch makes them go away.
--   TRADE WITH LINK C.      the GBA kid in the Celadon Department Store
--                           trade-evolves your KADABRA, HAUNTER, GRAVELER and
--                           MACHOKE (once each) and gives them back.
--   GET ???                 Champion and all 150 other Kanto Pokémon caught:
--                           Mom has seen a strange little Pokémon in the
--                           house...
--
-- Progress is kept in the save file (mod.save).
return function(ctx)
  local S = ctx.settings
  local K = { installed = false }

  local function on(key) return S.get(key) == true end
  local function warn(what, err)
    if ctx.mod.log then ctx.mod.log:warn("kanto all %s: %s", what, tostring(err)) end
  end
  local function req(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
  end

  local function session()
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.getSession then
      local ok, s = pcall(Runtime.getSession)
      if ok and type(s) == "table" then return s end
    end
  end

  local function kanto(sess)
    local v = S.version(sess or session())
    return v == "firered" or v == "leafgreen"
  end

  -- per save
  local function sget(key)
    local ok, v = pcall(function() return ctx.mod.save:get(key) end)
    return ok and v or nil
  end
  local function sset(key, v)
    pcall(function() ctx.mod.save:set(key, v) end)
  end

  -- ------------------------------------------------------------- game state

  local SP = {
    BULBASAUR = 1, CHARMANDER = 4, SQUIRTLE = 7,
    KADABRA = 64, ALAKAZAM = 65, MACHOKE = 67, MACHAMP = 68,
    GRAVELER = 75, GOLEM = 76, HAUNTER = 93, GENGAR = 94,
    ARTICUNO = 144, ZAPDOS = 145, MOLTRES = 146, SNORLAX = 143,
    ELECTABUZZ = 125, MAGMAR = 126,
    MEWTWO = 150, MEW = 151,
  }

  local GFX = { ITEM_BALL = 92, PROF_OAK = 71, MOM = 88, GBA_KID = 51, FOSSIL = 98, MEW = 140,
    ROCKET_M = 49, ROCKET_F = 50 }

  local function store()
    local Space = req("src.core.game3.scripting.space")
    return Space and Space.store
  end

  local function flagId(name)
    local Flags = req("src.core.game3.scripting.flags")
    return Flags and Flags.IDS and Flags.IDS[name]
  end

  local function flag(name)
    local Flags = req("src.core.game3.scripting.flags")
    local id = flagId(name)
    local st = store()
    if not (Flags and id and st) then return false end
    local ok, v = pcall(Flags.getFlag, st, nil, id)
    return ok and v == true
  end

  local function clearFlag(name)
    local Flags = req("src.core.game3.scripting.flags")
    local id = flagId(name)
    local st = store()
    if Flags and id and st then pcall(Flags.setFlag, st, nil, id, false) end
    local sess = session()
    if sess and type(sess.flags) == "table" and id then
      sess.flags[id], sess.flags[tostring(id)], sess.flags[name] = nil, nil, nil
    end
  end

  local function setFlag(name)
    local Flags = req("src.core.game3.scripting.flags")
    local id = flagId(name)
    local st = store()
    if Flags and id and st then pcall(Flags.setFlag, st, nil, id, true) end
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

  -- VAR_STARTER_MON: 0 Bulbasaur, 1 Squirtle, 2 Charmander
  local STARTER = {
    [0] = { mine = SP.BULBASAUR, rival = SP.CHARMANDER, left = SP.SQUIRTLE, x = 9 },
    [1] = { mine = SP.SQUIRTLE, rival = SP.BULBASAUR, left = SP.CHARMANDER, x = 10 },
    [2] = { mine = SP.CHARMANDER, rival = SP.SQUIRTLE, left = SP.BULBASAUR, x = 8 },
  }
  local function starterInfo() return STARTER[var(0x4031)] or STARTER[0] end

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

  local function monName(species)
    local Pokemon = req("src.core.game3.pokemon")
    local ok, n = pcall(Pokemon.name, species)
    return (ok and n) and tostring(n):upper() or "POKéMON"
  end

  local function playerName()
    local sess = session() or {}
    local n = sess.name or sess.playerName
    return (type(n) == "string" and n ~= "") and n or "RED"
  end

  local function rivalName()
    local sess = session() or {}
    local n = sess.rivalName
    return (type(n) == "string" and n ~= "") and n or "BLUE"
  end

  -- ------------------------------------------------------------- items

  local function norm(s)
    s = tostring(s or ""):gsub("é", "E"):gsub("É", "E"):upper()
    return (s:gsub("[^%w]", ""))
  end

  local itemCache = {}
  local function itemId(name)
    local key = norm(name)
    if itemCache[key] ~= nil then return itemCache[key] or nil end
    local ItemsData = req("src.core.game3.items_data")
    local found = false
    if ItemsData and ItemsData.info then
      for n = 1, 380 do
        local ok, info = pcall(ItemsData.info, n)
        if ok and info and norm(info.name) == key then found = n break end
      end
    end
    itemCache[key] = found
    return found or nil
  end

  local function hasItem(name)
    local sess, Bag, id = session(), req("src.core.game3.bag"), itemId(name)
    if not (sess and sess.bag and Bag and id) then return false end
    local ok, v = pcall(Bag.has, sess.bag, id, 1)
    return ok and v == true
  end

  local function bagDo(fn, name)
    local sess, Bag, id = session(), req("src.core.game3.bag"), itemId(name)
    if not (sess and sess.bag and Bag and id) then return false end
    local ok, v = pcall(Bag[fn], sess.bag, id, 1)
    return ok and v ~= false
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

  -- give a level-5 (or given level) Pokémon; returns "party", "pc" or "fail"
  local function giveMon(species, level)
    local sess = session()
    local Party = req("src.core.game3.party")
    if not (sess and Party and Party.giveMonToPlayer) then return "fail" end
    local ok, code = pcall(Party.giveMonToPlayer, sess, species, level or 5)
    code = ok and tonumber(code) or nil
    if code == (Party.MON_GIVEN_TO_PARTY or 0) then return "party" end
    if code == (Party.MON_GIVEN_TO_PC or 1) then return "pc" end
    return "fail"
  end

  local function receivedLine(species, where)
    if where == "fail" then return "There's no room for it..." end
    local line = playerName() .. " received " .. monName(species) .. "!"
    if where == "pc" then line = line .. "\f" .. monName(species) .. " was sent to the PC." end
    return line
  end

  local function giveAndSay(species, level, after)
    local where = giveMon(species, level)
    if where ~= "fail" then fanfare("MUS_OBTAIN_ITEM") end
    say(receivedLine(species, where), after)
    return where
  end

  -- ------------------------------------------------------------- objects

  local function objects()
    return req("src.core.game3.objects")
  end

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

  -- ------------------------------------------------------------- GET ALL STARTERS

  local function talkOak(eo)
    if not on("kanto_starters") then return false end
    local info = starterInfo()
    local rival = rivalName()
    local party = (session() or {}).party or {}
    if champion() and sget("kgk_ball_taken") and not sget("kgk_baby")
        and speciesOf(party[1]) == SP.MEWTWO and not isEgg(party[1]) then
      local FINAL = { [SP.BULBASAUR] = "VENUSAUR", [SP.CHARMANDER] = "CHARIZARD", [SP.SQUIRTLE] = "BLASTOISE" }
      face(eo)
      say("Incredible, that's the legendary POKéMON MEWTWO!\fThank you so much for showing it to me, "
        .. "this will help my research beyond what you can imagine.\fHere, it's not much, but " .. rival
        .. " went to JOHTO to see their POKéMON ecosystem and brought me back a little something.\fHe had his "
        .. (FINAL[info.rival] or monName(info.rival)) .. " bred at a daycare over there and got a baby "
        .. monName(info.rival) .. ".\fI want you to have it, it should help you finish your POKéDEX.", function()
          if giveAndSay(info.rival, 5) ~= "fail" then sset("kgk_baby", true) end
        end)
      return true
    end
    if allBadges() and not sget("kgk_oak_offered") then
      sset("kgk_oak_offered", true)
      face(eo)
      say("What a great accomplishment!\fDo you know why you were able to reach this point in your journey?\f"
        .. "Well it's because you took great care of your POKéMON by loving them and raising them carefully.\f"
        .. "Tell you what, why don't you go ahead and raise that last POKéMON that's on my table over there.\f"
        .. "I'm sure it will be happy to be with you as well.")
      return true
    end
    if sget("kgk_oak_offered") and not sget("kgk_ball_taken") then
      face(eo)
      -- the ball isn't on the table any more: Oak hands it over himself
      local O = objects()
      local ballThere = false
      for _, lid in ipairs((O and O._order) or {}) do
        local b = O._byId[lid]
        if b and b.visible and not b.hidden and gfxOf(b) == GFX.ITEM_BALL then ballThere = true end
      end
      if not ballThere then
        say("Here, take it. I won't tell " .. rival .. ".", function()
          if giveAndSay(info.left, 5) ~= "fail" then sset("kgk_ball_taken", true) end
        end)
        return true
      end
      say("Go on, don't be shy, take it.\fI won't tell " .. rival .. ".")
      return true
    end
    return false
  end

  local function talkBall(eo)
    if not on("kanto_starters") then return false end
    if not sget("kgk_oak_offered") or sget("kgk_ball_taken") then return false end
    local info = starterInfo()
    local O = objects()
    local x = tonumber(eo.cellX or (eo.def and eo.def.x))
    local count = 0
    for _, lid in ipairs((O and O._order) or {}) do
      local b = O._byId[lid]
      if b and b.visible and not b.hidden and gfxOf(b) == GFX.ITEM_BALL then count = count + 1 end
    end
    if x ~= info.x and count > 1 then return false end
    if giveMon(info.left, 5) == "fail" then
      say("There's no room for it...")
      return true
    end
    sset("kgk_ball_taken", true)
    hideObject(eo)
    fanfare("MUS_OBTAIN_ITEM")
    say(receivedLine(info.left, "party"))
    return true
  end

  -- ------------------------------------------------------------- GET OTHER FOSSIL

  -- Super Nerd Miguel (TRAINER_SUPER_NERD_MIGUEL = 170): his object's script
  -- (or a script it jumps to) starts his trainer battle.
  local MIGUEL = 170
  local function scriptHasTrainer(key, want, depth, seen)
    local Space = req("src.core.game3.scripting.space")
    local scripts = Space and Space.vm and Space.vm.scripts
    local list = scripts and key and scripts[key]
    if type(list) ~= "table" or seen[key] then return false end
    seen[key] = true
    for _, row in ipairs(list) do
      if type(row) == "table" then
        if (row.op == "trainerbattle" or row.op == "dotrainerbattle")
            and tonumber(row.trainer or row[1]) == want then
          return true
        end
        if depth > 0 then
          for _, v in pairs(row) do
            if type(v) == "string" and scripts[v] and scriptHasTrainer(v, want, depth - 1, seen) then
              return true
            end
          end
        end
      end
    end
    return false
  end

  local function isMiguel(eo)
    local key = eo.def and eo.def.scriptKey
    if key and scriptHasTrainer(key, MIGUEL, 3, {}) then return true end
    -- backup: the person standing right next to the two fossils
    local g = gfxOf(eo)
    if g == GFX.FOSSIL or g == GFX.ITEM_BALL or g == GFX.ROCKET_M or g == GFX.ROCKET_F then return false end
    local O = objects()
    local ex, ey = tonumber(eo.cellX), tonumber(eo.cellY)
    if not (ex and ey) then return false end
    for _, def in ipairs((O and O._defs) or {}) do
      if tonumber(def.graphicsId or def.graphics) == GFX.FOSSIL then
        local dx, dy = math.abs((tonumber(def.x) or -99) - ex), math.abs((tonumber(def.y) or -99) - ey)
        if dx + dy <= 2 then return true end
      end
    end
    return false
  end

  local function talkMiguel(eo)
    if not on("kanto_fossil") or not allBadges() or sget("kgk_fossil_traded") then return false end
    if not flag("FLAG_GOT_FOSSIL_FROM_MT_MOON") then return false end
    local fossil
    if flag("FLAG_GOT_DOME_FOSSIL") or hasItem("DOME FOSSIL") then fossil = "HELIX FOSSIL"
    elseif flag("FLAG_GOT_HELIX_FOSSIL") or hasItem("HELIX FOSSIL") then fossil = "DOME FOSSIL" end
    if not fossil then return false end
    face(eo)
    if not hasItem("S.S. TICKET") then
      say("Oh, it's you again, go away.\fI'm not giving you my fossil OK, we had a deal!")
      return true
    end
    local prompt = sget("kgk_fossil_asked") and "Have you reconsidered?"
      or ("Oh, it's you again... wait, what's that half-way in your bag?\fIs that an S.S. ANNE TICKET?!\f"
        .. "Please, please, I need it to go to the SINNOH region.\fWill you trade my fossil for it?")
    sset("kgk_fossil_asked", true)
    ask(prompt, function(yes)
      if not yes then say("Oh com'on, please reconsider.") return end
      if not bagDo("add", fossil) then say("Your BAG is full...") return end
      bagDo("remove", "S.S. TICKET")
      sset("kgk_fossil_traded", true)
      -- the Cinnabar Lab scientist only revives fossils whose "got" flag is set
      setFlag(fossil == "DOME FOSSIL" and "FLAG_GOT_DOME_FOSSIL" or "FLAG_GOT_HELIX_FOSSIL")
      fanfare("MUS_OBTAIN_KEY_ITEM")
      say("Thank you sooooo much.\nHere's the fossil as promised!\f" .. playerName() .. " received the " .. fossil .. "!")
    end)
    return true
  end

  -- ------------------------------------------------------------- TRADE WITH LINK C.

  local TRADE = {
    { from = SP.KADABRA, key = "kgk_linkc_kadabra" },
    { from = SP.HAUNTER, key = "kgk_linkc_haunter" },
    { from = SP.GRAVELER, key = "kgk_linkc_graveler" },
    { from = SP.MACHOKE, key = "kgk_linkc_machoke" },
  }

  -- the Game Boy (GBA) kid that's on his own in the Celadon Department Store
  local function isLinkC(eo)
    if gfxOf(eo) ~= GFX.GBA_KID then return false end
    local map = mapId()
    if not (map:find("CELADON") and map:find("DEPARTMENT")) then return false end
    local O = objects()
    local ex, ey = tonumber(eo.cellX) or 0, tonumber(eo.cellY) or 0
    for _, lid in ipairs((O and O._order) or {}) do
      local k = O._byId[lid]
      if k and k ~= eo and k.visible and not k.hidden and gfxOf(k) == GFX.GBA_KID then
        local d = math.abs((tonumber(k.cellX) or 0) - ex) + math.abs((tonumber(k.cellY) or 0) - ey)
        if d <= 3 then return false end -- one of the pair playing together
      end
    end
    return true
  end

  local LOCK = "ph3_link_c"

  -- frame-by-frame steps (fade, trade scene, evolution), like the game's own
  -- in-game trade task
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
        if not ok then warn("link c", err) i, started = i + 1, false end
        return false
      end
      frames = frames + 1
      local ok, done = pcall(st.wait, frames)
      if not ok then warn("link c", done) done = true end
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

  -- Link C.'s own Pokémon of the same kind (only shown in the trade scenes)
  local function linkCopy(mon)
    local copy = {}
    for k, v in pairs(mon) do copy[k] = v end
    copy.nickname = ""
    copy.ot, copy.otName = "LINK C.", "LINK C."
    copy.otId = 31415
    copy.heldItem, copy.item = 0, 0
    return copy
  end

  local function tradeEvolve(slot)
    local sess = session()
    local mon = sess and sess.party and sess.party[slot]
    local sp = speciesOf(mon)
    local row
    for _, t in ipairs(TRADE) do if t.from == sp and not sget(t.key) then row = t end end
    if not row or isEgg(mon) then
      say("I only trade KADABRA, HAUNTER, GRAVELER or MACHOKE.")
      return
    end
    local Evolution = req("src.core.game3.evolution")
    local target = Evolution and Evolution.tradeTarget and Evolution.tradeTarget(mon, sess)
    local his = linkCopy(mon)
    say("Okay, connect the cable like so!", function()
      -- your Pokémon goes to Link C. and evolves there...
      runSteps({ fadeStep(true), tradeStep(mon, his), evolveStep(mon, target, sess) }, function()
        say("OK, now let's trade back.", function()
          -- ...then comes back to you, evolved
          runSteps({ fadeStep(true), tradeStep(his, mon) }, function()
            sset(row.key, true)
            say("Thank you friend.")
          end)
        end)
      end)
    end)
  end

  local function talkLinkC(eo)
    if not on("kanto_linkc") then return false end
    face(eo)
    local left = 0
    for _, t in ipairs(TRADE) do if not sget(t.key) then left = left + 1 end end
    if left == 0 then say("Thank you friend.") return true end
    ask("My name is Link C. and I have these POKéMON that I really love, but they can only evolve via trading.\f"
      .. "Now I don't want to give them after they evolve, I want them back, hence why I'll only trade for the "
      .. "same kind of POKéMON, that way, I know I'll get them back.\fWhat do you say, want to trade?", function(yes)
        if not yes then say("OK, some other time then.") return end
        local PartyMenu = req("src.ui.game3.party_menu")
        local sess = session()
        if not (PartyMenu and sess and sess.party and sess.party[1]) then return end
        -- the menu closes before it reports the pick, so a cancel is only
        -- known one frame later
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
    return true
  end

  -- ------------------------------------------------------------- GET ???

  local MEW_LID = 0x70
  local function mewEligible()
    if not on("kanto_mystery") or sget("kgk_mew_caught") then return false end
    if not champion() then return false end
    local sess = session()
    local Dex = req("src.core.game3.dex")
    if not (sess and sess.dex and Dex) then return false end
    local okS, seen = pcall(Dex.isSeen, sess.dex, SP.MEW)
    if okS and seen and not sget("kgk_mew_hint") then return false end
    for sp = 1, 150 do
      local ok, c = pcall(Dex.isCaught, sess.dex, sp)
      if not (ok and c) then return false end
    end
    return true
  end

  -- JOHTO POKéMON HELPER's Mystic Ticket waits until GET ??? is done with Mom
  function K.momWants()
    return not sget("kgk_mew_outside") and mewEligible()
  end

  local function talkMom(eo)
    if sget("kgk_mew_outside") or not mewEligible() then return false end
    face(eo)
    sset("kgk_mew_hint", true)
    say("I saw a strange little floating POKéMON snooping in and around our house.\f"
      .. "Why don't you see if you can find it?")
    return true
  end

  local function mewBattle(eo)
    local Runtime = req("src.core.game3.runtime")
    local BB = req("src.core.game3.battle_bridge")
    if not (Runtime and BB) then return end
    local ok, err = pcall(BB.startWild, Runtime._mod, Runtime._game, { species = SP.MEW, level = 50 }, {
      legendary = true,
      done = function(result)
        if result == "caught" then
          sset("kgk_mew_caught", true)
          hideObject(eo)
        end
      end,
    })
    if not ok then warn("mew battle", err) end
  end

  local function mewTeleports(eo)
    sset("kgk_mew_outside", true)
    hideObject(eo)
    say("The little POKéMON notices you!\fIt teleported outside!")
  end

  -- free floor tile: walkable, nothing on it, not a warp
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

  local function spawnMew(x, y)
    local O = objects()
    if not O or O._byId[MEW_LID] then return end
    local defs = {}
    for i, d in ipairs(O._defs or {}) do defs[i] = d end
    defs[#defs + 1] = { localId = MEW_LID, index = MEW_LID, x = x, y = y, graphicsId = GFX.MEW,
      movementType = 8, elevation = 3, flag = 0, trainerType = 0 }
    O._defs = defs
    local ok, err = pcall(O.addObject, MEW_LID)
    if not ok then warn("spawn mew", err) end
  end

  local function placeMew()
    local map = mapId()
    local O = objects()
    if not O or O._byId[MEW_LID] then return end
    -- only once the new map's objects are loaded
    if tostring(O._mapId or ""):upper() ~= map then return end
    local Map = req("src.core.game3.map")
    local def = Map and Map.currentDef and Map.currentDef()
    if not def then return end
    if map:find("PLAYERS_HOUSE_2F") and sget("kgk_mew_hint") and not sget("kgk_mew_outside") then
      local w, h = tonumber(def.width) or 10, tonumber(def.height) or 8
      local x, y = nearestFree(math.floor(w / 2), math.floor(h / 2), 0, 6)
      if x then spawnMew(x, y) end
    elseif map:match("PALLET_TOWN$") and sget("kgk_mew_outside") then
      -- a free tile in front of the player's house door
      local dx, dy
      for _, wp in ipairs(def.warps or {}) do
        for _, v in pairs(wp) do
          if type(v) == "string" and v:upper():find("PLAYERS_HOUSE_1F") then dx, dy = tonumber(wp.x), tonumber(wp.y) end
        end
      end
      if not dx then dx, dy = math.floor((tonumber(def.width) or 20) / 2), math.floor((tonumber(def.height) or 20) / 2) end
      local x, y = nearestFree(dx, dy + 2, 0, 4)
      if x then spawnMew(x, y) end
    end
  end

  local spawnedFor = nil
  local function tickMew()
    if not kanto() then return end
    if not (on("kanto_mystery") or sget("kgk_mew_hint")) or sget("kgk_mew_caught") then return end
    local O = objects()
    if not O then return end
    local map = mapId()
    if spawnedFor ~= map then
      spawnedFor = map
      pcall(placeMew)
    elseif not O._byId[MEW_LID] then
      pcall(placeMew)
    end
    -- indoors: walking up next to it makes it teleport outside
    local eo = O._byId[MEW_LID]
    if eo and eo.visible and not eo.hidden and map:find("PLAYERS_HOUSE_2F") then
      local P = req("src.core.game3.player")
      local Message = req("src.ui.game3.message")
      if P and not P.moving and not (Message and Message.open) then
        local d = math.abs((P.cellX or 0) - (eo.cellX or 0)) + math.abs((P.cellY or 0) - (eo.cellY or 0))
        if d <= 1 then mewTeleports(eo) end
      end
    end
  end

  -- ------------------------------------------------------------- talk dispatch

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
    if not kanto() then return false end
    local P = req("src.core.game3.player")
    local O = objects()
    if not (P and O) then return false end
    local d = DELTA[P.facing or "down"] or DELTA.down
    local eo = O.at(P.cellX + d[1], P.cellY + d[2])
    if not eo then return false end
    local map, g = mapId(), gfxOf(eo)
    if eo.localId == MEW_LID then
      if map:find("PLAYERS_HOUSE_2F") then mewTeleports(eo) else mewBattle(eo) end
      return true
    end
    if map:find("OAKS_LAB") then
      if g == GFX.PROF_OAK then return talkOak(eo) end
      if g == GFX.ITEM_BALL then return talkBall(eo) end
    elseif map:find("MT_MOON") and map:find("B2F") then
      if isMiguel(eo) then return talkMiguel(eo) end
    elseif map:find("PLAYERS_HOUSE_1F") then
      if g == GFX.MOM then return talkMom(eo) end
    elseif g == GFX.GBA_KID and isLinkC(eo) then
      return talkLinkC(eo)
    end
    return false
  end

  -- ------------------------------------------------------------- exclusives + limited encounters

  local PAIRS = {
    { 23, 27 }, { 24, 28 }, -- Ekans / Sandshrew, Arbok / Sandslash
    { 43, 69 }, { 44, 70 }, { 45, 71 }, -- Oddish / Bellsprout lines
    { 54, 79 }, { 55, 80 }, -- Psyduck / Slowpoke, Golduck / Slowbro
    { 58, 37 }, { 59, 38 }, -- Growlithe / Vulpix, Arcanine / Ninetales
    { 90, 120 }, { 91, 121 }, -- Shellder / Staryu, Cloyster / Starmie
    { 123, 127 }, -- Scyther / Pinsir
    { 125, 126 }, -- Electabuzz / Magmar
  }
  local OTHER = {}
  for _, p in ipairs(PAIRS) do OTHER[p[1]], OTHER[p[2]] = p[2], p[1] end

  -- ------------------------------------------------------------- Electabuzz / Magmar spots
  -- Electabuzz and Magmar are the only exclusive pair FireRed and LeafGreen put
  -- in different places, so the 50% swap alone would only give LeafGreen an
  -- Electabuzz on Mt. Ember and FireRed a Magmar in the Power Plant. With GET
  -- OTHER GAME EXCLUSIVES on, each game also gets the other game's slots, so
  -- both have Electabuzz in the Power Plant and Magmar on Mt. Ember, and the
  -- pair is left out of the 50% swap.
  -- Slots copied from the other game's ROM table (gWildMonHeaders), 1-based.
  -- Each slot is only changed when it still holds the species we expect.
  local WOH_FIX = {
    leafgreen = { -- MAP_POWER_PLANT (1:95): FireRed's Electabuzz slots
      { group = 1, num = 95, area = "land", slots = {
        [10] = { from = 82, to = 125, min = 32, max = 32 },
        [12] = { from = 82, to = 125, min = 35, max = 35 },
      } },
    },
    firered = { -- MAP_MT_EMBER_EXTERIOR (1:97): LeafGreen's Magmar slots
      { group = 1, num = 97, area = "land", slots = {
        [9] = { from = 21, to = 126, min = 38, max = 38 },
        [11] = { from = 21, to = 126, min = 40, max = 40 },
      } },
    },
  }
  local fixOriginal = setmetatable({}, { __mode = "k" }) -- slot table -> its ROM values
  local fixState = nil

  local function applyWohFix()
    local Enc = req("src.core.game3.encounters")
    local tables = Enc and Enc._tables
    if type(tables) ~= "table" then return end
    local version = S.version(session())
    local want = on("kanto_exclusive") and WOH_FIX[version] or nil
    local state = tostring(tables) .. "|" .. tostring(version) .. "|" .. tostring(want ~= nil)
    if state == fixState then return end
    fixState = state
    -- put back anything changed before (toggle turned off, or another game)
    for slot, o in pairs(fixOriginal) do
      slot.species, slot.minLevel, slot.maxLevel = o.species, o.minLevel, o.maxLevel
      fixOriginal[slot] = nil
    end
    if not want then return end
    local changed = 0
    for _, t in pairs(tables) do
      if type(t) == "table" then
        for _, fix in ipairs(want) do
          if tonumber(t.mapGroup) == fix.group and tonumber(t.mapNum) == fix.num then
            local area = type(t[fix.area]) == "table" and t[fix.area]
            local slots = area and area.slots
            if type(slots) == "table" then
              for i, f in pairs(fix.slots) do
                local slot = slots[i]
                if type(slot) == "table" and tonumber(slot.species) == f.from and not fixOriginal[slot] then
                  fixOriginal[slot] = { species = slot.species, minLevel = slot.minLevel, maxLevel = slot.maxLevel }
                  slot.species, slot.minLevel, slot.maxLevel = f.to, f.min, f.max
                  changed = changed + 1
                end
              end
            end
          end
        end
      end
    end
    if ctx.mod.log then ctx.mod.log:info("electabuzz/magmar spots: %d slots set for %s", changed, tostring(version)) end
  end

  local function installWohFix()
    local Enc = require("src.core.game3.encounters")
    local origLoad = Enc.loadFromMod
    Enc.loadFromMod = function(...)
      local r = { origLoad(...) }
      fixState = nil -- fresh tables: apply again
      local ok, err = pcall(applyWohFix)
      if not ok then warn("woh fix", err) end
      return (table.unpack or unpack)(r)
    end
    local origTableFor = Enc.tableFor
    Enc.tableFor = function(...)
      local ok, err = pcall(applyWohFix)
      if not ok then warn("woh fix", err) end
      return origTableFor(...)
    end
    Enc.table_for = Enc.tableFor
    pcall(applyWohFix)
  end

  -- flags to clear (after the game's own script) when the battle isn't a catch
  local LIMITED = {
    [SP.ARTICUNO] = function() return { "FLAG_FOUGHT_ARTICUNO", "FLAG_HIDE_ARTICUNO" } end,
    [SP.ZAPDOS] = function() return { "FLAG_FOUGHT_ZAPDOS", "FLAG_HIDE_ZAPDOS" } end,
    [SP.MOLTRES] = function() return { "FLAG_FOUGHT_MOLTRES", "FLAG_HIDE_MOLTRES" } end,
    [SP.MEWTWO] = function() return { "FLAG_FOUGHT_MEWTWO", "FLAG_HIDE_MEWTWO" } end,
    -- Navel Rock / Birth Island (JOHTO POKéMON HELPER's tickets)
    [249] = function() return { "FLAG_FOUGHT_LUGIA", "FLAG_HIDE_LUGIA", "FLAG_LUGIA_FLEW_AWAY" } end,
    [250] = function() return { "FLAG_FOUGHT_HO_OH", "FLAG_HIDE_HO_OH", "FLAG_HO_OH_FLEW_AWAY" } end,
    [410] = function() return { "FLAG_FOUGHT_DEOXYS", "FLAG_HIDE_DEOXYS", "FLAG_DEOXYS_FLEW_AWAY" } end,
    [SP.SNORLAX] = function()
      local map = mapId()
      if map:find("ROUTE_12") then return { "FLAG_HIDE_ROUTE_12_SNORLAX", "FLAG_WOKE_UP_ROUTE_12_SNORLAX" } end
      if map:find("ROUTE_16") then return { "FLAG_HIDE_ROUTE_16_SNORLAX", "FLAG_WOKE_UP_ROUTE_16_SNORLAX" } end
      return {}
    end,
  }

  -- After a battle that isn't a catch, the game's own script carries on with
  -- "setflag FLAG_FOUGHT_x" and "removeobject" (and for a run, "x flew away!").
  -- While that script finishes, `stay` skips those two commands so the
  -- Pokémon never leaves its spot, and the line says it's still there. The
  -- flags are cleared again afterwards in case anything else set them.
  local pendingClear, stay = nil, nil

  local function now()
    return (love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
  end

  local function tickLimited()
    if not pendingClear then return end
    local Space = req("src.core.game3.scripting.space")
    if Space and Space.vm and Space.vm.isRunning and Space.vm:isRunning() then return end
    local Field = req("src.core.game3.field")
    if Field and Field.locked then return end
    if stay and now() - stay.since < 0.5 then return end
    local list = pendingClear
    pendingClear, stay = nil, nil
    for _, name in ipairs(list) do clearFlag(name) end
  end

  local function isCatch(result)
    if result == 7 then return true end -- B_OUTCOME_CAUGHT
    local r = tostring(result or ""):lower()
    return r == "caught" or r == "catch"
  end

  local function installStay()
    local Ops = require("src.core.game3.scripting.ops_a")
    local origDispatch = Ops.dispatch
    Ops.dispatch = function(vm, row, ...)
      if stay and type(row) == "table" then
        if row.op == "removeobject" then
          if ctx.mod.log then ctx.mod.log:info("infinite tries: kept %s on the map", tostring(stay.name)) end
          return false
        end
        if row.op == "setflag" then
          local id = tonumber(row.flag or row[1])
          if id and stay.ids[id] then return false end
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
        if low:find("flew away") or low:find("returned to the mountains") then
          r[1] = tostring(stay.name) .. " is still here!"
        end
      end
      return (table.unpack or unpack)(r)
    end
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

  local function installBattles()
    local BB = require("src.core.game3.battle_bridge")
    local orig = BB.startWild
    BB.startWild = function(mod, game, enc, opts, ...)
      local okK = pcall(function()
        if not kanto() or type(enc) ~= "table" then return end
        local sp = encSpecies(enc)
        opts = opts or {}
        local scripted = opts.wildScripted or opts.legendary or opts.oldManTutorial
        -- a visible Wilds of Hoenn Pokémon: its spawn filter already decided the species
        local locked = opts.speciesLocked or opts.wildsOfHoenn
        -- Electabuzz and Magmar have their own slots in both games (WOH_FIX above)
        local placed = sp == SP.ELECTABUZZ or sp == SP.MAGMAR
        if on("kanto_exclusive") and not scripted and not locked and sp and OTHER[sp] and not placed then
          local roll = (love and love.math and love.math.random) and love.math.random() or math.random()
          if roll < 0.5 then
            enc.species, enc.speciesId = OTHER[sp], OTHER[sp]
          end
        end
        if on("kanto_limited") and sp and LIMITED[sp] then
          local list = LIMITED[sp]()
          local done = opts.done
          opts.done = function(result, ...)
            if not isCatch(result) and #list > 0 then
              local ids = {}
              for _, name in ipairs(list) do
                local id = flagId(name)
                if id then ids[id] = true end
              end
              local Pokemon = req("src.core.game3.pokemon")
              local okN, name = pcall(function() return Pokemon.name(sp) end)
              stay = { ids = ids, since = now(), name = okN and name or "It" }
              pendingClear = list
              if ctx.mod.log then
                ctx.mod.log:info("infinite tries: %s not caught (%s), it stays", tostring(stay.name), tostring(result))
              end
            end
            if done then return done(result, ...) end
          end
        end
      end)
      if not okK then warn("battle", "options skipped") end
      return orig(mod, game, enc, opts, ...)
    end
  end

  -- ------------------------------------------------------------- Pokédex LOCATION tab
  -- The species a wild slot of `sp` can turn into (and the other way round)
  -- with GET OTHER GAME EXCLUSIVES, using the same rules as the battle-time
  -- swap above; nil when nothing swaps.
  function K.swapFor(sp)
    sp = tonumber(sp)
    local other = sp and OTHER[sp]
    if not other or not on("kanto_exclusive") or not kanto() then return nil end
    if sp == SP.ELECTABUZZ or sp == SP.MAGMAR then return nil end -- own slots in both games
    return other
  end

  -- make sure the Electabuzz / Magmar slots are in the tables before reading them
  function K.refreshTables()
    local ok, err = pcall(applyWohFix)
    if not ok then warn("spots", err) end
  end

  -- ------------------------------------------------------------- Wilds of Hoenn spawn filter
  -- Wilds of Hoenn 1.10.4+ rolls its visible Pokémon long before the battle, so
  -- the 50% swap runs there too (its spawn filter seam) and the Pokémon you see
  -- is the one you fight; its battles come with speciesLocked, skipped above.
  -- Older Wilds of Hoenn: nothing to register, the battle-time swap stays.
  local function installWohFilter()
    local find = ctx.mod and ctx.mod.find
    local woh = type(find) == "function" and find("wilds_of_hoenn") or nil
    local ex = woh and woh.exports
    if not (ex and type(ex.addSpawnFilter) == "function") then return false end
    ex.addSpawnFilter("project_highlander_gen3", function(enc)
      local sp = encSpecies(enc)
      local other = sp and K.swapFor(sp)
      if other then
        local roll = (love and love.math and love.math.random) and love.math.random() or math.random()
        if roll < 0.5 then enc.species, enc.speciesId = other, other end
      end
      return enc
    end)
    if ctx.mod.log then ctx.mod.log:info("wilds of hoenn: spawn filter added (other game exclusives)") end
    return true
  end

  -- ------------------------------------------------------------- install

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
    local origUpdate = Field.update
    Field.update = function(...)
      local r = { origUpdate(...) }
      local ok, err = pcall(tickLimited)
      if not ok then warn("limited", err) end
      local okW, errW = pcall(applyWohFix)
      if not okW then warn("spots", errW) end
      if Field.running and fieldReady() then
        local okM, errM = pcall(tickMew)
        if not okM then warn("mew", errM) end
      end
      return (table.unpack or unpack)(r)
    end
  end

  local done = {}
  -- ------------------------------------------------------------- Cinnabar fossil revive
  -- Always on (FireRed/LeafGreen). GET OTHER FOSSIL gives you both Mt. Moon
  -- fossils, which the cartridge never expects. The Cinnabar Lab scientist's
  -- own script (read from the ROM) decides what you have from the game's
  -- FLAG_GOT_HELIX_FOSSIL / FLAG_GOT_DOME_FOSSIL, not from the bag, and once
  -- the Old Amber is revived he checks only ONE of them (Helix first) to decide
  -- he's finished ("Aiyah! You come again!").
  --   * Miguel's trade now sets the "got" flag of the fossil he gives (and
  --     saves that already traded get it here).
  --   * While you're in the scientist's room with one Mt. Moon fossil revived
  --     and the other not yet, the revived one's "got" flag is hidden, so his
  --     check sees the one still to do. It's put back as soon as you leave the
  --     room (and on the next load, if you saved in there).
  local MOON = {
    { got = "FLAG_GOT_HELIX_FOSSIL", revived = "FLAG_REVIVED_HELIX" },
    { got = "FLAG_GOT_DOME_FOSSIL", revived = "FLAG_REVIVED_DOME" },
  }

  local function restoreHidden()
    local hidden = sget("kgk_fossil_hidden")
    if type(hidden) == "string" and hidden ~= "" then
      setFlag(hidden)
      sset("kgk_fossil_hidden", false)
    end
  end

  local checkAt = 0
  local function fossilTick()
    local t = (love.timer and love.timer.getTime()) or 0
    if t < checkAt then return end
    checkAt = t + 0.25
    if not kanto() or not store() then return end
    local map = mapId()
    if map == "" then return end

    -- saves that traded with Miguel before this fix: both fossils were "got"
    if sget("kgk_fossil_traded") and flag("FLAG_GOT_FOSSIL_FROM_MT_MOON") then
      for _, f in ipairs(MOON) do
        if not flag(f.got) and sget("kgk_fossil_hidden") ~= f.got then setFlag(f.got) end
      end
    end

    local inLab = map:find("CINNABAR") and map:find("EXPERIMENT")
    if not inLab then restoreHidden() return end

    local hidden = sget("kgk_fossil_hidden")
    local hasBoth = true
    for _, f in ipairs(MOON) do
      if not (flag(f.got) or hidden == f.got) then hasBoth = false end
    end
    if not hasBoth then restoreHidden() return end
    local hRev, dRev = flag(MOON[1].revived), flag(MOON[2].revived)
    local hide = nil
    if hRev and not dRev then hide = MOON[1].got
    elseif dRev and not hRev then hide = MOON[2].got end
    if hidden ~= hide then
      restoreHidden()
      if hide then
        clearFlag(hide)
        sset("kgk_fossil_hidden", hide)
      end
    end
  end

  local function installFossilFix()
    local mod = ctx.mod
    assert(mod.hooks and mod.hooks.wrap, "no hooks")
    mod.hooks:wrap("core.update", function(nextFn, game, dt, ...)
      pcall(fossilTick)
      return nextFn(game, dt, ...)
    end)
  end

  function K.install()
    -- Wilds of Hoenn may not be ready on the first try: retried on every install call
    if not done["woh filter"] then
      local ok, found = pcall(installWohFilter)
      if ok and found then done["woh filter"] = true elseif not ok then warn("woh filter", found) end
    end
    if K.installed then return end
    local all = true
    for _, s in ipairs({ { "battles", installBattles }, { "stay", installStay }, { "spots", installWohFix }, { "field", installField }, { "fossil fix", installFossilFix } }) do
      if not done[s[1]] then
        local ok, err = pcall(s[2])
        if ok then done[s[1]] = true else all = false warn(s[1], err) end
      end
    end
    K.installed = all
  end

  return K
end
