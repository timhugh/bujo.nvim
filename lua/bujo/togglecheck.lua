local M = {}

local config = require("bujo.config")

function M.togglecheck()
  local line = vim.api.nvim_get_current_line()
  local state = line:match("^%s*-%s%[(.*)%]")

  if not state then
    vim.notify("No checkbox found on this line", vim.log.levels.WARN)
    return
  end

  local new_state
  if state == " " then
    new_state = "x"
  elseif state == "x" then
    new_state = " "
  end

  local new_line = line:gsub("%[.*%]", string.format("[%s]", new_state), 1)
  vim.api.nvim_set_current_line(new_line)
end

function M.install()
  local keybind = config.options.toggle_check_keybind
  if keybind then
    vim.keymap.set("n", keybind, function()
      M.togglecheck()
    end, {
      noremap = true,
      silent = true,
      desc = "Bujo: Toggle checkbox state",
    })
  end
end

return M
