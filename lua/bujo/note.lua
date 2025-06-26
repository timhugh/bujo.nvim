local fs = require("bujo.fs_util")
local config = require("bujo.config")

return {
  note = function()
    local opts = config.options

    local notes_dir = vim.fn.join({ opts.journal_dir, opts.notes_dir }, "/")
    fs.ensure(notes_dir)
    vim.ui.input({ prompt = "New note name: " }, function(input)
      if input and input ~= "" then
        local filename = input:gsub("[^%w-]", "_") .. ".md"
        local file_path = vim.fn.join({ notes_dir, filename }, "/")
        vim.cmd("edit " .. vim.fn.fnameescape(file_path))
      end
    end)
  end
}
