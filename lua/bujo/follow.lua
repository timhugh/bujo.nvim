local config = require("bujo.config")

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

return {
  follow = function()
    local journal_dir = config.options.journal_dir
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

    if link_path then
      local full_path = vim.fn.join({ journal_dir, link_path }, "/")
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
    else
      vim.notify("No markdown link found under cursor", vim.log.levels.WARN)
    end
  end,
}
