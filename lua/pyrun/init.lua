local M = {}

-- local is_django = vim.uv.fs_stat(cwd .. "/manage.py") ~= nil

function M.run()
  local fp = vim.api.nvim_buf_get_name(0)
  local manage_fp = M.find_manage_file(fp)
  if manage_fp ~= nil then
    -- vim.notify(manage_fp, vim.log.levels.INFO)
    local module_path = M.set_module_path(fp, manage_fp)
    vim.notify("python manage.py " .. module_path, vim.log.levels.INFO)
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
  -- vim.notify("manage_fp is " .. manage_file, vim.log.levels.INFO)
  return manage_file
end

---@return string module_path
---@param fp string
---@param manage_fp string
function M.set_module_path(fp, manage_fp)
  local module_path = string.gsub(fp, ".py", "")
  -- vim.notify("module_path is" .. module_path, vim.log.levels.INFO)
  local project_root = vim.fs.dirname(manage_fp)
  local parts = vim.split(module_path, project_root)
  local module = ""
  for _, i in ipairs(vim.split(parts[2], "/")) do
    if module == "" then
      module = i
    else
      module = module .. "." .. i
    end
  end
  return module
end

return M
