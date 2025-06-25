local M = {}

local config = {
  file_extension = ".md",
  journal_dir = vim.fn.expand("~/.journal"),
  entries_dir = "entries",
  entries_name_template = "%Y/%m-%V.md", -- e.g., 2023/10-42.md for week 42 of 2023 in October
  notes_dir = "notes",
  projects_dir = "projects",
}

local function ensure_journal_dir(subdir)
  local dir = config.journal_dir
  if subdir then
    dir = vim.fn.join({config.journal_dir, subdir}, "/")
  end
  if not vim.fn.isdirectory(dir) then
    vim.fn.mkdir(dir, "p")
  end
end

function M.setup(user_config)
  if user_config then
    config = vim.tbl_deep_extend("force", config, user_config)
  end
end

-- :Bujo now -- open the current week's entry
function M.bujo_now()
  ensure_journal_dir(config.entries_dir)
  local current_file = os.date(config.entries_name_template)
  local file_path = vim.fn.join({config.journal_dir, config.entries_dir, current_file}, "/") .. config.file_extension
  vim.cmd("edit " .. vim.fn.fnameescape(file_path))
end

function M.register_commands()
  vim.api.nvim_create_user_command("Bujo", function(opts)
    local arg = opts.args or ""
    if arg == "now" then
      M.bujo_now()
    else
      vim.notify("Unknown :Bujo command: " .. opts.args, vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    complete = function()
      return { "now" }
    end,
  })
end

M.register_commands()

return M

