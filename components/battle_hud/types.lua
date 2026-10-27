-- Type colours for COLORED MOVE NAMES (same reference palette as the Gen 1/2
-- Battle HUD). FAIRY is ready for when the Fairy type is switched on.
local T = {}

T.COLORS = {
  NORMAL = { 144, 152, 162 }, FIGHTING = { 206, 63, 107 }, FLYING = { 143, 168, 222 },
  POISON = { 171, 106, 200 }, GROUND = { 217, 119, 70 }, ROCK = { 201, 182, 139 },
  BUG = { 144, 192, 44 }, GHOST = { 82, 105, 173 }, STEEL = { 91, 142, 161 },
  MYSTERY = { 104, 160, 144 }, -- the Gen 3 "???" type
  FIRE = { 254, 156, 85 }, WATER = { 77, 144, 214 }, GRASS = { 101, 188, 94 },
  ELECTRIC = { 244, 210, 59 }, PSYCHIC = { 249, 113, 119 }, ICE = { 115, 206, 191 },
  DRAGON = { 9, 109, 195 }, DARK = { 91, 82, 101 },
  FAIRY = { 238, 140, 206 }, -- nice pink
}

-- Gen 3 moves that became Fairy-type (Gen VI). Used when the Fairy type is on.
T.FAIRY_MOVES = { ["CHARM"] = true, ["MOONLIGHT"] = true, ["SWEET KISS"] = true }

-- type id (or name) -> colour key
function T.key(typeId, Types)
  if type(typeId) == "string" then
    local up = typeId:upper()
    if T.COLORS[up] then return up end
  end
  local id = tonumber(typeId)
  if id and Types and type(Types.ID) == "table" then
    for name, value in pairs(Types.ID) do
      if value == id then return T.COLORS[name] and name or "NORMAL" end
    end
  end
  return "NORMAL"
end

-- Swap point for the Fairy type: given the Gen 3 colour key and the move's
-- display name, return the key to draw with.
function T.resolve(key, moveName, fairyOn)
  if fairyOn and moveName and T.FAIRY_MOVES[tostring(moveName):upper()] then return "FAIRY" end
  return key
end

function T.rgb(key)
  local c = T.COLORS[key] or T.COLORS.NORMAL
  return c[1] / 255, c[2] / 255, c[3] / 255
end

-- ------- one-colour type badge (32x12), same look as the Pokédex 2nd screen.
-- The FireRed/LeafGreen badge sheet as loaded in G1R paints some badges in
-- two types' colours (FLYING, POISON...), so the mod draws its own.

T.BY_ID = { [0] = "NORMAL", "FIGHTING", "FLYING", "POISON", "GROUND", "ROCK", "BUG", "GHOST",
  "STEEL", "MYSTERY", "FIRE", "WATER", "GRASS", "ELECTRIC", "PSYCHIC", "ICE", "DRAGON", "DARK" }
T.SHORT = { FIGHTING = "FIGHT", ELECTRIC = "ELECTR", PSYCHIC = "PSYCHC", MYSTERY = "???" }

function T.badgeKey(t)
  if type(t) == "string" then
    local up = t:upper()
    if T.COLORS[up] then return up end
  end
  return T.BY_ID[tonumber(t) or 0] or "NORMAL"
end

function T.drawBadge(t, x, y)
  local FrlgFont = require("src.ui.game3.frlg_font")
  local key = T.badgeKey(t)
  local r, g, b = T.rgb(key)
  love.graphics.push("all")
  love.graphics.setColor(r * 0.55, g * 0.55, b * 0.55, 1)
  love.graphics.rectangle("fill", x, y, 32, 12, 3, 3)
  love.graphics.setColor(r, g, b, 1)
  love.graphics.rectangle("fill", x + 1, y + 1, 30, 10, 2, 2)
  love.graphics.setColor(math.min(1, r + 0.18), math.min(1, g + 0.18), math.min(1, b + 0.18), 1)
  love.graphics.rectangle("fill", x + 2, y + 1, 28, 1)
  local label = T.SHORT[key] or key
  local o = { small = true, maxWidth = 32,
    colors = { fg = { 1, 1, 1, 1 }, shadow = { r * 0.4, g * 0.4, b * 0.4, 1 }, bg = FrlgFont.STDPAL[0] } }
  local okW, w = pcall(FrlgFont.measure, label, o)
  w = (okW and tonumber(w)) or #label * 5
  FrlgFont.draw(label, x + math.floor((32 - w) / 2), y - 2, o)
  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
end

return T
