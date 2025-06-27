local M = {}

local config = require("bujo.config")

function M.toggle_check()
  local line = vim.api.nvim_get_current_line()
  local state = line:match("^%s*-%s%[(.)%]")

  if not state then
    vim.notify("No checkbox found on this line", vim.log.levels.WARN)
    return
  end

  local new_state = "x"
  if state == "x" then
    new_state = " "
  end
  local new_line = line:gsub("%[.%]", string.format("[%s]", new_state), 1)
  vim.api.nvim_set_current_line(new_line)
end

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

function M.follow_journal_link()
  local base_dir = config.options.base_directory
  local link_path = get_link_path()

  if link_path then
    local full_path = vim.fn.join({ base_dir, link_path }, "/")
    vim.schedule(function()
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
    end)
    return ""
  else
    -- fall through to the next handler for the keybind
    --   this allows overriding standard keybinds like `gf` or `<CR>` without affecting their normal behavior
    return config.options.markdown.follow_journal_link_keybind
  end
end

function M.follow_external_link()
  local link_path = get_link_path()

  if link_path then
    vim.schedule(function()
      vim.ui.open(link_path)
    end)
    return ""
  else
    -- fall through to the next handler for the keybind
    --   this allows overriding standard keybinds like `gx` without affecting their normal behavior
    return config.options.markdown.follow_external_link_keybind
  end
end

function M.install()
  local toggle_check_keybind = config.options.markdown.toggle_check_keybind
  if toggle_check_keybind then
    vim.keymap.set("n", toggle_check_keybind, M.toggle_check, {
      noremap = true,
      silent = true,
      desc = "Bujo: Toggle checkbox state",
    })
  end

  local follow_journal_link_keybind = config.options.markdown.follow_journal_link_keybind
  if follow_journal_link_keybind then
    vim.keymap.set("n", follow_journal_link_keybind, M.follow_journal_link, {
      -- expr = true allows follow to return the keybind if a link isn't found and execute the next handler
      expr = true,
      noremap = true,
      silent = true,
      desc = "Bujo: Follow markdown link"
    })
  end

  local follow_external_link_keybind = config.options.markdown.follow_external_link_keybind
  if follow_external_link_keybind then
    vim.keymap.set("n", follow_external_link_keybind, M.follow_external_link, {
      -- expr = true allows exec to return the keybind if a link isn't found and execute the next handler
      expr = true,
      noremap = true,
      silent = true,
      desc = "Bujo: Execute markdown link in default system handler"
    })
  end
end

return M
