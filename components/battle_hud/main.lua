-- Battle HUD for all five Gen 3 games.
--   DISPLAY ENEMY HP:   current/max HP in numbers under the enemy's HP bar
--                       (like the player's), on a small plate below the box.
--   COLORED MOVE NAMES: each move name sits in a rounded box filled with the
--                       move's type colour (Gen 1/2 Battle HUD style).
--   LOW HP WARNING:     NORMAL = the game's looping beep while your HP bar is
--                       red. REDUCED = a few beeps when the bar turns red, then
--                       quiet until it leaves the red and comes back (or another
--                       Pokémon comes out). OFF = no beep.
return function(ctx, TypeColors)
  local B = { installed = false }
  local S = ctx.settings

  local Ui, Moves, Types, FrlgFont, Healthbox
  local inMoveDraw = false
  local pendingMove = nil

  local function c5(v) return math.floor(v * 255 / 31 + 0.5) / 255 end
  local CREAM = { c5(31), c5(31), c5(27), 1 }
  local INK = { c5(8), c5(8), c5(8), 1 }
  local INK_SHADOW = { c5(27), c5(26), c5(22), 1 }
  local EDGE = { 0.16, 0.20, 0.16, 1 } -- healthbox outline
  local HP_TEXT = { fg = INK, shadow = INK_SHADOW }

  local function battleState()
    local st = Ui and Ui._st
    if st then return st end
    local ok, Battle = pcall(require, "src.core.game3.battle")
    return ok and type(Battle) == "table" and Battle._st or nil
  end

  local function activeMon()
    local st = battleState()
    return st and st.player and st.player.mon
  end

  local function moveKey(mv, name)
    local def = Moves.get(mv)
    local typeId = def and def.type
    local mon = activeMon()
    if mon and mon.moves then
      for slot = 1, 4 do
        if mon.moves[slot] == mv then
          local ok, t = pcall(Ui.moveTypeOf, mon, slot, def or {})
          if ok and t ~= nil then typeId = t end
          break
        end
      end
    end
    local key = TypeColors.key(typeId, Types)
    return TypeColors.resolve(key, name, S.get("fairy_type") == true)
  end

  -- A thin frame in the move's type colour around the name; the inside stays
  -- white, the game's pointing arrow stays visible, and there is a gap between
  -- the name and the frame and between neighbouring frames.
  -- Same-size frames for all four moves: a thick band of the type colour on
  -- top (there is room above each name), 1 px type-colour sides and bottom,
  -- white inside. The game's pointing arrow stays visible to the left.
  local function drawMoveBox(key, text, x, y, opts)
    local okL, layout = pcall(function() return require("src.ui.game3.battle_chrome").layout() end)
    -- same frame as before (1 px, around the name); the colour band fills the
    -- three empty rows above the letters
    local bx, by, w, h, band = x - 3, y - 1, 64, 15, 3
    -- Ruby/Sapphire: the bigger font starts 1 px left of x and fills y+2..y+13
    if okL and layout == "rs" then bx, by, w, h, band = x - 4, y - 2, 72, 17, 2 end
    local r, g, b = TypeColors.rgb(key)
    love.graphics.push("all")
    love.graphics.setColor(r * 0.85, g * 0.85, b * 0.85, 1)
    love.graphics.rectangle("fill", bx, by, w, h, 2, 2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", bx + 1, by + band, w - 2, h - band - 1)
    love.graphics.pop()
  end

  -- ------- enemy HP numbers

  local SHADOW = { 82 / 255, 106 / 255, 98 / 255, 1 } -- healthbox pointer/shadow colour

  local function enemyPanelShown(battler, opts)
    if not battler or not S.flag("battle_enemy_hp") then return false end
    local Anim = require("src.core.game3.battle.anim")
    local bst = battleState()
    -- double battles: no room, the game shows only the bars (even for the player)
    if bst and bst.double then return false end
    if bst and bst.ghostBattle then
      local pg = Anim.present and Anim.present("enemy")
      if not (pg and pg.ghostUnveiled) then return false end
    end
    local stage = Anim.stage and Anim.stage()
    local hb = stage and stage.healthbox and stage.healthbox.enemy
    if hb and hb.visible == false then return false end
    return true
  end

  -- The box grows downward, so the box's pointer triangle (right side,
  -- image rows CUT_Y and below) is drawn DROP rows lower and ends with it.
  local CUT_X, CUT_Y, DROP = 92, 20, 5
  local quads = {}
  local function drawSplitEnemyBox(img, x, y)
    local W, H = img:getDimensions()
    if quads.img ~= img then
      quads = {
        img = img,
        left = love.graphics.newQuad(0, 0, CUT_X, H, W, H),
        rightTop = love.graphics.newQuad(CUT_X, 0, W - CUT_X, CUT_Y, W, H),
        rightBottom = love.graphics.newQuad(CUT_X, CUT_Y, W - CUT_X, H - CUT_Y, W, H),
        strip = love.graphics.newQuad(CUT_X, CUT_Y - 1, W - CUT_X, 1, W, H),
      }
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(img, quads.left, x, y)
    love.graphics.draw(img, quads.rightTop, x + CUT_X, y)
    -- the shadow column keeps running down beside the taller box
    love.graphics.draw(img, quads.strip, x + CUT_X, y + CUT_Y, 0, 1, DROP)
    love.graphics.draw(img, quads.rightBottom, x + CUT_X, y + CUT_Y + DROP)
  end

  local function drawEnemyHp(battler, opts)
    if not enemyPanelShown(battler, opts) then return end
    local Anim = require("src.core.game3.battle.anim")
    local stage = Anim.stage and Anim.stage()
    local hb = stage and stage.healthbox and stage.healthbox.enemy
    local ox = ((hb and hb.ox) or 0) + ((opts and opts.ox) or 0)
    local oy = (opts and opts.oy) or 0
    local c = Healthbox.ENEMY_CENTER
    local tlX, tlY = c.x + ox - 32, c.y + oy - 16
    local hp, maxHp
    if Anim.displayHpRatio then
      local _, h, m = Anim.displayHpRatio("enemy", battler)
      hp, maxHp = tonumber(h), tonumber(m)
    end
    local mon = battler.mon
    hp = math.floor(hp or tonumber(mon and mon.hp) or 0)
    maxHp = math.floor(maxHp or tonumber(mon and mon.maxHp) or 1)
    local text = string.format("%3d/%3d", math.max(0, hp), math.max(1, maxHp))
    local tOpts = { small = true, colors = { fg = INK, shadow = INK_SHADOW, bg = FrlgFont.STDPAL[0] } }
    local ok, w = pcall(FrlgFont.measure, text, tOpts)
    w = ok and tonumber(w) or 36
    -- one box: the box's bottom line is covered and the panel continues it
    local px, top, pw, bottom = tlX + 1, tlY + 24, 91, tlY + 34
    love.graphics.push("all")
    love.graphics.setColor(EDGE)
    love.graphics.rectangle("fill", px, top + 1, pw, bottom - top, 2, 2)
    -- left edge 2 px wide, like the box above it
    love.graphics.setColor(CREAM)
    love.graphics.rectangle("fill", px + 2, top, pw - 3, bottom - top, 1, 1)
    -- shadow column between the box's right edge and the pointer triangle,
    -- so box, panel and triangle read as one piece
    love.graphics.setColor(SHADOW)
    love.graphics.rectangle("fill", tlX + CUT_X, tlY + CUT_Y, 1, (bottom - tlY) - CUT_Y + 1)
    love.graphics.pop()
    -- same row as the player's numbers (pret HP_TEXT_Y = 21); Ruby/Sapphire's
    -- font sits lower in its line, so it's raised to the same row there
    local textY = tlY + 21
    local okV, v = pcall(S.version)
    if okV and (v == "ruby" or v == "sapphire") then textY = textY - 5 end
    FrlgFont.draw(text, tlX + 86 - w, textY, tOpts)
    love.graphics.setColor(1, 1, 1, 1)
  end

  -- ------- low HP warning

  B.LOW_HP = {
    { id = "normal", label = "NORMAL" },
    { id = "reduced", label = "REDUCED" },
    { id = "off", label = "OFF" },
  }

  local function lowHpIndex()
    local v = S.get("low_hp_warning")
    for i, it in ipairs(B.LOW_HP) do if it.id == v then return i end end
    return 1
  end

  function B.lowHpLabel() return B.LOW_HP[lowHpIndex()].label end

  function B.stepLowHp(dir)
    local i = (lowHpIndex() - 1 + (dir or 1)) % #B.LOW_HP + 1
    S.set("low_hp_warning", B.LOW_HP[i].id)
  end

  -- REDUCED: how long the beep may run once the bar turns red (about 3 beeps)
  local REDUCED_SECONDS = 1.6
  local chirp = setmetatable({}, { __mode = "k" }) -- battle -> { mon, startedAt }

  local function lowHpAlarm(nextFn, c)
    local mode = B.LOW_HP[lowHpIndex()].id
    if type(c) == "table" then
      if mode == "off" then
        c.on = false
      elseif mode == "reduced" then
        local battle = c.battle
        local mon = battle and battle.player and battle.player.mon
        local t = (love.timer and love.timer.getTime()) or 0
        if not c.on then
          if battle then chirp[battle] = nil end
        elseif battle then
          local rec = chirp[battle]
          if not rec or rec.mon ~= mon then
            chirp[battle] = { mon = mon, at = t }
          elseif t - rec.at > REDUCED_SECONDS then
            c.on = false
          end
        end
      end
    end
    return nextFn(c)
  end

  function B.install()
    if B.installed then return end
    Ui = require("src.core.game3.battle.ui")
    Moves = require("src.core.game3.battle.moves")
    Types = require("src.core.game3.battle.types")
    FrlgFont = require("src.ui.game3.frlg_font")
    Healthbox = require("src.core.game3.battle.healthbox")
    B.installed = true

    local mod = ctx.mod
    if mod.hooks and mod.hooks.wrap then
      pcall(function() mod.hooks:wrap("battle.low_health_alarm", lowHpAlarm) end)
    end

    -- the move menu is drawn inside Ui.draw while choosing a move
    local origUiDraw = Ui.draw
    Ui.draw = function(...)
      inMoveDraw = S.flag("battle_move_colors") and (Ui._mode == "moves" or Ui._mode == "target")
      pendingMove = nil
      local ok, err = pcall(origUiDraw, ...)
      inMoveDraw, pendingMove = false, nil
      if not ok then error(err, 0) end
    end

    local origName = Moves.displayName
    Moves.displayName = function(mv, ...)
      local name = origName(mv, ...)
      if inMoveDraw and type(name) == "string" and name ~= "-------" then
        local okK, key = pcall(moveKey, mv, name)
        pendingMove = { text = name, key = okK and key or "NORMAL" }
      end
      return name
    end

    local origFontDraw = FrlgFont.draw
    FrlgFont.draw = function(text, x, y, opts, ...)
      if pendingMove ~= nil then
        local p = pendingMove
        pendingMove = nil
        if text == p.text then pcall(drawMoveBox, p.key, text, x, y, opts) end
      end
      return origFontDraw(text, x, y, opts, ...)
    end

    -- TM CASE / Summary / Move Relearner type badges (FireRed/LeafGreen's
    -- badge sheet): one colour per badge
    local okSC, SummaryChrome = pcall(require, "src.ui.game3.summary_chrome")
    if okSC and type(SummaryChrome) == "table" and type(SummaryChrome.drawTypeBadge) == "function" then
      local origBadge = SummaryChrome.drawTypeBadge
      SummaryChrome.drawTypeBadge = function(typeId, x, y, ...)
        local ok = pcall(TypeColors.drawBadge, typeId, x, y)
        if ok then return end
        return origBadge(typeId, x, y, ...)
      end
    end

    local Chrome = require("src.ui.game3.battle_chrome")
    local splitBox = false
    local origEnemyBox = Chrome.drawEnemyBox
    Chrome.drawEnemyBox = function(x, y, ...)
      local img = Chrome._enemyBox
      if splitBox and img then
        local okS = pcall(drawSplitEnemyBox, img, x, y)
        if okS then return end
      end
      return origEnemyBox(x, y, ...)
    end

    local origHb = Healthbox.draw
    Healthbox.draw = function(side, battler, opts, ...)
      local okP, shown = pcall(enemyPanelShown, battler, opts)
      splitBox = side == "enemy" and okP and shown or false
      local okH, result = pcall(origHb, side, battler, opts, ...)
      splitBox = false
      if not okH then error(result, 0) end
      if side == "enemy" then
        local ok, err = pcall(drawEnemyHp, battler, opts)
        if not ok and ctx.mod.log then ctx.mod.log:warn("enemy HP: %s", tostring(err)) end
      end
      return result
    end
  end

  return B
end
