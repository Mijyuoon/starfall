-------------------------------------------------------------------------------
-- Builtins.
-- Functions built-in to the default environment
-------------------------------------------------------------------------------

local dgetmeta = debug.getmetatable
local dsetmeta = debug.setmetatable

--- Built in values. These don't need to be loaded; they are in the default environment.
-- @name builtin
-- @shared
-- @class library
-- @libtbl SF.DefaultEnvironment

-- ------------------------- Lua Ports ------------------------- --
-- This part is messy because of LuaDoc stuff.

--- Same as the Gmod vector type
-- @name SF.DefaultEnvironment.Vector
-- @class function
-- @param x X coordinate
-- @param y Y coordinate
-- @param z Z coordinate
SF.DefaultEnvironment.Vector = Vector

--- Same as the Gmod angle type
-- @name SF.DefaultEnvironment.Angle
-- @class function
-- @param p Pitch
-- @param y Yaw
-- @param r Roll
SF.DefaultEnvironment.Angle = Angle

--- Same as the Gmod VMatrix type
-- @name SF.DefaultEnvironment.Matrix
-- @class function

--- Same as Lua's tostring
-- @name SF.DefaultEnvironment.tostring
-- @class function
-- @param obj Object to convert to string
SF.DefaultEnvironment.tostring = tostring

--- Same as Lua's tonumber
-- @name SF.DefaultEnvironment.tonumber
-- @class function
-- @param obj Object to convert to number
SF.DefaultEnvironment.tonumber = tonumber

local function mynext(t, idx)
	SF.CheckType(t, "table")
	
	local dm = dgetmeta(t)
	if dm and type(dm.__metatable) == "string" then
		if type(dm.__index) == "table" then
			return next(dm.__index, idx)
		end
		return nil
	else
		return next(t, idx)
	end
end
--- Same as Lua's ipairs
-- @name SF.DefaultEnvironment.ipairs
-- @class function
-- @param tbl Table to iterate
SF.DefaultEnvironment.ipairs = ipairs

--- Same as Lua's pairs
-- @name SF.DefaultEnvironment.pairs
-- @class function
-- @param tbl Table to iterate
SF.DefaultEnvironment.pairs = pairs

--- Same as Lua's pairs but iterates over metatable's __index
-- @name SF.DefaultEnvironment.mpairs
-- @class function
-- @param tbl Table to iterate
SF.DefaultEnvironment.mpairs = function(t) 
	return mynext, t, nil
end

--- Same as Lua's type
-- @name SF.DefaultEnvironment.type
-- @class function
-- @param obj Anything
-- @return Type of object
SF.DefaultEnvironment.type = function(val)
	local tp = getmetatable(val)
	return (type(tp) == "string") and tp or type(val)
end

--- Same as Lua's next
-- @name SF.DefaultEnvironment.next
-- @class function
-- @param tbl Table to get next key/value from
SF.DefaultEnvironment.next = next

--- Same as Lua's next but iterates over metatable's __index
-- @name SF.DefaultEnvironment.mnext
-- @class function
-- @param tbl Table to get next key/value from
SF.DefaultEnvironment.mnext = mynext

--- Same as Lua's assert
-- @name SF.DefaultEnvironment.assert
-- @class function
-- @param cond Condition to check
-- @param msg Error message
SF.DefaultEnvironment.assert = function(ok, msg) 
	if not ok then 
		SF.throw(msg or "assertion failed!",2) 
	end 
end

--- Same as Lua's unpack
-- @name SF.DefaultEnvironment.unpack
-- @class function
-- @param tbl Table to unpack
SF.DefaultEnvironment.unpack = unpack

--- Same as Lua's setmetatable. Doesn't work on most internal metatables
-- @param tbl Table to set metatable for
-- @param meta Metatable to set
SF.DefaultEnvironment.setmetatable = setmetatable

--- Same as Lua's getmetatable. Doesn't work on most internal metatables
-- @param Table to get metatable from
-- @return Metatable of given table (if exists)
SF.DefaultEnvironment.getmetatable = function(tbl)
	SF.CheckType(tbl,"table")
	return getmetatable(tbl)
end
--- Same as Lua's pcall.
-- @name SF.DefaultEnvironment.pcall
-- @param func Function to call
-- @param ... Arguments to function
-- @return True if no erros occurred, false otherwise
-- @return Called function's return values or error message
SF.DefaultEnvironment.pcall = pcall

--- Throws an error. Can't change the level yet.
-- @param msg Error message
SF.DefaultEnvironment.error = function(msg)
	error(msg or "unspecified error occured",2) 
end

--- Try to execute a function and catch possible exceptions
-- Similar to pcall, but a bit more in-depth
-- @param func Function to execute
-- @param catch Function to execute in case func fails
function SF.DefaultEnvironment.try(func, catch)
	SF.CheckType(func, "function")
	SF.CheckType(catch, "function")
	local ok, err = pcall(func)
	if ok then return end
	if type(err) == "table" then
		if err.uncatchable then
			error(err, 2)
		end
	end
	catch(err)
end

--- Throws an exception
-- @param msg Message
-- @param level Which level in the stacktrace to blame. Defaults to one of invalid
-- @param uncatchable Makes this exception uncatchable
function SF.DefaultEnvironment.throw(msg, level, uncatchable)
	local info = debug.getinfo(1 + (level or 1), "Sl")
	local filename = info.short_src:match("^SF:(.*)$")
	if not filename then
		info = debug.getinfo(2, "Sl")
		filename = info.short_src:match("^SF:(.*)$")
	end
	local err = {
		uncatchable = false,
		file = filename,
		line = info.currentline,
		message = msg,
		uncatchable = uncatchable
	}
	error(err)
end

SF.DefaultEnvironment.CLIENT = CLIENT
SF.DefaultEnvironment.SERVER = SERVER

--- Gets the amount of CPU time used so far
function SF.DefaultEnvironment.cpuUsed()
	return SF.instance:getCpuTimeAvg()
end

--- Gets the CPU time hard quota
function SF.DefaultEnvironment.cpuMax()
	return SF.instance.context.slice()
end

-- Filters Gmod Lua files based on Garry's naming convention.
local function filterGmodLua(lib, original, gm)
	original = original or {}
	gm = gm or {}
	for name, func in pairs(lib) do
		if name:match("^[A-Z]") then
			gm[name] = func
		else
			original[name] = func
		end
	end
	return original, gm
end

-- String library
local string_methods, string_metatable = SF.Typedef("Library: string")
filterGmodLua(string, string_methods)
string_metatable.__newindex = function() end

string_methods.explode = function(str,sep,patt)
	return string.Explode(sep,str,patt) 
end
string_methods.compress = util.Compress
string_methods.decompress = util.Decompress

--- Lua's (not glua's) string library, plus explode
-- @name SF.DefaultEnvironment.string
-- @class table
SF.DefaultEnvironment.string = setmetatable({}, string_metatable)

-- Color Type
local color_methods, color_metatable = SF.Typedef("Color")
color_metatable.__newindex = function() end
SF.ColorMetatable = color_metatable

--- Same as the Gmod Color type
-- @name SF.DefaultEnvironment.Color
-- @class function
-- @param r - Red
-- @param g - Green
-- @param b - Blue
-- @param a - Alpha
SF.DefaultEnvironment.Color = function(...)
	return setmetatable(Color(...), color_metatable)
end

-- Math library
local math_methods, math_metatable = SF.Typedef("Library: math")
filterGmodLua(math, math_methods)
math_metatable.__newindex = function() end
math_methods.clamp = math.Clamp
math_methods.round = math.Round
math_methods.randfloat = math.Rand
math_methods.calcBSplineN = nil

--- Lua's (not glua's) math library, plus clamp, round, and randfloat
-- @name SF.DefaultEnvironment.math
-- @class table
SF.DefaultEnvironment.math = setmetatable({}, math_metatable)

local table_methods, table_metatable = SF.Typedef("Library: table")
filterGmodLua(table, table_methods)
table_metatable.__newindex = function() end

--- Lua's (not glua's) table library
-- @name SF.DefaultEnvironment.table
-- @class table
SF.DefaultEnvironment.table = setmetatable({}, table_metatable)

local bit_methods, bit_metatable = SF.Typedef("Library: bit")
filterGmodLua(bit, bit_methods)
bit_metatable.__newindex = function() end

--- Lua's bit library
-- @name SF.DefaultEnvironment.bit
-- @class table
SF.DefaultEnvironment.bit = setmetatable({}, bit_metatable)

-- ------------------------- Functions ------------------------- --

--- Loads a library.
-- @name SF.DefaultEnvironment.loadLibrary
-- @class function
-- @param ... A list of library names, e.g. "hook", "ent", "render"
-- @return List of library tables
function SF.DefaultEnvironment.loadLibrary(...)
	local t = {...}
	local r = {}

	local instance = SF.instance

	for _,v in pairs(t) do
		SF.CheckType(v,"string")

		if instance.context.libs[v] then
			r[#r+1] = setmetatable({}, instance.context.libs[v])
		else
			r[#r+1] = SF.Libraries.Get(v)
		end
	end

	return unpack(r)
end

--- Gets a list of all libraries
function SF.DefaultEnvironment.getLibraries()
	local ret = {}
	for k,v in pairs(SF.Libraries.libraries) do
		ret[#ret+1] = k
	end
	return ret
end

local function printfmt(...)
	local buffer, tabl = nil, {...}
	local maxidx = select("#", ...)
	for key = 1, maxidx do
		tabl[key] = tostring(tabl[key])
	end
	buffer = table.concat(tabl, "\t")
	return buffer
end

if SERVER then
	util.AddNetworkString("SF_PrintMsg")
	
	--- Prints a message to the player's chat
	function SF.DefaultEnvironment.print(...)
		local buffer = printfmt(...)
		net.Start("SF_PrintMsg")
			net.WriteUInt(1, 8)
			net.WriteString(buffer)
		net.Send(SF.instance.player)
	end
	
	-- Prints a message to player's console
	function SF.DefaultEnvironment.printCon(...)
		local buffer = printfmt(...)
		net.Start("SF_PrintMsg")
			net.WriteUInt(0, 8)
			net.WriteString(buffer)
		net.Send(SF.instance.player)
	end
else
	--- Prints a message to the player's chat
	function SF.DefaultEnvironment.print(...)
		if SF.instance.player == LocalPlayer() then
			chat.AddText(printfmt(...))
		end
	end
	
	-- Prints a message to player's console
	function SF.DefaultEnvironment.printCon(...)
		if SF.instance.player == LocalPlayer() then
			MsgN(printfmt(...))
		end
	end
	
	net.Receive("SF_PrintMsg", function()
		local typ = net.ReadUInt(8)
		if typ == 0 then
			MsgN(net.ReadString())
		elseif typ == 1 then
			chat.AddText(net.ReadString())
		--[[-----
		elseif typ == 2 then
			local buffer = {}
			while true do
				local vt = net.ReadUInt(8)
				if vt < 0 then break end
				local val = net.ReadType(vt)
				buffer[#buffer+1] = val
			end
			chat.AddText(unpack(buffer))
		-------]]
		end
	end)
end

--[[---- Very shitty code -------------------------
local function printTableX(target, t, indent, alreadyprinted)
	for k,v in SF.DefaultEnvironment.pairs(t) do
		if SF.GetType(v) == "table" and not alreadyprinted[v] then
			alreadyprinted[v] = true
			target:ChatPrint(string.rep("\t", indent) .. tostring(k) .. ":")
			printTableX(target, v, indent + 1, alreadyprinted)
		else
			target:ChatPrint(string.rep("\t", indent) .. tostring(k) .. "\t=\t" .. tostring(v))
		end
	end
end

function SF.DefaultEnvironment.printTable(t)
	local ply = SF.instance.player
	if CLIENT and ply ~= LocalPlayer() then return end
	SF.CheckType(t, "table")

	printTableX(ply, t, 0, {[t] = true})
end
-----------------------------------------------]]

--- Runs an --@include'd script and caches the result.
-- Works pretty much like standard Lua require()
-- @param file File name to load (.txt is optional)
function SF.DefaultEnvironment.require(file)
	SF.CheckType(file, "string")
	if file:sub(-4, -1) ~= ".txt" then
		file = file .. ".txt"
	end
	local loaded = SF.instance.data.reqloaded
	if not loaded then
		loaded = {}
		SF.instance.data.reqloaded = loaded
	end
	
	if loaded[file] then
		return loaded[file]
	else
		local func = SF.instance.scripts[file]
		if not func then SF.throw("Can't find file '"..file.."' (did you forget to --@include it?)",2) end
		loaded[file] = func() or true
		return loaded[file]
	end
end

--- Runs an --@include'd file and returns the result.
-- Pretty much like standard Lua dofile()
-- @param file File name to load (.txt is optional)
function SF.DefaultEnvironment.loadFile(file)
	SF.CheckType(file, "string")
	if file:sub(-4,-1) ~= ".txt" then
		file = file .. ".txt"
	end
	local func = SF.instance.scripts[file]
	if not func then SF.throw("Can't find file '"..file.."' (did you forget to --@include it?)",2) end
	return func()
end

--- Compiles a string and returns boolean success, compiled function or error.
-- @param str Lua code to be compiled
-- @return True if compile was successful, false otherwise
-- @return Compiled function or error message
function SF.DefaultEnvironment.loadString(str)
        local func = CompileString(str, "SF - LoadString", false)
        if type(func) == "string" then
			return false, func
        end
        debug.setfenv(func, SF.instance.env)
        return true, func
end

--- Compiles a string and returns boolean success, compiled function or error.
-- This is MoonScript version of loadString.
-- @param str MoonScript code to be compiled
-- @return True if compile was successful, false otherwise
-- @return Compiled function or error message
function SF.DefaultEnvironment.loadStringM(str)
	if type(moonscript) ~= "table" then
		return false, "MoonScript module not loaded, cannot compile"
	end
	local func, err = moonscript.loadstring(str, "SF - LoadString")
	if type(func) ~= "function" then
		return false, (err or func)
	end
	debug.setfenv(func, SF.instance.env)
	return true, func
end

--- Wraps a current processor's context for a function (Note: uses pcall)
-- May be necesary to properly call functions from other SF instances
-- @param func Function to wrap current context for
-- @return function Wrapped function
function SF.DefaultEnvironment.wrapContext(func)
	local instance = SF.instance
	return function(...)
		local cinst = SF.instance
		SF.instance = instance
		local ret = { pcall(func, ...) }
		SF.instance = cinst
		return unpack(ret)
	end
end

-- ------------------------- Restrictions ------------------------- --
-- Restricts access to builtin type's metatables

--[[---- Is really needed? ----------------------
local _R = debug.getregistry()
local function restrict(instance, hook, name, ok, err)
	_R.Vector.__metatable = "Vector"
	_R.Angle.__metatable = "Angle"
end

local function unrestrict(instance, hook, name, ok, err)
	_R.Vector.__metatable = nil
	_R.Angle.__metatable = nil
end

SF.Libraries.AddHook("prepare", restrict)
SF.Libraries.AddHook("cleanup", unrestrict)
-----------------------------------------------]]

-- ------------------------- Hook Documentation ------------------------- --

--- Think hook. Called once per game tick
-- @name think
-- @class hook
-- @shared
