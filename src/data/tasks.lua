---@type TasksList
local tasksdata = {
  gatherer = { name = "Pep Hermint, the sugar daddy", color = { 0.95, 0.8, 0.9, 1 }, earns = 20, minigame = { kind = "click_targets", count = 5, need = 4, lifetime = 1.6, interval = 0.55, radius = 11 } },
  wall     = { name = "Wallther, the ginger bread wall baker", color = { 0.6, 0.8, 1.0, 1 }, cost = 15, gives = "wall", minigame = { kind = "candy_cane", structure = "wall", title = "Wallther, the Ginger Bread baker" }, },
  healer   = { name = "Hill Mi, the candheal man", color = { 0.6, 1.0, 0.7, 1 }, cost = 10, gives = "heal", minigame = { kind = "click_targets", count = 3, need = 3, lifetime = 1.4, interval = 0.70, radius = 7 } },
}

return tasksdata
