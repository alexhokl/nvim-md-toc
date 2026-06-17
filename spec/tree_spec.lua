package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local tree = require("nvim-md-toc.lib.tree")

--- Create a scratch buffer, fill it with lines, set filetype to markdown
--- so the Tree-sitter markdown parser attaches, and make it current.
--- Returns the buffer number.
local function make_buf(lines)
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_current_buf(bufnr)
  vim.bo[bufnr].filetype = "markdown"
  return bufnr
end

--- Delete a buffer to avoid state leaking between tests.
local function del_buf(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
end

-- ---------------------------------------------------------------------------
-- tree.get_headers()
-- ---------------------------------------------------------------------------

describe("tree.get_headers()", function()

  describe("empty buffer", function()
    local bufnr
    before_each(function() bufnr = make_buf({}) end)
    after_each(function() del_buf(bufnr) end)

    it("returns an empty table", function()
      assert.are.same({}, tree.get_headers(6))
    end)
  end)

  describe("buffer with no headings (plain paragraphs)", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({ "Just a paragraph.", "", "Another paragraph." })
    end)
    after_each(function() del_buf(bufnr) end)

    it("returns an empty table", function()
      assert.are.same({}, tree.get_headers(6))
    end)
  end)

  describe("single H1", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({ "# Introduction" })
    end)
    after_each(function() del_buf(bufnr) end)

    it("returns one entry", function()
      local result = tree.get_headers(6)
      assert.are.equal(1, #result)
    end)

    it("level is 1", function()
      local result = tree.get_headers(6)
      assert.are.equal(1, result[1].level)
    end)

    it("text is the heading content without the marker", function()
      local result = tree.get_headers(6)
      assert.are.equal("Introduction", result[1].text)
    end)
  end)

  describe("level filtering", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({
        "# H1",
        "## H2",
        "### H3",
        "#### H4",
      })
    end)
    after_each(function() del_buf(bufnr) end)

    it("level=1 returns only H1", function()
      local result = tree.get_headers(1)
      assert.are.equal(1, #result)
      assert.are.equal(1, result[1].level)
    end)

    it("level=2 returns H1 and H2", function()
      local result = tree.get_headers(2)
      assert.are.equal(2, #result)
    end)

    it("level=3 returns H1, H2, H3", function()
      local result = tree.get_headers(3)
      assert.are.equal(3, #result)
    end)

    it("level=6 returns all four headings", function()
      local result = tree.get_headers(6)
      assert.are.equal(4, #result)
    end)
  end)

  describe("multiple headings in document order", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({
        "# Alpha",
        "",
        "## Beta",
        "",
        "# Gamma",
      })
    end)
    after_each(function() del_buf(bufnr) end)

    it("returns headings in document order", function()
      local result = tree.get_headers(6)
      assert.are.equal(3, #result)
      assert.are.equal("Alpha", result[1].text)
      assert.are.equal("Beta",  result[2].text)
      assert.are.equal("Gamma", result[3].text)
    end)

    it("levels are correct", function()
      local result = tree.get_headers(6)
      assert.are.equal(1, result[1].level)
      assert.are.equal(2, result[2].level)
      assert.are.equal(1, result[3].level)
    end)
  end)

  describe("heading text with trailing whitespace stripped", function()
    local bufnr
    before_each(function()
      -- vim.trim is applied to the text in tree.lua
      bufnr = make_buf({ "# Section  " })
    end)
    after_each(function() del_buf(bufnr) end)

    it("trims trailing whitespace from heading text", function()
      local result = tree.get_headers(6)
      assert.are.equal("Section", result[1].text)
    end)
  end)

end)

-- ---------------------------------------------------------------------------
-- tree.has_thematic_break()
-- ---------------------------------------------------------------------------

describe("tree.has_thematic_break()", function()

  describe("buffer with no thematic break", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({ "# Title", "", "Some content." })
    end)
    after_each(function() del_buf(bufnr) end)

    it("returns false", function()
      assert.is_false(tree.has_thematic_break())
    end)
  end)

  describe("buffer with the plugin's default separator (____)", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({ "____", "# Title" })
    end)
    after_each(function() del_buf(bufnr) end)

    it("returns true", function()
      assert.is_true(tree.has_thematic_break())
    end)
  end)

  -- Documents the known quirk: any standard Markdown HR is treated as a
  -- TOC boundary, not just the plugin's own ____ separator.
  describe("standard Markdown thematic breaks (known quirk)", function()
    it("--- is detected as a thematic break", function()
      local bufnr = make_buf({ "---", "# Title" })
      assert.is_true(tree.has_thematic_break())
      del_buf(bufnr)
    end)

    it("*** is detected as a thematic break", function()
      local bufnr = make_buf({ "***", "# Title" })
      assert.is_true(tree.has_thematic_break())
      del_buf(bufnr)
    end)

    it("___ is detected as a thematic break", function()
      local bufnr = make_buf({ "___", "# Title" })
      assert.is_true(tree.has_thematic_break())
      del_buf(bufnr)
    end)
  end)

end)

-- ---------------------------------------------------------------------------
-- tree.first_thematic_break_location()
-- ---------------------------------------------------------------------------

describe("tree.first_thematic_break_location()", function()

  describe("buffer with no thematic break", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({ "# Title", "Content" })
    end)
    after_each(function() del_buf(bufnr) end)

    it("returns 0 as the fallback", function()
      assert.are.equal(0, tree.first_thematic_break_location())
    end)
  end)

  describe("thematic break on the first line (row 0)", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({ "____", "# Title" })
    end)
    after_each(function() del_buf(bufnr) end)

    it("returns 0-indexed row 0", function()
      assert.are.equal(0, tree.first_thematic_break_location())
    end)
  end)

  describe("thematic break further down the buffer", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({
        "- [Title](#title)",
        "____",
        "# Title",
        "Content",
      })
    end)
    after_each(function() del_buf(bufnr) end)

    it("returns 0-indexed row 1", function()
      assert.are.equal(1, tree.first_thematic_break_location())
    end)
  end)

  describe("multiple thematic breaks — returns the first", function()
    local bufnr
    before_each(function()
      bufnr = make_buf({
        "____",
        "# Title",
        "---",
        "Content",
      })
    end)
    after_each(function() del_buf(bufnr) end)

    it("returns row 0, not row 2", function()
      assert.are.equal(0, tree.first_thematic_break_location())
    end)
  end)

end)
