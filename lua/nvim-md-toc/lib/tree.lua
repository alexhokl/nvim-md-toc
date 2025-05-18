local M = {}

local themeatic_break_query = [[
  (thematic_break) @thematic_break
]]

local header_query = [[
  (atx_heading) @header
]]

local get_level_and_text_from_header = function(header_node)
  local full_text = vim.treesitter.get_node_text(header_node, 0)
  local space_start_index, _, _ = string.find(full_text, " ")
  if space_start_index == nil then
    return 0, ""
  end
  local level = space_start_index - 1
  local text = string.sub(full_text, space_start_index + 1)
  return level, text
end

M.get_headers = function(level)
  local headers = {}

  -- root node of the current buffer
  local root_node = vim.treesitter.get_parser():parse()[1]:root()
  local query_header = vim.treesitter.query.parse('markdown', header_query)

  for _, header_node, _ in query_header:iter_captures(root_node, 0) do
    local item_level, text = get_level_and_text_from_header(header_node)
    if (item_level <= level) then
      -- append to headers
      headers[#headers + 1] = { level = item_level, text = text }
    end
  end

  return headers
end

M.has_thematic_break = function()
  local root_node = vim.treesitter.get_parser():parse()[1]:root()
  local query_thematic_break = vim.treesitter.query.parse('markdown', themeatic_break_query)
  for _, _, _ in query_thematic_break:iter_captures(root_node, 0) do
    return true
  end
  return false
end

M.first_thematic_break_location = function()
  local root_node = vim.treesitter.get_parser():parse()[1]:root()
  local query_thematic_break = vim.treesitter.query.parse('markdown', themeatic_break_query)
  for _, thematic_break_node, _ in query_thematic_break:iter_captures(root_node, 0) do
    local row, _, _ = thematic_break_node:start()
    return row
  end
  return 0
end

return M
