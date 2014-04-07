
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

include("starfall/SFLib.lua")
assert(SF, "Starfall didn't load correctly!")

local context = SF.CreateContext(nil, nil, nil, nil, SF.Libraries.CreateLocalTbl{"render"})
local screens = {}

util.AddNetworkString("starfall_screen_download")
--util.AddNetworkString("starfall_screen_update")
util.AddNetworkString("starfall_screen_used")

local Requests = {}

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
				net.WriteString(data)
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

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType( 3 )
	
	self.Inputs = WireLib.CreateInputs(self, {})
	self.Outputs = WireLib.CreateOutputs(self, {})
	
	local r,g,b,a = self:GetColor()
end

function ENT:OnRestore()
end

function ENT:UpdateName(state)
	if state ~= "" then state = "\n"..state end
	
	if self.instance and self.instance.ppdata.scriptnames and self.instance.mainfile and self.instance.ppdata.scriptnames[self.instance.mainfile] then
		self:SetOverlayText("Starfall Processor\n"..tostring(self.instance.ppdata.scriptnames[self.instance.mainfile])..state)
	else
		self:SetOverlayText("Starfall Processor"..state)
	end
end

function ENT:Error(msg, override)
	if type( msg ) == "table" then
		if msg.message then
			local line = msg.line
			local file = msg.file

			msg = ( file and ( file .. ":" ) or "" ) .. ( line and ( line .. ": " ) or "" ) .. msg.message
		end
	end
	ErrorNoHalt( "Processor of " .. self.owner:Nick() .. " errored: " .. tostring( msg ) .. "\n" )
	WireLib.ClientError(msg, self.owner)
	
	if self.instance then
		self.instance:deinitialize()
		self.instance = nil
	end
	
	self:UpdateName("Inactive (Error)")
	local r,g,b,a = self:GetColor()
	self:SetColor(255, 0, 0, a)
end

function ENT:CodeSent(ply, files, mainfile)
	if not IsValid(self.owner) then
		self.owner = ply
	end
	if ply ~= self.owner then return end
	local update = (self.mainfile ~= nil)

	self.files = files
	self.co_files = {}
	self.mainfile = mainfile
	screens[self] = self
	for key,val in pairs(files) do
		self.co_files[key] = util.Base64Encode(util.Compress(val))
	end

	if update then
		sendScreenCode(nil, self)
	end

	local ppdata = {}
	SF.Preprocessor.ParseDirectives(mainfile, files[mainfile], {}, ppdata)
	
	if ppdata.sharedscreen then		
		local ok, instance = SF.Compiler.Compile(files,context,mainfile,ply)
		if not ok then self:Error(instance) return end
		
		instance.runOnError = function(inst,...) self:Error(...) end

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
		
		self:UpdateName("")
		local r,g,b,a = self:GetColor()
		self:SetColor(Color(255, 255, 255, a))
		self.sharedscreen = true
	end
end

local i = 0
function ENT:Think()
	self.BaseClass.Think(self)

	---[[
	i = i + 1

	if i % 22 == 0 then
		retryCodeRequests()
		i = 0
	end
	--]]

	self:NextThink(CurTime())
	
	if self.instance and not self.instance.error then
		self.instance:resetOps()
		self:runScriptHook("think")
	end
	
	return true
end

-- Sends a umsg to all clients about the use.
function ENT:Use( activator )
	if activator:IsPlayer() then
		net.Start( "starfall_screen_used" )
			net.WriteEntity( self )
			net.WriteEntity( activator )
		net.Broadcast()
	end
	if self.sharedscreen then
		self:runScriptHook( "use", SF.Entities.Wrap( activator ) )
	end
end

function ENT:OnRemove()
	if not self.instance then return end
	if self.sharedscreen then
		self:runScriptHook("last")
	end
	screens[self] = nil
	self.instance:deinitialize()
	self.instance = nil
end

function ENT:TriggerInput(key, value)
	self:runScriptHook("input", key, SF.Wire.InputConverters[self.Inputs[key].Type](value))
end

function ENT:ReadCell ( address )
	return tonumber( self:runScriptHookForResult( "readcell", address ) ) or 0
end

function ENT:WriteCell ( address, data )
	self:runScriptHook( "writecell", address, data )
end

--[[
function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}
	info.starfall = SF.SerializeCode(self.instance.files, self.instance.mainfile)
	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)
	self.owner = ply
	
	local code, main = SF.DeserializeCode(info.starfall)
	--local task = {files = code, mainfile = main}
	self:CodeSent(ply, files, main)
end
--]]

--[[
local instance

function ENT:PreEntityCopy()
	instance = self.instance
	self.instance = nil
end

function ENT:PostEntityCopy()
	self.instance = instance
end
--]]

duplicator.RegisterEntityClass("gmod_wire_starfall_processor", nil)
