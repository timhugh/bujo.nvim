local M = {}

local config = require("bujo.config")

M.load_error = "module.install was not called"

function M.execute(template_name, destination_file)
  if M.load_error then
    vim.notify("Bujo: templates are disabled: " .. M.load_error, vim.log.levels.ERROR)
    return
  end

  local template_path = vim.fn.join({ config.options.base_directory, config.options.templates_dir, template_name }, "/")
  local template_content = vim.fn.readfile(template_path)

  if not template_content or #template_content == 0 then
    vim.notify("Template file not found or empty: " .. template_path, vim.log.levels.ERROR)
    return
  end

  local template, err = require("etlua").compile(table.concat(template_content, "\n"))
  if err then
    vim.notify("Failed to compile template: " .. template_name .. ": " .. err, vim.log.levels.ERROR)
    return
  end

  local rendered_content = template({
    config = config.options,
  })

  local file = io.open(destination_file, "w")
  if not file then
    vim.notify("Failed to open destination file: " .. destination_file, vim.log.levels.ERROR)
    return
  end

  file:write(rendered_content)
  file:close()
end

function M.install()
  local etlua_success, etlua_err = pcall(require, "etlua")
  if not etlua_success then
    M.load_error = "etlua not found: " .. etlua_err
  else
    M.load_error = nil
  end
end

return M
