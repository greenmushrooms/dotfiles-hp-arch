---@type opencode.Opts
vim.g.opencode_opts = {}

vim.o.autoread = true

local opencode = function() return require("opencode") end

vim.keymap.set({ "n", "x" }, "<leader>oa", function() opencode().ask("@this: ", { submit = true }) end, { desc = "Ask opencode…" })
vim.keymap.set({ "n", "x" }, "<leader>os", function() opencode().select() end,                          { desc = "Select opencode…" })
vim.keymap.set({ "n", "t" }, "<leader>ot", function() opencode().toggle() end,                          { desc = "Toggle opencode" })

vim.keymap.set({ "n", "x" }, "go",  function() return opencode().operator("@this ") end,        { desc = "Add range to opencode", expr = true })
vim.keymap.set("n",          "goo", function() return opencode().operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })

vim.keymap.set("n", "<leader>ou", function() opencode().command("session.half.page.up") end,   { desc = "Scroll opencode up" })
vim.keymap.set("n", "<leader>od", function() opencode().command("session.half.page.down") end, { desc = "Scroll opencode down" })
