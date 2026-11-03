require("cloak").setup({
    -- Off by default: masked values hide trailing whitespace and stray
    -- characters, which makes debugging credentials in .env painful.
    -- Toggle it back on with <leader>ck before screen sharing.
    enabled = false,
    cloak_character = "*",
    highlight_group = "Comment",
    patterns = {
        {
            file_pattern = {
                ".env*",
                "wrangler.toml",
                ".dev.vars",
            },
            cloak_pattern = "=.+",
        },
    },
})

vim.keymap.set("n", "<leader>ck", "<cmd>CloakToggle<CR>", { desc = "Toggle cloak (mask .env values)" })
