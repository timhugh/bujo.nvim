local M = {}

function M.ensure(dir)
  vim.fn.mkdir(dir, "p")
  if vim.fn.isdirectory(dir) == 0 then
    vim.notify("Failed to create directory: " .. dir, vim.log.levels.ERROR)
  end
end

return M
