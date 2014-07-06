-------------------------------------------------------------------------------
-- Input library functions
-------------------------------------------------------------------------------

local input_lib = SF.Libraries.RegisterLocal("input")

SF.Libraries.AddHook("initialize", function(instance)
	instance.data.clSendInput = true
end)

local function getPdaObject(ply)
	ply = SF.UnwrapObject(ply)
	if not IsValid(ply) then return nil end
	local pda = ply.ActivePdaSystem
	if not IsValid(pda) then return nil end
	local ent = SF.instance.data.entity
	if ply.SFRemote_Link ~= ent then return nil end
	return ply, pda
end

--- Enables sending of input data to client
function input_lib.sendToClient(flag)
	SF.CheckType(flag, "boolean")
	SF.instance.data.clSendInput = flag
end

--- Remaps key scancode to ASCII char code
function input_lib.keyToChar(ply, key, opt)
	SF.CheckType(ply, SF.Types["Player"])
	SF.CheckType(key, "number")
	SF.CheckType(opt, "boolean")
	if key < 1 or key > KEY_LAST then return nil end
	
	local ply, pda = getPdaObject(ply)
	if not pda then return nil end
	local layout = ply:GetInfo("wire_keyboard_layout", "American")
	
	local current = Wire_Keyboard_Remap[layout]
	if not current then return nil end
	local ret = current.normal[key]
	
	for kx, st in pairs(pda.KeyStateBuffer) do
		if st and current[kx] and current[kx][key] then
			ret = current[kx][key]
		end
	end
	
	if opt and isstring(ret) then return ret:byte() end
	return ret
end

--- Returns state of key with given scancode
function input_lib.getKeyState(ply, key)
	SF.CheckType(ply, SF.Types["Player"])
	SF.CheckType(key, "number")
	
	local _, pda = getPdaObject(ply)
	if not pda then return nil end
	
	return pda.KeyStateBuffer[key] and true or false
end

--- Returns name of active input device
function input_lib.getDeviceName(ply)
	SF.CheckType(ply, SF.Types["Player"])
	
	local _, pda = getPdaObject(ply)
	if not pda then return nil end
	
	return pda.DeviceName or "<unknown>"
end