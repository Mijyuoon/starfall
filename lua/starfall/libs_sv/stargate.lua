-------------------------------------------------------------------------------
-- Stargate library functions
-------------------------------------------------------------------------------

local sg_lib = SF.Libraries.Register("stargate")
local e_meta = SF.Entities.Metatable

local unwrap = SF.Entities.Unwrap
--local isowner = SF.Entities.CheckAccess
local function isowner(e)
	return SF.Entities.CanModify(SF.instance.player, e)
end

local vgate = {"stargate_movie","stargate_sg1","stargate_infinity","stargate_universe"}
local function ValidGate(gt)
	local class = gt:GetClass()
	if not table.HasValue(vgate, class) then
		return nil
	end
	return (class == "stargate_universe") and "Gate" or "Ring"
end

function sg_lib.getRingAngle(gate)
	SF.CheckType(gate, e_meta)
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate then
		local gx = ValidGate(gate)
		if not gx then
			return -1 
		end
		local ang = gate[gx]:GetLocalAngles().r
		return math.NormalizeAngle(ang) + 180
	end
	return -1
end

function sg_lib.dialGate(gate, addr, mode)
	SF.CheckType(gate, e_meta)
	SF.CheckType(addr, "string")
	SF.CheckType(mode, "number")
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate and isowner(gate) then
		if mode > 1 then
			gate:NoxDialGate(addr:upper())
		else
			gate:DialGate(addr:upper(), mode > 0)
		end
	end
end

function sg_lib.closeGate(gate)
	SF.CheckType(gate, e_meta)
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate and isowner(gate) then
		gate:AbortDialling()
	end
end

function sg_lib.irisActive(gate)
	SF.CheckType(gate, e_meta)
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate then
		return gate:IsBlocked(1,1)
	end
	return false
end

function sg_lib.irisToggle(gate)
	SF.CheckType(gate, e_meta)
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate and isowner(gate) then
		gate:IrisToggle()
	end
end

function sg_lib.overloadPerc(gate)
	SF.CheckType(gate, e_meta)
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate then
		local pow = gate.excessPower or 0
		local lim = gate.excessPowerLimit or 1
		return math.Clamp(100*pow/lim, 0, 100)
	end
	return nil
end

function sg_lib.overloadTime(gate)
	SF.CheckType(gate, e_meta)
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate then
		if not IsValid(gate.overloader) then
			return -1
		elseif not gate.overloader.isFiring then
			return -1
		elseif gate.isOverloading then
			return 0
		end
		local pow = gate.excessPower or 0
		local lim = gate.excessPowerLimit or 1
		local sec = gate.overloader.energyPerSecond or 1
		local time_left = (lim-pow) / sec
		if StarGate.IsIrisClosed(gate) then
			time_left = time_left * 2
		end
		return time_left
	end
	return nil
end

function sg_lib.getAddressList(gate)
	SF.CheckType(gate, e_meta)
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate then
		return gate:WireGetAddresses()
	end
	return nil
end

function sg_lib.getGateDistance(gate, addr)
	SF.CheckType(gate, e_meta)
	SF.CheckType(addr, "string")
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate then
		addr = addr:upper():sub(1,9)
		return gate:WireGetEnergy(addr, true)
	end
	return nil
end

function sg_lib.gateUnstable(gate)
	SF.CheckType(gate, e_meta)
	gate = unwrap(gate)
	if IsValid(gate) and gate.IsStargate then
		local eh = gate.EventHorizon
		return (IsValid(eh) and eh.Unstable)
	end
	return false
end