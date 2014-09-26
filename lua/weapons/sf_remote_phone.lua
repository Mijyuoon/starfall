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

SWEP.DeviceName = "Phone-A"
SWEP.DeviceModel = "models/tablet/cellphone.mdl"
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
	SWEP.RenderTexture = "models/cellphone/screen_green"
	SWEP.RenderViewPort = {
		Left	= 241,
		Top		= 0,
		Width	= 542,
		Height	= 1024
	}
end

if CLIENT then
	function SWEP:ScreenShouldDraw()
		if IsValid(self.Owner.SFRemote_Link) then
			return true, false
		end
		return false, true
	end
	function SWEP:RenderScreenFunc(wid, hgt)
		local link = self.Owner.SFRemote_Link
		local vp = self.RenderViewPort
		link:SetViewPort(vp.Left, vp.Top, vp.Width, vp.Height)
		link:DrawScreen(self.Owner)
	end
end

if SERVER then
	function SWEP:HandleButtonPress(ply, vkey)
		local link = self.Owner.SFRemote_Link
		if not IsValid(link) then return end
		link:HandleButtonPress(ply, vkey)
	end
	
	function SWEP:HandleKeyInput(ply, vkey, st)
		local link = self.Owner.SFRemote_Link
		if not IsValid(link) then return end
		link:HandleKeyInput(ply, vkey, st)
	end
end
