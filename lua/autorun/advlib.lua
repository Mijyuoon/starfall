--[[
	AdvLib (C) Mijyuoon 2014-2020
	Contains various helper functions
]]

adv = {
	-- Constants here
	-- Nothing for now
}

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
