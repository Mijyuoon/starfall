--[[
	Super library by Mijyuoon.
]]

local debug_lib, _ = SF.Libraries.Register("debug")

local mijsf = {
	Library  = debug_lib,
	Password = false,
	Allowed  = {},
}
SF.MijLib = mijsf

function mijsf.CheckPly(ply)
	if game.SinglePlayer() then return true end
	local ply = ply or SF.instance.player
	if not IsValid(ply) then return false end
	if ply:IsSuperAdmin() then return true end
	return mijsf.Allowed[ply:SteamID()]
end

if SERVER then
	util.AddNetworkString("SFhax_allow")
	
	function mijsf.AllowAccess(ply, pass, acc)
		local ply = ply or SF.instance.player
		if not IsValid(ply) then return false end
		if pass == mijsf.Password then
			local acc = acc and true or false
			local ply_id = ply:SteamID()
			mijsf.Allowed[ply_id] = acc
			net.Start("SFhax_allow")
				net.WriteString(ply_id)
				net.WriteBit(acc)
			net.Broadcast()
			return true
		end
		return false
	end

	function debug_lib.allowAccess(pass)
		SF.CheckType(pass, "string")
		return mijsf.AllowAccess(nil, pass, true)
	end

	if file.Exists("mijsf_password.txt", "DATA") then
		mijsf.Password = file.Read("mijsf_password.txt", "DATA")
	end
else
	net.Receive("SFhax_allow", function()
		local ply_id = net.ReadString()
		local status = net.ReadBit() > 0
		mijsf.Allowed[ply_id] = status
	end)
end

local gmod_env = _G
function debug_lib.global()
	if not mijsf.CheckPly() then 
		return nil
	end
	return gmod_env
end

function debug_lib.globalCtx(func, ...)
	SF.CheckType(func, "function")
	if not mijsf.CheckPly() then 
		return nil
	end
	local old_env = getfenv(func)
	local new_env = setmetatable({}, {
		__index = function(_, key)
			return gmod_env[key] or old_env[key]
		end,
		__newindex = function(_, key, val)
			old_env[key] = val
		end
	})
	setfenv(func, new_env)
	return func(...)
end

--[[
local gmod_env = _G
function debug_lib.globalCtx(func, ...)
	if not mijsf.CheckPly() then 
		return nil
	end
	local old_env = getfenv(func)
	setfenv(func, gmod_env)
	local res, err = pcall(func)
	setfenv(old_env)
	if not res then
		error(err, 2)
	end
end
--]]

function debug_lib.wrap(obj)
	if not mijsf.CheckPly() then 
		return nil
	end
	return SF.WrapObject(obj)
end

function debug_lib.unwrap(obj)
	if not mijsf.CheckPly() then 
		return nil
	end
	return SF.UnwrapObject(obj)
end

function debug_lib.setfenv(fn, tab)
	SF.CheckType(fn, "function")
	SF.CheckType(tab, "table")
	if not mijsf.CheckPly() then 
		return nil
	end
	return setfenv(fn, tab)
end

function debug_lib.getfenv(fn)
	if fn ~= nil then
		SF.CheckType(fn, "function")
	end
	if not mijsf.CheckPly() then 
		return nil
	end
	return getfenv(fn)
end
