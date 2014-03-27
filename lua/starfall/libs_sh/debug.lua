--[[
	Super library by Mijyuoon.
]]

local super_lib, _ = SF.Libraries.Register("mij")

local mijsf = {
	Library  = super_lib,
	Password = false,
	Allowed  = {},
}
SF.MijLib = mijsf

function mijsf.CheckPly(ply)
	local ply = ply or SF.instance.player
	return (ply and mijsf.Allowed[ply:SteamID()])
end

function mijsf.AllowAccess(ply, pass, acc)
	local ply = ply or SF.instance.player
	if pass == mijsf.Password then
		local acc = acc and true or false
		mijsf.Allowed[ply:SteamID()] = acc
		return true
	end
	return false
end

if file.Exists("mijsf_password.txt", "DATA") then
	mijsf.Password = file.Read("mijsf_password.txt", "DATA")
end

local gmod_env = _G
function super_lib.global()
	if not mijsf.CheckPly() then 
		return nil
	end
	return gmod_env
end

function super_lib.allowAccess(pass, acc)
	SF.CheckType(pass, "string")
	SF.CheckType(acc, "boolean")
	return mijsf.AllowAccess(nil, pass, acc)
end

function super_lib.globalCtx(func, ...)
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
function super_lib.globalCtx(func, ...)
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

function super_lib.wrap(obj)
	if not mijsf.CheckPly() then 
		return nil
	end
	return SF.WrapObject(obj)
end

function super_lib.unwrap(obj)
	if not mijsf.CheckPly() then 
		return nil
	end
	return SF.UnwrapObject(obj)
end

function super_lib.setfenv(fn, tab)
	SF.CheckType(fn, "function")
	SF.CheckType(tab, "table")
	if not mijsf.CheckPly() then 
		return nil
	end
	return setfenv(fn, tab)
end

function super_lib.getfenv(fn)
	if fn ~= nil then
		SF.CheckType(fn, "function")
	end
	if not mijsf.CheckPly() then 
		return nil
	end
	return getfenv(fn)
end
