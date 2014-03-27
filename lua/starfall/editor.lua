-------------------------------------------------------------------------------
-- SF Editor.
-- Functions for setting up the code editor, as well as helper functions for
-- sending code over the network.
-------------------------------------------------------------------------------

SF.Editor = {}

-- TODO: Server-side controls

if CLIENT then

	local function mktrue(tab)
		local rtab = {}
		for _,v in ipairs(tab) do
			rtab[v] = true
		end
		return rtab
	end
	
	local function mkoptable(optab)
		local ptab = {}
		for _, op in pairs(optab) do
			local current = ptab
			local color = tonumber(op[-1])
			if color then
				op = op:sub(1, -2)
			end
			for i = 1, #op do
				local c = op[i]
				local nxt = current[c]
				if not nxt then
					nxt = {}
					current[c] = nxt
				end

				if i == #op then
					nxt[1] = true
					nxt[3] = color
				else
					if not nxt[2] then
						nxt[2] = {}
					end
					current = nxt[2]
				end
			end
		end
		return ptab
	end

	local lua_keywords = mktrue {
		"if", "elseif", "else", "then", "in",
		"while", "for", "repeat", "until",
		"do", "end", "break", "continue",
		"function", "local", "return",
		"true", "false", "nil",
		"and", "or", "not"
	}
	
	local moon_keywords = mktrue {
		"if", "then", "else", "elseif", 
		"export", "import", "from", "switch", 
		"when", "with", "using", "do", "for", 
		"unless", "continue", "break", "using",
		"in", "while", "return", "local", "nil",
		"class", "extends", "super", "self",
		"and", "or", "not", "true", "false"
	}
	
	local lua_kwords2 = mktrue {
		"print", "pairs", "ipairs", "next",
		"error", "pcall", "opsUsed", "opsMax",
		"loadFile", "loadString", "loadStringM",
		"assert", "require", "loadLibrary", "type",
		"CLIENT", "SERVER", "tostring", "tonumber",
		"setmetatable", "getmetatable", "unpack",
		"getLibraries", "Color", "Vector", "Angle"
	}
	
	local moon_kwords2 = lua_kwords2
	
	local lua_optable = mkoptable {
		"+", "-", "*",  "/",  "%",  "^",
		"#", "=", ",",  ".",  ":",  ";",
		"<", ">", "==", "~=", ">=", "<=",
		"(", ")", "{",  "}",  "[",  "]",
	}
	
	local moon_optable = mkoptable {
		"+", "-", "*",  "/",  "%",  "^",
		"\\2", "->2", "=>2", "#", "=", "!2",
		"<", ">", "==", "~=", "!=", ">=", "<=",
		"(", ")", "{",  "}",  "[",  "]",
		",",  ".",  ":",  ";",
	}
	
	local colors = {
		["keyword"]		= { Color(160, 240, 160), false },
		["keyvalue2"]	= { Color(60,  175, 175), false },
		["symbol"]		= { Color(200, 120,  90), false },
		["operator"]	= { Color(205, 170, 105), false },
		["operator2"]	= { Color(100, 255,   0), false },
		["brackets"]	= { Color(224, 224, 224), false },
		["number"]		= { Color(240, 160, 160), false },
		["variable"]	= { Color(120, 135, 165), false },
		["class_var"]	= { Color(0,   190, 240), false },
		["string"]		= { Color(180,  80, 220), false },
		["comment"]		= { Color(85,  140,  30), false },
		["ppcommand"]	= { Color(240, 240, 160), false },
		["notfound"]	= { Color(240,  96,  96), false },
	}
	
	-- cols[n] = { tokendata, color }
	local cols = {}
	local lastcol
	local function addToken(tokenname, tokendata)
		local color = colors[tokenname]
		if lastcol and color == lastcol[2] then
			lastcol[1] = lastcol[1] .. tokendata
		else
			cols[#cols + 1] = { tokendata, color, tokenname }
			lastcol = cols[#cols]
		end
	end
	
	local string_gsub = string.gsub
	local string_find = string.find
	local string_sub = string.sub
	local string_format = string.format
	local string_match = string.match
	
	local function findStringEnding(self,row,char)
		char = char or '"'
		
		while self.character do
		--[[
			if self:NextPattern( ".?"..char ) then -- Found another string char (' or ")
				if self.tokendata[-2] ~= "\\" then -- Ending found
					return true
				end
			end	
			self:NextCharacter()
		--]]
			if self:NextPattern(char) then
				return true
			end
			if self.character == "\\" then 
				self:NextCharacter() 
			end
			self:NextCharacter()
		end
		
		return false
	end

	local function findMultilineEnding(self,row,what,mx) -- also used to close multiline comments
		self.mlcount = mx or ""
		if self:NextPattern( ".-%]"..(self.mlcount).."%]" ) then -- Found ending
			return true
		end
		
		self.multiline = what
		return false
	end
	
	local table_concat = table.concat
	local string_gmatch = string.gmatch
	
	local function findInitialMultilineEnding(self,row,what)
		if row == self.Scroll[1] then
			self.multiline = nil
			self.mlcount = ""
			--local singleline = false
			
			for i=1, self.Scroll[1]-1 do
				local row = self.Rows[i]
				
				if not self.multiline then
					local offset = 1
					repeat
						local _, succ = string_find(row, "%[(=*)%[.-%]%1%]", offset)
						if succ then offset = succ end
					until not succ
					
					local succ, vpref, vext = string_match(row, "()(.?.?)%[(=*)%[", offset)
					if succ then
						self.mlcount = vext
						self.multiline = (vpref == "--") and "comment" or "string"
					end
				else
					local succ, vext = string_match(row, "()%](=*)%]")
					if succ and vext == self.mlcount then
						self.multiline = nil
					end
				end
			end
		end
	end
	
	local function NextOperator(self, operators)
		local op = operators[self.character]
		if not op then
			self:NextCharacter()
			return false, nil
		end

		for ik=1,5 do
			self:NextCharacter()
			if not (op[2] and op[2][self.character]) then 
				return op[1], (op[3] or "") 
			end
			op = op[2][self.character]
		end
	end

	-- TODO: remove all the commented debug prints
	local function SyntaxColorLine(self,row)
		cols,lastcol = {}, nil
		self:ResetTokenizer(row)
		findInitialMultilineEnding(self,row,self.multiline,self.mlcount)
		self:NextCharacter()
		
		if self.multiline then
			if findMultilineEnding(self,row,self.multiline,self.mlcount) then
				addToken( self.multiline, self.tokendata )
				self.multiline = nil
			else
				self:NextPattern( ".*" )
				addToken( self.multiline, self.tokendata )
				return cols
			end
			self.tokendata = ""
		end
		
		local is_moon = self.parentpanel.moonscript
		local kwords = is_moon and moon_keywords or lua_keywords
		local kwords2 = is_moon and moon_kwords2 or lua_kwords2
		local operators = is_moon and moon_optable or lua_optable

		while self.character do
			self.tokendata = ""
			
			-- Eat all spaces
			local spaces = self:SkipPattern( "^%s*" )
			if spaces then addToken( "comment", spaces ) end
	
			if self:NextPattern( "^[%a_][%w_]*" ) then -- Variables and keywords
				if is_moon and self.character == ":" then -- Symbols (moonscript)
					addToken( "symbol", self.tokendata .. ":" )
					self:NextCharacter()
				elseif kwords2[self.tokendata] then
					addToken( "keyvalue2", self.tokendata )
				elseif kwords[self.tokendata] then
					addToken( "keyword", self.tokendata )
				else
					addToken( "variable", self.tokendata )
				end
			elseif is_moon and self:NextPattern( "^:[%a_][%w_]*" ) then -- Symbols (moonscript)
				addToken( "symbol", self.tokendata )
			elseif is_moon and (self:NextPattern("^@@?[%a_][%w_]*") or self:NextPattern("^@@?")) then -- Class variables (moonscript)
				addToken( "class_var", self.tokendata )
			elseif self:NextPattern( "^0[xX][%da-fA-F]+" ) then -- Hex numbers
				addToken( "number", self.tokendata )
			elseif self:NextPattern( "^%d*%.?%d+") then -- Numbers
				self:NextPattern( "[eE][+-]?%d+" )
				addToken( "number", self.tokendata )
			elseif self:NextPattern( "^%-%-" ) then -- Comment
				if self:NextPattern( "^@" ) then -- ppcommand
					self:NextPattern( ".*" ) -- Eat all the rest
					addToken( "ppcommand", self.tokendata )
				elseif not is_moon and self:NextPattern( "^%[=*%[" ) then -- Multi line comment
					local mlcount = string_match(self.tokendata, "=+")
					if findMultilineEnding( self, row, "comment", mlcount ) then -- Ending found
						addToken( "comment", self.tokendata )
					else -- Ending not found
						self:NextPattern( ".*" )
						addToken( "comment", self.tokendata )
					end
				else
					self:NextPattern( ".*" ) -- Skip the rest
					addToken( "comment", self.tokendata )
				end
			elseif self:NextPattern( "^[\"']" ) then -- Single line string
				if findStringEnding( self,row, self.tokendata ) then -- String ending found
					addToken( "string", self.tokendata )
				else -- No ending found
					self:NextPattern( ".*" ) -- Eat everything
					addToken( "string", self.tokendata )
				end
			elseif self:NextPattern( "^%[=*%[" ) then -- Multi line strings
				local mlcount = string_match(self.tokendata, "=+")
				if findMultilineEnding( self, row, "string", mlcount ) then -- Ending found
					addToken( "string", self.tokendata )
				else -- Ending not found
					self:NextPattern( ".*" )
					addToken( "string", self.tokendata )
				end
			-- elseif self:NextPattern( op_pattern ) then -- Operators
			elseif self:NextPattern("^[%(%)%[%]{}]") then
				addToken( "brackets", self.tokendata)
			else
				-- self:NextCharacter()
				local is_operator, degree = NextOperator(self, operators)
				if is_operator then
					addToken("operator" .. degree, self.tokendata)
				else
					addToken("notfound", self.tokendata)
				end
			end
			self.tokendata = ""
		end
		
		return cols
	end
	
	local code1 = "--@name \n--@author \n\n"
	local code2 = "--[[\n" .. [[
    Starfall Scripting Environment

    More info: http://gmodstarfall.github.io/Starfall/
    Reference Page: http://sf.inp.io
    Development Thread: http://www.wiremod.com/forum/developers-showcase/22739-starfall-processor.html
]] .. "]]"

	--- (Client) Intializes the editor, if not initialized already
	function SF.Editor.init()
		if SF.Editor.editor then return end
		
		SF.Editor.editor = vgui.Create("Expression2EditorFrame")

		-- Change default event registration so we can have custom animations for starfall
		function SF.Editor.editor:SetV(bool)
			local wire_expression2_editor_worldclicker = GetConVar("wire_expression2_editor_worldclicker")

			if bool then
				self:MakePopup()
				self:InvalidateLayout(true)
				if self.E2 then self:Validate() end
			end
			self:SetVisible(bool)
			self:SetKeyBoardInputEnabled(bool)
			self:GetParent():SetWorldClicker(wire_expression2_editor_worldclicker:GetBool() and bool) -- Enable this on the background so we can update E2's without closing the editor
			if CanRunConsoleCommand() then
				RunConsoleCommand("starfall_event", bool and "editor_open" or "editor_close")
			end
		end


		SF.Editor.editor:Setup("SF Editor", "starfall", "nothing") -- Setting the editor type to not nil keeps the validator line
		
		if not file.Exists("starfall", "DATA") then
			file.CreateDir("starfall")
		end
		
		-- Add "Sound Browser" button
		do
			local editor = SF.Editor.editor
			local SoundBrw = editor:addComponent(vgui.Create("Button", editor), -205, 30, -125, 20)
			SoundBrw.panel:SetText("")
			SoundBrw.panel.Font = "E2SmallFont"
			SoundBrw.panel.Paint = function(button)
				local w,h = button:GetSize()
				draw.RoundedBox(1, 0, 0, w, h, editor.colors.col_FL)
				if ( button.Hovered ) then draw.RoundedBox(0, 1, 1, w - 2, h - 2, Color(0,0,0,192)) end
				surface.SetFont(button.Font)
				surface.SetTextPos( 3, 4 )
				surface.SetTextColor( 255, 255, 255, 255 )
				surface.DrawText("  Sound Browser")
			end
			SoundBrw.panel.DoClick = function() RunConsoleCommand("wire_sound_browser_open") end
			editor.C.SoundBrw = SoundBrw
		end
		
		SF.Editor.editor:SetSyntaxColorLine( SyntaxColorLine )
		--SF.Editor.editor:SetSyntaxColorLine( function(self, row) return {{self.Rows[row], Color(255,255,255)}} end)
		
		function SF.Editor.editor:OnTabCreated( tab )
			local editor = tab.Panel
			editor:SetText( code1 .. code2 )
			editor.Start = editor:MovePosition({1,1}, #code1)
			editor.Caret = editor:MovePosition(editor.Start, #code2)
		end
		
		local editor = SF.Editor.editor:GetCurrentEditor()
		
		function SF.Editor.editor:Validate(gotoerror)
			local fname, code = (self:GetChosenFile() or "main"), self:GetCode()
			local pp_data = { moonscript = false }
			SF.Preprocessor.ParseDirectives(fname, code, {}, pp_data)
			
			if self.moonscript ~= pp_data.moonscript then
				self.moonscript = pp_data.moonscript
			end
			
			local fcn, err
			if pp_data.moonscript then
				if type(moonscript) == "table" then
					fcn, err = moonscript.loadstring(code, "SF:"..fname)
					if type(fcn) ~= "function" then
						err = err or fcn
					end
				else
					err = "MoonScript module not loaded, cannot validate"
				end
			else
				err = CompileString(code, "SF:"..fname, false)
			end
			
			if type(err) == "string" then
				self.C['Val'].panel:SetBGColor(128, 0, 0, 180)
				self.C['Val'].panel:SetFGColor(255, 255, 255, 128)
				self.C['Val'].panel:SetText( "   " .. err:gsub("\n"," ") )
			else
				self.C['Val'].panel:SetBGColor(0, 128, 0, 180)
				self.C['Val'].panel:SetFGColor(255, 255, 255, 128)
				self.C['Val'].panel:SetText( "   No Syntax Errors" )
			end
		end
	end
	
	--- (Client) Returns true if initialized
	function SF.Editor.isInitialized()
		return SF.Editor.editor and true or false
	end
	
	--- (Client) Opens the editor. Initializes it first if needed.
	function SF.Editor.open()
		SF.Editor.init()
		SF.Editor.editor:Open()
	end
	
	--- (Client) Gets the filename of the currently selected file.
	-- @return The open file or nil if no files opened or not initialized
	function SF.Editor.getOpenFile()
		if not SF.Editor.editor then return nil end
		return SF.Editor.editor:GetChosenFile()
	end
	
	--- (Client) Gets the current code inside of the editor
	-- @return Code string or nil if not initialized
	function SF.Editor.getCode()
		if not SF.Editor.editor then return nil end
		return SF.Editor.editor:GetCode()
	end
	
	--- (Client) Builds a table for the compiler to use
	-- @param maincode The source code for the main chunk
	-- @param codename The name of the main chunk
	-- @return True if ok, false if a file was missing
	-- @return A table with mainfile = codename and files = a table of filenames and their contents, or the missing file path.
	function SF.Editor.BuildIncludesTable(maincode, codename)
		local tbl = {}
		maincode = maincode or SF.Editor.getCode()
		codename = codename or SF.Editor.getOpenFile() or "main"
		tbl.mainfile = codename
		tbl.files = {}
		tbl.filecount = 0
		tbl.includes = {}

		local loaded = {}
		local ppdata = {}

		local function recursiveLoad(path)
			if loaded[path] then return end
			loaded[path] = true
			
			local code
			if path == codename and maincode then
				code = maincode
			else
				code = file.Read("Starfall/"..path, "DATA") or error("Bad include: "..path,0)
			end
			
			tbl.files[path] = code
			SF.Preprocessor.ParseDirectives(path,code,{},ppdata)
			
			if ppdata.includes and ppdata.includes[path] then
				local inc = ppdata.includes[path]
				if not tbl.includes[path] then
					tbl.includes[path] = inc
					tbl.filecount = tbl.filecount + 1
				else
					assert(tbl.includes[path] == inc)
				end
				
				for i=1,#inc do
					recursiveLoad(inc[i])
				end
			end
		end
		local ok, msg = pcall(recursiveLoad, codename)
		if ok then
			return true, tbl
		elseif msg:sub(1,13) == "Bad include: " then
			return false, msg
		else
			error(msg,0)
		end
	end


	-- CLIENT ANIMATION

	local busy_players = {}
	hook.Add("EntityRemoved", "starfall_busy_animation", function(ply)
		busy_players[ply] = nil
	end)

	local emitter = ParticleEmitter(vector_origin)

	net.Receive("starfall_editor_status", function(len)
		local ply = net.ReadEntity()
		local status = net.ReadBit() ~= 0 -- net.ReadBit returns 0 or 1, despite net.WriteBit taking a boolean
		if not ply:IsValid() or ply == LocalPlayer() then return end

		busy_players[ply] = status or nil
	end)

	local rolldelta = math.rad(80)
	timer.Create("starfall_editor_status", 1/3, 0, function()
		rolldelta = -rolldelta
		for ply, _ in pairs(busy_players) do
			local BoneIndx = ply:LookupBone("ValveBiped.Bip01_Head1") or ply:LookupBone("ValveBiped.HC_Head_Bone") or 0
			local BonePos, BoneAng = ply:GetBonePosition(BoneIndx)
			local particle = emitter:Add("radon/starfall2", BonePos + Vector(math.random(-10,10), math.random(-10,10), 60+math.random(0,10)))
			if particle then
				particle:SetColor(math.random(30,50),math.random(40,150),math.random(180,220) )
				particle:SetVelocity(Vector(0, 0, -40))

				particle:SetDieTime(1.5)
				particle:SetLifeTime(0)

				particle:SetStartSize(10)
				particle:SetEndSize(5)

				particle:SetStartAlpha(255)
				particle:SetEndAlpha(0)

				particle:SetRollDelta(rolldelta)
			end
		end
	end)

else

	-- SERVER STUFF HERE
	-- -------------- client-side event handling ------------------
	-- this might fit better elsewhere

	util.AddNetworkString("starfall_editor_status")

	resource.AddFile( "materials/radon/starfall2.png" )
	resource.AddFile( "materials/radon/starfall2.vmt" )
	resource.AddFile( "materials/radon/starfall2.vtf" )

	local starfall_event = {}


	concommand.Add("starfall_event", function(ply, command, args)
		local handler = starfall_event[args[1]]
		if not handler then return end
		return handler(ply, args)
	end)


	-- actual editor open/close handlers


	function starfall_event.editor_open(ply, args)
		net.Start("starfall_editor_status")
		net.WriteEntity(ply)
		net.WriteBit(true)
		net.Broadcast()
	end


	function starfall_event.editor_close(ply, args)
		net.Start("starfall_editor_status")
		net.WriteEntity(ply)
		net.WriteBit(false)
		net.Broadcast()
	end

end
