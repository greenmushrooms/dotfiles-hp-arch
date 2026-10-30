-- No nvim-lspconfig installed, so supply the launch command explicitly.
-- pyright-langserver is installed by mason (see lua/plugins/lsp.lua) into
-- mason's bin dir, which isn't on nvim's PATH.
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/pyright-langserver"

return {
    cmd = { mason_bin, "--stdio" },
    filetypes = { "python" },
    root_markers = {
        "pyproject.toml",
        "setup.py",
        "setup.cfg",
        "requirements.txt",
        "Pipfile",
        "pyrightconfig.json",
        ".venv",
        ".git",
    },
    -- Point pyright at a project-local virtualenv when one exists, so imports
    -- resolve against the venv's packages instead of the system interpreter.
    before_init = function(_, config)
        local root = config.root_dir
        if not root then
            return
        end
        local venv_py = root .. "/.venv/bin/python"
        if vim.fn.executable(venv_py) == 1 then
            config.settings = config.settings or {}
            config.settings.python = config.settings.python or {}
            config.settings.python.pythonPath = venv_py
        end
    end,
    settings = {
        python = {
            analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
            },
        },
    },
}
