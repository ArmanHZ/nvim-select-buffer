local api = vim.api
local buf, win

local M = {}

M.center = function(str)
    local width = api.nvim_win_get_width(0)
    local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
    return string.rep(' ', shift) .. str
end

M.left_align = function(str)
    local width = api.nvim_win_get_width(0)
    local shift = math.floor(width - (width * 0.85))
    return string.rep(' ', shift) .. str
end

M.right_align = function(str, edit_flag)
    local width = api.nvim_win_get_width(0)
    local shift
    if edit_flag == ''
    then
        shift = math.floor(width - (width * 0.30) - string.len(str))
    else
        shift = math.floor(width - (width * 0.30) - string.len(str) - string.len(edit_flag))
    end
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
    local win_width = math.ceil(width * 0.6)

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

BUFFER_COUNT = 0  -- How many buffers are open (:buffers command output)

M.get_buffers = function()
    local active_buffers = api.nvim_list_bufs()
    local listed_buffers = {}
    for _, v in pairs(active_buffers) do
        if (api.nvim_buf_get_option(v, 'buflisted'))
        then
            local buffer_info = {} -- id, full path, modified, (read only, file type) Maybe in future if needed
            table.insert(buffer_info, v)

            local buffer_name = api.nvim_buf_get_name(v)
            if buffer_name == '' then
                buffer_name = "[No Name]"
            end
            table.insert(buffer_info, buffer_name)

            if api.nvim_buf_get_option(v, "modified") then
                table.insert(buffer_info, "[+]")
            else
                table.insert(buffer_info, "")
            end

            table.insert(listed_buffers, buffer_info)
        end
    end
    BUFFER_COUNT = #listed_buffers
    return listed_buffers
end

M.set_buffer_variable_timestamp = function(buffers)
    for i, v in pairs(buffers) do
        local isSet, _ = pcall(api.nvim_buf_get_var, v[1], "timestamp")
        if not isSet
        then
            -- When you have multiple buffers that have the same timestamp,
            -- it can mess up the order. Deducing a small integer helps.
            -- This only applies to buffers who don't have a timestamp.
            local timestamp = M.get_timestamp() - i
            api.nvim_buf_set_var(v[1], "timestamp", timestamp)
            table.insert(v, timestamp)
        else
            v[4] = api.nvim_buf_get_var(v[1], "timestamp")
        end
    end
end

M.get_timestamp = function ()
    return os.time()
end

M.update_view = function()
    local lines = {}
    local result = M.get_buffers()
    M.set_buffer_variable_timestamp(result)

    -- Sort by timestamp
    table.sort(result, function(a, b)
        return a[4] > b[4]
    end)

    -- Current buffer will be one below for usability.
    local temp = result[1]
    result[1] = result[2]
    result[2] = temp

    for _, v in pairs(result) do
        table.insert(lines, M.left_align(v[1]) .. " " .. v[3] .. M.right_align(v[2], v[3]))
    end

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
    if (index + 1) < (BUFFER_COUNT + first_buffer_index) then
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

-- TODO: fix how we get the number
M.switch_buffer = function()
    local selected_line = api.nvim_buf_get_lines(buf, index - 1, index, true)
    local left_trim = selected_line[1]:gsub("^%s+", "")
    local selected_buffer_number = left_trim:match("%S+")
    M.close_window()

    local timestamp = M.get_timestamp()
    api.nvim_buf_set_var(tonumber(selected_buffer_number), "timestamp", timestamp)

    api.nvim_exec2("buffer " .. selected_buffer_number, {})
end

M.set_mappings = function()
    local mappings = {
        ['<cr>'] = 'switch_buffer()',
        j = 'set_index(1)',     -- Go down, so Row count increase
        k = 'set_index(-1)',    -- Go up, so Row count reduces
        q = 'close_window()',
        ['<esc>'] = 'close_window()',    -- Works slower than q. TODO: Fix (somehow)
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

