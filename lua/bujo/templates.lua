local M = {}

local config = require("bujo.config")
M.load_error = true

function M.execute(template_name, destination_file)
  if M.load_error then
    return
  end

  destination_file = vim.fn.expand(destination_file)

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
    bujo_config = config.options,
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
  local etlua_success, _ = pcall(require, "etlua")
  if etlua_success then
    M.load_error = false
  end

  if not etlua_success and config.options.journal.template then
    vim.notify(
      "Bujo: you have configured a template, but etlua is not installed so your template cannot be used. Please make sure etlua is added to your dependencies or installed and added to your runtime path.",
      vim.log.levels.ERROR)
    return
  end
end

return M
