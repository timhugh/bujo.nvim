local M = {}

local fs = require("bujo.fs_util")
local config = require("bujo.config")

function M.note()
  local opts = config.options

  local notes_dir = vim.fn.join({ opts.journal_dir, opts.notes_dir }, "/")
  fs.ensure(notes_dir)
  vim.ui.input({ prompt = "New note name: " }, function(input)
    if input and input ~= "" then
      local filename = input:gsub("[^%w-]", "_") .. ".md"
      local file_path = vim.fn.join({ notes_dir, filename }, "/")
      vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    end
  end)
end

function M.install()
  local keybind = config.options.note_keybind
  if keybind then
    vim.keymap.set("n", keybind, function()
      M.note()
    end, { desc = "Bujo: Create a new note" })
  end
end

return M
