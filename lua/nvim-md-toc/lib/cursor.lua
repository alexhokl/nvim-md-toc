local M = {}

M.store_cursor_position = function(register)
  local row, column = unpack(vim.api.nvim_win_get_cursor(0))
  vim.fn.setreg(register, string.format("%d:%d", row, column))
end

M.restore_cursor_position = function(register)
  local cursor_position = vim.fn.getreg(register)
  if cursor_position == "" then
    return
  end
  local row, column = string.match(cursor_position, "(%d+):(%d+)")
  if row == nil or column == nil then
    return
  end
  vim.api.nvim_win_set_cursor(0, { tonumber(row), tonumber(column) })
end

return M
