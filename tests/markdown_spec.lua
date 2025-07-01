-- require("tests.spec_helper").setup()

local config = require("bujo.config")
local markdown = require("bujo.markdown")
local stub = require("luassert.stub")

describe("markdown.toggle_check", function()
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
    markdown.toggle_check()
    assert.stub(set_current_line_stub).was_called_with("- [x] Task 1")
  end)

  it("toggles a checked checkbox to unchecked", function()
    get_current_line_stub.returns("- [x] Task 1")
    markdown.toggle_check()
    assert.stub(set_current_line_stub).was_called_with("- [ ] Task 1")
  end)

  it("toggles an unknown checkbox state to checked", function()
    get_current_line_stub.returns("- [a] Task 1")
    markdown.toggle_check()
    assert.stub(set_current_line_stub).was_called_with("- [x] Task 1")
  end)

  it("does not affect markdown links on the same line", function()
    get_current_line_stub.returns("- [ ] Task 1 [link](http://example.com)")
    markdown.toggle_check()
    assert.stub(set_current_line_stub).was_called_with("- [x] Task 1 [link](http://example.com)")
  end)

  it("does not affect markdown links in bulleted lists", function()
    get_current_line_stub.returns("- [link](http://example.com)")
    local notify_stub = stub(vim, "notify")
    markdown.toggle_check()
    assert.stub(set_current_line_stub).was_not_called()
    assert.stub(notify_stub).was_called()
    notify_stub:revert()
  end)

  it("warns if no checkbox is found", function()
    get_current_line_stub.returns("No checkbox here")
    local notify_stub = stub(vim, "notify")
    markdown.toggle_check()
    assert.stub(set_current_line_stub).was_not_called()
    assert.stub(notify_stub).was_called()
    notify_stub:revert()
  end)
end)

describe("markdown.follow_journal_link", function()
  local get_current_line_stub
  local win_get_cursor_stub
  local vim_cmd_stub

  before_each(function()
    config.options.base_directory = "~/bujo"
    get_current_line_stub = stub(vim.api, "nvim_get_current_line")
    win_get_cursor_stub = stub(vim.api, "nvim_win_get_cursor")
    vim_cmd_stub = stub(vim, "cmd")
  end)

  after_each(function()
    get_current_line_stub:revert()
    win_get_cursor_stub:revert()
    vim_cmd_stub:revert()
  end)

  it("follows a single link on the line and does not fall through", function()
    get_current_line_stub.returns("[link](journal/2023-10-01.md)")
    win_get_cursor_stub.returns({ 1, 1 })

    assert(markdown.follow_journal_link() == "")
    vim.wait(0) -- force async execution

    assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/bujo/journal/2023-10-01.md"))
  end)

  it("follows a single link anywhere on the line regardless of cursor position and does not fall through", function()
    get_current_line_stub.returns("- hey check out this cool [link](journal/2023-10-01.md)")
    win_get_cursor_stub.returns({ 1, 1 }) -- cursor is not on the link

    assert(markdown.follow_journal_link() == "")
    vim.wait(0) -- force async execution

    assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/bujo/journal/2023-10-01.md"))
  end)

  it("follows a link under the cursor if there are multiple links on the line and does not fall through", function()
    get_current_line_stub.returns("- here are some neat links: [link1](journal/2023-10-01.md) and [link2](journal/2023-10-02.md)")
    win_get_cursor_stub.returns({ 1, 30 }) -- cursor is on link1

    assert(markdown.follow_journal_link() == "")
    vim.wait(0) -- force async execution

    assert.stub(vim_cmd_stub).was_called_with("edit " .. vim.fn.expand("~/bujo/journal/2023-10-01.md"))
  end)

  it("passes on to the next handler if there are no links", function()
    get_current_line_stub.returns("No links here")
    win_get_cursor_stub.returns({ 1, 1 })

    assert(markdown.follow_journal_link() == config.options.markdown.follow_journal_link_keybind)
    vim.wait(0) -- force async execution

    assert.stub(vim_cmd_stub).was_not_called()
  end)

  it("passes on to the next handler if there are multiple links and the cursor is not on one of them", function()
    get_current_line_stub.returns("- here are some neat links: [link1](journal/2023-10-01.md) and [link2](journal/2023-10-02.md)")
    win_get_cursor_stub.returns({ 1, 1 }) -- cursor is not on any link

    assert(markdown.follow_journal_link() == config.options.markdown.follow_journal_link_keybind)
    vim.wait(0) -- force async execution

    assert.stub(vim_cmd_stub).was_not_called()
  end)
end)

describe("markdown.follow_external_link", function()
  local get_current_line_stub
  local win_get_cursor_stub
  local vim_ui_open_stub

  before_each(function()
    get_current_line_stub = stub(vim.api, "nvim_get_current_line")
    vim_ui_open_stub = stub(vim.ui, "open")
    win_get_cursor_stub = stub(vim.api, "nvim_win_get_cursor")
  end)

  after_each(function()
    get_current_line_stub:revert()
    vim_ui_open_stub:revert()
    win_get_cursor_stub:revert()
  end)

  it("opens a single link on the line and does not fall through", function()
    get_current_line_stub.returns("[link](http://example.com)")
    win_get_cursor_stub.returns({ 1, 1 })

    assert(markdown.follow_external_link() == "")
    vim.wait(0) -- force async execution

    assert.stub(vim_ui_open_stub).was_called_with("http://example.com")
  end)

  it("opens a single link anywhere on the line regardless of cursor position and does not fall through", function()
    get_current_line_stub.returns("- hey check out this cool [link](http://example.com)")
    win_get_cursor_stub.returns({ 1, 1 }) -- cursor is not on the link
    
    assert(markdown.follow_external_link() == "")
    vim.wait(0) -- force async execution

    assert.stub(vim_ui_open_stub).was_called_with("http://example.com")
  end)

  it("opens a link under the cursor if there are multiple links on the line and does not fall through", function()
    get_current_line_stub.returns("- here are some neat links: [link1](http://example1.com) and [link2](http://example2.com)")
    win_get_cursor_stub.returns({ 1, 30 }) -- cursor is on link1
    
    assert(markdown.follow_external_link() == "")
    vim.wait(0) -- force async execution

    assert.stub(vim_ui_open_stub).was_called_with("http://example1.com")
  end)

  it("passes on to the next handler if there are no links", function()
    get_current_line_stub.returns("No links here")
    win_get_cursor_stub.returns({ 1, 1 })

    assert(markdown.follow_external_link() == config.options.markdown.follow_external_link_keybind)
    vim.wait(0) -- force async execution

    assert.stub(vim_ui_open_stub).was_not_called()
  end)

  it("passes on to the next handler if there are multiple links and the cursor is not on one of them", function()
    get_current_line_stub.returns("- here are some neat links: [link1](http://example1.com) and [link2](http://example2.com)")
    win_get_cursor_stub.returns({ 1, 1 })
    
    assert(markdown.follow_external_link() == config.options.markdown.follow_external_link_keybind)
    vim.wait(0) -- force async execution

    assert.stub(vim_ui_open_stub).was_not_called()
  end)
end)

-- describe("markdown.install", function()
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
--     it("sets keybind for toggling checkboxes", function()
--       markdown.install()
--       assert.stub(keymap_set_stub).was_called_with("n", "<C-Space>", markdown.toggle_check, {
--         noremap = true,
--         silent = true,
--         desc = "Bujo: Toggle checkbox state",
--       })
--     end)
--
--     it("sets keybind for following journal links", function()
--       markdown.install()
--
--       assert.stub(keymap_set_stub).was_called_with("n", "<M-CR>", markdown.follow_journal_link, {
--         expr = true,
--         noremap = true,
--         silent = true,
--         desc = "Bujo: Follow journal link",
--       })
--     end)
--
--     it("sets keybind for following external links", function()
--       markdown.install()
--
--       assert.stub(keymap_set_stub).was_called_with("n", "gx", markdown.follow_external_link, {
--         expr = true,
--         noremap = true,
--         silent = true,
--         desc = "Bujo: Follow external link in default system handler",
--       })
--     end)
--   end)
--
--   describe("overriding keybinds", function()
--     it("sets keybind for toggling checkboxes", function()
--       config.options.markdown.toggle_check_keybind = "<leader>tc"
--       markdown.install()
--       assert.stub(keymap_set_stub).was_called_with("n", "<leader>tc", markdown.toggle_check, {
--         noremap = true,
--         silent = true,
--         desc = "Bujo: Toggle checkbox state",
--       })
--     end)
--
--     it("sets keybind for following journal links", function()
--       config.options.markdown.follow_journal_link_keybind = "<leader>fj"
--       markdown.install()
--
--       assert.stub(keymap_set_stub).was_called_with("n", "<leader>fj", markdown.follow_journal_link, {
--         expr = true,
--         noremap = true,
--         silent = true,
--         desc = "Bujo: Follow journal link",
--       })
--     end)
--
--     it("sets keybind for following external links", function()
--       config.options.markdown.follow_external_link_keybind = "<leader>fe"
--       markdown.install()
--
--       assert.stub(keymap_set_stub).was_called_with("n", "<leader>fe", markdown.follow_external_link, {
--         expr = true,
--         noremap = true,
--         silent = true,
--         desc = "Bujo: Follow external link in default system handler",
--       })
--     end)
--   end)
--
--   describe("disabling keybinds", function()
--     it("does not set keybind for toggling checkboxes", function()
--       config.options.markdown.toggle_check_keybind = false
--       markdown.install()
--       assert.stub(keymap_set_stub).was_not_called_with("n", _, markdown.toggle_check, _)
--     end)
--
--     it("does not set keybind for following journal links", function()
--       config.options.markdown.follow_journal_link_keybind = false
--       markdown.install()
--       assert.stub(keymap_set_stub).was_not_called_with("n", _, markdown.follow_journal_link, _)
--     end)
--
--     it("does not set keybind for following external links", function()
--       config.options.markdown.follow_external_link_keybind = false
--       markdown.install()
--       assert.stub(keymap_set_stub).was_not_called_with("n", _, markdown.follow_external_link, _)
--     end)
--   end)
-- end)
