--- TODO: Permissions System before fixing this.
--- TODO: Add VON encoding of any table's that are passed, work on 'universal' serializer and deserializer
-------------------------------------------------------------------------------
-- File functions
-------------------------------------------------------------------------------

--- File functions. Allows modification of files.
-- @shared
local files_library, _ = SF.Libraries.Register("files")

-- Register privileges
do
	local P = SF.Permissions
	P.registerPrivilege( "file.read", "Read files", "Allows the user to read files from data/sf_files directory" )
	P.registerPrivilege( "file.write", "Write files", "Allows the user to write files to data/sf_files directory" )
	P.registerPrivilege( "file.exists", "File existence check", "Allows the user to determine whether a file in data/sf_files exists" )
end

file.CreateDir("sf_files/")

local function check_access(path, perm)
	return SF.Permissions.check( SF.instance.player, path, perm )
end

local function make_path(path)
	local path = path:gsub("[^%w%._]", "_")
	if CLIENT then
		return (path .. ".txt")
	end
	local plyid = SF.instance.player:SteamID():gsub(":","_")
	file.CreateDir("sf_files/"..plyid)
	return (plyid .. "/" .. path .. ".txt")
end

--- Reads a file from path
-- @param path Filepath relative to data/sf_files/. Cannot contain '..'
-- @return Contents, or nil if error
-- @return Error message if applicable
function files_library.read(path)
	SF.CheckType(path, "string")
	if not check_access(path, "file.read") then 
		return nil, "access denied"
	end
	local contents = file.Read("sf_files/"..make_path(path), "DATA")
	if not contents then 
		return nil, "file not found"
	end
	return contents
end

--- Writes to a file
-- @param path Filepath relative to data/sf_files/. Cannot contain '..'
-- @return True if OK, nil if error
-- @return Error message if applicable
function files_library.write(path, data)
	SF.CheckType(path, "string")
	SF.CheckType(data, "string")
	if not check_access(path, "file.write") then
		return nil, "access denied"
	end
	file.Write("sf_files/"..make_path(path), data)
	return true
end

--- Appends a string to the end of a file
-- @param path Filepath relative to data/sf_files/. Cannot contain '..'
-- @param data String that will be appended to the file.
-- @return Error message if applicable
function files_library.append(path,data)
	SF.CheckType(path, "string")
	SF.CheckType(data, "string")
	if not check_access(path, "file.write") then
		return nil, "access denied"
	end
	file.Append("sf_files/"..make_path(path), data)
	return true
end

--- Checks if a file exists
-- @param path Filepath relative to data/sf_files/. Cannot contain '..'
-- @return True if exists, false if not, nil if error
-- @return Error message if applicable
function files_library.exists(path)
	SF.CheckType(path, "string")
	if not check_access(path, "file.exists") then
		return nil, "access denied"
	end
	return file.Exists("sf_files/"..make_path(path), "DATA")
end

--- Retrieves file size
-- @param path Filepath relative to data/sf_files/. Cannot contain '..'
-- @return File size, nil if error
-- @return Error message if applicable
function files_library.size(path)
	SF.CheckType(path, "string")
	if not check_access(path, "file.read") then
		return nil, "access denied"
	end
	return file.Size("sf_files/"..make_path(path), "DATA")
end

--- Deletes a file
-- @param path Filepath relative to data/sf_files/. Cannot contain '..'
-- @return True if successful, nil if error
-- @return Error message if applicable
function files_library.delete(path)
	SF.CheckType(path, "string")
	local file_path = make_path(path)
	if not check_access(path, "file.write") then 
		return nil, "access denied"
	end
	if not file.Exists("sf_files/"..file_path, "DATA") then 
		return nil, "file not found"
	end
	file.Delete("sf_files/"..file_path)
	return true
end
