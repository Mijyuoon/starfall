--[[---------------------------------------------
	AdvLib (C) Mijyuoon 2014-2020
	Contains various helper functions
-----------------------------------------------]]

adv = {
	-- Constants here
	HttpCache = {},
	Markup = {},
}

----- Config section ----------------------------
local Use_MoonScript	= true
local Use_PrintTable	= false
-------------------------------------------------

local MODLOAD = {}
adv._MODLOAD = MODLOAD
function loadmodule(name)
	if MODLOAD[name] then
		return MODLOAD[name]
	end
	
	local kname = name:gsub("%.", "/") .. ".lua"
	local is_sv = file.Exists(kname, "LUA")
	local is_cl = file.Exists(kname, "LCL")
	if not (is_sv or is_cl) then
		error(adv.StrFormat{"cannot find module \"$1\"", name})
	end
	
	local func = CompileFile(kname, name)
	if func then
		MODLOAD[name] = func() or true
		return MODLOAD[name]
	end
end

if pcall(require, "lpeg") then
	function lpeg.L(v) return #v end
else
    loadmodule("moonscript.lulpeg"):register(_G)
end
lpeg.re = loadmodule("moonscript.lpeg_re")

local trmv = table.remove
function adv.StrFormat(text, subst)
	if subst == nil then
		subst = text
		text = trmv(text, 1)
	end
	text = text:gsub("$([%w_]+)", function(s)
		local ns = tonumber(s) or s
		local subs = subst[ns]
		if subs == nil then return end
		return tostring(subs)
	end)
	return text
end

function adv.StrSet(text, pos, rep)
	pos = (pos < 0) and #text+pos+1 or pos
	if pos > #text or pos < 1 then return text end
	return text:sub(1, pos-1) .. rep .. text:sub(pos+1, -1)
end

adv.StrPatt  = lpeg.re.compile
adv.StrFind  = lpeg.re.find
adv.StrMatch = lpeg.re.match
adv.StrSubst = lpeg.re.gsub

function adv.TblMap(tbl, func)
	for ki, vi in pairs(tbl) do
		tbl[ki] = func(vi)
	end
	return tbl
end

function adv.TblMapN(tbl, func)
	local res = {}
	for ki, vi in pairs(tbl) do
		res[ki] = func(vi)
	end
	return res
end

function adv.TblFold(tbl, acc, func)
	local init = nil
	if func == nil then
		func = acc
		acc = tbl[1]
		init = acc
	end
	for _, vi in next, tbl, init do
		acc = func(acc, vi)
	end
	return acc
end

function adv.TblFilt(tbl, func)
	for ki, vi in pairs(tbl) do
		if not func(vi) then
			tbl[ki] = nil
		end
	end
	return tbl
end

function adv.TblFiltN(tbl, func)
	local res = {}
	for ki, vi in pairs(tbl) do
		if func(vi) then
			res[ki] = vi
		end
	end
	return res
end

function adv.TblSlice(tbl, from, to, step)
	local res = {}
	from = from or 1
	to = to or #tbl
	step = step or 1
	for i = from, to, step do
		res[#res+1] = tbl[i]
	end
	return res
end

function adv.TblAny(tbl, func)
	for ki, vi in pairs(tbl) do
		if func(vi) then
			return true
		end
	end
	return false
end

function adv.TblAll(tbl, func)
	for ki, vi in pairs(tbl) do
		if not func(vi) then
			return false
		end
	end
	return true
end

function adv.TblKeys(tbl)
	local res = {}
	for k in pairs(tbl) do
		res[#res+1] = k
	end
	return res
end

for _, kn in pairs{"K", "V", "KV"} do
	adv["TblWeak" .. kn] = function()
		return setmetatable({}, {
			__mode = kn:lower()
		})
	end
end

local function prefix(str)
	local stri = tostring(str)
	return (stri:gsub("^[a-z]+: ", ""))
end
local function do_printr(arg, spaces, passed)
	local ty = type(arg)
	if ty == "table" then
		passed[arg] = true
		Msg(adv.StrFormat{"(table) $v {\n",
			v = prefix(arg)})
		for k ,v in pairs(arg) do
			if not passed[v] then
				Msg(adv.StrFormat{"  $s($t) $k => ",
					s = spaces, t = type(k), k = k})
				do_printr(rawget(arg, k), spaces.."  ", passed)
			else
				Msg(adv.StrFormat{"  $s($t) $k => [RECURSIVE TABLE: $v]\n",
					s = spaces, t = type(k), k = k, v = prefix(v)})
			end
		end
		Msg(spaces .. "}\n")
	elseif ty == "function" then
		Msg(adv.StrFormat{"($t) $v\n",
			t = ty, v = prefix(arg)})
	elseif ty == "string" then
		Msg(adv.StrFormat{"($t) '$v'\n",
			t = ty, v = arg})
	elseif ty == "nil" then
		Msg(adv.StrFormat{"($t)\n",
			t = ty})
	else
		Msg(adv.StrFormat{"($t) $v\n",
			t = ty, v = arg})
	end
end

function adv.TblPrint(...)
	local arg = {...}
	for i = 1, #arg do
		do_printr(arg[i], "", {})
	end
end

if CLIENT then
	function adv.DataMat(mat, opts)
		return Material(adv.StrFormat{"../data/$1\n.png", mat}, opts)
	end
	
	function adv.DataSnd(snd, opts, func)
		sound.PlayFile(adv.StrFormat{"../data/$1\n.mp3", snd}, opts, func)
	end
end


local http_cache = {}
file.CreateDir("httpcache/")

function adv.HttpCache.Del(url)
	if not http_cache[url] then return false end
	url = url:gsub("^%w://", "")
	file.Delete(http_cache[url])
	if file.Exists(http_cache[url], "DATA") then return false end
	http_cache[url] = nil
	return true
end

function adv.HttpCache.Wipe(filt)
	for key, fn in pairs(http_cache) do
		if not filt or key:match(filt) then
			adv.HttpCache.Del(key)
		end
	end
	local rest = file.Find("httpcache/*.txt", "DATA")
	for _, fn in ipairs(rest) do
		if not filt or fn:match(filt) then
			file.Delete(fn)
		end
	end
end

function adv.HttpCache.Get(url, rd)
	local url2 = http_cache[url:gsub("^%w://", "")]
	if not url2 then return false end
	if not rd then return url2 end
	return url2, file.Read(url2, "DATA")
end

function adv.HttpCache.New(url, succ, fail)
	local url2 = url:gsub("^%w://", "")
	local rand = url2:match("/([^/]+)$"):gsub("[^%w_%-]", "")
	rand = adv.StrFormat{"httpcache/$1.txt", rand}
	if http_cache[url2] then
		succ(http_cache[url2])
		return true
	elseif file.Exists(rand, "DATA") then
		http_cache[url2] = rand
		succ(http_cache[url2])
		return true
	end
	http.Fetch(url, function(data, ...)
		file.Write(rand, data)
		http_cache[url2] = rand
		if succ then succ(rand, data, ...) end
	end, fail)
	return false
end

do ---- Markup parser --------------------------------
	local esc = {
		['<'] = "&lt;",
		['>'] = "&gt;",
		['&'] = "&amp;",
		['"'] = "&quot;",
	}
	local repl; repl = {
		__Stk = {};
		StkPush = function(val)
			table.insert(repl.__Stk, val)
		end;
		StkPop = function()
			return table.remove(repl.__Stk)
		end;
		ReInit = function()
			table.Empty(repl.__Stk)
		end;
		PtEsc = function(value)
			return value[1]
		end;
		PtCmd = function(iden, ...)
			if iden == "{\\}" then
				local val = repl.StkPop()
				return "</"..(val or "")..">"
			end
			local tags = adv.Markup.Tags
			if not tags[iden] then return "" end
			local html = tags[iden](...)
			local tag = html:match"^<([a-z%-]+)"
			if tag then repl.StkPush(tag) end
			return html
		end;
		PtRaw = function(value)
			return (value:gsub('[<>&"]', esc))
		end;
	}

	local lP,lR,lS = lpeg.P, lpeg.R, lpeg.S
	local lC,lCs,lCt = lpeg.C, lpeg.Cs, lpeg.Ct

	local besc = lP"{{" / repl.PtEsc
	local sesc = lP"\"\"" / repl.PtEsc
	local iden = lC( (lR("az","AZ","09") + lS"#-")^1 )
	local var1 = iden + "\"" * lCs(( (1 - lP"\"")^1 + sesc )^0) * "\""
	local varn = var1 * (";" * var1)^0
	local cmd = lCs(lP"{\\" * ( iden * ("=" * varn)^-1 )^-1 * "}" / repl.PtCmd)
	local grammar = lCt(( besc + cmd + ((1 - lP"{")^1 / repl.PtRaw) )^0)

	adv.Markup.Tags = {
		c = function(arg1)
			if not arg1 then return "" end
			return adv.StrFormat{'<span style="color:$1">', arg1}
		end;
		n = function(arg1)
			local temp = tonumber(arg1)
			if not temp then return "" end
			return adv.StrFormat{'<span style="font-size:$1">', temp}
		end;
		f = function(...)
			local args = {...}
			if #args < 1 then return "" end
			adv.TblMap(args, function(v) 
				local fn = v:gsub("\"", "")
				if not fn:match(" ") then return fn end
				return adv.StrFormat{"&quot;$1$quot;", fn}
			end)
			local temp = table.concat(args, ", ")
			return adv.StrFormat{'<span style="font-family:$1">', temp}
		end;
		b = function() return "<b>" end;
		i = function() return "<i>" end;
		u = function() return "<u>" end;
		s = function() return "<s>" end;
	}

	function adv.Markup.Parse(text)
		repl.ReInit()
		local vals = grammar:match(text)
		for i = 1, #repl.__Stk do
			vals[#vals+1] = "</"..repl.StkPop()..">"
		end
		local result = table.concat(vals)
		return (result:gsub("\r?\n", "<br>\n"))
	end
end --------------------------------------------------


do ---- SQL query builder ----------------------------
	local lP,lR,lS = lpeg.P, lpeg.R, lpeg.S
	local lC,lCs,lCt = lpeg.C, lpeg.Cs, lpeg.Ct

	local str = lC(lP"'" * (lP"''" + (1 - lP"'"))^0 * "'")
	local mark = lCt(lC"?" * lC(lR("AZ", "az", "09", "__")^1)^-1)
	local grammar = lCt(( str + mark + lC((1 - lS"'?")^1) )^0)
	
	local sq_meta = {}
	sq_meta.__index = sq_meta
	
	function sq_meta:BindParam(key, value)
		local ty, _value = type(value), nil
		if ty == "boolean" then
			_value = value and 1 or 0
		elseif ty == "string" then
			_value = SQLStr(value)
		elseif ty == "number" then
			_value = value
		end
		if not _value then
			error("unsupported type")
		end
		self.params[key] = _value
	end
	
	function sq_meta:BindTable(tbl)
		for key, val in pairs(tbl) do
			self:BindParam(key, val)
		end
	end
	
	function sq_meta:Execute()
		local pd = self.params
		local qd = self.builder
		local count = 1
		for i = 1, #qd do
			local value = qd[i]
			if istable(value) then
				local nk = value[2]
				nk = tonumber(nk) or nk
				if not nk then
					nk = count
					count = nk + 1
				end
				if not pd[nk] then
					error("Unbound parameter: "..nk)
				end
				qd[i] = pd[nk]
			end
		end
		local query = table.concat(qd)
		local ret = sql.Query(query)
		if ret == false then
			return false, sql.LastError()
		end
		return ret
	end
	
	function adv.SqlNew(query)
		query = grammar:match(query)
		local parv = adv.TblWeakKV()
		return setmetatable({
			params = parv,
			builder = query,
		}, sq_meta)
	end
end --------------------------------------------------

if Use_PrintTable then
	PrintTable = adv.TblPrint
end

if Use_MoonScript then
	if SERVER then
		AddCSLuaFile("moonscript/base.lua")
		AddCSLuaFile("moonscript/compile.lua")
		AddCSLuaFile("moonscript/data.lua")
		AddCSLuaFile("moonscript/dump.lua")
		AddCSLuaFile("moonscript/errors.lua")
		AddCSLuaFile("moonscript/line_tables.lua")
		AddCSLuaFile("moonscript/lpeg_re.lua")
		AddCSLuaFile("moonscript/lulpeg.lua")
		AddCSLuaFile("moonscript/parse.lua")
		AddCSLuaFile("moonscript/transform.lua")
		AddCSLuaFile("moonscript/types.lua")
		AddCSLuaFile("moonscript/util.lua")
		
		AddCSLuaFile("moonscript/compile/statement.lua")
		AddCSLuaFile("moonscript/compile/value.lua")
		
		AddCSLuaFile("moonscript/transform/names.lua")
		AddCSLuaFile("moonscript/transform/destructure.lua")
	end
	moonscript = loadmodule "moonscript.base"
end
