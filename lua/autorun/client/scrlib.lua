--[[---------------------------------------------
	ScrLib (C) Mijyuoon 2014-2020
	Contains useful drawing functions
-----------------------------------------------]]

if scr then return end

local mat_lit2d = CreateMaterial("Lit2D", "VertexLitGeneric", {
	["$basetexture"] = "", ["$translucent"] = 1,
})
local mat_pngrt = CreateMaterial("PngRT", "UnlitGeneric", {
	["$basetexture"] = "", ["$ignorez"] = 1, ["$model"] = 1,
	["$vertexcolor"] = 1, ["$vertexalpha"] = 1,
})
scr = {
	-- Constants
	LIT_2D = mat_lit2d,
	PNG_RT = mat_pngrt,
}

function scr.Clear(col)
    render.Clear(col.r,col.g,col.b,col.a)
end

function scr.EnableTexture(tex)
	local m_type = type(tex)
	if m_type == "IMaterial" then
		surface.SetMaterial(tex)
	elseif m_type == "number" then
		surface.SetTexture(m_type)
	elseif not tex then
		surface.SetTexture(0)
	end
end

function scr.DrawRect(x,y,w,h,col)
    surface.SetDrawColor(col)
    surface.DrawRect(x,y,w,h)
end

function scr.DrawTexRect(x,y,w,h,tex,col)
	surface.SetDrawColor(col or color_white)
	scr.EnableTexture(tex)
	x, y = x+w/2, y+h/2
	surface.DrawTexturedRectRotated(x,y,w,h,0)
end

function scr.DrawTexRectUV(x,y,w,h,tex,col,ul,vl,uh,vh)
	surface.SetDrawColor(col or color_white)
	scr.EnableTexture(tex)
	local rw = tex:GetInt("$realwidth") or tex:Width()
	local rh = tex:GetInt("$realheight") or tex:Height()
	ul = (ul < 1e-7) and ul-0.5/rw or ul
	vl = (vl < 1e-7) and vl-0.5/rh or vl
	uh = (1 - uh < 1e-7) and uh+0.5/rw or uh
	vh = (1 - vh < 1e-7) and vh+0.5/rh or vh
	surface.DrawTexturedRectUV(x,y,w,h, ul,vl, uh,vh)
end

local min, max = math.min, math.max
function scr.DrawLine(x1,y1,x2,y2,col,sz)
	if x1 > x2 then
		x1, y1, x2, y2 = x2, y2, x1, y1
	end
	if y1 > y2 then
		x1, y1, x2, y2 = x2, y2, x1, y1
	end
    surface.SetDrawColor(col)
    if x1 == x2 then
        -- vertical lines
        local wid =  (sz or 1) / 2
        surface.DrawRect(x1-wid, y1, wid*2, y2-y1)
    elseif y1 == y2 then
        -- horizontal lines
        local wid =  (sz or 1) / 2
        surface.DrawRect(x1, y1-wid, x2-x1, wid*2)
    else
        -- non-axial lines
        local x3 = (x1 + x2) / 2
        local y3 = (y1 + y2) / 2
        local wx = math.sqrt((x2-x1) ^ 2 + (y2-y1) ^ 2)
        local angle = math.deg(math.atan2(y1-y2, x2-x1))
        surface.SetTexture(0)
        surface.DrawTexturedRectRotated(x3, y3, wx, (sz or 1), angle)
    end
end

local function rect_outln(x,y,w,h,c)
    scr.DrawLine(x-1,y,x+w,y,c)
    scr.DrawLine(x+w,y-1,x+w,y+h,c)
    scr.DrawLine(x-1,y+h,x+w,y+h,c)
    scr.DrawLine(x,y-1,x,y+h,c)
end

function scr._DrawRectOL(x,y,w,h,col,sz)
    local wid = sz or 1
    if wid < 0 then
        for i = 0, wid+1, -1 do
            rect_outln(x+i, y+i, w-2*i+1, h-2*i+1, col)
        end
    elseif wid > 0 then
        for i = 1, wid do
            rect_outln(x+i, y+i, w-2*i+1, h-2*i+1, col)
        end 
    end
end

function scr.DrawRectOL(x,y,w,h,col,sz)
    sz = sz or 1
    local asz = math.abs(sz)
    local opu = math.ceil(asz/2)-0.0
    local opd = math.floor(asz/2)+0.0
    if sz < 0 then
        scr.DrawLine(x-opd,y-asz,x-opd,y+h+asz,col,asz)
        scr.DrawLine(x-asz,y-opd,x+w+asz,y-opd,col,asz)
        scr.DrawLine(x+w+opu,y-asz,x+w+opu,y+h+asz,col,asz)
        scr.DrawLine(x-asz,y+h+opu,x+w+asz,y+h+opu,col,asz)
    elseif sz > 0 then
        scr.DrawLine(x+opu,y,x+opu,y+h,col,asz)
        scr.DrawLine(x,y+opu,x+w,y+opu,col,asz)
        scr.DrawLine(x+w-opd,y,x+w-opd,y+h,col,asz)
        scr.DrawLine(x,y+h-opd,x+w,y+h-opd,col,asz)
    end
end

local cos, sin, rad, floor = math.cos, math.sin, math.rad, math.floor
function scr.Circle(dx,dy,rx,ry,rot,fi)
	local rot2, fi = rad(rot or 0), (fi or 45)
    local vert, s, c = {}, sin(rot2), cos(rot2)
    for ii = 0, fi do
        local ik = rad(ii*360/fi)
        local x, y = cos(ik), sin(ik)
        local xs = x * rx * c - y * ry * s + dx
        local ys = x * rx * s + y * ry * c + dy 
        vert[#vert+1] = { x = xs, y = ys }
    end
    return vert
end

function scr.Sector(dx,dy,rx,ry,ang,rot,fi)
	local rot2, fi = rad(rot or 0), (fi or 45)
    local vert, s, c = {}, sin(rot2), cos(rot2)
	vert[1] = { x = dx, y = dy }
	for ii = 0, fi do
		local ik = rad(ii*ang/fi)
        local x, y = cos(ik), sin(ik)
        local xs = x * rx * c - y * ry * s + dx
        local ys = x * rx * s + y * ry * c + dy 
        vert[#vert+1] = { x = xs, y = ys }
    end
    return vert
end

function scr.Poly(xr,yr,argv)
    local vert = {}
    for i=1, #argv, 2 do
        local xs, ys = (argv[i] or 0), (argv[i+1] or 0)
        vert[#vert+1] = { x = xs+xr, y = ys+yr }
    end
    return vert
end

function scr.DrawTriang(x1,y1,x2,y2,x3,y3,col)
	local verts = {
		{ x = x1, y = y1 },
		{ x = x2, y = y2 },
		{ x = x3, y = y3 },
	}
	scr.DrawPoly(verts,col)
end

function scr.DrawPoly(poly,col,tex)
    surface.SetDrawColor(col or color_white)
	scr.EnableTexture(tex)
    surface.DrawPoly(poly)
end

function scr.DrawPolyOL(poly,col,sz)
    for i=1, #poly do
        local va, vb = poly[i], (poly[i+1] or poly[1])
        scr.DrawLine(va.x, va.y, vb.x, vb.y, col, sz)
    end
end

function scr.DrawQuadUnlit(pos, norm, wid, hgt, tex, ang)
	render.SetMaterial(tex)
	render.DrawQuadEasy(pos, norm, wid, hgt, nil, ang or 180)
end

function scr.DrawQuadLit2D(pos, norm, wid, hgt, tex, ang)
	local lm = render.ComputeLighting(pos, norm)
	render.SetLightingOrigin(pos)
	render.ResetModelLighting(lm.x, lm.y, lm.z)
	local vtex = tex:GetTexture("$basetexture")
	mat_lit2d:SetTexture("$basetexture", vtex)
	scr.DrawQuadUnlit(pos, norm, wid, hgt, mat_lit2d, ang)
	render.SuppressEngineLighting(false)
end

function scr.PngToRT(tex)
	local m_type = type(tex)
	if m_type == "IMaterial" then
		tex = tex:GetTexture("$basetexture")
		mat_pngrt:SetTexture("$basetexture", tex)
	elseif m_type == "ITexture" then
		mat_pngrt:SetTexture("$basetexture", tex)
	end
	return mat_pngrt
end

local font_bits = {
	"antialias",
	"additive",	
	"shadow", 	
	"outline", 	
	"rotary",
	"underline",
	"italic", 	
	"strikeout",
}

local function mangle_font(fd)
	local bits = ""
	for _, kv in ipairs(font_bits) do
		bits = bits .. (fd[kv] and "1" or "0")
	end
	return string.format("%s_%d.%d_%d.%d_%s", 
		fd.font, fd.size, fd.weight, fd.blursize or 0, fd.scanlines or 0, bits)
end

function scr.CreateFont(name,font,size,weight,params)
	local fdata = {
		font	= font,
		size	= size or 12,
		weight	= weight or 400,
	}
	if isstring(params) then
		local options = {}
		for _, s in ipairs(params:Split(",")) do
			local k, v = s:match("(%w+)=(%d+)")
			options[k or s] = tonumber(v) or true
		end
		params = options
	end
	if istable(params) then
		fdata.antialias = params.antialias
		fdata.additive	= params.additive
		fdata.shadow 	= params.shadow
		fdata.outline 	= params.outline
		fdata.blursize 	= params.blur
		fdata.rotary	= params.rotary
		fdata.underline = params.underln
		fdata.italic 	= params.italic
		fdata.strikeout = params.strike
		fdata.scanlines = params.scanline
	end
	name = name or mangle_font(fdata)
	surface.CreateFont(name, fdata)
	return name
end

function scr.AutoFont(font,size,weight,params)
	return scr.CreateFont(nil,font,size,weight,params)
end

function scr.DrawText(x,y,text,xal,yal,col,font)
    if yal == 2 then yal = 4 end
	col = col or color_white
	font = font or "Default"
	draw.SimpleText(text, font, x, y, col, xal, yal)
end

function scr.DrawTextEx(x,y,text,xal,col,font)
	col = col or color_white
	font = font or "Default"
	draw.DrawText(text, font, x, y, col, xal)
end

function scr.TextSize(text,font)
    surface.SetFont(font)
    return surface.GetTextSize(text)
end

--[[local scissor_rect = {}

function scr.PushScissorRect(x,y,w,h)
	local cnt = #scissor_rect
	scissor_rect[cnt+1] = {x,y,x+w,y+h}
	render.SetScissorRect(x,y,x+w,y+h,true)
end

function scr.PopScissorRect()
	local cnt = #scissor_rect
	if cnt < 1 then return end
	scissor_rect[cnt] = nil
	if cnt > 1 then
		local t = scissor_rect[cnt-1]
		render.SetScissorRect(t[1],t[2],t[3],t[4],true)
	else
		render.SetScissorRect(0,0,0,0,false)
	end
end]]

function scr.GenTranslateMatrix(x,y)
	local mat = Matrix()
	mat:Translate(Vector(x,y,0))
	return mat
end

function scr.GenRotateMatrix(x,y,ang)
	local mat = Matrix()
	local pos = Vector(x,y,0)
	mat:Translate(pos)
	mat:Rotate(Angle(0,ang,0))
	mat:Translate(-pos)
	return mat
end

function scr.GenScaleMatrix(x,y,sx,sy)
	scy = scy or scx
	local mat = Matrix()
	local pos = Vector(x,y,0)
	mat:Translate(pos)
	mat:Scale(Vector(sx,sy,0))
	mat:Translate(-pos)
	return mat
end

local matrix_stack = {
	Matrix() -- Identity
}

function scr.PushMatrix(mat)
	local id = #matrix_stack
	local newmat = matrix_stack[id] * mat
	matrix_stack[id+1] = newmat
	cam.PushModelMatrix(newmat)
end

function scr.PopMatrix()
	if #matrix_stack < 2 then return end
	matrix_stack[#matrix_stack] = nil
	cam.PopModelMatrix()
end

function scr.ClearMatrix()
	while #matrix_stack > 1 do
		scr.PopMatrix()
	end
end

function scr.PushTranslateMatrix(x,y)
	scr.PushMatrix(scr.GenTranslateMatrix(x,y))
end

function scr.PushRotateMatrix(x,y,ang)
	scr.PushMatrix(scr.GenRotateMatrix(x,y,ang))
end

function scr.PushScaleMatrix(x,y,sx,sy)
	scr.PushMatrix(scr.GenScaleMatrix(x,y,sx,sy))
end

local mt_anim = {}
mt_anim.__index = mt_anim
scr.META_AnimTex = mt_anim

function mt_anim:Render(x,y,tex,col)
	scr.PushTranslateMatrix(x,y)
		local frame = self:GetFrame()
		scr.DrawPoly(frame,col,tex)
	scr.PopMatrix()
end

function mt_anim:GetFrame(clk)
	clk = clk or RealTime()
	if self._mode then
		return 0, 0
	end
	local fi = clk / self.Speed % self.Length
	return self._frames[math.floor(fi)+1]
end

function scr.AnimTexture1D(w,h,len,ds)
	local polys = {}
	for i = 1, len do
		polys[i] = {
			{x = 0, y = 0, u = 1/len*(i-1), v = 0},
			{x = w, y = 0, u = 1/len*i, v = 0},
			{x = w, y = h, u = 1/len*i, v = 1},
			{x = 0,	y = h, u = 1/len*(i-1), v = 1},
		}
	end
	return setmetatable({
		_mode = false,
		_frames = polys,
		Width = w,
		Height = h,
		Length = len,
		Speed = ds,
	}, mt_anim)
end
