local neotest = require("neotest")
neotest.setup({
    adapters = {
        require("neotest-python")({
            dap = { justMyCode = false },
            runner = "pytest",
        }),
        require("neotest-go"),
    },
})

-- <leader>tn, not <leader>tc: that one is the Copilot toggle (init.lua).
vim.keymap.set("n", "<leader>tn", function()
    neotest.run.run()
end)

vim.keymap.set("n", "<leader>tf", function()
    neotest.run.run(vim.fn.expand("%"))
end)
