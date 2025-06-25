local fs = require("bujo.fs_util")

local M = {}

function M.now(config)
  local entries_dir = vim.fn.join({ config.journal_dir, config.entries_dir }, "/")
  fs.ensure(entries_dir)

  local current_file = os.date(config.entries_name_template)
  local current_file_path = vim.fn.join({ entries_dir, current_file }, "/")

  local current_file_dir = vim.fn.fnamemodify(current_file_path, ":h")
  fs.ensure(current_file_dir)

  if vim.fn.filereadable(current_file_path) == 0 then
    local file = io.open(current_file_path, "w")
    if file then
      -- TODO: we're going to do real templates at some point, this is just proof of concept
      file:write("# Week " .. os.date("%V") .. " of " .. os.date("%Y") .. "\n\n")
      file:close()
    else
      vim.notify("Failed to create entry file: " .. current_file_path, vim.log.levels.ERROR)
      return
    end
  end

  vim.cmd("edit " .. vim.fn.fnameescape(current_file_path))
end

return M
