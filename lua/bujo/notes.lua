local M = {}

local fs = require("bujo.fs_util")
local config = require("bujo.config")
local templates = require("bujo.templates")

local function open_or_create_file(file_path)
  if vim.fn.filereadable(file_path) == 0 then
    local file = io.open(file_path, "w")
    if file then
      if config.options.journal.template and config.options.journal.template ~= false then
        templates.execute(config.options.journal.template, file_path)
      end
    else
      vim.notify("Failed to create journal file: " .. file_path, vim.log.levels.ERROR)
      return
    end
  end
  vim.schedule(function()
    vim.cmd("edit " .. vim.fn.fnameescape(file_path))
  end)
end

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

  open_or_create_file(current_file_path)
end

local function get_file_from_current_buffer_or_current_date()
  local journal_dir = vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/")

  local current_file = nil
  local currently_open_file = vim.api.nvim_buf_get_name(0)
  if fs.is_journal_file(currently_open_file) then
    -- if currently open file is a journal file, start iterating from there
    -- get full file path and remove the extension and journal_dir from it, but keep subdirectories inside journal_dir
    -- e.g. journal_dir/subdir/file.md -> subdir/file
    local relative_path = currently_open_file:sub(#journal_dir +1)
    if relative_path:sub(1, 1) == "/" then
      relative_path = relative_path:sub(2) -- remove leading slash if present
    end
    current_file = relative_path:gsub("%.md$", "") -- remove the .md extension
  else
    -- otherwise, use the current date as the starting point
    current_file = os.date(config.options.journal.filename_template)
  end
  return current_file
end

function M.next()
  local journal_dir = vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/")
  fs.ensure(journal_dir)

  local current_file = get_file_from_current_buffer_or_current_date()

  -- TODO: this loop just iterates day by day until it finds a different file name
  --   it should be fine as a basic implementation, but for a large span like a year
  --   it might be better to inspect the template and try to do something more intelligent
  -- in the meantime we'll add a retry limit to avoid infinite loops
  local retries = 0
  local next_file = current_file
  local ts = os.time()
  while next_file == current_file do
    if retries >= 90 then
      vim.notify("Failed to find next journal entry after 20 attempts", vim.log.levels.WARN)
      return
    end
    ts = ts + 24 * 60 * 60 -- add one day
    next_file = os.date(config.options.journal.filename_template, ts)
    retries = retries + 1
  end

  local next_file_path = vim.fn.join({ journal_dir, next_file }, "/") .. ".md"
  open_or_create_file(next_file_path)
end

function M.previous()
  local journal_dir = vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/")
  fs.ensure(journal_dir)

  local current_file = get_file_from_current_buffer_or_current_date()

  -- TODO: this loop just iterates day by day until it finds a different file name
  --   it should be fine as a basic implementation, but for a large span like a year
  --   it might be better to inspect the template and try to do something more intelligent
  -- in the meantime we'll add a retry limit to avoid infinite loops
  local retries = 0
  local next_file = current_file
  local ts = os.time()
  while next_file == current_file do
    if retries >= 90 then
      vim.notify("Failed to find next journal entry after 20 attempts", vim.log.levels.WARN)
      return
    end
    ts = ts - 24 * 60 * 60 -- subtract one day
    next_file = os.date(config.options.journal.filename_template, ts)
    retries = retries + 1
  end

  local next_file_path = vim.fn.join({ journal_dir, next_file }, "/") .. ".md"
  open_or_create_file(next_file_path)
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

  local next_keybind = config.options.journal.next_keybind
  if next_keybind then
    vim.keymap.set("n", next_keybind, function()
      M.next()
    end, {
      noremap = true,
      silent = true,
      desc = "Bujo: Open next journal entry",
    })
  end

  local previous_keybind = config.options.journal.previous_keybind
  if previous_keybind then
    vim.keymap.set("n", previous_keybind, function()
      M.previous()
    end, {
      noremap = true,
      silent = true,
      desc = "Bujo: Open previous journal entry",
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
