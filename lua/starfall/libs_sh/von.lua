--[[--------------------------------------------------------
	SF vON library by Vercas. I only made stupid wrapper.
----------------------------------------------------------]]

--- vON library, allows for serializing/deserializing tables.
-- @shared

local von_lib, _ = SF.Libraries.Register("von")

local function IsColor(obj)
	if type(obj) ~= "table" then
		return false
	end
	if not (obj.a and obj.r and obj.g and obj.b) then 
		return false 
	end
	return true
end
local function sf_wrap_object(col)
	if IsColor(col) then
		return setmetatable(col, SF.ColorMetatable)
	end
	return (SF.WrapObject(col) or col)
end

--- Serializes table
-- @param Data Table to serialize
-- @return String that represents serialized table
function von_lib.serialize(data)
	SF.CheckType(data, "table")
	local wrapped = {}
	for key, val in pairs(data) do
		wrapped[key] = SF.UnwrapObject(val) or val
	end
	return von.serialize(wrapped)
end

--- Deserializes table
-- @param Data String to deserialize
-- @return Deserialized table
function von_lib.deserialize(data)
	SF.CheckType(data, "string")
	local wrapped = von.deserialize(data)
	for key, val in pairs(wrapped) do
		wrapped[key] = sf_wrap_object(val)
	end
	return wrapped
end