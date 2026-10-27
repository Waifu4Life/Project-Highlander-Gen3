-- QOL > DECAPITALIZE WORDS (same idea as Project Highlander Gen 1/2)
--   Words the games always write in capitals (POKéMON, POTION, BROCK, ROUTE,
--   your name...) are written normally: Pokémon, Potion, Brock, Route.
--   Short terms stay in capitals: HP, PP, PC, TM, HM, ID, OT, PKMN, VS, FR, LG, XP, LR...
--   Single letters (A, B, L, R) never change.
--
-- Done in the game's font (draw, measure, wrap), so centred and right-aligned
-- text uses the new widths. Text codes ({COLOR ...}, {PLAYER}, the 0xFC
-- control bytes) pass through untouched, Braille is skipped, and no word
-- changes length, so typed-out messages stay in step.
--
-- Installed from main.lua before every other Project Highlander font hook,
-- so those hooks still see the game's original text.
return function(ctx)
  local D = { installed = false }
  local S = ctx.settings

  local KEEP_CAPS = {
    HP = true, PP = true, PC = true, TM = true, HM = true, OK = true, TV = true,
    ID = true, KO = true, SS = true, FR = true, LG = true, PK = true, MN = true, PKMN = true,
    VS = true, OT = true, LV = true, IV = true, EV = true, BP = true, GBA = true,
    XP = true, LR = true,
  }

  local function on() return S.get("decapitalize") == true end

  local function caseSegment(str)
    -- "é" is two bytes in UTF-8, so it can't sit inside a [...] set.
    str = str:gsub("POK\195\169MON", "Pok\195\169mon")
    str = str:gsub("POK\195\169DEX", "Pok\195\169dex")
    str = str:gsub("POK\195\169BLOCK", "Pok\195\169block")
    str = str:gsub("FIRERED", "FireRed"):gsub("LEAFGREEN", "LeafGreen")
    str = str:gsub("(%u[%u'%-]*%u)", function(word)
      if KEEP_CAPS[word] then return word end
      if word == "TMS" or word == "HMS" then return word:sub(1, 2) .. "s" end
      return word:sub(1, 1) .. word:sub(2):lower()
    end)
    return str
  end

  -- Lengths of the 0xFC control sequences (frlg_font scanTokens).
  local function ctrlLength(s, i)
    local cmd = s:byte(i + 1)
    if not cmd then return 1 end
    if cmd == 0x01 or cmd == 0x02 or cmd == 0x03 or cmd == 0x06 then return 3 end
    if cmd == 0x04 then return 5 end
    if cmd == 0x0D or cmd == 0x0E or cmd == 0x11 or cmd == 0x12 or cmd == 0x13 or cmd == 0x14 then return 3 end
    if cmd == 0x05 or cmd == 0x08 or cmd == 0x0C then return 3 end
    if cmd == 0x0B or cmd == 0x10 then return 4 end
    return 2
  end

  local function recase(str)
    if not str:find("%u%u") then return str end
    if str:find("BRAILLE", 1, true) then return str end
    local out, pos, n = {}, 1, #str
    local segStart = 1
    while pos <= n do
      local b = str:byte(pos)
      if b == 0x7B then -- '{'
        local close = str:find("}", pos + 1, true)
        if close then
          out[#out + 1] = caseSegment(str:sub(segStart, pos - 1))
          out[#out + 1] = str:sub(pos, close)
          pos = close + 1
          segStart = pos
        else
          pos = pos + 1
        end
      elseif b == 0xFC then
        local len = ctrlLength(str, pos)
        out[#out + 1] = caseSegment(str:sub(segStart, pos - 1))
        out[#out + 1] = str:sub(pos, pos + len - 1)
        pos = pos + len
        segStart = pos
      elseif b == 0x5C then -- '\' escapes like \n \p \l
        out[#out + 1] = caseSegment(str:sub(segStart, pos - 1))
        out[#out + 1] = str:sub(pos, pos + 1)
        pos = pos + 2
        segStart = pos
      else
        pos = pos + 1
      end
    end
    out[#out + 1] = caseSegment(str:sub(segStart))
    return table.concat(out)
  end

  local cache, cacheSize = {}, 0
  function D.apply(text)
    if type(text) ~= "string" or text == "" or not on() then return text end
    local hit = cache[text]
    if hit == nil then
      local ok, r = pcall(recase, text)
      hit = ok and r or text
      if cacheSize >= 4096 then cache, cacheSize = {}, 0 end
      cache[text] = hit
      cacheSize = cacheSize + 1
    end
    return hit
  end

  local function skip(opts)
    return type(opts) == "table" and opts.font == "braille"
  end

  function D.install()
    if D.installed then return end
    local FrlgFont = require("src.ui.game3.frlg_font")
    D.installed = true
    local origDraw, origMeasure, origWrap = FrlgFont.draw, FrlgFont.measure, FrlgFont.wrap
    FrlgFont.draw = function(text, x, y, opts, ...)
      if not skip(opts) then text = D.apply(text) end
      return origDraw(text, x, y, opts, ...)
    end
    FrlgFont.measure = function(text, opts, ...)
      if not skip(opts) then text = D.apply(text) end
      return origMeasure(text, opts, ...)
    end
    if type(origWrap) == "function" then
      FrlgFont.wrap = function(text, maxWidth, opts, ...)
        if not skip(opts) then text = D.apply(text) end
        return origWrap(text, maxWidth, opts, ...)
      end
    end
  end

  return D
end
