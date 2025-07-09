local M = {}

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local make_entry = require("telescope.make_entry")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local config = require("bujo.config")

local function scan_dir(dir)
  local results = {}
  local scan = vim.loop.fs_scandir(dir)
  if not scan then
    return results
  end

  while true do
    local name, type = vim.loop.fs_scandir_next(scan)
    if not name then
      break
    end

    local full_path = vim.fn.join({ dir, name }, "/")
    if type == "file" and name:match("%.md$") then
      table.insert(results, full_path)
    elseif type == "directory" then
      local sub_results = scan_dir(full_path)
      for _, sub_path in ipairs(sub_results) do
        table.insert(results, sub_path)
      end
    end
  end

  return results
end

function M.find(opts)
  opts = opts or {}
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)
  local bujo_root = vim.fn.expand(config.options.base_directory)
  local files = scan_dir(bujo_root)
  if #files == 0 then
    vim.notify("Bujo: No files found in " .. bujo_root, vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = opts.prompt_title or "Bujo: Find document",
    cwd = bujo_root,
    finder = finders.new_table({
      results = files,
      entry_maker = make_entry.gen_from_file({ cwd = bujo_root }),
    }),
    sorter = conf.file_sorter(opts),
    previewer = conf.file_previewer(opts),
  }):find()
end

function M.insert_link()
  opts = opts or {}
  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)
  local bujo_root = vim.fn.expand(config.options.base_directory)
  local files = scan_dir(bujo_root)
  if #files == 0 then
    vim.notify("Bujo: No files found in " .. bujo_root, vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = opts.prompt_title or "Bujo: Insert link to document",
    cwd = bujo_root,
    finder = finders.new_table({
      results = files,
      entry_maker = make_entry.gen_from_file({ cwd = bujo_root }),
    }),
    sorter = conf.file_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry(prompt_bufnr)
        local relative_path = selection.filename:gsub("^" .. vim.pesc(bujo_root) .. "/?", "")
        local filename = vim.fn.fnamemodify(selection.filename, ":t")
        local link_text = string.format("[%s](%s)", filename, relative_path)
        actions.close(prompt_bufnr)
        vim.api.nvim_put({ link_text }, "c", false, true)
      end)
      return true
    end,
  }):find()
end

function M.install()
  local keybind = require("bujo.util.keybind")

  keybind.map_if_defined(
    "n",
    config.options.picker.open_keybind,
    M.find,
    { desc = "Bujo: Find document" }
  )

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
      keybind.map_if_defined(
        "i",
        config.options.picker.insert_link_keybind,
        M.insert_link,
        { desc = "Bujo: Insert link to document" }
      )
    end,
  })
end

return M
