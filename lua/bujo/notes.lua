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

local function open_or_create_document(file_path, template_path)
  file_path = vim.fn.expand(file_path)

  if vim.fn.filereadable(file_path) == 0 then
    local file = io.open(file_path, "w")
    if file then
      if template_path and template_path ~= false then
        templates.execute(template_path, file_path)
      end
    else
      vim.notify("Failed to create document: " .. file_path, vim.log.levels.ERROR)
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
  local spreads_dir = vim.fn.join({ config.options.base_directory, config.options.spreads.subdirectory }, "/")
  fs.ensure_directory(spreads_dir)

  local current_file = os.date(config.options.spreads.filename_template)
  local current_file_path = vim.fn.join({ spreads_dir, current_file }, "/") .. ".md"

  local current_file_dir = vim.fn.fnamemodify(current_file_path, ":h")
  fs.ensure_directory(current_file_dir)

  open_or_create_document(current_file_path, config.options.spreads.template)
end

local function is_spread(file_path)
  local spreads_dir = vim.fn.join({ config.options.base_directory, config.options.spreads.subdirectory }, "/")
  return file_path:match("%.md$") and fs.file_is_in_directory(file_path, spreads_dir)
end

local function get_current_spread_name()
  local spreads_dir = vim.fn.expand(vim.fn.join({ config.options.base_directory, config.options.spreads.subdirectory }, "/"))

  local currently_open_file = vim.api.nvim_buf_get_name(0)
  if not is_spread(currently_open_file) then return nil end

  return fs.get_path_relative_to(spreads_dir, currently_open_file):gsub("%.md$", "")
end

local function get_date_from_current_spread(template)
  local current_spread = get_current_spread_name()
  return parse_date_from_template(current_spread, config.options.spreads.filename_template)
end

local function iterate_date_to_next_template(start_time, step_seconds, max_steps, template)
  local retries = 0
  local start_file = os.date(template, start_time)
  local next_file = start_file
  local current_time = start_time
  while next_file == start_file do
    if retries >= max_steps then
      vim.notify("Failed to find next spread after " .. max_steps .. " attempts", vim.log.levels.WARN)
      return
    end
    current_time = current_time + step_seconds
    next_file = os.date(template, current_time)
    retries = retries + 1
  end
  return next_file
end

function M.next()
  local opts = config.options.spreads
  local spreads_dir = vim.fn.join({ config.options.base_directory, opts.subdirectory }, "/")
  fs.ensure_directory(spreads_dir)

  local start_time = get_date_from_current_spread(opts.filename_template) or os.time()

  local next_file = iterate_date_to_next_template(
    start_time,
    opts.iteration_step_seconds,
    opts.iteration_max_steps,
    opts.filename_template)

  local next_file_path = vim.fn.join({ spreads_dir, next_file }, "/") .. ".md"
  open_or_create_document(next_file_path, opts.template)
end

function M.previous()
  local opts = config.options.spreads
  local spreads_dir = vim.fn.join({ config.options.base_directory, config.options.spreads.subdirectory }, "/")
  fs.ensure_directory(spreads_dir)

  local start_time = get_date_from_current_spread(opts.filename_template) or os.time()

  local prev_file = iterate_date_to_next_template(
    start_time,
    -opts.iteration_step_seconds,
    opts.iteration_max_steps,
    opts.filename_template)

  local prev_file_path = vim.fn.join({ spreads_dir, prev_file }, "/") .. ".md"
  open_or_create_document(prev_file_path, config.options.spreads.template)
end

function M.install()
  local keybind = require("bujo.util.keybind")
  keybind.map_if_defined("n", config.options.spreads.now_keybind, M.now, {
    desc = "Bujo: Create or open current spread",
  })
  keybind.map_if_defined("n", config.options.spreads.next_keybind, M.next, {
    desc = "Bujo: Open next spread",
  })
  keybind.map_if_defined("n", config.options.spreads.previous_keybind, M.previous, {
    desc = "Bujo: Open previous spread",
  })
  keybind.map_if_defined("n", config.options.notes.note_keybind, M.note, {
    desc = "Bujo: Create a new note",
  })
end

return M
