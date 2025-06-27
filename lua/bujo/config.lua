BujoConfig = {}

local defaults = {
  -- the root directory where you want to keep your markdown files
  journal_dir = vim.fn.expand("~/.journal"),
  -- subdirectory where etlua templates can be found
  templates_dir = ".templates",

  -- subdirectory in journal_dir where actual journal entries will be stored
  entries_dir = "entries",
  -- a lua date template for journal entry files. subdirectories are supported e.g.:
  --   "%Y/%m-%V" will create a file for each week like ~/.journal/entries/2025/06-26.md
  --   "%Y/%m/%d" will create a file for each day like ~/.journal/entries/2025/06/25.md
  --   "%Y-%m-%d" will create a file for each day like ~/.journal/entries/2025-06-25.md
  entries_name_template = "%Y/%m-%V",
  -- specify an etlua template file in the templates_dir to execute when creating a new entry
  -- if set to false, no template will be used and an empty file will be created
  entries_template = false,
  -- subdirectory in journal_dir where notes will be stored
  notes_dir = "notes",

  -- if you keep your journal_dir git-versioned, you can use these options to automatically
  -- commit and push changes when buffers inside the journal_dir are saved
  auto_commit_journal = false,
  auto_push_journal = false,

  -- #### KEYBINDS ####
  -- all keybinds can be set to false to disable them
  --
  -- keybind for creating or opening a journal entry for the current date span
  now_keybind = "<leader>nn",
  -- keybind for creating a new note (will prompt for a name)
  note_keybind = "<leader>nN",
  -- keybind for opening the journal entry finder
  telescope_picker_keybind = "<leader>nf",
  -- keybind for inserting markdown links from telescope picker
  telescope_insert_link_keybind = "<M-i>",
  -- keybind for following journal markdown links. this speficially allows you to use relative links
  -- like `notes/my_note.md` to refer to a note at `~/.journal/notes/my_note.md` and still follow it
  --   if there is only one link on the line, it will be followed
  --   if there are multiple links, the link under the cursor will be followed
  follow_journal_link_keybind = "<M-CR>",
  -- keybind for opening a link with the default system handler. This is identical to the default "gx"
  -- behavior of vim, but it applies the same logic as the follow_journal_link_keybind to find links in the current line
  -- so that you don't have to place your cursor directly on the link if there is only one link on the line
  exec_link_keybind = "gx",
  -- keybind for toggling checkboxes in journal files
  toggle_check_keybind = "<C-Space>",
}

BujoConfig.options = vim.deepcopy(BujoConfig.options)

function BujoConfig.setup(options)
  BujoConfig.options = vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))
  return BujoConfig.options
end

return BujoConfig
