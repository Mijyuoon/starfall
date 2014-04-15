local lpeg_load = pcall(require, "lpeg")
if lpeg_load then
	-- Use binary LPeg module
	lpeg.L = function(val)
		return #val
	end
else
	-- Use LuLPeg as replacement
	loadmodule("moonscript.lulpeg"):register(_G)
end
lpeg.re = loadmodule("moonscript.lpeg_re")
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
    return nil, "expecting string (got " .. t .. ")"
  end
  local tree, err = parse.string(text)
  if not tree then
    return nil, err
  end
  local code, ltable, pos = compile.tree(tree, options)
  if not code then
    return nil, compile.format_error(ltable, pos, text)
  end
  return code, ltable
end
moon_loader = function(name)
  local name_path = name:gsub("%.", dirsep)
  local file, file_path
  local _list_0 = split(package.moonpath, ";")
  for _index_0 = 1, #_list_0 do
    local path = _list_0[_index_0]
    file_path = path:gsub("?", name_path)
    file = io.open(file_path)
    if file then
      break
    end
  end
  if file then
    local text = file:read("*a")
    file:close()
    local res, err = loadstring(text, file_path)
    if not res then
      error(file_path .. ": " .. err)
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
  return CompileString(code, chunk_name, unpack({
    mode,
    env
  }))
end
loadfile = function(fname, ...)
  local file, err = io.open(fname)
  if not (file) then
    return nil, err
  end
  local text = assert(file:read("*a"))
  file:close()
  return loadstring(text, fname, ...)
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
  moon_loader = moon_loader,
  dirsep = dirsep,
  dofile = dofile,
  loadfile = loadfile,
  loadstring = loadstring
}
