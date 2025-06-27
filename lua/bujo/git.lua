local M = {}

local config = require("bujo.config")

M._save_queue = {}
M._save_timer = vim.uv.new_timer()

local function is_journal_file(file_path)
  return file_path:match("%.md$") and file_path:find(config.options.journal_dir, 1, true) ~= nil
end

local function get_current_journal_file(bufnr)
  local current_file_path = vim.api.nvim_buf_get_name(bufnr)

  if is_journal_file(current_file_path) then
    return current_file_path
  else
    return nil
  end
end

local function get_commit_message()
  return os.date("%Y-%m-%d %H:%M:%S")
end

local function run_command_in_journal_dir(command)
  local process = vim.system(command, {cwd = config.options.journal_dir})
  local result = process:wait()
  if result.code ~= 0 then
    vim.notify("Bujo: command failed: " .. table.concat(process.cmd, " ") .. " - " .. result.stderr, vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.process_queue()
  M._save_timer:stop()
  M._save_timer:start(500, 0, vim.schedule_wrap(function()
    local should_commit = config.options.auto_commit_journal
    local should_push = config.options.auto_push_journal

    if not should_commit then
      return
    end

    if #M._save_queue == 0 then
      return
    end

    vim.notify("Bujo: committing changes to journal", vim.log.levels.INFO)
    for _, file in ipairs(M._save_queue) do
      if not run_command_in_journal_dir({"git", "add", file}) then return end
    end
    if not run_command_in_journal_dir({"git", "commit", "-m", get_commit_message()}) then return end

    if should_push then
      vim.notify("Bujo: pushing changes to remote", vim.log.levels.INFO)
      if not run_command_in_journal_dir({"git", "push"}) then return end
    end

    M._save_queue = {}
  end))
end

function M.commit_and_push()
  local current_file = get_current_journal_file(vim.api.nvim_get_current_buf())
  if current_file then
    table.insert(M._save_queue, current_file)
  end
  M.process_queue()
end

function M.install()
  vim.api.nvim_create_user_command("Bujo commit_and_push", function()
    M.commit_and_push()
  end, {
    nargs = 0,
    desc = "Bujo: Commit and push current journal state",
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.md",
    callback = function()
      M.commit_and_push()
    end,
  })
end

return M
