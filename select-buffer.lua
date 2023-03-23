local api = vim.api
local buf, win

local function center(str)
    local width = api.nvim_win_get_width(0)
    local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
    return string.rep(' ', shift) .. str
end

local function open_window()
    buf = api.nvim_create_buf(false, true) -- create new emtpy buffer

    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- Dimensions of main vim window
    local width = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")

    -- Pop-up size calculation
    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.8)

    -- Pop-up starting position
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    -- Window options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col
    }

    -- Create pop-up with buffer attached
    win = api.nvim_open_win(buf, true, opts)
end

local buffer_count = 0  -- How many buffers are open (:buffers command output)

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

local index = 4     -- Current row/position on the pop-up
local first_buffer_index = 4    -- First buffer text row on the pop-up

local function move_cursor_up(row_column_tuple)
    if (index + 1) < (buffer_count + first_buffer_index) then
        index = index + 1
        api.nvim_win_set_cursor(win, {row_column_tuple[1] + 1, row_column_tuple[2]})
    end
end

local function move_cursor_down(row_column_tuple)
    if (index - 1) >= first_buffer_index then
        index = index - 1
        api.nvim_win_set_cursor(win, {row_column_tuple[1] - 1, row_column_tuple[2]})
    end
end

local function set_index(number)
    local row_column_tuple = api.nvim_win_get_cursor(win)
    if number == 1 then
        move_cursor_up(row_column_tuple)
    elseif number == -1 then
        move_cursor_down(row_column_tuple)
    end
end

local function close_window()
    api.nvim_win_close(win, true)
    index = 4
end

local function switch_buffer()
    local selected_line = api.nvim_buf_get_lines(buf, index - 1, index, true)
    local left_trim = selected_line[1]:gsub("^%s+", "")
    local selected_buffer_number = left_trim:match("%S+")
    close_window()
    api.nvim_exec("buffer " .. selected_buffer_number, false)
end

local function set_mappings()
    local mappings = {
        ['<cr>'] = 'switch_buffer()',
        j = 'set_index(1)',     -- Go down, so Row count increase
        k = 'set_index(-1)',    -- Go up, so Row count reduces
        q = 'close_window()'
    }

    for k,v in pairs(mappings) do
        api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"testplugin".'..v..'<cr>', {
            nowait = true, noremap = true, silent = true
        })
    end
end

local function init_cursor()
    api.nvim_feedkeys("3j^", "n", false)
end

local function main()
    open_window()
    set_mappings()
    update_view()
    init_cursor()
end

return {
    main = main,
    open_window = open_window,
    set_mappings = set_mappings,
    update_view = update_view,
    init_cursor = init_cursor,
    switch_buffer = switch_buffer,
    set_index = set_index,
    close_window = close_window
}

