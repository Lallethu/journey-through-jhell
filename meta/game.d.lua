---@meta game

---Metafile documenting types and APIs

---@alias Binding
---| "move_left"
---| "move_right"
---| "move_up"
---| "move_down"
---| "interact"
---| "attack"
---| "heal"
---| "place_wall"
---| "end_day"
---| "debug_switch_state"
---| "debug_profiler"
---| "debug_reset_profiler"

---@alias GameEvent
---| "jelly_died"
---| "jelly_hit"
---| "jelly_hit_sixseven"
---| "player_attacked"
---| "player_healed"
---| "token_gained"
---| "player_hurt"
---| "jelly_spawned"
---| "sugar_changed"
---| "task_done"
---| "task_started"
---| "task_cancelled"
---| "task_failed"
---| "task_refused"
---| "task_target_hit"
---| "phase_changed"
---| "wave_cleared"
---| "restart_requested"
---| "structure_built"
---| "entity_hurt"
---| "structure_destroyed"

---@alias TaskId
---| "gatherer"
---| "wall"
---| "healer"

---@alias StructureId
---| "wall"

---@alias EntityKind
---| "player"
---| "jelly"
---| "wall"
---| "interactable"
---| "structure"

---@alias Bindings table<Binding, love.Scancode[]>
---@alias TasksList table<TaskId, table>

---@alias EventHandler fun(...: any)

---@class Listener
---@field fn EventHandler
---@field owner table?
local listeners = {}

---@class State
---@field machine StateMachine? reference to the statemachine
---@field world World? reference to the world
---@field activeTask Task?
---@field t number? Time variable to use as hearth content
---@field leaving number? Use case in TitleScreenState (timer)
---@field timeLeft number? Time between transitions
---@field age number? Time the state has been alive for
---@field won boolean? Flag for win/lose
---@field enter fun(self: State, ...: any)? Trigger when StateMachine:switch is called
---@field exit fun(self: State)? Trigger when StateMachine:switch is called
---@field update fun(self: State, dt: number)?
---@field closeTask fun(self: State)?
---@field draw fun(self: State)?
---@field startTask fun(self: State, target: Interactable)?
---@field onAction fun(self: State, action: Binding)?
---@field start fun(self: State)?
---@field keypressed fun(self: State, k: love.KeyConstant, sc: love.Scancode)?
---@field mousepressed fun(self: State, x: number, y: number, button: integer?)?
---@field mousereleased fun(self: State, x: number, y: number, button: integer?)?
---@field wheelmoved fun(self: State, dx: integer, dy: integer)?
---@field focus fun(self: State, focused: boolean)?

---@alias StateList table<string, State>

---@class StateContext
---@field states StateList
---@field world World

---@class Entity
---@field id integer
---@field x number Centre of the entity
---@field y number Centre of the entity
---@field kind EntityKind
---@field dead boolean
---@field update fun(self: Entity, dt: number)
---@field draw fun(self: Entity)

---@class Task
---@field panel boolean Either there is a panel UI element showing or not
---@field update fun(self: Task, dt: number)
---@field draw fun(self: Task)
---@field mousepressed fun(self: Task, x: number, y: number, button: integer?)
---@field brush fun(self: Task)?
---@field saw fun(self: Task)?
---@field refreshLabels fun(self: Task)?
---@field slotAt fun(self: Task)?
---@field cycleSize fun(self: Task)?
---@field complete fun(self: Task)?
---@field mousepressed fun(self: Task, x: number, y: number, button: integer)?
---@field mousereleased fun(self: Task, x: number, y: number, button: integer)?
---@field wheelmoved fun(self: Task, dx: integer, dy, integer)?
---@field blur fun(self: Task)?
---@field close fun(self: Task)?

---@class TaskResult
---@field success boolean
---@field quality number 0..1, 1 = perfect

---@class Swing
---@field t number
---@field fx number
---@field fy number
---@field hit table<Entity, boolean>
---@field impact boolean
