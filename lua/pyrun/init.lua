local M = {}

function M.run()
  local fp = vim.api.nvim_buf_get_name(0)
  local manage_fp = M.find_manage_file(fp)
  if manage_fp ~= nil then
    vim.notify(manage_fp, vim.log.levels.DEBUG)
    local module_path = M.set_module_path(fp, manage_fp)
    local command = { "python", manage_fp, "test", module_path }
    M.open_window(command)
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
  local module_path = string.gsub(fp, ".py", "")
  vim.notify("module_path is" .. module_path, vim.log.levels.DEBUG)
  local project_root = vim.fs.dirname(manage_fp)
  local m = string.sub(module_path, string.len(project_root) + 1, string.len(module_path))
  local module = ""
  for _, i in ipairs(vim.split(m, "/")) do
    if module == "" then
      module = i
    else
      module = module .. "." .. i
    end
  end
  return module
end

---@param width integer
---@param height integer
---@return integer x_col
---@return integer y_row
function M.get_coordinates(width, height)
  local center_r = vim.o.lines / 2
  local center_c = vim.o.columns / 2
  local x_col = center_c - (width / 2)
  local y_row = center_r - (height / 2)
  return x_col, y_row
end

function M.open_window(command)
  local width = 150
  local height = 40
  local col, row = M.get_coordinates(width, height)
  local buff_n = vim.api.nvim_create_buf(true, true)
  local win_id = vim.api.nvim_open_win(buff_n, false, {
    relative = "win",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "single",
    title = "My window"
  })
  local _ = vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      vim.api.nvim_buf_set_lines(buff_n, -1, -1, false, data)
    end,
    on_stderr = function(_, data)
      vim.api.nvim_buf_set_lines(buff_n, -1, -1, false, data)
    end,
    stderr_buffered = true,
    on_exit = function()
      os.execute("sleep 2")
      vim.api.nvim_win_close(win_id, false)
    end
  })
end

return M
