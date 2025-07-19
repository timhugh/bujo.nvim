local bujo_dir = vim.fn.getcwd()
local config_dir = bujo_dir .. "/tmp/lazy-basic"

vim.env.XDG_CONFIG_HOME = config_dir
vim.fn.mkdir(vim.env.XDG_CONFIG_HOME, "p")
vim.env.XDG_DATA_HOME   = config_dir .. "/data"
vim.fn.mkdir(vim.env.XDG_DATA_HOME, "p")
vim.env.XDG_STATE_HOME  = config_dir .. "/state"
vim.fn.mkdir(vim.env.XDG_STATE_HOME, "p")
vim.env.XDG_CACHE_HOME  = config_dir .. "/cache"
vim.fn.mkdir(vim.env.XDG_CACHE_HOME, "p")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "folke/lazy.nvim" },
  {
    dir = bujo_dir,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "leafo/etlua",
      "michaelb/sniprun",
    },
    opts = {
      base_directory = bujo_dir .. "/examples/journal",
      spreads = {
        monthly = {
          filename_template = "%Y/%m-%B",
          now_keybind = "<leader>nm",
        },
      },
    },
  },
})
