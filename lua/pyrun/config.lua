local config = {}

local ns_id = vim.api.nvim_create_namespace("pyrun_namespace")
local default_width = 150
local default_height = 40
local window_config = {
  relative = "win",
  width = default_width,
  height = default_height,
  style = "minimal",
  border = "single",
  title = "Running tests"
}

local default_opts = {
  window_config = window_config,
  ns_id = ns_id
}

config.default_opts = default_opts
return config
