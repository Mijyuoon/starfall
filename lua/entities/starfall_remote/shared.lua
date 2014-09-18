ENT.Type            = "anim"
ENT.Base            = "starfall_screen"

ENT.PrintName       = "Starfall"
ENT.Author          = "Mijyuoon"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.SFAcceptNetMsg	= true

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