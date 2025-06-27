# bujo.nvim

A markdown bullet journal accessible from any neovim session!

Featuring:

- uses standard markdown files so you're not locked in
- access and edit your notes from any neovim instance
- define templates for new notes using [leafo/etlua](https://github.com/leafo/etlua)
- provides a [telescope](https://github.com/nvim-telescope/telescope.nvim) extension to easily find notes and insert links

Coming soon:

- executable codeblocks using [michaelb/sniprun](https://github.com/michaelb/sniprun)
	- the default visual selection behavior of sniprun works, but automatically code-fencing blocks and displaying multiline output does not

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
  {
    "timhugh/bujo.nvim",
    lazy = true,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "leafo/etlua", -- optional; required for using templates
      "michaelb/sniprun", -- optional; required for executing code blocks
    },
    opts = {},
  },
```

## Usage

bujo.nvim provides user commands and default keybinds for all of its functions. See the [Configuration](#Configuration) section if you would like to change any of the default keybinds.

### `:Bujo now`

Default keybind config: `journal.now_keybind = "<leader>nn"`

Open the spread for your current time period. By default, this will be one file per week, stored in `~/.journal/entries/<year>/<month>-<week_number>.md`. See the [Configuration](#Configuration) section if you would like to change the cadence.

### `:Bujo note`

Default keybind config: `journal.note_keybind = "<leader>nN"`

Will prompt for a name and create a new file in `~/.journal/notes`.

### `:Bujo find / :Telescope bujo`

Default keybind config: `picker.open_keybind = "<leader>nf"`

Opens a Telescope picker for all of your entries and notes for easy navigation. Selecting a file will open it in a new buffer. 

To insert a link to the selected file in the current buffer: `picker.insert_link_keybind = "<M-i>"`

### `:Bujo follow_journal_link`

Default keybind config: `markdown.follow_journal_link_keybind = "<M-CR>"`

Finds a markdown link in the current line (if there are multiple, it will select the one under your cursor) and opens the linked note in a new buffer. This allows you to have relative links like `notes/my_current_project.md` or `entries/2025-06-25.md` relative to your journal root.

### `:Bujo follow_external_link`

Default keybind config: `markdown.follow_external_link_keybind = "gx"`

Finds a markdown link in the current line (if there are multiple, it will select the one under your cursor) and opens the link with the default system handler. This is the normal behavior of "gx" in default neovim mappings, but this command doesn't require your cursor to be inside the link if there is only one link on the line.

### `:Bujo toggle_check`

Default keybind config: `markdown.toggle_check_keybind = "<C-Space>"`

Toggles the markdown checkbox on the current line between unchecked `[ ]` and checked `[x]`.

### `:Bujo execute_code_block`

Default keybind config: `markdown.execute_code_block_keybind = "<leader>nr"`

Executes the code block under the cursor using [michaelb/sniprun](https://github.com/michaelb/sniprun). Bujo doesn't supply any special configuration to sniprun, it just uses treesitter to find the code and pass it along, so you'll want to refer to [sniprun's thorough documentation](https://michaelb.github.io/sniprun/) if you need to tweak anything for the languages you use.

### Git integration

Disabled by default:
```lua
git = {
  auto_commit = false,
  auto_push = false,
  debounce_ms = 1000,
},
```

When `git.auto_commit` is enabled, saving any file inside your journal directory will automatically git add and git commit your entire journal with a timestamp as the message. *Note that we are committing the entire journal to avoid the complexity of gracefully handling files being deleted or renamed.*

There is a debounce to prevent multiple commits for rapid writes, e.g. when using `:wa` that defaults to 1000ms but can be configured using `git.debounce_ms`.

When `git.auto_push` is enabled, `git push` will automatically run after the commit is created.

## Configuration

No configuration is necessary for bujo.nvim to work out of the box. By default, it will create weekly spreads in the `~/.journal` directory. You can see the default settings in [config.lua](/lua/bujo/config.lua), and override any of them in your setup.

If you would like to disable any of the default keybinds, simply set their value to `false`.

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
  {
    "timhugh/bujo.nvim",
    ......
    opts = {
      base_directory = "~/my_journal",
      journal = {
			  filename_template = "%Y-%m-%d",
			},
			markdown = {
        follow_external_link_keybind = false,
			},
    },
  },
```

Or manually:
```lua
require("bujo.nvim").setup({
	base_directory = "~/my_journal",
	journal = {
		filename_template = "%Y-%m-%d",
	},
	{
		follow_external_link_keybind = false,
	},
})
```
