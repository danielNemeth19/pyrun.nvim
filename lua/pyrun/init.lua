local M = {}
local config = require("pyrun.config").config
local default_opts = require("pyrun.config").opts
local runner = require("pyrun.runner")

---@param opts? pyrun.Opts
function M.setup(opts)
  ---@type pyrun.Opts
  M.options = vim.tbl_deep_extend("force", {}, default_opts, opts or {})
  vim.keymap.set("n", M.options.keymaps.run_all, M.run_all)
  vim.keymap.set("n", M.options.keymaps.run_closest_class, M.run_closest_class)
  ---@type pyrun.Config
  M.config = config

  local r = runner(opts, config)
  r:print_conf()
end

---@return string|nil manage_fp
---@return string|nil module_path
function M.ctx_setup()
  local fp = vim.api.nvim_buf_get_name(0)
  local manage_fp = M.find_manage_file(fp)
  if not manage_fp then
    vim.api.nvim_echo({{"Not a Django project"}}, true, {err = true})
    return
  end
  if manage_fp ~= nil then
    vim.notify(manage_fp, vim.log.levels.DEBUG)
    local module_path = M.set_module_path(fp, manage_fp)
    return manage_fp, module_path
  end
end

---@param root_node TSNode
---@param current_line integer
---@return string test_class
function M._get_closest_class(root_node, current_line)
  local classes = {}
  local query = vim.treesitter.query.parse("python", [[(class_definition name: (identifier) @type)]])
  for _, node in query:iter_captures(root_node, 0, 0, current_line) do
    local current_klass = vim.treesitter.get_node_text(node, 0)
    table.insert(classes, current_klass)
  end
  local test_class = classes[#classes]
  return test_class
end

function M.get_closest_class()
  local parser = vim.treesitter.get_parser(0, "python")
  if not parser then
    return
  end
  local tree = parser:parse()[1]
  local root = tree:root()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line, _ = pos[1], pos[2]
  local k = M._get_closest_class(root, line)
  return k
end

function M.run_closest_class()
  local manage_fp, module_path = M.ctx_setup()
  if not module_path then
    return
  end
  local class_to_run = M.get_closest_class()
  if not class_to_run then
    vim.api.nvim_echo({{"No test class above cursor"}}, true, {err = true})
    return
  end
  local class_path = module_path .. "." .. class_to_run
  local command = { "python", manage_fp, "test", class_path }
  local bufnr, win_id = M.create_window_and_buffer(M.options.window_config, class_to_run)
  M.run_command(bufnr, win_id, command)
end

function M.run_all()
  local manage_fp, module_path = M.ctx_setup()
  if not manage_fp or not module_path then
    return
  end
  local command = { "python", manage_fp, "test", module_path }
  local bufnr, win_id = M.create_window_and_buffer(M.options.window_config, module_path)
  M.run_command(bufnr, win_id, command)
end

---@param filepath string
---@return string|nil
function M.find_manage_file(filepath)
  local result = vim.fs.find("manage.py", {
    limit = 1,
    upward = true,
    type = "file",
    path = filepath
  })
  local manage_file = result[1]
  return manage_file
end

---@param fp string
---@param manage_fp string
---@return string module_path
function M.set_module_path(fp, manage_fp)
  local project_root = vim.fs.dirname(manage_fp)
  -- to get path of test file relative to project root, without leading "/"
  local relative_path = fp:sub(project_root:len() + 2, fp:len())
  local without_ext = vim.fn.fnamemodify(relative_path, ":r")
  local module_path = without_ext:gsub("/", ".")
  return module_path
end

---@param width integer
---@param height integer
---@return integer x_col
---@return integer y_row
function M.get_coordinates(width, height)
  local center_c = vim.o.columns / 2
  local center_r = vim.o.lines / 2
  local x_col = center_c - (width / 2)
  local y_row = center_r - (height / 2)
  return x_col, y_row
end

---@param opts pyrun.window_config
---@param title_suffix string
---@return integer
---@return integer
function M.create_window_and_buffer(opts, title_suffix)
  local col, row = M.get_coordinates(opts.width, opts.height)
  local bufnr = vim.api.nvim_create_buf(true, true)
  local title = opts.title_prefix .. title_suffix
  opts = vim.tbl_extend('force', opts, { col = col, row = row, title = title })
  opts.title_prefix = nil
  local win_id = vim.api.nvim_open_win(bufnr, true, opts)
  return bufnr, win_id
end

---@param bufnr integer
---@param win_id integer
---@param command table
function M.run_command(bufnr, win_id, command)
  vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
    end,
    on_stderr = function(_, data)
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, data)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)
      for line, row in ipairs(lines) do
        local first_char = string.sub(row, 1, 1)
        if first_char == "." then
          vim.hl.range(bufnr, M.config.ns_id, M.config.color_names.success, { line - 1, 0 }, { line - 1, -1 },
            { inclusive = true })
        end
      end
    end,
    stderr_buffered = true,
    on_exit = function()
      vim.keymap.set("n", M.options.keymaps.close_float, function()
        vim.api.nvim_win_close(win_id, false)
      end, { buffer = bufnr })
    end
  })
end

return M
