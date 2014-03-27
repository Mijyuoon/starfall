--[[
	Serverside screenPos() by Mijyuoon.
]]

local render_library, _ = SF.Libraries.Register("render")

--- Gets a 2D cursor position where ply is aiming.
function render_library.cursorPos( ply )
	-- Taken from EGPLib
	local Normal, Pos, monitor, Ang
	local screen = SF.instance.data.entity
	if not screen then return nil end
	
	ply = SF.Entities.Unwrap( ply )
	
	-- Get monitor screen pos & size
	monitor = WireGPU_Monitors[ screen:GetModel() ]
		
	-- Monitor does not have a valid screen point
	if not monitor then return nil end
		
	Ang = screen:LocalToWorldAngles( monitor.rot )
	Pos = screen:LocalToWorld( monitor.offset )
		
	Normal = Ang:Up()
	
	local Start = ply:GetShootPos()
	local Dir = ply:GetAimVector()
	
	local A = Normal:Dot(Dir)
	
	-- If ray is parallel or behind the screen
	if A == 0 or A > 0 then return nil end
	
	local B = Normal:Dot(Pos-Start) / A
		if (B >= 0) then
		local HitPos = WorldToLocal( Start + Dir * B, Angle(), Pos, Ang )
		local x = (0.5+HitPos.x/(monitor.RS*512/monitor.RatioX)) * 512
		local y = (0.5-HitPos.y/(monitor.RS*512)) * 512	
		if x < 0 or x > 512 or y < 0 or y > 512 then return nil end -- Aiming off the screen 
		return x, y
	end
	
	return nil
end