
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

include("starfall/SFLib.lua")
assert(SF, "Starfall didn't load correctly!")
local Context = SF.CreateContext()

util.AddNetworkString("starfall_remote_link")
util.AddNetworkString("starfall_remote_input")

function ENT:Use(activator)
	if activator:IsPlayer() then
		local lk = activator.SFRemote_Link
		net.Start("starfall_remote_link")
			net.WriteEntity(activator)
			net.WriteEntity(self)
			local ply2 = SF.Entities.Wrap(activator)
			if lk == self then
				activator:ChatPrint(Format("Unlinked controller [%d]", self:EntIndex()))
				activator.SFRemote_Link = nil
				self:runScriptHook("link", ply2, false)
				net.WriteBit(false)
			else
				activator:ChatPrint(Format("Linked controller [%d]", self:EntIndex()))
				if IsValid(lk) then
					lk:runScriptHook("link", ply2, false)
				end
				activator.SFRemote_Link = self
				self:runScriptHook("link", ply2, true)
				net.WriteBit(true)
			end
		net.Broadcast()
	end
end

function ENT:Think()
	self:NextThink(CurTime())
	
	if self.instance and not self.instance.error then
		self.instance:resetOps()
		self:runScriptHook("think")
	end
	
	return true
end

function ENT:SetContextBase()
	self.SFContext = Context
end

function ENT:MouseKeyInput(key)
	net.Start("starfall_remote_input")
		net.WriteEntity(self)
		net.WriteBit(true)
		net.WriteUInt(key, 8)
	net.Broadcast()
	if self.sharedscreen then
		self:runScriptHook("click", key)
	end
end