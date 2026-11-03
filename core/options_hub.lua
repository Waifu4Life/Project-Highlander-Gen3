-- Adds PROJECT HIGHLANDER to the game's own OPTIONS menu (FRLG, RS and
-- Emerald option menus all build their top page through option_rows.group).
-- Sub-menus: Enable on top, then alphabetical.
return function(ctx)
  local H = { installed = false }
  local S, Themes = ctx.settings, ctx.themes

  local function onOff(v) return v and "ON" or "OFF" end

  -- Project Highlander's pages have no CANCEL row (B goes back), like Gen 1/2
  function H.ours(rows)
    if type(rows) == "table" then rows.ph3NoCancel = true end
    return rows
  end

  local function pagesOf(menu)
    return menu._pages or (type(menu._st) == "table" and menu._st.pages) or nil
  end

  local function topPage(menu)
    local pages = pagesOf(menu)
    return type(pages) == "table" and pages[#pages] or nil, pages
  end

  -- the cursor never lands on the game's CANCEL row of our pages: going
  -- down from the last row goes round to the first, up from the first to the last
  local function skipCancel(menu, p0, before, setCursor)
    local p = topPage(menu)
    if not (p and p == p0 and type(p.rows) == "table" and p.rows.ph3NoCancel) then return end
    local n = #p.rows
    if n == 0 or (tonumber(p.index) or 1) <= n then return end
    if before == n then
      p.index, p.scroll = 1, 0
    else
      p.index = n
    end
    if setCursor then menu.cursor = p.index end
  end

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

  -- START MENU SETTINGS > HIDE ITEMS: MODS and other mods' items, A-Z
  local function hideRows()
    local rows = {}
    for _, it in ipairs(ctx.startMenu.hideItems()) do
      rows[#rows + 1] = {
        id = "ph3_hide_" .. it.key, label = it.label,
        value = aligned(function() return S.isHidden(it.key) and "HIDE" or "SHOW" end),
        step = function()
          S.setHidden(it.key, not S.isHidden(it.key))
          return true
        end,
      }
    end
    return rows
  end

  -- START MENU SETTINGS > CUSTOM RENAME: every item, A-Z; A opens the
  -- keyboard (up to 10 characters), an empty name puts the usual one back
  local function renameRows(session)
    pcall(ctx.startMenu.syncNames)
    local rows = {}
    for _, it in ipairs(ctx.startMenu.renameItems(session)) do
      rows[#rows + 1] = {
        id = "ph3_name_" .. it.key, label = it.label,
        value = aligned(function() return S.nameFor(it.key) or "----" end),
        activate = function(c)
          ctx.startMenu.rename(it.key, (c and c.session) or session)
        end,
      }
    end
    return rows
  end

  -- Same order as Gen 1/2: ENABLE, CLOCK, THEME (COLOUR), SAVE THEME (COLOUR
  -- SCOPE), CUSTOM ICONS, CUSTOM RENAME, HIDE ITEMS, SORT MENU. POKéBOX is in
  -- HIDE ITEMS, like Gen 1/2.
  local START_ORDER = { "ph3_start_enabled", "ph3_clock", "ph3_theme", "ph3_theme_scope",
    "ph3_custom_icons", "ph3_custom_rename", "ph3_hide_items", "ph3_sort" }
  local startMenuRowsRaw
  local function startMenuRows()
    local byId = {}
    for _, r in ipairs(startMenuRowsRaw()) do byId[r.id] = r end
    local out = {}
    for _, id in ipairs(START_ORDER) do
      if byId[id] then out[#out + 1] = byId[id] end
    end
    return out
  end

  startMenuRowsRaw = function()
    return {
      toggleRow("start_enabled", "ENABLE", "start_enabled"),
      {
        id = "ph3_clock", label = "CLOCK",
        value = aligned(function(c) return S.clockLabel(c and c.session) end),
        step = function(c, dir)
          S.stepClock(c and c.session, dir)
          return true
        end,
      },
      {
        id = "ph3_custom_icons", label = "CUSTOM ICONS", value = function() return "" end,
        activate = function(c)
          ctx.iconScreen.show({ session = c and c.session })
        end,
      },
      {
        id = "ph3_custom_rename", label = "CUSTOM RENAME", value = function() return "" end,
        activate = function(c)
          H.openPage("CUSTOM RENAME", H.ours(renameRows(c and c.session)))
        end,
      },
      {
        id = "ph3_hide_items", label = "HIDE ITEMS", value = function() return "" end,
        activate = function()
          H.openPage("HIDE ITEMS", H.ours(hideRows()))
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
      toggleRow("battle_effectiveness", "DISPLAY EFFECTIVENESS", "battle_effectiveness"),
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
      toggleRow("status_reset", "STATUS CONDITION RESET", "status_reset"),
      toggleRow("unlimited_pp", "UNLIMITED PP", "unlimited_pp"),
    }
  end

  local function overworldScreenRows()
    return {
      toggleRow("rematch_anyone", "REMATCH ANYONE, ANYTIME", "rematch_anyone"),
      toggleRow("run_everywhere", "RUN EVERYWHERE", "run_everywhere"),
      toggleRow("sparkling_hidden", "SPARKLING HIDDEN ITEMS", "sparkling_hidden"),
      toggleRow("use_repel_again", "USE REPEL AGAIN?", "use_repel_again"),
    }
  end

  -- Alphabetical (Kanto and Hoenn Safari Zones).
  local function safariRows()
    return {
      toggleRow("infinite_safari", "INFINITE SAFARI STEPS", "infinite_safari"),
      toggleRow("safari_no_run", "NO RUNNING AWAY", "safari_no_run"),
      toggleRow("safari_unlimited_balls", "UNLIMITED BALLS", "safari_unlimited_balls"),
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
        value = aligned(function()
          if JB.previewing() == song.name then return "PLAY" end
          return onOff(JB.isOn(song.name))
        end),
        step = function()
          JB.toggle(song.name)
          return true
        end,
        -- SELECT: play this song until SELECT again or the page is left
        onSelect = function(menu, pg)
          JB.preview(song, function()
            if type(menu) ~= "table" then return false end
            if type(menu.isOpen) == "function" then
              local okO, open = pcall(menu.isOpen)
              if okO and not open then return false end
            end
            local pages = menu._pages or (type(menu._st) == "table" and menu._st.pages) or nil
            return type(pages) == "table" and pages[#pages] == pg
          end)
        end,
      }
    end
    return rows
  end

  local function hubRows(openPage)
    local function page(id, label, build)
      return {
        id = "ph3_" .. id, label = label, value = function() return "" end,
        activate = function() openPage(label, H.ours(build())) end,
      }
    end
    -- Three categories, each with its pages in a set order (like Gen 1/2)
    local function category(id, label, entries)
      return {
        id = "ph3_" .. id, label = label, value = function() return "" end,
        activate = function()
          local out = {}
          for i = 1, #entries + 4 do
            if entries[i] then out[#out + 1] = entries[i] end
          end
          openPage(label, H.ours(out))
        end,
      }
    end
    local hoenn = S.isHoenn()
    return {
      category("cat_mechanics", "MECHANICS", {
        page("battle_screen", "BATTLE SCREEN", battleScreenRows),
        page("overworld_screen", "OVERWORLD SCREEN", overworldScreenRows),
        page("pokemoves", "POKéMOVES", pokemovesRows),
        page("shortcuts", "SHORTCUTS SETTINGS", shortcutRows),
        page("game_corner", "GAME CORNER CHEATS", gameCornerRows),
        page("safari_zone", "SAFARI ZONE CHEATS", safariRows),
      }),
      category("cat_system", "SYSTEM", {
        page("start_menu", "START MENU SETTINGS", startMenuRows),
        page("other_system", "OTHER SYSTEM SETTINGS", otherSystemRows),
        page("full_control", "FULL CONTROL", fullControlRows),
        page("rumble", "RUMBLE SETTINGS", rumbleRows),
        -- Ruby / Sapphire / Emerald: Hoenn's dex in the same place
        hoenn and page("hoenn_all", "FILL HOENN REGIONAL DEX", hoennRows)
          or page("kanto_all", "FILL KANTO REGIONAL DEX", kantoRows),
        page("johto_helper", "JOHTO POKéMON HELPER", johtoRows),
      }),
      category("cat_cosmetics", "COSMETICS", {
        page("jukebox", "JUKEBOX", jukeboxRows),
        page("borders", "CUSTOM BORDERS", borderRows),
        page("anim_sprites", "ANIMATED SPRITES", animRows),
      }),
    }
  end

  -- SELECT on one of our rows that has onSelect (the option menus themselves
  -- ignore SELECT). FireRed/LeafGreen keep their page stack in _pages,
  -- Emerald in _st.pages, Ruby/Sapphire in _pages.
  local function selectRow(menu)
    local pages = menu._pages or (type(menu._st) == "table" and menu._st.pages) or nil
    local p = type(pages) == "table" and pages[#pages] or nil
    local row = p and type(p.rows) == "table" and p.rows[p.index] or nil
    if type(row) == "table" and type(row.onSelect) == "function" then
      row.onSelect(menu, p)
      return true
    end
    return false
  end

  local function hookSelect(name)
    local ok, menu = pcall(require, name)
    if not (ok and type(menu) == "table" and type(menu.handleInput) == "function") then return end
    if menu._ph3Select then return end
    menu._ph3Select = true
    -- Ruby/Sapphire keep Menu.cursor on the top page; the others on the open page
    local setCursor = name ~= "src.ui.game3.rs.option_menu"
    local orig = menu.handleInput
    menu.handleInput = function(input, ...)
      if input and input.wasPressed then
        local okP, pressed = pcall(input.wasPressed, input, "select")
        if okP and pressed then
          local okS, used = pcall(selectRow, menu)
          if okS and used then return end
        end
      end
      local p0 = topPage(menu)
      local before = p0 and p0.index
      local r = { orig(input, ...) }
      pcall(skipCancel, menu, p0, before, setCursor)
      return (table.unpack or unpack)(r)
    end
    -- and the CANCEL row isn't drawn on our pages
    if type(menu.draw) == "function" then
      local origDraw = menu.draw
      menu.draw = function(...)
        local okT, p = pcall(topPage, menu)
        H.drawingOurs = okT and type(p) == "table" and type(p.rows) == "table" and p.rows.ph3NoCancel == true
        local okD, err = pcall(origDraw, ...)
        H.drawingOurs = false
        if not okD then error(err, 0) end
      end
    end
  end

  local cancelTexts = nil
  local function isCancel(text)
    if not cancelTexts then
      cancelTexts = { CANCEL = true, Cancel = true }
      local okR, RomText = pcall(require, "src.core.game3.rom_text")
      if okR then
        for _, k in ipairs({ "gText_OptionMenuCancel", "gText_Cancel", "gText_Cancel2" }) do
          local okT, t = pcall(RomText.plain, k)
          if okT and type(t) == "string" and t ~= "" then cancelTexts[t] = true end
        end
      end
    end
    return cancelTexts[text] == true
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
      if H.drawingOurs and type(text) == "string" and isCancel(text) then return 0 end
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
      pcall(function()
        if type(view) ~= "table" then return end
        local native = {}
        for _, id in ipairs(Rows.ORDER or {}) do native[id] = true end
        local seen = {}
        for _, row in ipairs(view) do
          if type(row) == "table" and type(row.activate) == "function" and not row.group
              and not (row.id ~= nil and native[row.id]) and row.id ~= "ph3_hub" then
            local key = ctx.startMenu.rowKey(row)
            if key then seen[#seen + 1] = { key = key, label = tostring(row.label or key) } end
          end
        end
        S.rememberOptionRows(seen)
      end)
      if type(view) == "table" and type(openPage) == "function" then
        view[#view + 1] = {
          id = "ph3_hub", label = "PROJECT HIGHLANDER", value = function() return "" end,
          activate = function()
            H.openPage = openPage
            openPage("PROJECT HIGHLANDER", H.ours(hubRows(openPage)))
          end,
        }
      end
      return view
    end
  end

  return H
end
