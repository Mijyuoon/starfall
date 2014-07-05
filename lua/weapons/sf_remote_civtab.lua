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
SWEP.PrintName	= "SF Remote (Tablet)"
SWEP.Purpose	= "Remote controler for Starfall Remote."
SWEP.Base		= "weapon_pda_base"

SWEP.Slot		= 0
SWEP.SlotPos	= 9
SWEP.Weight		= 5

SWEP.DeviceModel = "models/lt_c/tech/tablet_civ.mdl"
if util.IsValidModel(SWEP.DeviceModel) then
	SWEP.Spawnable	= true
	SWEP.AdminOnly	= true
end

SWEP.IronSightsPos = Vector(2, -9.2, -6.6)
SWEP.IronSightsAng = Vector(38, 0, 0)

if CLIENT then
	SWEP.ViewModelBoneMods = {
		["mesh1"] = { scale = Vector(0.009, 0.009, 0.009), pos = Vector(0, 0, 0), angle = Angle(0, 0, 0) }
	}
	SWEP.VElements = {
		["tablet"] = { type = "Model", model = SWEP.DeviceModel, bone = "mesh1", rel = "", pos = Vector(-3, 0, 0.3), angle = Angle(0, -90, 0), size = Vector(1.1, 1.1, 1.1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 12, bodygroup = {} }
	}
	SWEP.WElements = {
		["tablet"] = { type = "Model", model = SWEP.DeviceModel, bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(3.9, 6.1, -1.8), angle = Angle(90, 90, -90), size = Vector(1, 1, 1), color = Color(255, 255, 255, 255), surpresslightning = false, material = "", skin = 12, bodygroup = {} }
	}
	SWEP.RenderTexture = "models/lt_c/tablet/screen10"
	SWEP.RenderViewPort = {
		Left	= 14,
		Top		= 146,
		Width	= 996,
		Height	= 736
	}
end

--[[
if CLIENT then
	local m_font = scr.CreateFont(nil,"OCR A Extended",48,400)
	local m_color = Color(0,255,155)
	local r_color = Color(255,0,0)
	
	function SWEP:RenderScreenFunc(wid, hgt)
		local cx, cy = wid/2, hgt/2
		local ply = LocalPlayer()
		local ang = math.floor(ply:EyeAngles().y)
		
		local a2 = (ang == -180) and 0 or (360-(180+ang))
		scr.DrawText(20,20,Format("Angle: %03d", a2),0,0,m_color,m_font)
		
		local dis, dn = cy-60, 40
		local range = 10000
		local lx1, ly1, lx2, ly2 = 0, 0, 0, 0
		for w = 0, 360-10, 10 do
			if w == 0 then
				local vsin, vcos = math.sin(math.rad(w + ang)), math.cos(math.rad(w + ang)) 
				lx1, ly1 = cx + vsin * (dis + 3), cy + vcos * (dis + 3)
				local u1,v1 = cx + vsin * (dis + dn), cy + vcos * (dis + dn)
				local u2,v2 = cx + math.sin(math.rad(w + ang - 6)) * dis, cy + math.cos(math.rad(w + ang - 6)) * dis
				local u3,v3 = cx + math.sin(math.rad(w + ang + 6)) * dis, cy + math.cos(math.rad(w + ang + 6)) * dis
				scr.DrawTriang(u1, v1, u2, v2, u3, v3, m_color)
			elseif w == 180 then
				local vsin, vcos = math.sin(math.rad(w + ang)), math.cos(math.rad(w + ang)) 
				lx2, ly2 = cx + vsin * (dis + dn - 3), cy + vcos * (dis + dn - 3)
				local u1,v1 = cx + vsin * dis, cy + vcos * dis
				local u2,v2 = cx + math.sin(math.rad(w + ang - 6)) * (dis + dn), cy + math.cos(math.rad(w + ang - 6)) * (dis + dn)
				local u3,v3 = cx + math.sin(math.rad(w + ang + 6)) * (dis + dn), cy + math.cos(math.rad(w + ang + 6)) * (dis + dn)
				scr.DrawTriang(u1, v1, u2, v2, u3, v3, m_color)
			else
				scr.DrawLine(cx + math.sin(math.rad(w + ang)) * dis, cy + math.cos(math.rad(w + ang)) * dis,
					cx + math.sin(math.rad(w + ang)) * (dis+dn), cy + math.cos(math.rad(w + ang)) * (dis + dn), m_color, 5)
			end
		end
		
		scr.DrawLine(lx1, ly1, lx2, ly2, m_color, 3)
		
		scr.DrawLine(cx, cy-80, cx, cy+80, m_color, 5)
		scr.DrawLine(cx-80, cy, cx+80, cy, m_color, 5)
		
		for _, v in pairs(ents.FindByClass("npc_*")) do
			local oa = ( v:GetPos() - ply:GetPos() ):Angle().y
			local dist = math.Clamp(ply:GetPos():Distance2D(v:GetPos())/range, 0, 1)*(dis-6)
			local u,v = cx + math.sin(math.rad(oa)) * dist, cy + math.cos(math.rad(oa))*dist
			local point = scr.Circle(u, v, 8, 8, 0, 15)
			scr.DrawPoly(point, r_color)
		end
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
