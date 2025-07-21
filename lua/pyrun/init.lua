local M = {}

M.run = function()
    local ft = vim.bo.filetype
    if ft == "python" then
        local fn = vim.api.nvim_buf_get_name(0)
        print("filename: " .. fn)
    end
end

return M
