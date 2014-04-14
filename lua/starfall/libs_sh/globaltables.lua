
--- Cross-instance tables
-- @shared
local gtables_library, gtables_metamethods = SF.Libraries.Register("gtables")

SF.GlobalTables = {}

SF.GlobalTables.Global = {}
SF.GlobalTables.Players = {}

--- Global table shared by all instances on the same side.
-- @name gtables_library.global
-- @class table
function gtables_library.global()
	return SF.GlobalTables.Global
end

--gtables_library.global = SF.GlobalTables.Global

--- Player-unique global table.
-- @name gtables_library.player
-- @class table
function gtables_library.player()
	return SF.GlobalTables.Players[SF.instance.player]
end

hook.Add("PlayerInitialSpawn", "SF_GlobalTables_cn", function(ply)
	SF.GlobalTables.Players[ply] = {}
end)

hook.Add("PlayerDisconnected", "SF_GlobalTables_dc", function(ply)
	SF.GlobalTables.Players[ply] = nil
end)

--[[
local oldindex = gtables_metamethods.__index
function gtables_metamethods:__index(k)
	if k == "player" then
		return SF.GlobalTables.Players[SF.instance.player]
	else
		return oldindex[k]
	end
end
--]]


