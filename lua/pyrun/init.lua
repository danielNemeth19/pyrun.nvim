local M = {}

local fn = vim.api.nvim_buf_get_name(0)
local cwd = vim.uv.cwd()
local is_django = vim.uv.fs_stat(cwd .. "/manage.py") ~= nil

M.run = function()
    local parts = vim.split(fn, cwd)
    print(parts[2])
    local module_path = ""
    for _, i in ipairs(vim.split(parts[2], "/")) do
        if module_path == "" then
            module_path = i
        else
            module_path = module_path .. "." .. i
        end
    end
    print(module_path)

end

return M
