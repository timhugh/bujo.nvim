local M = {}

local config = require("bujo.config")
local bujo_notes = require("bujo.notes")
local bujo_find = require("bujo.find")
local bujo_markdown = require("bujo.markdown")
local bujo_git = require("bujo.git")
local bujo_templates = require("bujo.templates")

local commands = {
  ["now"] = bujo_notes.now,
  ["next"] = bujo_notes.next,
  ["previous"] = bujo_notes.previous,
  ["note"] = bujo_notes.note,
  ["find"] = bujo_find.find,
  ["insert_link"] = bujo_find.insert_link,
  ["follow_bujo_link"] = bujo_markdown.follow_bujo_link,
  ["follow_external_link"] = bujo_markdown.follow_external_link,
  ["toggle_check"] = bujo_markdown.toggle_check,
  ["execute_code_block"] = bujo_markdown.execute_code_block,
}

function M.setup(user_config)
  config.setup(user_config)

  bujo_notes.install()
  bujo_find.install()
  bujo_markdown.install()
  bujo_git.install()
  bujo_templates.install()
end

local function register_commands()
  vim.api.nvim_create_user_command("Bujo", function(opts)
    local arg = opts.args or "now"
    if not commands[arg] then
      vim.notify("Bujo: Unknown command: " .. arg, vim.log.levels.ERROR)
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

