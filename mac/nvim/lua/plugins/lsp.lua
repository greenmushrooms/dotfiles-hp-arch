require("mason").setup()
require("fidget").setup({})

-- Ensure the mason-managed language servers are installed.
-- mason has no declarative ensure_installed without mason-lspconfig, so install
-- imperatively if missing. Runs once; no-op when already present.
local function ensure_mason(pkg)
    local ok, registry = pcall(require, "mason-registry")
    if not ok then
        return
    end
    local function install()
        if registry.has_package(pkg) and not registry.is_installed(pkg) then
            registry.get_package(pkg):install()
        end
    end
    if registry.refresh then
        registry.refresh(install)
    else
        install()
    end
end

ensure_mason("pyright")
ensure_mason("copilot-language-server")
