local api = vim.api
local buf, win

local index = 3
local buffer_count = 0

local function center(str)
    local width = api.nvim_win_get_width(0)
    local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
    return string.rep(' ', shift) .. str
end

local function open_window()
    buf = api.nvim_create_buf(false, true) -- create new emtpy buffer

    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- get dimensions
    local width = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")

    -- calculate our floating window size
    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.8)

    -- and its starting position
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    -- set some options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col
    }

    -- and finally create it with buffer attached
    win = api.nvim_open_win(buf, true, opts)
end

local function update_view()
    local result = api.nvim_exec("buffers", true)
    local lines = {}

    for s in result:gmatch("[^\r\n]+") do
        table.insert(lines, center(s))
    end

    buffer_count = #lines

    api.nvim_buf_set_lines(buf, 0, 2, false, { "", center("Buffers"), "" })
    api.nvim_buf_set_lines(buf, 3, -1, false, lines)
end

local function move_cursor()
    api.nvim_feedkeys("3j^", "n", false)
end

local function set_index(number)
    print("Current index: " .. index)
    if number == 1 then
        if (index + 1) < buffer_count then
            index = index + 1
        end
    elseif number == -1 then
        if (index - 1) > 3 then
            index = index - 1
        end
    end
end

local function switch_buffer()
    local test = api.nvim_buf_get_lines(buf, index, index + 1, true)
    for k, v in pairs(test) do
        print(k .. "  " .. v)
    end
end

local function close_window()
    api.nvim_win_close(win, true)
end

local function set_mappings()
    local mappings = {
        ['<cr>'] = 'switch_buffer()',
        j = 'set_index(-1)',
        k = 'set_index(1)',
        q = 'close_window()'
    }

    for k,v in pairs(mappings) do
        api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"testplugin".'..v..'<cr>', {
            nowait = true, noremap = true, silent = true
        })
    end
end

local function main()
    open_window()
    set_mappings()
    update_view()
    move_cursor()
end

return {
    main = main,
    open_window = open_window,
    update_view = update_view,
    set_mappings = set_mappings,
    close_window = close_window,
    center = center,
    move_cursor = move_cursor,
    switch_buffer = switch_buffer,
    set_index = set_index
}

