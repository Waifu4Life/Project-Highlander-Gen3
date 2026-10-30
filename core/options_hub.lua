-- Adds PROJECT HIGHLANDER to the game's own OPTIONS menu (FRLG, RS and
-- Emerald option menus all build their top page through option_rows.group).
-- Sub-menus: Enable on top, then alphabetical.
return function(ctx)
  local H = { installed = false }
  local S, Themes = ctx.settings, ctx.themes

  local function onOff(v) return v and "ON" or "OFF" end

  -- Values on our pages are drawn right-aligned at the end of the row, so
  -- they line up in one column and never cover the setting's name. Each
  -- value() marks its text; the next font draw of that text is moved.
  local VALUE_RIGHT = 216
  H.pending = nil
  local function aligned(fn)
    return function(c)
      local t = fn(c)
      H.pending = (t ~= nil and tostring(t) ~= "") and tostring(t) or nil
      return t
    end
  end

  local function toggleRow(id, label, key)
    return {
      id = "ph3_" .. id, label = label,
      value = aligned(function() return onOff(S.flag(key)) end),
      step = function()
        S.set(key, not S.flag(key))
        return true
      end,
    }
  end

  local function startMenuRows()
    return {
      toggleRow("start_enabled", "ENABLE", "start_enabled"),
      toggleRow("clock", "CLOCK", "clock"),
      {
        id = "ph3_custom_icons", label = "CUSTOM ICONS", value = function() return "" end,
        activate = function(c)
          ctx.iconScreen.show({ session = c and c.session })
        end,
      },
      toggleRow("pokebox", "POKéBOX", "pokebox"),
      {
        id = "ph3_theme_scope", label = "SAVE THEME",
        value = aligned(function() return S.themeScope() == "save" and "PER SAVE" or "PER GAME" end),
        step = function()
          S.set("theme_scope", S.themeScope() == "save" and "game" or "save")
          return true
        end,
      },
      {
        id = "ph3_sort", label = "SORT MENU", value = function() return "" end,
        activate = function(c)
          ctx.sort.show({ session = c and c.session })
        end,
      },
      {
        id = "ph3_theme", label = "THEME",
        value = aligned(function(c)
          return Themes.LABELS[S.themeChoice(c and c.session)] or "AUTO"
        end),
        step = function(c, dir)
          local session = c and c.session
          S.setThemeChoice(session, Themes.step(S.themeChoice(session), dir))
          return true
        end,
      },
    }
  end

  -- Alphabetical, like every Project Highlander sub-menu.
  local function otherSystemRows()
    return {
      {
        id = "ph3_bag_pouch", label = "BAG ON SPECIFIC POUCH",
        value = aligned(function(c)
          return ctx.bag.POUCH_LABELS[ctx.bag.pouchChoice(c and c.session)] or "OFF"
        end),
        step = function(c, dir)
          ctx.bag.stepPouch(c and c.session, dir)
          return true
        end,
      },
      toggleRow("box_exclusive", "BOX EXCLUSIVE", "box_exclusive"),
      toggleRow("decapitalize", "DECAPITALIZE WORDS", "decapitalize"),
      toggleRow("party_xp", "DISPLAY XP IN PARTY MENU", "party_xp"),
      -- FireRed / LeafGreen only
      not S.isHoenn() and toggleRow("skip_recaps", "SKIP FR & LG RECAPS", "skip_recaps") or nil,
    }
  end

  local function battleScreenRows()
    return {
      toggleRow("always_boosted_exp", "ALWAYS BOOSTED EXP", "always_boosted_exp"),
      toggleRow("battle_move_colors", "COLORED MOVE NAMES", "battle_move_colors"),
      toggleRow("battle_enemy_hp", "DISPLAY ENEMY HP", "battle_enemy_hp"),
      {
        id = "ph3_low_hp_warning", label = "LOW HP WARNING",
        value = aligned(function() return ctx.battleHud.lowHpLabel() end),
        step = function(_, dir)
          ctx.battleHud.stepLowHp(dir)
          return true
        end,
      },
      toggleRow("modern_exp_share", "MODERN EXP SHARING", "modern_exp_share"),
      toggleRow("unlimited_pp", "UNLIMITED PP", "unlimited_pp"),
    }
  end

  local function overworldScreenRows()
    return {
      toggleRow("infinite_safari", "INFINITE SAFARI STEPS", "infinite_safari"),
      toggleRow("rematch_anyone", "REMATCH ANYONE, ANYTIME", "rematch_anyone"),
      toggleRow("run_everywhere", "RUN EVERYWHERE", "run_everywhere"),
      toggleRow("sparkling_hidden", "SPARKLING HIDDEN ITEMS", "sparkling_hidden"),
      toggleRow("use_repel_again", "USE REPEL AGAIN?", "use_repel_again"),
    }
  end

  -- Enable on top, then alphabetical.
  local function borderRows()
    local B = ctx.borders
    return {
      toggleRow("borders_enabled", "ENABLE", "borders_enabled"),
      {
        id = "ph3_border", label = "BORDER",
        value = aligned(function(c) return B.label(c and c.session) end),
        step = function(c, dir)
          B.step(c and c.session, dir)
          return true
        end,
      },
      {
        id = "ph3_border_scope", label = "BORDER SCOPE",
        value = aligned(function() return B.scope() == "save" and "BY SAVE" or "BY GAME" end),
        step = function()
          S.set("border_scope", B.scope() == "save" and "game" or "save")
          return true
        end,
      },
      {
        id = "ph3_screen_ratio", label = "SCREEN RATIO",
        value = aligned(function() return B.ratioLabel and B.ratioLabel() or (S.get("screen_ratio") == "16:9" and "16:9" or "OFF") end),
        step = function()
          S.set("screen_ratio", S.get("screen_ratio") == "16:9" and "off" or "16:9")
          return true
        end,
      },
    }
  end

  -- Ball switch on top, then directions in controller order, then items
  -- (same order as Gen 1/2).
  local function shortcutRows()
    local SC = ctx.shortcuts
    local rows = { toggleRow("ball_shortcuts", "BALL SHORTCUTS", "ball_shortcuts") }
    for _, d in ipairs(SC.DIRS) do
      rows[#rows + 1] = {
        id = "ph3_" .. d.key, label = d.label,
        value = aligned(function() return SC.ballLabel(d.key) end),
        step = function(_, dir)
          SC.stepBall(d.key, dir)
          return true
        end,
      }
    end
    rows[#rows + 1] = toggleRow("item_shortcuts", "ITEM SHORTCUTS", "item_shortcuts")
    for slot = 1, 3 do
      rows[#rows + 1] = {
        id = "ph3_item_shortcut_" .. slot, label = "ITEM SHORTCUT " .. slot,
        value = aligned(function(c) return SC.slotLabel(c and c.session, slot) end),
        step = function(c, dir)
          SC.stepSlot(c and c.session, slot, dir)
          return true
        end,
      }
    end
    return rows
  end

  -- Enable on top, buttons in controller order, then the toggles A-Z.
  local function fullControlRows()
    local FC = ctx.fullControl
    local function fcToggle(id, label, key)
      return {
        id = "ph3_" .. id, label = label,
        value = aligned(function() return onOff(S.flag(key)) end),
        step = function()
          S.set(key, not S.flag(key))
          FC.apply()
          return true
        end,
      }
    end
    local rows = { fcToggle("fullctl_enabled", "ENABLE", "fullctl_enabled") }
    for _, r in ipairs(FC.ROWS) do
      rows[#rows + 1] = {
        id = "ph3_fc_" .. r.id, label = r.label,
        value = aligned(function() return FC.label(r) end),
        activate = function() FC.capture.show(r) end,
      }
    end
    rows[#rows + 1] = fcToggle("fullctl_analog_left", "LEFT ANALOG FOR D-PAD", "fullctl_analog_left")
    rows[#rows + 1] = fcToggle("fullctl_analog_right", "RIGHT ANALOG FOR D-PAD", "fullctl_analog_right")
    rows[#rows + 1] = fcToggle("fullctl_select_combos", "SELECT VISUAL COMBOS", "fullctl_select_combos")
    return rows
  end

  -- Alphabetical (no Enable row, same as Gen 1/2).
  local function pokemovesRows()
    return {
      toggleRow("forgettable_hms", "FORGETTABLE HMS", "forgettable_hms"),
      toggleRow("instant_tmhm", "INSTANT TMS/HMS", "instant_tmhm"),
      toggleRow("move_relearning", "MOVE RELEARNING", "move_relearning"),
      toggleRow("no_learn_hms", "NO LEARN HMS", "no_learn_hms"),
      toggleRow("tms_forever", "TMS FOREVER", "tms_forever"),
    }
  end

  -- Alphabetical (2X first), same as Gen 1/2.
  local function gameCornerRows()
    local GC = ctx.gameCorner
    return {
      toggleRow("coins_2x", "2X COINS FOR CASH", "coins_2x"),
      toggleRow("slot_all_lucky", "ALL LUCKY MACHINES", "slot_all_lucky"),
      toggleRow("slot_bigger_payouts", "BIGGER PAYOUTS", "slot_bigger_payouts"),
      {
        id = "ph3_slot_odds", label = "SLOT ODDS",
        value = aligned(function() return GC.oddsLabel() end),
        step = function(_, dir)
          GC.stepOdds(dir)
          return true
        end,
      },
    }
  end

  -- Alphabetical; the scrolling note always goes last.
  -- Each game only shows its own rows: FIRE RED & LEAF GREEN in FireRed/
  -- LeafGreen, RUBY & SAPPHIRE in Ruby/Sapphire; Emerald has neither, and no
  -- scrolling note.
  local function animRows()
    local v = S.version()
    local kanto = v == "firered" or v == "leafgreen"
    local rsGame = v == "ruby" or v == "sapphire"
    local rows = {
      toggleRow("anim_back", "BACK ANIMATION", "anim_back"),
      kanto and toggleRow("anim_frlg", "FIRE RED & LEAF GREEN", "anim_frlg") or false,
      {
        id = "ph3_anim_loop", label = "LOOP ANIMATIONS",
        value = aligned(function() return ctx.animSprites.speedLabel() end),
        step = function(_, dir)
          ctx.animSprites.stepSpeed(dir)
          return true
        end,
      },
      rsGame and toggleRow("anim_rs", "RUBY & SAPPHIRE", "anim_rs") or false,
      v ~= "emerald" and ctx.animSprites.noteRow() or false,
    }
    local out = {}
    for i = 1, #rows + 4 do
      if rows[i] then out[#out + 1] = rows[i] end
    end
    return out
  end

  -- Fixed order (GET ??? always last, same as Gen 1).
  local function kantoRows()
    return {
      toggleRow("kanto_exclusive", "GET OTHER GAME EXCLUSIVES", "kanto_exclusive"),
      toggleRow("kanto_linkc", "TRADE WITH LINK C.", "kanto_linkc"),
      toggleRow("kanto_limited", "INFINITE TRIES FOR RARE PKMN", "kanto_limited"),
      toggleRow("kanto_starters", "GET ALL STARTERS", "kanto_starters"),
      toggleRow("kanto_fossil", "GET OTHER FOSSIL", "kanto_fossil"),
      toggleRow("kanto_mystery", "GET ???", "kanto_mystery"),
    }
  end

  -- Fixed order. Ruby/Sapphire-only rows are left out in Emerald.
  local function hoennRows()
    local rsOnly = S.version() ~= "emerald"
    local rows = {
      toggleRow("hoenn_exclusive", "GET OTHER GAME EXCLUSIVES", "hoenn_exclusive"),
      toggleRow("hoenn_linkc", "TRADE WITH LINK C.", "hoenn_linkc"),
      toggleRow("hoenn_limited", "INFINITE TRIES FOR RARE PKMN", "hoenn_limited"),
      toggleRow("hoenn_starters", "GET ALL STARTERS", "hoenn_starters"),
      rsOnly and toggleRow("hoenn_fossil", "GET OTHER FOSSIL", "hoenn_fossil") or false,
      toggleRow("hoenn_deepsea", "GET OTHER DEEP SEA ITEM", "hoenn_deepsea"),
      toggleRow("hoenn_roamer", "ROAMING HUNTER", "hoenn_roamer"),
      rsOnly and toggleRow("hoenn_box", "GET OTHER BOX LEGENDARY", "hoenn_box") or false,
      toggleRow("hoenn_eon", "GET EON TICKET", "hoenn_eon"),
      toggleRow("hoenn_wish", "GET A SPECIAL WISH", "hoenn_wish"),
    }
    local out = {}
    for i = 1, #rows + 4 do
      if rows[i] then out[#out + 1] = rows[i] end
    end
    return out
  end

  -- Fixed order. Each game only shows its own rows: FireRed/LeafGreen's four
  -- events (and ROAMING HUNTER for the beasts), Ruby/Sapphire's EMERALD GAME
  -- EXCLUSIVES, Emerald's SAFARI ZONE 5&6 EXTRAS.
  local function johtoRows()
    local v = S.version()
    local kanto = v == "firered" or v == "leafgreen"
    local rsGame = v == "ruby" or v == "sapphire"
    local rows
    if kanto then
      rows = {
        toggleRow("johto_exclusive", "GET OTHER GAME EXCLUSIVES", "johto_exclusive"),
        toggleRow("johto_beasts", "GET ALL ROAMING BEASTS", "johto_beasts"),
        toggleRow("johto_roamer", "ROAMING HUNTER", "johto_roamer"),
        toggleRow("johto_mystic", "OBTAIN MYSTIC TICKET", "johto_mystic"),
        toggleRow("johto_celebi", "GUARDIAN OF THE FOREST", "johto_celebi"),
      }
    else
      rows = {
        rsGame and toggleRow("johto_emerald", "GET EMERALD GAME EXCLUSIVES", "johto_emerald") or false,
        v == "emerald" and toggleRow("johto_extras", "EXTRAS IN SAFARI ZONE 5&6", "johto_extras") or false,
        toggleRow("johto_starters", "GET ALL JOHTO STARTERS", "johto_starters"),
      }
    end
    local out = {}
    for i = 1, #rows + 4 do
      if rows[i] then out[#out + 1] = rows[i] end
    end
    return out
  end

  -- INTENSITY on top (its OFF turns rumble off, like an ENABLE row), the
  -- test row right under it, then alphabetical.
  local function rumbleRows()
    local RU = ctx.rumble
    return {
      {
        id = "ph3_rumble_intensity", label = "INTENSITY",
        value = aligned(function() return RU.intensityLabel() end),
        step = function(_, dir)
          RU.stepIntensity(dir)
          -- a sample pulse so the new strength can be felt right away
          pcall(RU.pulse, false, RU.pattern("SE_EFFECTIVE"))
          return true
        end,
      },
      {
        id = "ph3_rumble_test", label = "PRESS SELECT TO TEST",
        value = aligned(function() return RU.testLabel() end),
        step = function(_, dir)
          RU.stepTest(dir)
          return true
        end,
        -- SELECT on this row (see selectRow below)
        onSelect = function() pcall(RU.test) end,
      },
      toggleRow("rumble_trainer", "BEFORE TRAINER BATTLE", "rumble_trainer"),
      toggleRow("rumble_wild", "BEFORE WILD BATTLE", "rumble_wild"),
      toggleRow("rumble_when_hit", "WHEN I GET HIT", "rumble_when_hit"),
      toggleRow("rumble_when_hitting", "WHEN I HIT", "rumble_when_hitting"),
    }
  end

  -- ALL SONGS on top (ON / OFF / SOME: A or LEFT/RIGHT turns them all On,
  -- or all Off when any is On), then this game's songs A-Z: the playlist.
  local function jukeboxRows()
    local JB = ctx.jukebox
    local rows = {
      {
        id = "ph3_jb_all", label = "ALL SONGS",
        value = aligned(function() return JB.allLabel() end),
        step = function()
          JB.toggleAll()
          return true
        end,
      },
    }
    for _, song in ipairs(JB.list()) do
      rows[#rows + 1] = {
        id = "ph3_jb_" .. song.name, label = song.label,
        value = aligned(function() return onOff(JB.isOn(song.name)) end),
        step = function()
          JB.toggle(song.name)
          return true
        end,
      }
    end
    return rows
  end

  local function hubRows(openPage)
    local function page(id, label, build)
      return {
        id = "ph3_" .. id, label = label, value = function() return "" end,
        activate = function() openPage(label, build()) end,
      }
    end
    -- Alphabetical
    local rows = {
      page("anim_sprites", "ANIMATED SPRITES", animRows),
      page("battle_screen", "BATTLE SCREEN", battleScreenRows),
      page("borders", "CUSTOM BORDERS", borderRows),
      -- FireRed / LeafGreen only
      -- Ruby / Sapphire / Emerald only
      S.isHoenn() and page("hoenn_all", "FILL HOENN REGIONAL DEX", hoennRows) or false,
      not S.isHoenn() and page("kanto_all", "FILL KANTO REGIONAL DEX", kantoRows) or false,
      page("full_control", "FULL CONTROL", fullControlRows),
      page("game_corner", "GAME CORNER CHEATS", gameCornerRows),
      page("johto_helper", "JOHTO POKéMON HELPER", johtoRows),
      page("jukebox", "JUKEBOX", jukeboxRows),
      page("other_system", "OTHER SYSTEM SETTINGS", otherSystemRows),
      page("overworld_screen", "OVERWORLD SCREEN", overworldScreenRows),
      page("pokemoves", "POKéMOVES", pokemovesRows),
      page("rumble", "RUMBLE SETTINGS", rumbleRows),
      page("shortcuts", "SHORTCUTS SETTINGS", shortcutRows),
      page("start_menu", "START MENU SETTINGS", startMenuRows),
    }
    -- rows that don't apply to this game are false: drop them
    local out = {}
    for i = 1, #rows + 16 do
      if rows[i] then out[#out + 1] = rows[i] end
    end
    return out
  end

  -- SELECT on one of our rows that has onSelect (the option menus themselves
  -- ignore SELECT). FireRed/LeafGreen keep their page stack in _pages,
  -- Emerald in _st.pages, Ruby/Sapphire in _pages.
  local function selectRow(menu)
    local pages = menu._pages or (type(menu._st) == "table" and menu._st.pages) or nil
    local p = type(pages) == "table" and pages[#pages] or nil
    local row = p and type(p.rows) == "table" and p.rows[p.index] or nil
    if type(row) == "table" and type(row.onSelect) == "function" then
      row.onSelect()
      return true
    end
    return false
  end

  local function hookSelect(name)
    local ok, menu = pcall(require, name)
    if not (ok and type(menu) == "table" and type(menu.handleInput) == "function") then return end
    if menu._ph3Select then return end
    menu._ph3Select = true
    local orig = menu.handleInput
    menu.handleInput = function(input, ...)
      if input and input.wasPressed then
        local okP, pressed = pcall(input.wasPressed, input, "select")
        if okP and pressed then
          local okS, used = pcall(selectRow, menu)
          if okS and used then return end
        end
      end
      return orig(input, ...)
    end
  end

  function H.install()
    if H.installed then return end
    local Rows = require("src.ui.game3.option_rows")
    H.installed = true
    for _, name in ipairs({ "src.ui.game3.option_menu", "src.ui.game3.rse.option_menu", "src.ui.game3.rs.option_menu" }) do
      hookSelect(name)
    end
    local FrlgFont = require("src.ui.game3.frlg_font")
    local origDraw = FrlgFont.draw
    FrlgFont.draw = function(text, x, y, opts, ...)
      local pending = H.pending
      if pending ~= nil then
        H.pending = nil
        if text == pending then
          local ok, w = pcall(FrlgFont.measure, text, opts)
          if ok and tonumber(w) then x = VALUE_RIGHT - tonumber(w) end
        end
      end
      return origDraw(text, x, y, opts, ...)
    end
    local origGroup = Rows.group
    Rows.group = function(rows, openPage, ...)
      -- Full Control On: the stock CONTROLS page is hidden (it's overwritten)
      if type(rows) == "table" and ctx.fullControl and ctx.fullControl.enabled() then
        local kept = {}
        for _, row in ipairs(rows) do
          if not (type(row) == "table" and row.id == "controls") then kept[#kept + 1] = row end
        end
        rows = kept
      end
      local view = origGroup(rows, openPage, ...)
      if type(view) == "table" and type(openPage) == "function" then
        view[#view + 1] = {
          id = "ph3_hub", label = "PROJECT HIGHLANDER", value = function() return "" end,
          activate = function() openPage("PROJECT HIGHLANDER", hubRows(openPage)) end,
        }
      end
      return view
    end
  end

  return H
end
