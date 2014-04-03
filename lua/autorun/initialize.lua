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

_MLOADED = {}
function loadmodule(name)
	if _MLOADED[name] then
		return _MLOADED[name]
	end
	
	local kname = name:gsub("%.","/") .. ".lua"
	if not file.Exists(kname, "LUA") then
		error("cannot find module \"" .. name .. "\"")
	end
	
	local func = CompileFile(kname, name)
	if func then
		_MLOADED[name] = func() or true
		return _MLOADED[name]
	end
end

package.moonpath = ""
moonscript = loadmodule "moonscript.base"

if not util.Base64Decode then
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	function util.Base64Decode(data)
		data = string.gsub(data, '[^'..b..'=]', '')
		return (data:gsub('.', function(x)
			if (x == '=') then return '' end
			local r,f='',(b:find(x)-1)
			for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
			return r;
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c=0
			for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
			return string.char(c)
		end))
	end
end