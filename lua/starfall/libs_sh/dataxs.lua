--[[
	DataXS library by Mijyuoon.
]]

local xs_lib, _ = SF.Libraries.Register("dataxs")

local xs_groups = {}
SF.DataXS = {
	Library = xs_lib,
	Groups  = xs_groups,
}

function xs_lib.joinGroup(name)
	SF.CheckType(name, "string")
	if #name < 1 then
		return false
	end
	local this = SF.instance.data.entity
	if not xs_groups[name] then
		xs_groups[name] = {n=0}
	end
	local group = xs_groups[name]
	if group[this] then
		return false
	end
	group[this] = SF.instance
	group.n = group.n + 1
	return true
end

local function leaveGroup(instance, name)
	local this = instance.data.entity
	local group = xs_groups[name]
	if not group or not group[this] then
		return false
	end
	group[this] = nil
	group.n = group.n - 1
	if group.n == 0 then
		xs_groups[name] = nil
	end
	return true
end

function xs_lib.leaveGroup(name)
	SF.ChckType(name, "string")
	return leaveGroup(SF.instance, name)
end

local function IsAllowed(ins1, ins2, all)
	if all then return true end
	return (ins1.player == ins2.player)
end

local function IsTarget(target, this)
	if target == "n" then return false end
	return (IsValid(target) and target ~= this)
end

function xs_lib.sendGroup(group, all, ...)
	SF.CheckType(group, "string")
	SF.CheckType(all, "boolean")
	if #group < 1 then return end
	if not xs_groups[group] then return end
	local instance = SF.instance
	local this = instance.data.entity
	for targ, hins in pairs(xs_groups[group]) do
		if IsTarget(targ, this) and IsAllowed(instance, hins, all) then
			targ:runScriptHook("dataxs", group, ...)
		end
	end
end

function xs_lib.sendDirect(ent, ...)
	SF.CheckType(ent, SF.Entities.Metatable)
	local chip = SF.Entities.Unwrap(ent)
	local instance = SF.instance
	local this = instance.data.entity
	if IsTarget(chip, this) then
		chip:runScriptHook("dataxs", false, ...)
	end
end

SF.Libraries.AddHook("deinitialize", function(instance)
	for group, _ in pairs(xs_groups) do
		leaveGroup(instance, group)
	end
end)