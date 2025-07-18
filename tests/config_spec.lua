local config = require("bujo.config")

describe("config", function()
  describe("setup", function()
    it("provides defaults for spread iteration configs", function()
      local resolved_config = config.setup({
        spreads = {
          monthly = {
            filename_template = "%Y-%m",
          },
        },
      })

      assert.is_not_nil(resolved_config.spreads.monthly)
      assert.are.same(
        {
          filename_template = "%Y-%m",
          iteration_step_seconds = 86400,
          iteration_max_steps = 120,
        },
        resolved_config.spreads.monthly
      )
    end)

    it("allows disabling the default weekly spread", function()
      local resolved_config = config.setup({
        spreads = {
          weekly = false,
        },
      })

      assert.is_nil(resolved_config.spreads.weekly)
    end)

    it("normalizes paths in the config", function()
      local resolved_config = config.setup({
        base_directory = "~/test_bujo",
        templates_dir = "templates",
        notes = {
          subdirectory = "notes",
        },
      })

      assert.are.same(vim.fn.expand("~/test_bujo"), resolved_config.base_directory)
      assert.are.same(vim.fn.expand("~/test_bujo/templates"), resolved_config.templates_dir)
      assert.are.same(vim.fn.expand("~/test_bujo/notes"), resolved_config.notes.subdirectory)
    end)
  end)
end)
