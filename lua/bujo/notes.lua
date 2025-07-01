local M = {}

local fs = require("bujo.util.fs")
local config = require("bujo.config")
local templates = require("bujo.templates")
-- local date = require("date")

local parse_date_from_template = function(template, date_string)
  -- local date = date(template, date_string)
  -- return date:spanseconds(date(1970, 1, 1))
  return nil
end

local function open_or_create_journal_entry(file_path)
  file_path = vim.fn.expand(file_path)

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
  fs.ensure_directory(notes_dir)

  vim.ui.input({ prompt = "New note name: " }, function(input)
    if input and input ~= "" then
      local filename = input:gsub("[^%w-]", "_") .. ".md"
      local file_path = vim.fn.expand(vim.fn.join({ notes_dir, filename }, "/"))
      vim.cmd("edit " .. vim.fn.fnameescape(file_path))
    end
  end)
end

function M.now()
  local journal_dir = vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/")
  fs.ensure_directory(journal_dir)

  local current_date_filename = os.date(config.options.journal.filename_template)

  local current_file = os.date(config.options.journal.filename_template)
  local current_file_path = vim.fn.join({ journal_dir, current_file }, "/") .. ".md"

  local current_file_dir = vim.fn.fnamemodify(current_file_path, ":h")
  fs.ensure_directory(current_file_dir)

  open_or_create_journal_entry(current_file_path)
end

local function is_journal_file(file_path)
  local journal_dir = vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/")
  return file_path:match("%.md$") and fs.file_is_in_directory(file_path, journal_dir)
end

local function get_file_from_current_buffer_or_current_date()
  local journal_dir = vim.fn.expand(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/"))

  local current_file = nil
  local current_time = nil
  local currently_open_file = vim.api.nvim_buf_get_name(0)
  if is_journal_file(currently_open_file) then
    -- if currently open file is a journal file, start iterating from there
    -- get full file path and remove the extension and journal_dir from it, but keep subdirectories inside journal_dir
    -- e.g. journal_dir/subdir/file.md -> subdir/file
    local absolute_path = vim.fn.expand(currently_open_file)
    local relative_path = absolute_path:sub(#journal_dir +1)
    if relative_path:sub(1, 1) == "/" then
      relative_path = relative_path:sub(2) -- remove leading slash if present
    end
    current_file = relative_path:gsub("%.md$", "") -- remove the .md extension
    current_time = parse_date_from_template(config.options.journal.filename_template, current_file)
  else
    -- otherwise, use the current date as the starting point
    current_time = os.time()
    current_file = os.date(config.options.journal.filename_template, current_time)
  end
  return current_time, current_file
end

function M.next()
  local journal_dir = vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/")
  fs.ensure_directory(journal_dir)

  local start_time, start_file = get_file_from_current_buffer_or_current_date()

  -- TODO: this loop just iterates day by day until it finds a different file name
  --   it should be fine as a basic implementation, but for a large span like a year
  --   it might be better to inspect the template and try to do something more intelligent
  -- in the meantime we'll add a retry limit to avoid infinite loops
  local retries = 0
  local next_file = start_file
  local ts = start_time
  while next_file == start_file do
    if retries >= 30 then
      vim.notify("Failed to find next journal entry after 30 attempts", vim.log.levels.WARN)
      return
    end
    ts = ts + 24 * 60 * 60 -- add one day
    next_file = os.date(config.options.journal.filename_template, ts)
    retries = retries + 1
  end

  local next_file_path = vim.fn.join({ journal_dir, next_file }, "/") .. ".md"
  open_or_create_journal_entry(next_file_path)
end

function M.previous()
  local journal_dir = vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/")
  fs.ensure_directory(journal_dir)

  local start_time, start_file = get_file_from_current_buffer_or_current_date()

  -- TODO: this loop just iterates day by day until it finds a different file name
  --   it should be fine as a basic implementation, but for a large span like a year
  --   it might be better to inspect the template and try to do something more intelligent
  -- in the meantime we'll add a retry limit to avoid infinite loops
  local retries = 0
  local next_file = start_file
  local ts = start_time
  while next_file == start_file do
    if retries >= 30 then
      vim.notify("Failed to find next journal entry after 30 attempts", vim.log.levels.WARN)
      return
    end
    ts = ts - 24 * 60 * 60 -- subtract one day
    next_file = os.date(config.options.journal.filename_template, ts)
    retries = retries + 1
  end

  local next_file_path = vim.fn.join({ journal_dir, next_file }, "/") .. ".md"
  open_or_create_journal_entry(next_file_path)
end

function M.install()
  local keybind = require("bujo.util.keybind")
  keybind.map_if_defined("n", config.options.journal.now_keybind, M.now, {
    desc = "Bujo: Create or open current journal entry",
  })
  keybind.map_if_defined("n", config.options.journal.next_keybind, M.next, {
    desc = "Bujo: Open next journal entry",
  })
  keybind.map_if_defined("n", config.options.journal.previous_keybind, M.previous, {
    desc = "Bujo: Open previous journal entry",
  })
  keybind.map_if_defined("n", config.options.journal.note_keybind, M.note, {
    desc = "Bujo: Create a new note",
  })
end

return M
