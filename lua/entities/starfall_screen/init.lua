
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

include("starfall/SFLib.lua")
assert(SF, "Starfall didn't load correctly!")

local libs = SF.Libraries.CreateLocalTbl{"render"}
local Context = SF.CreateContext(nil, nil, nil, libs)
local Requests, screens = {}, {}

function ENT:UpdateState(state)
	if self.name then
		self:SetOverlayText("Starfall HUD\n"..self.name)
	else
		self:SetOverlayText("Starfall HUD")
	end
end

util.AddNetworkString("starfall_screen_download")
util.AddNetworkString("starfall_screen_used")
util.AddNetworkString("starfall_hud_connect")

local function sendScreenCode(ply, screen)
	net.Start("starfall_screen_download")
	net.WriteInt(SF_UPLOAD_CRC, 8)
	net.WriteEntity(screen)
	net.WriteEntity(screen.owner)
	net.WriteString(screen.mainfile)
	for key, val in pairs(screen.files) do
		net.WriteBit(true)
		net.WriteString(key)
		net.WriteString(util.CRC(val))
	end
	net.WriteBit(false)
	if not ply then
		net.Broadcast()
	else
		net.Send(ply)
	end
end

local function initCodeRequest(screen, ply)
	if not IsValid(screen) then
		Requests[screen] = nil
		return
	end
	if screen.mainfile then
		if Requests[screen] then
			Requests[screen][ply] = nil
		end
		sendScreenCode(ply, screen)
	else
		if not Requests[screen] then
			Requests[screen] = {}
		end
		Requests[screen][ply] = true
	end
end

local function retryCodeRequests()
	for screen, plys in pairs(Requests) do
		for ply, _ in pairs(plys) do
			initCodeRequest(screen, ply)
		end
	end
end

net.Receive("starfall_screen_download", function(len, ply)
	local action = net.ReadInt(8)
	if action == SF_UPLOAD_INIT then
		local screen = net.ReadEntity()
		initCodeRequest(screen, ply)
	elseif action == SF_UPLOAD_DATA then
		local screen = net.ReadEntity()
		local file_list = {}
		while net.ReadBit() > 0 do
			local fname = net.ReadString()
			file_list[#file_list + 1] = fname
			--print("Server requested for: "..fname)
		end
		for _, fname in ipairs(file_list) do
			local fdata, offset = screen.co_files[fname], 1
			repeat
				net.Start("starfall_screen_download")
				net.WriteInt(SF_UPLOAD_DATA, 8)
				net.WriteEntity(screen)
				net.WriteString(fname)
				local data = fdata:sub(offset, offset+64000)
				net.WriteUInt(#data, 16)
				net.WriteData(data, #data)
				net.Send(ply)
				offset = offset + #data + 1
			until offset > #fdata
		end
		net.Start("starfall_screen_download")
		net.WriteInt(SF_UPLOAD_END, 8)
		net.WriteEntity(screen)
		net.Send(ply)
	end
end)

local Vehicle_Links = {}

function ENT:LinkHudToVehicle(vehicle)
	if not self.IsHudMode then return end
	self.LinkedVehicles[vehicle] = true
	Vehicle_Links[self] = self.LinkedVehicles
end

local function getnil() return nil end
function ENT:UnlinkHudFromVehicle(vehicle)
	if not vehicle then
		Vehicle_Links[self] = nil
		adv.TblMap(self.LinkedVehicles, getnil)
		self:SendConnectHud(false, false)
	else
		local self_links = Vehicle_Links[self]
		if not self_links then return end
		if self_links[vehicle] then
			self_links[vehicle] = nil
			self:SendConnectHud(false, false)
		end
	end
end

function ENT:SendConnectHud(ply, flag)
	net.Start("starfall_hud_connect")
	net.WriteEntity(self)
	net.WriteBool(flag)
	if ply then
		net.Send(ply)
	else
		net.Broadcast() 
	end
end

hook.Add("PlayerEnteredVehicle", "SF_HUD_Enter", function(ply, veh)
	for ent, lnk in pairs(Vehicle_Links) do
		if not lnk[veh] then continue end
		if not IsValid(ent) then continue end
		ent:SendConnectHud(ply, true)
	end
end)
hook.Add("PlayerLeaveVehicle", "SF_HUD_Enter", function(ply, veh)
	for ent, lnk in pairs(Vehicle_Links) do
		if not lnk[veh] then continue end
		if not IsValid(ent) then continue end
		ent:SendConnectHud(ply, false)
	end
end)

function ENT:SetContextBase()
	self.SFContext = Context
	if self.IsHudMode then
		self:UpdateState()
	end
end

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(3)
	
	if self:hudModelCheck() then
		self.IsHudMode = true
		local tbl = adv.TblWeakK()
		self.LinkedVehicles = tbl
	end
	
	self:SetContextBase()
	self.Inputs = WireLib.CreateInputs(self, {})
	self.Outputs = WireLib.CreateOutputs(self, {})
end

function ENT:OnRestore()
end

function ENT:Error(msg, override)
	if type(msg) == "table" then
		if msg.message then
			local line, file = msg.line, msg.file
			msg = (file and (file .. ":") or "") .. (line and (line .. ": ") or "") .. msg.message
		end
	end
	ErrorNoHalt(Format("Processor of %s errored: %s\n", self.owner:Nick(), msg))
	WireLib.ClientError(msg, self.owner)
	
	if self.instance then
		self.instance:deinitialize()
		self.instance = nil
	end
	
	local r,g,b,a = self:GetColor()
	self:SetColor(255, 0, 0, a)
end

function ENT:CodeSent(ply, files, mainfile)
	if IsValid(ply) and ply ~= self.owner then return end
	local update = (self.mainfile ~= nil)

	self.files = files
	self.co_files = {}
	self.mainfile = mainfile
	screens[self] = self
	for key,val in pairs(files) do
		self.co_files[key] = util.Compress(val)
	end

	if update then sendScreenCode(nil, self) end

	local ppdata = {}
	SF.Preprocessor.ParseDirectives(mainfile, files[mainfile], {}, ppdata)
	
	if ppdata.scriptnames and mainfile and ppdata.scriptnames[mainfile] then
		self.name = tostring(ppdata.scriptnames[mainfile])
	end
	if not self.name or #self.name < 1 then
		self.name = "generic"
	end
	
	self:UpdateState()
	
	if ppdata.sharedscreen then		
		local ok, instance = SF.Compiler.Compile(files, self.SFContext, mainfile, ply)
		if not ok then self:Error(instance) return end
		
		instance.runOnError = function(inst, ...) self:Error(...) end

		if self.instance then
			self:runScriptHook("last")
			self.instance:deinitialize()
			self.instance = nil
		end

		self.instance = instance
		instance.data.entity = self
		
		local ok, msg = instance:initialize()
		if not ok then
			self:Error(msg)
			return
		end
		
		if not self.instance then return end
		
		local r,g,b,a = self:GetColor()
		self:SetColor(Color(255, 255, 255, a))
		self.sharedscreen = true
	end
end

timer.Create("Starfall_RetryCodeReq", 0.66, 0, retryCodeRequests)

function ENT:Think()
	self.BaseClass.Think(self)
	self:NextThink(CurTime())
	
	if self.instance and not self.instance.error then
		self:runScriptHook("think")
		self:resetCpuTime()
	end
	
	return true
end

-- Sends a umsg to all clients about the use.
function ENT:Use(activator)
	if activator:IsPlayer() then
		net.Start("starfall_screen_used")
			net.WriteEntity(self)
			net.WriteEntity(activator)
		net.Broadcast()
	end
	if self.sharedscreen then
		self:runScriptHook("use", SF.Entities.Wrap(activator))
	end
end

function ENT:OnRemove()
	if self.IsHudMode then
		self:UnlinkHudFromVehicle()
	end
	if not self.instance then return end
	if not self.instance.error and self.sharedscreen then
		self:runScriptHook("last")
	end
	screens[self] = nil
	self.instance:deinitialize()
	self.instance = nil
end

function ENT:TriggerInput(key, value)
	self:runScriptHook("input", key, SF.Wire.InputConverters[self.Inputs[key].Type](value))
end

function ENT:ReadCell(address)
	return tonumber(self:runScriptHookForResult("readcell",address)) or 0
end

function ENT:WriteCell(address, data)
	self:runScriptHook("writecell",address,data)
end

function ENT:BuildDupeInfo()
	local info = WireLib.BuildDupeInfo(self) or {}
	if self.IsHudMode then
		local vehicles = {}
		for vh in pairs(self.LinkedVehicles) do
			if not IsValid(vh) then continue end
			vehicles[#vehicles+1] = vh:EntIndex()
		end
		info.hud_vehicles = vehicles
	end
	if self.mainfile then
		info.starfall = SF.SerializeCode(self.files, self.mainfile)
	end
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.owner = ply
	if info.hud_vehicles then
		for _, vh in ipairs(info.hud_vehicles) do
			local veh = GetEntByID(vh)
			if not IsValid(veh) then continue end
			self:LinkHudToVehicle(veh)
		end
	end
	if info.starfall then
		local code, main = SF.DeserializeCode(info.starfall)
		self:CodeSent(ply, code, main)
	end
	WireLib.ApplyDupeInfo(ply, ent, info, GetEntByID)
end

local tmp_instance = {}
function ENT:PreEntityCopy()
	local info = self:BuildDupeInfo()
	tmp_instance[self] = self.instance
	self.instance = nil
	if not info then return end
	duplicator.StoreEntityModifier(self, "SFDupeInfo", info)
end

function ENT:PostEntityCopy()
	self.instance = tmp_instance[self]
end

local function EntLookup(created)
	return function(id, def)
		local ent = created[id]
		return (IsValid(ent) and ent or def)
	end
end

function ENT:PostEntityPaste(ply, ent, created)
	if ent.EntityMods and ent.EntityMods.SFDupeInfo then
		ent:ApplyDupeInfo(ply, ent, ent.EntityMods.SFDupeInfo, EntLookup(created))
	end
end