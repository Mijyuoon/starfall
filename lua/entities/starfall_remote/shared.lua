ENT.Type            = "anim"
ENT.Base            = "starfall_screen"

ENT.PrintName       = "Starfall Remote"
ENT.Author          = "Mijyuoon"

ENT.Spawnable       = false
ENT.AdminSpawnable  = false
ENT.SFAcceptNetMsg	= true

function ENT:runScriptHook(hook, ...)
	if self.instance and not self.instance.error and self.instance.hooks[hook:lower()] then
		local ok, rt = self.instance:runScriptHook(hook, ...)
		if not ok then self:Error(rt)
		else return rt end
	end
end

function ENT:runScriptHookForResult(hook,...)
	if self.instance and not self.instance.error and self.instance.hooks[hook:lower()] then
		local ok, rt = self.instance:runScriptHookForResult(hook, ...)
		if not ok then self:Error(rt)
		else return rt end
	end
end