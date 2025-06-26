# bujo.nvim

A markdown bullet journal accessible from any neovim session!

Featuring:

- access and edit your notes from any neovim instance
- define templates for new notes using [leafo/etlua](https://github.com/leafo/etlua)
- create arbitrary notes on the fly
- markdown links to navigate between files
- open a telescope picker to quickly navigate to notes or past/future spreads
- quickly insert links into your current buffer

Coming soon:

- executable codeblocks using [michaelb/sniprun](https://github.com/michaelb/sniprun)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```
  {
    "timhugh/bujo.nvim",
    lazy = true,
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    opts = {},
  },
```

## Usage

### `:Bujo now`

Open the spread for your current time period. By default, this will be one file per week, stored in `~/.journal/entries/<year>/<month>-<week_number>.md`. See the configuration section if you would like to change the cadence.

### `:Bujo note`

Will prompt for a name and create a new file in `~/.journal/notes`.

### `:Bujo find / :Telescope bujo`

Opens a Telescope picker for all of your entries and notes for easy navigation. Selecting a file will open it in a new buffer. `<M-i>` will insert a markdown link to that file in the current buffer.

### `:Bujo follow`

Finds a markdown link in the current line (if there are multiple, it will select the one under your cursor) and opens the linked note in a new buffer. This allows you to have relative links like `notes/my_current_project.md` or `entries/2025-06-25.md` relative to your journal root.

### `:Bujo togglecheck`

Toggles the markdown checkbox on the current line between unchecked `[ ]` and checked `[x]`.

## Configuration

No configuration is necessary for bujo.nvim to work out of the box. By default, it will create weekly spreads in the ~/.journal directory. You can see the default settings in [config.lua](/lua/bujo/config.lua), and override any of them in your setup:

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```
  {
    "timhugh/bujo.nvim",
    ......
    opts = {
      journal_dir = "~/my_journal",
      entries_name_template = "%Y-%m-%d",
    },
  },
```

Or manually:
```
require("bujo.nvim").setup({
  journal_dir = "~/my_journal",
  entries_name_template = "%Y-%m-%d",
})
```
