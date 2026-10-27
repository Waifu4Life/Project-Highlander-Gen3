-- PokéMoves sub-menu (same idea as Project Highlander Gen 1/2). All Off by default.
--
--   FORGETTABLE HMS : an HM move can be replaced like any other move (level up,
--                     TMs, HMs, move tutors, the relearner).
--   INSTANT TMS/HMS : A in front of a cut tree, smashable rock, boulder, water,
--                     waterfall or dive spot uses Cut / Rock Smash / Strength /
--                     Surf / Waterfall / Dive straight away (no question, no text).
--                     SELECT in the overworld lists Sweet Scent, Teleport, Dig,
--                     Secret Power, Fly and Flash under the Item Shortcuts.
--   MOVE RELEARNING : RELEARN in the Party A menu opens the game's own Move
--                     Relearner for that Pokémon; the list also has the level-up
--                     moves of its earlier forms (up to its current level).
--   NO LEARN HMS    : with the badge, a Pokémon that CAN learn the HM counts as
--                     knowing it (field, party menu and the game's scripts).
--   TMS FOREVER     : teaching a TM doesn't use it up.
return function(ctx)
  local S = ctx.settings
  local M = { installed = false }

  local function on(key) return S.get(key) == true end
  M.instantOn = function() return on("instant_tmhm") end

  local function req(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
    return nil
  end

  local function warn(what, err)
    if ctx.mod.log then ctx.mod.log:warn("pokemoves %s: %s", what, tostring(err)) end
  end

  local function session()
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.getSession then
      local ok, s = pcall(Runtime.getSession)
      if ok and type(s) == "table" then return s end
    end
    local g = S.game and S.game()
    return g and g.session or nil
  end

  local function se(id)
    pcall(function()
      local Audio = require("src.core.game3.audio")
      local ids = req("src.core.game3.se_ids")
      Audio.playSe((ids and ids.resolve) and ids.resolve(id) or id)
    end)
  end

  -- ------------------------------------------------------------- HM helpers

  -- the real HM move ids (Pokemon.isHmMove is switched off by Forgettable HMs)
  local HM_IDS = {
    [15] = "CUT", [19] = "FLY", [57] = "SURF", [70] = "STRENGTH", [148] = "FLASH",
    [249] = "ROCK_SMASH", [127] = "WATERFALL", [291] = "DIVE",
  }
  local HM_BY_NAME = {}
  for id, name in pairs(HM_IDS) do HM_BY_NAME[name] = id end

  local hmItemCache = {}
  local function hmItemFor(moveId)
    if hmItemCache[moveId] ~= nil then return hmItemCache[moveId] or nil end
    local Pokemon = req("src.core.game3.pokemon")
    local found = false
    if Pokemon and Pokemon.moveFromTmItem then
      for n = 339, 346 do
        local ok, mv = pcall(Pokemon.moveFromTmItem, n)
        if ok and tonumber(mv) == moveId then found = n break end
      end
    end
    hmItemCache[moveId] = found
    return found or nil
  end

  local function speciesNum(mon)
    local n = tonumber(mon.species or mon.speciesId)
    if n then return n end
    local Pokemon = req("src.core.game3.pokemon")
    if Pokemon and Pokemon.speciesOf then
      local ok, v = pcall(Pokemon.speciesOf, mon)
      if ok then return tonumber(v) end
    end
  end

  local function isEgg(mon)
    if not mon then return true end
    if mon.isEgg or mon.egg then return true end
    local Pokemon = req("src.core.game3.pokemon")
    if Pokemon and Pokemon.isEgg then
      local ok, v = pcall(Pokemon.isEgg, mon)
      if ok and v then return true end
    end
    return false
  end

  local function canLearnHm(mon, moveId)
    if isEgg(mon) then return false end
    local item = hmItemFor(moveId)
    local sp = speciesNum(mon)
    local Pokemon = req("src.core.game3.pokemon")
    if not (item and sp and Pokemon and Pokemon.canLearnTmItem) then return false end
    local ok, can = pcall(Pokemon.canLearnTmItem, sp, item)
    return ok and can == true
  end

  local function hasBadge(sess, moveId)
    local FieldMoves = req("src.core.game3.field_moves")
    local Space = req("src.core.game3.scripting.space")
    if not FieldMoves then return false end
    local ok, has = pcall(FieldMoves.hasBadge,
      { store = Space and Space.store, session = sess or session() }, HM_IDS[moveId])
    return ok and has == true
  end

  -- No Learn HMs: first Pokémon (party order) that can learn the HM. 0-based slot.
  local function noLearnUser(party, moveId, sess)
    if not on("no_learn_hms") or not HM_IDS[moveId] or type(party) ~= "table" then return nil end
    if not hasBadge(sess, moveId) then return nil end
    for i = 1, 6 do
      local mon = party[i]
      if mon and canLearnHm(mon, moveId) then return mon, i - 1 end
    end
    return nil
  end
  M.noLearnUser = noLearnUser

  -- a Pokémon that knows the move, or (No Learn HMs) can learn it
  local function fieldUser(moveName)
    local FieldMoves = req("src.core.game3.field_moves")
    local sess = session()
    if not (FieldMoves and sess) then return nil end
    local mon, slot = FieldMoves.partyMoveUser(sess.party, moveName)
    if mon then return mon, slot end
    return nil
  end

  -- ------------------------------------------------------------- Forgettable HMs

  local function installForgettable()
    local Pokemon = require("src.core.game3.pokemon")
    local orig = Pokemon.isHmMove
    if type(orig) ~= "function" then return end
    Pokemon.isHmMove = function(moveId, ...)
      if on("forgettable_hms") then return false end
      return orig(moveId, ...)
    end
  end

  -- ------------------------------------------------------------- TMs Forever

  local teaching = 0
  local function installTmsForever()
    local Bag = require("src.core.game3.bag")
    local ItemsData = require("src.core.game3.items_data")
    local PartyMenu = require("src.ui.game3.party_menu")
    local function num(id)
      local ok, n = pcall(ItemsData.toNumericId, id)
      return (ok and tonumber(n)) or tonumber(id)
    end
    local function isTm(id)
      local okT, tm = pcall(ItemsData.isTm, id)
      local okH, hm = pcall(ItemsData.isHm, id)
      return okT and tm and not (okH and hm)
    end
    local origRemove = Bag.remove
    Bag.remove = function(bag, id, qty, ...)
      if on("tms_forever") and (tonumber(qty) or 1) == 1 and isTm(id) then
        -- teaching from the Bag / TM Case opens the party in "use" mode
        -- (GIVE uses "give", so a held TM is still taken from the Bag)
        local partyTeach = PartyMenu.open and PartyMenu._item ~= nil and num(PartyMenu._item) == num(id)
          and (PartyMenu._previousMode == "use" or PartyMenu.mode == "use")
        if partyTeach or teaching > 0 then return true end
      end
      return origRemove(bag, id, qty, ...)
    end
    local ItemUse = req("src.core.game3.item_use")
    if ItemUse and type(ItemUse.useTm) == "function" then
      local origUse = ItemUse.useTm
      ItemUse.useTm = function(...)
        teaching = teaching + 1
        local r = { pcall(origUse, ...) }
        teaching = teaching - 1
        if not r[1] then error(r[2], 0) end
        return (table.unpack or unpack)(r, 2)
      end
    end
  end

  -- ------------------------------------------------------------- No Learn HMs

  local function installNoLearn()
    local FieldMoves = require("src.core.game3.field_moves")
    local Ops = require("src.core.game3.scripting.ops_a")
    local Flags = require("src.core.game3.scripting.flags")
    local Ctx = require("src.core.game3.scripting.ctx")
    local origUser = FieldMoves.partyMoveUser
    FieldMoves.partyMoveUser = function(party, move, ...)
      local mon, slot = origUser(party, move, ...)
      if mon or not on("no_learn_hms") then return mon, slot end
      local id = FieldMoves.normalizeMoveId(move)
      local m2, s2 = noLearnUser(party, id)
      if m2 then return m2, s2 end
      return mon, slot
    end

    -- the ROM scripts' checkpartymove (Ruby/Sapphire/Emerald trees, rocks, water...)
    local origDispatch = Ops.dispatch
    Ops.dispatch = function(vm, row, ...)
      local r = { origDispatch(vm, row, ...) }
      if type(row) == "table" and row.op == "checkpartymove" and on("no_learn_hms") then
        local ok, err = pcall(function()
          local moveId = tonumber(row[1]) or 0
          if not HM_IDS[moveId] then return end
          local store, c = vm.store, vm.ctx
          if tonumber(Flags.getVar(store, c, Ctx.VAR_RESULT)) ~= 6 then return end
          local sess = session()
          local mon, slot = noLearnUser(sess and sess.party, moveId, sess)
          if mon then
            Flags.setVar(store, c, Ctx.VAR_RESULT, slot)
            Flags.setVar(store, c, 0x8004, speciesNum(mon) or 0)
          end
        end)
        if not ok then warn("checkpartymove", err) end
      end
      return (table.unpack or unpack)(r)
    end
  end

  -- ------------------------------------------------------------- Party A menu

  local relearnMon = nil

  -- pre-evolutions of every species, built once
  local prevos = nil
  local function prevosOf(species)
    if not prevos then
      prevos = {}
      local Pokemon = req("src.core.game3.pokemon")
      if Pokemon and Pokemon.evolutions then
        for sp = 1, 411 do
          local ok, rows = pcall(Pokemon.evolutions, sp)
          if ok and type(rows) == "table" then
            for _, evo in ipairs(rows) do
              local to = tonumber(evo.target or evo[3]) or 0
              if to > 0 then
                prevos[to] = prevos[to] or {}
                prevos[to][#prevos[to] + 1] = sp
              end
            end
          end
        end
      end
    end
    return prevos[species] or {}
  end

  -- the relearnable list plus the earlier forms' level-up moves (up to its level)
  local function extendList(mon, list)
    local Pokemon = req("src.core.game3.pokemon")
    local species = Pokemon and Pokemon.speciesOf and Pokemon.speciesOf(mon) or speciesNum(mon)
    if not (Pokemon and species) then return list end
    local level = tonumber(mon.level) or 0
    local have = {}
    for i = 1, 4 do
      local id = Pokemon.moveIdAt(mon, i)
      if id then have[id] = true end
    end
    for _, mv in ipairs(list) do have[mv] = true end
    local seen, queue = { [species] = true }, {}
    for _, p in ipairs(prevosOf(species)) do queue[#queue + 1] = p end
    while #queue > 0 do
      local sp = table.remove(queue, 1)
      if not seen[sp] then
        seen[sp] = true
        for _, e in ipairs(Pokemon.learnset(sp)) do
          local lv = tonumber(e[1] or e.level) or 0
          local mv = tonumber(e[2] or e.move) or 0
          if mv > 0 and lv <= level and not have[mv] then
            have[mv] = true
            list[#list + 1] = mv
          end
        end
        for _, p in ipairs(prevosOf(sp)) do queue[#queue + 1] = p end
      end
    end
    return list
  end

  local function relearnable(mon)
    local MoveLearn = req("src.core.game3.move_learn")
    if not (mon and MoveLearn) or isEgg(mon) then return {} end
    local prev = relearnMon
    relearnMon = mon
    local ok, list = pcall(MoveLearn.relearnableMoves, mon)
    relearnMon = prev
    return ok and type(list) == "table" and list or {}
  end

  local function installRelearnList()
    local MoveLearn = require("src.core.game3.move_learn")
    local orig = MoveLearn.relearnableMoves
    MoveLearn.relearnableMoves = function(mon, ...)
      local list = orig(mon, ...)
      if relearnMon ~= nil and mon == relearnMon and type(list) == "table" then
        local ok, out = pcall(extendList, mon, list)
        if ok then return out end
        warn("relearn list", out)
      end
      return list
    end
  end

  local function relearnerScreen(sess)
    local Profile = req("src.core.game3.profile")
    local id = Profile and Profile.forSession(sess).id
    if id == "ruby" or id == "sapphire" then return req("src.ui.game3.rs.move_relearner") end
    if id == "emerald" then return req("src.ui.game3.rse.move_relearner") end
    return req("src.ui.game3.move_relearner")
  end

  local PartyMenu
  local RELEARN = "RELEARN"

  local function destroyPartyOam()
    local Oam = req("src.core.game3.oam")
    if not Oam then return end
    local slots = PartyMenu._oam
    if slots then
      for i = 1, 6 do
        local s = slots[i]
        if s then
          for _, k in ipairs({ "mon", "ball", "status", "item" }) do
            if s[k] ~= nil then pcall(Oam.destroySprite, s[k]) end
          end
        end
      end
    end
    if PartyMenu._summaryIcon ~= nil then pcall(Oam.destroySprite, PartyMenu._summaryIcon) end
    PartyMenu._oam, PartyMenu._summaryIcon = nil, nil
  end

  local function openRelearn()
    local mon = PartyMenu._party and PartyMenu._party[PartyMenu.cursor]
    local sess = PartyMenu._session or session()
    local Screen = relearnerScreen(sess)
    if not (mon and Screen and Screen.show) then return false end
    se("SE_SELECT")
    PartyMenu.mode = "list"
    destroyPartyOam()
    relearnMon = mon
    local ok, err = pcall(Screen.show, mon, {
      session = sess,
      onDone = function()
        relearnMon = nil
        PartyMenu.mode = "list"
        pcall(PartyMenu.reloadSprites)
      end,
    })
    if not ok then
      relearnMon = nil
      warn("relearn", err)
      pcall(PartyMenu.reloadSprites)
    end
    return true
  end

  local function indexOf(list, v)
    for i, x in ipairs(list) do if x == v then return i end end
  end

  -- the overworld A menu (SUMMARY, ITEM/MAIL and CANCEL are always in it)
  local function isFieldList(list)
    if type(list) ~= "table" then return false end
    for i = 1, #list do if type(list[i]) ~= "string" then return false end end
    return indexOf(list, "SUMMARY") and indexOf(list, "CANCEL")
      and (indexOf(list, "ITEM") or indexOf(list, "MAIL")) and true or false
  end

  -- field-move label the game uses for a move id (nil if it has none)
  local function fieldLabel(moveId)
    local FieldMoves = req("src.core.game3.field_moves")
    local gfm = PartyMenu._fieldMoveData
    local label
    if type(gfm) == "table" and type(gfm.byMove) == "table" then
      label = gfm.byMove[moveId]
    else
      local name = FieldMoves and FieldMoves.MOVE_NAME_BY_ID[moveId]
      label = name and (name:gsub("_", " "))
    end
    if not label then return nil end
    local ok, text = pcall(PartyMenu._cursorOptionText, label)
    if not ok or text == nil then return nil end
    return label, text
  end

  -- add No Learn HM rows and RELEARN to the A menu that just opened
  local function addRows()
    local list = PartyMenu.ACTIONS
    if not isFieldList(list) then return end
    local mon = PartyMenu._party and PartyMenu._party[PartyMenu.cursor]
    if not mon or isEgg(mon) then return end
    local adds = {}
    local Pokemon = req("src.core.game3.pokemon")
    if on("no_learn_hms") and Pokemon then
      local sess = PartyMenu._session or session()
      local ids = {}
      for id in pairs(HM_IDS) do ids[#ids + 1] = id end
      table.sort(ids)
      for _, id in ipairs(ids) do
        if not Pokemon.knowsMove(mon, id) and canLearnHm(mon, id) and hasBadge(sess, id) then
          local label, text = fieldLabel(id)
          if label and not indexOf(list, label) then
            adds[#adds + 1] = { act = label, text = text, field = true }
          end
        end
      end
    end
    if on("move_relearning") and not indexOf(list, RELEARN) and #relearnable(mon) > 0 then
      adds[#adds + 1] = { act = RELEARN, text = RELEARN }
    end
    if #adds == 0 then return end

    -- texts for the rows already there (keep another mod's prebuilt ones)
    local old = PartyMenu._actionTexts
    local texts = {}
    for i, act in ipairs(list) do
      local t = (type(old) == "table" and old.list == list and type(old.texts) == "table") and old.texts[i] or nil
      if t == nil then
        local ok, v = pcall(PartyMenu._cursorOptionText, act)
        t = ok and v or act
      end
      texts[i] = t
    end
    local at = indexOf(list, "CANCEL") or (#list + 1)
    PartyMenu._fieldMoveNames = PartyMenu._fieldMoveNames or {}
    for _, a in ipairs(adds) do
      table.insert(list, at, a.act)
      table.insert(texts, at, a.text)
      if a.field then PartyMenu._fieldMoveNames[a.act] = true end
      at = at + 1
    end
    PartyMenu._actionTexts = { list = list, texts = texts }
  end

  local function installParty()
    PartyMenu = require("src.ui.game3.party_menu")
    local origInput = PartyMenu.handleInput
    PartyMenu.handleInput = function(input, ...)
      local before = PartyMenu.mode
      if before == "action" and input and input.wasPressed and input:wasPressed("a")
          and on("move_relearning") then
        local act = PartyMenu.ACTIONS and PartyMenu.ACTIONS[PartyMenu.actionCursor or 1]
        if act == RELEARN then
          local ok, done = pcall(openRelearn)
          if not ok then warn("relearn", done) end
          if ok and done then return end
        end
      end
      local r = { origInput(input, ...) }
      if before == "list" and PartyMenu.mode == "action" then
        local ok, err = pcall(addRows)
        if not ok then warn("party rows", err) end
      end
      return (table.unpack or unpack)(r)
    end
  end

  -- ------------------------------------------------------------- Instant A press

  local function fieldReady()
    local Field = req("src.core.game3.field")
    if not (Field and Field.running) or Field.locked then return false end
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.uiBusy and Runtime.uiBusy() then return false end
    local Space = req("src.core.game3.scripting.space")
    if not (Space and Space.active) then return false end
    if Space.vm and Space.vm.isRunning and Space.vm:isRunning() then return false end
    local P = req("src.core.game3.player")
    if not P or P.moving or P.boulderPush or P.jumping then return false end
    return true
  end

  local DELTA = { up = { 0, -1 }, down = { 0, 1 }, left = { -1, 0 }, right = { 1, 0 } }

  local function badgeFor(name)
    local id = HM_BY_NAME[name]
    return id == nil or hasBadge(session(), id)
  end

  local function tryInstant()
    local Field = require("src.core.game3.field")
    local FieldMoves = require("src.core.game3.field_moves")
    local P = require("src.core.game3.player")
    local Objects = require("src.core.game3.objects")
    local Collision = require("src.core.game3.collision")
    local Flags = require("src.core.game3.scripting.flags")
    local Space = req("src.core.game3.scripting.space")
    local d = DELTA[P.facing or "down"] or DELTA.down
    local fx, fy = P.cellX + d[1], P.cellY + d[2]

    local eo = Objects.at(fx, fy)
    if eo then
      local gfx = eo.graphicsId or (eo.def and (eo.def.graphicsId or eo.def.gfx))
      local G = FieldMoves.GFX_IDS
      if gfx == nil then return false end
      if gfx == G.CUT_TREE then
        local mon = fieldUser("CUT")
        if not (mon and badgeFor("CUT")) then return false end
        Field.executeFieldMove({ action = "cut_tree", target = eo, mon = mon, se = FieldMoves.SE.CUT })
        return true
      elseif gfx == G.ROCK_SMASH_ROCK then
        local mon = fieldUser("ROCK_SMASH")
        if not (mon and badgeFor("ROCK_SMASH")) then return false end
        Field.executeFieldMove({ action = "rock_smash", target = eo, mon = mon, se = FieldMoves.SE.ROCK_SMASH })
        return true
      elseif gfx == G.PUSHABLE_BOULDER then
        local flag = FieldMoves.SYS_FLAGS.USE_STRENGTH
        if Space and Space.store and flag and Flags.getFlag(Space.store, nil, flag) then return false end
        local mon = fieldUser("STRENGTH")
        if not (mon and badgeFor("STRENGTH")) then return false end
        Field.executeFieldMove({ action = "strength", mon = mon, flag = flag })
        return true
      end
      return false
    end

    -- waterfall (surfing, facing up)
    local beh = Collision.behavior and Collision.behavior(fx, fy)
    if FieldMoves.isWaterfallBehavior(beh) then
      if not (P.surfing and P.facing == "up") then return false end
      local mon = fieldUser("WATERFALL")
      if not (mon and badgeFor("WATERFALL")) then return false end
      Field.executeFieldMove({ action = "waterfall", mon = mon })
      return true
    end

    -- water in front (not already surfing)
    if not P.surfing and not P.underwater and Collision.isWater and Collision.isWater(fx, fy) then
      local mon = fieldUser("SURF")
      if not (mon and badgeFor("SURF")) then return false end
      Field.executeFieldMove({ action = "surf", mon = mon })
      return true
    end
    return false
  end

  local function installInstantA()
    local Field = require("src.core.game3.field")
    local Dive = require("src.core.game3.dive")
    local origInteract = Field.interact
    Field.interact = function(game, ...)
      if on("instant_tmhm") and fieldReady() then
        local ok, done = pcall(tryInstant)
        if not ok then warn("instant", done) end
        if ok and done then return true end
      end
      local r = origInteract(game, ...)
      -- underwater: A also comes back up (B still works too)
      if not r and on("instant_tmhm") then
        local P = req("src.core.game3.player")
        local Dive = req("src.core.game3.dive")
        if P and P.underwater and Dive and Dive.tryEmerge then
          local ok, up = pcall(Dive.tryEmerge)
          if ok and up then return true end
        end
      end
      return r
    end

    local function instantDive(wantCode)
      if not on("instant_tmhm") or not fieldReady() then return false end
      local sess = session()
      if not (Dive.enabled(sess) and Dive._task == nil) then return false end
      if wantCode == 1 and not Dive.isUnderwaterMap((require("src.core.game3.map").currentDef())) then
        return false
      end
      if not hasBadge(sess, 291) then return false end
      local code = Dive.trySetDiveWarp(sess)
      if code ~= wantCode then return false end
      local mon = fieldUser("DIVE")
      if not mon then return false end
      Dive.useDive(nil, mon)
      return true
    end
    local origDown, origUp = Dive.tryDiveDown, Dive.tryEmerge
    Dive.tryDiveDown = function(...)
      local ok, done = pcall(instantDive, 2)
      if not ok then warn("dive", done) end
      if ok and done then return true end
      return origDown(...)
    end
    Dive.tryEmerge = function(...)
      local ok, done = pcall(instantDive, 1)
      if not ok then warn("emerge", done) end
      if ok and done then return true end
      return origUp(...)
    end
  end

  -- ------------------------------------------------------------- Instant SELECT menu

  -- in menu order: Sweet Scent, Teleport, Dig, Secret Power, Fly, Flash
  local MENU_MOVES = {
    { key = "SWEET_SCENT" }, { key = "TELEPORT" }, { key = "DIG" },
    { key = "SECRET_POWER", hoenn = true }, { key = "FLY" }, { key = "FLASH" },
  }

  -- moves for the SELECT box: { move = "FLY", label = "FLY" }, ...
  function M.selectMoves(sess)
    local out = {}
    if not on("instant_tmhm") then return out end
    sess = sess or session()
    local FieldMoves = req("src.core.game3.field_moves")
    local Pokemon = req("src.core.game3.pokemon") or {}
    if not (FieldMoves and sess) then return out end
    for _, m in ipairs(MENU_MOVES) do
      if not m.hoenn or S.isHoenn(sess) then
        local mon = FieldMoves.partyMoveUser(sess.party, m.key)
        if mon and badgeFor(m.key) then
          local id = FieldMoves.MOVES[m.key]
          local okN, n = false, nil
          if Pokemon.moveName then okN, n = pcall(Pokemon.moveName, id) end
          local label = (okN and n) and tostring(n):upper() or (m.key:gsub("_", " "))
          out[#out + 1] = { move = m.key, label = label }
        end
      end
    end
    return out
  end

  local function mapFlag(def, key)
    return def ~= nil and (tonumber(def[key]) or 0) ~= 0
  end

  -- same checks and effects as choosing the move in the Party menu
  function M.useMenuMove(game, moveKey)
    local Field = require("src.core.game3.field")
    local FieldMoves = require("src.core.game3.field_moves")
    local P = require("src.core.game3.player")
    local Collision = require("src.core.game3.collision")
    local Objects = require("src.core.game3.objects")
    local Map = require("src.core.game3.map")
    local Space = req("src.core.game3.scripting.space")
    local sess = (game and game.session) or session()
    if not sess then return end
    local mon, slot = FieldMoves.partyMoveUser(sess.party, moveKey)
    if not mon then return end
    local d = DELTA[P.facing or "down"] or DELTA.down
    local fx, fy = P.cellX + d[1], P.cellY + d[2]
    local mapDef = Map.currentDef()
    local function grass3x3()
      if not Collision.isGrass then return false end
      for y = P.cellY - 1, P.cellY + 1 do
        for x = P.cellX - 1, P.cellX + 1 do
          local e = Collision.elevationAt and Collision.elevationAt(x, y)
          if (P.elevation == nil or e == P.elevation) and Collision.isGrass(x, y) then return true end
        end
      end
      return false
    end
    local fctx = {
      party = sess.party, mon = mon, slot = (slot or 0) + 1,
      store = Space and Space.store, session = sess,
      facingObject = Objects.at(fx, fy),
      isFacingWater = Collision.isWater and Collision.isWater(fx, fy),
      isFacingWaterfall = FieldMoves.isWaterfallBehavior(Collision.behavior and Collision.behavior(fx, fy)),
      facing = P.facing, isSurfing = P.surfing == true,
      hasCuttableGrass = grass3x3(),
      mapType = mapDef and mapDef.mapType,
      isCave = mapFlag(mapDef, "cave"),
      canEscapeRope = mapFlag(mapDef, "allowEscaping"),
      escapeWarp = sess.escapeWarp,
    }
    local res = FieldMoves.fromMenu(moveKey, fctx)
    if not res or not res.ok then
      se("SE_SELECT")
      local Message = req("src.ui.game3.message")
      local RomText = req("src.core.game3.rom_text")
      local text = res and res.text
      if not text and RomText then
        local ok, t = pcall(RomText.box, "gText_CantUseHere")
        text = ok and t or nil
      end
      if Message and text then Message.show(text) end
      return
    end
    if res.action == "secret_power" then return end -- its own script is already queued
    Field.executeFieldMove(res)
  end

  -- ------------------------------------------------------------- install

  -- each part installs once; a part that fails (game not ready yet) is retried
  -- on the next install call (game.ready)
  local done = {}
  function M.install()
    if M.installed then return end
    local steps = {
      { "forgettable hms", installForgettable },
      { "tms forever", installTmsForever },
      { "no learn hms", installNoLearn },
      { "relearn list", installRelearnList },
      { "party", installParty },
      { "instant", installInstantA },
    }
    local all = true
    for _, s in ipairs(steps) do
      if not done[s[1]] then
        local ok, err = pcall(s[2])
        if ok then done[s[1]] = true else all = false warn(s[1], err) end
      end
    end
    M.installed = all
  end

  return M
end
