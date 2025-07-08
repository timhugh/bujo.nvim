local M = {}

local fs = require("bujo.util.fs")
local config = require("bujo.config")
local templates = require("bujo.templates")
local date = require("bujo.util.date")

local parse_date_from_template = function(date_string, template)
  local parsed_date = date.parse(date_string, template)
  if not parsed_date then
    return nil
  end
  return os.time(parsed_date)
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
    current_time = parse_date_from_template(current_file, config.options.journal.filename_template)
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
  if not start_time or not start_file then
    vim.notify("Failed to determine starting journal entry", vim.log.levels.ERROR)
    return
  end

  local retries = 0
  local next_file = start_file
  local ts = start_time
  while next_file == start_file do
    if retries >= config.options.journal.iteration_max_steps then
      vim.notify("Failed to find next journal entry after " .. config.options.journal.iteration_max_steps .. " attempts", vim.log.levels.WARN)
      return
    end
    ts = ts + config.options.journal.iteration_step_seconds
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
  if not start_time or not start_file then
    vim.notify("Failed to determine starting journal entry", vim.log.levels.ERROR)
    return
  end

  local retries = 0
  local prev_file = start_file
  local ts = start_time
  while prev_file == start_file do
    if retries >= config.options.journal.iteration_max_steps then
      vim.notify("Failed to find previous journal entry after " .. config.options.journal.iteration_max_steps .. " attempts", vim.log.levels.WARN)
      return
    end
    ts = ts - config.options.journal.iteration_step_seconds
    prev_file = os.date(config.options.journal.filename_template, ts)
    retries = retries + 1
  end

  local prev_file_path = vim.fn.join({ journal_dir, prev_file }, "/") .. ".md"
  open_or_create_journal_entry(prev_file_path)
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
  keybind.map_if_defined("n", config.options.notes.note_keybind, M.note, {
    desc = "Bujo: Create a new note",
  })
end

return M
