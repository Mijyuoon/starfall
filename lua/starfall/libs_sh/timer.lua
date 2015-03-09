-------------------------------------------------------------------------------
-- Time library
-------------------------------------------------------------------------------

local timer = timer

--- Deals with time and timers.
-- @shared
local timer_library, _ = SF.Libraries.Register("timer")

-- ------------------------- Time ------------------------- --

--- Same as GLua's CurTime()
function timer_library.curtime()
	return CurTime()
end

--- Same as GLua's RealTime()
function timer_library.realtime()
	return RealTime()
end

--- Same as GLua's SysTime()
function timer_library.systime()
	return SysTime()
end

--- Returns time between frames on client and ticks on server. Same thing as G.FrameTime in GLua
function timer_library.frametime()
	return FrameTime()
end

--- Same as Lua's os.date()
function timer_library.date(format, time)
	SF.CheckType(format, "string")
	if time ~= nil then
		SF.CheckType(time, "number")
	end
	return os.date(format, time)
end

--- Same as Lua's os.time()
function timer_library.time(ts_struct)
	if ts_struct ~= nil then
		SF.CheckType(ts_struct, "table")
	end
	return os.time(ts_struct)
end

-- ------------------------- Timers ------------------------- --

local function mangle_timer_name(instance, name)
	return string.format("sftimer_%s_%s", tostring(instance), name)
end

local function mk_base_timer(_cons, name, delay, reps, func)
	SF.CheckType(name, "string", 1)
	SF.CheckType(delay, "number", 1)
	reps = SF.CheckType(reps, "number", 1, 1)
	SF.CheckType(func, "function", 1)
	
	local instance = SF.instance
	local timername = mangle_timer_name(instance, name)
	
	local function timercb()
		if instance.error then return end
		local ok, msg, trb = instance:runFunction(func)
		if not ok then
			instance:Error(msg, trb)
			timer.Remove(timername)
		end
	end
	
	_cons(timername, delay, reps, timercb)
	instance.data.timers[name] = true
end

--- Creates (and starts) a timer
-- @param name The timer name
-- @param delay The time, in seconds, to set the timer to.
-- @param reps The repititions of the tiemr. 0 = infinte, nil = 1
-- @param func The function to call when the tiemr is fired
function timer_library.create(name, delay, reps, func)
	mk_base_timer(timer.Create, name, delay, reps, func)
end

--- Adjusts (or creates) a timer
-- @param name The timer name
-- @param delay The time, in seconds, to set the timer to.
-- @param reps The repititions of the tiemr. 0 = infinte, nil = 1
-- @param func The function to call when the tiemr is fired
function timer_library.adjust(name, delay, reps, func)
	mk_base_timer(timer.Adjust, name, delay, reps, func)
end

--- Removes a timer
-- @param name The timer name
function timer_library.remove(name)
	SF.CheckType(name, "string")
	
	local instance = SF.instance
	timer.Remove(mangle_timer_name(instance, name))
	instance.data.timers[name] = nil
end

--- Stops a timer
-- @param name The timer name
function timer_library.stop(name)
	SF.CheckType(name, "string")
	
	local instance = SF.instance
	timer.Stop(mangle_timer_name(instance, name))
end

--- Starts a timer
-- @param name The timer name
function timer_library.start(name)
	SF.CheckType(name, "string")
	
	local instance = SF.instance
	timer.Start(mangle_timer_name(instance, name))
end

--- Pauses a timer
-- @param name The timer name
function timer_library.pause(name)
	SF.CheckType(name, "string")
	
	local instance = SF.instance
	timer.Pause(mangle_timer_name(instance, name))
end

--- Unpauses a timer
-- @param name The timer name
function timer_library.unpause(name)
	SF.CheckType(name, "string")
	
	local instance = SF.instance
	timer.UnPause(mangle_timer_name(instance, name))
end

--- Creates a simple timer, has no name, can't be stopped, paused, or destroyed.
-- @param delay the time, in second, to set the timer to
-- @param func the function to call when the timer is fired
function timer_library.simple(delay, func)
	SF.CheckType(delay, "number")
	SF.CheckType(func, "function")
	
	local instance = SF.instance
	timer.Simple(delay, function()
		if IsValid(instance.data.entity) and not instance.error then
			local ok, msg, trb = instance:runFunction(func)
			if not ok then
				instance:Error("simple timer errored with: " .. msg, trb)
			end
		end
	end)
end

SF.Libraries.AddHook("initialize", function(instance)
	instance.data.timers = {}
end)

SF.Libraries.AddHook("deinitialize", function(instance)
	if instance.data.timers ~= nil then
		for name in pairs(instance.data.timers) do
			timer.Remove(mangle_timer_name(instance, name))
		end
	end
	instance.data.timers = nil
end)
