local M = {}
local config = require("pyrun.config").config
local default_opts = require("pyrun.config").opts
local runner = require("pyrun.runner")

---@param opts? pyrun.Opts
function M.setup(opts)
  ---@type pyrun.Opts
  local options = vim.tbl_deep_extend("force", {}, default_opts, opts or {})
  local r = runner:new(options, config)
  vim.api.nvim_create_autocmd("FileType", {
    pattern  = "python",
    callback = function(args)
      for func_name, key in pairs(r.opts.keymaps) do
        vim.keymap("n", key, function ()
          r[func_name]()
        end, {buffer = args.buf})
      end
    end
  })
end
return M
