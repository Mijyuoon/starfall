local updateCheckDone = false
local updateUrl = "https://raw.github.com/Mijyuoon/starfall/master/lua/starfall/version.lua"
local updateMsg = [[
Your copy of Starfall is out of date!
Your version: %d   Latest version: %d
Please update to get new features and bug fixes!]]

if SERVER then
	AddCSLuaFile()
	AddCSLuaFile("moonscript/base.lua")
	AddCSLuaFile("moonscript/compile.lua")
	AddCSLuaFile("moonscript/data.lua")
	AddCSLuaFile("moonscript/dump.lua")
	AddCSLuaFile("moonscript/errors.lua")
	AddCSLuaFile("moonscript/line_tables.lua")
	AddCSLuaFile("moonscript/lpeg_re.lua")
	AddCSLuaFile("moonscript/lulpeg.lua")
	AddCSLuaFile("moonscript/parse.lua")
	AddCSLuaFile("moonscript/transform.lua")
	AddCSLuaFile("moonscript/types.lua")
	AddCSLuaFile("moonscript/util.lua")
	
	AddCSLuaFile("moonscript/compile/statement.lua")
	AddCSLuaFile("moonscript/compile/value.lua")
	
	AddCSLuaFile("moonscript/transform/names.lua")
	AddCSLuaFile("moonscript/transform/destructure.lua")
	
	resource.AddFile( "materials/models/spacecode/glass.vmt" )
	resource.AddFile( "materials/models/spacecode/sfchip.vmt" )
	resource.AddFile( "materials/models/spacecode/sfpcb.vmt" )
	resource.AddFile( "models/spacecode/sfchip.mdl" )
	resource.AddFile( "models/spacecode/sfchip_medium.mdl" )
	resource.AddFile( "models/spacecode/sfchip_small.mdl" )
	
	util.AddNetworkString("SF_hudscreen")
else
	list.Set( "Starfall_gate_Models", "models/spacecode/sfchip.mdl", true )
	list.Set( "Starfall_gate_Models", "models/spacecode/sfchip_medium.mdl", true )
	list.Set( "Starfall_gate_Models", "models/spacecode/sfchip_small.mdl", true )

	HudSF = HudSF or {
		Scale = 2,
		DrawBG = true,
		ScrA = false,
		ScrB = false,
	}
	
	local function DrawScreen(X,Y,RTarg,Scl)
		local mat = WireGPU_matScreen
		local OldTex = mat:GetTexture("$basetexture")
		mat:SetTexture("$basetexture", RTarg)
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(mat)
		surface.DrawTexturedRectRotated(X,Y,Scl,Scl,0)
		mat:SetTexture("$basetexture", OldTex)
	end

	local function HudSF_Scale(mode, dbl)
		local W,H = ScrW()/2, ScrH()/2
		local mode = mode or 0
		if mode == 0 then
			return 256
		elseif mode == 1 then
			if not dbl then return H end
			return math.min(W/2, H)
		elseif mode == 2 then
			return math.min(W/2, H)
		end
	end
	
	local function ValidScr(scrn)
		return (IsValid(scrn) and scrn.GPU)
	end

	hook.Add("Think", "SF_HUD", function()
		local scra, scrb = HudSF.ScrA, HudSF.ScrB
		if not ValidScr(scra) then
			scra, scrb = ValidScr(scrb) and scrb, false
			HudSF.ScrA, HudSF.ScrB = scra, false
		end
		if not ValidScr(scrb) then
			scrb, HudSF.ScrB = false, false
		end
		if scra and not scrb then
			scra:DrawScreen()
		elseif scra and scrb then
			scra:DrawScreen()
			scrb:DrawScreen()
		end
	end)
	
	hook.Add("HUDPaint", "SF_HUD", function()
		local W, H = ScrW(), ScrH()
		local scra, scrb = HudSF.ScrA, HudSF.ScrB
		if ValidScr(scra) and not ValidScr(scrb) then
			if HudSF.DrawBG then
				surface.SetDrawColor(0,0,0,240)
				surface.DrawRect(0,0,W,H)
			end
			local offs = HudSF_Scale(HudSF.Scale, false)
			DrawScreen(W/2, H/2, scra.GPU.RT, offs*2)
		elseif ValidScr(scra) and ValidScr(scrb) then
			if HudSF.DrawBG then
				surface.SetDrawColor(0,0,0,240)
				surface.DrawRect(0,0,W,H)
			end
			local offs = HudSF_Scale(HudSF.Scale, true)
			DrawScreen(W/2 - offs, H/2, scra.GPU.RT, offs*2)
			DrawScreen(W/2 + offs, H/2, scrb.GPU.RT, offs*2)
		end
	end)

	local disable_hud = {
		CHudHealth = true,
		CHudSuitPower = true,
		CHudBattery = true,
		CHudCrosshair = true,
		CHudAmmo = true,
		CHudSecondaryAmmo = true,
	}
	
	hook.Add("HUDShouldDraw", "SF_HUD", function(name)
		if ValidScr(HudSF.ScrA) and disable_hud[name] then
			return false
		end
	end)

	net.Receive("SF_hudscreen", function()
		local scrn = net.ReadInt(8)
		if scrn == 0 then
			HudSF.ScrA = false
			HudSF.ScrB = false
		elseif scrn == 1 then
			local cent = net.ReadEntity()
			HudSF.ScrA = IsValid(cent) and cent
		elseif scrn == 2 then
			local cent = net.ReadEntity()
			HudSF.ScrB = IsValid(cent) and cent
		end
	end)
	
	--- Update check code ----------------------
	--------------------------------------------
	local function DisplayUpdateMsg(vCur, vLast)
		local updateWnd = vgui.Create("DFrame")
		updateWnd:SetTitle("Starfall update reminder")
		updateWnd:SetSize(380, 120)
		updateWnd:SetPos(100, 100)
		updateWnd:SetVisible(true)
		updateWnd:SetDraggable(true)
		updateWnd:MakePopup()
		local wndPaint = updateWnd.Paint
		updateWnd.Paint = function(self, w, h)
			wndPaint(self, w, h)
			local msg = Format(updateMsg, vCur, vLast)
			draw.DrawText(msg, "ScoreboardText", w/2, 30, color_white, 1)
		end
		
		local updateWndB = vgui.Create("DButton", updateWnd)
		updateWndB:SetText("Close")
		updateWndB:SetPos(290, 85)
		updateWndB:SetSize(80, 25)
		updateWndB.DoClick = function()
			updateWnd:Close()
		end
	end

	local function GetVersion(dat)
		dat = (dat or ""):match("^SF.Version=(%d+)$")
		return tonumber(dat)
	end
	
	local function CheckForUpdates(_, key)
		if key ~= "+menu" then return end
		if updateCheckDone then return end
		http.Fetch(updateUrl, function(dat)
			local last_ver = GetVersion(dat)
			if last_ver and SF_Version < last_ver then
				DisplayUpdateMsg(SF_Version, last_ver)
			end
			updateCheckDone = true
		end)
	end
	
	SF_Version = GetVersion(file.Read("lua/starfall/version.lua", "GAME"))
	hook.Add("PlayerBindPress", "SF_UpdateCheck", CheckForUpdates)
end

_MODLOAD = {}
function loadmodule(name)
	if _MODLOAD[name] then
		return _MODLOAD[name]
	end
	
	local kname = name:gsub("%.","/") .. ".lua"
	local is_sv = file.Exists(kname, "LUA")
	local is_cl = file.Exists(kname, "LCL")
	if not (is_sv or is_cl) then
		error("cannot find module \"" .. name .. "\"")
	end
	
	local func = CompileFile(kname, name)
	if func then
		_MODLOAD[name] = func() or true
		return _MODLOAD[name]
	end
end

package.moonpath = ""
moonscript = loadmodule "moonscript.base"

if not util.Base64Decode then
	local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

	function util.Base64Decode(data)
		data = string.gsub(data, '[^'..b..'=]', '')
		return (data:gsub('.', function(x)
			if (x == '=') then return '' end
			local r,f='',(b:find(x)-1)
			for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
			return r;
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c=0
			for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
			return string.char(c)
		end))
	end
end