-- Birth Island for Ruby/Sapphire (part of FILL HOENN REGIONAL DEX). Loaded by
-- components/hoenn_all/main.lua, which hands over its helpers in D.
return function(D)
  local ctx = D.ctx
  D.version = D.version or function() return ctx.settings.version() end
  local req = D.req
  local rs = D.rs
  local info = D.info
  local warn = D.warn
  local session = D.session
  local sget = D.sget
  local sset = D.sset
  local mapId = D.mapId
  local objects = D.objects
  local spawnObject = D.spawnObject
  local hideObject = D.hideObject
  local face = D.face
  local ask = D.ask
  local say = D.say
  local cry = D.cry
  local wildBattle = D.wildBattle
  local SP = D.SP
  local gfx = D.gfx
  local on = D.on
  local now = D.now
  local mapLoaded = D.mapLoaded

  -- ================================================================ BIRTH ISLAND (Ruby/Sapphire)
  -- Ruby/Sapphire have no Aurora Ticket and no Birth Island. Both are borrowed
  -- from the player's installed Emerald, read straight from its cache while
  -- needed (nothing of Emerald's is shipped with the mod):
  --   * the AURORA TICKET item (id 371: name, description, Key Items pocket,
  --     its bag icon from Emerald's icon sheet);
  --   * the two Birth Island maps (EM_BIRTH_ISLAND_HARBOR and _EXTERIOR) with
  --     their tilesets, loaded under "em__<pair>" names so they never mix with
  --     Ruby/Sapphire's own pairs of the same name;
  --   * the Deoxys triangle: Emerald's positions, step limits and colours
  --     (rse/event_islands/manifest.lua).
  -- The Lilycove harbor sailor takes you there with the ticket; the sailor on
  -- Birth Island's dock takes you back. The triangle and Deoxys are drawn by
  -- the mod (Deoxys with Wilds of Hoenn's HGSS sheet, assets/sprites).

  local BI = {}
  local AURORA_ID = 371
  local EM_ROOT = "data/generated/gba"
  local BI_SAILOR, BI_ROCK, BI_DEOXYS = 0x75, 0x76, 0x77
  -- Emerald's harbor door (8,2) and the exterior's building door (15,24)
  local HARBOR_ARRIVE = { 8, 4, "up" }
  local HARBOR_SAILOR = { 10, 4 }
  local HARBOR_EXIT = { 8, 3 }         -- walking up onto it leaves the harbor
  local EXT_ARRIVE = { 15, 22, "up" }
  local EXT_ENTER = { 15, 23 }         -- walking down onto it enters the harbor
  local HARBOR_FROM_EXT = { 8, 3, "down" }

  local function emPrefix()
    local GameVersion = req("src.core.GameVersion")
    local ok, p = pcall(GameVersion.cachePrefix, "emerald")
    return ok and p or "emerald/"
  end
  local function emRead(rel)
    local CacheFs = req("src.import.CacheFs")
    if not (CacheFs and CacheFs.readAt) then return nil end
    local ok, b = pcall(CacheFs.readAt, emPrefix() .. rel)
    return ok and type(b) == "string" and b or nil
  end
  local function emExists(rel)
    local CacheFs = req("src.import.CacheFs")
    if not CacheFs then return false end
    if CacheFs.existsAt then
      local ok, v = pcall(CacheFs.existsAt, emPrefix() .. rel)
      if ok then return v == true end
    end
    return emRead(rel) ~= nil
  end
  local function inflate(b)
    if type(b) == "string" and b:byte(1) == 0x78 and love and love.data and love.data.decompress then
      local ok, out = pcall(love.data.decompress, "string", "zlib", b)
      if ok and type(out) == "string" then return out end
    end
    return b
  end
  local function emLua(rel)
    local src = inflate(emRead(rel))
    if not src then return nil end
    local chunk = load(src, "@emerald " .. rel, "t", {})
    if not chunk then return nil end
    local ok, v = pcall(chunk)
    return ok and v or nil
  end

  local availableCache = nil
  function BI.available()
    if not rs() then return false end
    if availableCache == nil then
      availableCache = emExists(EM_ROOT .. "/native/layouts/EM_BIRTH_ISLAND_EXTERIOR.mid")
        and emExists(EM_ROOT .. "/native/layouts/EM_BIRTH_ISLAND_HARBOR.mid")
      info("birth island: Emerald %s", availableCache and "found" or "not installed (no Birth Island in Ruby/Sapphire)")
    end
    return availableCache
  end

  -- ---------------------------------------------------------- the Aurora Ticket item

  local auroraIcon = nil
  local function installTicketItem()
    local ItemsData = req("src.core.game3.items_data")
    if not ItemsData then return false end
    pcall(ItemsData.ensureLoaded)
    local byId = ItemsData._byId
    if type(byId) ~= "table" then return false end
    if byId[AURORA_ID] then return true end
    local pack = emLua(EM_ROOT .. "/items/pack.lua")
    local e = pack and pack.items and pack.items[AURORA_ID]
    local entry = {}
    if type(e) == "table" then for k, v in pairs(e) do entry[k] = v end end
    entry.name = entry.name or "AURORATICKET"
    entry.pocket = entry.pocket or "KEY_ITEMS"
    entry.fieldUse = entry.fieldUse or "key"
    entry.price = 0
    entry.importance = entry.importance or 1
    entry.description = entry.description or "A ticket required\nto board the ship\nto BIRTH ISLAND."
    entry.itemId = AURORA_ID
    -- no Emerald function pointers in Ruby/Sapphire's item code
    entry.fieldUseFunc, entry.battleUseFunc = nil, nil
    entry.fieldUseName = "ItemUseOutOfBattle_CannotUse"
    byId[AURORA_ID] = entry
    if ItemsData._byName then ItemsData._byName["AURORATICKET"] = AURORA_ID; ItemsData._byName["AURORA_TICKET"] = AURORA_ID end
    return true
  end

  local function auroraImage()
    if auroraIcon == nil then
      auroraIcon = false
      local man = emLua(EM_ROOT .. "/rse/bag/manifest.lua")
      local ic = man and man.icons
      local raw = ic and inflate(emRead(ic.rgba or (EM_ROOT .. "/rse/bag/icons.rgba")))
      local w = ic and tonumber(ic.w) or 24
      if raw and #raw >= (AURORA_ID + 1) * 24 * w * 4 then
        local ok, img = pcall(function()
          local data = love.image.newImageData(w, 24, "rgba8", raw:sub(AURORA_ID * 24 * w * 4 + 1, (AURORA_ID + 1) * 24 * w * 4))
          local im = love.graphics.newImage(data)
          im:setFilter("nearest", "nearest")
          return im
        end)
        if ok then auroraIcon = img else warn("aurora icon", img) end
      end
    end
    return auroraIcon or nil
  end

  local function installTicketIcon()
    local BagChrome = req("src.ui.game3.rse.bag_chrome")
    if not (BagChrome and BagChrome.drawItemIcon) or BagChrome._ph3Aurora then return end
    BagChrome._ph3Aurora = true
    local orig = BagChrome.drawItemIcon
    BagChrome.drawItemIcon = function(index, x, y, rotation, ox, oy, ...)
      if rs() and tonumber(index) == AURORA_ID then
        local img = auroraImage()
        if img then
          love.graphics.setColor(1, 1, 1, 1)
          love.graphics.draw(img, x, y, rotation or 0, 1, 1, ox or 0, oy or 0)
          return
        end
      end
      return orig(index, x, y, rotation, ox, oy, ...)
    end
  end

  function BI.hasTicket()
    local sess, Bag = session(), req("src.core.game3.bag")
    if not (sess and sess.bag and Bag) then return false end
    local ok, v = pcall(Bag.has, sess.bag, AURORA_ID, 1)
    return ok and v == true
  end

  function BI.giveTicket()
    if not installTicketItem() then return false end
    local sess, Bag = session(), req("src.core.game3.bag")
    if not (sess and sess.bag and Bag) then return false end
    local ok, v = pcall(Bag.add, sess.bag, AURORA_ID, 1)
    return ok and v ~= false
  end

  -- ---------------------------------------------------------- the maps

  local ids, idsFor = nil, nil
  local function mapIds()
    if ids and idsFor == D.version() then return ids end
    idsFor = D.version()
    local game = (req("src.core.game3.runtime") or {})._game
    local maps = game and game.data and game.data.maps
    local prefix
    for k in pairs(maps or {}) do
      local p = tostring(k):match("^(%u+_)SOUTHERN_ISLAND_EXTERIOR$")
      if p then prefix = p break end
    end
    prefix = prefix or (mapId():match("^(%u+_)") or "RU_")
    ids = { ext = prefix .. "BIRTH_ISLAND_EXTERIOR", harbor = prefix .. "BIRTH_ISLAND_HARBOR",
      lilycove = prefix .. "LILYCOVE_CITY_HARBOR", southern = prefix .. "SOUTHERN_ISLAND_EXTERIOR" }
    return ids
  end
  function BI.isExterior(m) return BI.available() and (m or mapId()) == mapIds().ext end
  function BI.isHarbor(m) return BI.available() and (m or mapId()) == mapIds().harbor end
  function BI.isOurs(m) return BI.isExterior(m) or BI.isHarbor(m) end

  -- reads of "native/em__<pair>/..." come from Emerald's "native/<pair>/..."
  local function emRel(rel)
    if type(rel) ~= "string" then return nil end
    local a, b = rel:match("^(.-/native/)em__(.*)$")
    return a and (a .. b) or nil
  end
  local function patchCache(cache)
    if type(cache) ~= "table" or rawget(cache, "_ph3Emerald") then return end
    rawset(cache, "_ph3Emerald", true)
    local oRead, oExists, oSpec, oWrite = cache.read, cache.exists, cache.assetWorkerSpec, cache.write
    cache.read = function(self, rel, ...)
      local r = emRel(rel)
      if r then return emRead(r) end
      return oRead and oRead(self, rel, ...) or nil
    end
    if oExists then
      cache.exists = function(self, rel, ...)
        local r = emRel(rel)
        if r then return emExists(r) end
        return oExists(self, rel, ...)
      end
    end
    if oSpec then
      -- no worker thread for Emerald's pairs: they decode on the main thread
      cache.assetWorkerSpec = function(self, root, kind, key, ...)
        if tostring(key):find("^em__") then return nil end
        return oSpec(self, root, kind, key, ...)
      end
    end
    if oWrite then
      cache.write = function(self, rel, ...)
        if emRel(rel) then return false end
        return oWrite(self, rel, ...)
      end
    end
  end
  local function patchCaches()
    local NT = req("src.core.game3.tileset_native")
    if NT then patchCache(NT._cache) end
    local Dataset = req("src.core.game3.dataset")
    if Dataset and Dataset.cache then
      local ok, c = pcall(Dataset.cache)
      if ok then patchCache(c) end
    end
  end

  local MAP_FIELDS = { "music", "weather", "mapType", "kind", "environment", "cave", "allowEscaping",
    "allowRunning", "bikingAllowed", "battleType", "floorNum", "regionMapSectionId", "tileset" }
  local function buildDef(game, id, file, pair, template)
    local NativePack = req("src.import.gba.native_pack")
    local LayoutNative = req("src.core.game3.layout_native")
    if not (NativePack and LayoutNative) then return nil end
    local blob = inflate(emRead(EM_ROOT .. "/native/layouts/" .. file))
    local decoded = blob and NativePack.decodeMidLayout(blob)
    if not decoded then warn("birth island", "could not read Emerald's " .. file) return nil end
    local pairName = "em__" .. pair
    local t = game.data.maps[template] or {}
    local def = {}
    for _, k in ipairs(MAP_FIELDS) do def[k] = t[k] end
    def.id, def.name = id, id
    def.width, def.height = decoded.width, decoded.height
    def.pair = pairName
    def.midLayout = LayoutNative.fromDecoded(decoded, id, pairName, blob)
    def.warps, def.connections, def.objects, def.bgEvents, def.coordEvents = {}, {}, {}, {}, {}
    def.showMapName = 0
    def.allowEscaping = 0
    def.native = true
    def.ph3BirthIsland = true
    -- behaviours: the exterior uses General + Dewford metatiles, which Ruby/Sapphire share
    local IS = req("src.core.game3.scripting.interaction_scripts")
    if IS and IS.behaviors and IS.behaviors[pairName] == nil then
      IS.behaviors[pairName] = (pair == "general__dewford" and IS.behaviors["general__dewford"]) or {}
    end
    return def
  end

  function BI.ensureMaps(game)
    if not BI.available() then return false end
    game = game or (req("src.core.game3.runtime") or {})._game
    if not (game and game.data and game.data.maps) then return false end
    patchCaches()
    local m = mapIds()
    local maps = game.data.maps
    if not maps[m.ext] then
      maps[m.ext] = buildDef(game, m.ext, "EM_BIRTH_ISLAND_EXTERIOR.mid", "general__dewford", m.southern)
    end
    if not maps[m.harbor] then
      maps[m.harbor] = buildDef(game, m.harbor, "EM_BIRTH_ISLAND_HARBOR.mid", "general__island_harbor", m.lilycove)
    end
    return maps[m.ext] ~= nil and maps[m.harbor] ~= nil
  end

  local function warpTo(map, x, y, facing, onDone)
    local Runtime = req("src.core.game3.runtime")
    local Warp = req("src.core.game3.warp")
    if not (Runtime and Warp) then return false end
    local game = Runtime._game
    if BI.isOurs(map) and not BI.ensureMaps(game) then return false end
    local ok, err = pcall(Warp.scripted, Runtime._mod, game, "warp", map, x, y, facing or "down", onDone)
    if not ok then warn("birth island warp", err) end
    return ok
  end

  -- ---------------------------------------------------------- the ferry

  function BI.talkFerry(eo, fallback)
    if not (BI.available() and BI.hasTicket()) then return false end
    face(eo)
    ask("Ah! That's an AURORA TICKET!\fWould you like to sail to BIRTH ISLAND?", function(yes)
      if not yes then
        if fallback then fallback() else say("Please sail with us another time.") end
        return
      end
      if not BI.ensureMaps() then say("...The ship can't find the way to BIRTH ISLAND.") return end
      local sess = session() or {}
      sset("hgk_bi_from", { map = sess.map, x = sess.x, y = sess.y })
      say("All right! All aboard!", function()
        pcall(function() require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").SE_SHIP) end)
        warpTo(mapIds().harbor, HARBOR_ARRIVE[1], HARBOR_ARRIVE[2], HARBOR_ARRIVE[3])
      end)
    end)
    return true
  end

  local function talkHarborSailor(eo)
    face(eo)
    ask("Would you like to sail back to LILYCOVE CITY?", function(yes)
      if not yes then say("I'll be here when you want to go back.") return end
      local from = sget("hgk_bi_from")
      local map = type(from) == "table" and from.map or mapIds().lilycove
      local x, y = type(from) == "table" and tonumber(from.x) or 8, type(from) == "table" and tonumber(from.y) or 4
      pcall(function() require("src.core.game3.audio").playSe(require("src.core.game3.se_ids").SE_SHIP) end)
      warpTo(map, x, y, "down")
    end)
    return true
  end

  -- ---------------------------------------------------------- the triangle and Deoxys

  local ROCK_COORDS = { { 15, 12 }, { 11, 14 }, { 15, 8 }, { 19, 14 }, { 12, 11 }, { 18, 11 },
    { 15, 14 }, { 11, 14 }, { 19, 14 }, { 15, 15 }, { 15, 10 } }
  local ROCK_STEPS = { 4, 8, 8, 8, 4, 4, 4, 6, 3, 3 }
  local ROCK_PALS = nil -- [level+1] = { {r,g,b} x 5 }, from Emerald
  local rock = { level = 0, steps = 0, lastX = nil, lastY = nil }

  local function loadRockData()
    if ROCK_PALS ~= nil then return end
    ROCK_PALS = false
    local man = emLua(EM_ROOT .. "/rse/event_islands/manifest.lua")
    if type(man) ~= "table" then return end
    if type(man.deoxysRockCoords) == "table" and #man.deoxysRockCoords == 11 then ROCK_COORDS = man.deoxysRockCoords end
    if type(man.deoxysRockMaxSteps) == "table" and #man.deoxysRockMaxSteps == 10 then ROCK_STEPS = man.deoxysRockMaxSteps end
    if type(man.deoxysRockPalettes) == "table" then
      local pals = {}
      for i, pal in ipairs(man.deoxysRockPalettes) do
        local row = {}
        for c = 1, 5 do
          local v = tonumber(pal[c]) or 0
          row[c] = { (v % 32) / 31, (math.floor(v / 32) % 32) / 31, (math.floor(v / 1024) % 32) / 31 }
        end
        pals[i] = row
      end
      ROCK_PALS = pals
    end
  end

  local FALLBACK_PAL = { nil, { 0.55, 0.55, 0.55 }, { 0.32, 0.32, 0.32 }, { 0.13, 0.13, 0.13 }, { 0.05, 0.05, 0.05 } }
  local function drawRock(a, camX, camY)
    loadRockData()
    local pal = (ROCK_PALS and ROCK_PALS[rock.level + 1]) or FALLBACK_PAL
    local light, mid, dark, line = pal[2] or FALLBACK_PAL[2], pal[3] or FALLBACK_PAL[3], pal[4] or FALLBACK_PAL[4], pal[5] or FALLBACK_PAL[5]
    -- a 32x32 triangle standing on its cell, like Emerald's
    local x = math.floor((a.x or 0) - (camX or 0)) - 8
    local y = math.floor((a.y or 0) - (camY or 0)) - 16
    local ax, ay, bx, by, cx, cy = x + 16, y + 3, x + 2, y + 30, x + 30, y + 30
    love.graphics.setColor(line[1], line[2], line[3], 1)
    love.graphics.polygon("fill", ax, ay - 1, bx - 1, by + 1, cx + 1, cy + 1)
    love.graphics.setColor(mid[1], mid[2], mid[3], 1)
    love.graphics.polygon("fill", ax, ay + 1, bx + 1, by, cx - 1, cy)
    love.graphics.setColor(light[1], light[2], light[3], 1)
    love.graphics.polygon("fill", ax, ay + 1, bx + 1, by, x + 16, y + 30)
    love.graphics.setColor(dark[1], dark[2], dark[3], 1)
    love.graphics.polygon("fill", x + 16, y + 30, cx - 1, cy, x + 16, y + 20)
    love.graphics.setColor(1, 1, 1, 1)
  end

  local deoxysImg, deoxysQuads = nil, nil
  local function drawDeoxys(a, camX, camY)
    if deoxysImg == nil then
      deoxysImg = false
      local ok, img = pcall(function() return ctx.mod.assets:image("assets/sprites/deoxys.png") end)
      if ok and img then
        deoxysImg = img
        if img.setFilter then pcall(img.setFilter, img, "nearest", "nearest") end
        local iw, ih = img:getDimensions()
        deoxysQuads = {}
        for i = 0, 17 do deoxysQuads[i] = love.graphics.newQuad(0, i * 32, 32, 32, iw, ih) end
      end
    end
    if not deoxysImg then return end
    local bob = math.floor(math.sin(now() * 3) * 1.5 + 0.5)
    local x = math.floor((a.x or 0) - (camX or 0)) - 8
    local y = math.floor((a.y or 0) - (camY or 0)) - 16 - 2 + bob
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(deoxysImg, deoxysQuads[0], x, y)
  end

  local function dress(eo, fn)
    if not eo then return end
    eo.foreign = eo.foreign or { ph3BirthIsland = true }
    eo.draw = fn
  end

  local function deoxysGone() return sget("hgk_deoxys_done") == true end

  local function placeRock(level)
    local O = objects()
    local eo = O and O._byId[BI_ROCK]
    if not eo then return end
    local c = ROCK_COORDS[level + 1] or ROCK_COORDS[1]
    eo.cellX, eo.cellY = c[1], c[2]
    eo.px, eo.py = c[1] * 16, c[2] * 16
    if eo.def then eo.def.x, eo.def.y = c[1], c[2] end
  end

  local function se(name)
    pcall(function() require("src.core.game3.audio").playSe(require("src.core.game3.se_ids")[name]) end)
  end

  local function spawnDeoxys()
    local O = objects()
    if not O or O._byId[BI_DEOXYS] then return O and O._byId[BI_DEOXYS] end
    local c = ROCK_COORDS[11]
    local eo = spawnObject(BI_DEOXYS, c[1], c[2], gfx("ITEM_BALL"), 8)
    dress(eo, drawDeoxys)
    return eo
  end

  local function battleDeoxys(eo)
    local sp = SP("DEOXYS")
    cry(sp)
    wildBattle(sp, 30, function(got)
      if got then
        sset("hgk_deoxys_done", true)
        hideObject(eo)
      elseif not on("hoenn_limited") then
        sset("hgk_deoxys_done", true) -- one try only
        hideObject(eo)
      end
    end)
  end

  local function talkRock(eo)
    loadRockData()
    local steps = rock.steps
    rock.steps = 0
    if rock.level ~= 0 and steps > (tonumber(ROCK_STEPS[rock.level]) or 0) then
      -- not the shortest way: the triangle goes back to where it started
      rock.level = 0
      se("SE_M_DETECT")
      placeRock(0)
      return true
    end
    if rock.level == #ROCK_COORDS - 1 then
      -- solved: the triangle shatters and Deoxys appears
      sset("hgk_deoxys_awake", true)
      se("SE_M_EXPLOSION")
      hideObject(eo)
      local dx = spawnDeoxys()
      if dx then battleDeoxys(dx) end
      return true
    end
    rock.level = rock.level + 1
    se("SE_M_DETECT")
    placeRock(rock.level)
    return true
  end

  -- ---------------------------------------------------------- per frame / per tick

  local enteredFor = nil
  function BI.tick()
    if not BI.isOurs() then enteredFor = nil return end
    local O = objects()
    if not (O and mapLoaded()) then return end
    local map = mapId()
    if enteredFor ~= map then
      enteredFor = map
      rock.level, rock.steps = 0, 0
      local P = req("src.core.game3.player")
      rock.lastX, rock.lastY = P and P.cellX, P and P.cellY
    end
    if BI.isHarbor() then
      if not O._byId[BI_SAILOR] then
        local eo = spawnObject(BI_SAILOR, HARBOR_SAILOR[1], HARBOR_SAILOR[2], gfx("SAILOR"), 10)
        if eo then eo.facing = "left" end
      end
      return
    end
    -- exterior
    if deoxysGone() then return end
    if sget("hgk_deoxys_awake") then
      local eo = spawnDeoxys()
      if eo then dress(eo, drawDeoxys) end
    elseif not O._byId[BI_ROCK] then
      local c = ROCK_COORDS[1]
      dress(spawnObject(BI_ROCK, c[1], c[2], gfx("ITEM_BALL"), 8), drawRock)
    else
      dress(O._byId[BI_ROCK], drawRock)
    end
  end

  -- every frame: count steps (triangle) and walk through the island's doors
  function BI.frame()
    if not BI.isOurs() then return end
    local P = req("src.core.game3.player")
    local Warp = req("src.core.game3.warp")
    if not P or P.moving or (Warp and Warp.isBusy and Warp.isBusy()) then return end
    local x, y = P.cellX, P.cellY
    if x == rock.lastX and y == rock.lastY then return end
    rock.lastX, rock.lastY = x, y
    rock.steps = rock.steps + 1
    if BI.isExterior() and x == EXT_ENTER[1] and y == EXT_ENTER[2] and P.facing == "down" then
      se("SE_DOOR")
      warpTo(mapIds().harbor, HARBOR_FROM_EXT[1], HARBOR_FROM_EXT[2], HARBOR_FROM_EXT[3])
    elseif BI.isHarbor() and x == HARBOR_EXIT[1] and y == HARBOR_EXIT[2] and P.facing == "up" then
      se("SE_DOOR")
      warpTo(mapIds().ext, EXT_ARRIVE[1], EXT_ARRIVE[2], EXT_ARRIVE[3])
    end
  end

  function BI.talk(eo)
    if not BI.isOurs() or not eo then return false end
    local lid = eo.localId
    if lid == BI_SAILOR then return talkHarborSailor(eo) end
    if lid == BI_ROCK then return talkRock(eo) end
    if lid == BI_DEOXYS then battleDeoxys(eo) return true end
    return false
  end

  function BI.install()
    if BI.installed then return end
    BI.installed = true
    -- Birth Island exists before any map load (a save made on the island)
    local Map = require("src.core.game3.map")
    local origLoad = Map.load
    Map.load = function(mod, game, id, ...)
      if rs() and type(id) == "string" and id:find("BIRTH_ISLAND_", 1, true) then
        local ok, err = pcall(BI.ensureMaps, game)
        if not ok then warn("birth island maps", err) end
      end
      return origLoad(mod, game, id, ...)
    end
    local NT = require("src.core.game3.tileset_native")
    local origInstall = NT.install
    NT.install = function(...)
      local r = { origInstall(...) }
      pcall(patchCaches)
      return (table.unpack or unpack)(r)
    end
    pcall(patchCaches)
    installTicketIcon()
  end

  return BI
end
