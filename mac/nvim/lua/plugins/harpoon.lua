local harpoon = require("harpoon")

harpoon:setup()

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
vim.keymap.set("n", "<leader>5", function() harpoon:list():select(5) end)

local function harpoon_tabline()
    local list = harpoon:list()
    local current = vim.fn.bufnr("%")
    local tabs = {}
    for i, item in ipairs(list.items) do
        local name = vim.fn.fnamemodify(item.value, ":t")
        local bufnr = vim.fn.bufnr(item.value)
        if bufnr == current then
            table.insert(tabs, "%#TabLineSel# " .. i .. " " .. name .. " ")
        else
            table.insert(tabs, "%#TabLine# " .. i .. " " .. name .. " ")
        end
    end
    if #tabs == 0 then return "" end
    return table.concat(tabs, "%#TabLineFill#|") .. "%#TabLineFill#"
end

vim.o.showtabline = 2
local group = vim.api.nvim_create_augroup("HarpoonTabline", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave" }, {
    group = group,
    callback = function()
        vim.o.tabline = harpoon_tabline()
    end,
})
