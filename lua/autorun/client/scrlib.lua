--[[---------------------------------------------
	ScrLib (C) Mijyuoon 2014-2020
	Contains useful drawing functions
-----------------------------------------------]]

local mat_lit2d = CreateMaterial("Lit2D", "VertexLitGeneric", {
	["$basetexture"] = "", ["$translucent"] = 1,
})
scr = {
	-- Constants
	LIT_2D = mat_lit2d,
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

function scr.DrawRectOL(x,y,w,h,col,sz)
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
		size	= size,
		weight	= weight,
	}
	if type(params) == "table" then
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

local scissor_rect = {}

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
end