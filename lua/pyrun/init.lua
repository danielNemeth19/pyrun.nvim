local M = {}
local default_opts = require("pyrun.config").default_opts


---@param opts? table
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, default_opts, opts or {})
  vim.keymap.set("n", M.options.keymaps.run_all, M.run)
end

function M.run()
  local fp = vim.api.nvim_buf_get_name(0)
  local manage_fp = M.find_manage_file(fp)
  if manage_fp ~= nil then
    vim.notify(manage_fp, vim.log.levels.DEBUG)
    local module_path = M.set_module_path(fp, manage_fp)
    local command = { "python", manage_fp, "test", module_path }
    local bufnr, win_id = M.create_window_and_buffer(M.options.window_config)
    M.run_command(bufnr, win_id, command)
  end
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
  vim.notify("manage_fp is " .. manage_file, vim.log.levels.DEBUG)
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

---@param opts table
---@return integer
---@return integer
function M.create_window_and_buffer(opts)
  local col, row = M.get_coordinates(opts.width, opts.height)
  local bufnr = vim.api.nvim_create_buf(true, true)
  opts = vim.tbl_extend('force', opts, { col = col, row = row })
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
          vim.hl.range(bufnr, M.options.ns_id, M.colors.success.name, { line - 1, 0 }, { line - 1, -1 },
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
