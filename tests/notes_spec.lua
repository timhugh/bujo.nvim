local config = require("bujo.config")
local notes = require("bujo.notes")
local stub = require("luassert.stub")

local templates = require("bujo.templates")
local fs = require("bujo.util.fs")

describe("note.now", function()
  local vim_cmd_stub
  local file_readable_stub
  local templates_execute_stub
  local fs_ensure_stub

  before_each(function()
    vim_cmd_stub = stub(vim, "cmd")
    file_readable_stub = stub(vim.fn, "filereadable")
    templates_execute_stub = stub(templates, "execute")
    fs_ensure_stub = stub(fs, "ensure")
  end)

  after_each(function()
    vim_cmd_stub:revert()
    file_readable_stub:revert()
    templates_execute_stub:revert()
    fs_ensure_stub:revert()
  end)

  describe("when the journal file does not exist", function()
    before_each(function()
      file_readable_stub.returns(0)
    end)

    it("ensures the journal directory exists", function()
      notes.now()
      vim.wait(0)
      assert.stub(fs_ensure_stub).was_called_with(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory }, "/"))
    end)

    it("creates a new journal file with the current date", function()
      notes.now()
      vim.wait(0)
      assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.fnameescape(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, os.date(config.options.journal.filename_template) }, "/") .. ".md"))
    end)

    it("respects the journal filename template", function()
      config.options.journal.filename_template = "%Y-%m-%d"
      notes.now()
      vim.wait(0)
      assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.fnameescape(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, os.date(config.options.journal.filename_template) }, "/") .. ".md"))
    end)

    it("executes the template if configured", function()
      config.options.journal.template = "test_template"
      notes.now()
      vim.wait(0)
      assert.stub(templates_execute_stub).was_called_with("test_template", vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, os.date(config.options.journal.filename_template) }, "/") .. ".md")
      assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.fnameescape(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, os.date(config.options.journal.filename_template) }, "/") .. ".md"))
    end)
  end)

  describe("when the journal file exists", function()
    before_each(function()
      file_readable_stub.returns(1)
    end)

    it("opens the existing journal file for the current date", function()
      notes.now()
      vim.wait(0)
      assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.fnameescape(vim.fn.join({ config.options.base_directory, config.options.journal.subdirectory, os.date(config.options.journal.filename_template) }, "/") .. ".md"))
    end)

    it("does not execute the template", function()
      notes.now()
      vim.wait(0)
      assert.stub(templates_execute_stub).was_not_called()
    end)
  end)
end)

describe("note.next", function()
end)

describe("note.previous", function()
end)

describe("note.note", function()
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
