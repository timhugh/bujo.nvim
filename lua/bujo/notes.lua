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

function M.now()
  local opts = config.options

  local entries_dir = vim.fn.join({ opts.journal_dir, opts.entries_dir }, "/")
  fs.ensure(entries_dir)

  local current_file = os.date(opts.entries_name_template)
  local current_file_path = vim.fn.join({ entries_dir, current_file }, "/") .. ".md"

  local current_file_dir = vim.fn.fnamemodify(current_file_path, ":h")
  fs.ensure(current_file_dir)

  if vim.fn.filereadable(current_file_path) == 0 then
    local file = io.open(current_file_path, "w")
    if file then
      if opts.entries_template and opts.entries_template ~= false then
        require('bujo.templates').execute(opts.entries_template, current_file_path)
      end
    else
      vim.notify("Failed to create entry file: " .. current_file_path, vim.log.levels.ERROR)
      return
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(current_file_path))
end

function M.install()
  local now_keybind = config.options.now_keybind
  if now_keybind then
    vim.keymap.set("n", now_keybind, function()
      M.now()
    end, {
      noremap = true,
      silent = true,
      desc = "Bujo: Create or open current journal entry",
    })
  end

  local note_keybind = config.options.note_keybind
  if note_keybind then
    vim.keymap.set("n", note_keybind, function()
      M.note()
    end, { desc = "Bujo: Create a new note" })
  end
end

return M
