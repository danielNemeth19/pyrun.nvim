print("LOADING")
vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter'}, {
    pattern = { "*.*" },
    callback = function()
        vim.notify("autocommand is running")
        -- local pr = require("pyrun")
        -- print(pr.run())
    end
})
print("LOADED")
