local M = {}

local config = require("bujo.config")

function M.ensure_directory(dir)
  vim.fn.mkdir(dir, "p")
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify("Failed to create directory: " .. dir, vim.log.levels.ERROR)
  end
end

function M.file_is_in_directory(file_path, directory)
  local absolute_directory = vim.fn.fnamemodify(directory, ":p")
  local absolute_file_path = vim.fn.fnamemodify(file_path, ":p")

  return absolute_file_path:find(absolute_directory, 1, true) == 1
end

function M.is_bujo_file(file_path)
  return file_path:match("%.md$") and M.file_is_in_directory(file_path, config.options.base_directory)
end

function M.get_current_bujo_file(bufnr)
  local current_file_path = vim.api.nvim_buf_get_name(bufnr)

  if M.is_bujo_file(current_file_path) then
    return current_file_path
  else
    return nil
  end
end

return M
