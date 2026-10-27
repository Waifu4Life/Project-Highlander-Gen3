-- QoL features (OPTIONS > PROJECT HIGHLANDER > QOL). All five Gen 3 games.
--   Skip Recaps in FR & LG                          (this file)
--   Always Boosted EXP, Modern EXP Sharing          -> exp.lua
--   Unlimited PP                                    -> unlimited_pp.lua
--   Infinite Safari, Run Everywhere,
--   Sparkling Hidden Items, Use Repel Again?        -> field.lua
--   Rematch Anyone, Anytime                         -> rematch.lua
--   Decapitalize Words                              -> decap.lua (installed first, from main.lua)
--
-- Every patch is installed on its own: if a game module is not loaded yet (or
-- is missing in some version), only that patch waits for the next install
-- pass (game.ready); the others still go in.
return function(ctx)
  local Q = { installed = false }
  local S = ctx.settings
  local mod = ctx.mod

  local function loadLocal(relative)
    local source, readErr = mod:read(relative)
    assert(source, tostring(readErr or (relative .. " is missing")))
    local chunk, compileErr = load(source, "@" .. tostring(mod.path) .. "/" .. relative)
    assert(chunk, compileErr)
    return chunk()
  end

  -- patch(id, fn): runs fn once; a failure leaves it pending for the next pass.
  local done = {}
  local function patch(id, fn)
    if done[id] then return true end
    local ok, err = pcall(fn)
    if ok then
      done[id] = true
      return true
    end
    if mod.log then pcall(mod.log.warn, mod.log, "qol patch %s waiting: %s", id, tostring(err)) end
    return false
  end
  ctx.qolPatch = patch

  local parts = {}
  for _, name in ipairs({ "exp", "unlimited_pp", "field", "rematch" }) do
    local ok, part = pcall(function() return loadLocal("components/qol/" .. name .. ".lua")(ctx, patch) end)
    if ok and type(part) == "table" then
      parts[#parts + 1] = part
    elseif mod.log then
      pcall(mod.log.error, mod.log, "qol %s failed to load: %s", name, tostring(part))
    end
  end

  function Q.install()
    patch("skip_recaps", function()
      local QuestLog = require("src.ui.game3.quest_log")
      local origBegin = QuestLog.begin
      QuestLog.begin = function(session, ...)
        local v = S.version(session)
        if (v == "firered" or v == "leafgreen") and S.flag("skip_recaps") then
          return nil -- Game3 then enters the field directly ("continue")
        end
        return origBegin(session, ...)
      end
    end)
    for _, part in ipairs(parts) do
      pcall(part.install)
    end
    Q.installed = true
  end

  return Q
end
