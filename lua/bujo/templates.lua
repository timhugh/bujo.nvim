local etlua = require("etlua")
local config = require("bujo.config")

return {
  execute = function(template_name, destination_file)
    local opts = config.options

    local template_path = vim.fn.join({ opts.journal_dir, opts.templates_dir, template_name }, "/")
    local template_content = vim.fn.readfile(template_path)

    if not template_content or #template_content == 0 then
      vim.notify("Template file not found or empty: " .. template_path, vim.log.levels.ERROR)
      return
    end

    local template = etlua.compile(table.concat(template_content, "\n"))

    local rendered_content = template({
      config = opts,
    })

    local file = io.open(destination_file, "w")
    if not file then
      vim.notify("Failed to open destination file: " .. destination_file, vim.log.levels.ERROR)
      return
    end

    file:write(rendered_content)
    file:close()
  end
}
