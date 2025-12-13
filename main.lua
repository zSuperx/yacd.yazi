Plugin_path = os.getenv("HOME") .. "/.local/state/yazi/cd-plus/"

local get_state = ya.sync(function(state, key)
  return state[key]
end)

local set_state = ya.sync(function(state, key, value)
  state[key] = value
end)

--- Uses Yazi's sync runtime to obtain the cwd
local get_cwd = ya.sync(function()
  return tostring(cx.active.current.cwd)
end)

--- Trims the string s to length, adding "..." if needed
---@param s string
---@param length integer
---@return string
local trim = function(s, length)
  s = string.gsub(s, "[\n\t\r]", " ")
  if string.len(s) <= length then
    return s
  else
    return string.sub(s, 0, length - 2) .. "..."
  end
end

--- Performs "cd" within Yazi. This will verify the path exists. Errors otherwise.
---@param path_raw string
---@return string | nil path_final
---@return string | nil error
local cd = function(path_raw)
  -- Obtain file information
  local url = Url(path_raw)
  local cha, err = fs.cha(url)

  if err ~= nil then
    -- Handle error thrown by fs.cha()
    return nil, err
  else
    -- Check if path_raw is a directory
    -- If so, then use that as the path_final
    -- Otherwise, use everything up to and includng the last '/' as the path
    local path_final
    if cha.is_dir then
      path_final = path_raw
    else
      path_final = string.match(path_raw, "^(.*/).+$")
    end

    ya.emit("cd", { path_final })
    return path_final, nil
  end
end

--- Attempts to "cd" to the contents of Yazi's clipboard
local cd_clipboard = function()
  -- Get clipboard contents and strip leading and trailing whitespace
  -- since Yazi's copy path feature appends a space to the end
  local clipboard = string.gsub(ya.clipboard(), '^%s*(.-)%s*$', '%1')

  local _, err = cd(clipboard)
  if err ~= nil then
    ya.notify {
      title = "cd-paste: ERROR",
      content = "Clipboard doesn't seem to contain a path: `" .. trim(clipboard, 50) .. "`",
      level = "info",
      timeout = 5,
    }
  end
end

--- Attempts to "cd" to the swap directory, while also setting it to the previous cwd
local cd_swap = function(state)
  local alt = get_state("alt_cwd")
  set_state("alt_cwd", get_cwd())
  ya.emit("cd", { alt })
end


--- Table of actions, because Lua doesn't believe in syntactical switch/case statements.
local actions = {
  ["clipboard"] = cd_clipboard,

  ["swap"] = cd_swap,

  default = nil
}


--- Callback function for all "cd" events.
--- This function will log the new directory after a JUMP (not enters/leaves) occurs
--- and swap the last cwd with the alt directory
local handler = function(args)
  local cwd = get_cwd()
  local last_cwd = get_state("last_cwd") or cwd
  if args.source == "cd" then
    set_state("alt_cwd", last_cwd)

    local history_file, err = io.open(Plugin_path .. "/history", "w+")
    if history_file then
      history_file:write(cwd .. "\n")
      history_file:close()
    else
      ya.err("Could not open file:", err)
    end
  end
  set_state("last_cwd", cwd)
  return args
end

return {
  setup = function()
    -- ensure directory exists
    os.execute("mkdir -p " .. Plugin_path)

    ps.sub("ind-stash", handler)
    ps.sub("relay-stash", handler)

    -- TODO: find a way to get the startup/initial cwd
    set_state("alt_cwd", "~")
  end,

  entry = function(state, job)
    local cmd = job.args[1]
    local action = actions[cmd] or actions.default
    if action then
      action(state)
    end
  end
}
