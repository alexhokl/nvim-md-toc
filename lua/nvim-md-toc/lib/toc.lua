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
  local header_text_count = {}
  local lines = {}
  for _, header in pairs(headers) do
    if header_text_count[header.text] == nil then
      header_text_count[header.text] = 1
      table.insert(lines,
        default_bullet_markers[header.level] .. " " .. create_link(header.text, 0))
    else
      table.insert(lines,
        default_bullet_markers[header.level] ..
        " " .. create_link(header.text, header_text_count[header.text]))
      header_text_count[header.text] = header_text_count[header.text] + 1
    end
  end
  return lines
end

return M
