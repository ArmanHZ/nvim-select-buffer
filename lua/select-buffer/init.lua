local api = vim.api
local buf, win

local M = {}

-- TODO Seems like doesn't center too well.
M.center = function(str)
    local width = api.nvim_win_get_width(0)
    local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
    return string.rep(' ', shift) .. str
end

M.open_window = function()
    buf = api.nvim_create_buf(false, true) -- create new emtpy buffer

    api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- Dimensions of main vim window
    local width = api.nvim_get_option("columns")
    local height = api.nvim_get_option("lines")

    -- Pop-up size calculation
    local win_height = math.ceil(height * 0.8 - 4)
    local win_width = math.ceil(width * 0.5)

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
    api.nvim_win_set_option(win, 'cursorline', true)
    -- Visual color, since the pop-up is different color. Normal cursorline color might fail in some themes.
    local visual_color = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Visual")), "bg", "gui")
    api.nvim_set_hl(0, 'CursorLine', { bg = visual_color})
end

local buffer_count = 0  -- How many buffers are open (:buffers command output)

M.update_view = function()
    local result = api.nvim_exec("buffers", true)
    local lines = {}

    for s in result:gmatch("[^\r\n]+") do
        table.insert(lines, M.center(s))
    end

    buffer_count = #lines

    local width = api.nvim_get_option("columns")
    local win_width = math.ceil(width * 0.8)

    api.nvim_buf_set_lines(buf, 0, 2, false, {
        "",
        M.center("Buffers"),
        "",
        M.center("Enter: Select   j: Down   k: Up   q: Close"),
        M.center(string.rep("-", win_width / 2))
    })
    api.nvim_buf_set_lines(buf, 5, -1, false, lines)
end

local index = 6     -- Current row/position on the pop-up
local first_buffer_index = 6    -- First buffer text row on the pop-up

M.move_cursor_up = function(row_column_tuple)
    if (index + 1) < (buffer_count + first_buffer_index) then
        index = index + 1
        api.nvim_win_set_cursor(win, {row_column_tuple[1] + 1, row_column_tuple[2]})
    end
end

M.move_cursor_down = function(row_column_tuple)
    if (index - 1) >= first_buffer_index then
        index = index - 1
        api.nvim_win_set_cursor(win, {row_column_tuple[1] - 1, row_column_tuple[2]})
    end
end

M.set_index = function(number)
    local row_column_tuple = api.nvim_win_get_cursor(win)
    if number == 1 then
        M.move_cursor_up(row_column_tuple)
    elseif number == -1 then
        M.move_cursor_down(row_column_tuple)
    end
end

M.close_window = function()
    api.nvim_win_close(win, true)
    index = 6   -- Reset index for the next time pop-up opens
end

M.switch_buffer = function()
    local selected_line = api.nvim_buf_get_lines(buf, index - 1, index, true)
    local left_trim = selected_line[1]:gsub("^%s+", "")
    local selected_buffer_number = left_trim:match("%S+")
    M.close_window()
    api.nvim_exec("buffer " .. selected_buffer_number, false)
end

M.set_mappings = function()
    local mappings = {
        ['<cr>'] = 'switch_buffer()',
        j = 'set_index(1)',     -- Go down, so Row count increase
        k = 'set_index(-1)',    -- Go up, so Row count reduces
        q = 'close_window()',
        ['<esc>'] = 'close_window()',    -- Works slower than q. TODO: Fix
    }

    for k,v in pairs(mappings) do
        api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"select-buffer".'..v..'<cr>', {
            nowait = true, noremap = true, silent = true
        })
    end
end

M.set_unmappings = function()
    local unmappings = {
        h = '<nop>',
        l = '<nop>'
    }

    for k,v in pairs(unmappings) do
        api.nvim_buf_set_keymap(buf, 'n', k, v, {
            nowait = true, noremap = true, silent = true
        })
    end
end

M.init_cursor = function()
    api.nvim_feedkeys((first_buffer_index - 1) .. "j^", "n", false)
end

M.main = function()
    M.open_window()
    M.set_mappings()
    M.set_unmappings()
    M.update_view()
    M.init_cursor()
end

return M

