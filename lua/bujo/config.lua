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

  -- keybind for inserting markdown links from telescope picker
  telescope_insert_link_keybind = "<M-i>",
}

BujoConfig.options = vim.deepcopy(BujoConfig.options)

function BujoConfig.setup(options)
  BujoConfig.options = vim.deepcopy(vim.tbl_deep_extend("keep", options or {}, defaults or {}))
  return BujoConfig.options
end

return BujoConfig
