local M = {}

function M.map_if_defined(mode, keybind, callback, opts)
  opts = vim.tbl_deep_extend("force", {
    noremap = true,
    silent = true,
  }, opts or {})

  if keybind then
    vim.keymap.set(mode, keybind, callback, opts)
  end
end

return M
