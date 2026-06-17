-- Adjust package.path so the plugin modules resolve under nlua/busted.
-- nlua sets the cwd, but the Lua package path doesn't include the plugin's
-- lua/ directory by default.
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local url = require("nvim-md-toc.lib.url")

describe("url.get_link_text()", function()

  describe("spaces", function()
    it("replaces spaces with dashes", function()
      assert.are.equal("hello-world", url.get_link_text("Hello World"))
    end)

    it("handles multiple consecutive spaces", function()
      assert.are.equal("a--b", url.get_link_text("A  B"))
    end)
  end)

  describe("case normalisation", function()
    it("lowercases all ASCII letters", function()
      assert.are.equal("introduction", url.get_link_text("Introduction"))
    end)

    it("already-lowercase input is unchanged (modulo other transforms)", function()
      assert.are.equal("hello", url.get_link_text("hello"))
    end)

    it("mixed case is fully lowercased", function()
      assert.are.equal("my-section", url.get_link_text("My Section"))
    end)
  end)

  describe("bracket stripping", function()
    it("removes square brackets []", function()
      assert.are.equal("link-text", url.get_link_text("[Link] Text"))
    end)

    it("removes parentheses ()", function()
      assert.are.equal("text", url.get_link_text("(Text)"))
    end)

    it("removes curly braces {}", function()
      assert.are.equal("text", url.get_link_text("{Text}"))
    end)

    it("removes angle brackets <>", function()
      assert.are.equal("text", url.get_link_text("<Text>"))
    end)

    it("removes all bracket types in combination", function()
      assert.are.equal("foo-bar", url.get_link_text("[Foo] <Bar>"))
    end)
  end)

  describe("URL encoding", function()
    it("encodes ampersand as %26", function()
      assert.are.equal("foo-%26-bar", url.get_link_text("Foo & Bar"))
    end)

    it("encodes hash as %23", function()
      assert.are.equal("%23section", url.get_link_text("#Section"))
    end)

    it("leaves alphanumerics and hyphens unencoded", function()
      assert.are.equal("abc-123", url.get_link_text("abc 123"))
    end)

    it("leaves underscores unencoded", function()
      assert.are.equal("foo_bar", url.get_link_text("foo_bar"))
    end)

    it("leaves dots unencoded", function()
      assert.are.equal("v1.2.3", url.get_link_text("v1.2.3"))
    end)
  end)

  describe("empty and minimal input", function()
    it("returns empty string for empty input", function()
      assert.are.equal("", url.get_link_text(""))
    end)

    it("handles a single word", function()
      assert.are.equal("word", url.get_link_text("Word"))
    end)
  end)

  describe("combined transforms", function()
    it("applies all transforms in order: strip, lower, encode", function()
      -- "[Hello] & <World>"
      -- strip [] and <>  -> "Hello & World"
      -- spaces -> dashes -> "Hello-&-World"
      -- lowercase        -> "hello-&-world"
      -- encode &         -> "hello-%26-world"
      assert.are.equal("hello-%26-world", url.get_link_text("[Hello] & <World>"))
    end)
  end)

end)
