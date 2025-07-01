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
  local bujo_dir = config.options.base_directory
  local link_path = get_link_path()

  if link_path then
    local full_path = vim.fn.join({ bujo_dir, link_path }, "/")
    vim.schedule(function()
      vim.cmd({"edit", vim.fn.fnameescape(full_path)})
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

function M.execute_code_block()
  local sniprun_available, sniprun = pcall(require, "sniprun.api")
  if not sniprun_available then
    vim.notify("Sniprun is not installed.\nPlease install it to execute code blocks.", vim.log.levels.ERROR)
    return
  end

  local ts_available, ts = pcall(vim.treesitter.get_parser, 0, "markdown")
  if not ts_available then
    vim.notify("There is no treesitter parser configured for markdown.\nPlease check your treesitter configuration", vim.log.levels.ERROR)
    return
  end

  local node = vim.treesitter.get_node()
  if not node or node:type() ~= "code_fence_content" then
    vim.notify("No code block found under cursor", vim.log.levels.WARN)
    return
  end

  local start_row, _, end_row, _ = node:range()
  sniprun.run_range(start_row + 1, end_row)
end

local function map_keybinds()
  local keybind = require("bujo.util.keybind")
  keybind.map_if_defined("n",
    config.options.markdown.toggle_check_keybind,
    M.toggle_check,
    { desc = "Bujo: Toggle checkbox state" }
  )
  keybind.map_if_defined("n",
    config.options.markdown.follow_journal_link_keybind,
    M.follow_journal_link,
    { expr = true, desc = "Bujo: Follow journal link" }
  )
  keybind.map_if_defined("n",
    config.options.markdown.follow_external_link_keybind,
    M.follow_external_link,
    { expr = true, desc = "Bujo: Follow external link in default system handler" }
  )
  keybind.map_if_defined("n",
    config.options.markdown.execute_code_block_keybind,
    M.execute_code_block,
    { desc = "Bujo: Execute code block" }
  )
end

function M.install()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = map_keybinds,
  })
end

return M
