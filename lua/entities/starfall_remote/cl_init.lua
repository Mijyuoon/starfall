include('shared.lua')

ENT.RenderGroup = RENDERGROUP_OPAQUE

include("starfall/SFLib.lua")
assert(SF, "Starfall didn't load correctly!")
local libs = SF.Libraries.CreateLocalTbl{"render", "input"}
local Context = SF.CreateContext(nil, nil, nil, libs)

surface.CreateFont("Starfall_ErrorFontBig", {
	font = "Arial",
	size = 40,
	weight = 400,
})

net.Receive("starfall_remote_input", function()
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end
	local mode = net.ReadBool()
	if mode then
		local keyid = net.ReadUInt(8)
		local ply = SF.WrapObject(net.ReadEntity())
		ent:runScriptHook("button", ply, keyid)
	else
		local vkey = net.ReadUInt(8)
		local st = net.ReadBool()
		local ply = SF.WrapObject(net.ReadEntity())
		ent:runScriptHook("keyinput", ply, vkey, st)
	end
end)

function ENT:SetContextBase()
	self.SFContext = Context
end

function ENT:SetRenderFunc(data)
	function self.renderfunc()
		if self.instance then
			data.render.isRendering = true
			self:runScriptHook("render", self.DrawTarget)
			data.render.isRendering = nil
		elseif self.error then
			surface.SetTexture(0)
			surface.SetDrawColor(0, 0, 0, 140)
			surface.DrawRect(0, 0, ScrW(), ScrH())
			
			draw.DrawText("Error occurred in Starfall Remote:", "Starfall_ErrorFontBig", 32, 16, Color(0, 255, 255, 255))
			draw.DrawText(tostring(self.error.msg), "Starfall_ErrorFontBig", 16, 80, Color(255, 0, 0, 255))
			if self.error.source and self.error.line then
				draw.DrawText("Line: "..tostring(self.error.line), "Starfall_ErrorFontBig", 16, ScrH()-16*7, Color(255, 255, 255, 255))
				draw.DrawText("Source: "..self.error.source, "Starfall_ErrorFontBig", 16, ScrH()-16*5, Color(255, 255, 255, 255))
			end
			self.renderfunc = nil
		end
	end
end

function ENT:Initialize()
	self:SetContextBase()
	self.files = {}
	net.Start("starfall_screen_download")
	net.WriteInt(SF_UPLOAD_INIT, 8)
	net.WriteEntity(self)
	net.SendToServer()
end

function ENT:OnRemove()
	local vtab = self:GetTable()
	timer.Simple(0.1, function()
		if IsValid(self) then return end
		if not vtab.instance then return end
		if not vtab.instance.error then
			vtab:runScriptHook("last")
		end
		vtab.instance:deinitialize()
	end)
end

function ENT:Think()
	self:NextThink(CurTime())
	
	if self.instance and not self.instance.error then
		self:runScriptHook("think")
		self:resetCpuTime()
	end
end

function ENT:SetViewPort(x, y, w, h)
	local inst = self.instance
	if not inst then return end
	local vp = inst.data.render.viewport
	vp.x, vp.y, vp.w, vp.h = x, y, w, h
end

function ENT:DrawScreen(ply)
	--if not self.WasFrameDrawn and self.renderfunc then -- Wtf?
	if self.renderfunc then
		self.DrawTarget = SF.WrapObject(ply)
		local ok, err = xpcall(self.renderfunc, debug.traceback)
		if not ok then WireLib.ErrorNoHalt(err) end
		--self.WasFrameDrawn = true -- Wtf?
	end
end

function ENT:Draw()
	self:DoNormalDraw()
	Wire_Render(self)
end