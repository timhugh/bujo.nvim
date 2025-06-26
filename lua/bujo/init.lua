local M = {}
local config = require("bujo.config")

local commands = {
  ["now"] = require("bujo.now").now,
  ["note"] = require("bujo.note").note,
  ["find"] = require("bujo.find").find,
  ["follow"] = require("bujo.follow").follow,
  ["togglecheck"] = require("bujo.togglecheck").togglecheck,
}

function M.setup(user_config)
  config.setup(user_config)

  for name, _ in pairs(commands) do
    require("bujo." .. name).install()
  end
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

