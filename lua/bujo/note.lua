local fs = require("bujo.fs_util")

local M = {}

function M.note(config)
  local notes_dir = vim.fn.join({ config.journal_dir, config.notes_dir }, "/")
  fs.ensure(notes_dir)

  vim.ui.input({ prompt = "New note name: " }, function(input)
    if input and input ~= "" then
      local filename = input:gsub("[^%w-]", "_") .. ".md"
      local file_path = vim.fn.join({ notes_dir, filename }, "/")
      vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    end
  end)
end

return M
