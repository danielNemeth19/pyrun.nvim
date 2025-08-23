local M = {}
local config = require("pyrun.config").config
local default_opts = require("pyrun.config").opts
local runner = require("pyrun.runner")

---@param opts? pyrun.Opts
function M.setup(opts)
  ---@type pyrun.Opts
  local options = vim.tbl_deep_extend("force", {}, default_opts, opts or {})
  local r = runner:new(options, config)
  vim.keymap.set("n", r.opts.keymaps.run_all, function()
    r:run_all()
  end)
  vim.keymap.set("n", r.opts.keymaps.run_closest_class, function()
    r:run_closest_class()
  end)
  vim.keymap.set("n", r.opts.keymaps.run_closest_test, function()
    r:run_closest_test()
  end)
end

return M
