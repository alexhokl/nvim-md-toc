package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local stub = require("luassert.stub")

local cursor = require("nvim-md-toc.lib.cursor")

describe("cursor.store_cursor_position()", function()

  it("reads the cursor from window 0 and writes 'row:col' to the named register", function()
    local get_stub = stub(vim.api, "nvim_win_get_cursor")
    local set_reg_stub = stub(vim.fn, "setreg")
    get_stub.returns({ 5, 3 })

    cursor.store_cursor_position("v")

    assert.stub(get_stub).was_called_with(0)
    assert.stub(set_reg_stub).was_called_with("v", "5:3")

    get_stub:revert()
    set_reg_stub:revert()
  end)

  it("uses the register name that was passed in", function()
    local get_stub = stub(vim.api, "nvim_win_get_cursor")
    local set_reg_stub = stub(vim.fn, "setreg")
    get_stub.returns({ 1, 0 })

    cursor.store_cursor_position("z")

    assert.stub(set_reg_stub).was_called_with("z", "1:0")

    get_stub:revert()
    set_reg_stub:revert()
  end)

end)

describe("cursor.restore_cursor_position()", function()

  it("reads the register and calls nvim_win_set_cursor with the correct numbers", function()
    local get_reg_stub = stub(vim.fn, "getreg")
    local set_cursor_stub = stub(vim.api, "nvim_win_set_cursor")
    get_reg_stub.returns("7:12")

    cursor.restore_cursor_position("v")

    assert.stub(get_reg_stub).was_called_with("v")
    assert.stub(set_cursor_stub).was_called_with(0, { 7, 12 })

    get_reg_stub:revert()
    set_cursor_stub:revert()
  end)

  it("is a no-op when the register is empty", function()
    local get_reg_stub = stub(vim.fn, "getreg")
    local set_cursor_stub = stub(vim.api, "nvim_win_set_cursor")
    get_reg_stub.returns("")

    cursor.restore_cursor_position("v")

    assert.stub(set_cursor_stub).was_not_called()

    get_reg_stub:revert()
    set_cursor_stub:revert()
  end)

  it("is a no-op when the register contains malformed content", function()
    local get_reg_stub = stub(vim.fn, "getreg")
    local set_cursor_stub = stub(vim.api, "nvim_win_set_cursor")
    get_reg_stub.returns("not-a-position")

    cursor.restore_cursor_position("v")

    assert.stub(set_cursor_stub).was_not_called()

    get_reg_stub:revert()
    set_cursor_stub:revert()
  end)

  it("uses the register name passed in", function()
    local get_reg_stub = stub(vim.fn, "getreg")
    local set_cursor_stub = stub(vim.api, "nvim_win_set_cursor")
    get_reg_stub.returns("2:4")

    cursor.restore_cursor_position("z")

    assert.stub(get_reg_stub).was_called_with("z")

    get_reg_stub:revert()
    set_cursor_stub:revert()
  end)

  it("restores row 1 col 0 correctly", function()
    local get_reg_stub = stub(vim.fn, "getreg")
    local set_cursor_stub = stub(vim.api, "nvim_win_set_cursor")
    get_reg_stub.returns("1:0")

    cursor.restore_cursor_position("v")

    assert.stub(set_cursor_stub).was_called_with(0, { 1, 0 })

    get_reg_stub:revert()
    set_cursor_stub:revert()
  end)

end)
