--[[
	SF LPeg library by Mijyuoon.
]]

--- LPeg library, allows for advanced pattern matching.
-- @shared

local lpeg_lib, _ = SF.Libraries.Register("lpeg")

local patt_mt = debug.getmetatable(lpeg.P(true))
local lp_methods, lp_meta = SF.Typedef("Pattern")
local wrap, unwrap = SF.CreateWrapper(lp_meta, true, false, patt_mt)

local op_types = {
	["number"] = true, ["string"] = true, 
	["boolean"] = true, ["Pattern"] = true
}
local function getpatt(patt)
	local vtype = SF.GetType(patt)
	if not op_types[vtype] then
		return nil
	end
	return unwrap(patt) or patt
end

local p_types = {
	["number"] = true, ["string"] = true, 
	["boolean"] = true, ["table"] = true, 
	["function"] = true, ["Pattern"] = true
}

function lpeg_lib.P(patt)
	local vtype = SF.GetType(patt)
	if not p_types[vtype] then
		SF.throw("Bad argument to pattern constructor",2)
	end
	if vtype == "table" then
		patt = adv.TblMapN(patt, unwrap)
	else
		patt = unwrap(patt) or patt
	end
	return wrap(lpeg.P(patt))
end

function lpeg_lib.B(patt)
	SF.CheckType(patt, lp_meta)
	local patt = unwrap(patt)
	return wrap(lpeg.B(patt))
end

function lpeg_lib.R(...)
	local range = {...}
	for _, rng in ipairs(range) do
		SF.CheckType(rng, "string")
		if #rng ~= 2 then
			SF.throw("Range string length must be 2", 2)
		end
	end
	return wrap(lpeg.R(...))
end

function lpeg_lib.S(str)
	SF.CheckType(str, "string")
	return wrap(lpeg.S(str))
end

function lpeg_lib.V(str)
	SF.CheckType(str, "string")
	return wrap(lpeg.V(str))
end

function lpeg_lib.L(patt)
	SF.CheckType(patt, lp_meta)
	local patt = unwrap(patt)
	return wrap(lpeg.L(patt))
end

function lpeg_lib.locale()
	local loc = lpeg.locale()
	for key, patt in pairs(loc) do
		loc[key] = wrap(patt)
	end
	return loc
end

function lpeg_lib.setmaxstack(num)
	SF.CheckType(num, "number")
	lpeg.setmaxstack(math.Clamp(num, 1, 10000))
end

function lpeg_lib.match(patt, str, pos, ...)
	SF.CheckType(patt, lp_meta)
	SF.CheckType(str, "string")
	if pos ~= nil then
		SF.CheckType(pos, "number")
	end
	local patt = unwrap(patt)
	return lpeg.match(patt, str, pos, ...)
end

function lp_methods:match(str, pos, ...)
	SF.CheckType(str, "string")
	if pos ~= nil then
		SF.CheckType(pos, "number")
	end
	local patt = unwrap(self) or patt
	return lpeg.match(patt, str, pos, ...)
end

function lp_meta.__unm(patt)
	local patt = unwrap(patt)
	return wrap(-patt)
end

function lp_meta.__add(pt1, pt2)
	local pt1 = getpatt(pt1)
	local pt2 = getpatt(pt2)
	if pt1 == nil or pt2 == nil then
		SF.throw("Bad argument to LPeg operator", 2)
	end
	return wrap(pt1 + pt2)
end

function lp_meta.__sub(pt1, pt2)
	local pt1 = getpatt(pt1)
	local pt2 = getpatt(pt2)
	if pt1 == nil or pt2 == nil then
		SF.throw("Bad argument to LPeg operator", 2)
	end
	return wrap(pt1 - pt2)
end

function lp_meta.__mul(pt1, pt2)
	local pt1 = getpatt(pt1)
	local pt2 = getpatt(pt2)
	if pt1 == nil or pt2 == nil then
		SF.throw("Bad argument to LPeg operator", 2)
	end
	return wrap(pt1 * pt2)
end

function lp_meta.__pow(patt, num)
	SF.CheckType(num, "number")
	local patt = unwrap(patt)
	return wrap(patt ^ num)
end

local c_types = {
	["number"] = true, ["string"] = true, 
	["table"] = true, ["function"] = true,
}
function lp_meta.__div(patt, val)
	if not c_types[SF.GetType(val)] then
		SF.throw("Bad argument to LPeg operator",2)
	end
	local patt = unwrap(patt)
	return wrap(patt / val)
end

function lp_meta.__tostring()
	return "[LPeg Pattern]"
end

function lpeg_lib.C(patt)
	SF.CheckType(patt, lp_meta)
	local patt = unwrap(patt)
	return wrap(lpeg.C(patt))
end

function lpeg_lib.Carg(num)
	SF.CheckType(num, "number")
	return wrap(lpeg.Carg(num))
end

function lpeg_lib.Cb(name)
	SF.CheckType(name, "string")
	return wrap(lpeg.Cb(name))
end

function lpeg_lib.Cc(...)
	return wrap(lpeg.Cc(...))
end

function lpeg_lib.Cf(patt, func)
	SF.CheckType(patt, lp_meta)
	SF.CheckType(func, "function")
	local patt = unwrap(patt)
	return wrap(lpeg.Cf(patt, func))
end

function lpeg_lib.Cg(patt, name)
	SF.CheckType(patt, lp_meta)
	if name ~= nil then
		SF.CheckType(name, "string")
	end
	local patt = unwrap(patt)
	return wrap(lpeg.Cg(patt, name))
end

function lpeg_lib.Cp()
	return wrap(lpeg.Cp())
end

function lpeg_lib.Cs(patt)
	SF.CheckType(patt, lp_meta)
	local patt = unwrap(patt)
	return wrap(lpeg.Cs(patt))
end

function lpeg_lib.Ct(patt)
	SF.CheckType(patt, lp_meta)
	local patt = unwrap(patt)
	return wrap(lpeg.Ct(patt))
end

function lpeg_lib.Cmt(patt, func)
	SF.CheckType(patt, lp_meta)
	SF.CheckType(func, "function")
	local patt = unwrap(patt)
	return wrap(lpeg.Cmt(patt, func))
end

local lpeg_re = {}
lpeg_lib.re = lpeg_re
local re_lib = lpeg.re

function lpeg_re.compile(patt, defs)
	SF.CheckType(patt, "string")
	if defs ~= nil then
		SF.CheckType(defs, "table")
	end
	return wrap(re_lib.compile(patt, defs))
end

local pt_types = {
	["string"] = true, ["Pattern"] = true,
}
function lpeg_re.find(str, patt, pos)
	SF.CheckType(str, "string")
	if not pt_types[SF.GetType(patt)] then
		SF.throw("Bad LPeg pattern type", 2)
	end
	if pos ~= nil then
		SF.CheckType(pos, "number")
	end
	local patt = unwrap(patt) or patt
	return re_lib.find(str, patt, pos)
end

function lpeg_re.match(str, patt)
	SF.CheckType(str, "string")
	if not pt_types[SF.GetType(patt)] then
		SF.throw("Bad LPeg pattern type", 2)
	end
	local patt = unwrap(patt) or patt
	return re_lib.match(str, patt)
end

local gs_types = {
	["string"] = true, ["table"] = true,
	["function"] = true,
}
function lpeg_re.gsub(str, patt, repl)
	SF.CheckType(str, "string")
	if not pt_types[SF.GetType(patt)] then
		SF.throw("Bad LPeg pattern type", 2)
	end
	if not gs_types[SF.GetType(repl)] then
		SF.throw("Bad replacement value type", 2)
	end
	local patt = unwrap(patt) or patt
	return re_lib.gsub(str, patt, repl)
end