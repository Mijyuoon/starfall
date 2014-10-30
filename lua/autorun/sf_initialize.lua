AddCSLuaFile()
local updateCheckDone = false
local updateUrl = "https://raw.github.com/Mijyuoon/starfall/master/lua/starfall/version.lua"
local updateMsg = [[
Your copy of Starfall is out of date!
Your version: $cur   Latest version: $last
Please update to get new features and bug fixes!]]

if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/models/spacecode/glass.vmt")
	resource.AddFile("materials/models/spacecode/sfchip.vmt")
	resource.AddFile("materials/models/spacecode/sfpcb.vmt")
	resource.AddFile("models/spacecode/sfchip.mdl")
	resource.AddFile("models/spacecode/sfchip_medium.mdl")
	resource.AddFile("models/spacecode/sfchip_small.mdl")
	
	---- Disabled (Useless) ----------------
	-- util.AddNetworkString("SF_hudscreen")
else
	list.Set("Starfall_gate_Models", "models/spacecode/sfchip.mdl", true)
	list.Set("Starfall_gate_Models", "models/spacecode/sfchip_medium.mdl", true)
	list.Set("Starfall_gate_Models", "models/spacecode/sfchip_small.mdl", true)
	
	--[[---- Disabled (Useless) ----------------------
	do ---- Screen to HUD rendering ---------------------
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
			if disable_hud[name] and ValidScr(HudSF.ScrA) then
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
	end -------------------------------------------------
	------------------------------------------------]]
	
	do ---- Automatic update check ----------------------
		local function DisplayUpdateMsg(vCur, vLast)
			scr.CreateFont("SFUpdateMsg", "Verdana", 16, 700)
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
				local msg = adv.StrFormat{updateMsg, cur = vCur, last = vLast}
				draw.DrawText(msg, "SFUpdateMsg", w/2, 30, color_white, 1)
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
			if not dat then return nil end
			dat = dat:match("^SF.Version=(%d+)$")
			return tonumber(dat)
		end
		
		local function CheckForUpdates(_, key)
			if key ~= "+menu" then return end
			if updateCheckDone then return end
			if not SF_Version then return end
			http.Fetch(updateUrl, function(dat)
				local last_ver = GetVersion(dat)
				if last_ver and SF_Version < last_ver then
					DisplayUpdateMsg(SF_Version, last_ver)
				end
			end)
			updateCheckDone = true
		end
		
		SF_Version = GetVersion(file.Read("lua/starfall/version.lua", "GAME"))
		hook.Add("PlayerBindPress", "SF_UpdateCheck", CheckForUpdates)
	end -------------------------------------------------
	
	do ---- Context menu HUD switcher -------------------
		local function AddSwitch(name, text, icon, stat)
			properties.Add(name, {
				Order = 350;
				MenuLabel = text;
				MenuIcon = icon;
				Filter = function(_, ent, ply)
					return IsValid(ent) and ent:GetClass() == "starfall_screen"
					and ent.IsHudMode and ent.HudActive ~= stat
				end;
				Action = function(_, ent)
					ent.HudActive = stat
				end;
			})
		end
		
		AddSwitch("sfhud_enable", "Enable HUD", "icon16/connect.png", true)
		AddSwitch("sfhud_disable", "Disable HUD", "icon16/disconnect.png", false)
	end -------------------------------------------------
	
	do ---- Context menu Remote switcher ----------------
		local function AddSwitch(name, text, icon, stat)
			properties.Add(name, {
				Order = 350;
				MenuLabel = text;
				MenuIcon = icon;
				Filter = function(_, ent, ply)
					return IsValid(ent) and ent:GetClass() == "starfall_remote"
					and (ply.SFRemote_Link == ent) ~= stat
				end;
				Action = function(_, ent)
					local ply = LocalPlayer()
					local lk = ply.SFRemote_Link
					net.Start("starfall_remote_link")
						net.WriteEntity(ent)
						local ply2 = SF.WrapObject(ply)
						if lk == ent then
							ply.SFRemote_Link = nil
							ent:runScriptHook("link", ply2, false)
							net.WriteBool(false)
						else
							if IsValid(lk) then
								lk:runScriptHook("link", ply2, false)
							end
							ply.SFRemote_Link = ent
							ent:runScriptHook("link", ply2, true)
							net.WriteBool(true)
						end
					net.SendToServer()
				end;
			})
		end
		
		AddSwitch("sfrmt_enable", "Link Remote", "icon16/connect.png", true)
		AddSwitch("sfrmt_disable", "Unlink Remote", "icon16/disconnect.png", false)
	end -------------------------------------------------
	
	do ---- Link menu for Remotes -----------------------
		scr.CreateFont("SFMenuButton", "Default", 18, 700)
		
		local _meta = {}
		_meta.__index = _meta
		local function MakeMenuObject()
			local obj = setmetatable({}, _meta)
			return obj:__init()
		end
		
		function _meta:__init()
			local fMain = vgui.Create("DFrame")
			fMain:SetDeleteOnClose(false)
			fMain:SetTitle("Starfall Remote linking")
			fMain:ShowCloseButton(true)
			fMain:SetDraggable(true)
			fMain:SetSize(320, 480)
			fMain:Center()
			fMain:Close()
			
			local lsRmt = vgui.Create("DListView", fMain)
			local eid = lsRmt:AddColumn("Ent ID")
			lsRmt:AddColumn("Instance Name")
			eid:SetFixedWidth(50)
			lsRmt:SetMultiSelect(false)
			lsRmt:SetSize(308, 400)
			lsRmt:SetPos(6, 30)
			function lsRmt.DoDoubleClick(_, _, sel)
				self:RemoteLink(sel.Data.ud_ent)
				fMain:Close()
			end
			
			local btLnk = vgui.Create("DButton", fMain)
			btLnk:SetText("Link selected")
			btLnk:SetFont("SFMenuButton")
			btLnk:SetImage("icon16/accept.png")
			btLnk:SetSize(190, 40)
			btLnk:SetPos(6, 434)
			function btLnk.DoClick()
				local sel = lsRmt:GetSelected()
				if #sel < 1 then return end
				self:RemoteLink(sel[1].Data.ud_ent)
			end
			
			local btUnl = vgui.Create("DButton", fMain)
			btUnl:SetText("Unlink")
			btUnl:SetFont("SFMenuButton")
			btUnl:SetImage("icon16/delete.png")
			btUnl:SetSize(114, 40)
			btUnl:SetPos(200, 434)
			function btUnl.DoClick()
				self:RemoteUnlink()
				lsRmt:ClearSelection()
			end
			
			self.Window = fMain
			self.RemList = lsRmt
			return self
		end
		
		function _meta:RemoteLink(ent)
			local ply = LocalPlayer()
			local lnk = ply.SFRemote_Link
			if lnk == ent then return end
			local nply = SF.WrapObject(ply)
			if IsValid(lnk) then
				lnk:runScriptHook("link", nply, false)
			end
			ply.SFRemote_Link = ent
			ent:runScriptHook("link", nply, true)
			net.Start("starfall_remote_link")
				net.WriteEntity(ent)
				net.WriteBool(true)
			net.SendToServer()
		end
		
		function _meta:RemoteUnlink()
			local ply = LocalPlayer()
			local lnk = ply.SFRemote_Link
			ply.SFRemote_Link = nil
			if not IsValid(lnk) then return end
			local nply = SF.WrapObject(ply)
			lnk:runScriptHook("link", nply, false)
			net.Start("starfall_remote_link")
				net.WriteEntity(lnk)
				net.WriteBool(false)
			net.SendToServer()
		end
		
		local function owns_filter(ent)
			if not IsValid(ent) then
				return false
			end
			local ply = LocalPlayer()
			local ownr = ent.owner
			return ownr == ply
		end
		
		function _meta:UpdateList()
			self.RemList:Clear()
			local tbl = SF.AllRemotes
			local ply = LocalPlayer()
			for ent in pairs(tbl) do
				local inst = ent.instance
				if owns_filter(ent) and inst and not inst.error then
					local nametbl = inst.ppdata.scriptnames
					local name = nametbl and nametbl[inst.mainfile] or "(none)"
					local row = self.RemList:AddLine(ent:EntIndex(), name)
					if ply.SFRemote_Link == ent then
						self.RemList:SelectItem(row)
					end
					row.Data.ud_ent = ent
				end
			end
		end
		
		function _meta:ShowMenu()
			self.Window:Show()
			self.Window:Center()
			self.Window:MakePopup()
		end
		
		hook.Add("Initialize", "sf_linkmenu", function()
			SF.RemoteLinkMenu = MakeMenuObject()
			concommand.Add("sf_linkmenu", function()
				SF.RemoteLinkMenu:UpdateList()
				SF.RemoteLinkMenu:ShowMenu()
			end)
		end)
	end -------------------------------------------------
end

if not net.ReadBool then
	net.WriteBool = net.WriteBit
	function net.ReadBool()
		return net.ReadBit() > 0
	end
end
