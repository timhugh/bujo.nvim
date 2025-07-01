local config = require("bujo.config")
local notes = require("bujo.notes")
local stub = require("luassert.stub")

local templates = require("bujo.templates")
local fs = require("bujo.util.fs")

local time_util = require("tests.util.time")

describe("note.now", function()
  local vim_cmd_stub
  local fs_ensure_directory_stub
  local file_readable_stub
  local templates_execute_stub
  local os_date_stub
  local io_open_stub

  local subject = function()
    notes.now()
    vim.wait(0)
  end

  before_each(function()
    vim_cmd_stub = stub(vim, "cmd")
    file_readable_stub = stub(vim.fn, "filereadable")
    templates_execute_stub = stub(templates, "execute")
    fs_ensure_directory_stub = stub(fs, "ensure_directory")
    io_open_stub = stub(io, "open", function(file_path, mode)
      return { close = function() end }
    end)

    time_util.stubbed_time = {
      year = 2025,
      month = 6,
      day = 23,
    }
    os_date_stub = stub(os, "date", time_util.os_date_stub)

    config.options.base_directory = "~/test_bujo"
    config.options.journal.subdirectory = "journal"
    config.options.journal.filename_template = "%Y/%m-%V"
  end)

  after_each(function()
    vim_cmd_stub:revert()
    file_readable_stub:revert()
    templates_execute_stub:revert()
    fs_ensure_directory_stub:revert()
    io_open_stub:revert()
    os_date_stub:revert()
  end)

  describe("when the journal file does not exist", function()
    before_each(function()
      file_readable_stub.returns(0)
    end)

    it("ensures the journal directory exists", function()
      subject()
      assert.stub(fs_ensure_directory_stub).was_called_with("~/test_bujo/journal")
    end)

    it("creates a new journal file with the current date", function()
      subject()
      assert.stub(vim_cmd_stub).was_called_with("edit ~/test_bujo/journal/2025/06-26.md")
    end)

    it("respects the journal filename template", function()
      config.options.journal.filename_template = "%Y-%m-%d"
      subject()
      assert.stub(vim_cmd_stub).was_called_with("edit ~/test_bujo/journal/2025-06-23.md")
    end)

    it("executes the template if configured", function()
      config.options.journal.template = "test_template"
      subject()
      assert.stub(templates_execute_stub).was_called_with("test_template", "~/test_bujo/journal/2025/06-26.md")
      assert.stub(vim_cmd_stub).was_called_with("edit ~/test_bujo/journal/2025/06-26.md")
    end)
  end)

  describe("when the journal file exists", function()
    before_each(function()
      file_readable_stub.returns(1)
    end)

    it("opens the existing journal file for the current date", function()
      subject()
      assert.stub(vim_cmd_stub).was_called_with("edit ~/test_bujo/journal/2025/06-26.md")
    end)

    it("respects the journal filename template", function()
      config.options.journal.filename_template = "%Y-%m-%d"
      subject()
      assert.stub(vim_cmd_stub).was_called_with("edit ~/test_bujo/journal/2025-06-23.md")
    end)

    it("does not execute the template", function()
      subject()
      assert.stub(templates_execute_stub).was_not_called()
    end)
  end)
end)

-- describe("note.next / note.previous", function()
--   local vim_cmd_stub
--   local fs_ensure_stub
--   local nvim_buf_get_name_stub
--   local os_time_stub
--
--   local stubbed_time = os.time{ year = 2025, month = 6, day = 26 }
--
--   before_each(function()
--     vim_cmd_stub = stub(vim, "cmd")
--     fs_ensure_stub = stub(fs, "ensure")
--     nvim_buf_get_name_stub = stub(vim.api, "nvim_buf_get_name")
--     os_time_stub = stub(os, "time", function()
--       return stubbed_time
--     end)
--   end)
--
--   after_each(function()
--     vim_cmd_stub:revert()
--     fs_ensure_stub:revert()
--     nvim_buf_get_name_stub:revert()
--     os_time_stub:revert()
--   end)
--
--   describe("when the current buffer is a journal file", function()
--     describe("with default weekly filename template", function()
--       it("navigates forward if the current buffer is a journal entry file", function()
--         nvim_buf_get_name_stub.returns(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, "06-26.md"}, "/"))
--         notes.next()
--         vim.wait(0)
--         assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.fnameescape(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, "06-27.md" }, "/")))
--       end)
--
--       it("navigates backward if the current buffer is a journal entry file", function()
--         nvim_buf_get_name_stub.returns(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, "06-26.md"}, "/"))
--         notes.next()
--         vim.wait(0)
--         assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.fnameescape(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, "06-25.md" }, "/")))
--       end)
--
--       it("opens next week if the current buffer is not a journal entry file", function()
--         nvim_buf_get_name_stub.returns("some_other_file.md")
--         notes.next()
--         vim.wait(0)
--         assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.fnameescape(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, "06-27.md" }, "/")))
--       end)
--
--       it("opens previous week if the current buffer is not a journal entry file", function()
--         nvim_buf_get_name_stub.returns("some_other_file.md")
--         notes.next()
--         vim.wait(0)
--         assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.fnameescape(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, "06-25.md" }, "/")))
--       end)
--     end)
--
--     describe("with a daily filename template", function()
--       before_each(function()
--         config.options.journal.filename_template = "%Y-%m-%d"
--       end)
--
--       it("navigates forward if the current buffer is a journal entry file", function()
--       end)
--
--       it("navigates backward if the current buffer is a journal entry file", function()
--       end)
--
--       it("opens next week if the current buffer is not a journal entry file", function()
--       end)
--
--       it("opens previous week if the current buffer is not a journal entry file", function()
--       end)
--     end)
--
--     describe("with a monthly filename template", function()
--       before_each(function()
--         config.options.journal.filename_template = "%Y-%m"
--       end)
--
--       it("navigates forward if the current buffer is a journal entry file", function()
--       end)
--
--       it("navigates backward if the current buffer is a journal entry file", function()
--       end)
--
--       it("opens next week if the current buffer is not a journal entry file", function()
--       end)
--
--       it("opens previous week if the current buffer is not a journal entry file", function()
--       end)
--     end)
--   end)
-- end)

describe("note.note", function()
  local vim_cmd_stub
  local fs_ensure_directory_stub
  local vim_ui_input_stub

  local subject = function()
    notes.note()
    vim.wait(0)
  end

  before_each(function()
    vim_cmd_stub = stub(vim, "cmd")
    fs_ensure_directory_stub= stub(fs, "ensure_directory")
    vim_ui_input_stub = stub(vim.ui, "input", function(opts, callback)
      assert(opts.prompt == "New note name: ")
      callback("test note")
    end)
  end)

  after_each(function()
    vim_cmd_stub:revert()
    fs_ensure_directory_stub:revert()
    vim_ui_input_stub:revert()
  end)

  it("ensures the notes directory exists", function()
    subject()
    assert.stub(fs_ensure_directory_stub).was_called_with(vim.fn.join({ config.options.base_directory, config.options.notes.subdirectory }, "/"))
  end)

  it("prompts for a new note name", function()
    subject()
    assert.stub(vim_ui_input_stub).was_called()
  end)

  it("opens a new note with a path-safe name", function()
    subject()
    assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.fnameescape(vim.fn.join({ config.options.base_directory, config.options.notes.subdirectory, "test_note.md" }, "/")))
  end)
end)

describe("note.install", function()
  local keymap_set_stub

  before_each(function()
    keymap_set_stub = stub(vim.keymap, "set")
  end)

  after_each(function()
    keymap_set_stub:revert()
  end)

  describe("default keybinds", function()
    it("sets keybind for now", function()
      notes.install()
      assert.stub(keymap_set_stub).was_called_with("n", config.options.journal.now_keybind, notes.now, {
        noremap = true,
        silent = true,
        desc = "Bujo: Create or open current journal entry"
      })
    end)

    it("sets keybind for next", function()
      notes.install()
      assert.stub(keymap_set_stub).was_called_with("n", config.options.journal.next_keybind, notes.next, {
        noremap = true,
        silent = true,
        desc = "Bujo: Open next journal entry"
      })
    end)

    it("sets keybind for previous", function()
      notes.install()
      assert.stub(keymap_set_stub).was_called_with("n", config.options.journal.previous_keybind, notes.previous, {
        noremap = true,
        silent = true,
        desc = "Bujo: Open previous journal entry"
      })
    end)

    it("sets keybind for note", function()
      notes.install()
      assert.stub(keymap_set_stub).was_called_with("n", config.options.journal.note_keybind, notes.note, {
        noremap = true,
        silent = true,
        desc = "Bujo: Create a new note"
      })
    end)
  end)

  describe("overriding keybinds", function()
    it("sets the keybind for now", function()
      config.options.journal.now_keybind = "gn"
      notes.install()
      assert.stub(keymap_set_stub).was_called_with("n", "gn", notes.now, {
        noremap = true,
        silent = true,
        desc = "Bujo: Create or open current journal entry"
      })
    end)

    it("sets the keybind for next", function()
      config.options.journal.next_keybind = "gF"
      notes.install()
      assert.stub(keymap_set_stub).was_called_with("n", "gF", notes.next, {
        noremap = true,
        silent = true,
        desc = "Bujo: Open next journal entry"
      })
    end)

    it("sets the keybind for previous", function()
      config.options.journal.previous_keybind = "gB"
      notes.install()
      assert.stub(keymap_set_stub).was_called_with("n", "gB", notes.previous, {
        noremap = true,
        silent = true,
        desc = "Bujo: Open previous journal entry"
      })
    end)

    it("sets the keybind for note", function()
      config.options.journal.note_keybind = "gN"
      notes.install()
      assert.stub(keymap_set_stub).was_called_with("n", "gN", notes.note, {
        noremap = true,
        silent = true,
        desc = "Bujo: Create a new note"
      })
    end)
  end)

  describe("disabling keybinds", function()
    it("does not set keybind for now", function()
      config.options.journal.now_keybind = false
      notes.install()
      assert.stub(keymap_set_stub).was_not_called_with("n", config.options.journal.now_keybind, notes.now)
    end)

    it("does not set keybind for next", function()
      config.options.journal.next_keybind = false
      notes.install()
      assert.stub(keymap_set_stub).was_not_called_with("n", config.options.journal.next_keybind, notes.next)
    end)

    it("does not set keybind for previous", function()
      config.options.journal.previous_keybind = false
      notes.install()
      assert.stub(keymap_set_stub).was_not_called_with("n", config.options.journal.previous_keybind, notes.previous)
    end)

    it("does not set keybind for note", function()
      config.options.journal.note_keybind = false
      notes.install()
      assert.stub(keymap_set_stub).was_not_called_with("n", config.options.journal.note_keybind, notes.note)
    end)
  end)
end)
