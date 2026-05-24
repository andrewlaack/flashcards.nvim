local function flash()

    local currentWin = vim.api.nvim_get_current_win()

    local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))

    local files = vim.split(vim.fn.glob(cwd .. "/*.md"), "\n")

    local buf = vim.api.nvim_create_buf(false, true)

    local row = 0
    local col = 0

    local width = vim.fn.winwidth(currentWin)
    local height = vim.fn.winheight(currentWin)

    local opts = {
      width = width,
      height = height,
      row = row,
      col = col,
      border = "rounded",
      relative = "win",
      title = "Flashcards",
      title_pos = "center"
    }

    local _ = vim.api.nvim_open_win(buf, true, opts)

    local file = vim.fn.readfile(files[1])
    vim.api.nvim_buf_set_lines(buf, 0, 10, false, file)


end

vim.api.nvim_create_user_command('Flash', flash, {})
