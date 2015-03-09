--- Http library. Requests content from urls.
-- @shared
local http_library, _ = SF.Libraries.Register("http")
local http_interval = CreateConVar("sf_http_interval", "0.5", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Interval in seconds in which one http request can be made")
local http_max_active = CreateConVar("sf_http_max_active", "3", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The maximum amount of active http requests at the same time")

SF.Libraries.AddHook("initialize", function(instance)
	instance.data.http = {
		nextRequest = 0,
		active = 0
	}
end)

-- Raises an error when a http request was already triggered in the current interval
-- or if the maximum amount of simultaneous requests is currently active
local function httpRequestReady()
	if not http_library.canRequest() then
		SF.throw("You can't run a new http request yet", 2)
	end
	local httpData = SF.instance.data.http
	httpData.active = httpData.active + 1
	httpData.nextRequest = CurTime() + http_interval:GetFloat()
end

-- Runs the appropriate callback after a http request
local function runCallback(instance, callback, ...)
	local httpData = instance.data.http
	httpData.active = httpData.active - 1
	if callback then
		if IsValid(instance.data.entity) and not instance.error then
			local ok, msg, tb = instance:runFunction(callback, ...)
			if not ok then
				instance:Error("http callback errored with: " .. msg, tb)
			end
		end
	end
end

--- Checks if a new http request can be started
function http_library.canRequest()
	local httpData = SF.instance.data.http
	return httpData.nextRequest <= CurTime() and httpData.active < http_max_active:GetInt()
end

--- Runs a new http GET request
-- @param url http target url
-- @param callbackSuccess the function to be called on request success, taking the arguments body (string), length (number), headers (table) and code (number)
-- @param callbackFail the function to be called on request fail, taking the failing reason as an argument
function http_library.get(url, callbackSuccess, callbackFail)
	SF.CheckType(url, "string")
	SF.CheckType(callbackSuccess, "function")
	if callbackFail ~= nil then
		SF.CheckType(callbackFail, "function")
	end
	
	httpRequestReady()
	http.Fetch(url, function(body, len, headers, code) 
		runCallback(instance, callbackSuccess, body, len, headers, code)
	end, function (err)
		runCallback(instance, callbackFail, err)
	end)
end

--- Runs a new http POST request
-- @param url http target url
-- @param params POST parameters to be sent
-- @param callbackSuccess the function to be called on request success, taking the arguments body (string), length (number), headers (table) and code (number)
-- @param callbackFail the function to be called on request fail, taking the failing reason as an argument
function http_library.post(url, params, callbackSuccess, callbackFail)
	SF.CheckType(url, "string")
	SF.CheckType(callbackSuccess, "function")	
	if callbackFail ~= nil then
		SF.CheckType(callbackFail, "function") 
	end
	
	if params ~= nil then
		SF.CheckType(params, "table")
		for key, val in pairs(params) do
			if type(key) .. type(val) ~= "stringstring" then
				SF.throw("POST parameters can only contain string keys and values", 2)
			end
		end
	end
	
	httpRequestReady()
	http.Post(url, params, function(body, len, headers, code)
		runCallback(instance, callbackSuccess, body, len, headers, code)
	end, function (err)
		runCallback(instance, callbackFail, err)
	end)
end
