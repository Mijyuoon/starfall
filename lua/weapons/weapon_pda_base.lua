--[[*******************************************************
	SWEP Construction Kit base code
		Created by Clavus
	Available for public use, thread at:
	   facepunch.com/threads/1032378
	   
	   
	DESCRIPTION:
		This script is meant for experienced scripters 
		that KNOW WHAT THEY ARE DOING. Don't come to me 
		with basic Lua questions.
		
		Just copy into your SWEP or SWEP base of choice
		and merge with your own code.
		
		The SWEP.VElements, SWEP.WElements and
		SWEP.ViewModelBoneMods tables are all optional
		and only have to be visible to the client.
*******************************************************--]]

AddCSLuaFile()

SWEP.Instructions = ""
SWEP.Author	= "Mijyuoon"
SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.IsPdaSystem = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo	= "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo	= "none"

SWEP.HoldType = "pistol"
SWEP.ViewModelFOV = 60
SWEP.ViewModelFlip = false
SWEP.ViewModel = "models/tablet/v_hands.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.ShowViewModel = true
SWEP.ShowWorldModel = false
SWEP.IronSightsEnabled = false
SWEP.KeyboardEnabled = false

if SERVER then
	SWEP.InputKeyMap = {
		pri = {
			norm = 1,
			use  = 4,
			walk = -2,
		},
		sec = {
			norm = 2,
			use  = 5,
			walk = -1,
		},
		rel = {
			norm = 3,
			use  = 6,
			walk = 0,
		},
	}
	SWEP.ActionKeyMap = {
		[-1] = function(self)
			if not self.IronSightsPos then return end
			self.IronSightsEnabled = not self.IronSightsEnabled
			self:SetDTBool(1, self.IronSightsEnabled)
		end;
		[-2] = function(self)
			self:EnableKeyboard(true)
		end;
	}
	
	util.AddNetworkString("pdasys_blockinput")
	function SWEP:EnableKeyboard(flag)
		if flag == self.KeyboardEnabled then return end
		self.KeyStateBuffer = {}
		self.IgnoreFirstKey = true
		self.KeyboardEnabled = flag
		net.Start("pdasys_blockinput")
			net.WriteEntity(self)
			net.WriteBit(flag)
			if flag ~= false then
				net.WriteUInt(self.Owner:GetInfoNum("wire_keyboard_leavekey", KEY_LALT), 8)
			end
		net.Send(self.Owner)
	end
	
	function SWEP:ProcKeyboard(keyid, flag)
		self.KeyStateBuffer[keyid] = flag and true or nil
		if self.HandleKeyInput then
			self:HandleKeyInput(self.Owner, keyid, flag)
		end
	end
	
	function SWEP:Think()
		if not self.KeyboardEnabled then
			self:NextThink(CurTime() + 0.3)
			return true
		elseif self.IgnoreFirstKey then
			if table.Count(self.Owner.keystate) == 0 then
				self.IgnoreFirstKey = false
			end
		else
			local keystate, keybuffer = self.Owner.keystate, self.KeyStateBuffer
			local leavekey = self.Owner:GetInfoNum("wire_keyboard_leavekey", KEY_LALT)
			
			for key, _ in pairs(keybuffer) do
				if not keystate[key] then self:ProcKeyboard(key, false) end
			end
			
			if not keystate[leavekey] then
				for key, _ in pairs(keystate) do
					if not keybuffer[key] then self:ProcKeyboard(key, true) end
				end
			else
				self:EnableKeyboard(false)
			end
		end
		self:NextThink(CurTime())
		return true
	end
	
	local vmap = { pri = IN_ATTACK, sec = IN_ATTACK2, rel = IN_RELOAD }
	function SWEP:ProcButtonInput(index)
		local keyvalue = nil
		local keymap = self.InputKeyMap
		if self.Owner:KeyDownLast(vmap[index]) then
			keyvalue = false
		elseif self.Owner:KeyDown(IN_WALK) then
			keyvalue = keymap[index].walk
		elseif self.Owner:KeyDown(IN_USE) then
			keyvalue = keymap[index].use
		else
			keyvalue = keymap[index].norm
		end
		if not keyvalue then return end
		if keyvalue < 0 and self.ActionKeyMap[keyvalue] then
			self.ActionKeyMap[keyvalue](self)
		elseif keyvalue > 0 and self.HandleButtonPress then
			self:HandleButtonPress(self.Owner, keyvalue)
		end
	end

	function SWEP:PrimaryAttack()
		self:ProcButtonInput("pri")
		return false
	end

	function SWEP:SecondaryAttack()
		self:ProcButtonInput("sec")
		return false
	end

	function SWEP:Reload()
		self:ProcButtonInput("rel")
		return false
	end
end

if CLIENT then
	RT_PdaSystem = GetRTManager("PdaSys", 1024, 1024)

	function SWEP:RenderScreenHelper(e_draw, e_clear)
		local vp = self.RenderViewPort
		if not (self.RT and vp) then return end
		local matScreen = Material(self.RenderTexture)
		matScreen:SetTexture("$basetexture", self.RT)
		render.PushRenderTarget(self.RT, vp.Left, vp.Top, vp.Width, vp.Height)
		cam.Start2D()
			if e_clear then
				render.Clear(0, 0, 0, 255)
			end
			if e_draw and self.RenderScreenFunc then
				self:RenderScreenFunc(vp.Width, vp.Height)
			end
		cam.End2D()
		render.PopRenderTarget()
	end
	
	function SWEP:ScreenShouldDraw()
		return true, true
	end

	local IRONSIGHT_TIME = 0.2
	function SWEP:GetViewModelPosition(pos, ang)
		local bIron = self:GetDTBool(1)
		
		if bIron ~= self.LastIron then
			self.LastIron = bIron 
			self.IronTime = CurTime()
			if bIron then 
				self.SwayScale 	= 0.3
				self.BobScale 	= 0.1
			else 
				self.SwayScale 	= 1.0
				self.BobScale 	= 1.0
			end
		
		end
		
		local IronTime, Mul = self.IronTime or 0, 1.0

		if not bIron and IronTime < CurTime() - IRONSIGHT_TIME then 
			return pos, ang
		end
		
		if IronTime > CurTime() - IRONSIGHT_TIME then
			Mul = math.Clamp((CurTime() - IronTime) / IRONSIGHT_TIME, 0, 1)
			if not bIron then Mul = 1 - Mul end
		end

		local Rt = ang:Right()
		local Up = ang:Up()
		local Fd = ang:Forward()
		
		if self.IronSightsAng then
			ang:RotateAroundAxis(Rt, self.IronSightsAng.x * Mul)
			ang:RotateAroundAxis(Up, self.IronSightsAng.y * Mul)
			ang:RotateAroundAxis(Fd, self.IronSightsAng.z * Mul)
			Rt, Up, Fd = ang:Right(), ang:Up(), ang:Forward()
		end
		
		pos = pos + self.IronSightsPos.x * Rt * Mul
		pos = pos + self.IronSightsPos.y * Fd * Mul
		pos = pos + self.IronSightsPos.z * Up * Mul
		
		return pos, ang
	end
	
	function SWEP:PrimaryAttack()
		return false
	end
	
	function SWEP:SecondaryAttack()
		return false
	end
	
	function SWEP:Reload()
		return false
	end
	
	hook.Add("HUDShouldDraw", "PDA.Crosshair", function(name)
		if name ~= "CHudCrosshair" then return end
		local cur_weapon = LocalPlayer():GetActiveWeapon()
		if cur_weapon and cur_weapon.IsPdaSystem then
			return false
		end
	end)
	
	hook.Add("PlayerBindPress", "PDA.BlockInput", function(ply, bind)
		assert(LocalPlayer() == ply, "What the fuck?!")
		local cur_weapon = LocalPlayer():GetActiveWeapon()
		if cur_weapon and cur_weapon.IsPdaSystem then
			return cur_weapon.KeyboardEnabled or nil
		end
	end)
	
	net.Receive("pdasys_blockinput", function()
		local target = net.ReadEntity()
		local flag = (net.ReadBit() > 0)
		target.KeyboardEnabled = flag
		if not flag then return end
		local vkey = input.GetKeyName(net.ReadUInt(8)):upper()
		chat.AddText("Keyboard enabled - press "..vkey.." to disable")
	end)
end

function SWEP:Initialize()
	if CLIENT then
		self.RT = RT_PdaSystem:GetRT()
		self.VElements = table.FullCopy(self.VElements)
		self.WElements = table.FullCopy(self.WElements)
		self.ViewModelBoneMods = table.FullCopy(self.ViewModelBoneMods)
		
		self:CreateModels(self.VElements) -- create viewmodels
		self:CreateModels(self.WElements) -- create worldmodels
		
		-- init view model bone build function
		if IsValid(self.Owner) then
			local vm = self.Owner:GetViewModel()
			if not IsValid(vm) then return end
			self:ResetBonePositions(vm)
			
			-- Init viewmodel visibility
			if self.ShowViewModel ~= false then
				vm:SetColor(color_white)
			else
				-- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
				vm:SetColor(color_transparent)
				-- ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
				-- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
				vm:SetMaterial("Debug/hsv")			
			end
		end
	end
end

local function SetActivePdaSystem(targ, opt)
	if CLIENT then return end
	targ.Owner.ActivePdaSystem = targ
	net.Start("pdasys_setactive")
		net.WriteEntity(targ.Owner)
		net.WriteEntity(opt and targ or NULL)
	net.Broadcast()
end

if CLIENT then
	net.Receive("pdasys_setactive", function()
		local ply = net.ReadEntity()
		local ent = net.ReadEntity()
		ply.ActivePdaSystem = IsValid(ent) and ent
	end)
else
	util.AddNetworkString("pdasys_setactive")
end

function SWEP:Deploy()
	if SERVER and IsValid(self.Owner) then
		--self.Owner.ActivePdaSystem = self
		SetActivePdaSystem(self, true)
	end
	return true
end

function SWEP:Holster()
	if CLIENT and IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
		end
	elseif SERVER and IsValid(self.Owner) then
		--self.Owner.ActivePdaSystem = nil
		SetActivePdaSystem(self, false)
		self:EnableKeyboard(false)
	end
	return true
end

function SWEP:OnRemove()
	if CLIENT then
		local RT = self.RT
		timer.Simple(0.1, function()
			if IsValid(self) then return end
			RT_PdaSystem:FreeRT(RT)
		end)
	end
	self:Holster()
end

if CLIENT then

	SWEP.vRenderOrder = nil
	function SWEP:ViewModelDrawn()
		local e_draw, e_clear = self:ScreenShouldDraw()
		self:RenderScreenHelper(e_draw, e_clear)
		
		local vm = self.Owner:GetViewModel()
		if not IsValid(vm) then return end
		if not self.VElements then return end
		
		self:UpdateBonePositions(vm)

		if not self.vRenderOrder then
			-- we build a render order because sprites need to be drawn after models
			self.vRenderOrder = {}
			for k, v in pairs(self.VElements) do
				if v.type == "Model" then
					table.insert(self.vRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.vRenderOrder, k)
				end
			end
		end

		for k, name in ipairs(self.vRenderOrder) do
			local v = self.VElements[name]
			if not v then self.vRenderOrder = nil break end
			if v.hide then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if not v.bone then continue end
			local pos, ang = self:GetBoneOrientation(self.VElements, v, vm)
			if not pos then continue end
			
			if v.type == "Model" and IsValid(model) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix("RenderMultiply", matrix)
				
				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial(v.material)
				end
				
				if v.skin and v.skin ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end
				
				if v.bodygroup then
					for k, v in pairs(v.bodygroup) do
						if model:GetBodygroup(k) ~= v then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if v.surpresslightning then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end
			elseif v.type == "Sprite" and sprite then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif v.type == "Quad" and v.draw_func then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func(self)
				cam.End3D2D()
			end
		end
	end

	SWEP.wRenderOrder = nil
	function SWEP:DrawWorldModel()
		local e_draw, e_clear = self:ScreenShouldDraw()
		if not (self.RenderOnGround or IsValid(self.Owner))  then
			e_draw, e_clear = false, true
		end
		self:RenderScreenHelper(e_draw, e_clear)
		
		if self.ShowWorldModel ~= false then
			self:DrawModel()
		end
		
		if not self.WElements then return end
		
		if not self.wRenderOrder then
			self.wRenderOrder = {}
			for k, v in pairs(self.WElements) do
				if v.type == "Model" then
					table.insert(self.wRenderOrder, 1, k)
				elseif v.type == "Sprite" or v.type == "Quad" then
					table.insert(self.wRenderOrder, k)
				end
			end
		end
		
		local bone_ent = IsValid(self.Owner) and self.Owner or self
		
		for k, name in pairs(self.wRenderOrder) do
			local v = self.WElements[name]
			if not v then self.wRenderOrder = nil break end
			if v.hide then continue end
			
			local bone_id = not v.bone and "ValveBiped.Bip01_R_Hand" or nil
			local pos, ang = self:GetBoneOrientation(self.WElements, v, bone_ent, bone_id)
			if not pos then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if v.type == "Model" and IsValid(model) then
				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix("RenderMultiply", matrix)
				
				if v.material == "" then
					model:SetMaterial("")
				elseif model:GetMaterial() ~= v.material then
					model:SetMaterial(v.material)
				end
				
				if v.skin and v.skin ~= model:GetSkin() then
					model:SetSkin(v.skin)
				end
				
				if v.bodygroup then
					for k, v in pairs(v.bodygroup) do
						if model:GetBodygroup(k) ~= v then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if v.surpresslightning then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if v.surpresslightning then
					render.SuppressEngineLighting(false)
				end
			elseif v.type == "Sprite" and sprite then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
			elseif v.type == "Quad" and v.draw_func then
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func(self)
				cam.End3D2D()
			end
		end
	end

	function SWEP:GetBoneOrientation(basetab, tab, ent, bone_override)
		local bone, pos, ang
		if tab.rel and tab.rel ~= "" then
			local v = basetab[tab.rel]
			if not v then return end
			
			-- Technically, if there exists an element with the same name as a bone
			-- you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:GetBoneOrientation(basetab, v, ent)
			if not pos then return end
			
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
		else
			bone = ent:LookupBone(bone_override or tab.bone)
			if not bone then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if m then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip then
				ang.r = -ang.r -- Fixes mirrored models
			end
		end
		
		return pos, ang
	end

	function SWEP:CreateModels(tab)
		if not tab then return end

		-- Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs(tab) do
			if v.type == "Model" and v.model and v.model ~= "" and (not IsValid(v.modelEnt) or v.createdModel ~= v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME")  then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if IsValid(v.modelEnt) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
			elseif v.type == "Sprite" and v.sprite and v.sprite ~= "" and (not v.spriteMaterial or v.createdSprite ~= v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME") then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				-- make sure we create a unique name based on the selected options
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs(tocheck) do
					if v[j] then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
			end
		end
	end

	function SWEP:UpdateBonePositions(vm)
		if self.ViewModelBoneMods then
			if not vm:GetBoneCount() then return end
			local loopthrough = self.ViewModelBoneMods
			
			for k, v in pairs(loopthrough) do
				local bone = vm:LookupBone(k)
				if not bone then continue end

				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				
				if vm:GetManipulateBoneScale(bone) ~= s then
					vm:ManipulateBoneScale(bone, s)
				end
				if vm:GetManipulateBoneAngles(bone) ~= v.angle then
					vm:ManipulateBoneAngles(bone, v.angle)
				end
				if vm:GetManipulateBonePosition(bone) ~= p then
					vm:ManipulateBonePosition(bone, p)
				end
			end
		else
			self:ResetBonePositions(vm)
		end
	end
	 
	function SWEP:ResetBonePositions(vm)
		local bonecount = vm:GetBoneCount()
		if not bonecount then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale(i, Vector(1, 1, 1))
			vm:ManipulateBoneAngles(i, Angle(0, 0, 0))
			vm:ManipulateBonePosition(i, Vector(0, 0, 0))
		end
	end

	--[[--------------------------
		Global utility code
	----------------------------]]

	-- Fully copies the table, meaning all tables inside this table are copied too and so on (normal table.Copy copies only their reference).
	-- Does not copy entities of course, only copies their reference.
	-- WARNING: do not use on tables that contain themselves somewhere down the line or you'll get an infinite loop
	function table.FullCopy(tab)
		if not tab then return nil end
		local res = {}
		for k, v in pairs(tab) do
			if type(v) == "table" then
				res[k] = table.FullCopy(v) -- recursion ho!
			elseif type(v) == "Vector" then
				res[k] = Vector(v.x, v.y, v.z)
			elseif type(v) == "Angle" then
				res[k] = Angle(v.p, v.y, v.r)
			else
				res[k] = v
			end
		end
		return res
	end

end
