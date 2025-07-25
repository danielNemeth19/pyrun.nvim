local M = {}

function M.run()
  local fp = vim.api.nvim_buf_get_name(0)
  local manage_fp = M.find_manage_file(fp)
  if manage_fp ~= nil then
    vim.notify(manage_fp, vim.log.levels.DEBUG)
    local module_path = M.set_module_path(fp, manage_fp)
    local command = "!python " .. manage_fp .. " test " .. module_path
    vim.notify(command, vim.log.levels.DEBUG)
    vim.cmd(command)
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
  local m = string.sub(module_path, string.len(project_root)+1, string.len(module_path))
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

return M
