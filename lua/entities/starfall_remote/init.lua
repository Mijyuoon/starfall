AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

include("starfall/SFLib.lua")
assert(SF, "Starfall didn't load correctly!")

ENT.WireDebugName = "Starfall Remote"
ENT.OverlayDelay = 0

local libs = SF.Libraries.CreateLocalTbl{"input"}
local Context = SF.CreateContext(nil, nil, nil, libs)

function ENT:UpdateState(state)
	if self.name then
		self:SetOverlayText("Starfall Remote\n"..self.name)
	else
		self:SetOverlayText("Starfall Remote")
	end
end

util.AddNetworkString("starfall_remote_link")
util.AddNetworkString("starfall_remote_input")

net.Receive("starfall_remote_link", function(_, ply)
	local ent = net.ReadEntity()
	local ply2 = SF.WrapObject(ply)
	local status = net.ReadBool()
	if status then
		local old = ply.SFRemote_Link
		if IsValid(old) then
			old:runScriptHook("link", ply2, false)
		end
		ply.SFRemote_Link = ent
		ent:runScriptHook("link", ply2, true)
	else
		ply.SFRemote_Link = nil
		ent:runScriptHook("link", ply2, false)
	end
end)

function ENT:Use(activator)
	-- Empty for now
end

function ENT:Think()
	self:NextThink(CurTime())
	
	if self.instance and not self.instance.error then
		self:runScriptHook("think")
		self:resetCpuTime()
	end
	
	return true
end

function ENT:SetContextBase()
	self.SFContext = Context
	self:UpdateState()
end

function ENT:HandleButtonPress(ply, vkey)
	local ins = self.instance
	if not ins or ins.data.clSendInput then
		net.Start("starfall_remote_input")
			net.WriteEntity(self)
			net.WriteBool(true)
			net.WriteUInt(vkey, 8)
			net.WriteEntity(ply)
		net.Broadcast()
	end
	if self.sharedscreen then
		local ply2 = SF.WrapObject(ply)
		self:runScriptHook("button", ply2, vkey)
	end
end

function ENT:HandleKeyInput(ply, vkey, st)
	local ins = self.instance
	if not ins or ins.data.clSendInput then
		net.Start("starfall_remote_input")
			net.WriteEntity(self)
			net.WriteBool(false)
			net.WriteUInt(vkey, 8)
			net.WriteBool(st)
			net.WriteEntity(ply)
		net.Broadcast()
	end
	if self.sharedscreen then
		local ply2 = SF.WrapObject(ply)
		self:runScriptHook("keyinput", ply2, vkey, st)
	end
end