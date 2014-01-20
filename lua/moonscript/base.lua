local instance = SERVER and "gmsv_lpeg_" or "gmcl_lpeg_"
if system.IsWindows() then
	instance = instance .. "win32.dll"
elseif system.IsLinux() then
	instance = instance .. "linux.dll"
else
	instance = instance .. "osx.dll"
end

if file.Exists("lua/bin/" .. instance, "MOD") then
	require "lpeg"
else
	local errmsg = "LPeg library not installed"
	MsgC(Color(255,0,0), "MoonScript: " .. errmsg .. "\n")
	return errmsg
end

local compile = loadmodule("moonscript.compile")
local parse = loadmodule("moonscript.parse")
local concat, insert, remove
do
  local _obj_0 = table
  concat, insert, remove = _obj_0.concat, _obj_0.insert, _obj_0.remove
end
local split, dump, get_options, unpack
do
  local _obj_0 = loadmodule("moonscript.util")
  split, dump, get_options, unpack = _obj_0.split, _obj_0.dump, _obj_0.get_options, _obj_0.unpack
end
local lua = {
  loadstring = CompileString,
  load = nil,
}
local dirsep, line_tables, create_moonpath, to_lua, moon_loader, loadstring, loadfile, dofile, insert_loader, remove_loader
dirsep = "/"
line_tables = loadmodule("moonscript.line_tables")
create_moonpath = function(package_path)
  local paths = split(package_path, ";")
  for i, path in ipairs(paths) do
    local p = path:match("^(.-)%.lua$")
    if p then
      paths[i] = p .. ".moon"
    end
  end
  return concat(paths, ";")
end
to_lua = function(text, options)
  if options == nil then
    options = { }
  end
  if "string" ~= type(text) then
    local t = type(text)
    return nil, "expecting string (got " .. t .. ")", 2
  end
  local tree, err = parse.string(text)
  if not tree then
    return nil, err
  end
  local code, ltable, pos = compile.tree(tree, options)
  if not code then
    return nil, compile.format_error(ltable, pos, text), 2
  end
  return code, ltable
end
moon_loader = function(name)
  local name_path = name:gsub("%.", dirsep)
  local file_data, file_path
  local _list_0 = split(package.moonpath, ";")
  for _index_0 = 1, #_list_0 do
    local path = _list_0[_index_0]
    file_path = path:gsub("?", name_path)
    file_data = file.Read(file_path, "GAME")
    if file_data then
      break
    end
  end
  if file_data then
    local res, err = loadstring(file_data, file_path)
    if not res then
      error(err)
    end
    return res
  end
  return nil, "Could not find moon file"
end
loadstring = function(...)
  local options, str, chunk_name, mode, env = get_options(...)
  chunk_name = chunk_name or "=(moonscript.loadstring)"
  local code, ltable_or_err = to_lua(str, options)
  if not (code) then
    return nil, ltable_or_err
  end
  if chunk_name then
    line_tables[chunk_name] = ltable_or_err
  end
  --[[
  return (lua.loadstring or lua.load)(code, chunk_name, unpack({
    mode,
    env
  }))
  ]]--
  return lua.loadstring(code, chunk_name, false)
end
loadfile = function(fname, ...)
  local fdata, err = file.Read(fname, "GAME")
  if not fdata then
    return nil
  end
  return loadstring(fdata, fname, ...)
end
dofile = function(...)
  local f = assert(loadfile(...))
  return f()
end
insert_loader = function(pos)
  if pos == nil then
    pos = 2
  end
  if not package.moonpath then
    package.moonpath = create_moonpath(package.path)
  end
  local loaders = package.loaders or package.searchers
  for _index_0 = 1, #loaders do
    local loader = loaders[_index_0]
    if loader == moon_loader then
      return false
    end
  end
  insert(loaders, pos, moon_loader)
  return true
end
remove_loader = function()
  local loaders = package.loaders or package.searchers
  for i, loader in ipairs(loaders) do
    if loader == moon_loader then
      remove(loaders, i)
      return true
    end
  end
  return false
end
return {
  _NAME = "moonscript",
  insert_loader = insert_loader,
  remove_loader = remove_loader,
  to_lua = to_lua,
  moon_chunk = moon_chunk,
  moon_loader = moon_loader,
  dirsep = dirsep,
  dofile = dofile,
  loadfile = loadfile,
  loadstring = loadstring
}
