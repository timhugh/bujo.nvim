local M = {}

local config = require("bujo.config")
local fs = require("bujo.util.fs")

M._save_timer = vim.uv.new_timer()

local function get_commit_message()
  return os.date("%Y-%m-%d %H:%M:%S")
end

local function run_command_in_base_dir(command)
  local process = vim.system(command, { cwd = config.options.base_directory })
  local result = process:wait()
  if result.code ~= 0 then
    vim.notify("Bujo: command failed: " .. table.concat(process.cmd, " ") .. " - " .. result.stderr, vim.log.levels.ERROR)
    return false
  end
  return result.stdout
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

    vim.notify("Bujo: committing changes to journal", vim.log.levels.INFO)
    if not run_command_in_base_dir({ "git", "add", "." }) then return end
    if not run_command_in_base_dir({ "git", "commit", "-m", get_commit_message() }) then return end

    if should_push then
      vim.notify("Bujo: pushing changes to remote", vim.log.levels.INFO)
      if not run_command_in_base_dir({"git", "push"}) then return end
    end
  end))
end

function M.commit_and_push_if_journal_file()
  local current_file = fs.get_current_journal_file(vim.api.nvim_get_current_buf())
  if current_file then
    commit_and_push()
  end
end

function M.install()
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.md",
    callback = function()
      M.commit_and_push_if_journal_file()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      commit_and_push(0)
    end,
  })
end

return M
