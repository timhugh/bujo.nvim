local default_config = {
  journal_dir = vim.fn.expand("~/.journal"),
  entries_dir = "entries",
  entries_name_template = "%Y/%m-%V.md", -- e.g., 2023/10-42.md for week 42 of 2023 in October
  notes_dir = "notes",
  projects_dir = "projects",
  templates_dir = "templates",
}

local M = vim.tbl_deep_extend("force", {}, default_config)

function M.setup(user_config)
  -- TODO: we should validate the config to make sure e.g. directories are writable and safe
  if user_config then
    vim.tbl_deep_extend("force", M, user_config)
  end
end

return M
