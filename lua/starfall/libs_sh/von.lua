--[[
	SF vON library by Wiremod Devs. I only made stupid wrapper.
]]

--- vON library, allows for serializing/deserializing tables.
-- @shared

local von_lib, _ = SF.Libraries.Register("von")

--- Serializes table
-- @param Data Table to serialize
-- @return String that represents serialized table

function von_lib.serialize(data)
	SF.CheckType(data, "table")
	return von.serialize(data)
end

--- Deserializes table
-- @param Data String to deserialize
-- @return Deserialized table

function von_lib.deserialize(data)
	SF.CheckType(data, "string")
	return von.deserialize(data)
end