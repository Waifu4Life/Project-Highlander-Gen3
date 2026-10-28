-- Preferences for Project Highlander Gen3.
-- Global values live in options.modOptions[ID] (written with the game's options);
-- the per-save theme lives in mod.save (stored inside the save file).
return function(mod)
  local ID = "project_highlander_gen3"
  local S = { ID = ID }

  S.DEFAULT_ORDER = { "pokedex", "pokemon", "bag", "pokebox", "trainer", "save", "option", "mods", "pokenav" }
  S.KNOWN = {}
  for _, id in ipairs(S.DEFAULT_ORDER) do S.KNOWN[id] = true end

  local DEFAULTS = {
    start_enabled = true,
    pokebox = true,
    clock = true,
    skip_recaps = true,
    box_exclusive = true,
    party_xp = true,
    always_boosted_exp = true,
    decapitalize = true,
    infinite_safari = true,
    modern_exp_share = true,
    rematch_anyone = true,
    run_everywhere = true,
    sparkling_hidden = true,
    unlimited_pp = true,
    use_repel_again = true,
    borders_enabled = true,
    border_scope = "game", -- "game" | "save"
    screen_ratio = "16:9", -- "off" | "16:9"
    bag_pouch_kanto = "off",
    bag_pouch_hoenn = "off",
    battle_enemy_hp = true,
    low_hp_warning = "normal", -- "normal" | "reduced" | "off"
    ball_shortcuts = true,
    select_up = 4, -- POKé BALL
    select_down = 2, -- ULTRA BALL
    select_left = 3, -- GREAT BALL
    select_right = 0, -- NONE
    item_shortcuts = true,
    fullctl_enabled = true,
    fullctl_analog_left = true,
    fullctl_analog_right = true,
    fullctl_select_combos = true,
    battle_move_colors = true,
    anim_back = true,
    anim_frlg = true,
    anim_loop = "medium", -- "off" | "slow" | "medium" | "fast"
    anim_rs = true,
    kanto_exclusive = true,
    kanto_starters = true,
    kanto_fossil = true,
    kanto_limited = true,
    kanto_linkc = true,
    kanto_mystery = true,
    hoenn_wish = true,
    hoenn_starters = true,
    hoenn_eon = true,
    hoenn_box = true,
    hoenn_deepsea = true,
    hoenn_fossil = true,
    hoenn_exclusive = true,
    hoenn_limited = true,
    hoenn_roamer = true,
    hoenn_linkc = true,
    johto_exclusive = true,
    johto_beasts = true,
    johto_roamer = true,
    johto_mystic = true,
    johto_celebi = true,
    johto_emerald = true,
    johto_extras = true,
    johto_starters = true,
    coins_2x = true,
    slot_odds = "normal", -- "normal" | "generous" | "lucky"
    slot_bigger_payouts = true,
    slot_all_lucky = true,
    rumble_enabled = true, -- old toggle, only read once to move Off into INTENSITY
    rumble_wild = true,
    rumble_trainer = true,
    rumble_intensity = "medium", -- "low" | "medium" | "high"
    rumble_when_hit = true,
    rumble_when_hitting = true,
    forgettable_hms = true,
    instant_tmhm = true,
    move_relearning = true,
    no_learn_hms = true,
    tms_forever = true,
    fairy_type = false, -- set by the future Fairy feature
    theme_scope = "game", -- "game" | "save"
    start_order = table.concat(S.DEFAULT_ORDER, ","),
  }

  local function liveGame()
    local ok, Runtime = pcall(require, "src.core.game3.runtime")
    local g = ok and type(Runtime) == "table" and Runtime._game or nil
    if g then return g end
    local okG, mg = pcall(function() return mod.game end)
    return okG and mg or nil
  end
  S.game = liveGame

  local function bucket(tbl, create)
    if type(tbl) ~= "table" then return nil end
    if create then tbl.modOptions = tbl.modOptions or {} end
    local all = tbl.modOptions
    if type(all) ~= "table" then return nil end
    if create and type(all[ID]) ~= "table" then all[ID] = {} end
    return all[ID]
  end

  function S.get(key)
    local g = liveGame()
    local live = g and bucket(g.mods, false)
    if live and live[key] ~= nil then return live[key] end
    local saved = g and bucket(g.options, false)
    if saved and saved[key] ~= nil then return saved[key] end
    local ok, value = pcall(mod.options.get, mod.options, key)
    if ok and value ~= nil then return value end
    return DEFAULTS[key]
  end

  function S.set(key, value)
    local g = liveGame()
    local saved = g and bucket(g.options, true)
    if saved then saved[key] = value end
    local live = g and bucket(g.mods, true)
    if live then live[key] = value end
    if g and type(g.writeOptions) == "function" then pcall(g.writeOptions, g) end
  end

  -- many keys at once, written to the options file once (JUKEBOX > ALL SONGS)
  function S.setMany(values)
    local g = liveGame()
    local saved = g and bucket(g.options, true)
    local live = g and bucket(g.mods, true)
    for key, value in pairs(values) do
      if saved then saved[key] = value end
      if live then live[key] = value end
    end
    if g and type(g.writeOptions) == "function" then pcall(g.writeOptions, g) end
  end

  function S.flag(key)
    return S.get(key) ~= false
  end

  -- ------- game version

  local GEN3 = { firered = true, leafgreen = true, ruby = true, sapphire = true, emerald = true }
  S.HOENN = { ruby = true, sapphire = true, emerald = true }

  function S.version(session)
    local v = type(session) == "table" and session.version or nil
    if GEN3[v] then return v end
    local g = liveGame()
    v = g and (g.version or (g.session and g.session.version)) or nil
    if GEN3[v] then return v end
    local ok, GameVersion = pcall(require, "src.core.GameVersion")
    if ok and type(GameVersion.get) == "function" then
      local okV, id = pcall(GameVersion.get)
      if okV and GEN3[id] then return id end
    end
    return "firered"
  end

  function S.isHoenn(session)
    return S.HOENN[S.version(session)] == true
  end

  -- ------- theme (per game or per save)

  function S.themeScope()
    return S.get("theme_scope") == "save" and "save" or "game"
  end

  function S.themeChoice(session)
    if S.themeScope() == "save" then
      local ok, value = pcall(mod.save.get, mod.save, "theme")
      if ok and type(value) == "string" then return value end
    end
    local value = S.get("theme_" .. S.version(session))
    return type(value) == "string" and value or "auto"
  end

  function S.setThemeChoice(session, value)
    if S.themeScope() == "save" then
      pcall(mod.save.set, mod.save, "theme", value)
    else
      S.set("theme_" .. S.version(session), value)
    end
  end

  -- ------- start menu order (shared by all five games; absent items are skipped)

  function S.order()
    local raw = S.get("start_order")
    local out, seen = {}, {}
    if type(raw) == "string" then
      for id in raw:gmatch("[^,%s]+") do
        if S.KNOWN[id] and not seen[id] then
          out[#out + 1] = id
          seen[id] = true
        end
      end
    end
    for _, id in ipairs(S.DEFAULT_ORDER) do
      if not seen[id] then out[#out + 1] = id end
    end
    return out
  end

  function S.setOrder(list)
    S.set("start_order", table.concat(list, ","))
  end

  function S.resetOrder()
    S.set("start_order", table.concat(S.DEFAULT_ORDER, ","))
  end

  return S
end
