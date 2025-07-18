BujoConfigSingleton = {}

---@class SpreadConfig
---@field filename_template string
---@field template? string|false
---@field now_keybind? string|false
---@field next_keybind? string|false
---@field previous_keybind? string|false
---@field iteration_step_seconds? number
---@field iteration_max_steps? number

---@class NotesConfig
---@field subdirectory string
---@field note_keybind? string|false

---@class PickerConfig
---@field open_keybind? string|false
---@field insert_link_keybind? string|false

---@class MarkdownConfig
---@field follow_bujo_link_keybind? string|false
---@field follow_external_link_keybind? string|false
---@field toggle_check_keybind? string|false
---@field execute_code_block_keybind? string|false

---@class GitConfig
---@field auto_commit boolean
---@field auto_push boolean
---@field notify boolean
---@field debounce_ms number

---@class BujoConfig
---@field base_directory string
---@field templates_dir? string
---@field spreads {[string]: SpreadConfig|false}
---@field notes NotesConfig
---@field picker PickerConfig
---@field markdown MarkdownConfig
---@field git GitConfig

---@type BujoConfig
local defaults = {
  -- the root directory where you want to keep your bujo documents
  base_directory = "~/.bujo",

  -- subdirectory inside base_directory where etlua templates can be found
  templates_dir = ".templates",

  spreads = {
    weekly = {
      -- A Lua/strftime date template for spreads. subdirectories are supported e.g.:
      --   "%Y/W%V" will create a file for each week like ~/.bujo/2025/W26.md
      --   "%Y/%m/%d" will create a file for each day like ~/.bujo/2025/06/25.md
      --   "spreads/%Y-%m-%d" will create a file for each day like ~/.bujo/spreads/2025-06-25.md
      -- Note that your template also determines the date span, and Bujo is fully agnostic to date spans but will instead
      -- identify whether or not a span applies to a given date based on whether or not the template evaluates to the same
      -- string. This means that some care must be taken when defining your template with incompatible date specifiers, e.g
      -- using the %m month and %V week specifiers in the same template will not work as expected when a week starts and ends
      -- in two different months.
      -- Also note that bujo.nvim uses days as the smallest unit of time by default, so using time specifiers like %H or %M,
      -- will cause next/previous to break unless you adjust the iteration_step_seconds and iteration_max_steps accordingly.
      -- For more information on date specifiers, refer to the strftime documentation: https://www.man7.org/linux/man-pages/man3/strftime.3.html
      filename_template = "%Y/W%V",

      -- Specify an etlua template file in the templates directory to execute when creating a new spread. For example, if you
      -- use the default values for base_directory and templates_dir, then to use a template located at ~/.bujo/.templates/daily-template.etlua
      -- you would set this to "daily-template.etlua". If set to false, no template will be used and new spreads will be empty.
      template = false,

      -- keybind for navigating to the spread for the current date. If it doesn't already exist, a file will be created,
      -- and if a template is configured, that template will automatically be executed on the new file. set to false to disable
      now_keybind = "<leader>nn",

      -- keybinds for creating or opening a spread for the next/previous date span. set to false to disable.
      -- If the current buffer is a spread, the next/previous spread relative to that file will be opened. If the current buffer 
      -- is not a spread, then the next/previous spread selected based on the current date.
      -- Note that the next and previous date spans are determined using the filename_template, e.g. if the filename_template's smallest 
      -- unit is one week (%V), then the file for the next or previous week will be opened. Changing the filename_template with pre-existing
      -- spreads will lead to unexpected behavior, so it is recommended to set the filename_template before creating any spreads and to aggregate
      -- and rename existing spreads if you change the template later and still want to be able to navigate between them chronologically.
      next_keybind = "<leader>nf",
      previous_keybind = "<leader>nb",

      -- Configuration for how bujo.nvim will iterate through date spans when navigating to the next or previous spread.
      --
      -- The defaults will support anything from daily to quarterly spreads, but these can be adjusted for more bespoke use cases.
      -- bujo.nvim takes a fairly naive approach to finding previous/next spreads, which is to iterate through timestamps and continually 
      -- evaluate the filename_template. When it finds a date that evaluates to a different filename than the current one, it will stop 
      -- iterating and open that file. If you are using something like a quarterly or yearly template, you may want to increase the
      -- iteration_step_seconds so less iterations are required, or adjust the iteration_limit to allow for more iterations if e.g.
      -- 120 days is not a large enough search span for your filename template.
      --
      -- As noted above, this iteration can behave oddly if the filename_template has mixed specifiers that can potentially evaluate differently
      -- for the same date span, e.g. using both %m and %V in the same template, and can also behave oddly if the filename_template is changed
      -- after spreads have been created.
      iteration_step_seconds = 24 * 60 * 60,
      iteration_max_steps = 120,
    },
  },

  notes = {
    -- subdirectory inside base_directory where notes will be stored
    subdirectory = "notes",

    -- keybind for creating a new note (will prompt for a name). set to false to disable
    note_keybind = "<leader>nN",
  },

  picker = {
    -- keybind for opening the file picker. set to false to disable
    open_keybind = "<leader>fn",

    -- keybind for opening the insert link picker. set to false to disable.
    insert_link_keybind = "<M-i>",
  },

  markdown = {
    -- keybind for following bujo markdown links. this speficially allows you to use relative links
    -- like `notes/my_note.md` to refer to a note at `~/.bujo/notes/my_note.md` and still follow it
    --   if there is only one link on the line, it will be followed
    --   if there are multiple links, the link under the cursor will be followed
    -- set to false to disable
    follow_bujo_link_keybind = "gf",

    -- keybind for opening a link with the default system handler. This is identical to the default "gx"
    -- behavior of vim, but it also will open a link in the current line if there is only one link on the
    -- line, or the link under the cursor if there are multiple links.
    -- set to false to disable
    follow_external_link_keybind = "gx",

    -- keybind for toggling checkboxes in bujo documents. set to false to disable
    toggle_check_keybind = "<C-Space>",

    -- keybind for executing code blocks in bujo documents. set to false to disable
    --   this functionality relies on michaleb/sniprun
    execute_code_block_keybind = "<leader>nr",
  },

  git = {
    -- If you keep your base_directory git-versioned, you can use these options to automatically
    -- commit and push changes when buffers inside the base_directory are saved
    auto_commit = false, -- if true, will commit changes after saving (and after the debounce_ms)
    auto_push = false, -- if true, will also push changes after committing

    -- If notify is set to true, bujo.nvim will use the vim.notify API to tell you when it is committing or pushing changes.
    notify = false,

    -- the debounce in milliseconds after a buffer save to queue writes before committing. This is 
    -- mostly to avoid committing multiple times in a row when writing multiple files like ":wa"
    debounce_ms = 1000,
  },
}

local default_iteration_params = {
  iteration_step_seconds = 24 * 60 * 60, -- 1 day in seconds
  iteration_max_steps = 120, -- iterate up to 120 days to find the next or previous spread
}

---@type BujoConfig
BujoConfigSingleton.defaults = vim.deepcopy(defaults)
---@type BujoConfig
BujoConfigSingleton.options = vim.deepcopy(defaults)

local function apply_spread_defaults()
  for spread_name, spread_config in pairs(BujoConfigSingleton.options.spreads) do
    if spread_config then
      BujoConfigSingleton.options.spreads[spread_name] = vim.tbl_deep_extend("keep", spread_config, default_iteration_params)
    else
      BujoConfigSingleton.options.spreads[spread_name] = nil
    end
  end
end

local function normalize_paths()
  BujoConfigSingleton.options.base_directory = vim.fn.expand(BujoConfigSingleton.options.base_directory)
  BujoConfigSingleton.options.templates_dir = vim.fn.expand(vim.fn.join({BujoConfigSingleton.options.base_directory, BujoConfigSingleton.options.templates_dir}, "/"))
  BujoConfigSingleton.options.notes.subdirectory = vim.fn.expand(vim.fn.join({BujoConfigSingleton.options.base_directory, BujoConfigSingleton.options.notes.subdirectory}, "/"))
end

---@param options BujoConfig|nil
---@return BujoConfig
function BujoConfigSingleton.setup(options)
  BujoConfigSingleton.options = vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))

  apply_spread_defaults()
  normalize_paths()

  return BujoConfigSingleton.options
end

return BujoConfigSingleton
