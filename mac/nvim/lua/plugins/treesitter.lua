-- nvim-treesitter `main` branch (the rewrite, Neovim 0.12+).
-- NOTE: `setup({ ensure_installed = ... })` is a MASTER-branch API and is a
-- silent no-op on main. Main uses .install({...}) to fetch parsers, and
-- highlighting is enabled per-buffer via vim.treesitter.start() (not by the
-- plugin). See :h nvim-treesitter and :h treesitter-highlight.
local ts = require("nvim-treesitter")

ts.setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Parsers to keep installed. .install() is async and a no-op if already present.
-- `jinja` + `jinja_inline` are both needed for full Jinja highlighting.
ts.install({
    "vimdoc", "python", "go", "gomod", "gosum",
    "javascript", "typescript", "c", "lua", "rust",
    "bash", "json", "yaml", "toml", "dockerfile",
    "sql", "jinja", "jinja_inline",
})

-- Enable treesitter highlighting per filetype (main branch does not auto-enable).
vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("TreesitterHighlight", {}),
    pattern = {
        "vimdoc", "python", "go", "gomod", "gosum",
        "javascript", "typescript", "c", "lua", "rust",
        "sh", "bash", "json", "yaml", "toml", "dockerfile",
        "sql", "jinja", "htmldjango",
    },
    callback = function()
        pcall(vim.treesitter.start)
    end,
})
