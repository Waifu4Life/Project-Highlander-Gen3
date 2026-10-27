-- CUSTOM BORDERS (OPTIONS > PROJECT HIGHLANDER > CUSTOM BORDERS)
-- Paints border art in the space around the 240x160 GBA screen, like the
-- Gen 1/2 Custom Borders. The art lives in assets/borders/*.png, 16:9 with the
-- game window at the template's place (3840x2160: hole at 360,40, 3120x2080,
-- or the same proportions at any size). Only the parts outside the game
-- window are drawn, so whatever a custom PNG holds in the middle never shows.
--
-- Where it appears: screens that keep the GBA box -- battles, full-screen
-- menus (Bag, Party, Pokédex, Options, PC...), the shop view and the title
-- and boot screens. G1R draws the overworld across the whole window, so the
-- overworld never gets a border.
--
--   ENABLE        Off by default
--   BORDER        Automatic (follows the cartridge), FireRed, LeafGreen,
--                 Ruby, Sapphire, Emerald, Custom 1-4
--   BORDER SCOPE  By Game / By Save
--   SCREEN RATIO  Off / 16:9 -- runs the game in a 16:9 area (Steam Deck 16:10...)
return function(ctx)
  local B = { installed = false }
  local S = ctx.settings
  local mod = ctx.mod

  B.CHOICES = {
    { "AUTOMATIC", "auto" },
    { "FIRERED", "firered" }, { "LEAFGREEN", "leafgreen" },
    { "RUBY", "ruby" }, { "SAPPHIRE", "sapphire" }, { "EMERALD", "emerald" },
    { "CUSTOM 1", "custom1" }, { "CUSTOM 2", "custom2" },
    { "CUSTOM 3", "custom3" }, { "CUSTOM 4", "custom4" },
  }
  local OK = {}
  for _, c in ipairs(B.CHOICES) do OK[c[2]] = true end

  -- template proportions (3840x2160 with the hole at 360,40 3120x2080)
  local HOLE = { x = 360 / 3840, y = 40 / 2160, w = 3120 / 3840, h = 2080 / 2160 }

  local function mreq(name)
    local ok, m = pcall(require, name)
    if ok and type(m) == "table" then return m end
    return nil
  end

  local function on() return S.get("borders_enabled") == true end

  -- ------- choice (by game or by save)

  function B.scope() return S.get("border_scope") == "save" and "save" or "game" end

  function B.choice(session)
    local found
    if B.scope() == "save" then
      local ok, v = pcall(mod.save.get, mod.save, "border")
      if ok and OK[v] then found = v end
    end
    if not found then
      local v = S.get("border_" .. S.version(session))
      if OK[v] then found = v end
    end
    return found or "auto"
  end

  function B.setChoice(session, value)
    if not OK[value] then return end
    if B.scope() == "save" then
      pcall(mod.save.set, mod.save, "border", value)
    else
      S.set("border_" .. S.version(session), value)
    end
  end

  function B.step(session, dir)
    local cur, index = B.choice(session), 1
    for i, c in ipairs(B.CHOICES) do if c[2] == cur then index = i end end
    index = (index - 1 + (dir or 1)) % #B.CHOICES + 1
    B.setChoice(session, B.CHOICES[index][2])
  end

  function B.label(session)
    local cur = B.choice(session)
    for _, c in ipairs(B.CHOICES) do if c[2] == cur then return c[1] end end
    return "AUTOMATIC"
  end

  local function resolved(session)
    local c = B.choice(session)
    if c == "auto" then
      local v = S.version(session)
      return OK[v] and v or "firered"
    end
    return c
  end

  -- ------- art

  local images = {}
  local function image(key)
    if images[key] ~= nil then return images[key] or nil end
    local ok, img = pcall(function() return mod.assets:image("assets/borders/" .. key .. ".png") end)
    if ok and img then
      pcall(img.setFilter, img, "linear", "linear")
      images[key] = img
    else
      images[key] = false
    end
    return images[key] or nil
  end

  local quads = {}
  local function quadSet(iw, ih)
    local id = iw .. "x" .. ih
    if quads[id] then return quads[id] end
    local G = love.graphics
    local hx, hy = math.floor(iw * HOLE.x + 0.5), math.floor(ih * HOLE.y + 0.5)
    local hw, hh = math.floor(iw * HOLE.w + 0.5), math.floor(ih * HOLE.h + 0.5)
    local set = { hx = hx, hy = hy, hw = hw, hh = hh, rx = hx + hw, by = hy + hh, iw = iw, ih = ih }
    set.left = G.newQuad(0, hy, hx, hh, iw, ih)
    set.right = G.newQuad(hx + hw, hy, iw - hx - hw, hh, iw, ih)
    set.top = hy > 0 and G.newQuad(0, 0, iw, hy, iw, ih) or nil
    set.bottom = (ih - hy - hh) > 0 and G.newQuad(0, hy + hh, iw, ih - hy - hh, iw, ih) or nil
    quads[id] = set
    return set
  end

  -- Each piece is stretched to fill its gap exactly: the pillars beside the
  -- game window, and the full-width bars above and below it.
  local function drawBorder(img, rect, winW, winH)
    local G = love.graphics
    local iw, ih = img:getDimensions()
    local q = quadSet(iw, ih)
    local x0, y0 = rect.x, rect.y
    local x1, y1 = rect.x + rect.w, rect.y + rect.h
    local sy = rect.h / q.hh
    if x0 > 0 then G.draw(img, q.left, 0, y0, 0, x0 / q.hx, sy) end
    if winW - x1 > 0 then G.draw(img, q.right, x1, y0, 0, (winW - x1) / (q.iw - q.rx), sy) end
    if q.top and y0 > 0 then G.draw(img, q.top, 0, 0, 0, winW / q.iw, y0 / q.hy) end
    if q.bottom and winH - y1 > 0 then
      G.draw(img, q.bottom, 0, y1, 0, winW / q.iw, (winH - y1) / (q.ih - q.by))
    end
  end

  -- ------- where the GBA box is this frame

  local function boxedFrame()
    local Battle = mreq("src.core.game3.battle")
    if Battle and Battle.isActive and Battle.isActive() then return true end
    local Stack = mreq("src.ui.game3.stack")
    if Stack and Stack.fullscreen and Stack.fullscreen() then return true end
    if Stack and Stack.has and Stack.has("minigame") then return true end
    local Shop = mreq("src.ui.game3.shop_menu")
    if Shop and Shop.isShopCamera and Shop.isShopCamera() then return true end
    return false
  end

  local function gameRect(Display, winW, winH)
    if not Display.planesBroken then
      local Renderer = mreq("src.render.Renderer")
      if Renderer and Renderer.frameRects then
        local ok, r = pcall(Renderer.frameRects, Renderer)
        if ok and type(r) == "table" and r.uvpw then
          return { x = r.uox, y = r.uoy, w = r.uvpw, h = r.uvph }
        end
      end
    end
    local ok, scale, ox, oy, _, _, scaleY = pcall(Display.fit, winW, winH)
    if ok and scale then
      return { x = ox, y = oy, w = (Display.W or 240) * scale, h = (Display.H or 160) * (scaleY or scale) }
    end
    return nil
  end

  local function paint(Display, session)
    if not on() then return end
    local G = love.graphics
    local winW, winH = G.getDimensions()
    local rect = gameRect(Display, winW, winH)
    if not rect or rect.w <= 0 or rect.h <= 0 then return end
    -- The game already fills the window: nothing to decorate.
    if rect.x <= 2 and rect.x + rect.w >= winW - 2 and rect.y <= 2 and rect.y + rect.h >= winH - 2 then return end
    local img = image(resolved(session))
    if not img then return end
    G.push("all")
    G.origin()
    G.setScissor()
    pcall(G.setShader)
    G.setBlendMode("alpha")
    G.setColor(1, 1, 1, 1)
    pcall(drawBorder, img, rect, winW, winH)
    G.pop()
  end

  function B.install()
    if B.installed then return end
    local Display = require("src.core.game3.display")
    B.installed = true
    local origPresent, origUi = Display.present, Display.presentUi
    Display.present = function(game, winW, winH, ...)
      local boxed = on() and boxedFrame()
      local r1, r2, r3 = origPresent(game, winW, winH, ...)
      if boxed then pcall(paint, Display, game and game.session) end
      return r1, r2, r3
    end
    if type(origUi) == "function" then
      Display.presentUi = function(game, winW, winH, kind, drawFn, ...)
        local r1, r2, r3 = origUi(game, winW, winH, kind, drawFn, ...)
        if r1 then pcall(paint, Display, game and game.session) end
        return r1, r2, r3
      end
    end

    -- SCREEN RATIO: the Gen 1/2 module, fed this mod's setting.
    local shim = {
      options = { get = function(_, key) if key == "screen_ratio" then return S.get("screen_ratio") end end },
      log = mod.log, exports = {},
    }
    local okR, err = pcall(function()
      local source = assert(mod:read("components/borders/screen_ratio.lua"))
      local chunk = assert(load(source, "@" .. tostring(mod.path) .. "/components/borders/screen_ratio.lua"))
      chunk()(shim)
    end)
    if not okR and mod.log then pcall(mod.log.warn, mod.log, "Screen Ratio unavailable: %s", tostring(err)) end
    B.ratioLabel = function()
      local f = shim.exports.screenRatioLabel
      if type(f) == "function" then
        local ok, v = pcall(f)
        if ok and v then return v end
      end
      return S.get("screen_ratio") == "16:9" and "16:9" or "OFF"
    end
  end

  return B
end
