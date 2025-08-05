-- TODO: think about adding color keys (or maybe whole color config?)
-- TODO: validate config (ignore ns_id)
local config = {}

local ns_id = vim.api.nvim_create_namespace("pyrun_namespace")

local keymap_presets = {
  run_all = "<leader>t",
  close_float = "q"
}

local window_config = {
  relative = "win",
  width = 150,
  height = 40,
  style = "minimal",
  border = "single",
  title = "Running tests"
}

local default_opts = {
  keymaps = keymap_presets,
  window_config = window_config,
  ns_id = ns_id
}

config.default_opts = default_opts
return config
