local config = require("bujo.config")
local M = {}
local function get_markdown_links(line)
  local links = {}
  for start, text, path, finish in line:gmatch('()(%[.-%]%((.-)%)())') do
    table.insert(links, {
      start = start,
      finish = finish,
      text = text,
      path = path
    })
  end
  return links
end

local function get_link_path()
  local line = vim.api.nvim_get_current_line()
  local links = get_markdown_links(line)

    local link_path = nil

    if #links == 1 then
      link_path = links[1].path
    elseif #links > 1 then
      local _, col = unpack(vim.api.nvim_win_get_cursor(0))
      local cursor_pos = col + 1
      for _, link in ipairs(links) do
        if cursor_pos >= link.start and cursor_pos <= link.finish then
          link_path = link.path
          break
        end
      end
    end

  return link_path
end

function M.follow()
  local journal_dir = config.options.journal_dir
  local link_path = get_link_path()

  if link_path then
    local full_path = vim.fn.join({ journal_dir, link_path }, "/")
    vim.cmd("edit " .. vim.fn.fnameescape(full_path))
    return ""
  else
    -- fall through to the next handler for the keybind
    --   this allows overriding standard keybinds like `gf` or `<CR>` without affecting their normal behavior
    return config.options.follow_link_keybind
  end
end

function M.install()
  local keybind = config.options.follow_link_keybind
  if keybind then
    vim.keymap.set("n", keybind, function()
      return M.follow()
    end, {
      -- expr = true allows follow to return the keybind if a link isn't found and execute the next handler
      expr = true,
      noremap = true,
      silent = true,
      desc = "Bujo: Follow markdown link"
    })
  end
end

return M
