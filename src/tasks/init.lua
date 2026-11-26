---@class Tasks
local Tasks = {}

local kinds = {
  click_targets = require("src.tasks.click_targets"),
  candy_cane = require("src.tasks.candy_cane"),
}

---@param config table a `minigame` entry from data/tasks.lua
---@param onFinish fun(result: TaskResult)
---@return table task
function Tasks.create(config, onFinish)
  local kind = kinds[config.kind]
  assert(kind, "unknown task kind: " .. tostring(config.kind))
  return kind.new(config, onFinish)
end

return Tasks
