-- OTHER SYSTEM SETTINGS > LEARN TMS FASTER / FAST PKMN CENTER (all five games)
--
-- Learn TMs Faster: teaching a TM/HM to a Pokémon that already knows four
-- moves goes straight to the "which move?" screen. No "is trying to learn /
-- delete a move?" questions, no "1, 2 and... Poof!" lines; only the
-- "<MON> learned <MOVE>!" line (and the HM-can't-be-forgotten line) remain.
-- Backing out of the move screen quietly cancels.
--
-- Fast PKMN Center: the nurse says one welcome line with the YES/NO.
--   NO  -> "Thank you, come again!"
--   YES -> the healing machine runs at once (no "I'll take your Pokémon" or
--          "Thank you for waiting" lines), then "All done! Thank you, come again!"
-- The Pokérus line and Emerald's gold-card greeting are left alone.
return function(ctx, patch)
  local P = {}
  local S = ctx.settings

  local function on(key) return S.flag(key) and true or false end

  ---------------------------------------------------------------------------
  -- Learn TMs Faster
  ---------------------------------------------------------------------------
  local function tmFromPartyMenu()
    local ok, yes = pcall(function()
      local PartyMenu = package.loaded["src.ui.game3.party_menu"]
      if not (PartyMenu and PartyMenu._item ~= nil) then return false end
      local ItemsData = require("src.core.game3.items_data")
      return ItemsData.isTm(PartyMenu._item) and true or false
    end)
    return ok and yes
  end

  local function installTms()
    local LearnMove = require("src.core.game3.battle.learn_move")
    local Pokemon = require("src.core.game3.pokemon")
    local RomText = require("src.core.game3.rom_text")
    local orig = LearnMove.begin
    assert(type(orig) == "function", "LearnMove.begin missing")

    LearnMove.begin = function(opts, ...)
      if type(opts) ~= "table" or not on("learn_tms_faster") or opts.battleText or opts.relearner
        or opts.headless or type(opts.pushMsg) ~= "function" or type(opts.askYesNo) ~= "function"
        or type(opts.askForget) ~= "function" or not opts.mon or not tonumber(opts.moveId)
        or not tmFromPartyMenu() then
        return orig(opts, ...)
      end
      local okCount, count = pcall(Pokemon.moveSlotCount, opts.mon)
      if not okCount or (tonumber(count) or 0) < 4 then return orig(opts, ...) end

      -- The only lines that stay: the HM refusal and "<MON> learned <MOVE>!".
      local keep = {}
      pcall(function()
        local name = opts.displayName or Pokemon.displayMonName(opts.mon)
        local moveName = Pokemon.moveName(tonumber(opts.moveId))
        keep[RomText.ascii("gText_PkmnLearnedMove3", { stringVars = { name, moveName } })] = true
        local key = require("src.core.game3.battle.profile").get(nil).strings.hmCantForget
        keep[RomText.ascii(key)] = true
      end)

      local fast = {}
      for k, v in pairs(opts) do fast[k] = v end
      local pushMsg = opts.pushMsg
      fast.pushMsg = function(text, cb)
        if keep[text] then return pushMsg(text, cb) end
        if cb then cb() end
      end
      -- "Delete a move?" -> YES (opens the move screen);
      -- "Stop learning?" (after backing out) -> YES (cancel).
      fast.askYesNo = function(a, b)
        local cb = (type(a) == "function") and a or b
        if cb then cb(true) end
      end
      return orig(fast, ...)
    end
  end

  ---------------------------------------------------------------------------
  -- Fast PKMN Center
  ---------------------------------------------------------------------------
  local WELCOME = "Welcome to the POKéMON CENTER!\nMay I heal your POKéMON?"
  local NO_TEXT = "Thank you,\ncome again!"
  local DONE_TEXT = "All done! Thank you,\ncome again!"

  local function norm(text)
    if type(text) ~= "string" then return "" end
    local s = text:lower():gsub("{[^}]*}", ""):gsub("[^a-z0-9]", "")
    return (s:gsub("pok[a-z]?mon", "pkmn"))
  end

  local function kind(text)
    local n = norm(text)
    if n == "" then return nil end
    if n:find("welcome", 1, true) and (n:find("healyourpkmn", 1, true) or n:find("restyourpkmn", 1, true)) then
      return "welcome"
    end
    if n:find("illtakeyourpkmn", 1, true) then return "take" end
    if n:find("thankyouforwaiting", 1, true) and n:find("restored", 1, true) then return "restored" end
    if n == "wehopetoseeyouagain" then return "bye" end
    return nil
  end

  local visit = nil -- { healed = bool } while a fast nurse talk is going on

  local function closeBox()
    local Message = package.loaded["src.ui.game3.message"]
    if Message and Message.isOpen and Message.isOpen() then
      Message._done = nil
      Message.close()
    end
  end

  local function installCenter()
    local Hud = require("src.ui.game3.hud")
    local orig = Hud.openMessageStay
    assert(type(orig) == "function", "Hud.openMessageStay missing")
    Hud.openMessageStay = function(game, text, opts, ...)
      if not on("fast_pkmn_center") or type(text) ~= "string" then
        return orig(game, text, opts, ...)
      end
      local k = kind(text)
      if k == "welcome" then
        visit = { healed = false }
        return orig(game, WELCOME, opts, ...)
      elseif visit and k == "take" then
        visit.healed = true
        closeBox() -- the machine runs with no box up
        return
      elseif visit and k == "restored" then
        closeBox()
        return
      elseif visit and k == "bye" then
        local healed = visit.healed
        visit = nil
        return orig(game, healed and DONE_TEXT or NO_TEXT, opts, ...)
      end
      return orig(game, text, opts, ...)
    end
  end

  P._kind = kind -- for tests

  function P.install()
    patch("fast_tms", installTms)
    patch("fast_center", installCenter)
  end

  return P
end
