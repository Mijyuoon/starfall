if SERVER then
	AddCSLuaFile("moonscript/base.lua")
	AddCSLuaFile("moonscript/compile.lua")
	AddCSLuaFile("moonscript/data.lua")
	AddCSLuaFile("moonscript/dump.lua")
	AddCSLuaFile("moonscript/errors.lua")
	-- AddCSLuaFile("moonscript/init.lua")
	AddCSLuaFile("moonscript/line_tables.lua")
	AddCSLuaFile("moonscript/parse.lua")
	AddCSLuaFile("moonscript/transform.lua")
	AddCSLuaFile("moonscript/types.lua")
	AddCSLuaFile("moonscript/util.lua")
	
	AddCSLuaFile("moonscript/compile/statement.lua")
	AddCSLuaFile("moonscript/compile/value.lua")
	
	AddCSLuaFile("moonscript/transform/names.lua")
	AddCSLuaFile("moonscript/transform/destructure.lua")
end
	
package.moonpath = ""
moonscript = loadmodule "moonscript.base"