---@class Runner
---@field opts pyrun.Opts
---@field config pyrun.Config
local Runner = {}
Runner.__index = Runner

---@param opts pyrun.Opts
---@param config pyrun.Config
---@return Runner
function Runner:new(opts, config)
    local instance = setmetatable({}, self)
    instance.opts = opts
    instance.config = config
    return instance
end

function Runner:print_conf()
  P(self)
end

return Runner
