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
  local journal_root = config.options.base_directory
  local files = scan_dir(journal_root)
  if #files == 0 then
    vim.notify("No Markdown files found in journal directory: " .. journal_root, vim.log.levels.WARN)
    return
  end

  pickers.new(opts, {
    prompt_title = opts.prompt_title or "Bujo: Find Journal Entries",
    cwd = journal_root,
    finder = finders.new_table({
      results = files,
      entry_maker = make_entry.gen_from_file({ cwd = journal_root }),
    }),
    sorter = conf.file_sorter(opts),
    previewer = conf.file_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      local function insert_markdown_link(selection)
        if not selection then return end
        actions.close(prompt_bufnr)
        local relative_path = selection.filename:gsub("^" .. vim.pesc(journal_root) .. "/?", "")
        local filename = vim.fn.fnamemodify(selection.filename, ":t")
        local link_text = string.format("[%s](%s)", filename, relative_path)
        vim.api.nvim_put({ link_text }, "c", false, true)
      end
      map("n", config.options.picker.insert_link_keybind, function()
        local selection = action_state.get_selected_entry()
        insert_markdown_link(selection)
      end)
      map("i", config.options.picker.insert_link_keybind, function()
        local selection = action_state.get_selected_entry()
        insert_markdown_link(selection)
      end)

      return true
    end,
  }):find()
end

function M.install()
  require("bujo.util.keybind").map_if_defined(
    "n",
    config.options.picker.open_keybind,
    M.find,
    { desc = "Bujo: Find journal entries" }
  )
end
return M
