--- Provides permissions for entities based on CPPI if present

local P = setmetatable( {}, { __index = SF.Permissions.Provider } )

local ALLOW = SF.Permissions.Result.ALLOW
local DENY = SF.Permissions.Result.DENY
local NEUTRAL = SF.Permissions.Result.NEUTRAL

local canTool = {
	[ "ents.parent" ] = true,
	[ "ents.unparent" ] = true,
	[ "ents.setSolid" ] = true,
	[ "ents.enableGravity" ] = true,
	[ "ents.setColor" ] = true,
	[ "ents.getWirelink" ] = true
}

local canPhysgun = {
	[ "ents.applyForce" ] = true,
	[ "ents.setPos" ] = true,
	[ "ents.setAngles" ] = true,
	[ "ents.setVelocity" ] = true,
	[ "ents.setFrozen" ] = true
}

local target_type = {
	Entity = true,
	Player = true,
	Vehicle = true,
	NPC = true,
}

function P:check ( principal, target, key )
	if not CPPI then return NEUTRAL end
	if not target_type[type(target)] then return NEUTRAL end

	if canTool[ key ] then
		if target:CPPICanTool( principal, "starfall_ent_lib" ) then return ALLOW end
		return DENY
	elseif canPhysgun[ key ] then
		if target:CPPICanPhysgun( principal ) then return ALLOW end
		return DENY
	end

	return NEUTRAL
end

SF.Permissions.registerProvider( P )
