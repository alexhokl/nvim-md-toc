package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local toc = require("nvim-md-toc.lib.toc")

-- Convenience: build a header table from a flat list of {level, text} pairs.
local function headers(list)
  local result = {}
  for _, item in ipairs(list) do
    result[#result + 1] = { level = item[1], text = item[2] }
  end
  return result
end

describe("toc.create_toc_from_headers()", function()

  describe("empty input", function()
    it("returns an empty table", function()
      assert.are.same({}, toc.create_toc_from_headers({}))
    end)
  end)

  describe("single heading", function()
    it("H1 produces a '-' bullet", function()
      local lines = toc.create_toc_from_headers(headers({ { 1, "Introduction" } }))
      assert.are.equal(1, #lines)
      assert.are.equal("- [Introduction](#introduction)", lines[1])
    end)

    it("H2 produces a '  *' bullet", function()
      local lines = toc.create_toc_from_headers(headers({ { 2, "Background" } }))
      assert.are.equal("  * [Background](#background)", lines[1])
    end)

    it("H3 produces a '    +' bullet", function()
      local lines = toc.create_toc_from_headers(headers({ { 3, "Details" } }))
      assert.are.equal("    + [Details](#details)", lines[1])
    end)

    it("H4 produces a '      +' bullet", function()
      local lines = toc.create_toc_from_headers(headers({ { 4, "Sub" } }))
      assert.are.equal("      + [Sub](#sub)", lines[1])
    end)

    it("H5 produces a '        +' bullet", function()
      local lines = toc.create_toc_from_headers(headers({ { 5, "Deep" } }))
      assert.are.equal("        + [Deep](#deep)", lines[1])
    end)

    it("H6 produces a '          +' bullet", function()
      local lines = toc.create_toc_from_headers(headers({ { 6, "Deepest" } }))
      assert.are.equal("          + [Deepest](#deepest)", lines[1])
    end)
  end)

  describe("multiple headings at different levels", function()
    local lines

    before_each(function()
      lines = toc.create_toc_from_headers(headers({
        { 1, "Top" },
        { 2, "Middle" },
        { 3, "Leaf" },
      }))
    end)

    it("produces three lines", function()
      assert.are.equal(3, #lines)
    end)

    it("H1 line is correct", function()
      assert.are.equal("- [Top](#top)", lines[1])
    end)

    it("H2 line is correct", function()
      assert.are.equal("  * [Middle](#middle)", lines[2])
    end)

    it("H3 line is correct", function()
      assert.are.equal("    + [Leaf](#leaf)", lines[3])
    end)
  end)

  describe("link text derivation", function()
    it("header with spaces produces dash-separated anchor", function()
      local lines = toc.create_toc_from_headers(headers({ { 1, "My Section" } }))
      assert.are.equal("- [My Section](#my-section)", lines[1])
    end)

    it("header text is preserved as-is in the label", function()
      local lines = toc.create_toc_from_headers(headers({ { 1, "Hello World" } }))
      -- label part preserves original case; anchor is lowercased
      -- Use plain=true (4th arg) to avoid treating [ and ] as pattern chars.
      assert.is_not_nil(lines[1]:find("[Hello World]", 1, true))
    end)
  end)

  describe("duplicate heading deduplication", function()
    local lines

    before_each(function()
      lines = toc.create_toc_from_headers(headers({
        { 1, "Same" },
        { 1, "Same" },
        { 1, "Same" },
      }))
    end)

    it("produces three lines", function()
      assert.are.equal(3, #lines)
    end)

    it("first occurrence has no numeric suffix", function()
      assert.are.equal("- [Same](#same)", lines[1])
    end)

    -- NOTE: off-by-one in counter: first duplicate gets -1 (not -2).
    it("second occurrence gets '-1' suffix", function()
      assert.are.equal("- [Same](#same-1)", lines[2])
    end)

    it("third occurrence gets '-2' suffix", function()
      assert.are.equal("- [Same](#same-2)", lines[3])
    end)
  end)

  describe("unique headings never get a suffix", function()
    it("two different headings have no numeric suffix", function()
      local lines = toc.create_toc_from_headers(headers({
        { 1, "Alpha" },
        { 1, "Beta" },
      }))
      assert.are.equal("- [Alpha](#alpha)", lines[1])
      assert.are.equal("- [Beta](#beta)", lines[2])
    end)
  end)

  describe("ordering preserved", function()
    it("output order matches input order", function()
      local lines = toc.create_toc_from_headers(headers({
        { 1, "First" },
        { 2, "Second" },
        { 1, "Third" },
      }))
      assert.are.equal(3, #lines)
      assert.is_not_nil(lines[1]:find("First", 1, true))
      assert.is_not_nil(lines[2]:find("Second", 1, true))
      assert.is_not_nil(lines[3]:find("Third", 1, true))
    end)
  end)

end)
