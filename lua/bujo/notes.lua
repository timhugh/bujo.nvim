local M = {}

local fs = require("bujo.fs_util")
local config = require("bujo.config")

function M.note()
  local notes_dir = vim.fn.join({ config.options.base_directory, config.options.notes.subdirectory }, "/")
  fs.ensure(notes_dir)
  vim.ui.input({ prompt = "New note name: " }, function(input)
    if input and input ~= "" then
      local filename = input:gsub("[^%w-]", "_") .. ".md"
      local file_path = vim.fn.join({ notes_dir, filename }, "/")
      vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    end
  end)
end

function M.now()
  local journal_dir = vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/")
  fs.ensure(journal_dir)

  local current_file = os.date(config.options.journal.filename_template)
  local current_file_path = vim.fn.join({ journal_dir, current_file }, "/") .. ".md"

  local current_file_dir = vim.fn.fnamemodify(current_file_path, ":h")
  fs.ensure(current_file_dir)

  if vim.fn.filereadable(current_file_path) == 0 then
    local file = io.open(current_file_path, "w")
    if file then
      if config.options.journal.template and config.options.journal.template ~= false then
        require('bujo.templates').execute(config.options.journal.template, current_file_path)
      end
    else
      vim.notify("Failed to create journal file: " .. current_file_path, vim.log.levels.ERROR)
      return
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(current_file_path))
end

function M.install()
  local now_keybind = config.options.journal.now_keybind
  if now_keybind then
    vim.keymap.set("n", now_keybind, function()
      M.now()
    end, {
      noremap = true,
      silent = true,
      desc = "Bujo: Create or open current journal entry",
    })
  end

  local note_keybind = config.options.journal.note_keybind
  if note_keybind then
    vim.keymap.set("n", note_keybind, function()
      M.note()
    end, { desc = "Bujo: Create a new note" })
  end
end

return M
