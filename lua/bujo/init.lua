local M = {}

local config = require("bujo.config")
local bujo_notes = require("bujo.notes")
local bujo_find = require("bujo.find")
local bujo_follow = require("bujo.follow")
local bujo_toggle_check = require("bujo.toggle_check")
local bujo_git = require("bujo.git")
local bujo_templates = require("bujo.templates")

local commands = {
  ["now"] = bujo_notes.now,
  ["note"] = bujo_notes.note,
  ["find"] = bujo_find.find,
  ["follow"] = bujo_follow.follow_journal_link,
  ["exec"] = bujo_follow.exec_link,
  ["toggle_check"] = bujo_toggle_check.toggle_check,
}

function M.setup(user_config)
  config.setup(user_config)

  bujo_notes.install()
  bujo_find.install()
  bujo_follow.install()
  bujo_toggle_check.install()
  bujo_git.install()
  bujo_templates.install()
end

local function register_commands()
  vim.api.nvim_create_user_command("Bujo", function(opts)
    local arg = opts.args or "now"
    if not commands[arg] then
      vim.notify("Unknown :Bujo command: " .. arg, vim.log.levels.ERROR)
      return
    end
    commands[arg]()
  end, {
    nargs = "?",
    complete = function()
      return vim.tbl_keys(commands)
    end,
  })
end

register_commands()

return M

