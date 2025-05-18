local M = {}

local url_encode_string = function(str)
  -- Define the characters that need to be encoded
  local function encode_char(c)
    local h = string.format("%x", string.byte(c))
    if #h == 1 then
      h = "0" .. h
    end
    return "%" .. string.upper(h)
  end

  -- Loop through and encode characters
  return str:gsub("([^%w%-%_%.%~%s])",
    function(c)
      if c == " " then
        return "+"
      else
        return encode_char(c)
      end
    end
  ):gsub(" ", "+")
end

M.get_link_text = function(header_text)
  -- replace space with dash
  local link_text = string.gsub(header_text, " ", "-")

  -- remove brackets
  link_text = string.gsub(link_text, "%[", "")
  link_text = string.gsub(link_text, "%]", "")
  link_text = string.gsub(link_text, "%(", "")
  link_text = string.gsub(link_text, "%)", "")
  link_text = string.gsub(link_text, "%{", "")
  link_text = string.gsub(link_text, "%}", "")
  link_text = string.gsub(link_text, "%<", "")
  link_text = string.gsub(link_text, "%>", "")

  -- change to lowercase
  link_text = string.lower(link_text)

  -- apply URL encoding
  link_text = url_encode_string(link_text)

  return link_text
end

return M
