local state = {
    buf = nil,
    win = nil,
    cards = {},
    index = 1,
    showing_back = false,
}

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function formatCard(strArr)

    local result = {}
    local firstNonBlank = false

    for i = 2, #strArr do
        if strArr[i] == "" and firstNonBlank == false then
            goto continue
        end

        firstNonBlank = true
        table.insert(result, strArr[i])

        ::continue::
    end

    return result
end

local function formatH1(str)
    if not str then
        return ""
    end

    if #str >= 3 then
        return str:sub(3)
    end

    return ""
end

local function load_cards()

    -- clear state
    state.cards = {}
    state.index = 1
    state.showing_back = false

    local cwd = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
    local files = vim.split(vim.fn.glob(cwd .. "/*.md"), "\n")
    files = shuffle(files)

    for index, _ in ipairs(files) do
        local file = vim.fn.readfile(files[index])
        -- add card to state
        table.insert(state.cards, {
            formatH1(file[1]), formatCard(file)
        })
    end
end

local function render()
    vim.bo[state.buf].modifiable = true
    vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, {})
    if state.showing_back then
        vim.api.nvim_buf_set_lines(state.buf, 0, 10, false, state.cards[state.index][2])
    else
        vim.api.nvim_buf_set_lines(state.buf, 0, 10, false, {state.cards[state.index][1]})
    end
    vim.bo[state.buf].modifiable = false
end


local function previous_card()
    state.index = state.index - 1
    state.showing_back = false

    if state.index < 1 then
        state.index = #state.cards
    end

    render()
end

local function next_card()
    state.index = state.index + 1
    state.showing_back = false

    if state.index > #state.cards then
        state.index = 1
    end

    render()
end

local function flip_card()
    state.showing_back = not state.showing_back
    render()
end

local function flash()

    -- this also clears the card state.
    load_cards()

    -- if this was already opened close and reopen because that's easier than figuring out if the window
    -- or buffer is rendered right now.


    if state.buf ~= nil then
        vim.api.nvim_buf_delete(state.buf, { force = true })
        state.buf = nil
        state.win = nil -- do windows have to be closed? presumably not, I think the window abstraction is simply a view into a buffer
                        -- which would then be closed by this point thus requiring no cleanup.
    end

    state.win = vim.api.nvim_get_current_win()
    state.buf = vim.api.nvim_create_buf(false, true)
    
    vim.api.nvim_buf_set_keymap(state.buf, "n", "<Left>", ":PreviousCard<CR>", {})
    vim.api.nvim_buf_set_keymap(state.buf, "n", "<Right>", ":NextCard<CR>", {})
    vim.api.nvim_buf_set_keymap(state.buf, "n", "<Up>", ":Flip<CR>", {})
    vim.api.nvim_buf_set_keymap(state.buf, "n", "<Down>", ":Flip<CR>", {})

    vim.api.nvim_buf_set_keymap(state.buf, "n", "h", ":PreviousCard<CR>", {})
    vim.api.nvim_buf_set_keymap(state.buf, "n", "l", ":NextCard<CR>", {})
    vim.api.nvim_buf_set_keymap(state.buf, "n", "k", ":Flip<CR>", {})
    vim.api.nvim_buf_set_keymap(state.buf, "n", "j", ":Flip<CR>", {})

    local row = 0
    local col = 0

    local width = vim.fn.winwidth(state.win)
    local height = vim.fn.winheight(state.win)

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

    local _ = vim.api.nvim_open_win(state.buf, true, opts)

    render()


end

vim.api.nvim_create_user_command('Flash', flash, {})
vim.api.nvim_create_user_command('Flip', flip_card, {})
vim.api.nvim_create_user_command('NextCard', next_card, {}) -- defaults first side
vim.api.nvim_create_user_command('PreviousCard', previous_card, {}) -- defaults first side
