-------------------------------------------------------------------------------
-- Player functions.
-------------------------------------------------------------------------------

SF.Players = {}
--- Player type
local player_methods, player_metamethods = SF.Typedef("Player", SF.Entities.Metatable)

SF.Players.Methods = player_methods
SF.Players.Metatable = player_metamethods

--- Custom wrapper/unwrapper is necessary for player objects
-- wrapper
local dsetmeta = debug.setmetatable
local function wrap(object)
	object = SF.Entities.Wrap(object)
	dsetmeta(object, player_metamethods)
	return object
end

SF.AddObjectWrapper(debug.getregistry().Player, player_metamethods, wrap)

-- unwrapper
SF.AddObjectUnwrapper(player_metamethods, SF.Entities.Unwrap)

--- To string
-- @shared
function player_metamethods:__tostring()
	local ent = SF.Entities.Unwrap(self)
	if not ent then return "(null entity)"
	else return tostring(ent) end
end


-- ------------------------------------------------------------------------- --
--- Returns whether the player is alive
-- @shared
-- @return True if player alive
function player_methods:isAlive()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:Alive()
end

--- Returns the player's armor
-- @shared
-- @return Armor
function player_methods:getArmor()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:Armor()
end

--- Returns the player's health
-- @shared
-- @return Health
function player_methods:getHealth()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:Health()
end

--- Returns whether the player is crouching
-- @shared
-- @return True if player crouching
function player_methods:isCrouching()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:Crouching()
end

--- Returns the amount of deaths of the player
-- @shared
-- @return Amount of deaths
function player_methods:getDeaths()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:Deaths()
end

--- Returns whether the player's flashlight is on
-- @shared
-- @return True if player has flashlight on
function player_methods:isFlashlightOn()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:FlashlightIsOn()
end

--- Returns the amount of kills of the player
-- @shared
-- @return Amount of kills
function player_methods:getFrags()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:Frags()
end

--- Returns the name of the player's active weapon
-- @shared
-- @return Name of weapon
function player_methods:getActiveWeapon()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:GetActiveWeapon():GetClass()
end

--- Returns the player's aim vector
-- @shared
-- @return Aim vector
function player_methods:getAimVector()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:GetAimVector()
end

--- Returns the player's field of view
-- @shared
-- @return Field of view
function player_methods:getFOV()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:GetFOV()
end

--- Returns the player's jump power
-- @shared
-- @return Jump power
function player_methods:getJumpPower()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:GetJumpPower()
end

--- Returns the player's maximum speed
-- @shared
-- @return Maximum speed
function player_methods:getMaxSpeed()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:GetMaxSpeed()
end

--- Returns the player's name
-- @shared
-- @return Name
function player_methods:getName()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:GetName()
end

--- Returns the player's running speed
-- @shared
-- @return Running speed
function player_methods:getRunSpeed()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:GetRunSpeed()
end

--- Returns the player's shoot position
-- @shared
-- @return Shoot position
function player_methods:getShootPos()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:GetShootPos()
end

--- Returns whether the player is in a vehicle
-- @shared
-- @return True if player in vehicle
function player_methods:inVehicle()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:InVehicle()
end

--- Returns whether the player is an admin
-- @shared
-- @return True if player is admin
function player_methods:isAdmin()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:IsAdmin()
end

--- Returns whether the player is a bot
-- @shared
-- @return True if player is a bot
function player_methods:isBot()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:IsBot()
end

--- Returns whether the player is connected
-- @shared
-- @return True if player is connected
function player_methods:isConnected()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:IsConnected()
end

--- Returns whether the player is frozen
-- @shared
-- @return True if player is frozen
function player_methods:isFrozen()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:IsFrozen()
end

--- Returns whether the player is a super admin
-- @shared
-- @return True if player is super admin
function player_methods:isSuperAdmin()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:IsSuperAdmin()
end

--- Returns whether the player belongs to a usergroup
-- @shared
-- @param group Group to check against
-- @return True if player belongs to group
function player_methods:isUserGroup(group)
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:IsUserGroup(group)
end

--- Returns the player's current ping
-- @shared
-- @return ping
function player_methods:getPing()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:Ping()
end

--- Returns the player's steam ID
-- @shared
-- @return steam ID
function player_methods:getSteamID()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:SteamID()
end

--- Returns the player's community ID
-- @shared
-- @return community ID
function player_methods:getSteamID64()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:SteamID64()
end

--- Returns the player's current team
-- @shared
-- @return team
function player_methods:getTeam()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:Team()
end

--- Returns the name of the player's current team
-- @shared
-- @return team name
function player_methods:getTeamName()
	local ent = SF.Entities.Unwrap(self)
	return ent and team.GetName(ent:Team())
end

--- Returns the player's unique ID
-- @shared
-- @return unique ID
function player_methods:getUniqueID()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:UniqueID()
end

--- Returns the player's user ID
-- @shared
-- @return user ID
function player_methods:getUserID()
	local ent = SF.Entities.Unwrap(self)
	return ent and ent:UserID()
end

--- Returns a table with information of what the player is looking at
-- @shared
-- @return table trace data
function player_methods:getEyeTrace()
	local ent = SF.UnwrapObject(self)
	if not SF.Permissions.check(SF.instance.player, ent, "trace") then
		SF.throw("Insufficient permissions", 2) 
	end
	return SF.Sanitize(ent:GetEyeTrace())
end

if CLIENT then
	--- Returns the relationship of the player to the local client
	-- @return One of: "friend", "blocked", "none", "requested"
	function player_methods:getFriendStatus()
		SF.CheckType(self, player_metamethods)
		local ent = SF.Entities.Unwrap(self)
		return ent and ent:GetFriendStatus()
	end
	
	--- Returns whether the local player has muted the player
	-- @return True if the player was muted
	function player_methods:isMuted()
		SF.CheckType(self, player_metamethods)
		local ent = SF.Entities.Unwrap(self)
		return ent and ent:IsMuted()
	end
end
