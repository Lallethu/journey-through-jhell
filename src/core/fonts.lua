---@class Fonts
local Fonts = {}

local cache = {}

---Rerturn the cached font at the requested size or create and cache it
---@param size integer
function Fonts.get(size)
  local f = cache[size]
  if not f then
    f = love.graphics.newFont("assets/fonts/cute-dino.ttf", size, "mono")
    cache[size] = f
  end
  return f
end

return Fonts
