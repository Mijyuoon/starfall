TOOL.Category		= "Visuals/Screens"
TOOL.Name			= "SF Screen"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

-- ------------------------------- Sending / Recieving ------------------------------- --
include("starfall/sflib.lua")

local MakeSF, MdList

TOOL.ClientConVar[ "Model" ] = "models/hunter/plates/plate2x2.mdl"
TOOL.ClientConVar[ "Type" ] = "scr"
cleanup.Register("starfall_screen")

if SERVER then
	CreateConVar('sbox_maxstarfall_screen', 10, {FCVAR_REPLICATED,FCVAR_NOTIFY,FCVAR_ARCHIVE})
	
	function MakeSF(pl, Pos, Ang, model)
		if not pl:CheckLimit("starfall_screen") then return false end
		local sf = ents.Create("starfall_screen")
		if not IsValid(sf) then return false end
		sf:SetAngles(Ang)
		sf:SetPos(Pos)
		sf:SetModel(model)
		sf:Spawn()
		sf.owner = pl
		pl:AddCount("starfall_screen", sf)
		return sf
	end
	
	MdList = {
		hud = "models/bull/dynamicbutton.mdl",
		scr = false,
	}
else
	language.Add("Tool.wire_starfall_screen.name", "Starfall - Screen (Wire)")
	language.Add("Tool.wire_starfall_screen.desc", "Spawns a starfall screen")
	language.Add("Tool.wire_starfall_screen.0", "Primary: Create/Update screen/HUD, Secondary: Open editor (Shift: Link to vehicle), Reload: Unlink from all")
	language.Add("Tool.wire_starfall_screen.1", "Secondary: link to selected vehicle, Reload: Unlink from selected vehicle")
	language.Add("sboxlimit_wire_starfall_screen", "You've hit the Starfall Screen limit!")
	language.Add("undone_Wire Starfall Screen", "Undone Starfall Screen")
end

function TOOL:LeftClick(trace)
	if not trace.HitPos then return false end
	if self:GetStage() ~= 0 then return false end
	if CLIENT then return true end

	local ply, tr_ent = self:GetOwner(), trace.Entity
	if tr_ent:IsPlayer() then return false end

	if IsValid(tr_ent) and tr_ent:GetClass() == "starfall_screen" then
		if not SF.RequestCode(ply, function(mainfile, files)
			if not mainfile then return end
			if not IsValid(tr_ent) then return end
			if not IsValid(tr_ent.owner) then
				tr_ent.owner = ply
			end
			tr_ent:CodeSent(ply, files, mainfile)
		end) then
			WireLib.AddNotify(ply,"Cannot upload SF code, please wait for the current upload to finish.",NOTIFY_ERROR,7,NOTIFYSOUND_ERROR1)
		end
		return true
	end
	
	local mtype = self:GetClientInfo("Type")
	local model = self:GetClientInfo("Model")
	if not self:GetSWEP():CheckLimit("starfall_screen") then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	model = MdList[mtype] or model
	local sf = MakeSF(ply, trace.HitPos, Ang, model)
	if not IsValid(sf) then return false end

	local min = sf:OBBMins()
	sf:SetPos(trace.HitPos - trace.HitNormal * min.z)

	local const = WireLib.Weld(sf, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Starfall Screen")
		undo.AddEntity(sf)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup("starfall_screen", sf)
	
	if not SF.RequestCode(ply, function(mainfile, files)
		if not mainfile then return end
		if not IsValid(sf) then return end
		sf:CodeSent(ply, files, mainfile)
	end) then
		WireLib.AddNotify(ply,"Cannot upload SF code, please wait for the current upload to finish.",NOTIFY_ERROR,7,NOTIFYSOUND_ERROR1)
	end

	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	local owner = self:GetOwner()
	local stage = self:GetStage()
	local tr_ent = trace.Entity
	
	if stage == 0 then
		if not owner:KeyDown(IN_SPEED) then
			owner:SendLua("SF.Editor.open()")
			return false
		elseif IsValid(tr_ent) and tr_ent.IsHudMode
		and tr_ent:GetClass() == "starfall_screen" then
			self._LnEnt = tr_ent
			self:SetStage(1)
		end
	elseif stage == 1 then
		if IsValid(tr_ent) and tr_ent:IsVehicle() then
			if IsValid(self._LnEnt) then
				self._LnEnt:LinkHudToVehicle(tr_ent)
			end
		else
			WireLib.AddNotify(owner, "Not a vehicle!", NOTIFY_ERROR, 3, NOTIFYSOUND_ERROR1)
		end
		self:SetStage(0)
	end
	return true
end

function TOOL:Reload(trace)
	if CLIENT then return true end
	local stage = self:GetStage()
	local tr_ent = trace.Entity
	
	if stage == 0 then
		if IsValid(tr_ent) and tr_ent.IsHudMode
		and tr_ent:GetClass() == "starfall_screen" then
			tr_ent:UnlinkHudFromVehicle(false)
		end
	elseif stage == 1 then
		if IsValid(tr_ent) and tr_ent:IsVehicle() then
			if IsValid(self._LnEnt) then
				self._LnEnt:UnlinkHudFromVehicle(tr_ent)
			end
		else
			WireLib.AddNotify(owner, "Not a vehicle!", NOTIFY_ERROR, 3, NOTIFYSOUND_ERROR1)
		end
		self:SetStage(0)
	end
	return true
end

function TOOL:DrawHUD()
end

function TOOL:Think()
end

if CLIENT then
	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool.wire_starfall_screen.name", Description = "#Tool.wire_starfall_screen.desc" })
		
		local modelpanel = WireDermaExts.ModelSelect(panel, "wire_starfall_screen_Model", list.Get("WireScreenModels"), 2)
		panel:AddControl("Label", {Text = ""})
		
		local cbox = {
			Label = "Screen Type",
			MenuButton = 0,
			Options = {
				Screen = { wire_starfall_screen_Type = "scr" },
				HUD = { wire_starfall_screen_Type = "hud" },
			},
		}
		panel:AddControl("ComboBox", cbox)
		
		--[[----
		local docbutton = vgui.Create("DButton" , panel)
		panel:AddPanel(docbutton)
		docbutton:SetText("Starfall Documentation")
		docbutton.DoClick = function()
			gui.OpenURL("http://sf.inp.io")
		end
		------]]
		
		local filebrowser = vgui.Create("wire_expression2_browser")
		panel:AddPanel(filebrowser)
		filebrowser:Setup("starfall")
		filebrowser:SetSize(235,400)
		function filebrowser:OnFileOpen(filepath, newtab)
			SF.Editor.open(filepath, nil, newtab)
		end
		
		local openeditor = vgui.Create("DButton", panel)
		panel:AddPanel(openeditor)
		openeditor:SetText("Open Editor")
		openeditor.DoClick = function()
			SF.Editor.open()
		end
	end
end
