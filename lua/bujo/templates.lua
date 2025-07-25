local M = {}

local config = require("bujo.config")
M.load_error = true

function M.execute(template_name, destination_file, context)
  if M.load_error then
    return
  end

  local template_path = vim.fn.join({ config.options.templates_dir, template_name }, "/")
  local template_content = vim.fn.readfile(template_path)

  if not template_content or #template_content == 0 then
    vim.notify("Bujo: Template file not found or empty: " .. template_path, vim.log.levels.ERROR)
    return
  end

  local template, err = require("etlua").compile(table.concat(template_content, "\n"))
  if err then
    vim.notify("Bujo: Failed to compile template: " .. template_name .. ": " .. err, vim.log.levels.ERROR)
    return
  end

  context = context or {}
  context.bujo_config = config.options
  local rendered_content = template(context)

  local file = io.open(vim.fn.expand(destination_file), "w")
  if not file then
    vim.notify("Bujo: Failed to open destination file while executing template: " .. destination_file, vim.log.levels.ERROR)
    return
  end

  file:write(rendered_content)
  file:close()
end

function M.install()
  local etlua_success, _ = pcall(require, "etlua")
  if etlua_success then
    M.load_error = false
  end

  if not etlua_success and config.options.spreads.template then
    vim.notify(
      "Bujo: You have configured a template, but etlua is not installed\nso your template cannot be used.\nPlease make sure etlua is added to your dependencies\nor installed and added to your runtime path.",
      vim.log.levels.ERROR)
    return
  end
end

return M
