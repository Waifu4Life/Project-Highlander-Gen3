-- ANIMATED SPRITES sub-menu.
--
--   BACK ANIMATION         your Pokémon's back animation when it's sent out
--                          (and while looping)
--   FIRE RED & LEAF GREEN  Emerald's Pokémon sprites and animations in FR/LG
--   LOOP ANIMATIONS        OFF / SLOW / MEDIUM / FAST: on the FIGHT/BAG/
--                          POKéMON/RUN menu and the move list, the Pokémon's
--                          animation plays again every 5 / 2.5 / 1.5 s (no cry); it stops as soon as you pick
--                          an action, so turns and move animations are never
--                          held up
--   RUBY & SAPPHIRE        Emerald's Pokémon sprites and animations in R/S
--
-- How: G1R Deluxe's Pokémon animation code is shared by all five games; only
-- Emerald has the data (the motions and each species' second frame). With a
-- toggle on, the other game reads the Pokémon pictures and the animation data
-- from Emerald's own extracted files (nothing is shipped with the mod), so
-- Emerald has to be installed in G1R Deluxe. Deoxys keeps its own game's
-- picture (each game has its own form); Spinda keeps its own spots.
return function(ctx)
  local S = ctx.settings
  local A = { installed = false }

  local function on(key) return S.get(key) == true end
  local function warn(what, err)
    if ctx.mod.log then ctx.mod.log:warn("animated sprites %s: %s", what, tostring(err)) end
  end
  local function req(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
  end

  A.NOTE = "EMERALD NEEDS TO BE INSTALLED FOR RUBY, SAPPHIRE, FIRE RED AND LEAF GREEN"
    .. " TO HAVE ANIMATED SPRITES."

  -- ------------------------------------------------------------- Emerald files

  local function emPrefix()
    local GV = req("src.core.GameVersion")
    local ok, p = pcall(function() return GV.cachePrefix("emerald") end)
    return (ok and type(p) == "string") and p or "emerald/"
  end

  local function emRead(rel)
    local CacheFs = req("src.import.CacheFs")
    if not (CacheFs and CacheFs.readAt) then return nil end
    local ok, bytes = pcall(CacheFs.readAt, emPrefix() .. rel)
    if ok and type(bytes) == "string" and bytes ~= "" then return bytes end
    return nil
  end

  local emCache = {
    read = function(_, rel) return emRead(rel) end,
    exists = function(_, rel) return emRead(rel) ~= nil end,
  }

  local availCache = nil
  function A.emeraldAvailable()
    if availCache ~= nil then return availCache end
    local CacheFs = req("src.import.CacheFs")
    local ok, has = pcall(function()
      return CacheFs.existsAt(emPrefix() .. "data/generated/gba/pokemon/front_anims.lua")
        and CacheFs.existsAt(emPrefix() .. "data/generated/gba/pokemon/front/1.rgba")
    end)
    availCache = ok and has == true
    return availCache
  end

  local function version()
    local ok, v = pcall(S.version)
    return ok and v or nil
  end

  -- this game borrows Emerald's sprites + animations
  function A.borrowing()
    local v = version()
    if v == "ruby" or v == "sapphire" then
      if not on("anim_rs") then return false end
    elseif v == "firered" or v == "leafgreen" then
      if not on("anim_frlg") then return false end
    else
      return false
    end
    return A.emeraldAvailable()
  end

  -- ------------------------------------------------------------- pictures

  local SPECIES_DEOXYS, SPECIES_SPINDA, SPECIES_EGG, SPECIES_CASTFORM = 410, 308, 412, 385
  local pics, picOrder, PIC_CAP = {}, {}, 64

  local function emPic(kind, species, form, shiny)
    species = tonumber(species)
    if not species or species < 1 then return nil end
    if species == SPECIES_DEOXYS or species == SPECIES_SPINDA or species == SPECIES_EGG then return nil end
    form = tonumber(form) or 0
    if species ~= SPECIES_CASTFORM or form < 1 or form > 3 then form = 0 end
    local dir = kind .. (shiny and "_shiny" or "")
    local name = form > 0 and (species .. "_" .. form) or tostring(species)
    local key = dir .. "/" .. name
    local hit = pics[key]
    if hit ~= nil then return hit or nil end
    local rgba = emRead("data/generated/gba/pokemon/" .. dir .. "/" .. name .. ".rgba")
    if type(rgba) ~= "string" or #rgba < 64 * 64 * 4 or not (love and love.image and love.graphics) then
      pics[key] = false
      return nil
    end
    local okI, img = pcall(love.image.newImageData, 64, 64, "rgba8", rgba:sub(1, 64 * 64 * 4))
    if not okI then pics[key] = false return nil end
    local image = love.graphics.newImage(img)
    image:setFilter("nearest", "nearest")
    hit = { image = image, w = 64, h = 64 }
    pics[key] = hit
    picOrder[#picOrder + 1] = key
    if #picOrder > PIC_CAP then
      local old = table.remove(picOrder, 1)
      if pics[old] then pics[old] = nil end
    end
    return hit
  end

  local function installPics()
    local Pokemon = require("src.core.game3.pokemon")
    local origFront, origBack = Pokemon.frontPic, Pokemon.backPic
    Pokemon.frontPic = function(species, form, shiny, personality, ...)
      if A.borrowing() then
        local ok, e = pcall(emPic, "front", species, form, shiny)
        if ok and e then return e end
      end
      return origFront(species, form, shiny, personality, ...)
    end
    Pokemon.frontSprite = Pokemon.frontPic
    Pokemon.backPic = function(species, form, shiny, ...)
      if A.borrowing() then
        local ok, e = pcall(emPic, "back", species, form, shiny)
        if ok and e then return e end
      end
      return origBack(species, form, shiny, ...)
    end
  end

  -- ------------------------------------------------------------- animation data

  local function installData()
    local Data = require("src.core.game3.mon_anim_data")
    local origCache, origGet = Data.cache, Data.get
    local last = nil
    Data.cache = function(...)
      if A.borrowing() then return emCache end
      return origCache(...)
    end
    Data.get = function(...)
      local now = A.borrowing()
      if now ~= last then
        last = now
        pcall(Data.reset)
      end
      return origGet(...)
    end
  end

  -- ------------------------------------------------------------- back animation + loop

  local MAB
  local looping = {} -- [battler id] = { sprite, p, idle }

  -- LOOP ANIMATIONS: OFF / SLOW (every 5 s) / MEDIUM (2.5 s) / FAST (1.5 s)
  A.SPEEDS = {
    { id = "off", label = "OFF", frames = nil },
    { id = "slow", label = "SLOW", frames = 300 },
    { id = "medium", label = "MEDIUM", frames = 150 },
    { id = "fast", label = "FAST", frames = 90 },
  }
  local function speedIndex()
    local v = S.get("anim_loop")
    if v == true then v = "fast" elseif v == false then v = "off" end -- 1.48-1.50 On/Off
    for i, sp in ipairs(A.SPEEDS) do if sp.id == v then return i end end
    return 3
  end
  function A.speedLabel() return A.SPEEDS[speedIndex()].label end
  function A.stepSpeed(dir)
    local i = (speedIndex() - 1 + (dir or 1)) % #A.SPEEDS + 1
    S.set("anim_loop", A.SPEEDS[i].id)
  end
  local function loopFrames() return A.SPEEDS[speedIndex()].frames end

  local function resetPresent(p)
    if not p then return end
    p.ox, p.oy, p.sx, p.sy, p.rotation = 0, 0, 1, 1, 0
    p.invisible, p.monFrame, p.blendCoeff, p.blendColor = nil, 0, nil, nil
  end

  local function stopLoops()
    local MonAnim = req("src.core.game3.mon_anim")
    for id, l in pairs(looping) do
      if l.sprite and MonAnim then
        local active = MAB._active[l.p]
        if active == l.sprite then
          pcall(MonAnim.stop, l.sprite)
          MAB._active[l.p] = nil
          resetPresent(l.p)
        end
      end
      looping[id] = nil
    end
  end

  local function menuIdle()
    -- (mods have no `package` table, so the module comes from require)
    local Ui = req("src.core.game3.battle.ui")
    if not Ui then return false end
    return Ui._mode == "menu" or Ui._mode == "moves"
  end

  local function tickLoops()
    local PAUSE = loopFrames()
    if not PAUSE then
      if next(looping) then stopLoops() end
      return
    end
    local MonAnim = req("src.core.game3.mon_anim")
    if not (MonAnim and MonAnim.enabled()) then return end
    if not menuIdle() then
      if next(looping) then stopLoops() end
      return
    end
    local Anim = req("src.core.game3.battle.anim")
    if not Anim then return end
    for id = 0, 3 do
      local front = (id % 2) == 1
      if front or on("anim_back") then
        local okP, p = pcall(Anim.present, id)
        p = okP and p or nil
        if not p and id < 2 then
          -- same lookup as the game's own mon_anim_battle (side name in singles)
          local State = req("src.core.game3.battle.state")
          local okS, side = pcall(function() return State.sideOf(id) end)
          if okS and side then
            local okQ, q = pcall(Anim.present, side)
            p = okQ and q or nil
          end
        end
        if p and not p.invisible then
          local l = looping[id] or { idle = 0, stale = 0 }
          looping[id] = l
          local cur = MAB._active[p]
          -- a sprite that's stopped or finished doesn't count; one the game
          -- left behind (its task cleared) is given up on after 10 seconds
          local busy = cur ~= nil and not cur.stopped and MonAnim.busy(cur)
          if busy and cur ~= l.sprite then
            l.stale = (l.staleOf == cur) and (l.stale + 1) or 0
            l.staleOf = cur
            if l.stale > 600 then busy = false end
          end
          if busy and cur ~= l.sprite then
            -- the game's own animation (send-out) is still playing
          elseif not busy then
            l.idle = l.idle + 1
            if l.idle >= PAUSE then
              l.idle = 0
              local okS, sprite = pcall(MAB.start, id, front and "front" or "back", { noCry = true })
              if okS and sprite then l.sprite, l.p = sprite, p end
            end
          end
        end
      end
    end
  end

  local function installBattle()
    MAB = require("src.core.game3.battle.mon_anim_battle")
    local origStart = MAB.start
    MAB.start = function(key, kind, opts, ...)
      if kind == "back" and not on("anim_back") then return nil end
      return origStart(key, kind, opts, ...)
    end
    local origReset = MAB.reset
    MAB.reset = function(...)
      looping = {}
      return origReset(...)
    end
    -- every battle frame (the battle's own update, called by the game's
    -- runtime while a battle is active)
    local Battle = require("src.core.game3.battle")
    local origUpdate = Battle.update
    Battle.update = function(...)
      local r = { origUpdate(...) }
      local ok, err = pcall(tickLoops)
      if not ok then warn("loop", err) end
      return (table.unpack or unpack)(r)
    end
  end

  -- ------------------------------------------------------------- note row (scrolls)

  function A.noteRow()
    local start = love and love.timer and love.timer.getTime() or 0
    local row = { id = "ph3_anim_note", value = function() return "" end }
    local text = A.NOTE .. "      "
    return setmetatable(row, {
      __index = function(_, k)
        if k ~= "label" then return nil end
        local t = (love and love.timer and love.timer.getTime() or 0) - start
        -- hold the start for a moment, then move 8 letters a second
        local shift = math.max(0, math.floor((t - 1.5) * 8)) % #text
        local s = text:sub(shift + 1) .. text:sub(1, shift)
        local FrlgFont = req("src.ui.game3.frlg_font")
        local n = #s
        if FrlgFont and FrlgFont.measure then
          n = 1
          -- Ruby/Sapphire's option page starts its labels further right
          local v = version()
          local maxW = (v == "ruby" or v == "sapphire") and 174 or 196
          while n < #s do
            local ok, w = pcall(FrlgFont.measure, s:sub(1, n + 1))
            if not ok or (tonumber(w) or 0) > maxW then break end
            n = n + 1
          end
        else
          n = 32
        end
        return s:sub(1, n)
      end,
    })
  end

  -- ------------------------------------------------------------- install

  local done = {}
  function A.install()
    if A.installed then return end
    local all = true
    for _, s in ipairs({ { "pics", installPics }, { "data", installData }, { "battle", installBattle } }) do
      if not done[s[1]] then
        local ok, err = pcall(s[2])
        if ok then done[s[1]] = true else all = false warn(s[1], err) end
      end
    end
    A.installed = all
  end

  return A
end
