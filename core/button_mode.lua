-- Always on (all five Gen 3 games): the game's own OPTION > BUTTON MODE is
-- kept on LR (FireRed/LeafGreen: HELP / LR / L=A; Ruby/Sapphire/Emerald:
-- NORMAL / LR / L=A), so L and R always work as L and R. Several mods need
-- the shoulder buttons, and L=A would turn L into a second A button.
return function(mod)
  local M = {}
  local LR = 1

  local function force(o)
    if type(o) ~= "table" then return o end
    o.buttonMode = LR
    o.l_equals_a = false
    if o.optionsButtonMode ~= nil then o.optionsButtonMode = LR end
    return o
  end

  function M.install()
    if M.installed then return end
    local Options = require("src.core.game3.options")
    M.installed = true
    for _, name in ipairs({ "ensure", "bind", "block" }) do
      local orig = Options[name]
      if type(orig) == "function" then
        Options[name] = function(a, ...)
          local o = orig(a, ...)
          force(o)
          if name ~= "block" and type(a) == "table" and a.optionsButtonMode ~= nil then a.optionsButtonMode = LR end
          return o
        end
      end
    end
    local origSet = Options.set
    Options.set = function(session, key, value, ...)
      if key == "buttonMode" then value = LR
      elseif key == "l_equals_a" then value = false end
      local o = origSet(session, key, value, ...)
      return force(o)
    end
    Options.lEqualsA = function() return false end
    Options.lrMode = function() return true end
    if mod.log then pcall(mod.log.info, mod.log, "button mode: locked on LR") end
  end

  return M
end
