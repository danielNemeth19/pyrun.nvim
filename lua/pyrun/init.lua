local M = {}

M.run = function()
    local ft = vim.bo.filetype
    print("Filetype is " .. ft)
end

return M
