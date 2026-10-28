-- Project Highlander Gen3: entry point.
-- Gen 3 only (manifest "games": ["gen3"]); shares nothing with Project Highlander.
return function(mod)
  local function loadLocal(relative)
    local source, readErr = mod:read(relative)
    assert(source, tostring(readErr or (relative .. " is missing")))
    local chunk, compileErr = load(source, "@" .. tostring(mod.path) .. "/" .. relative)
    assert(chunk, compileErr)
    return chunk()
  end

  local ctx = { mod = mod }
  ctx.settings = loadLocal("core/settings.lua")(mod)
  ctx.themes = loadLocal("core/themes.lua")
  ctx.decap = loadLocal("components/qol/decap.lua")(ctx)
  ctx.iconMaps = loadLocal("components/start_menu/icon_maps.lua")
  ctx.layout = loadLocal("components/start_menu/layout.lua")(ctx)
  ctx.draw = loadLocal("components/start_menu/draw.lua")(ctx)
  ctx.sort = loadLocal("components/start_menu/sort_screen.lua")(ctx)
  ctx.startMenu = loadLocal("components/start_menu/main.lua")(ctx)
  ctx.qol = loadLocal("components/qol/main.lua")(ctx)
  ctx.pc = loadLocal("components/pc/main.lua")(ctx)
  ctx.party = loadLocal("components/party/main.lua")(ctx)
  ctx.partyXp = loadLocal("components/party/xp.lua")(ctx)
  ctx.bag = loadLocal("components/bag/main.lua")(ctx)
  ctx.pokedex = loadLocal("components/pokedex/main.lua")(ctx)
  ctx.typeColors = loadLocal("components/battle_hud/types.lua")
  ctx.battleHud = loadLocal("components/battle_hud/main.lua")(ctx, ctx.typeColors)
  ctx.borders = loadLocal("components/borders/main.lua")(ctx)
  ctx.shortcuts = loadLocal("components/shortcuts/main.lua")(ctx)
  ctx.fullControl = loadLocal("components/full_control/main.lua")(ctx)
  ctx.pokemoves = loadLocal("components/pokemoves/main.lua")(ctx)
  ctx.rumble = loadLocal("components/rumble/main.lua")(ctx)
  ctx.gameCorner = loadLocal("components/game_corner/main.lua")(ctx)
  ctx.kantoAll = loadLocal("components/kanto_all/main.lua")(ctx)
  ctx.birthIslandFactory = loadLocal("components/hoenn_all/birth_island.lua")
  ctx.hoennAll = loadLocal("components/hoenn_all/main.lua")(ctx)
  ctx.johto = loadLocal("components/johto/main.lua")(ctx)
  ctx.animSprites = loadLocal("components/animated_sprites/main.lua")(ctx)
  ctx.jukebox = loadLocal("components/jukebox/main.lua")(ctx)
  ctx.hub = loadLocal("core/options_hub.lua")(ctx)
  ctx.buttonMode = loadLocal("core/button_mode.lua")(mod)

  -- Always on: take keyboard/gamepad focus when started from outside the
  -- launcher (frontend, Playnite, shortcuts) -- same fix as Project Highlander.
  pcall(function() loadLocal("core/window_focus.lua")(mod) end)

  local function install()
    -- Decapitalize Words goes first: it must sit under every other font hook.
    pcall(ctx.decap.install)
    -- always on: OPTION > BUTTON MODE stays on LR
    local okBm, errBm = pcall(ctx.buttonMode.install)
    if not okBm and mod.log then mod.log:warn("button mode: %s", tostring(errBm)) end
    ctx.startMenu.install()
    ctx.qol.install()
    ctx.pc.install()
    ctx.party.install()
    -- PokéMoves after Party: its RELEARN / No Learn HM rows go into the sorted A menu
    local okPm, errPm = pcall(ctx.pokemoves.install)
    if not okPm and mod.log then mod.log:warn("pokemoves: %s", tostring(errPm)) end
    ctx.partyXp.install()
    ctx.bag.install()
    ctx.pokedex.install()
    ctx.battleHud.install()
    pcall(ctx.borders.install)
    ctx.shortcuts.install()
    local okAs, errAs = pcall(ctx.animSprites.install)
    if not okAs and mod.log then mod.log:warn("animated sprites: %s", tostring(errAs)) end
    local okKa, errKa = pcall(ctx.kantoAll.install)
    if not okKa and mod.log then mod.log:warn("kanto all: %s", tostring(errKa)) end
    local okHa, errHa = pcall(ctx.hoennAll.install)
    if not okHa and mod.log then mod.log:warn("hoenn all: %s", tostring(errHa)) end
    -- after Fill Kanto / Fill Hoenn: its hooks wrap theirs
    local okJo, errJo = pcall(ctx.johto.install)
    if not okJo and mod.log then mod.log:warn("johto: %s", tostring(errJo)) end
    local okGc, errGc = pcall(ctx.gameCorner.install)
    if not okGc and mod.log then mod.log:warn("game corner: %s", tostring(errGc)) end
    local okRu, errRu = pcall(ctx.rumble.install)
    if not okRu and mod.log then mod.log:warn("rumble: %s", tostring(errRu)) end
    local okJb, errJb = pcall(ctx.jukebox.install)
    if not okJb and mod.log then mod.log:warn("jukebox: %s", tostring(errJb)) end
    local okFc, errFc = pcall(ctx.fullControl.install)
    if not okFc and mod.log then mod.log:warn("full control: %s", tostring(errFc)) end
    ctx.hub.install()
  end
  local ok, err = pcall(install)
  if not ok and mod.log then mod.log:warn("deferred install: %s", tostring(err)) end
  if mod.events and mod.events.on then
    mod.events:on("game.ready", function()
      local okReady, errReady = pcall(install)
      if not okReady and mod.log then mod.log:error("install failed: %s", tostring(errReady)) end
    end)
  end
end
