-- Overworld QoL, all five Gen 3 games.
--
-- QOL > INFINITE SAFARI
--   The Safari Zone step counter (Kanto and Hoenn) is topped back up before
--   every step, so it stays full and never runs out. The game only ends when
--   you run out of Safari Balls or leave. Hoenn Pokéblock feeders still count down.
--
-- QOL > RUN EVERYWHERE
--   With the Running Shoes, the map's "no running" setting (buildings in
--   Ruby/Sapphire/Emerald) is ignored. Ground that blocks running for its
--   animation (long grass, hot springs, Pacifidlog logs, Fortree bridges)
--   still does. FireRed/LeafGreen already allow running indoors.
--
-- QOL > SPARKLING HIDDEN ITEMS
--   Every hidden item not found yet on the current map gets a pulsing
--   sparkle on the ground, drawn over the map's top layer (tall grass, tree tops). Picking it up clears
--   the game's own flag, so the sparkle goes away.
--
-- FEEBAS TILES (always on, Ruby/Sapphire/Emerald)
--   On Route 119 the water tiles where Feebas can be fished shimmer. They
--   follow the Dewford trend like the game's own Feebas check, so they move
--   when the trend changes.
--
-- QOL > USE REPEL AGAIN?
--   The last Repel used is remembered in the save. When one wears off and you
--   still have that kind, the game asks "Use another ...?". Yes uses it through
--   the game's normal item code (bag count, message, quest log).
return function(ctx, patch)
  local P = {}
  local S = ctx.settings
  -- The mod sandbox has no `package` table; require hands back the game's
  -- real (already loaded) modules.
  local function mreq(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
    return nil
  end
  local function pack(...) return { n = select("#", ...), ... } end
  local function unpackN(t, i) return (table.unpack or unpack)(t, i, t.n) end
  local mod = ctx.mod

  local function lazy(name) return mreq(name) end

  local function session()
    local Runtime = lazy("src.core.game3.runtime")
    return Runtime and Runtime.getSession and Runtime.getSession() or nil
  end

  -- ------------------------------------------------------- infinite safari

  local function installSafari()
    local Safari = require("src.core.game3.safari")
    local orig = Safari.takeStep
    assert(type(orig) == "function", "Safari.takeStep missing")
    Safari.takeStep = function(sess, game, ...)
      if S.get("infinite_safari") == true then
        pcall(function()
          if not Safari.isActive(sess) then return end
          local state = Safari.state(sess)
          if type(state) ~= "table" then return end
          local cfg = Safari.rseConfig and Safari.rseConfig(sess or session()) or nil
          local full = (cfg and tonumber(cfg.steps)) or tonumber(Safari.STEPS) or 600
          state.steps = full + 1 -- the step about to be taken brings it back to full
        end)
      end
      return orig(sess, game, ...)
    end
  end

  -- -------------------------------------------------------- run everywhere

  local function installRun()
    local Player = require("src.core.game3.player")
    local Collision = require("src.core.game3.collision")
    local orig = Player.runningDisallowed
    assert(type(orig) == "function", "Player.runningDisallowed missing")
    Player.runningDisallowed = function(cx, cy, ...)
      if S.get("run_everywhere") ~= true then return orig(cx, cy, ...) end
      local def = Collision._mapDef
      if type(def) ~= "table" or tonumber(def.allowRunning) ~= 0 then return orig(cx, cy, ...) end
      local before = def.allowRunning
      def.allowRunning = 1
      local res = pack(pcall(orig, cx, cy, ...))
      def.allowRunning = before
      if not res[1] then error(res[2], 0) end
      return unpackN(res, 2)
    end
  end

  -- ------------------------------------------------ sparkling hidden items

  local CELL = 16
  -- 10x10 diamond sparkle (same shape as the Gen 1/2 sparkle): row widths.
  local SPARKLE = { 2, 2, 4, 6, 10, 10, 6, 4, 2, 2 }

  -- Every place the game keeps a map's bg events: the map definition the
  -- game uses for A-button pickups (game.data.maps), the script bundle, and
  -- the currently loaded map. Hidden items from all of them are combined.
  local srcInfo = ""
  local function isHidden(ev)
    return type(ev) == "table" and (ev.type == "hidden_item" or ev.kind == 7)
      and tonumber(ev.x) ~= nil and tonumber(ev.y) ~= nil
  end
  local function bgEvents(game, mapId)
    local Map = mreq("src.core.game3.map")
    local Space = mreq("src.core.game3.scripting.space")
    local data = game and game.data and game.data.maps
    local def = mapId and data and data[mapId]
    local ev = Space and Space.bundle and Space.bundle.events and mapId and Space.bundle.events[mapId]
    local cur = Map and Map.currentDef and Map.currentDef()
    local lists = {
      { "data", def and def.bgEvents },
      { "bundle", ev and ev.bgEvents },
      { "cur", (Map and (Map.current == nil or Map.current == mapId)) and cur and cur.bgEvents or nil },
    }
    local out, seen, info = {}, {}, {}
    for _, l in ipairs(lists) do
      local list, total, hid = l[2], 0, 0
      if type(list) == "table" then
        for _, e in ipairs(list) do
          total = total + 1
          if isHidden(e) then
            hid = hid + 1
            local key = tostring(e.x) .. "," .. tostring(e.y)
            if not seen[key] then
              seen[key] = true
              out[#out + 1] = e
            end
          end
        end
        info[#info + 1] = l[1] .. " " .. total .. "/" .. hid
      else
        info[#info + 1] = l[1] .. " -"
      end
    end
    srcInfo = table.concat(info, ", ")
    return out
  end

  local function hiddenStore(sess)
    local Runtime = mreq("src.core.game3.runtime")
    local Space = mreq("src.core.game3.scripting.space")
    if sess and Runtime and Runtime.getSession and Runtime.getSession() == sess and Space and Space.store then
      return Space.store
    end
    if Space and Space.store then return Space.store end
    return sess and (sess.store or sess)
  end

  local diag = { count = nil, route = "-", err = nil, map = "?" }

  local function drawSparkles(camX, camY)
    local Field = mreq("src.core.game3.field")
    local Runtime = mreq("src.core.game3.runtime")
    local sess = (Field and Field._session) or session()
    local game = (Field and Field._game) or (Runtime and Runtime._game)
    local Map = mreq("src.core.game3.map")
    local mapId = (sess and sess.map) or (Map and Map.current)
    if not (game and game.data and game.data.maps and game.data.maps[mapId]) and Runtime and Runtime._game then
      game = Runtime._game
    end
    diag.map = tostring(mapId)
    diag.count = 0
    if not mapId then return 0 end
    local events = bgEvents(game, mapId)
    if type(events) ~= "table" or #events == 0 then return 0 end
    local Flags = lazy("src.core.game3.scripting.flags")
    if not Flags then return 0 end
    local store = hiddenStore(sess)
    local G = love.graphics
    local now = (love.timer and love.timer.getTime and love.timer.getTime()) or 0
    local n = 0
    G.push("all")
    pcall(G.setShader)
    pcall(G.setBlendMode, "alpha")
    for _, ev in ipairs(events) do
      if isHidden(ev) then
        local flag = ev.flag or (ev.hiddenItemId and (0x3E8 + ev.hiddenItemId))
        if flag and not Flags.getFlag(store, nil, flag) then
          n = n + 1
          local x, y = tonumber(ev.x), tonumber(ev.y)
          local pulse = 0.45 + 0.55 * math.abs(math.sin(now * 4 + x * 1.7 + y * 2.3))
          local cx = math.floor(x * CELL + CELL / 2 - camX)
          local top = math.floor(y * CELL + CELL / 2 - camY) - #SPARKLE / 2
          -- dark outline, then the white sparkle
          G.setColor(0.1, 0.1, 0.2, 0.6 * pulse)
          for row, w in ipairs(SPARKLE) do
            G.rectangle("fill", cx - w / 2 - 1, top + row - 1, w + 2, 1)
          end
          G.setColor(1, 1, 1, pulse)
          for row, w in ipairs(SPARKLE) do
            G.rectangle("fill", cx - w / 2, top + row - 1, w, 1)
          end
        end
      end
    end
    G.pop()
    diag.count = n
    return n
  end

  -- ---------------------------------------------------- feebas tile shimmer
  -- Always on (Ruby/Sapphire/Emerald, Route 119). The six Feebas tiles are
  -- worked out exactly like the game's checkFeebas does it (seed from the
  -- current Dewford trend, same LCG, same per-section tile numbering), but
  -- without touching the game's RNG. Each matching water tile shimmers.

  local NUM_FEEBAS_SPOTS = 6
  local NUM_FISHING_SPOTS = 131 + 167 + 149
  local feebasCache = { key = nil, tiles = nil }

  local function feebasRules()
    local Encounters = mreq("src.core.game3.encounters")
    if not (Encounters and Encounters.rules) then return nil end
    local ok, R = pcall(Encounters.rules)
    if not (ok and type(R) == "table" and R.checkFeebas and R.wildExtra) then return nil end
    return R, Encounters
  end

  local function onRoute119(mapId, Encounters)
    local MapIds = mreq("src.core.game3.map_ids")
    local H = Encounters._h
    if not (MapIds and MapIds.forConst and H and H.constants) then return false end
    local ok, id = pcall(MapIds.forConst, "MAP_ROUTE119", H.constants().game)
    return ok and id ~= nil and id == mapId
  end

  local function feebasTiles(mapId)
    local R, Encounters = feebasRules()
    if not R or not onRoute119(mapId, Encounters) then return nil end
    local bitlib = mreq("bit")
    local Rng = mreq("src.core.game3.rng")
    local Coll = mreq("src.core.game3.collision")
    local CollRse = package and package.loaded and package.loaded["src.core.game3.scripting.collision_rse"]
      or mreq("src.core.game3.scripting.collision_rse")
    local bits = CollRse and CollRse._tileBits
    local layout = Coll and Coll._mapDef and Coll._mapDef.midLayout
    local width = layout and tonumber(layout.width)
    if not (bitlib and Rng and Rng.mulU32 and Coll and Coll.behavior and bits and width) then return nil end
    local sess = session()
    local trend = sess and type(sess.dewfordTrends) == "table" and sess.dewfordTrends[1]
    local seed = tonumber(trend and trend.rand) or 0
    local key = tostring(mapId) .. ":" .. seed .. ":" .. tostring(layout)
    if feebasCache.key == key then return feebasCache.tiles end

    -- the same six spot numbers the game rolls (wild_encounter.c:136)
    local state = seed
    local wanted = {}
    local i = 0
    while i ~= NUM_FEEBAS_SPOTS do
      state = (Rng.mulU32(1103515245, state) + 12345) % 4294967296
      local v = math.floor(state / 65536) % NUM_FISHING_SPOTS
      if v == 0 then v = NUM_FISHING_SPOTS end
      if v < 1 or v >= 4 then
        wanted[v] = true
        i = i + 1
      end
    end

    -- number the water tiles the way the game does (wild_encounter.c:90):
    -- a tile's section comes from its row (last match wins, else the first)
    local sections = R.wildExtra().feebas.sections
    local function sectionOf(y)
      local s = 1
      for k = 1, 3 do
        local sec = sections[k]
        if sec and y >= sec.yMin and y <= sec.yMax then s = k end
      end
      return s
    end
    local MB = mreq("src.core.game3.mb")
    local waterfall = MB and MB.id and MB.id("WATERFALL")
    local tiles = {}
    for k = 1, 3 do
      local sec = sections[k]
      if sec then
        local spot = sec.spotBase
        for y = sec.yMin, sec.yMax do
          for x = 0, width - 1 do
            local b = Coll.behavior(x, y)
            local tb = b ~= nil and (tonumber(bits[b]) or 0) or 0
            if bitlib.band(tb, 2) ~= 0 and b ~= waterfall then
              spot = spot + 1
              if wanted[spot] and sectionOf(y) == k then
                tiles[#tiles + 1] = { x = x, y = y }
              end
            end
          end
        end
      end
    end
    feebasCache.key, feebasCache.tiles = key, tiles
    return tiles
  end

  local function drawFeebas(camX, camY)
    local Field = mreq("src.core.game3.field")
    local Map = mreq("src.core.game3.map")
    local sess = (Field and Field._session) or session()
    local mapId = (sess and sess.map) or (Map and Map.current)
    if not mapId then return end
    local tiles = feebasTiles(mapId)
    if not tiles or #tiles == 0 then return end
    local G = love.graphics
    local now = (love.timer and love.timer.getTime and love.timer.getTime()) or 0
    G.push("all")
    pcall(G.setShader)
    for _, t in ipairs(tiles) do
      local px = math.floor(t.x * CELL - camX)
      local py = math.floor(t.y * CELL - camY)
      if px > -CELL and py > -CELL and px < 512 and py < 384 then
        local phase = now * 3 + t.x * 1.3 + t.y * 0.9
        local pulse = 0.5 + 0.5 * math.sin(phase)
        -- soft glow over the water tile
        G.setBlendMode("add")
        G.setColor(0.55, 0.75, 1.0, 0.18 + 0.22 * pulse)
        G.rectangle("fill", px + 1, py + 1, CELL - 2, CELL - 2)
        G.setColor(1.0, 0.85, 1.0, 0.25 + 0.35 * pulse)
        G.rectangle("fill", px + 1, py + 1, CELL - 2, 1)
        G.rectangle("fill", px + 1, py + CELL - 2, CELL - 2, 1)
        G.rectangle("fill", px + 1, py + 2, 1, CELL - 4)
        G.rectangle("fill", px + CELL - 2, py + 2, 1, CELL - 4)
        -- small twinkle that hops between the tile's corners
        G.setBlendMode("alpha")
        local corner = math.floor(phase / math.pi) % 4
        local sx = px + ((corner == 0 or corner == 3) and 5 or 10)
        local sy = py + ((corner == 0 or corner == 1) and 5 or 10)
        G.setColor(1, 1, 1, math.abs(math.sin(phase)))
        G.rectangle("fill", sx - 1, sy, 3, 1)
        G.rectangle("fill", sx, sy - 1, 1, 3)
      end
    end
    G.pop()
  end

  -- Drawn with the effects that go over tall grass (drawFront), after the
  -- map's top layer, so grass and tree tops can't cover the sparkle.
  -- Backup: if the game didn't call drawFront during a field draw, the
  -- sparkles are drawn right after the field, with the field's camera.
  local function installSparkles()
    local FieldEffects = require("src.core.game3.field_effects")
    local FieldView = require("src.core.game3.field_view")
    local origFront = FieldEffects.drawFront
    local origView = FieldView.draw
    assert(type(origFront) == "function" and type(origView) == "function", "field draw functions missing")
    local frontRan = false

    local feebasWarned = false
    local function run(camX, camY, route)
      diag.route = route
      local okF, errF = pcall(drawFeebas, camX, camY)
      if not okF then
        pcall(love.graphics.pop)
        if mod.log and not feebasWarned then
          feebasWarned = true
          pcall(mod.log.warn, mod.log, "feebas tiles: %s", tostring(errF))
        end
      end
      if S.get("sparkling_hidden") ~= true then return end
      local ok, err = pcall(drawSparkles, camX, camY)
      if not ok then
        diag.err = err
        pcall(love.graphics.pop)
        if mod.log then pcall(mod.log.warn, mod.log, "sparkles: %s", tostring(err)) end
      else
        diag.err = nil
      end
    end

    FieldEffects.drawFront = function(camX, camY, ...)
      local res = pack(origFront(camX, camY, ...))
      if tonumber(camX) and tonumber(camY) then
        frontRan = true
        run(camX, camY, "front")
      end
      return unpackN(res, 1)
    end

    FieldView.draw = function(game, canvasW, canvasH, opts, ...)
      frontRan = false
      local res = pack(origView(game, canvasW, canvasH, opts, ...))
      if not (type(opts) == "table" and opts.actorsOnly) then
        if not frontRan then
          pcall(function()
            local Player = mreq("src.core.game3.player")
            local W = tonumber(canvasW) or 240
            local H = tonumber(canvasH) or 160
            local px, py = tonumber(Player and Player.px), tonumber(Player and Player.py)
            if not (px and py) then return end
            local camX = math.floor(px + CELL / 2 - W / 2) + (FieldView.cameraPanX or 0)
            local camY = math.floor(py + CELL / 2 - H / 2) + (FieldView.cameraPanY or 0)
            run(camX, camY, "after")
          end)
        end
      end
      return unpackN(res, 1)
    end
  end

  -- ------------------------------------------------------ use repel again?

  local function lastRepel()
    local ok, v = pcall(mod.save.get, mod.save, "last_repel")
    if ok and v ~= nil and v ~= "" then return v end
    return nil
  end

  local function rememberRepel(id)
    if id == nil then return end
    pcall(mod.save.set, mod.save, "last_repel", id)
  end

  local function askAgain(sess, onDone)
    local id = lastRepel()
    local Bag = lazy("src.core.game3.bag")
    local bag = sess and sess.bag
    if not (id and Bag and bag and (tonumber(Bag.get(bag, id)) or 0) > 0) then
      return onDone()
    end
    local ItemsData = lazy("src.core.game3.items_data")
    local Message = require("src.ui.game3.message")
    local Choice = require("src.ui.game3.choice")
    local ItemUse = require("src.core.game3.item_use")
    local name = (ItemsData and ItemsData.displayName and ItemsData.displayName(id)) or "REPEL"
    local finished = false
    local function finish()
      if finished then return end
      finished = true
      onDone()
    end
    Message.show("Use another " .. tostring(name) .. "?", function()
      Choice.yesNo(function(yes)
        if yes then
          local ok, _, _, text = pcall(ItemUse.useField, sess, bag, id)
          if ok and ((type(text) == "string" and text ~= "") or type(text) == "table") then
            Message.show(text, function() finish() end)
            return
          end
        end
        Message.close()
        finish()
      end)
    end)
  end

  local function installRepel()
    local ItemUse = require("src.core.game3.item_use")
    local StepEvents = require("src.core.game3.step_events")
    local origUse = ItemUse.useField
    local origStep = StepEvents.onRepelStep
    assert(type(origUse) == "function" and type(origStep) == "function", "repel functions missing")

    ItemUse.useField = function(sess, bag, id, ...)
      local res = pack(origUse(sess, bag, id, ...))
      if res[1] and res[2] == "repel" then rememberRepel(id) end
      return unpackN(res, 1)
    end

    StepEvents.onRepelStep = function(sess, game, ...)
      local queued = StepEvents._queue and #StepEvents._queue or 0
      local res = pack(origStep(sess, game, ...))
      if res[1] and S.get("use_repel_again") == true and type(StepEvents._queue) == "table" then
        for i = #StepEvents._queue, queued + 1, -1 do
          local ev = StepEvents._queue[i]
          if type(ev) == "table" and ev.type == "repel_wore_off" and type(ev.run) == "function"
              and not ev._ph3RepelAgain then
            ev._ph3RepelAgain = true
            local origRun = ev.run
            local s = sess or session()
            ev.run = function(onDone)
              return origRun(function(...)
                local ok = pcall(askAgain, s, function() if onDone then onDone() end end)
                if not ok and onDone then onDone() end
              end)
            end
            break
          end
        end
      end
      return unpackN(res, 1)
    end
  end

  function P.install()
    patch("infinite_safari", installSafari)
    patch("run_everywhere", installRun)
    patch("sparkling_hidden", installSparkles)
    patch("use_repel_again", installRepel)
  end

  return P
end
