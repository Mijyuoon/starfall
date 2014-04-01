--- TODO: Permissions System before fixing this.
--- TODO: Add VON encoding of any table's that are passed, work on 'universal' serializer and deserializer
-------------------------------------------------------------------------------
-- File functions
-------------------------------------------------------------------------------

--- File functions. Allows modification of files.
-- @shared
local files_library, _ = SF.Libraries.Register("files")

--- Access Files permission
-- @name Access Files Permission
-- @class table
-- @field name "Access Files"
-- @field desc "Allows access to data/sf_files/"
-- @field level 1
-- @field value True if clientside, false if serverside

SF.Permissions:registerPermission({
	name  = "AccessFiles",
	desc  = "Allows access to data/sf_files/",
	level = 1,
	value = 1,
})

file.CreateDir("sf_files/")

local function check_access()
	return SF.instance.permissions:checkPermission("AccessFiles")
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
	if not check_access() then 
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
	if not check_access() then
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
	if not check_access() then
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
	if not check_access() then
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
	if not check_access() then
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
	if not check_access() then 
		return nil, "access denied"
	end
	if not file.Exists("sf_files/"..file_path, "DATA") then 
		return nil, "file not found"
	end
	file.Delete(file_path)
	return true
end
