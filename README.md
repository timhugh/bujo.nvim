# bujo.nvim

A markdown bullet journal accessible from any neovim session!

Featuring:

- Uses standard markdown files so you're not locked in to a specific journal app/plugin
- Highly configurable and unopinionated to suit your flow
- Access and edit your notes from any neovim instance
- Convenient mappings for inserting links and navigating between linked documents
- Define templates for new notes using [leafo/etlua](https://github.com/leafo/etlua)
- Provides [telescope](https://github.com/nvim-telescope/telescope.nvim) extensions to easily find notes and insert links
- Executable codeblocks using [michaelb/sniprun](https://github.com/michaelb/sniprun)
- Support for multiple spreads with arbitrary date spans. Weekly and monthly? Go for it. Daily and quarterly? Why not. Hourly? You do you.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "timhugh/bujo.nvim",
  lazy = true,
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "leafo/etlua",
    "michaelb/sniprun",
  },
  opts = {},
},
```

## Dependencies

- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) is required for pickers. Technically you can use the other features of bujo.nvim without it, but you're missing out on a big part of what makes it useful
- [leafo/etlua](https://github.com/leafo/etlua) is required if you want to use templates
- [michaelb/sniprun](https://github.com/michaelb/sniprun) is required if you want to be able to execute code blocks in your markdown files
- LuaJIT is required to use the forward/back functions. It's very likely that you are already are using LuaJIT, but if you're not sure you can learn more about that in the [Neovim docs](https://neovim.io/doc/user/lua.html#lua-luajit)

## Usage

bujo.nvim distinguishes between two types of documents. A "spread" is tied to a specific date range (weekly by default, but see [Configuration](#configuration) for more options), where a "note" is typically tied to a specific topic ("weekly status meeting updates" or "blog ideas"), but you can use them however you would like.

Here are some of the common functions:

- Open the current week's spread with `<leader>nn` ('n' for now)
- Open last week's spread with `<leader>nb` ('b' for back)
- Open next week's spread with `<leader>nf` ('f' for forward)
  - If the current buffer is a spread, you can use forward/back to continue navigating further forward/backward through time
- Create a new note with `<leader>nN` ('N' for note), and enter a name when prompted
- Search for and open a specific document with `<leader>fn` ('fn' for find note)

bujo.nvim also provides some conveniences for linking documents together. Note these keybinds are only mapped in markdown documents:

- Insert a link to another document with `<M-i>` while in insert mode. This will open a picker that inserts a link when you select a document
- Follow a document link with `gf`. If there's only a single link on the current line, your cursor doesn't even have to be inside it
- Use `<C-Space>` to toggle the checkbox on the current line between unchecked `[ ]` and checked `[x]`

Additionally, bujo.nvim integrates with [michaelb/sniprun](https://github.com/michaelb/sniprun), allowing you to use `<leader>nr` ('r' for run) to send the entire code block under your cursor to sniprun for evaluation. bujo.nvim doesn't supply any special configuration to sniprun, so you'll want to refer to [sniprun's thorough documentation](https://michaelb.github.io/sniprun/) if you need to tweak anything for the languages you use.

### Templates

`.etlua` files can be placed in the templates_dir (`<base_directory>/.templates` by default). For spreads, use the `template` config field to specify the filename of a template, and that template will be applied any time a new spread is created (using now, forward, backward, etc).

`<leader>nt` ('t' for template) creates a note just like the new note command but it allows you to specify a template from your templates directory to execute on the created document.

See the [etlua README](https://github.com/leafo/etlua/blob/master/README.md) for information about how to format templates. The evaluation context for templates includes access to the plugin configuration as `bujo_config`, access to the first date of the current span as `span_start_date` (this only applies to spreads), and any global you normally have access to in Lua.

### Git integration

bujo.nvim can automatically commit and push changes for you if you would like. This is disabled by default, but when enabled it will commit and push any time a bujo document is saved (optionally after a short debounce delay, which defaults to 1 second to support `:wa`). Note that it will commit and push _all_ changes to your bujo repo, not just the current file.

To enable, alter the `git` section of the config:
```lua
git = {
  auto_commit = false,
  auto_push = false,
  debounce_ms = 1000,
},
```

## Configuration

No configuration is necessary for bujo.nvim to work out of the box. By default, it will create weekly spreads in the `~/.bujo` directory. Please refer to the documentation in [config.lua](/lua/bujo/config.lua) for more information about each config and how it can be used. If you would like to disable any of the default keybinds, simply set their value to `false`.

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "timhugh/bujo.nvim",
  ......
  opts = {
    base_directory = "~/my_bujo",
    markdown = {
      follow_external_link_keybind = false,
    },
  },
},
```

Or manually:

```lua
require("bujo").setup({
  base_directory = "~/my_bujo",
  markdown = {
    follow_external_link_keybind = false,
  },
})
```

### Custom spreads

By default, bujo.nvim creates weekly spreads, but it supports anything you can dream up using date specifiers.

- `"%Y/%m-%B"`: "2025/07-July.md"
- `"%Y/%m/%d-%a"`: "2025/07/18-Fri.md"

You can configure as many spans as you like with separate templates and bindings:

```lua
opts = {
  spreads = {
    weekly = false, -- disable the default weekly spreads
    daily = {
      filename_template = "journal/%Y/%m-%d",
      template = "daily_spread",
      now_keybind = "<leader>nt",
      next_keybind = "<leader>nf",
      previous_keybind = "<leader>nb",
    },
    monthly = {
      filename_template = "journal/%Y/%m",
      template = "monthly_spread",
      now_keybind = "<leader>nm",
      next_keybind = false,
      previous_keybind = false,
    },
  },
}
```

## Compatibility

bujo.nvim is by no means thoroughly tested with other plugins, but care has been taken to follow best practices for not breaking other stuff. Keybinds are only mapped globally when it makes sense and are otherwise confined only to markdown buffers, and those keybinds typically allow fallthrough so they won't block other plugins' behavior if they aren't relevant. If there are any conflicts, all keybinds are configurable (see [Configuration](#configuration)).

If you find an compatibility issue with another plugin, feel free to open an issue or PR! See [Contributing](#contributing) for more details.

bujo.nvim has explicit dependencies on a few plugins that I suspect could be swapped for other popular options, but I built it with the plugins I use in mind so there are no adapters as of yet. If that interests you, see [Contributing](#contributing) for ways to make that happen! As an example, bujo.nvim explicitly depends on [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for pickers. I know there are other popular options like [echasnovski/mini.pick](https://github.com/echasnovski/mini.pick) and [https://github.com/folke/snacks.nvim](https://github.com/folke/snacks.nvim), I just don't use them so they aren't supported yet.

bujo.nvim does not provide any markdown rendering or formatting capability. I've used it alongside [MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) without issue, but I wouldn't expect it to interfere with any rendering/formatting plugins.

## Contributing

Feel free to submit issues or PRs! I tried to make bujo.nvim configurable and modular, but I built it with my personal use case in mind and with very little Lua and plugin development experience, so I'm happy to take suggestions and improvements.

Some notes on process/design ideals:
- There isn't a versioning/release strategy yet. I'm avoiding breaking changes, but no guarantees for the time being
- New features should be tested (see [Testing](#testing) below)
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

For manual testing, some example minimal configs are provided in the `/examples` directory:

```sh
nvim -u examples/lazy-basic.lua
```

