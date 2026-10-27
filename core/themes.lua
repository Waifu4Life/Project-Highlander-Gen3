-- Theme palettes. main = bars/highlight, light = selection border, dark = backdrop.
local Themes = {}

Themes.ORDER = { "auto", "firered", "leafgreen", "ruby", "sapphire", "emerald" }

Themes.LABELS = {
  auto = "AUTO", firered = "FIRERED", leafgreen = "LEAFGREEN",
  ruby = "RUBY", sapphire = "SAPPHIRE", emerald = "EMERALD",
}

Themes.PALETTES = {
  firered = { -- red-orange
    main = { 0.91, 0.33, 0.12, 1 }, light = { 1.00, 0.64, 0.40, 1 }, dark = { 0.20, 0.06, 0.03, 1 },
  },
  leafgreen = { -- bright green
    main = { 0.34, 0.78, 0.18, 1 }, light = { 0.70, 0.97, 0.50, 1 }, dark = { 0.05, 0.17, 0.04, 1 },
  },
  ruby = { -- dark red
    main = { 0.62, 0.07, 0.13, 1 }, light = { 0.93, 0.40, 0.44, 1 }, dark = { 0.15, 0.02, 0.04, 1 },
  },
  sapphire = { -- blue (brighter: the only blue game)
    main = { 0.18, 0.42, 0.92, 1 }, light = { 0.62, 0.78, 1.00, 1 }, dark = { 0.08, 0.20, 0.50, 1 },
  },
  emerald = { -- darker green
    main = { 0.04, 0.48, 0.27, 1 }, light = { 0.36, 0.82, 0.56, 1 }, dark = { 0.01, 0.12, 0.07, 1 },
  },
}

function Themes.resolve(choice, version)
  if choice == nil or choice == "auto" or not Themes.PALETTES[choice] then
    choice = Themes.PALETTES[version or ""] and version or "firered"
  end
  return Themes.PALETTES[choice], choice
end

function Themes.step(choice, dir)
  local index = 1
  for i, id in ipairs(Themes.ORDER) do
    if id == choice then index = i break end
  end
  local n = #Themes.ORDER
  index = ((index - 1 + (dir or 1)) % n + n) % n + 1
  return Themes.ORDER[index]
end

return Themes
