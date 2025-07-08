# bujo.nvim

A markdown bullet journal accessible from any neovim session!

Featuring:

- uses standard markdown files so you're not locked in to a specific journal app/plugin
- access and edit your notes from any neovim instance
- define templates for new notes using [leafo/etlua](https://github.com/leafo/etlua)
- provides [telescope](https://github.com/nvim-telescope/telescope.nvim) extensions to easily find notes and insert links
- executable codeblocks using [michaelb/sniprun](https://github.com/michaelb/sniprun)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "timhugh/bujo.nvim",
  lazy = true,
  dependencies = {
    "nvim-telescope/telescope.nvim", -- optional but highly recommended; required for navigating notes
    "leafo/etlua", -- optional; required for using templates
    "michaelb/sniprun", -- optional; required for executing code blocks
  },
  opts = {},
},
```

It is _highly_ recommended that you use a version of Neovim built with LuaJIT. It's very likely that you are already are, but if you're not sure you can learn more about that in the [Neovim docs](https://neovim.io/doc/user/lua.html#lua-luajit)

## Usage

bujo.nvim provides user commands and default keybinds for all of its functions. See the [Configuration](#Configuration) section if you would like to change any of the default keybinds.

### `:Bujo now`

Default keybind config: `journal.now_keybind = "<leader>nn"`

Open the spread for your current time period. By default, this will be one file per week, stored in `~/.bujo/entries/<year>/W<week_number>.md`. See the [Configuration](#Configuration) section if you would like to change the cadence.

If `journal.template` is defined and [leafo/etlua](https://github.com/leafo/etlua) is present, the configured template will automatically be executed when a new entry is created.

### `:Bujo next / :Bujo previous`

> [!WARNING] this functionality requires LuaJIT

Default keybind config:
```lua
next_keybind = "<leader>nf",
previous_keybind = "<leader>nb",
```

Open the spread for the next or previous time period. If a journal spread is currently open, this will navigate forward or backward through time. If a journal spread is not open, this will open the next or previous spread relative to the current date (e.g. next week or last week for weekly spreads).

If `journal.template` is defined and [leafo/etlua](https://github.com/leafo/etlua) is present, the configured template will automatically be executed when a new entry is created.

### `:Bujo note`

Default keybind config: `notes.note_keybind = "<leader>nN"`

Will prompt for a name and create a new file in `<base_directory>/notes`.

### `:Bujo find / :Telescope bujo`

> [!WARNING] This functionality requires [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

Default keybind config: `picker.open_keybind = "<leader>nf"`

Opens a Telescope picker for all of your entries and notes for easy navigation. Selecting a file will open it in a new buffer. 

To insert a link to the selected file in the current buffer: `picker.insert_link_keybind = "<M-i>"`

### `:Bujo insert_link / :Telescope bujo_insert_link

> [!WARNING] This functionality requires [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

Default keybind config: `picker.insert_link_picker_keybind`

Similar to `:Bujo find`, this opens a Telescope picker for all of your entries and notes, but it is only mapped in insert mode and the default action inserts a markdown link into the current buffer instead of opening the file.

### `:Bujo follow_journal_link`

Default keybind config: `markdown.follow_journal_link_keybind = "gf"`

Finds a markdown link in the current line (if there are multiple, it will select the one under your cursor) and opens the linked note in a new buffer. This allows you to have relative links like `notes/my_current_project.md` or `entries/2025-06-25.md` relative to your journal root.

### `:Bujo follow_external_link`

Default keybind config: `markdown.follow_external_link_keybind = "gx"`

Finds a markdown link in the current line (if there are multiple, it will select the one under your cursor) and opens the link with the default system handler. This is the normal behavior of "gx" in default neovim mappings, but this command doesn't require your cursor to be inside the link if there is only one link on the line.

### `:Bujo toggle_check`

Default keybind config: `markdown.toggle_check_keybind = "<C-Space>"`

Toggles the markdown checkbox on the current line between unchecked `[ ]` and checked `[x]`.

### `:Bujo execute_code_block`

Default keybind config: `markdown.execute_code_block_keybind = "<leader>nr"`

Executes the code block under the cursor using [michaelb/sniprun](https://github.com/michaelb/sniprun). bujo.nvim doesn't supply any special configuration to sniprun, it just uses treesitter to find the code and pass it along, so you'll want to refer to [sniprun's thorough documentation](https://michaelb.github.io/sniprun/) if you need to tweak anything for the languages you use.

### Templates

> [!WARNING] This functionality requires [leafo/etlua](https://github.com/leafo/etlua)

#### Journal entries / spreads

`.etlua` files can be placed in the templates_dir (`<base_directory>/.templates` by default). For journal entries, use the configuration `journal.template` to specify the filename of a template, and that template will be applied any time a new journal entry is created (using `:Bujo now`, `:Bujo next`, etc).

See the [etlua README](https://github.com/leafo/etlua/blob/master/README.md) for information about how to format templates. The evaluation context for templates includes access to the plugin configuration as `bujo_config`, as well as anything you normally have access to in Lua.

#### Arbitrary documents / `:Bujo template <template>`

> [!ERROR] This isn't implemented yet

`:Bujo template` does the same thing as `:Bujo note` but allows you to specify a template to execute on the created document.
For example `:Bujo template meeting_notes` will prompt for a new note name and create the file normally, but also execute `<template_dir>meeting_notes.etlua` on the newly created file.

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

No configuration is necessary for bujo.nvim to work out of the box. By default, it will create weekly spreads in the `~/.bujo` directory. You can see the default settings in [config.lua](/lua/bujo/config.lua), and override any of them in your setup.

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
require("bujo").setup({
  base_directory = "~/my_journal",
  journal = {
    filename_template = "%Y-%m-%d",
  },
  markdown = {
    follow_external_link_keybind = false,
  },
})
```

## Compatibility

bujo.nvim is by no means thoroughly tested with other plugins, but care has been taken to follow best practices for not breaking other stuff. Keybinds are only mapped globally when it makes sense and are otherwise confined only to markdown buffers, and those keybinds typically allow fallthrough so they won't block other plugins' behavior if they aren't relevant. If there are any conflicts, all keybinds are configurable (see [Configuration](#Configuration)).

bujo.nvim does not provide any markdown rendering or formatting capability. I've used it alongside [MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) without issue, but I wouldn't expect it to interfere with any rendering/formatting plugins.

## Contributing

Feel free to submit Issues or PRs! I tried to make bujo.nvim configurable and modular, but I built it with my personal use case in mind and with very little Lua and plugin development experience, so I'm happy to take suggestions and improvements.

Some notes on process/design ideals:
- There isn't a versioning/release strategy yet. I'm avoiding breaking changes, but no guarantees for the time being
- New features should be tested (see [Testing](#Testing) below)
- Most features should be configurable, but the default configuration should always work correctly
  - keybinds in particular should always be configurable and possible to disable if some functionality isn't desired

## Testing

Test coverage is not complete, but any new features should be tested (and PRs to improve the existing tests are also great). To run tests, you'll need [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) in your neovim config. Note that the plugin itself does not require plenary.nvim, it is only used for running tests. For example, if you are using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "timhugh/bujo.nvim",
  dependencies = {
    ...
    "nvim-lua/plenary.nvim",
  },
  ...
},
```

Then you can use Plenary as normal, or to run tests from the command line:

```sh
# all tests:
nvim --headless -c 'PlenaryBustedDirectory tests/' +qall
# specific test:
nvim --headless -c 'PlenaryBustedFile tests/notes_spec.lua' +qall
```
