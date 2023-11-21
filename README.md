# nvim-select-buffer
Plugin for NeoVim to display and switch to a buffer. (also my first nvim plugin)

# Demo
![demo](./media/plugin_demo.gif)

# Installation
Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
-- In packer.lua add
use 'ArmanHZ/nvim-select-buffer'
```

# Setting keybinding to launch the plugin

Create the `selectbuffer.lua` file in the `/after/plugin` directory and add the following lines:

```lua
-- In /after/plugin/selectbuffer.lua file
local select_buffer = require("select-buffer")
vim.keymap.set("n", "<leader>bb", select_buffer.main)   -- You can use any keybinding you want
```

# Todo
- [x] ~~Complete the movement feature and select buffer feature~~
- [x] ~~Add help menu below the Buffer text~~
- [x] ~~Prepare the directory structure for 'packer' compatibility~~
- [x] ~~Add a demo video for the repo~~
- [x] ~~Added line highlighting for the buffer window for better visibility~~
- [ ] Update old api calls to new ones (exec -> exec2)
- [ ] Re-write the buffer order, s.t. latest buffers will be at the top
- [ ] Clean the code and add some color to the display
- [ ] Disable some movement keys while showing the buffer
- [ ] Update the demo and readme after all these tasks are done

