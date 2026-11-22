local M = {}

local url = require("nvim-md-toc.lib.url")

local default_bullet_markers = {
  [1] = "-",
  [2] = "  *",
  [3] = "    +",
  [4] = "      +",
  [5] = "        +",
  [6] = "          +",
}

local create_link = function(header_text, count)
  local link_text = url.get_link_text(header_text)
  if count == 0 then
    return "[" .. header_text .. "](#" .. link_text .. ")"
  else
    return "[" .. header_text .. "](#" .. link_text .. "-" .. count .. ")"
  end
end

M.create_toc_from_headers = function(headers)
  -- count by link slug (not raw text) since anchors are lowercased and
  -- stripped, so "How old" and "how old" collide
  local slug_count = {}
  local lines = {}
  for _, header in pairs(headers) do
    local slug = url.get_link_text(header.text)
    local count = slug_count[slug] or 0
    slug_count[slug] = count + 1
    table.insert(lines,
      default_bullet_markers[header.level] .. " " .. create_link(header.text, count))
  end
  return lines
end

return M
