
AddCSLuaFile('cl_init.lua')
AddCSLuaFile('shared.lua')
include('shared.lua')

include("starfall/SFLib.lua")
assert(SF, "Starfall didn't load correctly!")

local context = SF.CreateContext()
local screens = {}

util.AddNetworkString("starfall_screen_download")
util.AddNetworkString("starfall_screen_update")
util.AddNetworkString("starfall_screen_used")

local function sendScreenCode(screen, owner, files, mainfile, recipient)
	--print("Sending SF code for: " .. tostring(recipient))
	net.Start("starfall_screen_download")
	net.WriteEntity(screen)
	net.WriteEntity(owner)
	net.WriteString(mainfile)
	if recipient then net.Send(recipient) else net.Broadcast() end
	--print("\tHeader sent")
	
	for fname, fdata in pairs(files) do
		local offset = 1
		local pp_data = { moonscript = false }
		SF.Preprocessor.ParseDirectives(fname, fdata, {}, pp_data)
		if pp_data.moonscript then
			fdata = moonscript.to_lua(fdata)
		end
		repeat
			net.Start("starfall_screen_download")
			net.WriteBit(false)
			net.WriteString(fname)
			local data = fdata:sub(offset, offset+60000)
			net.WriteString(data)
			net.WriteBit(pp_data.moonscript)
			--print( "moonscript " .. tostring(pp_data.moonscript) .. " for: " .. fname)
			if recipient then net.Send(recipient) else net.Broadcast() end
			offset = offset + #data + 1
		until offset > #fdata
	end

	net.Start("starfall_screen_download")
	net.WriteBit(true)
	if recipient then net.Send(recipient) else net.Broadcast() end
	--print("Done sending")
end

local requests = {}

local function sendCodeRequest(ply, screenid)
	local screen = Entity(screenid)
	if not IsValid(screen) then
		print("[SF] Bad screen ID: "..screenid)
	end

	if not screen.mainfile then
		if not requests[screenid] then requests[screenid] = {} end
		if requests[screenid][player] then return end
		requests[screenid][ply] = true
		return

		--[[if timer.Exists("starfall_send_code_request") then return end
		timer.Create("starfall_send_code_request", .5, 1, retryCodeRequests) ]]
	elseif screen.mainfile then
		if requests[screenid] then
			requests[screenid][ply] = nil
		end
		sendScreenCode(screen, screen.owner, screen.files, screen.mainfile, ply)
	end
end

local function retryCodeRequests()
	for screenid,plys in pairs(requests) do
		for ply,_ in pairs(requests[screenid]) do
			sendCodeRequest(ply, screenid)
		end
	end
end

net.Receive("starfall_screen_download", function(len, ply)
	local screen = net.ReadEntity()
	sendCodeRequest(ply, screen:EntIndex())
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
	ErrorNoHalt("Processor of "..self.owner:Nick().." errored: "..msg.."\n")
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
	if ply ~= self.owner then return end
	local update = self.mainfile ~= nil

	self.files = files
	self.mainfile = mainfile
	screens[self] = self

	if update then
		net.Start("starfall_screen_update")
			net.WriteEntity(self)
			for k,v in pairs(files) do
				net.WriteBit(false)
				net.WriteString(k)
				net.WriteString(util.CRC(v))
			end
			net.WriteBit(true)
		net.Broadcast()
		--sendScreenCode(self, ply, files, mainfile)
	end

	local ppdata = {}
	SF.Preprocessor.ParseDirectives(mainfile, files[mainfile], {}, ppdata)
	
	if ppdata.sharedscreen then		
		local ok, instance = SF.Compiler.Compile(files,context,mainfile,ply)
		if not ok then self:Error(instance) return end
		
		instance.runOnError = function(inst,...) self:Error(...) end

		if self.instance then
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

	i = i + 1

	if i % 22 == 0 then
		retryCodeRequests()
		i = 0
	end

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
	screens[self] = nil
	self.instance:deinitialize()
	self.instance = nil
end

function ENT:TriggerInput(key, value)
	self:runScriptHook("input", key, SF.Wire.InputConverters[self.Inputs[key].Type](value))
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

local instance

function ENT:PreEntityCopy()
	instance = self.instance
	self.instance = nil
end

function ENT:PostEntityCopy()
	self.instance = instance
end

duplicator.RegisterEntityClass("gmod_wire_starfall_processor", nil)
