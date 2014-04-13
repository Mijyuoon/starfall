TOOL.Category		= "Wire - Display"
TOOL.Name			= "Starfall - Screen"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

-- ------------------------------- Sending / Recieving ------------------------------- --
include("starfall/sflib.lua")

TOOL.ClientConVar[ "Model" ] = "models/hunter/plates/plate2x2.mdl"
cleanup.Register( "starfall_screen" )

if SERVER then
	CreateConVar('sbox_maxstarfall_screen', 10, {FCVAR_REPLICATED,FCVAR_NOTIFY,FCVAR_ARCHIVE})
	
	function MakeSF( pl, Pos, Ang, model)
		if not pl:CheckLimit( "starfall_screen" ) then return false end

		local sf = ents.Create( "starfall_screen" )
		if not IsValid(sf) then return false end

		sf:SetAngles( Ang )
		sf:SetPos( Pos )
		sf:SetModel( model )
		sf:Spawn()

		sf.owner = pl

		pl:AddCount( "starfall_screen", sf )

		return sf
	end
else
	language.Add( "Tool.wire_starfall_screen.name", "Starfall - Screen (Wire)" )
	language.Add( "Tool.wire_starfall_screen.desc", "Spawns a starfall screen" )
	language.Add( "Tool.wire_starfall_screen.0", "Primary: Spawns a screen / uploads code, Secondary: Opens editor" )
	language.Add( "SBox_max_starfall_Screen", "You've hit the Starfall Screen limit!" )
	language.Add( "undone_Wire Starfall Screen", "Undone Starfall Screen" )
end

function TOOL:LeftClick( trace )
	if not trace.HitPos then return false end
	if trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end

	local ply = self:GetOwner()

	if trace.Entity:IsValid() and trace.Entity:GetClass() == "starfall_screen" then
		local ent = trace.Entity
		if not SF.RequestCode(ply, function(mainfile, files)
			if not mainfile then return end
			if not IsValid(ent) then return end
			ent:CodeSent(ply, files, mainfile)
		end) then
			WireLib.AddNotify(ply,"Cannot upload SF code, please wait for the current upload to finish.",NOTIFY_ERROR,7,NOTIFYSOUND_ERROR1)
		end
		return true
	end
	
	self:SetStage(0)

	local model = self:GetClientInfo( "Model" )
	if not self:GetSWEP():CheckLimit( "starfall_screen" ) then return false end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local sf = MakeSF( ply, trace.HitPos, Ang, model)

	local min = sf:OBBMins()
	sf:SetPos( trace.HitPos - trace.HitNormal * min.z )

	local const = WireLib.Weld(sf, trace.Entity, trace.PhysicsBone, true)

	undo.Create("Wire Starfall Screen")
		undo.AddEntity( sf )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "starfall_screen", sf )
	
	if not SF.RequestCode(ply, function(mainfile, files)
		if not mainfile then return end
		if not IsValid(sf) then return end
		sf:CodeSent(ply, files, mainfile)
	end) then
		WireLib.AddNotify(ply,"Cannot upload SF code, please wait for the current upload to finish.",NOTIFY_ERROR,7,NOTIFYSOUND_ERROR1)
	end

	return true
end

function TOOL:RightClick( trace )
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
	local lastclick = CurTime()
	
	local function GotoDocs(button)
		gui.OpenURL("http://sf.inp.io") -- old one: http://colonelthirtytwo.net/sfdoc/
	end
	
	function TOOL.BuildCPanel(panel)
		panel:AddControl("Header", { Text = "#Tool.wire_starfall_screen.name", Description = "#Tool.wire_starfall_screen.desc" })
		
		local modelpanel = WireDermaExts.ModelSelect(panel, "wire_starfall_screen_Model", list.Get("WireScreenModels"), 2)
		panel:AddControl("Label", {Text = ""})
		
		local docbutton = vgui.Create("DButton" , panel)
		panel:AddPanel(docbutton)
		docbutton:SetText("Starfall Documentation")
		docbutton.DoClick = GotoDocs
		
		local filebrowser = vgui.Create("wire_expression2_browser")
		panel:AddPanel(filebrowser)
		filebrowser:Setup("starfall")
		filebrowser:SetSize(235,400)
		function filebrowser:OnFileOpen(filepath, newtab)
			SF.Editor.editor:Open(filepath, nil, newtab)
		end
		
		local openeditor = vgui.Create("DButton", panel)
		panel:AddPanel(openeditor)
		openeditor:SetText("Open Editor")
		openeditor.DoClick = SF.Editor.open
	end
end
