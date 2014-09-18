AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

include("starfall/SFLib.lua")
assert(SF, "Starfall didn't load correctly!")

ENT.WireDebugName = "Starfall Processor"
ENT.OverlayDelay = 0

local Context = SF.CreateContext()

function ENT:UpdateState(state)
	if self.name then
		self:SetOverlayText("Starfall Processor\n"..self.name.."\n"..state)
	else
		self:SetOverlayText("Starfall Processor\n"..state)
	end
end

function ENT:SetContextBase()
	self.SFContext = Context
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	self:SetContextBase()
	self.Inputs = WireLib.CreateInputs(self, {})
	self.Outputs = WireLib.CreateOutputs(self, {})
	
	self:UpdateState("Inactive (No code)")
	local clr = self:GetColor()
	self:SetColor(Color(255, 0, 0, clr.a))
end

function ENT:CodeSent(ply, codetbl, mainfile)
	if ply ~= self.owner then return end
	
	if self.instance then
		self:runScriptHook("last")
		self.instance:deinitialize() 
	end
	
	local ok, instance = SF.Compiler.Compile(codetbl,self.SFContext,mainfile,self.owner)
	if not ok then self:Error(instance) return end
	
	instance.runOnError = function(inst,...) self:Error(...) end
	
	self.instance = instance
	instance.data.entity = self
	
	local ok, msg = instance:initialize()
	if not ok then
		self:Error(msg)
		return
	end
	
	if not self.instance then return end

	self.name = nil

	if self.instance.ppdata.scriptnames and self.instance.mainfile and self.instance.ppdata.scriptnames[self.instance.mainfile] then
		self.name = tostring(self.instance.ppdata.scriptnames[self.instance.mainfile])
	end

	if not self.name or string.len(self.name) <= 0 then
		self.name = "generic"
	end

	self:UpdateState("(None)")
	local clr = self:GetColor()
	self:SetColor(Color(255, 255, 255, clr.a))
end

function ENT:Error(msg, traceback)
	if type( msg ) == "table" then
		if msg.message then
			local line = msg.line
			local file = msg.file

			msg = ( file and ( file .. ":" ) or "" ) .. ( line and ( line .. ": " ) or "" ) .. msg.message
		end
	end
	ErrorNoHalt(Format("Processor of %s errored: %s\n", self.owner:Nick(), msg))
	if traceback then
		print(traceback)
	end
	WireLib.ClientError(msg, self.owner)
	
	if self.instance then
		self.instance:deinitialize()
		self.instance = nil
	end
	
	self:UpdateState("Inactive (Error)")
	local clr = self:GetColor()
	self:SetColor(Color(255, 0, 0, clr.a))
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if self.instance and not self.instance.error then
		local slice = self.instance:getCpuTimeAvg()
		local limit = self.instance.context.slice()
		self:UpdateState(Format("%.2f ms, %.2f%%", slice * 1000, slice / limit))
		self:runScriptHook("think")
		self:resetCpuTime()
	end

	self:NextThink(CurTime())
	return true
end

function ENT:OnRemove()
	if not self.instance then return end
	self:runScriptHook("last")
	self.instance:deinitialize()
	self.instance = nil
end

function ENT:TriggerInput(key, value)
	self:runScriptHook("input", key, SF.Wire.InputConverters[self.Inputs[key].Type](value))
end

function ENT:ReadCell(address)
	return tonumber(self:runScriptHookForResult("readcell",address)) or 0
end

function ENT:WriteCell(address, data)
	self:runScriptHook("writecell",address,data)
end

function ENT:resetCpuTime()
	if self.instance then
		self.instance:resetCpuTime()
	end
end

function ENT:runScriptHook(hook, ...)
	if self.instance and not self.instance.error and self.instance.hooks[hook:lower()] then
		local instance = SF.instance
		SF.instance = nil
		local ok, rt = self.instance:runScriptHook(hook, ...)
		SF.instance = instance
		if not ok then self:Error(rt) end
	end
end

function ENT:runScriptHookForResult(hook,...)
	if self.instance and not self.instance.error and self.instance.hooks[hook:lower()] then
		local instance = SF.instance
		SF.instance = nil
		local ok, rt = self.instance:runScriptHookForResult(hook, ...)
		SF.instance = instance
		if not ok then self:Error(rt)
		else return rt end
	end
end

function ENT:OnRestore()
end

function ENT:BuildDupeInfo()
	local info = WireLib.BuildDupeInfo(self) or {}
	if self.instance then
		info.starfall = SF.SerializeCode(self.instance.source, self.instance.mainfile)
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.owner = ply
	if info.starfall then
		local code, main = SF.DeserializeCode(info.starfall)
		self:CodeSent(code, main)
	end
	WireLib.ApplyDupeInfo(ply, ent, info, GetEntByID)
end

local tmp_instance = {}
function ENT:PreEntityCopy()
	local info = self:BuildDupeInfo()
	tmp_instance[self] = self.instance
	self.instance = nil
	if not info then return end
	duplicator.StoreEntityModifier(self, "SFDupeInfo", info)
end

function ENT:PostEntityCopy()
	self.instance = tmp_instance[self]
end

local function EntLookup(created)
	return function(id, def)
		local ent = created[id]
		return (IsValid(ent) and ent or def)
	end
end

function ENT:PostEntityPaste(ply, ent, created)
	if ent.EntityMods and ent.EntityMods.SFDupeInfo then
		ent:ApplyDupeInfo(ply, ent, ent.EntityMods.SFDupeInfo, EntLookup(created))
	end
end
