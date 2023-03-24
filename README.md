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

Create the `selectbuffer.lua` file in the `/after` directory and add the following lines:

```lua
-- In /after/selectbuffer.lua file
local select_buffer = require("select-buffer")
vim.keymap.set("n", "<leader>bb", select_buffer.main)   -- You can use any keybinding you want
```

# Todo
- ~~Complete the movement feature and select buffer feature~~
- ~~Add help menu below the Buffer text~~
- ~~Prepare the directory structure for 'packer' compatibility~~
- ~~Add a demo video for the repo~~
- Clean the code and add some color to the display

