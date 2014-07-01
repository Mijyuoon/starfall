/********************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
	   
	   
	DESCRIPTION:
		This script is meant for experienced scripters 
		that KNOW WHAT THEY ARE DOING. Don't come to me 
		with basic Lua questions.
		
		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.
		
		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
********************************************************/

AddCSLuaFile()

SWEP.Category = "Wiremod"
SWEP.PrintName	= "SF Remote (Cell phone)"
SWEP.Purpose	= "Remote controler for Starfall Remote."
SWEP.Base		= "weapon_pda_base"

SWEP.Slot		= 0
SWEP.SlotPos	= 9
SWEP.Weight		= 5

SWEP.DeviceModel = "models/lt_c/tech/cellphone.mdl"
if util.IsValidModel(SWEP.DeviceModel) then
	SWEP.Spawnable	= true
	SWEP.AdminOnly	= true
end

SWEP.IronSightsPos = Vector(-2.9, -11.5, -5.6)
SWEP.IronSightsAng = Vector(42, 0, 0)

if CLIENT then
	SWEP.ViewModelBoneMods = {
		["mesh1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
	}
	SWEP.VElements = {
		["tablet"] = { type = "Model", model = SWEP.DeviceModel, bone = "mesh1", rel = "", pos = Vector(1.1, 0.4, 0.2), angle = Angle(0, -90, 0), size = Vector(1.1, 1.1, 1.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 11, bodygroup = {} }
	}
	SWEP.WElements = {
		["tablet"] = { type = "Model", model = SWEP.DeviceModel, bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.9, 2.6, -1.6), angle = Angle(90, 90, -90), size = Vector(1.1, 1.1, 1.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 11, bodygroup = {} }
	}
	SWEP.RenderTexture = "models/lt_c/tech/cellphone/screen_green"
	SWEP.RenderViewPort = {
		Left	= 241,
		Top		= 0,
		Width	= 542,
		Height	= 1024
	}
end

--[[
if CLIENT then
	local m_font = scr.CreateFont(nil,"OCR A Extended",48,400)
	local m_color = Color(0,255,155)
	
	function SWEP:RenderScreenFunc(wid, hgt)
		local mt_text = "<UNKNOWN>"
		local mt_date = os.date("%d/%m/%y %H:%M:%S")
		if IsValid(self.Owner) then
			mt_text = self.Owner:Name()
		end
		scr.DrawRectOL(10,10,wid-20,hgt-20,m_color,6)
		scr.DrawText(wid/2,hgt/2,mt_text,1,2,m_color,m_font)
		scr.DrawText(wid/2,hgt/2,mt_date,1,0,m_color,m_font)
	end
end
--]]

if CLIENT then
	function SWEP:ScreenShouldDraw()
		if not IsValid(self.Owner.SFRemote_Link) then
			return false, true
		end
		return true, false
	end
	function SWEP:RenderScreenFunc(wid, hgt)
		local link = self.Owner.SFRemote_Link
		local vp = self.RenderViewPort
		link:SetViewPort(vp.Left, vp.Top, vp.Width, vp.Height)
		link:DrawScreen()
	end
end

if SERVER then
	function SWEP:HandleKeyInput(vkey)
		local link = self.Owner.SFRemote_Link
		if not IsValid(link) then return end
		link:MouseKeyInput(vkey)
	end
end
