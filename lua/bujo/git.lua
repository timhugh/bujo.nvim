local M = {}

local config = require("bujo.config")
local fs = require("bujo.util.fs")

M._save_timer = vim.uv.new_timer()

local function get_commit_message()
  return os.date("%Y-%m-%d %H:%M:%S")
end

local function run_command_in_base_dir(command)
  local bujo_root = vim.fn.expand(config.options.base_directory)
  local process = vim.system(command, { cwd = bujo_root })
  local result = process:wait()
  if result.code ~= 0 then
    vim.notify("Bujo: command failed: " .. table.concat(process.cmd, " ") .. " - " .. result.stderr, vim.log.levels.ERROR)
    return false
  end
  return result.stdout
end

local function notify(message, level)
  if not config.options.git.notify then
    return
  end

  level = level or vim.log.levels.INFO
  vim.notify("Bujo: " .. message, level)
end

local function commit_and_push(delay)
  delay = delay or tonumber(config.options.git.debounce_ms) or 1000
  M._save_timer:stop()
  M._save_timer:start(delay, 0, vim.schedule_wrap(function()
    local should_commit = config.options.git.auto_commit
    local should_push = config.options.git.auto_push

    if not should_commit then
      return
    end

    local dirty = run_command_in_base_dir({ "git", "status", "--porcelain" })
    if not dirty or dirty == "" then
      return
    end

    notify("Committing changes", vim.log.levels.INFO)
    if not run_command_in_base_dir({ "git", "add", "." }) then return end
    if not run_command_in_base_dir({ "git", "commit", "-m", get_commit_message() }) then return end

    if should_push then
      notify("Pushing changes to remote", vim.log.levels.INFO)
      if not run_command_in_base_dir({"git", "push"}) then return end
    end
  end))
end

function M.commit_and_push_if_bujo_file()
  local current_file = fs.get_current_bujo_file(vim.api.nvim_get_current_buf())
  if current_file then
    commit_and_push()
  end
end

function M.install()
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.md",
    callback = function()
      M.commit_and_push_if_bujo_file()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      commit_and_push(0)
    end,
  })
end

return M
