BujoConfigSingleton = {}

---@class JournalConfig
---@field subdirectory string
---@field filename_template string
---@field template? string|false
---@field now_keybind? string|false
---@field next_keybind? string|false
---@field previous_keybind? string|false
---@field note_keybind? string|false

---@class NotesConfig
---@field subdirectory string

---@class PickerConfig
---@field open_keybind? string|false
---@field insert_link_keybind? string|false

---@class MarkdownConfig
---@field follow_journal_link_keybind? string|false
---@field follow_external_link_keybind? string|false
---@field toggle_check_keybind? string|false
---@field execute_code_block_keybind? string|false

---@class GitConfig
---@field auto_commit boolean
---@field auto_push boolean
---@field debounce_ms number

---@class BujoConfig
---@field base_directory string
---@field templates_dir? string
---@field journal JournalConfig
---@field notes NotesConfig
---@field picker PickerConfig
---@field markdown MarkdownConfig
---@field git GitConfig

---@type BujoConfig
local defaults = {
  -- the root directory where you want to keep your markdown files
  base_directory = vim.fn.expand("~/.bujo"),
  -- subdirectory inside base_directory where etlua templates can be found
  templates_dir = ".templates",

  journal = {
    -- subdirectory inside base_directory where journal entries will be stored
    subdirectory = "entries",
    -- a lua date template for journal entry files. subdirectories are supported e.g.:
    --   "%Y/W%V" will create a file for each week like ~/.journal/entries/2025/W26.md
    --   "%Y/%m/%d" will create a file for each day like ~/.journal/entries/2025/06/25.md
    --   "%Y-%m-%d" will create a file for each day like ~/.journal/entries/2025-06-25.md
    filename_template = "%Y/W%V",
    -- specify an etlua template file in the templates directory to execute when creating a new entry
    --   if set to false, no template will be used and an empty file will be created
    template = false,
    -- keybind for creating or opening a journal entry for the current date span. set to false to disable
    now_keybind = "<leader>nn",
    -- keybinds for creating or opening a journal entry for the next/previous date span. set to false to disable
    --   - "next" and "previous" are sort of ambiguous since the date span is defined by the filename_template above
    --     but essentially we will iterate forward or backward through time until the template evaluates to something
    --     that isn't the current date span.
    --   - these keybinds will open the previous or next entry to the current date, or the the next or previous entry
    --     to the current buffer, if the current buffer is a journal entry.
    next_keybind = "<leader>nf",
    previous_keybind = "<leader>nb",
    -- keybind for creating a new note (will prompt for a name). set to false to disable
    note_keybind = "<leader>nN",
  },

  notes = {
    -- subdirectory inside base_directory where notes will be stored
    subdirectory = "notes",
  },

  picker = {
    -- keybind for opening the file picker. set to false to disable
    open_keybind = "<leader>fn",
    -- keybind for inserting markdown links from file picker. set to false to disable
    insert_link_keybind = "<M-i>",
  },

  markdown = {
    -- keybind for following journal markdown links. this speficially allows you to use relative links
    -- like `notes/my_note.md` to refer to a note at `~/.journal/notes/my_note.md` and still follow it
    --   if there is only one link on the line, it will be followed
    --   if there are multiple links, the link under the cursor will be followed
    -- set to false to disable
    follow_journal_link_keybind = "<M-CR>",
    -- keybind for opening a link with the default system handler. This is identical to the default "gx"
    -- behavior of vim, but it also will open a link in the current line if there is only one link on the
    -- line, or the link under the cursor if there are multiple links.
    -- set to false to disable
    follow_external_link_keybind = "gx",
    -- keybind for toggling checkboxes in journal files. set to false to disable
    toggle_check_keybind = "<C-Space>",
    -- keybind for executing code blocks in journal files. set to false to disable
    --   this functionality relies on michaleb/sniprun
    execute_code_block_keybind = "<leader>nr",
  },

  git = {
    -- if you keep your base_directory git-versioned, you can use these options to automatically
    -- commit and push changes when buffers inside the base_directory are saved
    auto_commit = false,
    auto_push = false,
    -- the debounce in milliseconds after a buffer save to queue writes before committing
    --   this is mostly to avoid committing multiple times in a row when writing multiple files like ":wa"
    debounce_ms = 1000,
  },
}

---@type BujoConfig
BujoConfigSingleton.options = vim.deepcopy(defaults)

---@param options BujoConfig|nil
---@return BujoConfig
function BujoConfigSingleton.setup(options)
  BujoConfigSingleton.options = vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))
  return BujoConfigSingleton.options
end

return BujoConfigSingleton
