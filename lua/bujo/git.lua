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
    return false, result.stderr
  end
  return true, result.stdout
end

local function notify(message, level, force)
  if not force and not config.options.git.notify then
    return
  end

  level = level or vim.log.levels.INFO
  vim.notify("Bujo: " .. message, level)
end

local function auto_commit_and_push(delay)
  if not config.options.git.auto_commit then
    return
  end

  delay = delay or tonumber(config.options.git.debounce_ms) or 1000
  M._save_timer:stop()
  M._save_timer:start(delay, 0, vim.schedule_wrap(function()
    if not M.commit() then return end
    if not config.options.git.auto_push then return end
    if not M.pull() then return end
    M.push()
  end))
end

local function is_dirty()
  local ok, output = run_command_in_base_dir({ "git", "status", "--porcelain" })
  return ok and output and output ~= ""
end

local function commit_and_push_if_bujo_file()
  local current_file = fs.get_current_bujo_file(vim.api.nvim_get_current_buf())
  if current_file then
    auto_commit_and_push(config.options.git.debounce_ms)
  end
end

function M.commit()
  if not is_dirty() then return end

  notify("Committing changes", vim.log.levels.INFO)
  local ok, output = run_command_in_base_dir({ "git", "add", "." })
  if not ok then
    notify("Failed to stage changes: " .. output, vim.log.levels.ERROR, true)
    return false
  end
  ok, output = run_command_in_base_dir({ "git", "commit", "-m", get_commit_message() })
  if not ok then
    notify("Failed to commit changes: " .. output, vim.log.levels.ERROR, true)
    return false
  end

  return true
end

function M.push()
  notify("Pushing changes to remote", vim.log.levels.INFO)
  local ok, output = run_command_in_base_dir({ "git", "push" })
  if not ok then
    notify("Failed to push changes: " .. output, vim.log.levels.ERROR, true)
    return false
  end
  return true
end

function M.pull()
  notify("Pulling changes from remote", vim.log.levels.INFO)
  local ok, output = run_command_in_base_dir({ "git", "pull", "--rebase" })
  if not ok then
    notify("Failed to pull changes: " .. output, vim.log.levels.ERROR, true)
    return false
  end
  return true
end

function M.install()
  if config.options.git.auto_commit then
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.md",
      callback = function()
        commit_and_push_if_bujo_file()
      end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        auto_commit_and_push(0)
      end,
    })
  end
end

return M
