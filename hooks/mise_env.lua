local cmd = require("cmd")
local file = require("file")
local strings = require("strings")

local function is_windows()
  return package.config:sub(1, 1) == "\\"
end

local function shell_quote(value)
  local str = tostring(value)
  if is_windows() then
    str = str:gsub('"', '\\"')
    return '"' .. str .. '"'
  end
  str = str:gsub("'", "'\"'\"'")
  return "'" .. str .. "'"
end

local function chomp(value)
  if value == nil then
    return ""
  end
  return (value:gsub("\r?\n$", ""))
end

local function strip_quotes(value)
  if value == nil then
    return ""
  end

  if #value >= 2 then
    local first = value:sub(1, 1)
    local last = value:sub(-1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
      value = value:sub(2, -2)
      if first == '"' then
        value = value:gsub("\\n", "\n")
        value = value:gsub("\\r", "\r")
        value = value:gsub("\\t", "\t")
        value = value:gsub('\\"', '"')
        value = value:gsub("\\\\", "\\")
      end
    end
  end

  return value
end

local function parse_env(content)
  local env = {}
  for line in content:gmatch("[^\r\n]+") do
    local trimmed = strings.trim_space(line)
    if trimmed ~= "" and not strings.has_prefix(trimmed, "#") then
      if strings.has_prefix(trimmed, "export ") then
        trimmed = strings.trim_space(trimmed:sub(8))
      end

      local eq = trimmed:find("=", 1, true)
      if eq ~= nil then
        local key = strings.trim_space(trimmed:sub(1, eq - 1))
        local value = trimmed:sub(eq + 1)
        value = strings.trim_space(value)
        value = strip_quotes(value)
        if key ~= "" then
          table.insert(env, { key = key, value = value })
        end
      end
    end
  end
  return env
end

local function resolve_env_file(op_bin, path)
  local cmdline = op_bin .. " inject --in-file " .. shell_quote(path)
  local output = cmd.exec(cmdline)
  if output == nil then
    return ""
  end
  return output
end

local function resolve_var(op_bin, value)
  if type(value) ~= "string" then
    return tostring(value)
  end

  if strings.has_prefix(value, "op://") then
    local cmdline = op_bin .. " read " .. shell_quote(value)
    return chomp(cmd.exec(cmdline))
  end

  return value
end

local function upsert(env_entries, env_index, key, value)
  local idx = env_index[key]
  if idx then
    env_entries[idx].value = value
    return
  end

  env_entries[#env_entries + 1] = { key = key, value = value }
  env_index[key] = #env_entries
end

function PLUGIN:MiseEnv(ctx)
  local options = ctx.options or {}
  local op_bin = options.op_bin or "op"
  local env_entries = {}
  local env_index = {}
  local watch_files = {}

  local env_files = {}
  if type(options.env_files) == "table" then
    for _, path in ipairs(options.env_files) do
      table.insert(env_files, path)
    end
  elseif options.env_file then
    table.insert(env_files, options.env_file)
  else
    table.insert(env_files, ".env.op")
  end

  local require_env_file = options.require_env_file == true
  for _, path in ipairs(env_files) do
    if file.exists(path) then
      local resolved = resolve_env_file(op_bin, path)
      for _, kv in ipairs(parse_env(resolved)) do
        upsert(env_entries, env_index, kv.key, kv.value)
      end
      table.insert(watch_files, path)
    elseif require_env_file then
      error("env_file not found: " .. path)
    end
  end

  if type(options.vars) == "table" then
    for key, value in pairs(options.vars) do
      upsert(env_entries, env_index, key, resolve_var(op_bin, value))
    end
  end

  if options.cache == nil or options.cache == true then
    return {
      cacheable = true,
      watch_files = watch_files,
      env = env_entries,
    }
  end

  return env_entries
end
