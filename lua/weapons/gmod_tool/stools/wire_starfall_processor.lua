TOOL.Category		= "Chips, Gates"
TOOL.Name			= "SF Processor"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

-- ------------------------------- Sending / Recieving ------------------------------- --
include("starfall/sflib.lua")

local MakeSF, MClass

TOOL.ClientConVar[ "Model" ] = "models/jaanus/wiretool/wiretool_siren.mdl"
TOOL.ClientConVar[ "Type" ] = "prc"
cleanup.Register("starfall_processor")
cleanup.Register("starfall_remote")

if SERVER then
	CreateConVar('sbox_maxstarfall_processor', 10, {FCVAR_REPLICATED,FCVAR_NOTIFY,FCVAR_ARCHIVE})
	
	function MakeSF(class, pl, Pos, Ang, model)
		if not pl:CheckLimit(class) then return false end
		local sf = ents.Create(class)
		if not IsValid(sf) then return false end
		sf:SetAngles(Ang)
		sf:SetPos(Pos)
		sf:SetModel(model)
		sf:Spawn()
		sf.owner = pl
		pl:AddCount(class, sf)
		return sf
	end
	
	MClass = {
		prc = {
			cn = "starfall_processor",
			lb = "Wire Starfall Processor",
		};
		rem = {
			cn = "starfall_remote",
			lb = "Wire Starfall Remote",
		};
	}
else
	language.Add("Tool.wire_starfall_processor.name", "Starfall - Processor (Wire)")
	language.Add("Tool.wire_starfall_processor.desc", "Spawns a starfall processor (Press Shift+F to switch to screen and back again)")
	language.Add("Tool.wire_starfall_processor.0", "Primary: Create/Update processor/remote, Secondary: Open editor")
	language.Add("sboxlimit_wire_starfall_processor", "You've hit the Starfall processor limit!")
	language.Add("sboxlimit_wire_starfall_remote", "You've hit the Starfall remote limit!")
	language.Add("undone_Wire Starfall Processor", "Undone Starfall Processor")
	language.Add("undone_Wire Starfall Remote", "Undone Starfall Remote")
end

function TOOL:LeftClick(trace)
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()
	local tr_ent = trace.Entity
	local selected = MClass[self:GetClientInfo("Type")]
	
	if IsValid(tr_ent) and tr_ent:GetClass() == selected.cn then
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
	
	self:SetStage(0)

	local model = self:GetClientInfo("Model")
	if not self:GetSWEP():CheckLimit(selected.cn) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
	
	local sf = MakeSF(selected.cn, ply, trace.HitPos, Ang, model)
	if not IsValid(sf) then return false end

	local min = sf:OBBMins()
	sf:SetPos(trace.HitPos - trace.HitNormal * min.z)

	local const = WireLib.Weld(sf, trace.Entity, trace.PhysicsBone, true)

	undo.Create(selected.lb)
		undo.AddEntity(sf)
		undo.AddEntity(const)
		undo.SetPlayer(ply)
	undo.Finish()

	ply:AddCleanup(selected.cn, sf)
	
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
	if SERVER then self:GetOwner():SendLua("SF.Editor.open()") end
	return false
end

function TOOL:Reload(trace)
	return false
end

function TOOL:DrawHUD()
end

function TOOL:Think()
end

if CLIENT then
	local function get_active_tool(ply, tool)
		-- find toolgun
		local activeWep = ply:GetActiveWeapon()
		if not IsValid(activeWep) or activeWep:GetClass() ~= "gmod_tool" or activeWep.Mode ~= tool then return end

		return activeWep:GetToolObject(tool)
	end
	
	hook.Add("PlayerBindPress", "wire_adv", function(ply, bind, pressed)
		if not pressed then return end
	
		if bind == "impulse 100" and ply:KeyDown(IN_SPEED) then
			local self = get_active_tool(ply, "wire_starfall_processor")
			if not self then
				self = get_active_tool(ply, "wire_starfall_screen")
				if not self then return end
				
				RunConsoleCommand("gmod_tool", "wire_starfall_processor") -- switch back to processor
				return true
			end
			
			RunConsoleCommand("gmod_tool", "wire_starfall_screen") -- switch to screen
			return true
		end
	end)
	
	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool.wire_starfall_processor.name", Description = "#Tool.wire_starfall_processor.desc" })
		
		local modelPanel = WireDermaExts.ModelSelect(panel, "wire_starfall_processor_Model", list.Get("Starfall_gate_Models"), 2)
		panel:AddControl("Label", {Text = ""})
		
		local cbox = {
			Label = "Processor type",
			MenuButton = 0,
			Options = {
				Processor = { wire_starfall_processor_Type = "prc" },
				Remote = { wire_starfall_processor_Type = "rem" },
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
