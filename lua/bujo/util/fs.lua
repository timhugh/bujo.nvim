local M = {}

local config = require("bujo.config")

function M.ensure_directory(dir)
  dir = vim.fn.expand(dir)
  if vim.fn.mkdir(dir, "p") == 0 then
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

function M.get_path_relative_to(base_dir, file_path)
  local absolute_base_dir = vim.fn.expand(base_dir)
  local absolute_file_path = vim.fn.expand(file_path)

  local relative_file_path = absolute_file_path:sub(#absolute_base_dir +1)
  if relative_file_path:sub(1, 1) == "/" then
    relative_file_path = relative_file_path:sub(2) -- remove leading slash if present
  end
  return relative_file_path
end

return M
