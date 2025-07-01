local config = require("bujo.config")
local notes = require("bujo.notes")
local templates = require("bujo.templates")
local time_util = require("tests.util.time")
local stub = require("luassert.stub")

describe("note", function()
  local vim_cmd_stub
  local vim_mkdir_stub
  local file_readable_stub
  local templates_execute_stub
  local io_open_stub
  local os_date_stub
  local os_time_stub

  before_each(function()
    vim_cmd_stub = stub(vim, "cmd")
    vim_mkdir_stub = stub(vim.fn, "mkdir", function(dir, mode) return 1 end)
    file_readable_stub = stub(vim.fn, "filereadable")
    templates_execute_stub = stub(templates, "execute")
    io_open_stub = stub(io, "open", function(file_path, mode)
      return { close = function() end }
    end)

    time_util.stubbed_time = {
      year = 2025,
      month = 6,
      day = 23,
    }
    os_date_stub = stub(os, "date", time_util.os_date_stub)
    os_time_stub = stub(os, "time", time_util.os_time_stub)

    config.options.base_directory = "~/test_bujo"
    config.options.journal.subdirectory = "journal"
  end)

  after_each(function()
    vim_cmd_stub:revert()
    vim_mkdir_stub:revert()
    file_readable_stub:revert()
    templates_execute_stub:revert()
    io_open_stub:revert()
    os_date_stub:revert()
    os_time_stub:revert()
  end)

  -- describe("now", function()
  --
  --   local subject = function()
  --     notes.now()
  --     vim.wait(0)
  --   end
  --
  --   before_each(function()
  --     config.options.journal.filename_template = "%Y/%m-%V"
  --   end)
  --
  --   describe("when the journal file does not exist", function()
  --     before_each(function()
  --       file_readable_stub.returns(0)
  --     end)
  --
  --     it("ensures the journal directory exists", function()
  --       subject()
  --       assert.stub(vim_mkdir_stub).was_called_with(vim.fn.expand("~/test_bujo/journal"), "p")
  --     end)
  --
  --     it("creates a new journal file with the current date", function()
  --       subject()
  --       assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025/06-26.md"))
  --     end)
  --
  --     it("respects the journal filename template", function()
  --       config.options.journal.filename_template = "%Y-%m-%d"
  --       subject()
  --       assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-06-23.md"))
  --     end)
  --
  --     it("executes the template if configured", function()
  --       config.options.journal.template = "test_template"
  --       subject()
  --       assert.stub(templates_execute_stub).was_called_with("test_template", vim.fn.expand("~/test_bujo/journal/2025/06-26.md"))
  --       assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025/06-26.md"))
  --     end)
  --   end)
  --
  --   describe("when the journal file exists", function()
  --     before_each(function()
  --       file_readable_stub.returns(1)
  --     end)
  --
  --     it("opens the existing journal file for the current date", function()
  --       subject()
  --       assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025/06-26.md"))
  --     end)
  --
  --     it("respects the journal filename template", function()
  --       config.options.journal.filename_template = "%Y-%m-%d"
  --       subject()
  --       assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-06-23.md"))
  --     end)
  --
  --     it("does not execute the template", function()
  --       subject()
  --       assert.stub(templates_execute_stub).was_not_called()
  --     end)
  --   end)
  -- end)

  describe("next / previous", function()
    local nvim_buf_get_name_stub

    before_each(function()
      nvim_buf_get_name_stub = stub(vim.api, "nvim_buf_get_name")
    end)

    after_each(function()
      nvim_buf_get_name_stub:revert()
    end)

    describe("weekly template", function()
      before_each(function()
        config.options.journal.filename_template = "%Y-%m-W%V"
      end)

      it("navigates forward one week from the current file", function()
        nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/journal/2025-06-W23.md"))
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-06-W24.md"))
      end)

      it("navigates backward one week from the current file", function()
        nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/journal/2025-06-W23.md"))
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-06-W22.md"))
      end)

      it("navigates forward one week from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-06-W27.md"))
      end)

      it("navigates backward one week from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-06-W25.md"))
      end)
    end)

    describe("daily template", function()
      before_each(function()
        config.options.journal.filename_template = "%Y-%m-%d"
      end)

      -- it("navigates forward one day from the current file", function()
      --   nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/journal/06-22.md"))
        -- notes.next()
        -- vim.wait(0)
      --   assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/06-23.md"))
      -- end)
      --
      -- it("navigates backward one day from the current file", function()
      --   nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/journal/06-26.md"))
        -- notes.next()
        -- vim.wait(0)
      --   assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/06-22.md"))
      -- end)

      it("navigates forward one day from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-06-24.md"))
      end)

      it("navigates backward one day from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-06-22.md"))
      end)
    end)

    describe("monthly template", function()
      before_each(function()
        config.options.journal.filename_template = "%Y-%m"
      end)

      -- it("navigates forward one month from the current file", function()
      --   nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/journal/06-22.md"))
        -- notes.next()
        -- vim.wait(0)
      --   assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/06-23.md"))
      -- end)
      --
      -- it("navigates backward one month from the current file", function()
      --   nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/journal/06-26.md"))
        -- notes.next()
        -- vim.wait(0)
      --   assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/06-22.md"))
      -- end)

      it("navigates forward one month from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-07.md"))
      end)

      it("navigates backward one month from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/journal/2025-05.md"))
      end)
    end)
  end)

  -- describe("note", function()
  --   local vim_ui_input_stub
  --
  --   local subject = function()
  --     notes.note()
  --     vim.wait(0)
  --   end
  --
  --   before_each(function()
  --     vim_ui_input_stub = stub(vim.ui, "input", function(opts, callback)
  --       assert(opts.prompt == "New note name: ")
  --       callback("test note")
  --     end)
  --
  --     config.options.base_directory = "~/test_bujo"
  --     config.options.journal.subdirectory = "notes"
  --   end)
  --
  --   after_each(function()
  --     vim_ui_input_stub:revert()
  --   end)
  --
  --   it("ensures the notes directory exists", function()
  --     subject()
  --     assert.stub(vim_mkdir_stub).was_called_with(vim.fn.expand("~/test_bujo/notes"), "p")
  --   end)
  --
  --   it("prompts for a new note name", function()
  --     subject()
  --     assert.stub(vim_ui_input_stub).was_called()
  --   end)
  --
  --   it("opens a new note with a path-safe name", function()
  --     subject()
  --     assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/notes/test_note.md"))
  --   end)
  -- end)
  --
  -- describe("install", function()
  --   local keymap_set_stub
  --
  --   before_each(function()
  --     keymap_set_stub = stub(vim.keymap, "set")
  --   end)
  --
  --   after_each(function()
  --     keymap_set_stub:revert()
  --   end)
  --
  --   describe("default keybinds", function()
  --     it("sets keybind for now", function()
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_called_with("n", config.options.journal.now_keybind, notes.now, {
  --         noremap = true,
  --         silent = true,
  --         desc = "Bujo: Create or open current journal entry"
  --       })
  --     end)
  --
  --     it("sets keybind for next", function()
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_called_with("n", config.options.journal.next_keybind, notes.next, {
  --         noremap = true,
  --         silent = true,
  --         desc = "Bujo: Open next journal entry"
  --       })
  --     end)
  --
  --     it("sets keybind for previous", function()
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_called_with("n", config.options.journal.previous_keybind, notes.previous, {
  --         noremap = true,
  --         silent = true,
  --         desc = "Bujo: Open previous journal entry"
  --       })
  --     end)
  --
  --     it("sets keybind for note", function()
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_called_with("n", config.options.journal.note_keybind, notes.note, {
  --         noremap = true,
  --         silent = true,
  --         desc = "Bujo: Create a new note"
  --       })
  --     end)
  --   end)
  --
  --   describe("overriding keybinds", function()
  --     it("sets the keybind for now", function()
  --       config.options.journal.now_keybind = "gn"
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_called_with("n", "gn", notes.now, {
  --         noremap = true,
  --         silent = true,
  --         desc = "Bujo: Create or open current journal entry"
  --       })
  --     end)
  --
  --     it("sets the keybind for next", function()
  --       config.options.journal.next_keybind = "gF"
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_called_with("n", "gF", notes.next, {
  --         noremap = true,
  --         silent = true,
  --         desc = "Bujo: Open next journal entry"
  --       })
  --     end)
  --
  --     it("sets the keybind for previous", function()
  --       config.options.journal.previous_keybind = "gB"
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_called_with("n", "gB", notes.previous, {
  --         noremap = true,
  --         silent = true,
  --         desc = "Bujo: Open previous journal entry"
  --       })
  --     end)
  --
  --     it("sets the keybind for note", function()
  --       config.options.journal.note_keybind = "gN"
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_called_with("n", "gN", notes.note, {
  --         noremap = true,
  --         silent = true,
  --         desc = "Bujo: Create a new note"
  --       })
  --     end)
  --   end)
  --
  --   describe("disabling keybinds", function()
  --     it("does not set keybind for now", function()
  --       config.options.journal.now_keybind = false
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_not_called_with("n", config.options.journal.now_keybind, notes.now)
  --     end)
  --
  --     it("does not set keybind for next", function()
  --       config.options.journal.next_keybind = false
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_not_called_with("n", config.options.journal.next_keybind, notes.next)
  --     end)
  --
  --     it("does not set keybind for previous", function()
  --       config.options.journal.previous_keybind = false
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_not_called_with("n", config.options.journal.previous_keybind, notes.previous)
  --     end)
  --
  --     it("does not set keybind for note", function()
  --       config.options.journal.note_keybind = false
  --       notes.install()
  --       assert.stub(keymap_set_stub).was_not_called_with("n", config.options.journal.note_keybind, notes.note)
  --     end)
  --   end)
  -- end)

end)
