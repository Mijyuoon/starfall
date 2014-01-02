--[[
	SF HTTP library by Person8880.
]]

--- HTTP library, allows for GET and POST requests.
-- @shared

local HTTPLib, _ = SF.Libraries.Register( "http" )

local Cooldown
local CurTime = CurTime
local Fetch = http.Fetch
local Post = http.Post

local FC = { FCVAR_ARCHIVE, FCVAR_DONTRECORD }

if SERVER then
	Cooldown = CreateConVar( "sf_http_cooldown_sv", "15", FC )
else
	Cooldown = CreateConVar( "sf_http_cooldown_cl", "15", FC )
end

local Requests = {}

local function AddRequest( Ply, Time )
	Requests[ Ply ] = Time

	timer.Create( "SF-HTTP"..Ply:EntIndex(), Cooldown:GetInt(), 1, function()
		if Requests[ Ply ] then
			Requests[ Ply ] = nil
		end
	end )
end

local function CanRequest( Ply )
	return Requests[ Ply ] == nil
end

--- Performs a GET request.
-- @param URL The URL to request.
-- @param OnSuccess Function to run on success. It's passed the body of the web page.
-- @param OnFail Function to run on failure.
function HTTPLib.fetch( URL, OnSuccess, OnFail )
	SF.CheckType( URL, "string" )
	SF.CheckType( OnSuccess, "function" )
	SF.CheckType( OnFail, "function" )

	local Instance = SF.instance
	local Ply = SF.instance.player

	if not CanRequest( Ply ) then return nil, "cooldown" end

	local Time = CurTime() + Cooldown:GetInt()

	AddRequest( Ply, Time )

	Fetch( URL, function( Body )
		if not ( Instance and Instance.initialized ) then return end
		if Requests[ Ply ] ~= Time then return end --Timed out.

		Instance:runFunction( OnSuccess, Body ) 
	end, function( ... )
		if not ( Instance and Instance.initialized ) then return end
		if Requests[ Ply ] ~= Time then return end

		Instance:runFunction( OnFail, ... ) 
	end )

	return true
end

--- Performs a POST request.
-- @param URL The URL to request.
-- @param Params The table of parameters of the POST request.
-- @param OnSuccess The function to run on success. It's passed the body of the response.
-- @param OnFail Function to run on failure.
function HTTPLib.post( URL, Params, OnSuccess, OnFail )
	SF.CheckType( URL, "string" )
	SF.CheckType( Params, "table" )
	SF.CheckType( OnSuccess, "function" )
	SF.CheckType( OnFail, "function" )

	local Instance = SF.instance
	local Ply = SF.instance.player

	if not CanRequest( Ply ) then return nil, "cooldown" end

	local Time = CurTime() + Cooldown:GetInt()

	AddRequest( Ply, Time )

	Post( URL, Params, function( Body )
		if not ( Instance and Instance.initialized ) then return end
		if Requests[ Ply ] ~= Time then return end --Timed out.

		Instance:runFunction( OnSuccess, Body ) 
	end, function( ... )
		if not ( Instance and Instance.initialized ) then return end
		if Requests[ Ply ] ~= Time then return end

		Instance:runFunction( OnFail, ... ) 
	end )

	return true
end

--- Returns when you can next run a request.
function HTTPLib.nextRequest()
	return Requests[ SF.instance.player ] or 0
end

--- Returns how long until the next request is allowed.
function HTTPLib.cooldownTime()
	local Next = Requests[ SF.instance.player ]

	if Next then
		return Next - CurTime()
	end

	return 0
end
