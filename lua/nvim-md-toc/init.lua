local M = {}

local tree = require("nvim-md-toc.lib.tree")
local cursor = require("nvim-md-toc.lib.cursor")
local toc = require("nvim-md-toc.lib.toc")

local default_options = {
  -- Keymap to create or update the table of contents
  keymap = "<leader>rm",
  temporary_register = "v",
  themeatic_break = "____",
  level = 3,
}

local delete_all_lines_above = function(row)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(bufnr, 0, row, true, {})
end

local refresh_toc_with_config = function(level, themeatic_break, temporary_register)
  local headers = tree.get_headers(level)
  local toc_lines = toc.create_toc_from_headers(headers)

  -- register the current cursor position to register "v"
  cursor.store_cursor_position(temporary_register)

  if tree.has_thematic_break() then
    local row = tree.first_thematic_break_location()
    -- delete all lines above the thematic break
    delete_all_lines_above(row + 1)
  else
    -- add themeatic break to before the first line
    vim.api.nvim_buf_set_lines(0, 0, 0, false, { themeatic_break })
  end

  -- add the table of contents
  table.insert(toc_lines, themeatic_break)
  vim.api.nvim_buf_set_lines(0, 0, 0, false, toc_lines)

  cursor.restore_cursor_position(temporary_register)
end

M.refresh_toc = function(level)
  refresh_toc_with_config(
    level or M.options.level,
    M.options.themeatic_break,
    M.options.temporary_register)
end

M.setup = function(options)
  local map = function(mode, keys, action, desc)
    vim.keymap.set(mode, keys, action, { desc = desc, silent = true, noremap = true })
  end

  M.options = vim.tbl_deep_extend("force", default_options, options or {})
  local call = function()
    refresh_toc_with_config(
      M.options.level,
      M.options.themeatic_break,
      M.options.temporary_register)
  end
  map("n", M.options.keymap, call, "Refresh table of contents")
end

return M
