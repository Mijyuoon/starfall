--[[
	SF coroutine library by Mijyuoon.
]]

--- Coroutine library. Allows for co-operative threading.
-- @shared
local coroutine_lib, _ = SF.Libraries.Register("coroutine")

--- Creates and returns a coroutine thread object from the given function.
-- @class function
-- @param func Function to run inside the coroutine.
-- @return Coroutine object representing the given function.
function coroutine_lib.create(func)
	SF.CheckType(func, "function")
	return coroutine.create(func)
end

--- Resumes a given coroutine
-- @class function
-- @param coro Coroutine to resume.
-- @param ... Arguments that are passed to coroutine function.
-- @return Arguments that were passed to yield() function.
function coroutine_lib.resume(coro, ...)
	SF.CheckType(coro, "thread")
	return coroutine.resume(coro, ...)
end

--- Gets the status of a given coroutine. Either 'suspended', 'running' or 'dead'.
-- @class function
-- @param coro Coroutine to check.
-- @return Status of coroutine.
function coroutine_lib.status(coro)
	SF.CheckType(coro, "thread")
	return coroutine.status(coro)
end

--- Yields active coroutine, halting it in place ready for the next resume. 
-- @class function
-- @param ... Arguments to return from coroutine function.
function coroutine_lib.yield(...)
	coroutine.yield(...)
end

--- Returns a function that, when run, resumes the coroutine representing the given function. 
-- @class function
-- @param func Function to run inside the coroutine.
-- @return Function that resumes the coroutine when run.
function coroutine_lib.wrap(func)
	SF.CheckType(func, "function")
	return coroutine.wrap(func)
end