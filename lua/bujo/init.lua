local M = {}

local config = require("bujo.config")
local bujo_notes = require("bujo.notes")
local bujo_find = require("bujo.find")
local bujo_markdown = require("bujo.markdown")
local bujo_git = require("bujo.git")
local bujo_templates = require("bujo.templates")

function M.setup(user_config)
  config.setup(user_config)

  bujo_notes.install()
  bujo_find.install()
  bujo_markdown.install()
  bujo_git.install()
  bujo_templates.install()
end

return M

