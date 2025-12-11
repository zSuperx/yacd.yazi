-- Helper function used only for notifications
local trim = function(s)
  s = string.gsub(s, "[\n\t\r]", " ")
  if string.len(s) <= 50 then
    return s
  else
    return string.sub(s, 0, 48) .. "..."
  end
end

return {
  entry = function()
    -- Get clipboard contents and strip leading and trailing whitespace
    -- since Yazi's copy feature appends a space to the end
    local clipboard = ya.clipboard()
    clipboard = string.gsub(clipboard, '^%s*(.-)%s*$', '%1')

    -- Obtain file information
    local url = Url(clipboard)
    local cha, err = fs.cha(url)

    if err ~= nil then
      -- Handle error thrown by fs.cha()
      ya.notify {
        title = "cd-paste: ERROR",
        content = "Clipboard doesn't seem to contain a path: `" .. trim(clipboard) .. "`",
        level = "info",
        timeout = 5,
      }
    else
      -- Check if clipboard contents contain a directory
      -- If so, then use that as the path
      -- Otherwise, use everything up to and includng the last '/' as the path
      local path
      if cha.is_dir then
        path = clipboard
      else
        path = string.match(clipboard, "^(.*/).+$")
      end

      ya.emit("cd", { path })
      ya.notify {
        title = "cd-paste:",
        content = "Going to: `" .. path .. "`",
        level = "info",
        timeout = 5,
      }
    end
  end
}
