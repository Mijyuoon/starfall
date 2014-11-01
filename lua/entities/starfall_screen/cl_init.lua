include('shared.lua')

ENT.RenderGroup = RENDERGROUP_OPAQUE

include("starfall/SFLib.lua")
assert(SF, "Starfall didn't load correctly!")

local libs = SF.Libraries.CreateLocalTbl{"render"}
local Context = SF.CreateContext(nil, nil, nil, libs)

surface.CreateFont("Starfall_ErrorFont", {
	font = "Arial",
	size = 20,
	weight = 200,
})

local function make_path(ply, path)
	if not IsValid(ply) then return false end
	local path = util.CRC(path:gsub("starfall/", ""))
	local plyid = ply:SteamID():gsub(":","_")
	file.CreateDir("sf_cache/" .. plyid)
	return string.format("sf_cache/%s/%s.txt", plyid, path)
end

local function check_cached(ply, path, crc)
	if not IsValid(ply) then return false end
	local path = make_path(ply, path)
	if not path or not file.Exists(path, "DATA") then
		return false
	end
	
	local fdata = util.Decompress(file.Read(path, "DATA"))
	if not fdata or util.CRC(fdata) ~= crc then
		return false
	end
	return true, fdata
end

net.Receive("starfall_screen_download", function()
	local action = net.ReadInt(8)
	if action == SF_UPLOAD_CRC then
		local screen = net.ReadEntity()
		screen.owner = net.ReadEntity()
		screen.mainfile = net.ReadString()
		local file_list = {}
		while net.ReadBit() > 0 do
			local fname = net.ReadString()
			local fcrc = net.ReadString()
			local chk, fdata = check_cached(screen.owner, fname, fcrc)
			if not chk then
				file_list[#file_list + 1] = fname
				--print("Cache miss/expired for: "..fname)
			else
				screen.files[fname] = fdata
				--print("Got cache entry for: "..fname)
			end
		end	
		net.Start("starfall_screen_download")
		net.WriteInt(SF_UPLOAD_DATA, 8)
		net.WriteEntity(screen)
		for _, fname in ipairs(file_list) do
			net.WriteBit(true)
			net.WriteString(fname)
			--print("Request file: "..fname)
		end
		net.WriteBit(false)
		net.SendToServer()
	elseif action == SF_UPLOAD_DATA then
		local screen = net.ReadEntity()
		local filename = net.ReadString()
		local filesz = net.ReadUInt(16)
		local filedata = net.ReadData(filesz)
		local current_file = screen.files[filename]
		if type(current_file) ~= "table" then
			screen.files[filename] = {filedata}
		else
			current_file[#current_file + 1] = filedata
		end
	elseif action == SF_UPLOAD_END then
		local screen = net.ReadEntity()
		for key, val in pairs(screen.files) do
			if type(val) == "table" then
				local file_data = table.concat(val)
				screen.files[key] = util.Decompress(file_data)
				if key ~= "generic" then
					local cache_path = make_path(screen.owner, key)
					if cache_path then
						file.Write(cache_path, file_data)
					end
					--print("Write cache for: "..key.." as "..cache_path)
				end
			end
		end
		screen:CodeSent(screen.files, screen.mainfile, screen.owner)
	end
end)

net.Receive("starfall_screen_used", function()
	local screen = net.ReadEntity()
	local activator = net.ReadEntity()
	
	screen:runScriptHook("use", SF.Entities.Wrap(activator))
	
	-- Error message copying
	if screen.error then
		SetClipboardText(string.format("%q", screen.error.orig))
	end
end)

net.Receive("starfall_hud_connect", function()
	local ent = net.ReadEntity()
	local flag = net.ReadBool()
	if not IsValid(ent) then return end
	ent.VehActive = flag
end)

function ENT:SetContextBase()
	self.SFContext = Context
end

function ENT:Initialize()
	if self:hudModelCheck() then
		self.IsHudMode, self.HudActive = true, false
		hook.Add("HUDPaint", self, self.DrawToHUD)
	else
		self.GPU = GPULib.WireGPU(self)
	end
	self.files = {}
	self:SetContextBase()
	net.Start("starfall_screen_download")
	net.WriteInt(SF_UPLOAD_INIT, 8)
	net.WriteEntity(self)
	net.SendToServer()
end

function ENT:Think()
	self.BaseClass.Think(self)
	self:NextThink(CurTime())
	self.WasFrameDrawn = false
	
	if self.instance and not self.instance.error then
		self:runScriptHook("think")
		self:resetCpuTime()
	end
end

function ENT:OnRemove()
	if not self.GPU then return end
	local vtab = self:GetTable()
	timer.Simple(0.1, function()
		if IsValid(self) then return end
		vtab.GPU:Finalize()
		if vtab.instance and not vtab.instance.error then
			vtab:runScriptHook("last")
			vtab.instance:deinitialize()
		end
	end)
end

function ENT:Error(msg)
	if type(msg) == "table" then
		if msg.message then
			local line, file = msg.line, msg.file
			msg = (file and (file .. ":") or "") .. (line and (line .. ": ") or "") .. msg.message
		end
	end
	WireLib.AddNotify(self.owner, tostring(msg), NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1)
	
	-- Process error message
	self.error = {}
	self.error.orig = msg
	self.error.source, self.error.line, self.error.msg = string.match(msg, "%[@?SF:(%a+):(%d+)](.+)$")

	if not self.error.source or not self.error.line or not self.error.msg then
		self.error.source, self.error.line, self.error.msg = nil, nil, msg
	else
		self.error.msg = string.TrimLeft(self.error.msg)
	end
	
	if self.instance then
		self.instance:deinitialize()
		self.instance = nil
	end
end

function ENT:SetRenderFunc(data)
	function self.renderfunc()
		if self.instance then
			data.render.isRendering = true
			self:runScriptHook("render")
			data.render.isRendering = nil
		elseif self.error then
			surface.SetTexture(0)
			surface.SetDrawColor(0, 0, 0, 140)
			surface.DrawRect(0, 0, 512, 512)
			
			draw.DrawText("Error occurred in Starfall Screen:", "Starfall_ErrorFont", 32, 16, Color(0, 255, 255, 255)) -- Cyan
			draw.DrawText(tostring(self.error.msg), "Starfall_ErrorFont", 16, 80, Color(255, 0, 0, 255))
			if self.error.source and self.error.line then
				draw.DrawText("Line: "..tostring(self.error.line), "Starfall_ErrorFont", 16, 512-16*7, Color(255, 255, 255, 255))
				draw.DrawText("Source: "..self.error.source, "Starfall_ErrorFont", 16, 512-16*5, Color(255, 255, 255, 255))
			end
			draw.DrawText("Press USE to copy to your clipboard", "Starfall_ErrorFont", 512 - 16*25, 512-16*2, Color(255, 255, 255, 255))
			self.renderfunc = nil
		end
	end
end

function ENT:CodeSent(files, main, owner)
	if not files or not main or not owner then return end
	if self.instance and not self.instance.error then
		self:runScriptHook("last")
		self.instance:deinitialize()
	end
	--self.owner = owner
	local datatable = { ent = self, render = {} }
	local ok, instance = SF.Compiler.Compile(files,self.SFContext,main,owner,datatable)
	if not ok then self:Error(instance) return end
	
	instance.runOnError = function(inst, ...) self:Error(...) end
	
	self.error = nil
	self.instance = instance
	instance.data.entity = self
	instance.data.render.gpu = self.GPU
	instance.data.render.matricies = 0
	instance.data.render.viewport = {
		x = 0, y = 0, w = 512, h = 512
	}
	local ok, msg = instance:initialize()
	if not ok then self:Error(msg) end
	
	if not self.instance then return end
	
	self:SetRenderFunc(instance.data)
end

function ENT:DrawScreen()
	if not self.WasFrameDrawn and self.renderfunc then
		self.GPU:RenderToGPU(self.renderfunc)
		self.WasFrameDrawn = true
	end
end

function ENT:DrawToHUD()
	if (self.HudActive or self.VehActive) and self.renderfunc then
		local ok, err = xpcall(self.renderfunc, debug.traceback)
		if not ok then WireLib.ErrorNoHalt(err) end
	end
end

function ENT:Draw()
	if self.GPU then
		self:DrawModel()
		self:DrawScreen()
		self.GPU:Render()
	else
		self:DoNormalDraw()
	end
	Wire_Render(self)
end
