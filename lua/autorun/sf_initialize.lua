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
	
	local function DrawScreen(X,Y,RTarg,Scl)
		local OldTex = WireGPU_matScreen:GetTexture("$basetexture")
		WireGPU_matScreen:SetTexture("$basetexture", RTarg)
		
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(WireGPU_matScreen)
		surface.DrawTexturedRectRotated(X,Y,Scl,Scl,0)
		
		WireGPU_matScreen:SetTexture("$basetexture", OldTex)
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

	HudSF = HudSF or {
		Scale = 2,
		DrawBG = true,
		ScrA = false,
		ScrB = false,
	}

	hook.Add("HUDPaint", "SF_1", function()
		local W, H = ScrW(), ScrH()
		local scra, scrb = HudSF.ScrA, HudSF.ScrB
		if scra and not scrb then
			if HudSF.DrawBG then
				surface.SetDrawColor(0,0,0,240)
				surface.DrawRect(0,0,W,H)
			end
			local offs = HudSF_Scale(HudSF.Scale, false)
			scra.GPU:RenderToGPU(scra.renderfunc)
			DrawScreen(W/2, H/2, scra.GPU.RT, offs*2)
		elseif scra and scrb then
			if HudSF.DrawBG then
				surface.SetDrawColor(0,0,0,240)
				surface.DrawRect(0,0,W,H)
			end
			scra.GPU:RenderToGPU(scra.renderfunc)
			scrb.GPU:RenderToGPU(scrb.renderfunc)
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
	hook.Add("HUDShouldDraw", "SF_1", function(name)
		if HudSF.ScrA and disable_hud[name] then
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

end

_MLOADED = {}
function loadmodule(name)
	if _MLOADED[name] then
		return _MLOADED[name]
	end
	
	local kname = name:gsub("%.","/") .. ".lua"
	if not file.Exists(kname, "LUA") then
		error("cannot find module \"" .. name .. "\"")
	end
	
	local func = CompileFile(kname, name)
	if func then
		_MLOADED[name] = func() or true
		return _MLOADED[name]
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