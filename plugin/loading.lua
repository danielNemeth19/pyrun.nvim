vim.api.nvim_create_autocmd({ 'BufReadPost' }, {
    pattern = { "*.py" },
    callback = function()
        local pr = require("pyrun")
        vim.keymap.set("n", "<leader>t", pr.run)
    end
})
