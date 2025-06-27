BujoConfig = {}

local defaults = {
  -- the root directory where you want to keep your markdown files
  base_directory = vim.fn.expand("~/.journal"),
  -- subdirectory inside base_directory where etlua templates can be found
  templates_dir = ".templates",

  journal = {
    -- subdirectory inside base_directory where journal entries will be stored
    subdirectory = "entries",
    -- a lua date template for journal entry files. subdirectories are supported e.g.:
    --   "%Y/%m-%V" will create a file for each week like ~/.journal/entries/2025/06-26.md
    --   "%Y/%m/%d" will create a file for each day like ~/.journal/entries/2025/06/25.md
    --   "%Y-%m-%d" will create a file for each day like ~/.journal/entries/2025-06-25.md
    filename_template = "%Y/%m-%V",
    -- specify an etlua template file in the templates directory to execute when creating a new entry
    --   if set to false, no template will be used and an empty file will be created
    template = false,
    -- keybind for creating or opening a journal entry for the current date span. set to false to disable
    now_keybind = "<leader>nn",
    -- keybind for creating a new note (will prompt for a name). set to false to disable
    note_keybind = "<leader>nN",
  },

  notes = {
    -- subdirectory inside base_directory where notes will be stored
    subdirectory = "notes",
  },

  picker = {
    -- keybind for opening the file picker. set to false to disable
    open_keybind = "<leader>nf",
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

BujoConfig.options = vim.deepcopy(defaults)

function BujoConfig.setup(options)
  BujoConfig.options = vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))
  return BujoConfig.options
end

return BujoConfig
