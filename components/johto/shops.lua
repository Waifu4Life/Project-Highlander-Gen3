-- JOHTO POKéMON HELPER, always on: the four trade-evolution items for sale
-- after the Champion. Lilycove Department Store 2F (the clerk who sells
-- Potions, Ruby/Sapphire/Emerald) and Celadon Department Store 4F (the clerk
-- who sells the evolution stones, FireRed/LeafGreen): METAL COAT, KING'S ROCK,
-- DRAGON SCALE and UP-GRADE at $20,000 each. Selling them gives the usual price.
return function(D)
  local SH = {}
  local req, warn, info = D.req, D.warn, D.info

  local EXTRA = { 199, 187, 201, 218 } -- Metal Coat, King's Rock, Dragon Scale, Up-Grade
  local PRICE = 20000
  local isExtra = {}
  for _, id in ipairs(EXTRA) do isExtra[id] = true end
  local POTION, FIRE_STONE = 13, 95

  local active = false

  local function has(items, id)
    for _, v in ipairs(items or {}) do if tonumber(v) == id then return true end end
    return false
  end

  local function wanted(items)
    if not D.champion() then return false end
    local map = D.mapId()
    if D.hoenn() then
      return map:find("LILYCOVE_CITY_DEPARTMENT_STORE_2F", 1, true) ~= nil and has(items, POTION)
    end
    if D.kanto() then
      return map:find("CELADON_CITY_DEPARTMENT_STORE", 1, true) ~= nil and has(items, FIRE_STONE)
    end
    return false
  end

  local function selling(menu)
    return type(menu) == "table" and (menu.mode == "sell" or menu.state == "sell")
  end

  local function installShop()
    local ShopMenu = require("src.ui.game3.shop_menu")
    local origShow = ShopMenu.show
    ShopMenu.show = function(opts, ...)
      local ok, changed = pcall(function()
        if type(opts) ~= "table" or type(opts.items) ~= "table" or not wanted(opts.items) then return nil end
        local Marts = req("src.core.game3.marts")
        local mart = opts.mart
        if not mart then
          for _, e in pairs(Marts and Marts._byKey or {}) do
            if e.items == opts.items then mart = e break end
          end
        end
        local items = {}
        for i, v in ipairs(opts.items) do items[i] = v end
        for _, id in ipairs(EXTRA) do if not has(items, id) then items[#items + 1] = id end end
        local copy = {}
        for k, v in pairs(opts) do copy[k] = v end
        copy.items, copy.mart = items, mart
        local onClose = opts.onClose
        copy.onClose = function(...)
          active = false
          if onClose then return onClose(...) end
        end
        return copy
      end)
      if ok and changed then
        active = true
        info("johto shop: trade-evolution items added")
        return origShow(changed, ...)
      end
      if not ok then warn("shop", changed) end
      active = false
      return origShow(opts, ...)
    end
    local origClose = ShopMenu.close
    if origClose then
      ShopMenu.close = function(...)
        local r = { origClose(...) }
        active = false
        return (table.unpack or unpack)(r)
      end
    end

    local ItemsData = require("src.core.game3.items_data")
    local origInfo = ItemsData.info
    local priced = setmetatable({}, { __mode = "k" })
    ItemsData.info = function(id, ...)
      local r = origInfo(id, ...)
      if active and type(r) == "table" and isExtra[tonumber(id) or -1] and not selling(ShopMenu) then
        local c = priced[r]
        if not c then
          c = {}
          for k, v in pairs(r) do c[k] = v end
          c.price = PRICE
          priced[r] = c
        end
        return c
      end
      return r
    end
  end

  SH.installers = { { "johto shops", installShop } }
  return SH
end
