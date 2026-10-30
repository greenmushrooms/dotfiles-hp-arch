-- GitHub Copilot via the official language server, driving Neovim 0.12's
-- native inline completion (ghost text). No nvim-lspconfig installed, so the
-- launch command and the sign-in flow are supplied here.
-- copilot-language-server is installed by mason (see lua/plugins/lsp.lua).
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/copilot-language-server"

-- Device-flow sign in: copies the one-time code to the clipboard, then has the
-- server open the browser and wait for confirmation.
local function sign_in(bufnr, client)
    client:request("signIn", vim.empty_dict(), function(err, result)
        if err then
            vim.notify(err.message, vim.log.levels.ERROR)
            return
        end
        if result.status == "AlreadySignedIn" then
            vim.notify("Copilot: already signed in as " .. result.user)
            return
        end
        if result.command then
            vim.fn.setreg("+", result.userCode)
            local choice = vim.fn.confirm(
                "Copilot code " .. result.userCode .. " copied to clipboard.\nOpen the browser to sign in?",
                "&Yes\n&No"
            )
            if choice == 1 then
                client:exec_cmd(result.command, { bufnr = bufnr }, function(cmd_err, cmd_result)
                    if cmd_err then
                        vim.notify(cmd_err.message, vim.log.levels.ERROR)
                    elseif cmd_result.status == "OK" then
                        vim.notify("Copilot: signed in as " .. cmd_result.user)
                    end
                end)
            end
        elseif result.userCode then
            vim.notify("Copilot: enter code " .. result.userCode .. " at " .. result.verificationUri)
        end
    end)
end

return {
    cmd = { mason_bin, "--stdio" },
    root_markers = { ".git" },
    init_options = {
        editorInfo = { name = "Neovim", version = tostring(vim.version()) },
        editorPluginInfo = { name = "Neovim", version = tostring(vim.version()) },
    },
    settings = {
        telemetry = { telemetryLevel = "off" },
    },
    on_attach = function(client, bufnr)
        vim.api.nvim_buf_create_user_command(bufnr, "CopilotSignIn", function()
            sign_in(bufnr, client)
        end, { desc = "Sign in to GitHub Copilot" })
        vim.api.nvim_buf_create_user_command(bufnr, "CopilotSignOut", function()
            client:request("signOut", vim.empty_dict(), function(err)
                vim.notify(err and err.message or "Copilot: signed out")
            end)
        end, { desc = "Sign out of GitHub Copilot" })
    end,
}
