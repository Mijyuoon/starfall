SF.DefaultEnvironment = SF.DefaultEnvironment or {}

--- Compiles a string and returns boolean success, compiled function or error.
function SF.DefaultEnvironment.compileString(string)
        local func = CompileString(string, "SF - CompileString:", false)
        if type(func) == "string" then
                return false, func
        end
        debug.setfenv(func, SF.instance.env)
        return true, func
end