-- JUKEBOX (all five games)
--
-- Each game's background music has its own On/Off row (sub-menu JUKEBOX,
-- alphabetical, ALL SONGS on top; every song On by default). The songs that
-- are On make the playlist, in the menu's order.
--
-- FULL CONTROL > JUKEBOX BUTTON (no key or pad by default), in the overworld,
-- held with a direction (the button alone does nothing; while it's held the
-- player stays put and the directions only work the Jukebox):
--   + UP     play the playlist (from the song it was on last)
--   + DOWN   stop it: back to the game's own music
--   + LEFT   previous song (from the first, the last)
--   + RIGHT  next song (from the last, the first)
-- LEFT / RIGHT do nothing while the playlist isn't playing.
--
-- While a Jukebox song plays, it replaces the area music everywhere (new
-- maps, Surf, Bicycle) until the button goes back to the game's music.
-- Battles, evolutions, trainer encounters, scripted events and jingles keep
-- the game's music; when they end, the Jukebox song comes back instead of
-- the area's. A short note shows the song's name when it changes.
return function(ctx)
  local S = ctx.settings
  local J = { installed = false, active = false, pos = 0, song = nil }

  local function req(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
    return nil
  end
  local function now() return (love and love.timer and love.timer.getTime()) or os.clock() end

  -- ------------------------------------------------------------- song lists
  -- Constant name (without MUS_) -> menu name. A name the running game
  -- doesn't have is skipped, so one list serves Ruby, Sapphire and Emerald.
  -- Jingles (item, badge, heal, level up, caught...) aren't listed.
  local KANTO = {
    BERRY_PICK = "BERRY PICKING", CELADON = "CELADON CITY", CINNABAR = "CINNABAR ISLAND",
    CYCLING = "BICYCLE", ENCOUNTER_BOY = "ENCOUNTER: BOY", ENCOUNTER_DEOXYS = "ENCOUNTER: DEOXYS",
    ENCOUNTER_GIRL = "ENCOUNTER: GIRL", ENCOUNTER_GYM_LEADER = "ENCOUNTER: GYM LEADER",
    ENCOUNTER_RIVAL = "ENCOUNTER: RIVAL", ENCOUNTER_ROCKET = "ENCOUNTER: ROCKET",
    FOLLOW_ME = "FOLLOW ME", FUCHSIA = "FUCHSIA CITY", GAME_CORNER = "GAME CORNER", GYM = "GYM",
    HALL_OF_FAME = "HALL OF FAME", LAVENDER = "LAVENDER TOWN", MT_MOON = "MT. MOON",
    MYSTERY_GIFT = "MYSTERY GIFT", NET_CENTER = "NET CENTER", NEW_GAME_INSTRUCT = "OAK'S SPEECH",
    OAK = "PROF. OAK", OAK_LAB = "OAK'S LAB", PALLET = "PALLET TOWN", PEWTER = "PEWTER CITY",
    POKE_CENTER = "POKéMON CENTER", POKE_JUMP = "POKéMON JUMP", POKE_MANSION = "POKéMON MANSION",
    POKE_TOWER = "POKéMON TOWER", ROCKET_HIDEOUT = "ROCKET HIDEOUT", ROUTE1 = "ROUTE 1",
    ROUTE3 = "ROUTE 3", ROUTE11 = "ROUTE 11", ROUTE24 = "ROUTE 24", SCHOOL = "TRAINER TIPS",
    SEVII_123 = "ISLANDS 1, 2 & 3", SEVII_45 = "ISLANDS 4 & 5", SEVII_67 = "ISLANDS 6 & 7",
    SEVII_CAVE = "SEVII CAVE", SEVII_DUNGEON = "SEVII DUNGEON", SEVII_ROUTE = "SEVII ROUTE",
    SILPH = "SILPH CO.", SLOW_PALLET = "PALLET TOWN (SLOW)", SS_ANNE = "S.S. ANNE", SURF = "SURF",
    TEACHY_TV_SHOW = "TEACHY TV", TITLE = "TITLE SCREEN", TRAINER_TOWER = "TRAINER TOWER",
    UNION_ROOM = "UNION ROOM", VERMILLION = "VERMILION CITY", VICTORY_GYM_LEADER = "VICTORY: GYM LEADER",
    VICTORY_ROAD = "VICTORY ROAD", VICTORY_TRAINER = "VICTORY: TRAINER", VICTORY_WILD = "VICTORY: WILD",
    VIRIDIAN_FOREST = "VIRIDIAN FOREST", VS_CHAMPION = "BATTLE: CHAMPION", VS_DEOXYS = "BATTLE: DEOXYS",
    VS_GYM_LEADER = "BATTLE: GYM LEADER", VS_LEGEND = "BATTLE: LEGENDARY", VS_MEWTWO = "BATTLE: MEWTWO",
    VS_TRAINER = "BATTLE: TRAINER", VS_WILD = "BATTLE: WILD",
  }
  local HOENN = {
    ABANDONED_SHIP = "ABANDONED SHIP", ABNORMAL_WEATHER = "ABNORMAL WEATHER",
    AQUA_MAGMA_HIDEOUT = "TEAM HIDEOUT", AWAKEN_LEGEND = "LEGEND AWAKENS", BIRCH_LAB = "BIRCH'S LAB",
    B_ARENA = "BATTLE ARENA", B_DOME = "BATTLE DOME", B_DOME_LOBBY = "BATTLE DOME LOBBY",
    B_FACTORY = "BATTLE FACTORY", B_FRONTIER = "BATTLE FRONTIER", B_PALACE = "BATTLE PALACE",
    B_PIKE = "BATTLE PIKE", B_PYRAMID = "BATTLE PYRAMID", B_PYRAMID_TOP = "BATTLE PYRAMID TOP",
    B_TOWER = "BATTLE TOWER", B_TOWER_RS = "BATTLE TOWER (R/S)", CABLE_CAR = "CABLE CAR",
    CAVE_OF_ORIGIN = "CAVE OF ORIGIN", CONTEST = "CONTEST", CONTEST_LOBBY = "CONTEST LOBBY",
    CONTEST_RESULTS = "CONTEST RESULTS", CYCLING = "BICYCLE", C_VS_LEGEND_BEAST = "BATTLE: LEGENDARY BEAST",
    DESERT = "DESERT", DEWFORD = "DEWFORD TOWN", ENCOUNTER_AQUA = "ENCOUNTER: AQUA",
    ENCOUNTER_BRENDAN = "ENCOUNTER: BRENDAN", ENCOUNTER_CHAMPION = "ENCOUNTER: CHAMPION",
    ENCOUNTER_COOL = "ENCOUNTER: COOL", ENCOUNTER_ELITE_FOUR = "ENCOUNTER: ELITE FOUR",
    ENCOUNTER_FEMALE = "ENCOUNTER: FEMALE", ENCOUNTER_GIRL = "ENCOUNTER: GIRL",
    ENCOUNTER_HIKER = "ENCOUNTER: HIKER", ENCOUNTER_INTENSE = "ENCOUNTER: INTENSE",
    ENCOUNTER_INTERVIEWER = "ENCOUNTER: INTERVIEWER", ENCOUNTER_MAGMA = "ENCOUNTER: MAGMA",
    ENCOUNTER_MALE = "ENCOUNTER: MALE", ENCOUNTER_MAY = "ENCOUNTER: MAY", ENCOUNTER_RICH = "ENCOUNTER: RICH",
    ENCOUNTER_SUSPICIOUS = "ENCOUNTER: SUSPICIOUS", ENCOUNTER_SWIMMER = "ENCOUNTER: SWIMMER",
    ENCOUNTER_TWINS = "ENCOUNTER: TWINS", EVER_GRANDE = "EVER GRANDE CITY", FALLARBOR = "FALLARBOR TOWN",
    FOLLOW_ME = "FOLLOW ME", FORTREE = "FORTREE CITY", GAME_CORNER = "GAME CORNER", GYM = "GYM",
    HALL_OF_FAME = "HALL OF FAME", HALL_OF_FAME_ROOM = "HALL OF FAME ROOM", HELP = "HELP!",
    LILYCOVE = "LILYCOVE CITY", LILYCOVE_MUSEUM = "LILYCOVE MUSEUM", LITTLEROOT = "LITTLEROOT TOWN",
    MT_CHIMNEY = "MT. CHIMNEY", MT_PYRE = "MT. PYRE", MT_PYRE_EXTERIOR = "MT. PYRE OUTSIDE",
    OCEANIC_MUSEUM = "OCEANIC MUSEUM", OLDALE = "OLDALE TOWN", PETALBURG = "PETALBURG CITY",
    PETALBURG_WOODS = "PETALBURG WOODS", POKE_CENTER = "POKéMON CENTER", POKE_MART = "POKé MART",
    RAYQUAZA_APPEARS = "RAYQUAZA APPEARS", ROULETTE = "ROULETTE", ROUTE101 = "ROUTE 101",
    ROUTE104 = "ROUTE 104", ROUTE110 = "ROUTE 110", ROUTE111 = "ROUTE 111", ROUTE113 = "ROUTE 113",
    ROUTE118 = "ROUTE 118", ROUTE_118 = "ROUTE 118", ROUTE119 = "ROUTE 119", ROUTE120 = "ROUTE 120",
    ROUTE122 = "ROUTE 122", RUSTBORO = "RUSTBORO CITY", SAFARI_ZONE = "SAFARI ZONE", SAILING = "SAILING",
    SCHOOL = "TRAINER'S SCHOOL", SEALED_CHAMBER = "SEALED CHAMBER", SLATEPORT = "SLATEPORT CITY",
    SOOTOPOLIS = "SOOTOPOLIS CITY", SURF = "SURF", TITLE = "TITLE SCREEN", TRICK_HOUSE = "TRICK HOUSE",
    UNDERWATER = "UNDERWATER", VERDANTURF = "VERDANTURF TOWN", VICTORY_AQUA_MAGMA = "VICTORY: TEAM",
    VICTORY_GYM_LEADER = "VICTORY: GYM LEADER", VICTORY_LEAGUE = "VICTORY: LEAGUE",
    VICTORY_ROAD = "VICTORY ROAD", VICTORY_TRAINER = "VICTORY: TRAINER", VICTORY_WILD = "VICTORY: WILD",
    VS_AQUA_MAGMA = "BATTLE: TEAM", VS_AQUA_MAGMA_LEADER = "BATTLE: TEAM LEADER",
    VS_CHAMPION = "BATTLE: CHAMPION", VS_ELITE_FOUR = "BATTLE: ELITE FOUR",
    VS_FRONTIER_BRAIN = "BATTLE: FRONTIER BRAIN", VS_GYM_LEADER = "BATTLE: GYM LEADER",
    VS_KYOGRE_GROUDON = "BATTLE: KYOGRE/GROUDON", VS_MEW = "BATTLE: MEW", VS_RAYQUAZA = "BATTLE: RAYQUAZA",
    VS_REGI = "BATTLE: REGI", VS_RIVAL = "BATTLE: RIVAL", VS_TRAINER = "BATTLE: TRAINER",
    VS_WILD = "BATTLE: WILD", WEATHER_GROUDON = "DROUGHT", WEATHER_KYOGRE = "HEAVY RAIN",
  }

  local function Audio() return req("src.core.game3.audio") end

  local function songTable()
    local A = Audio()
    if not (A and A.songs) then return {} end
    local ok, t = pcall(A.songs)
    return (ok and type(t) == "table") and t or {}
  end

  local listCache = {}
  -- this game's songs: { name = "MUS_...", label = "...", id = n }, A-Z by label
  function J.list()
    local v = S.version()
    if listCache[v] and #listCache[v] > 0 then return listCache[v] end
    local names = S.isHoenn() and HOENN or KANTO
    local A = Audio()
    local packed = A and A._pack ~= nil
    local indexed = packed and type(A._pack.index) == "table" and type(A._pack.index.songs) == "table"
    local songs, out, seenId = songTable(), {}, {}
    for short, label in pairs(names) do
      local name = "MUS_" .. short
      local id = tonumber(songs[name])
      local usable = id and id > 0 and id < 0x7FFF and not seenId[id]
      -- with the sound data loaded: only songs it really has, no jingles
      if usable and indexed and A.songInfo then
        local ok, info = pcall(A.songInfo, id)
        if ok and info == nil then usable = false end
        if ok and type(info) == "table" and info.kind == "fanfare" then usable = false end
      end
      if usable then
        seenId[id] = true
        out[#out + 1] = { name = name, label = label, id = id }
      end
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    if packed then listCache[v] = out end
    return out
  end

  local function key(name) return "jb_" .. S.version() .. "_" .. name end
  function J.isOn(name) return S.flag(key(name)) end
  function J.toggle(name) S.set(key(name), not J.isOn(name)) end

  function J.allLabel()
    local on, off = 0, 0
    for _, s in ipairs(J.list()) do
      if J.isOn(s.name) then on = on + 1 else off = off + 1 end
    end
    if off == 0 then return "ON" end
    if on == 0 then return "OFF" end
    return "SOME"
  end
  -- any song On: all Off; else all On
  function J.toggleAll()
    local value = J.allLabel() == "OFF"
    local values = {}
    for _, s in ipairs(J.list()) do values[key(s.name)] = value end
    if S.setMany then S.setMany(values) else for k, v in pairs(values) do S.set(k, v) end end
  end

  local function playlist()
    local out = {}
    for _, s in ipairs(J.list()) do
      if J.isOn(s.name) then out[#out + 1] = s end
    end
    return out
  end

  -- ------------------------------------------------------------- note on screen

  local note = nil -- { text, untilT }
  local NOTE_TIME = 2.5
  local function showNote(text) note = { text = text, untilT = now() + NOTE_TIME } end

  local function drawNote()
    if not note then return end
    if now() > note.untilT then note = nil return end
    local FrlgFont = req("src.ui.game3.frlg_font")
    if not FrlgFont then return end
    local pal = ctx.themes.resolve(S.themeChoice(), S.version())
    local o = { small = true, maxWidth = 200,
      colors = { fg = { 1, 1, 1, 1 }, shadow = { pal.dark[1], pal.dark[2], pal.dark[3], 1 } } }
    local okW, w = pcall(FrlgFont.measure, note.text, o)
    w = (okW and tonumber(w)) or #note.text * 5
    local rs = S.version() == "ruby" or S.version() == "sapphire"
    local x, y, bw, bh = 4, 4, w + 10, 13
    love.graphics.push("all")
    love.graphics.setColor(pal.dark[1], pal.dark[2], pal.dark[3], 1)
    love.graphics.rectangle("fill", x, y, bw, bh, 3, 3)
    love.graphics.setColor(pal.main[1], pal.main[2], pal.main[3], 1)
    love.graphics.rectangle("fill", x + 1, y + 1, bw - 2, bh - 2, 2, 2)
    love.graphics.pop()
    pcall(FrlgFont.draw, note.text, x + 5, y - (rs and 6 or 1), o)
  end

  -- ------------------------------------------------------------- playing

  -- same tests the game runs before the field takes a button
  local function fieldFree()
    local Runtime = req("src.core.game3.runtime")
    if Runtime and Runtime.active == false then return false end
    if Runtime and Runtime.uiBusy then
      local ok, busy = pcall(Runtime.uiBusy)
      if ok and busy then return false end
    end
    local Field = req("src.core.game3.field")
    if Field and (Field.locked or (Field.isLocked and Field.isLocked())) then return false end
    return true
  end

  local function areaSong()
    local A = Audio()
    if not A then return nil end
    local ok, id = pcall(A.specialMapSong)
    return (ok and id) or A._mapSong
  end

  local function playAt(list, pos)
    local s = list[pos]
    J.active, J.pos, J.song = true, pos, s.id
    local A = Audio()
    if A then pcall(A.fadeOutAndPlay, s.id, 4) end
    showNote("JUKEBOX: " .. s.label)
  end

  -- UP: play (from the song it was on last); already playing: show its name
  function J.play()
    local list = playlist()
    if #list == 0 then showNote("JUKEBOX: NO SONG IS ON") return end
    if J.active then
      local s = list[J.pos]
      if s then showNote("JUKEBOX: " .. s.label) end
      return
    end
    local pos = (J.pos >= 1 and J.pos <= #list) and J.pos or 1
    playAt(list, pos)
  end

  -- DOWN: back to the game's own music (the place in the playlist is kept)
  function J.stop()
    if not J.active then return end
    J.active, J.song = false, nil
    local A, id = Audio(), areaSong()
    if A and id then pcall(A.fadeOutAndPlay, id, 4) end
    showNote("JUKEBOX: GAME MUSIC")
  end

  -- LEFT (-1) / RIGHT (+1), going round; nothing while the playlist is stopped
  function J.skip(dir)
    if not J.active then return end
    local list = playlist()
    if #list == 0 then showNote("JUKEBOX: NO SONG IS ON") return end
    local pos = J.pos + dir
    if pos > #list then pos = 1 elseif pos < 1 then pos = #list end
    playAt(list, pos)
  end

  -- ------------------------------------------------------------- the button
  -- Full Control reports the JUKEBOX BUTTON's presses and releases here.

  local LOCK = "ph3_jukebox"
  local held = nil -- { kind, value }

  local function lockField(on)
    local Field = req("src.core.game3.field")
    if not Field then return end
    if on and Field.lock then pcall(Field.lock, LOCK)
    elseif not on and Field.unlock then pcall(Field.unlock, LOCK) end
  end

  function J.canUse() return fieldFree() end
  function J.isHeld(kind, value)
    return held ~= nil and held.kind == kind and held.value == value
  end

  function J.press(kind, value)
    held = { kind = kind, value = value }
    lockField(true)
  end

  function J.release(kind, value)
    if not J.isHeld(kind, value) then return end
    held = nil
    lockField(false)
  end

  -- still physically down? (a release can go missing when the window loses
  -- focus or a pad disconnects: never leave the player locked)
  local AXIS = {
    triggerleft = { "triggerleft", 1 }, triggerright = { "triggerright", 1 },
    leftstick_up = { "lefty", -1 }, leftstick_down = { "lefty", 1 },
    leftstick_left = { "leftx", -1 }, leftstick_right = { "leftx", 1 },
    rightstick_up = { "righty", -1 }, rightstick_down = { "righty", 1 },
    rightstick_left = { "rightx", -1 }, rightstick_right = { "rightx", 1 },
  }
  local function stillDown(h)
    if h.kind == "key" then return love.keyboard.isDown(h.value) end
    if not (love.joystick and love.joystick.getJoysticks) then return true end
    for _, js in ipairs(love.joystick.getJoysticks()) do
      local ok, down = pcall(function()
        if h.kind == "joy" then return js:isDown(tonumber(h.value) or 0) end
        local ax = AXIS[h.value]
        if ax then
          local v = js:getGamepadAxis(ax[1]) * ax[2]
          return v > 0.4
        end
        return js:isGamepadDown(h.value)
      end)
      if ok and down then return true end
    end
    return false
  end

  local DIRS = { up = function() J.play() end, down = function() J.stop() end,
    left = function() J.skip(-1) end, right = function() J.skip(1) end }

  -- after the game reads its buttons: while the Jukebox button is held, a
  -- direction works the Jukebox and never reaches the game
  local function onStep(input)
    local h = held
    if not h then return end
    local okD, down = pcall(stillDown, h)
    if okD and not down then
      held = nil
      lockField(false)
      return
    end
    for dir, fn in pairs(DIRS) do
      if input.pressed and input.pressed[dir] then pcall(fn) end
      if input.pressed then input.pressed[dir] = nil end
      if input.state then input.state[dir] = nil end
    end
  end

  -- ------------------------------------------------------------- music hooks

  local function isArea(A, id)
    if id == nil then return false end
    if id == A._mapSong then return true end
    local songs = songTable()
    if id == songs.MUS_SURF or id == songs.MUS_CYCLING or id == songs.MUS_UNDERWATER then return true end
    local ok, sp = pcall(A.specialMapSong)
    return ok and sp == id
  end

  -- the Jukebox song to play instead of id, or nil
  local function swap(A, id)
    if not (J.active and J.song) then return nil end
    local ok, r = pcall(A.resolveSong, id)
    r = ok and r or id
    if r == J.song or not isArea(A, r) then return nil end
    return J.song
  end

  local function current(A)
    return A._currentSong and A._currentSong.id or nil
  end

  function J.install()
    if J.installed then return end
    local A = Audio()
    if not A then return end
    J.installed = true

    local origPlay = A.playSong
    A.playSong = function(id, opts, ...)
      local okS, s = pcall(swap, A, id)
      if okS and s then id = s end
      return origPlay(id, opts, ...)
    end

    local origFade = A.fadeOutAndPlay
    A.fadeOutAndPlay = function(id, speed, fadeIn, ...)
      local okS, s = pcall(swap, A, id)
      if okS and s then
        -- already playing it: keep going instead of fading it out and back
        if current(A) == s and not A._fadeOut and not A._fanfareActive then return true end
        id = s
      end
      return origFade(id, speed, fadeIn, ...)
    end

    if type(A.playMapSong) == "function" then
      local origMap = A.playMapSong
      A.playMapSong = function(id, opts, ...)
        if J.active and type(opts) == "table" and opts.fadeOut then
          local copy = {}
          for k, v in pairs(opts) do copy[k] = v end
          copy.fadeOut = nil
          opts = copy
        end
        return origMap(id, opts, ...)
      end
    end

    -- Ruby/Sapphire/Emerald fade the old map's music out at a door when the
    -- next map's differs: not while the Jukebox plays (it carries on)
    if type(A.tryFadeOutOldMapMusic) == "function" then
      local origTry = A.tryFadeOutOldMapMusic
      A.tryFadeOutOldMapMusic = function(...)
        if J.active then return 0 end
        return origTry(...)
      end
    end

    local okI, Input = pcall(require, "src.core.Input")
    if okI and type(Input) == "table" and type(Input.step) == "function" then
      local origStep = Input.step
      Input.step = function(self, ...)
        local r = { origStep(self, ...) }
        if held then pcall(onStep, self) end
        return (table.unpack or unpack)(r)
      end
    end

    local okU, UiPass = pcall(require, "src.ui.game3.ui_pass")
    if okU and type(UiPass) == "table" and type(UiPass.drawUi) == "function" then
      local origUi = UiPass.drawUi
      UiPass.drawUi = function(...)
        local r = { origUi(...) }
        if note then pcall(drawNote) end
        return (table.unpack or unpack)(r)
      end
    end
  end

  return J
end
