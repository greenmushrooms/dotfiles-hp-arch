require("neo-tree").setup({
    close_if_last_window = true,
    window = {
        position = "left",
        width = 30,
    },
    filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
        },
    },
})
