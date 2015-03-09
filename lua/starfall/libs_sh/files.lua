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
	P.registerPrivilege("file.read", "Read files", "Allows the user to read files from data/sf_files directory")
	P.registerPrivilege("file.write", "Write files", "Allows the user to write files to data/sf_files directory")
	P.registerPrivilege("file.exists", "File existence check", "Allows the user to determine whether a file in data/sf_files exists")
	P.registerPrivilege("file.getList", "Get list of files", "Allows the user to get list of files in data/sf_files")
	P.registerPrivilege("file.transfer", "Transfer files", "Allows user to transfer files between client and server")
end

file.CreateDir("sf_files/")

local function check_access(path, perm)
	return SF.Permissions.check(SF.instance.player, path, perm)
end

local function make_path_raw(path, inv)
	local is_client = CLIENT
	if inv then is_client = SERVER end
	if is_client then return (path .. ".txt") end
	local plyid = SF.instance.player:SteamID():gsub(":","_")
	file.CreateDir("sf_files/"..plyid)
	return (plyid .. "/" .. path .. ".txt")
end
local function make_path(path, inv)
	return make_path_raw(path:gsub("[^%w%._]", "_"), inv)
end

--- Reads a file from path
-- @param path Filepath relative to data/sf_files/
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
-- @param path Filepath relative to data/sf_files/
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
-- @param path Filepath relative to data/sf_files/
-- @param data String that will be appended to the file
-- @return True if OK, nil if error
-- @return Error message if applicable
function files_library.append(path, data)
	SF.CheckType(path, "string")
	SF.CheckType(data, "string")
	if not check_access(path, "file.write") then
		return nil, "access denied"
	end
	file.Append("sf_files/"..make_path(path), data)
	return true
end

--- Checks if a file exists
-- @param path Filepath relative to data/sf_files/
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
-- @param path Filepath relative to data/sf_files/
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
-- @param path Filepath relative to data/sf_files/
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

--- Gets list of files in data/sf_files
-- @return List of files
-- @return Error message if applicable
function files_library.getList()
	if not check_access(false, "file.getList") then 
		return nil, "access denied"
	end
	local file_path = make_path_raw("*")
	local files = file.Find("sf_files/"..file_path, "DATA")
	for key, fname in ipairs(files) do
		files[key] = fname:sub(1, -5)
	end
	return files
end

local net_send_func
if CLIENT then
	net_send_func = net.SendToServer
else
	net_send_func = function()
		net.Send(SF.instance.player)
	end
end

local function send_filedata(fname, fdata)
	if #data > 65000 then return end
	net.Start("SF_filetransfer")
		net.WriteInt(SF_UPLOAD_DATA, 8)
		net.WriteString(fname)
		net.WriteString(fdata)
	net_send_func()
end

net.Receive("SF_filetransfer", function()
	local action = net.ReadInt(8)
	if action == SF_UPLOAD_INIT then
		local fpath, upath = net.ReadString(), net.ReadString()
		if file.Exists("sf_files/"..fpath, "DATA") then
			send_filedata(upath, file.Read("sf_files/"..fpath, "DATA"))
		end
	elseif action == SF_UPLOAD_DATA then
		local fpath = net.ReadString()
		file.Write("sf_files/"..fpath, net.ReadString())
	end
end)

if SERVER then
	util.AddNetworkString("SF_filetransfer")
	
	--- Downloads file from server to client
	-- @param fname Filepath relative to data/sf_files/
	-- @return True if successful, nil if error
	-- @return Error message if applicable
	function files_library.download(fname)
		SF.CheckType(fname, "string")
		if not check_access(fname, "file.transfer") then 
			return nil, "access denied"
		end
		local fpath = make_path(fname)
		if not file.Exists("sf_files/"..fpath, "DATA") then 
			return nil, "file not found"
		end
		local upath = make_path(fname, true)
		send_filedata(upath, file.Read("sf_files/"..fpath, "DATA"))
		return true
	end
	
	--- Uploads file from client to server
	-- @param fname Filepath relative to data/sf_files/
	-- @return True if successful, nil if error
	-- @return Error message if applicable
	function files_library.upload(fname)
		SF.CheckType(fname, "string")
		if not check_access(fname, "file.transfer") then 
			return nil, "access denied"
		end
		net.Start("SF_filetransfer")
			net.WriteInt(SF_UPLOAD_INIT, 8)
			net.WriteString(make_path(fname, true))
			net.WriteString(make_path(fname, false))
		net_send_func()
		return true
	end
end
