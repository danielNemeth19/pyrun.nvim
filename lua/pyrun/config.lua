-- TODO: think about adding color keys (or maybe whole color config?)
-- TODO: validate config (ignore ns_id)
---@class pyrun.Colors
---@field success string
---@field failure string

---@class pyrun.Config
---@field color_names pyrun.Colors
---@field ns_id integer

---@class pyrun.keymaps
---@field run_all string
---@field close_float string

---@class pyrun.window_config
---@field relative string
---@field width integer
---@field height integer
---@field style string
---@field border string
---@field title string

---@class pyrun.Opts
---@field keymaps pyrun.keymaps
---@field window_config pyrun.window_config

---@class pyrun.Setup
---@field opts pyrun.Opts
---@field config pyrun.Config


---@type pyrun.Colors
local color_names = {
  success = "PyrunTestSuccess",
  failure = "PyrunTestFailure",
}

---@type pyrun.Config
local config = {
  color_names = color_names,
  ns_id = vim.api.nvim_create_namespace("pyrun_namespace"),
}

---@type pyrun.keymaps
local keymap_presets = {
  run_all = "<leader>t",
  close_float = "q"
}

---@type pyrun.window_config
local window_config = {
  relative = "win",
  width = 150,
  height = 40,
  style = "minimal",
  border = "single",
  title = "Running tests",
}

---@type pyrun.Opts
local opts = {
  window_config = window_config,
  keymaps = keymap_presets,
  mas = "asdad"
}

---@type pyrun.Setup
local setup_table = {
  opts = opts,
  config = config
}
return setup_table
