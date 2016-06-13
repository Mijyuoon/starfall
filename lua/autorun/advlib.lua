--[[---------------------------------------------
	AdvLib (C) Mijyuoon 2014-2020
	Contains various useful functions
-----------------------------------------------]]

if adv then return end
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
	if MODLOAD[name] then return MODLOAD[name] end
	local kname = name:gsub("%.", "/") .. ".lua"
	local is_sv = file.Exists(kname, "LUA")
	local is_cl = file.Exists(kname, "LCL")
	if not (is_sv or is_cl) then
		error(Format("cannot find module \"%s\"", name))
	end
	local func = CompileFile(kname, name)
	if func then
		MODLOAD[name] = func() or true
		return MODLOAD[name]
	end
end

local sp = SERVER and "LSV" or "LCL"
function IncludeDir(dir)
	if dir[-1] ~= "/" then dir = dir.."/" end
	for _, fn in ipairs(file.Find(dir.."*", sp)) do
		if fn:find("%.lua$") then include(dir..fn) end
	end
end

function AddCSLuaDir(dir)
	if dir[-1] ~= "/" then dir = dir.."/" end
	for _, fn in ipairs(file.Find(dir.."*", "LUA")) do
		if fn:find("%.lua$") then AddCSLuaFile(dir..fn) end
	end
end

if pcall(require, "lpeg") then
	function lpeg.L(v) return #v end
else
    lpeg = loadmodule("moonscript.lulpeg")
end
lpeg.re = loadmodule("moonscript.lpeg_re")

local trmv = table.remove
function adv.StrFormat(text, subst)
	if subst == nil then
		subst = text
		text = trmv(text, 1)
	end
	text = text:gsub("%$([%w_]+)", function(s)
		local subs = subst[tonumber(s) or s]
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

function adv.StrSplit(str, sep)
	sep = lpeg.re.compile(sep)
	local elem = lpeg.C((1 - sep)^0)
	local gs = lpeg.Ct(elem * (sep * elem)^0)
	return gs:match(str)
end

function adv.StrLine(str, pos)
	local lines = adv.StrSplit(str, "%nl")
	for ln, lv in ipairs(lines) do
		if pos <= #lv then
			return ln, lv
		else
			pos = pos - #lv
		end
	end
	return 0, ""
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
		if not func(vi,ki) then
			tbl[ki] = nil
		end
	end
	return tbl
end

function adv.TblFiltN(tbl, func)
	local res = {}
	for ki, vi in pairs(tbl) do
		if func(vi,ki) then
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

function adv.TblVals(tbl)
	local res = {}
	for _, v in pairs(tbl) do
		res[#res+1] = v
	end
	return res
end

function adv.TblFind(tbl, val)
	for i, v in pairs(tbl) do
		if v == val then return i end
	end
end

function adv.TblSet(tbl)
	local res = {}
	for _, v in pairs(tbl) do
		res[v] = true
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

function adv.TblAppend(tbl, base)
	for key, val in pairs(base) do
		if tbl[key] == nil then
			tbl[key] = val
		end
	end
	return tbl
end

function adv.TblClear(tbl)
	for k in pairs(tbl) do
		tbl[k] = nil
	end
end

function adv.TblClearI(tbl)
	for i = #tbl, 1, -1 do
		tbl[i] = nil
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

do ---- Cached HTTP requests -------------------------
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
		return url2, rd and file.Read(url2, "DATA")
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
end --------------------------------------------------

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
	local lC,lCt = lpeg.C, lpeg.Ct
	
	local str = lC(lP"'" * (lP"''" + (1 - lP"'"))^0 * "'")
	local mark = lCt(lC"?" * lC(lR("AZ", "az", "09", "__")^1)^-1)
	local grammar = lCt(( str + mark + lC((1 - lS"'?")^1) )^0)
	
	local sq_meta = {}
	sq_meta.__index = sq_meta
	adv.META_SqlQuery = sq_meta
	
	local val_conv = {
		number = tostring;
		string = SQLStr;
		boolean = function(v)
			return v and "1" or "0"
		end;
	}
	function sq_meta:BindParam(key, value)
		local vconv = val_conv[type(value)]
		if not vconv then
			error("unsupported value type")
		end
		self.params[key] = vconv(value)
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
	
	function adv.SqlQuery(query)
		query = grammar:match(query)
		local parv = adv.TblWeakKV()
		return setmetatable({
			params = parv,
			builder = query,
		}, sq_meta)
	end
end --------------------------------------------------

do ---- Data structure networking --------------------
	local lP,lR,lS,lV = lpeg.P, lpeg.R, lpeg.S, lpeg.V
	local lC,lCc,lCt = lpeg.C, lpeg.Cc, lpeg.Ct
	
	local WS = lS" \t"^0
	local function sym(id)
		return WS * id
	end
	
	local function lnode(...)
		return {"#", ...}
	end
	local function mnode(...)
		return {"$", ...}
	end
	local function lmnode(...)
		return {"#", {"$", ...}}
	end
	
	local typid = lR"az" * lR("az","09")^0
	local ident = lR("az","AZ","09","__")^1
	
	local grammar = WS * lP{
		lCt(lCc"!!" * lV"Nodes"^1);
		LstNode = sym"{" * lV"Nodes"^1 * sym"}";
		MapNode = sym"${" * lV"MapV"^1 * sym"}";
		LmNode = sym"#{" * lV"MapV"^1 * sym"}";
		MapV = sym(lC(ident) * sym":" * lV"Nodes");
		Nodes =
			sym(lC(typid + "@")) +
			lV"LstNode" / lnode +
			lV"MapNode" / mnode + 
			lV"LmNode" / lmnode;
	} * WS * -1
	
	local wtypes = {
		i8  = "?Int($,8)",		u8 = "?UInt($,8)",
		i16 = "?Int($,16)",		u16 = "?UInt($,16)",
		i32 = "?Int($,32)", 	u32 = "?UInt($,32)",
		
		fs = "?Float($)",		fd = "?Double($)",
		s = "?String($)",		b = "?Bool($)",
		
		v = "?Float($.x)\n?Float($.y)\n?Float($.z)",
		a = "?Float($.p)\n?Float($.y)\n?Float($.r)",
		e = "?Entity($)",		["@"] = "?Type($)",
	}
	
	local rtypes = {
		i8 = "$ = ?Int(8)",		u8 = "$ = ?UInt(8)",
		i16 = "$ = ?Int(16)",	u16 = "$ = ?UInt(16)",
		i32 = "$ = ?Int(32)",	u32 = "$ = ?UInt(32)",
		
		fs = "$ = ?Float()",	fd = "$ = ?Double()",
		s = "$ = ?String()",	b = "$ = ?Bool()",
		
		v = "$ = Vector(?Float(), ?Float(), ?Float())",
		a = "$ = Angle(?Float(), ?Float(), ?Float())",
		e = "$ = ?Entity()",	["@"] = "$ = ?Type(?UInt(8))",
	}
	
	local ns_meta = {}
	ns_meta.__index = ns_meta
	adv.META_NetStruct = ns_meta
	
	function ns_meta:__FmtTyp(str, val)
		return str:gsub("%?", self.__Prefix):gsub("%$", val)
	end
	
	function ns_meta:__Append(str, fmt, lvl)
		local buf = self.__Buffer
		lvl = self.__Lvl + (lvl or 0)
		buf[#buf+1] = fmt and adv.StrFormat(str, fmt) or str
	end
	
	function ns_meta:__Iterate(node, ni)
		local lvl, mod = self.__Lvl, self.__Mode
		local ntyp, types = node[1], mod and wtypes or rtypes
		
		if ntyp == "!!" then
			local par = mod and "..." or ""
			self:__Append("local _val$1 = {$2}", { lvl, par })
		elseif ntyp == "#" then
			local ki = ni and "["..ni.."]" or ""
			if mod then
				self:__Append("local _val$1 = _val$2$3", { lvl, lvl-1, ki }, -1)
				self:__Append(self:__FmtTyp(wtypes.u16, "#_val$1"), { lvl }, -1)
				self:__Append("for _i$1 = 1, #_val$1, $2 do", { lvl, #node-1 }, -1)
			else
				self:__Append("local _val$1 = {}", { lvl }, -1)
				self:__Append("_val$2$3 = _val$1", { lvl, lvl-1, ki }, -1)
				self:__Append(self:__FmtTyp(rtypes.u16, "local _len$1"), { lvl }, -1)
				self:__Append("for _i$1 = 1, _len$1, $2 do", { lvl, #node-1 }, -1)
			end
		elseif ntyp == "$" then
			local ki = ni and "["..ni.."]" or ""
			if mod then
				self:__Append("local _val$1 = _val$2$3", { lvl, lvl-1, ki }, -1)
			else
				self:__Append("local _val$1 = {}", { lvl }, -1)
				self:__Append("_val$2$3 = _val$1", { lvl, lvl-1, ki }, -1)
			end
		end
		
		local step = (ntyp == "$") and 2 or 1
		for i = 2, #node, step do
			local val, key = node[i]
			if step == 2 then
				key = '"'..val..'"'
				val = node[i+1]
			end
			if not key and ni then
				key = adv.StrFormat{"_i$1+$2", lvl, i-2}
			elseif not ni then
				key = i-1
			end
			if istable(val) then
				self.__Lvl = lvl + 1
				self:__Iterate(val, key)
				self.__Lvl = lvl
			elseif types[val] then
				local frag = types[val]
				local vn = adv.StrFormat{"_val$1[$2]", lvl, key}
				self:__Append(self:__FmtTyp(frag, vn))
			else
				error("unknown type: "..val)
			end
		end
		
		if not mod and ntyp == "!!" then
			self:__Append("return _val$1", { lvl })
		elseif ntyp == "#" then
			self:__Append("end", nil, -1)
		end
	end
	
	local tcat = table.concat
	function ns_meta:InitWriter()
		if self.__WrFunc then
			return false
		end
		self.__Lvl = 0
		self.__Buffer = {}
		self.__Mode = true
		self.__Prefix = "net.Write"
		self:__Iterate(self.__Struc)
		local code = tcat(self.__Buffer, "\n")
		self.__WrFunc = CompileString(code, "NSr")
		return true
	end
	
	function ns_meta:InitReader()
		if self.__RdFunc then
			return false
		end
		self.__Lvl = 0
		self.__Buffer = {}
		self.__Mode = false
		self.__Prefix = "net.Read"
		self:__Iterate(self.__Struc)
		local code = tcat(self.__Buffer, "\n")
		self.__RdFunc = CompileString(code, "NSw")
		return true
	end
	
	function ns_meta:WriteStruct(...)
		self:InitWriter()
		self.__WrFunc(...)
	end
	
	function ns_meta:ReadStruct(upx)
		self:InitReader()
		local dat = self.__RdFunc()
		if not upx then
			return unpack(dat)
		end
		return dat
	end
	
	function adv.NetStruct(def, op)
		local struc = grammar:match(def)
		if not struc then return nil end
		local obj = setmetatable({
			__Struc = struc,
		}, ns_meta)
		return obj
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
		AddCSLuaFile("moonscript/errors.lua")
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
