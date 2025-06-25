local default_config = {
  -- the root directory where you want to keep your markdown files
  journal_dir = vim.fn.expand("~/.journal"),

  -- subdirectory where templates can be found
  templates_dir = ".templates",

  -- subdirectory in journal_dir where actual journal entries will be stored
  entries_dir = "entries",
  -- a lua date template for journal entry files. subdirectories are supported e.g.:
  --   "%Y/%m-%V" will create a file for each week like ~/.journal/entries/2025/06-26.md
  --   "%Y/%m/%d" will create a file for each day like ~/.journal/entries/2025/06/25.md
  --   "%Y-%m-%d" will create a file for each day like ~/.journal/entries/2025-06-25.md
  entries_name_template = "%Y/%m-%V",

  -- subdirectory in journal_dir where notes will be stored
  notes_dir = "notes",
}

local M = vim.tbl_deep_extend("force", {}, default_config)

function M.setup(user_config)
  -- TODO: we should validate the config to make sure e.g. directories are writable and safe
  if user_config then
    vim.tbl_deep_extend("force", M, user_config)
  end
end

return M
