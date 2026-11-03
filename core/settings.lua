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
    clock = true,          -- old ON/OFF; only read once to carry OFF into clock_mode
    clock_mode = "rotation", -- "off" | "device" | "play" | "ingame" (Hoenn) | "rotation"
    start_hidden = "",     -- "KEY,KEY" (START MENU SETTINGS > HIDE ITEMS)
    start_names = "",
    start_opt_rows = "",   -- other mods' OPTIONS rows seen so far (Start Menu items)      -- "KEY=NAME|KEY=NAME" (START MENU SETTINGS > CUSTOM RENAME)
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
    unlimited_pp = false, -- Off by default: borderline cheating
    status_reset = false, -- Off by default (BATTLE SCREEN > STATUS CONDITION RESET)
    use_repel_again = true,
    borders_enabled = true,
    border_scope = "game", -- "game" | "save"
    screen_ratio = "16:9", -- "off" | "16:9"
    bag_pouch_kanto = "off",
    bag_pouch_hoenn = "off",
    battle_enemy_hp = true,
    battle_effectiveness = true,
    safari_unlimited_balls = true,
    safari_no_run = true,
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
    start_icons = "",      -- "KEY=icon,KEY=icon" (CUSTOM ICONS for other mods' items)
    start_icon_items = "", -- "KEY=LABEL|KEY=LABEL" (other mods' items seen so far)
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

  -- ------- per-save values (Start Menu order, icons, hidden items, names)
  -- Kept in the save file. A save without its own order/icons uses the
  -- shared ones from before 1.81.0; hidden items and names start empty.
  local function saveGet(key, noShared)
    local ok, v = pcall(mod.save.get, mod.save, key)
    if ok and v ~= nil then return v end
    if noShared then return DEFAULTS[key] end
    return S.get(key)
  end

  local function saveSet(key, value)
    local ok = pcall(mod.save.set, mod.save, key, value)
    if not ok then S.set(key, value) end
  end

  function S.orderRaw() return tostring(saveGet("start_order")) end

  -- other mods' rows of the OPTIONS menu that open something (seen there),
  -- "KEY=LABEL|...": they become Start Menu items
  function S.rememberOptionRows(list)
    local parts = {}
    for _, r in ipairs(list or {}) do
      local k = tostring(r.key or ""):gsub("[|=]", " ")
      local l = tostring(r.label or k):gsub("[|=]", " ")
      if k ~= "" then parts[#parts + 1] = k .. "=" .. l end
    end
    local raw = table.concat(parts, "|")
    if S.get("start_opt_rows") ~= raw then S.set("start_opt_rows", raw) end
  end

  function S.optionRows()
    local out = {}
    local raw = S.get("start_opt_rows")
    if type(raw) == "string" then
      for part in raw:gmatch("[^|]+") do
        local k, l = part:match("^([^=]+)=(.*)$")
        if k then out[#out + 1] = { key = k, label = l } end
      end
    end
    return out
  end

  -- ------- start menu order (shared by all five games; absent items are skipped)

  function S.order()
    local raw = saveGet("start_order")
    local out, seen = {}, {}
    if type(raw) == "string" then
      for id in raw:gmatch("[^,%s]+") do
        -- built-in ids, and "x:<KEY>" for other mods' items (see S.extraKey)
        if (S.KNOWN[id] or id:match("^x:[%w_]+$")) and not seen[id] then
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

  -- order key of another mod's item
  function S.extraKey(iconKey)
    return "x:" .. tostring(iconKey or "ITEM")
  end

  function S.setOrder(list)
    saveSet("start_order", table.concat(list, ","))
  end

  function S.resetOrder()
    saveSet("start_order", table.concat(S.DEFAULT_ORDER, ","))
  end

  -- ------- custom icons for other mods' Start Menu items (shared by all games)

  -- stable key for an entry: its id, else its label (letters/digits only)
  function S.iconKey(entry)
    if type(entry) ~= "table" then return "ITEM" end
    local raw
    if type(entry.id) == "string" and entry.id ~= "" then
      raw = "ID_" .. entry.id
    else
      raw = "LB_" .. tostring(entry.label or "ITEM")
    end
    raw = raw:upper():gsub("[^%w]", "_")
    return raw
  end

  local function parsePairs(raw, sep)
    local out, list = {}, {}
    if type(raw) ~= "string" then return out, list end
    for part in raw:gmatch("[^" .. sep .. "]+") do
      local k, v = part:match("^([%w_]+)=(.*)$")
      if k and v ~= "" and out[k] == nil then
        out[k] = v
        list[#list + 1] = k
      end
    end
    return out, list
  end

  function S.icons()
    return (parsePairs(saveGet("start_icons"), ","))
  end

  -- "auto" when the player has not picked one
  function S.iconFor(key)
    local v = S.icons()[key]
    return (type(v) == "string" and v ~= "") and v or "auto"
  end

  function S.setIcon(key, value)
    local map, list = parsePairs(saveGet("start_icons"), ",")
    if value == nil or value == "auto" then
      map[key] = nil
    else
      if map[key] == nil then list[#list + 1] = key end
      map[key] = value
    end
    local parts = {}
    for _, k in ipairs(list) do
      if map[k] then parts[#parts + 1] = k .. "=" .. map[k] end
    end
    saveSet("start_icons", table.concat(parts, ","))
  end

  -- other mods' items, remembered so CUSTOM ICONS lists them even before
  -- START has been opened this session
  function S.iconItems()
    local map, list = parsePairs(S.get("start_icon_items"), "|")
    local out = {}
    for _, k in ipairs(list) do out[#out + 1] = { key = k, label = map[k] } end
    return out
  end

  function S.rememberIconItems(items)
    local map, list = parsePairs(S.get("start_icon_items"), "|")
    local changed = false
    for _, it in ipairs(items or {}) do
      local label = tostring(it.label or "ITEM"):gsub("[|=,]", " ")
      if it.key and map[it.key] ~= label then
        if map[it.key] == nil then list[#list + 1] = it.key end
        map[it.key] = label
        changed = true
      end
    end
    if not changed then return end
    local parts = {}
    for _, k in ipairs(list) do parts[#parts + 1] = k .. "=" .. map[k] end
    S.set("start_icon_items", table.concat(parts, "|"))
  end

  -- ------- clock (top bar of the Start Menu)

  S.CLOCKS = {
    { id = "off", label = "OFF" },
    { id = "device", label = "DEVICE" },
    { id = "play", label = "PLAY" },
    { id = "ingame", label = "IN-GAME", hoenn = true }, -- FireRed/LeafGreen have no clock
    { id = "rotation", label = "ROTATION" },
  }

  function S.clockMode(session)
    local v = S.get("clock_mode")
    -- an old CLOCK OFF (before 1.79.0) stays OFF
    if v == "rotation" and S.get("clock") == false then
      local g = liveGame()
      local saved = g and bucket(g.options, false)
      if not (saved and saved.clock_mode ~= nil) then v = "off" end
    end
    for _, c in ipairs(S.CLOCKS) do
      if c.id == v then
        if c.hoenn and not S.isHoenn(session) then return "device" end
        return v
      end
    end
    return "rotation"
  end

  function S.clockLabel(session)
    local v = S.clockMode(session)
    for _, c in ipairs(S.CLOCKS) do if c.id == v then return c.label end end
    return "ROTATION"
  end

  function S.stepClock(session, dir)
    local v, at = S.clockMode(session), 1
    for i, c in ipairs(S.CLOCKS) do if c.id == v then at = i break end end
    local hoenn = S.isHoenn(session)
    repeat
      at = (at - 1 + (dir or 1)) % #S.CLOCKS + 1
    until hoenn or not S.CLOCKS[at].hoenn
    S.set("clock_mode", S.CLOCKS[at].id)
  end

  -- ------- HIDE ITEMS (keys: "mods" and "x:<KEY>" for other mods' items)

  function S.hiddenSet()
    local out = {}
    local raw = saveGet("start_hidden", true)
    if type(raw) == "string" then
      for key in raw:gmatch("[^,]+") do out[key] = true end
    end
    return out
  end

  function S.isHidden(key)
    return S.hiddenSet()[key] == true
  end

  function S.setHidden(key, hide)
    local set = S.hiddenSet()
    set[key] = hide and true or nil
    local list = {}
    for k in pairs(set) do list[#list + 1] = k end
    table.sort(list)
    saveSet("start_hidden", table.concat(list, ","))
  end

  -- ------- CUSTOM RENAME (keys: built-in ids, "exit", "x:<KEY>")

  function S.names()
    local map = {}
    local raw = saveGet("start_names", true)
    if type(raw) == "string" then
      for part in raw:gmatch("[^|]+") do
        local k, v = part:match("^([^=]+)=(.+)$")
        if k and map[k] == nil then map[k] = v end
      end
    end
    return map
  end

  function S.nameFor(key)
    local v = S.names()[key]
    return (type(v) == "string" and v ~= "") and v or nil
  end

  -- an empty name (or nil) puts the usual one back
  function S.setName(key, name)
    local map = S.names()
    if type(name) == "string" then name = name:gsub("[|=]", " ") end
    map[key] = (type(name) == "string" and name ~= "") and name or nil
    local keys = {}
    for k in pairs(map) do keys[#keys + 1] = k end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do parts[#parts + 1] = k .. "=" .. map[k] end
    saveSet("start_names", table.concat(parts, "|"))
  end

  return S
end
