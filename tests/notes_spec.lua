local config = require("bujo.config")
local notes = require("bujo.notes")
local templates = require("bujo.templates")
local time_util = require("tests.util.time")
local stub = require("luassert.stub")

describe("notes", function()
  local vim_notify_stub
  local vim_cmd_stub
  local vim_mkdir_stub
  local file_readable_stub
  local templates_execute_stub
  local io_open_stub
  local os_date_stub
  local os_time_stub

  before_each(function()
    vim_notify_stub = stub(vim, "notify", function(msg, level)
      if level == vim.log.levels.ERROR then
        error(msg)
      else
        print("Notify: " .. msg)
      end
    end)
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
    config.options.spreads.subdirectory = "spreads"
  end)

  after_each(function()
    vim_notify_stub:revert()
    vim_cmd_stub:revert()
    vim_mkdir_stub:revert()
    file_readable_stub:revert()
    templates_execute_stub:revert()
    io_open_stub:revert()
    os_date_stub:revert()
    os_time_stub:revert()
  end)

  describe("now", function()

    local subject = function()
      notes.now()
      vim.wait(0)
    end

    before_each(function()
      config.options.spreads.filename_template = "%Y/W%V"
    end)

    describe("when the spread does not exist", function()
      before_each(function()
        file_readable_stub.returns(0)
      end)

      it("ensures the directory exists", function()
        subject()
        assert.stub(vim_mkdir_stub).was_called_with(vim.fn.expand("~/test_bujo/spreads/2025"), "p")
      end)

      it("creates a new spread with the current date", function()
        subject()
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025/W26.md"))
      end)

      it("respects the spreads filename template", function()
        config.options.spreads.filename_template = "%Y-%m-%d"
        subject()
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-06-23.md"))
      end)

      it("executes the template if configured", function()
        config.options.spreads.template = "test_template"
        subject()
        assert.stub(templates_execute_stub).was_called_with("test_template", vim.fn.expand("~/test_bujo/spreads/2025/W26.md"))
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025/W26.md"))
      end)

      it("does not execute the template if not configured", function()
        config.options.spreads.template = false
        subject()
        assert.stub(templates_execute_stub).was_not_called()
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025/W26.md"))
      end)
    end)

    describe("when the spread exists", function()
      before_each(function()
        file_readable_stub.returns(1)
      end)

      it("opens the existing spread for the current date", function()
        subject()
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025/W26.md"))
      end)

      it("respects the spreads filename template", function()
        config.options.spreads.filename_template = "%Y-%m-%d"
        subject()
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-06-23.md"))
      end)

      it("does not execute the template", function()
        subject()
        assert.stub(templates_execute_stub).was_not_called()
      end)
    end)
  end)

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
        config.options.spreads.filename_template = "%Y-W%V"
      end)

      it("navigates forward one week from the current file", function()
        nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/spreads/2025-W23.md"))
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-W24.md"))
      end)

      it("navigates backward one week from the current file", function()
        nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/spreads/2025-W23.md"))
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-W22.md"))
      end)

      it("navigates forward one week from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-W27.md"))
      end)

      it("navigates backward one week from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-W25.md"))
      end)
    end)

    describe("daily template", function()
      before_each(function()
        config.options.spreads.filename_template = "%Y-%m-%d"
      end)

      it("navigates forward one day from the current file", function()
        nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/spreads/2025-06-22.md"))
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-06-23.md"))
      end)

      it("navigates backward one day from the current file", function()
        nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/spreads/2025-06-22.md"))
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-06-21.md"))
      end)

      it("navigates forward one day from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-06-24.md"))
      end)

      it("navigates backward one day from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-06-22.md"))
      end)
    end)

    describe("monthly template", function()
      before_each(function()
        config.options.spreads.filename_template = "%Y-%m"
      end)

      it("navigates forward one month from the current file", function()
        nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/spreads/2025-08.md"))
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-09.md"))
      end)

      it("navigates backward one month from the current file", function()
        nvim_buf_get_name_stub.returns(vim.fn.expand("~/test_bujo/spreads/2025-08.md"))
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-07.md"))
      end)

      it("navigates forward one month from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.next()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-07.md"))
      end)

      it("navigates backward one month from the current date", function()
        nvim_buf_get_name_stub.returns("some_other_file.md")
        notes.previous()
        vim.wait(0)
        assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/spreads/2025-05.md"))
      end)
    end)
  end)

  describe("note", function()
    local vim_ui_input_stub

    local subject = function()
      notes.note()
      vim.wait(0)
    end

    before_each(function()
      vim_ui_input_stub = stub(vim.ui, "input", function(opts, callback)
        assert(opts.prompt == "New note name: ")
        callback("test note")
      end)

      config.options.base_directory = "~/test_bujo"
      config.options.spreads.subdirectory = "notes"
    end)

    after_each(function()
      vim_ui_input_stub:revert()
    end)

    it("ensures the directory exists", function()
      subject()
      assert.stub(vim_mkdir_stub).was_called_with(vim.fn.expand("~/test_bujo/notes"), "p")
    end)

    it("prompts for a new note name", function()
      subject()
      assert.stub(vim_ui_input_stub).was_called()
    end)

    it("opens a new note with a path-safe name", function()
      subject()
      assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/test_bujo/notes/test_note.md"))
    end)
  end)
end)
