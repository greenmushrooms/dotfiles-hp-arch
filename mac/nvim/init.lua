-- Leader must be set before lazy
vim.g.mapleader = " "

-- Options
vim.opt.guicursor = ""
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = (os.getenv("HOME") or os.getenv("USERPROFILE")) .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
-- Completion menu: show it, but never auto-select/insert a candidate — the
-- LSP autotrigger (see LspAttach) would otherwise jam matches into the buffer
-- as you type. You pick explicitly with <C-n>/<C-y>/<CR>.
vim.opt.completeopt = { "menuone", "noselect", "popup", "fuzzy" }
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"
vim.opt.shell = "nu"

-- Keymaps
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>px", "<cmd>Neotree toggle<CR>")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])
vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])
vim.keymap.set("i", "<C-c>", "<Esc>")
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>w", "<cmd>set wrap!<CR>", { desc = "Toggle visual line wrap" })
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })
vim.keymap.set("n", "<leader>ee", "oif err != nil {<CR>}<Esc>Oreturn err<Esc>")
vim.keymap.set("n", "<leader><leader>", function() vim.cmd("so") end)

-- Completion accept: with completeopt=noselect nothing is preselected, so
-- <C-y> alone has nothing to confirm. Make <CR> accept the highlighted item,
-- or the first item if none is highlighted; otherwise a plain newline.
vim.keymap.set("i", "<CR>", function()
    if vim.fn.pumvisible() == 0 then
        return "<CR>"
    end
    -- item selected via <C-n>/<C-p> -> confirm it; else pick the first item
    local selected = vim.fn.complete_info({ "selected" }).selected
    return selected ~= -1 and "<C-y>" or "<C-n><C-y>"
end, { expr = true })

-- Snippet jump keymaps (native vim.snippet)
vim.keymap.set({"i", "s"}, "<C-s>;", function()
    if vim.snippet.active({ direction = 1 }) then vim.snippet.jump(1) end
end, {silent = true})
vim.keymap.set({"i", "s"}, "<C-s>,", function()
    if vim.snippet.active({ direction = -1 }) then vim.snippet.jump(-1) end
end, {silent = true})

-- Plugin build hooks (must be registered before vim.pack.add)
vim.api.nvim_create_autocmd("PackChanged", {
    callback = function(ev)
        local name = ev.data.spec.name
        local kind = ev.data.kind
        if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
            vim.cmd("TSUpdate")
        end
    end,
})

-- Install + load plugins via Neovim 0.12 native vim.pack
vim.pack.add({
    -- Core
    { src = "https://github.com/nvim-lua/plenary.nvim",            name = "plenary" },
    { src = "https://github.com/eandrju/cellular-automaton.nvim" },

    -- Colors
    { src = "https://github.com/folke/tokyonight.nvim" },
    { src = "https://github.com/rose-pine/neovim",                 name = "rose-pine" },

    -- Finders / nav
    { src = "https://github.com/nvim-telescope/telescope.nvim" },
    { src = "https://github.com/ThePrimeagen/harpoon",             version = "harpoon2" },
    { src = "https://github.com/mbbill/undotree" },
    { src = "https://github.com/MunifTanjim/nui.nvim",             name = "nui" },
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/nvim-neo-tree/neo-tree.nvim",      version = "v3.x" },

    -- Treesitter
    { src = "https://github.com/nvim-treesitter/nvim-treesitter",  version = "main" },

    -- Git
    { src = "https://github.com/tpope/vim-fugitive" },

    -- LSP support
    { src = "https://github.com/williamboman/mason.nvim" },
    { src = "https://github.com/j-hui/fidget.nvim" },

    -- Tests
    { src = "https://github.com/nvim-neotest/nvim-nio" },
    { src = "https://github.com/antoinemadec/FixCursorHold.nvim" },
    { src = "https://github.com/nvim-neotest/neotest" },
    { src = "https://github.com/nvim-neotest/neotest-python" },
    { src = "https://github.com/nvim-neotest/neotest-go" },

    -- QoL
    { src = "https://github.com/laytan/cloak.nvim" },
    { src = "https://github.com/danymat/neogen" },
    { src = "https://github.com/folke/trouble.nvim" },
    { src = "https://github.com/folke/zen-mode.nvim" },

    -- AI
    { src = "https://github.com/nickjvandyke/opencode.nvim" },
})

-- Per-plugin configuration (imperative, runs after pack.add finishes)
require("plugins")

-- Enable native LSP servers (configured in lsp/ directory)
vim.lsp.enable({ "lua_ls", "gopls", "pyright", "copilot" })

-- Copilot ghost text (native inline completion). <Tab> accepts the suggestion,
-- falling back to a normal tab when none is showing; <M-]>/<M-[> cycle
-- candidates; <leader>tc toggles it off/on.
vim.lsp.inline_completion.enable()
vim.keymap.set("i", "<Tab>", function()
    if not vim.lsp.inline_completion.get() then
        return "<Tab>"
    end
end, { expr = true, desc = "Accept Copilot suggestion" })
vim.keymap.set("i", "<M-]>", function() vim.lsp.inline_completion.select({ count = 1 }) end, { desc = "Next Copilot suggestion" })
vim.keymap.set("i", "<M-[>", function() vim.lsp.inline_completion.select({ count = -1 }) end, { desc = "Prev Copilot suggestion" })
vim.keymap.set("n", "<leader>tc", function()
    local on = not vim.lsp.inline_completion.is_enabled()
    vim.lsp.inline_completion.enable(on)
    vim.notify("Copilot suggestions " .. (on and "on" or "off"))
end, { desc = "Toggle Copilot suggestions" })

-- Autocommands
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

autocmd("TextYankPost", {
    group = augroup("HighlightYank", {}),
    pattern = "*",
    callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 40 })
    end,
})

autocmd("BufWritePre", {
    group = augroup("TrimWhitespace", {}),
    pattern = "*",
    command = [[%s/\s\+$//e]],
})

autocmd("LspAttach", {
    group = augroup("LspKeymaps", {}),
    callback = function(e)
        local client = vim.lsp.get_client_by_id(e.data.client_id)
        local opts = { buffer = e.buf }

        -- Copilot only serves inline completion, so it gets no gd/K/etc. maps
        -- (they'd clobber filetype maps in buffers where it's the only server).
        if client and client.name == "copilot" then
            return
        end

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = 1 }) end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = -1 }) end, opts)

        if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, e.buf, { autotrigger = true })

            -- autotrigger only fires on the server's trigger chars (pyright: . [ " '),
            -- so plain identifiers (e.g. your declared variables) never pop the menu.
            -- Re-request completion whenever a word char is typed and no menu is open.
            autocmd("InsertCharPre", {
                group = augroup("LspWordTrigger", { clear = false }),
                buffer = e.buf,
                callback = function()
                    if vim.fn.pumvisible() == 1 then
                        return
                    end
                    if vim.v.char:match("[%w_]") then
                        vim.schedule(function()
                            vim.lsp.completion.get()
                        end)
                    end
                end,
            })
        end
    end,
})

vim.diagnostic.config({
    float = {
        focusable = false,
        style = "minimal",
        border = "rounded",
        source = true,
        header = "",
        prefix = "",
    },
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25

