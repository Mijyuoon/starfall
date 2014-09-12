---------------------------------------------------------------------
-- SF Compiler.
-- Compiles code into an uninitialized Instance.
---------------------------------------------------------------------

SF.Compiler = {}

local function getrawenv(tbl)
	local glob = getfenv(1)
	return setmetatable({}, {
		__index = function(s,k)
			return (k == "_SF")
				and tbl or glob[k]
		end
	})
end

--- Preprocesses and Compiles code and returns an Instance
-- @param code Either a string of code, or a {path=source} table
-- @param context The context to use in the resulting Instance
-- @param mainfile If code is a table, this specifies the first file to parse.
-- @param player The "owner" of the instance
-- @param data The table to set instance.data to. Default is a new table.
-- @param dontpreprocess Set to true to skip preprocessing
-- @return True if no errors, false if errors occured.
-- @return The compiled instance, or the error message.
function SF.Compiler.Compile(code, context, mainfile, player, data, dontpreprocess)
	if type(code) == "string" then
		mainfile = mainfile or "generic"
		code = { mainfile = code }
	end
	
	local instance = setmetatable({}, SF.Instance)
	
	data = data or {}
	
	instance.player = player
	instance.env = setmetatable({}, context.env)
	instance.env._G = instance.env
	instance.data = data
	instance.ppdata = {}
	instance.slice = 0
	instance.hooks = {}
	instance.scripts = {}
	instance.source = code
	instance.initialized = false
	instance.context = context
	instance.mainfile = mainfile
	
	for filename, source in pairs(code) do
		if type(source) == "table" then
			-- Hack for propagating Moonscript parse errors
			return false, source.msg:gsub("\n", " ")
		elseif not dontpreprocess then
			instance.ppdata.moonscript = nil
			SF.Preprocessor.ParseDirectives(filename, source, context.directives, instance.ppdata)
		end
		
		if string.match(source, "^[%s\n]*$") then
			-- Lua doesn't have empty statements, so an empty file gives a syntax error
			instance.scripts[filename] = function() end
		else
			if instance.ppdata.moonscript then
				if type(moonscript) == "table" then
					local func, err = moonscript.loadstring(source, "SF:"..filename)
					if type(func) ~= "function" then
						return false, (err or func)
					end
					if player:IsSuperAdmin() and instance.ppdata.nosandbox then
						debug.setfenv(func, getrawenv(context.env.__index))
					else
						debug.setfenv(func, instance.env)
					end
					instance.scripts[filename] = func
				else
					return false, "MoonScript module not loaded, cannot compile"
				end
			else
				local func = CompileString(source, "SF:"..filename, false)
				if type(func) == "string" then
					return false, func
				end
				if player:IsSuperAdmin() and instance.ppdata.nosandbox then
					debug.setfenv(func, getrawenv(context.env.__index))
				else
					debug.setfenv(func, instance.env)
				end
				instance.scripts[filename] = func
			end
		end
	end
	
	return true, instance
end
