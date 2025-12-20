Plugin_path = os.getenv("HOME") .. "/.local/state/yazi/yacd/"

---@type file* | nil
History_file = nil

--- Returns state[key]
local get_state = ya.sync(function(state, key)
  return state[key]
end)

--- Sets state[key] to value
local set_state = ya.sync(function(state, key, value)
  state[key] = value
end)

--- Merges the current state[key] with value, value takes precedence
local merge_state = ya.sync(function(state, key, value)
  local current = state[key]

  if type(current) ~= "table" then
    current = {}
    state[key] = current
  end

  for k, v in pairs(value) do
    current[k] = v
  end
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

--- Returns deserialized 1-depth string table, nil on error
local deserialize = function(str)
  if str == nil then return nil end
  local tbl = {}
  for pair in str:gmatch("[^\n]+") do
    local k, v = pair:match("([^=]+)=(.+)")
    if not k or not v then
      return nil       -- invalid format, return nil immediately
    end
    tbl[k] = v
  end
  return tbl
end

--- Returns serialized 1-depth string table as a string
local serialize = function(tbl)
  local parts = {}
  for k, v in pairs(tbl) do
    parts[#parts + 1] = k .. "=" .. v
  end
  return table.concat(parts, "\n")
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

--- Requests a popup key to retrieve a mark, then `cd`s to it.
local goto_mark = function(state)
  local all_cands = {}

  for index = string.byte('a'), string.byte('z') do
    local letter = string.char(index)
    table.insert(all_cands, { on = letter, desc = get_state("marks")[letter] or "(unset)" })
  end

  table.insert(all_cands, { on = "'", desc = get_state("marks")["'"] or "(unset)" })

  ---@type integer
  local cand = ya.which {
    cands = all_cands,
    silent = false,
  }

  if cand == nil then return end
  local letter = all_cands[cand].on or nil
  if letter == nil then return end

  local target_dir = get_state("marks")[letter]

  if letter == "'" then
    merge_state("marks", { ["'"] = get_cwd() })
  end

  ya.emit("cd", { target_dir })
end

--- Requests a popup key to set a mark.
local set_mark = function()
  local all_cands = {}

  for index = string.byte('a'), string.byte('z') do
    local letter = string.char(index)
    table.insert(all_cands, { on = letter, desc = get_state("marks")[letter] or "(unset)" })
  end

  ---@type integer
  local cand = ya.which {
    cands = all_cands,
    silent = false,
  }

  if cand == nil then return end
  local letter = all_cands[cand].on or nil
  if letter == nil then return end

  merge_state("marks", { [letter] = get_cwd() })
end

--- Table of actions, because Lua doesn't believe in syntactical switch/case statements.
local actions = {
  ["clipboard"] = cd_clipboard,

  ["goto_mark"] = goto_mark,

  ["set_mark"] = set_mark,

  default = nil
}


--- Callback function for all "cd" events.
--- This function will log the new directory after a JUMP (not enters/leaves) occurs
--- and swap the last cwd with the alt directory
local on_cd = function(args)
  local cwd = get_cwd()
  local last_cwd = get_state("last_cwd") or cwd
  if args.source == "cd" then
    merge_state("marks", { ["'"] = last_cwd })

    if History_file then
      History_file:write(cwd .. "\n")
    end
  end
  set_state("last_cwd", cwd)
  return args
end

--- Stuff to run when plugin is set up
local on_start = function()
  -- ensure directory exists
  os.execute("mkdir -p " .. Plugin_path)

  -- TODO: find a way to get the startup/initial cwd
  set_state("marks", { ["'"] = "~" })

  local history_file_raw, err = io.open(Plugin_path .. "/history", "a+")
  History_file = history_file_raw or nil

  local marks_file, _ = io.open(Plugin_path .. "/marks.txt", "r")
  if marks_file then
    local content = marks_file:read("*a")

    local marks_table = deserialize(content)
    if marks_table then
      set_state("marks", marks_table)
    end
    marks_file:close()
  end
end

--- Stuff to run when Yazi exits
local on_exit = function(args)
  if History_file then
    History_file:close()
  end

  local marks_file, _ = io.open(Plugin_path .. "/marks.txt", "w+")
  if marks_file then
    marks_file:write(serialize(get_state("marks")))
    marks_file:close()
  end

  return args
end

return {
  setup = function()
    -- Set up callback functions
    ps.sub("ind-stash", on_cd)
    ps.sub("relay-stash", on_cd)
    ps.sub("key-quit", on_exit)

    on_start()
  end,

  entry = function(state, job)
    local cmd = job.args[1]
    local action = actions[cmd] or actions.default
    if action then
      action(state)
    end
  end
}
