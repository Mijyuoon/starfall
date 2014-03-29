include('shared.lua')

ENT.RenderGroup = RENDERGROUP_OPAQUE

include("starfall/SFLib.lua")
assert(SF, "Starfall didn't load correctly!")

local context = SF.CreateContext(nil, nil, nil, nil, SF.Libraries.CreateLocalTbl{"render"})

surface.CreateFont("Starfall_ErrorFont", {
	font = "Arial",
	size = 16,
	weight = 200,
})

local function make_path(ply, path)
	local path = util.CRC(path:gsub("starfall/", ""))
	return string.format("sf_cache/%s.txt", path)
end
	
local function check_cached(ply, path, crc)
	local path = make_path(ply, path)
	if not file.Exists(path, "DATA") then
		return false
	end
	
	local fdata = file.Read(path, "DATA")
	if util.CRC(fdata) ~= crc then
		return false
	end
	return true, fdata
end

net.Receive("starfall_screen_download", function()
	local action = net.ReadInt(8)
	if action == SF_UPLOAD_CRC then
		local screen = net.ReadEntity()
		screen.files = {}
		local file_list = {}
		while net.ReadBit() > 0 do
			local fname = net.ReadString()
			local fcrc = net.ReadString()
			local chk, fdata = check_cached(ply, fname, fcrc)
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
		local filedata = net.ReadString()
		local current_file = screen.files[filename]
		if not current_file then
			screen.files[filename] = {filedata}
		else
			current_file[#current_file + 1] = filedata
		end
	elseif action == SF_UPLOAD_END then
		local screen = net.ReadEntity()
		for key, val in pairs(screen.files) do
			if type(val) == "table" then
				screen.files[key] = table.concat(val)
				if key ~= "generic" then
					local cache_path = make_path(ply, key)
					file.Write(cache_path, screen.files[key])
					--print("Write cache for: "..key.." as "..cache_path)
				end
			end
		end
		screen.owner = net.ReadEntity()
		screen.mainfile = net.ReadString()
		screen:CodeSent(screen.files, screen.mainfile, screen.owner)
	end
end)

net.Receive("starfall_screen_used", function ()
	local screen = net.ReadEntity()
	local activator = net.ReadEntity()
	
	screen:runScriptHook( "use", SF.Entities.Wrap( activator ) )
	
	-- Error message copying
	if screen.error then
		SetClipboardText(string.format("%q", screen.error.orig))
	end
end)

function ENT:Initialize()
	self.GPU = GPULib.WireGPU(self)
	net.Start("starfall_screen_download")
	net.WriteInt(SF_UPLOAD_INIT, 8)
	net.WriteEntity(self)
	net.SendToServer()
end

function ENT:Think()
	self.BaseClass.Think(self)
	self:NextThink(CurTime())
	
	if self.instance and not self.instance.error then
		self.instance:resetOps()
		self:runScriptHook("think")
	end
end

function ENT:OnRemove()
	self.GPU:Finalize()
	if self.instance then
		self:runScriptHook("last")
		self.instance:deinitialize()
	end
end

function ENT:Error(msg)
	if type( msg ) == "table" then
		if msg.message then
			local line = msg.line
			local file = msg.file

			msg = ( file and ( file .. ":" ) or "" ) .. ( line and ( line .. ": " ) or "" ) .. msg.message
		end
	end
	WireLib.AddNotify( self.owner, tostring( msg ), NOTIFY_ERROR, 7, NOTIFYSOUND_ERROR1 )

	
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
	
	self:SetOverlayText("Starfall Screen\nInactive (Error)")
end

function ENT:CodeSent(files, main, owner)
	if not files or not main or not owner then return end
	if self.instance then
		self:runScriptHook("last")
		self.instance:deinitialize()
	end
	--self.owner = owner
	local datatable = { ent = self, render = {} }
	local ok, instance = SF.Compiler.Compile(files,context,main,owner,datatable)
	if not ok then self:Error(instance) return end
	
	instance.runOnError = function(inst,...) self:Error(...) end
	
	self.instance = instance
	instance.data.entity = self
	instance.data.render.gpu = self.GPU
	instance.data.render.matricies = 0
	local ok, msg = instance:initialize()
	if not ok then self:Error(msg) end
	
	if not self.instance then return end
	
	local data = instance.data
	
	function self.renderfunc()
		if self.instance then
			data.render.isRendering = true
			self:runScriptHook("render")
			data.render.isRendering = nil
			
		elseif self.error then
			surface.SetTexture(0)
			surface.SetDrawColor(0, 0, 0, 120)
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

function ENT:Draw()
	self:DrawModel()
	Wire_Render(self)
	
	if self.renderfunc then
		self.GPU:RenderToGPU(self.renderfunc)
	end
	
	self.GPU:Render()
end
