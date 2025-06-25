local M = {}

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

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

function M.find(config)
  local journal_root = config.journal_dir
  local files = scan_dir(journal_root)
  if #files == 0 then
    vim.notify("No Markdown files found in journal directory: " .. journal_root, vim.log.levels.WARN)
    return
  end

  pickers.new({}, {
    prompt_title = "Bujo Notes",
    finder = finders.new_table{
      results = files,
      entry_maker = function(entry)
        local relative_path = entry:gsub("^" .. vim.pesc(journal_root) .. "/?", "")
        local filename = vim.fn.fnamemodify(entry, ":t")
        return {
          value = entry,
          display = relative_path,
          ordinal = relative_path,
          filename = filename,
          relpath = relative_path,
        }
      end,
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)

        -- Default action opens the selected file in a new buffer
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            vim.cmd("edit " .. vim.fn.fnameescape(selection.value))
          end
        end)

        -- Insert a markdown link to the selected file in the current buffer
        -- TODO: keymap needs to be added to the config
        map("ni", "<C-l>", function()
          local selection = action_state.get_selected_entry()
          if not selection then return end
          actions.close(prompt_bufnr)
          local link_text = string.format("[%s](%s)", selection.filename or selection.relpath, selection.relpath)
          vim.api.nvim_put({ link_text }, "c", true, true)
        end)

      end,
    },
  }):find()
end

return M
