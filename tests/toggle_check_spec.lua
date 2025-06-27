local toggle = require("bujo.toggle_check")
local stub = require("luassert.stub")

describe("bujo.toggle_check", function()
  local get_current_line_stub
  local set_current_line_stub

  before_each(function()
    get_current_line_stub = stub(vim.api, "nvim_get_current_line")
    set_current_line_stub = stub(vim.api, "nvim_set_current_line")
  end)

  after_each(function()
    get_current_line_stub:revert()
    set_current_line_stub:revert()
  end)

  it("toggles an unchecked checkbox to checked", function()
    get_current_line_stub.returns("- [ ] Task 1")
    toggle.toggle_check()
    assert.stub(set_current_line_stub).was_called_with("- [x] Task 1")
  end)

  it("toggles a checked checkbox to unchecked", function()
    get_current_line_stub.returns("- [x] Task 1")
    toggle.toggle_check()
    assert.stub(set_current_line_stub).was_called_with("- [ ] Task 1")
  end)

  it("toggles an unknown checkbox state to checked", function()
    get_current_line_stub.returns("- [a] Task 1")
    toggle.toggle_check()
    assert.stub(set_current_line_stub).was_called_with("- [x] Task 1")
  end)

  it("does not affect markdown links on the same line", function()
    get_current_line_stub.returns("- [ ] Task 1 [link](http://example.com)")
    toggle.toggle_check()
    assert.stub(set_current_line_stub).was_called_with("- [x] Task 1 [link](http://example.com)")
  end)

  it("does not affect markdown links in bulleted lists", function()
    get_current_line_stub.returns("- [link](http://example.com)")
    local notify_stub = stub(vim, "notify")
    toggle.toggle_check()
    assert.stub(set_current_line_stub).was_not_called()
    assert.stub(notify_stub).was_called()
    notify_stub:revert()
  end)

  it("warns if no checkbox is found", function()
    get_current_line_stub.returns("No checkbox here")
    local notify_stub = stub(vim, "notify")
    toggle.toggle_check()
    assert.stub(set_current_line_stub).was_not_called()
    assert.stub(notify_stub).was_called()
    notify_stub:revert()
  end)
end)

describe("bujo.toggle_check.install", function()
  local keymap_set_stub

  before_each(function()
    keymap_set_stub = stub(vim.keymap, "set")
  end)

  after_each(function()
    keymap_set_stub:revert()
  end)

  it("sets the keybind for toggling checkboxes", function()
    local config = require("bujo.config")
    config.setup({
      toggle_check_keybind = "<leader>tc",
    })
    toggle.install()
    assert.stub(keymap_set_stub).was_called_with("n", "<leader>tc", toggle.toggle_check, {
      noremap = true,
      silent = true,
      desc = "Bujo: Toggle checkbox state",
    })
  end)
end)
