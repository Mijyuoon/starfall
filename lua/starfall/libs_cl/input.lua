-------------------------------------------------------------------------------
-- Input library functions
-------------------------------------------------------------------------------

local input_lib = SF.Libraries.RegisterLocal("input")

local function getPdaObject(ply)
	ply = SF.UnwrapObject(ply)
	if not IsValid(ply) then return nil end
	local pda = ply.ActivePdaSystem
	if not IsValid(pda) then return nil end
	local ent = SF.instance.data.entity
	if ply.SFRemote_Link ~= ent then return nil end
	return ply, pda
end

--- Returns name of active input device
function input_lib.getDeviceName(ply)
	SF.CheckType(ply, SF.Types["Player"])
	
	local _, pda = getPdaObject(ply)
	if not pda then return nil end
	
	return pda.DeviceName or "<unknown>"
end