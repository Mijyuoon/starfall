ENT.Type            = "anim"
ENT.Base            = "base_wire_entity"

ENT.PrintName       = "Starfall"
ENT.Author          = "Colonel Thirty Two"
ENT.Contact         = "initrd.gz@gmail.com"
ENT.Purpose         = ""
ENT.Instructions    = ""

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.SFAcceptNetMsg	= true

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
		if not ok then self:Error(rt)
		else return rt end
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