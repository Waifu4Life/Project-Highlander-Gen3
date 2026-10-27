-- Bag additions for all five Gen 3 games.
--   * 255-item limit (always on): the bag holds up to 255 DIFFERENT items in
--     total (any quantity of each), instead of each pocket's own slot limit.
--     FireRed/LeafGreen: the TM CASE and BERRY POUCH count as one item each
--     (what's inside them doesn't count). Ruby/Sapphire/Emerald: every TM, HM
--     and berry counts. An "Items x/255" box shows the count in the bag.
--   * SELECT opens the TM CASE (FireRed/LeafGreen, outside battle, always on).
--   * QOL > OPEN BAG ON SPECIFIC POUCH: open the bag on a chosen pocket instead
--     of the last one used (in and out of battle).
return function(ctx)
  local B = { installed = false }
  local S = ctx.settings
  local Bag, ItemsData, FrlgFont

  local LIMIT = 255

  -- ------- counting

  local INSIDE_A_CASE = { TM_CASE = true, BERRY_POUCH = true }

  function B.count(bag)
    if type(bag) ~= "table" or type(bag.pockets) ~= "table" then return 0 end
    local hoenn = S.isHoenn()
    local n = 0
    for pocket, slots in pairs(bag.pockets) do
      if type(slots) == "table" and (hoenn or not INSIDE_A_CASE[pocket]) then
        for _, slot in ipairs(slots) do
          if type(slot) == "table" and slot.id ~= nil and (tonumber(slot.qty) or 0) > 0 then n = n + 1 end
        end
      end
    end
    return n
  end

  -- would adding `id` start a NEW entry that counts toward the 255?
  local function startsNewEntry(bag, id)
    local okG, have = pcall(Bag.get, bag, id)
    if okG and (tonumber(have) or 0) > 0 then return false end
    if not S.isHoenn() then
      local okP, pocket = pcall(ItemsData.pocketOf, id)
      if okP and INSIDE_A_CASE[pocket] then
        -- a TM/berry: only counts if the case itself would be new
        local caseId = pocket == "TM_CASE" and ItemsData.ITEM_TM_CASE or ItemsData.ITEM_BERRY_POUCH
        local okC, cases = pcall(Bag.get, bag, caseId)
        return not (okC and (tonumber(cases) or 0) > 0)
      end
    end
    return true
  end

  -- Each game profile carries its own pocket caps (FireRed/LeafGreen: Items 42,
  -- Key Items 30, Poké Balls 13), and the game copies them back into
  -- ItemsData.CAPACITY every time it (re)applies the profile -- on loading a
  -- save, switching games, etc. So the caps are lifted in the profiles too,
  -- and again after every profile apply.
  local function liftTable(t)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do
      if type(v) == "number" and v < LIMIT then t[k] = LIMIT end
    end
  end

  local function liftProfiles()
    local okP, Profile = pcall(require, "src.core.game3.profile")
    if not (okP and type(Profile) == "table") then return end
    for _, v in ipairs({ "firered", "leafgreen", "ruby", "sapphire", "emerald" }) do
      local okR, row = pcall(Profile.of, v)
      if okR and type(row) == "table" and type(row.bag) == "table" then liftTable(row.bag.capacity) end
    end
    if type(Profile.active) == "function" then
      local okA, row = pcall(Profile.active)
      if okA and type(row) == "table" and type(row.bag) == "table" then liftTable(row.bag.capacity) end
    end
  end

  local function liftCapacities()
    pcall(liftProfiles)
    for name, value in pairs(ItemsData) do
      if type(name) == "string" and name:upper():find("CAPACITY") and type(value) == "table" then
        for k, v in pairs(value) do
          if type(v) == "number" and v < LIMIT then value[k] = LIMIT end
          if type(v) == "table" then
            for k2, v2 in pairs(v) do
              if type(v2) == "number" and v2 < LIMIT then v[k2] = LIMIT end
            end
          end
        end
      end
    end
  end

  -- ------- open on a specific pocket

  -- option values per region, in the games' pocket order
  B.POUCHES = {
    kanto = { "off", "items", "key", "balls" },
    hoenn = { "off", "items", "balls", "tms", "berries", "key" },
  }
  B.POUCH_LABELS = { off = "OFF", items = "ITEMS", key = "KEY ITEMS", balls = "POKé BALLS",
    tms = "TMs & HMs", berries = "BERRIES" }
  local DEFAULT_INDEX = {
    kanto = { items = 1, key = 2, balls = 3 },
    hoenn = { items = 1, balls = 2, tms = 3, berries = 4, key = 5 },
  }
  local MATCH = {
    items = function(p) return p == "ITEMS" end,
    key = function(p) return p:find("KEY") ~= nil end,
    balls = function(p) return p:find("BALL") ~= nil end,
    tms = function(p) return p:find("TM") ~= nil end,
    berries = function(p) return p:find("BERR") ~= nil end,
  }

  local function region(session) return S.isHoenn(session) and "hoenn" or "kanto" end

  function B.pouchChoice(session)
    local r = region(session)
    local v = S.get("bag_pouch_" .. r)
    for _, id in ipairs(B.POUCHES[r]) do if id == v then return v end end
    return "off"
  end

  function B.stepPouch(session, dir)
    local r = region(session)
    local list, cur = B.POUCHES[r], B.pouchChoice(session)
    local i = 1
    for k, id in ipairs(list) do if id == cur then i = k break end end
    i = (i - 1 + (dir or 1)) % #list + 1
    S.set("bag_pouch_" .. r, list[i])
  end

  local function pocketIndex(choice, session, menu)
    local order = (menu and menu.POCKET_ORDER) or ItemsData.BAG_POCKET_ORDER
    local want = (region(session) == "hoenn") and 5 or 3
    if type(order) == "table" and #order == want and MATCH[choice] then
      for i, p in ipairs(order) do
        if type(p) == "string" and MATCH[choice](p:upper()) then return i, p end
      end
    end
    return DEFAULT_INDEX[region(session)][choice], nil
  end

  -- ------- the "Items x/255" box

  local function liveBag(menu)
    local bag = menu and (menu._bag or menu.bag)
    if type(bag) == "table" and bag.pockets then return bag end
    local session = menu and (menu._session or menu.session)
    if type(session) == "table" and type(session.bag) == "table" then return session.bag end
    local okR, Runtime = pcall(require, "src.core.game3.runtime")
    if okR and type(Runtime) == "table" and Runtime.getSession then
      local okS, live = pcall(Runtime.getSession)
      if okS and type(live) == "table" and type(live.bag) == "table" then return live.bag end
    end
    local g = S.game and S.game()
    local gs = g and g.session
    if type(gs) == "table" and type(gs.bag) == "table" then return gs.bag end
    return nil
  end

  -- one long row: "Items" on the left, the count right-aligned at the end
  local BOX_W = 78
  local function drawCounter(bag)
    local n = B.count(bag)
    local hoenn = S.isHoenn()
    -- Ruby/Sapphire/Emerald: top-left, under the pocket name and dots;
    -- FireRed/LeafGreen: bottom-left of the bag picture, above the description
    local x, y = 1, 99
    if hoenn then x, y = 0, 33 end
    local opts = { small = true, maxWidth = 120,
      colors = { fg = { 0.16, 0.16, 0.16, 1 }, shadow = { 0.80, 0.74, 0.50, 1 }, bg = FrlgFont.STDPAL[0] } }
    local numOpts = { small = true, maxWidth = 120, colors = {
      fg = n >= LIMIT and { 0.80, 0.16, 0.12, 1 } or opts.colors.fg, shadow = opts.colors.shadow, bg = opts.colors.bg } }
    local count = ("%d/%d"):format(n, LIMIT)
    local okW, tw = pcall(FrlgFont.measure, count, numOpts)
    tw = (okW and tonumber(tw)) or #count * 5
    local h, boxW, textY = 11, BOX_W, y - 2
    local v = S.version()
    if v == "ruby" or v == "sapphire" then
      -- Ruby/Sapphire: in the strip above the bag picture (clear of the bag),
      -- just as wide as the text; their small font prints about 8 px under y
      local okI, iw = pcall(FrlgFont.measure, "Items", opts)
      iw = (okI and tonumber(iw)) or 25
      x, y, h = 0, 0, 10
      boxW = 4 + iw + 5 + tw + 4
      textY = y + 2 - 8
    end
    love.graphics.push("all")
    love.graphics.setColor(0.22, 0.22, 0.25, 1)
    love.graphics.rectangle("fill", x, y, boxW, h + 2)
    love.graphics.setColor(0.99, 0.90, 0.58, 1)
    love.graphics.rectangle("fill", x + 1, y + 1, boxW - 2, h)
    FrlgFont.draw("Items", x + 4, textY, opts)
    FrlgFont.draw(count, x + boxW - 4 - tw, textY, numOpts)
    love.graphics.pop()
  end

  -- several paths may want to draw it in one frame; only the first does
  local drawnAt = -1
  local function now() return (love.timer and love.timer.getTime()) or 0 end
  local function drawnThisFrame() return now() - drawnAt < 0.004 end
  local function counterFor(menu)
    if drawnThisFrame() then return end
    if type(menu) == "table" and (menu.open == false or menu._open or menu._exit) then return end
    local bag = liveBag(menu)
    if not bag then return end
    drawnAt = now()
    if B.sort and B.sort.open then pcall(restore) end
    local ok, err = pcall(drawCounter, bag)
    if not ok and ctx.mod.log and not B.warned then
      B.warned = true
      ctx.mod.log:warn("bag counter: %s", tostring(err))
    end
    if B.sort then
      local okS, errS = pcall(B.sort.draw)
      if not okS and ctx.mod.log then ctx.mod.log:warn("bag sort draw: %s", tostring(errS)) end
    end
  end

  -- which loaded module is this table? (to recognise the Hoenn bag screen by name)
  local names, namesAt = {}, -1
  local function moduleName(mod)
    local now = (love.timer and love.timer.getTime()) or 0
    if names[mod] == nil and now - namesAt > 1 then
      namesAt = now
      names = {}
      for k, v in pairs(package.loaded) do
        if type(v) == "table" and type(k) == "string" then names[v] = k end
      end
    end
    return names[mod]
  end

  local function isBagScreen(mod, id)
    if type(mod) ~= "table" then return false end
    local name = ((type(id) == "string" and id or "") .. " " .. (moduleName(mod) or "")):lower()
    return name:find("bag") ~= nil and not name:find("berry") and not name:find("tm_case")
      and not name:find("powder") and not name:find("chrome")
  end
  B.isBagScreen = isBagScreen

  -- ------- SELECT: TM CASE (FireRed/LeafGreen)

  local function openTmCase(menu)
    local id = ItemsData.ITEM_TM_CASE
    if not id then return false end
    local okH, have = pcall(Bag.get, menu._bag, id)
    if not (okH and (tonumber(have) or 0) > 0) then return false end
    local okT, TmCase = pcall(require, "src.ui.game3.tm_case")
    if not (okT and type(TmCase) == "table" and TmCase.show) then return false end
    local saved = { pocketIdx = menu.pocketIdx, cursor = menu.cursor, scroll = menu.scroll }
    pcall(function() require("src.core.game3.audio").playSe(5) end)
    -- same route as USE on the TM CASE: the bag slides out, the case opens, and
    -- closing the case brings the bag back where it was
    menu._open, menu._switch = nil, nil
    menu._exit = { k = 0, curtain = false, cb = function()
      TmCase.show(menu._session, menu._bag, {
        session = menu._session, bag = menu._bag,
        onClose = function()
          menu.pocketIdx, menu.cursor, menu.scroll = saved.pocketIdx, saved.cursor, saved.scroll
          menu.mode = "list"
          if menu.open then menu._exit = nil; menu._open = { k = 0, curtain = false } end
        end,
      })
    end }
    return true
  end

  -- ------- hooks for one bag menu module

  -- While the sort menu is up, the bag underneath must not move. Ruby/Sapphire/
  -- Emerald's bag reads the d-pad outside handleInput, so: the menu reads the
  -- game's own input once per frame (from whichever hook runs first), the bag's
  -- update is paused, and its cursor/pocket are put back every frame.
  local snapshot, sortTick
  local KEEP = { "cursor", "scroll", "pocketIdx", "pocket", "mode", "actionCursor", "itemCursor", "listCursor" }
  local held = nil
  snapshot = function(menu)
    held = { menu = menu }
    for _, k in ipairs(KEEP) do held[k] = menu[k] end
  end
  local function restore()
    if not (held and B.sort and B.sort.open) then held = nil return end
    for _, k in ipairs(KEEP) do
      if held.menu[k] ~= held[k] then held.menu[k] = held[k] end
    end
  end
  B.restore = restore

  local tickAt = -1
  local function markTick() tickAt = (love.timer and love.timer.getTime()) or 0 end
  sortTick = function(menu, passed)
    local t = (love.timer and love.timer.getTime()) or 0
    if t - tickAt < 0.004 then return end
    tickAt = t
    local g = S.game and S.game()
    local input = (g and type(g.input) == "table" and g.input.wasPressed and g.input) or passed
    if not input then return end
    local wasOpen = B.sort.open
    local before = held
    B.sort.input(menu, liveBag(menu), input)
    if wasOpen and not B.sort.open and before then
      -- sorting may have moved the cursor on purpose: keep the new one
      held = nil
    else
      restore()
    end
  end

  local function hookMenu(menu, name)
    if type(menu) ~= "table" or menu._ph3Hooked then return end
    menu._ph3Hooked = true

    if type(menu.show) == "function" then
      local origShow = menu.show
      menu.show = function(sessionBag, opts, ...)
        opts = opts or {}
        local session = opts.session or (type(sessionBag) == "table" and sessionBag) or nil
        local choice = B.pouchChoice(session)
        if choice ~= "off" and opts.pocket == nil and opts.pocketIdx == nil
            and opts.location == nil and not opts.sell then
          local copy = {}
          for k, v in pairs(opts) do copy[k] = v end
          local idx, pocket = pocketIndex(choice, session, menu)
          copy.pocketIdx = idx
          if pocket then copy.pocket = pocket end
          opts = copy
        end
        if B.sort then B.sort.close() end
        return origShow(sessionBag, opts, ...)
      end
    end

    if type(menu.handleInput) == "function" then
      local origInput = menu.handleInput
      menu.handleInput = function(input, ...)
        local okSort, sorted = pcall(function()
          local Sort = B.sort
          if not (Sort and input and input.wasPressed) then return false end
          if menu.open == false then Sort.close() return false end
          if Sort.open then sortTick(menu, input) return true end
          if input:wasPressed("start") and (menu.mode == nil or menu.mode == "list")
              and not (menu._open or menu._exit or menu._switch) and menu._location == nil
              and liveBag(menu) then
            Sort.show()
            snapshot(menu)
            markTick() -- the START that opened it must not also close it this frame
            return true
          end
          return false
        end)
        if okSort and sorted then return end
        if not okSort and ctx.mod.log then ctx.mod.log:warn("bag sort input (%s): %s", name, tostring(sorted)) end
        local ok, handled = pcall(function()
          return input and input.wasPressed and input:wasPressed("select")
            and not S.isHoenn() and menu.open and menu.mode == "list"
            and not menu._battle and menu._location == nil
            and not (menu._open or menu._exit or menu._switch)
            and openTmCase(menu)
        end)
        if ok and handled then return end
        if not ok and ctx.mod.log then ctx.mod.log:warn("bag select (%s): %s", name, tostring(handled)) end
        return origInput(input, ...)
      end
    end

    for _, fn in ipairs({ "update", "tick" }) do
      if type(menu[fn]) == "function" then
        local orig = menu[fn]
        menu[fn] = function(...)
          if B.sort and B.sort.open and held and held.menu == menu then
            pcall(sortTick, menu, nil)
            return
          end
          return orig(...)
        end
      end
    end

    if type(menu.draw) == "function" then
      local origDraw = menu.draw
      menu.draw = function(...)
        local r = { origDraw(...) }
        counterFor(menu)
        return (table.unpack or unpack)(r)
      end
    end
  end

  function B.install()
    if B.installed then return end
    Bag = require("src.core.game3.bag")
    ItemsData = require("src.core.game3.items_data")
    FrlgFont = require("src.ui.game3.frlg_font")
    B.installed = true
    local okSort, mk = pcall(function()
      local src = assert(ctx.mod:read("components/bag/sort.lua"))
      return assert(load(src, "@" .. tostring(ctx.mod.path) .. "/components/bag/sort.lua"))()
    end)
    if okSort then
      B.sort = mk(ctx, { ItemsData = ItemsData, FrlgFont = FrlgFont, Bag = Bag })
    elseif ctx.mod.log then
      ctx.mod.log:warn("bag sort load: %s", tostring(mk))
    end

    pcall(liftCapacities)
    if type(ItemsData.applyProfile) == "function" then
      local origApply = ItemsData.applyProfile
      ItemsData.applyProfile = function(...)
        local r = { origApply(...) }
        pcall(liftCapacities)
        return (table.unpack or unpack)(r)
      end
    end
    if type(ItemsData.ensureModel) == "function" then
      local origEnsure = ItemsData.ensureModel
      ItemsData.ensureModel = function(...)
        local r = { origEnsure(...) }
        if (ItemsData.CAPACITY.ITEMS or LIMIT) < LIMIT then pcall(liftCapacities) end
        return (table.unpack or unpack)(r)
      end
    end
    local origCanAdd = Bag.canAdd
    if type(origCanAdd) == "function" then
      Bag.canAdd = function(bag, id, qty, ...)
        local okN, isNew = pcall(startsNewEntry, bag, id)
        if okN and isNew and B.count(bag) >= LIMIT then return false end
        return origCanAdd(bag, id, qty, ...)
      end
    end

    -- Any screen pushed onto the UI stack under a "bag" name gets the same hooks
    -- (Ruby/Sapphire/Emerald use their own bag screen). The first time such a
    -- screen opens it was already set up, so the chosen pocket is applied here.
    local okSt, Stack = pcall(require, "src.ui.game3.stack")
    if okSt and type(Stack) == "table" and type(Stack.push) == "function" then
      local origPush = Stack.push
      Stack.push = function(id, mod, opts, ...)
        local result = origPush(id, mod, opts, ...)
        pcall(function()
          local name = type(id) == "string" and id:lower() or ""
          local looksLikeBag = name:find("bag") or (name:find("item") and not name:find("pc")
            and (type(mod) == "table" and (mod.pocketIdx ~= nil or mod.pocket ~= nil or mod.pockets ~= nil)))
          if type(mod) == "table" and looksLikeBag and not name:find("berry")
              and not name:find("tm") and not mod._ph3Hooked then
            hookMenu(mod, id)
            if ctx.mod.log and ctx.mod.log.info then ctx.mod.log:info("bag hooks on screen '%s'", tostring(id)) end
            local choice = B.pouchChoice()
            if choice ~= "off" and type(mod.pocketIdx) == "number" and mod._location == nil then
              local idx = pocketIndex(choice, nil, mod)
              if idx and idx ~= mod.pocketIdx then
                mod.pocketIdx = idx
                if type(mod.cursor) == "number" then mod.cursor = 1 end
                if type(mod.scroll) == "number" then mod.scroll = 0 end
              end
            end
          end
        end)
        return result
      end
    end

    -- The counter rides on the UI stack: right after a bag screen's layer, so
    -- anything opened on top of the bag (messages, menus) still covers it.
    if okSt and type(Stack) == "table" and type(Stack.drawOrder) == "function" then
      local origOrder = Stack.drawOrder
      Stack.drawOrder = function(...)
        local order = origOrder(...)
        local ok = pcall(function()
          if type(order) ~= "table" then return end
          for i = #order, 1, -1 do
            local layer = order[i]
            if type(layer) == "table" and isBagScreen(layer.mod, layer.id) then
              local bagMod = layer.mod
              if not bagMod._ph3Hooked then hookMenu(bagMod, layer.id or moduleName(bagMod) or "?") end
              local copy = {}
              for k = 1, i do copy[k] = order[k] end
              copy[i + 1] = { id = "ph3_bag_counter", mod = { draw = function() counterFor(bagMod) end } }
              for k = i + 1, #order do copy[#copy + 1] = order[k] end
              order = copy
              break
            end
          end
        end)
        return order
      end
    end
    -- last resort: a bag screen that is open but not on the stack
    local okU, UiPass = pcall(require, "src.ui.game3.ui_pass")
    if okU and type(UiPass) == "table" and type(UiPass.drawUi) == "function" then
      local origUi = UiPass.drawUi
      UiPass.drawUi = function(...)
        local r = { origUi(...) }
        if not drawnThisFrame() then
          pcall(function()
            for k, v in pairs(package.loaded) do
              if type(k) == "string" and type(v) == "table" and isBagScreen(v, k)
                  and type(v.isOpen) == "function" and k:find("src.ui", 1, true) then
                local okO, open = pcall(v.isOpen)
                if okO and open then counterFor(v) break end
              end
            end
          end)
        end
        return (table.unpack or unpack)(r)
      end
    end

    local okM, BagMenu = pcall(require, "src.ui.game3.bag_menu")
    if okM then hookMenu(BagMenu, "bag_menu") end
    -- Ruby/Sapphire/Emerald may use their own bag screen; hook it the same way if present
    for _, modName in ipairs({ "src.ui.game3.rs.bag_menu", "src.ui.game3.rs.bag" }) do
      local okR, RsBag = pcall(require, modName)
      if okR and type(RsBag) == "table" then hookMenu(RsBag, modName) end
    end
  end

  return B
end
