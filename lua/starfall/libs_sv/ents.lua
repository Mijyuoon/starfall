-------------------------------------------------------------------------------
-- Serverside Entity functions
-------------------------------------------------------------------------------

assert(SF.Entities)

local huge = math.huge
local abs = math.abs
local ents_lib = SF.Entities.Library
local ents_metatable = SF.Entities.Metatable
local ents_methods = SF.Entities.Methods
local wrap, unwrap = SF.Entities.Wrap, SF.Entities.Unwrap

local function fix_nan(v)
	if v < huge and v > -huge then return v else return 0 end
end

-- Register privileges
do
	local P = SF.Permissions
	P.registerPrivilege("ents.parent", "Parent", "Allows the user to parent an entity to another entity")
	P.registerPrivilege("ents.unparent", "Unparent", "Allows the user to remove the parent of an entity") -- TODO: maybe merge with entities.parent?
	P.registerPrivilege("ents.applyForce", "Apply force", "Allows the user to apply force to an entity")
	P.registerPrivilege("ents.setPos", "Set Position", "Allows the user to teleport an entity to another location")
	P.registerPrivilege("ents.setAngles", "Set Angles", "Allows the user to teleport an entity to another orientation")
	P.registerPrivilege("ents.setVelocity", "Set Velocity", "Allows the user to change the velocity of an entity")
	P.registerPrivilege("ents.setFrozen", "Set Frozen", "Allows the user to freeze and unfreeze an entity")
	P.registerPrivilege("ents.setSolid", "Set Solid", "Allows the user to change the solidity of an entity")
	P.registerPrivilege("ents.enableGravity", "Enable gravity", "Allows the user to change whether an entity is affected by gravity")
	P.registerPrivilege("ents.getWirelink", "Get wirelink", "Allows the user to retrieve wirelink that represents an entity")
end

-- ------------------------- Internal Library ------------------------- --

--- Gets the entity's owner
-- TODO: Optimize this!
-- @return The entities owner, or nil if not found
function SF.Entities.GetOwner(entity)
	local valid = SF.Entities.IsValid
	if not valid(entity) then return end
	
	if entity.IsPlayer and entity:IsPlayer() then
		return entity
	end
	
	if CPPI then
		local owner = entity:CPPIGetOwner()
		if valid(owner) then return owner end
	end
	
	if entity.GetPlayer then
		local ply = entity:GetPlayer()
		if valid(ply) then return ply end
	end
	
	if entity.owner and valid(entity.owner) and entity.owner:IsPlayer() then
		return entity.owner
	end
	
	local OnDieFunctions = entity.OnDieFunctions
	if OnDieFunctions then
		if OnDieFunctions.GetCountUpdate and OnDieFunctions.GetCountUpdate.Args and OnDieFunctions.GetCountUpdate.Args[1] then
			return OnDieFunctions.GetCountUpdate.Args[1]
		elseif OnDieFunctions.undo1 and OnDieFunctions.undo1.Args and OnDieFunctions.undo1.Args[2] then
			return OnDieFunctions.undo1.Args[2]
		end
	end
	
	if entity.GetOwner then
		local ply = entity:GetOwner()
		if valid(ply) then return ply end
	end

	return nil
end

--- Checks to see if a player can modify an entity without the override permission
-- @param ply The player
-- @param ent The entity being modified
function SF.Entities.CanModify(ply, ent)
	return (CPPI and ent:CPPICanPhysgun(ply)) or SF.Entities.GetOwner(ent) == ply
end

local isValid = SF.Entities.IsValid
local getPhysObject = SF.Entities.GetPhysObject
local getOwner = SF.Entities.GetOwner
local canModify = SF.Entities.CanModify

-- Add wire inputs/outputs
local function postload()
	if SF.Wire then
		SF.Wire.AddInputType("ENTITY",function(data)
			if data == nil then return nil end
			return wrap(data)
		end)

		SF.Wire.AddOutputType("ENTITY", function(data)
			if data == nil then return nil end
			SF.CheckType(data,ents_metatable)
			
			return unwrap(data)
		end)
	end
end
SF.Libraries.AddHook("postload",postload)


local sv_gravity = GetConVar("sv_gravity")

--- Gets standard gravity constant that ~WORKS~ for F=mg
function ents_lib.g0()
	return sv_gravity:GetFloat() / 66.566676122833
end

--- Gets the owner of the entity
function ents_methods:owner()
	local ent = unwrap(self)
	return wrap(getOwner(ent))
end

local function check(v)
	return 	-math.huge < v.x and v.x < math.huge and
			-math.huge < v.y and v.y < math.huge and
			-math.huge < v.z and v.z < math.huge
end

local function checka(a)
	return 	-math.huge < v.p and v.p < math.huge and
			-math.huge < v.y and v.y < math.huge and
			-math.huge < v.r and v.r < math.huge
end

local function parent_check(child, parent)
	while isValid(parent) do
		if (child == parent) then
			return false
		end
		parent = parent:GetParent()
	end
	return true
end

--[[
function SF.Entities.CheckAccess(ent)
	return (canModify(SF.instance.player, ent) or SF.instance.permissions:checkPermission("Modify All Entities"))
end
local check_access = SF.Entities.CheckAccess
--]]
local function check_access(data, perm)
	return SF.Permissions.check(SF.instance.player, data, perm)
end

function ents_methods:wirelink()
	SF.CheckType(self, ents_metatable)
	
	local this = unwrap(self)
	if not isValid(this) then
		return false, "invalid entity"
	end
	if not check_access(this, "ents.getWirelink") then
		SF.throw("Insufficient permissions", 2)
	end
	
	this.extended = true -- What is this for?
	return SF.Wire.WlWrap(this)
end

function ents_methods:parent(ent)
	SF.CheckType(self, ents_metatable)

	local ent = unwrap(ent)
	local this = unwrap(self)

	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not parent_check(this, ent) then
		return false, "cannot parent to self"
	end
	--print("getOwner: ,",ent:GetOwner())
	if not check_access({this, ent}, "ents.parent") then
		SF.throw("Insufficient permissions", 2)
	end

	this:SetParent(ent)
	return true
end

function ents_methods:unparent()
	local this = unwrap(self)
	if not isValid(this) then return
		false, "invalid entity"
	end
	if not check_access(this, "ents.unparent") then
		SF.throw("Insufficient permissions", 2)
	end
	this:SetParent(nil)
	return true
end

--- Applies linear force to the entity
-- @param vec The force vector
function ents_methods:applyForceCenter(vec)
	SF.CheckType(vec,"Vector")
	if not check(vec) then
		return false, "infinite vector"
	end
	
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.applyForce") then
		SF.throw("Insufficient permissions", 2)
	end
	local phys = getPhysObject(ent)
	if not phys then return false, "invalid physobj" end
	
	phys:ApplyForceCenter(vec)
	
	return true
end

--- Applies linear force to the entity with an offset
-- @param vec The force vector
-- @param offset An optional offset position (TODO: Local or world?)
function ents_methods:applyForceOffset(vec, offset)
	SF.CheckType(vec,"Vector")
	SF.CheckType(offset,"Vector")
	if not check(vec) or not check(offset) then
		return false, "infinite vector"
	end
	
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.applyForce") then
		SF.throw("Insufficient permissions", 2)
	end
	local phys = getPhysObject(ent)
	if not phys then return false, "invalid physobj" end
	
	phys:ApplyForceOffset(vec, offset)
	
	return true
end

--- Applies angular force to the entity
-- @param ang The force angle
-- @depreciated Gmod has no phys:ApplyAngleForce function, so this uses black magic
function ents_methods:applyAngForce(ang)
	SF.CheckType(ang,"Angle")
	
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.applyForce") then
		SF.throw("Insufficient permissions", 2)
	end
	local phys = getPhysObject(ent)
	if not phys then
		return false, "invalid physobj"
	end
	
	-- assign vectors
	local up = ent:GetUp()
	local left = ent:GetRight() * -1
	local forward = ent:GetForward()
	
	-- apply pitch force
	if ang.p ~= 0 then
		local pitch = up      * (ang.p * 0.5)
		phys:ApplyForceOffset(forward, pitch)
		phys:ApplyForceOffset(forward * -1, pitch * -1)
	end
	
	-- apply yaw force
	if ang.y ~= 0 then
		local yaw   = forward * (ang.y * 0.5)
		phys:ApplyForceOffset(left, yaw)
		phys:ApplyForceOffset(left * -1, yaw * -1)
	end
	
	-- apply roll force
	if ang.r ~= 0 then
		local roll  = left    * (ang.r * 0.5)
		phys:ApplyForceOffset(up, roll)
		phys:ApplyForceOffset(up * -1, roll * -1)
	end
	
	return true
end

--- Applies torque
-- @param tq The torque vector
function ents_methods:applyTorque(tq)
	SF.CheckType(tq,"Vector")
	
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.applyForce") then
		SF.throw("Insufficient permissions", 2)
	end
	local phys = getPhysObject(ent)
	if not phys then
		return false, "invalid physobj"
	end
	
	local torqueamount = tq:Length()
	
	-- Convert torque from local to world axis
	tq = phys:LocalToWorld(tq) - phys:GetPos()
	
	-- Find two vectors perpendicular to the torque axis
	local off
	if abs(tq.x) > torqueamount * 0.1 or abs(tq.z) > torqueamount * 0.1 then
		off = Vector(-tq.z, 0, tq.x)
	else
		off = Vector(-tq.y, tq.x, 0)
	end
	off = off:GetNormal() * torqueamount * 0.5
	
	local dir = (tq:Cross(off)):GetNormal()
	
	if not check(dir) or not check(off) then return end
	phys:ApplyForceOffset(dir, off)
	phys:ApplyForceOffset(dir * -1, off * -1)
	
	return true
end

--- Sets the entitiy's position
-- @param vec New position
function ents_methods:setPos(vec)
	SF.CheckType(vec,"Vector")
	
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.setPos") then
		SF.throw("Insufficient permissions", 2)
	end

	SF.setPos(ent, vec)

	return true
end

--- Sets the entity's angles
-- @param ang New angles
function ents_methods:setAngles(ang)
	SF.CheckType(ang,"Angle")
	
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.setAngles") then
		SF.throw("Insufficient permissions", 2)
	end

	SF.setAng(ent, ang)

	return true
end

--- Sets the entity's linear velocity
-- @param vel New velocity
function ents_methods:setVelocity(vel)
	SF.CheckType(vel,"Vector")
	
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.setVelocity") then
		SF.throw("Insufficient permissions", 2)
	end
	local phys = getPhysObject(ent)
	if not phys then
		return false, "invalid physobj"
	end
	
	phys:SetVelocity(vel)
	return true
end

--- Sets the entity frozen state
-- @param freeze Should the entity be frozen?
function ents_methods:setFrozen(freeze)
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.setFrozen") then
		SF.throw("Insufficient permissions", 2)
	end
	local phys = getPhysObject(ent)
	if not phys then 
		return false, "invalid physobj"
	end
	
	phys:EnableMotion(not freeze)
	phys:Wake()
	return true
end

--- Checks the entities frozen state
function ents_methods:isFrozen()
	SF.CheckType(self, ents_metatable)

	local ent = unwrap(self)
	if not isValid(ent) then
		return false
	end
	local phys = ent:GetPhysicsObject()
	if phys:IsMoveable() then return false else return true end
end

--- Sets the entity solid state
-- @param notsolid Should the entity be not solid?
function ents_methods:setSolid(solid)
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.setSolid") then
		SF.throw("Insufficient permissions", 2)
	end
	
	ent:SetNotSolid(not notsolid)
	return true
end

--- Sets entity gravity
-- @param grav Should the entity respect gravity?
function ents_methods:enableGravity(grav)
	local ent = unwrap(self)
	if not isValid(ent) then
		return false, "invalid entity"
	end
	if not check_access(ent, "ents.enableGravity") then
		SF.throw("Insufficient permissions", 2)
	end
	local phys = getPhysObject(ent)
	if not phys then
		return false, "invalid physobj"
	end
	
	phys:EnableGravity(grav and true or false)
	phys:Wake()
	return true
end

local function ent1or2(ent,con,num)
	if not con then return nil end
	if num then
		con = con[num]
		if not con then return nil end
	end
	if con.Ent1==ent then return con.Ent2 end
	return con.Ent1
end

--- Gets what the entity is welded to
function ents_methods:isWeldedTo()
	local this = unwrap(self)
	if not isValid(this) then return nil end
	if not constraint.HasConstraints(this) then return nil end

	return wrap(ent1or2(this, constraint.FindConstraint(this, "Weld")))
end

--- Gets the entities up vector
function ents_methods:getUp()
	return unwrap(self):GetUp()
end

--- Gets the entities right vector
function ents_methods:getRight()
	return unwrap(self):GetRight()
end

--- Gets the entities forward vector
function ents_methods:getForward()
	return unwrap(self):GetForward()
end