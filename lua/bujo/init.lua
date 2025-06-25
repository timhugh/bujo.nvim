local M = {}

local config = {
  journal_dir = vim.fn.expand("~/.journal"),
  entries_dir = "entries",
  entries_name_template = "%Y/%m-%V.md", -- e.g., 2023/10-42.md for week 42 of 2023 in October
  notes_dir = "notes",
  projects_dir = "projects",
  templates_dir = "templates",
}

function M.setup(user_config)
  -- TODO: we should validate the config to make sure e.g. directories are writable and safe
  if user_config then
    config = vim.tbl_deep_extend("force", config, user_config)
  end
end
local commands = {
  ["now"] = require("bujo.now").now,
  ["note"] = require("bujo.note").note,
}

function M.register_commands()
  vim.api.nvim_create_user_command("Bujo", function(opts)
    local arg = opts.args or "now"
    if not commands[arg] then
      vim.notify("Unknown :Bujo command: " .. arg, vim.log.levels.ERROR)
      return
    end
    commands[arg](config)
  end, {
    nargs = "?",
    complete = function()
      return vim.tbl_keys(commands)
    end,
  })
end

M.register_commands()

return M

