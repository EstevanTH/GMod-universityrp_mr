--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

--[[ INFORMATION:
	- You can make slideshows with both pictures and iframe URLs.
	- Only 1 SAMEORIGIN URL is allowed in 1 slideshow.
]]

print("prop_teacher_computer_mr:sv")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("config/prop_teacher_computer_mr/shared.lua")
include("config/prop_teacher_computer_mr/server.lua")
resource.AddWorkshop("2128234105")

-- Configuration:
local LessonsListUrl = prop_teacher_computer_mr.LessonsListUrl or "models/prop_teacher_computer_mr/lessons_library.json.vvd"
local LessonsListRefresh_s = prop_teacher_computer_mr.LessonsListRefresh_s or 45.
local LessonsListRefreshAfterError_s = prop_teacher_computer_mr.LessonsListRefreshAfterError_s or 10.
local SleepTimeout_s = prop_teacher_computer_mr.SleepTimeout_s or 600.
local OnlyTeachersIfProjector = prop_teacher_computer_mr.OnlyTeachersIfProjector or false
ENT.Model = prop_teacher_computer_mr.Model or "models/props/cs_office/computer.mdl"
ENT.RemoteModel = prop_teacher_computer_mr.RemoteModel or "models/props/cs_office/projector_remote.mdl"
ENT.RemotePos = prop_teacher_computer_mr.RemotePos or Vector(-1.00, 12.00, 0.00)
ENT.RemoteAng = prop_teacher_computer_mr.RemoteAng or Angle(0., -70., 0.)
ENT.PhoneModel = prop_teacher_computer_mr.PhoneModel or "models/props/cs_office/phone.mdl"
ENT.PhonePos = prop_teacher_computer_mr.PhonePos or Vector(-7.00, 25.00, 0.00)
ENT.PhoneAng = prop_teacher_computer_mr.PhoneAng or Angle(0., -15., 0.)

local a = prop_teacher_computer_mr.actions -- shortcut

local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "prop_teacher_computer_mr:sv")

function ENT:KeyValue(key, value)
	local key = string.lower(key)
	if key == "model" then
		self.Model = value
	elseif key == "projector" then
		self.projector = value
	elseif key == "seat" then
		self.seat = value
	elseif key == "gmod_allowphysgun" then
		if value == "0" then
			self.staticPhysics = true
		end
	end
end

local invalidModels = {
	["models/error.mdl"] = true,
	[""] = true,
}

function ENT:Initialize()
	if invalidModels[self:GetModel()] then
		self:SetModel(self.Model)
	end
	self:SetSkin(1)
	if self.staticPhysics then
		self:PhysicsInitStatic(SOLID_VPHYSICS)
	else
		self:PhysicsInit(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end
	prop_teacher_computer_mr._markAsCreated(self)
	
	if self.projector and not IsValid(self:GetProjector()) then
		self:SetProjector(ents.FindByName(self.projector)[1])
	end
	self.projector = nil
	
	if self.seat and not IsValid(self:GetSeat()) then
		self:SetSeat(ents.FindByName(self.seat)[1])
	end
	self.seat = nil
end

function ENT:OnRemove()
	prop_teacher_computer_mr._markAsDestroyed(self)
end

function ENT:makeRemoteProp()
	if not IsValid(self.Remote) then
		self.Remote = ents.Create("prop_dynamic")
		if IsValid(self.Remote) then
			self.Remote:SetModel(self.RemoteModel)
			self.Remote:SetSolid(SOLID_NONE)
			self.Remote:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			self.Remote:SetParent(self)
			self.Remote:SetLocalPos(self.RemotePos)
			self.Remote:SetLocalAngles(self.RemoteAng)
		end
	end
end

function ENT:removeRemoteProp()
	if IsValid(self.Remote) then
		self.Remote:Remove()
	end
	self.Remote = nil
end

function ENT:makePhoneProp()
	-- Decoration: make a phone prop
	
	if not IsValid(self.Phone) then
		self.Phone = ents.Create("prop_dynamic")
		if IsValid(self.Phone) then
			self.Phone:SetModel(self.PhoneModel)
			self.Phone:SetSolid(SOLID_NONE)
			self.Phone:SetCollisionGroup(COLLISION_GROUP_WEAPON)
			self.Phone:SetParent(self)
			self.Phone:SetLocalPos(self.PhonePos)
			self.Phone:SetLocalAngles(self.PhoneAng)
		end
	end
end

do
	-- Broadcast clock updates:
	
	local nextAtmosRefresh = 0.
	hook.Add("Tick", "prop_teacher_computer_mr:sv", function()
		local now = RealTime()
		local atmosActive
		if now > nextAtmosRefresh then
			if type(atmos_enabled) == "ConVar" and atmos_enabled:GetInt() >= 1 then
				atmosActive = true
			else
				atmosActive = false
			end
			nextAtmosRefresh = now + 60.
		end
		if atmosActive then
			SetGlobalInt("URP_clock", math.floor(AtmosGlobal:GetTime() * 3600))
		else
			SetGlobalInt("URP_clock", -1)
		end
	end)
end

function ENT:playerEntered(ply)
	-- nothing
end

function ENT:playerLeft(ply)
	-- nothing
end

function ENT:GetUser()
	local user
	do
		local user_ = self:GetRemoteOwner()
		if IsValid(user_) then
			user = user_
		end
	end
	if not user then
		local seat = self:GetSeat()
		if IsValid(seat) then
			local user_ = seat:GetDriver()
			if IsValid(user_) then
				user = user_
			end
		end
	end
	return user
end

do
	-- Seat management:
	
	hook.Add("PlayerLeaveVehicle", "prop_teacher_computer_mr:sv", function(ply, seat)
		-- Signal that the player left his seat:
		
		if IsValid(seat) then
			local computer = prop_teacher_computer_mr.getComputerFromSeat(seat)
			if computer then
				computer:playerLeft(ply)
			end
		end
	end)
	
	hook.Add("PlayerEnteredVehicle", "prop_teacher_computer_mr:sv", function(ply, seat)
		-- Signal that the player took place on his seat:
		
		if IsValid(seat) then
			local computer = prop_teacher_computer_mr.getComputerFromSeat(seat)
			if computer then
				computer:playerEntered(ply)
			end
		end
	end)
	
	hook.Add("CanPlayerEnterVehicle", "prop_teacher_computer_mr:sv", function(ply, seat)
		-- Do an entry check to prevent computer usage in a classroom:
		-- The module "universityrp_mr_agenda" is required.
		
		local allowed = hook.Run("prop_teacher_computer_mr:canUseComputer", ply, computer)
		if allowed == nil and OnlyTeachersIfProjector and universityrp_mr_agenda then
			local computer = IsValid(seat) and prop_teacher_computer_mr.getComputerFromSeat(seat)
			if computer and IsValid(computer:GetProjector()) then
				allowed = universityrp_mr_agenda.playerIsTeacher(ply)
			end
		end
		if allowed == nil then
			allowed = true
		end
		if not allowed then
			return false
		end
	end)
	
	hook.Add("seat_natural_leaving:shouldDo", "prop_teacher_computer_mr:sv", function(seat, ply)
		-- Do the job even when a parent entity (usually the desk) exist:
		
		local computer = prop_teacher_computer_mr.getComputerFromSeat(seat)
		if computer then
			return true
		end
	end)
end

function ENT:turnComputerOn()
	if not self:isComputerOn() then -- because non-boolean state
		self:SetState(a.ComputerWake)
	end
end

function ENT:turnComputerOff()
	self:SetState(a.ComputerSleep)
end

function ENT:giveRemote(ply)
	if IsValid(self.Remote) and not IsValid(self:GetRemoteOwner()) then
		self:SetRemoteOwner(ply)
		if IsValid(self.Remote) then
			self.Remote:SetNoDraw(true)
		end
		if IsValid(self.HandRemote) then
			self.HandRemote:Remove()
		end
		if ply:HasWeapon(self.RemoteWeaponClass) then
			self.HandRemote = ply:GetWeapon(self.RemoteWeaponClass)
		else
			self.HandRemote = ply:Give(self.RemoteWeaponClass, true)
		end
		-- ply:SelectWeapon() does not work on a seat.
		ply:SetActiveWeapon(self.HandRemote)
	end
end

function ENT:stripRemote()
	local ply = self:GetRemoteOwner()
	self:SetRemoteOwner(nil)
	if IsValid(self.HandRemote) then
		self.HandRemote:Remove()
		self.HandRemote = nil
	end
	if IsValid(self.Remote) then
		self.Remote:SetNoDraw(false)
	end
	if IsValid(ply) then
		local previousWeapon = ply:GetPreviousWeapon()
		if IsValid(previousWeapon) and previousWeapon:IsWeapon() then
			ply:SetActiveWeapon(previousWeapon)
		end
	end
end

function prop_teacher_computer_mr.slideshowAllowedInWhitelist(lesson, ply)
	-- Check if the player can open the specified slideshow according to the whitelist:
	-- The whitelist checks: the SteamID, the user group, the super-admin rank, the TEAM_ name.
	
	local allowed = false
	if not lesson.allowed then
		-- allowed because there is no whitelist:
		allowed = true
	end
	if not allowed then
		if lesson.allowed[ply:SteamID()]
		or lesson.allowed[ply:GetUserGroup()]
		or ply:IsSuperAdmin() then
			-- allowed by SteamID or user group:
			allowed = true
		end
	end
	if not allowed then
		local team_ = ply:Team()
		for teamName in pairs(lesson.allowed) do
			if string.sub(teamName, 1, 5) == "TEAM_" then
				if _G[teamName] == team_ then
					-- allowed by team:
					allowed = true
					break
				end
			end
		end
	end
	return allowed
end

function prop_teacher_computer_mr.slideshowAllowed(lesson, ply, computer)
	local allowed = hook.Run("canOpenSlideshow_mr", lesson, ply, computer)
	if allowed == nil then
		allowed = prop_teacher_computer_mr.slideshowAllowedInWhitelist(lesson, ply)
	end
	return allowed
end

local function holdVideoUrl(computer)
	local currentUrl = computer:GetCurrentUrl()
	if prop_teacher_computer_mr.isVideoUrl(currentUrl) then
		computer.pendingVideoUrl = currentUrl
		-- unload video if slideshow not running, but hold the value:
		computer:SetCurrentUrl("")
		-- hold the position to continue playing 6 seconds before the current position:
		computer.videoStartPosition_s = math.max(0, math.floor(RealTime() - computer.videoStartedAt) - 6)
	end
end

util.AddNetworkString("prop_teacher_computer_mr")
net.Receive("prop_teacher_computer_mr", function(len, ply)
	if IsValid(ply) then
		local computer, on_seat = prop_teacher_computer_mr.getComputerFromPlayer(ply)
		local action = net.ReadUInt(8)
		local state
		if computer then
			state = computer:GetState()
		end
		if action == a.ScreenOpen then
			if computer then
				local bigScreen = computer:GetProjectorScreen()
				if IsValid(bigScreen) then
					bigScreen:openScreen()
				end
			end
		elseif action == a.ScreenClose then
			if computer then
				local bigScreen = computer:GetProjectorScreen()
				if IsValid(bigScreen) then
					bigScreen:closeScreen()
				end
			end
		elseif action == a.ComputerWake then
			if computer and on_seat then
				computer:turnComputerOn()
				computer:unloadLesson()
			end
		elseif action == a.ComputerSleep then
			if computer and on_seat then
				if state ~= a.SlideshowRun then -- security against wrong usage & unexpected behavior
					computer:turnComputerOff()
					computer:unloadLesson()
				end
			end
		elseif action == a.ProgramOpen then
			if computer and on_seat and state == a.ComputerWake then
				computer:SetState(a.ProgramOpen)
				computer:unloadLesson()
			end
		elseif action == a.ProgramClose then
			if computer and on_seat and (state == a.ProgramOpen or state == a.SlideshowOpen or state == a.SlideshowRun) then
				computer:SetState(a.ComputerWake)
				computer:unloadLesson()
			end
		elseif action == a.SlideNext then
			if computer then
				computer:actionSlideNext()
			end
		elseif action == a.SlidePrevious then
			if computer then
				computer:actionSlidePrevious()
			end
		elseif action == a.SlideSetPage then
			if computer and (state == a.SlideshowOpen or state == a.SlideshowRun) then
				local page = net.ReadUInt(16)
				computer:actionSlideSetPage(page)
			end
		elseif action == a.SlideshowRun then
			if computer and on_seat and state == a.SlideshowOpen and computer:isComputerOn() then
				computer:giveRemote(ply)
				computer:SetState(a.SlideshowRun)
				if computer.pendingVideoUrl then
					computer:SetCurrentUrl(computer.pendingVideoUrl) -- restore unloaded video
					computer.pendingVideoUrl = nil
					if computer.videoStartPosition_s then
						-- Start playing the video at the planned position:
						computer.videoStartedAt = RealTime() - computer.videoStartPosition_s -- pretend that the video was started at that time
						computer:SetVideoPosition_s(computer.videoStartPosition_s)
					end
				end
			end
		elseif action == a.SlideshowExit then
			if computer and on_seat and state == a.SlideshowRun then
				computer:SetState(a.SlideshowOpen)
				holdVideoUrl(computer)
			end
		elseif action == a.SlideshowOpen then
			if prop_teacher_computer_mr.lessonsList then
				local step = net.ReadUInt(8)
				if step == 1 then -- list of categories
					net.Start("prop_teacher_computer_mr")
						net.WriteUInt(a.SlideshowOpen, 8)
						net.WriteUInt(1, 8) -- list of categories
						local categories = {}
						for category, lessons in pairs(prop_teacher_computer_mr.lessonsList) do
							table.insert(categories, {category, #lessons})
						end
						net.WriteUInt(#categories, 8)
						for _, info in ipairs(categories) do
							net.WriteString(info[1])
							net.WriteUInt(info[2], 16)
						end
					net.Send(ply)
				elseif step == 2 then -- list of slideshows
					net.Start("prop_teacher_computer_mr")
						net.WriteUInt(a.SlideshowOpen, 8)
						net.WriteUInt(2, 8) -- list of slideshows
						local category = net.ReadString()
						net.WriteString(category)
						if prop_teacher_computer_mr.lessonsList[category] then
							net.WriteUInt(#prop_teacher_computer_mr.lessonsList[category], 16)
							for _, lesson in ipairs(prop_teacher_computer_mr.lessonsList[category]) do
								net.WriteString(tostring(lesson.title))
								net.WriteBool(prop_teacher_computer_mr.slideshowAllowed(lesson, ply, computer))
							end
						else
							net.WriteUInt(0, 16) -- empty list
						end
					net.Send(ply)
				elseif step == 3 then -- open selected slideshow
					if computer and on_seat then
						local category = net.ReadString()
						local title = net.ReadString()
						if prop_teacher_computer_mr.lessonsList[category] then
							for _, lesson in ipairs(prop_teacher_computer_mr.lessonsList[category]) do
								if lesson.title == title and prop_teacher_computer_mr.slideshowAllowed(lesson, ply, computer) then
									net.Start("prop_teacher_computer_mr")
										net.WriteUInt(a.SlideshowOpen, 8)
										net.WriteUInt(3, 8) -- acknowledge: opening slideshow
									net.Send(ply)
									if state == a.ProgramOpen or state == a.SlideshowOpen then
										computer:loadLesson(lesson)
									end
									break
								end
							end
						end
					end
				end
			end
		elseif action == a.SlideshowClose then
			if computer and on_seat and state == a.SlideshowOpen then
				computer:SetState(a.ProgramOpen)
				computer:unloadLesson()
			end
		elseif action == a.ProjectorOn then
			if computer then
				local projector = computer:GetProjector()
				if IsValid(projector) then
					projector:SetOn(true)
				end
			end
		elseif action == a.ProjectorOff then
			if computer then
				local projector = computer:GetProjector()
				if IsValid(projector) then
					projector:SetOn(false)
				end
			end
		end
	end
end)

function ENT:loadLesson(lesson)
	-- Load a lesson, usually loaded from the JSON slideshow list:
	-- The lesson must have been normalized with prop_teacher_computer_mr.fixLessonInfo().
	
	self.openedSlideshow = lesson
	self:SetPage(1)
	self:SetState(a.SlideshowOpen)
	self:SetSlideshowPages(#lesson.slides)
	local filename = lesson.filename or lesson.title
	if not filename then
		filename = (
			hl == "fr" and
			"Sans titre" or
			"Untitled"
		)
	end
	self:SetFilename(filename)
	self:SetPreviewUrl(lesson.preview)
end

function ENT:unloadLesson()
	-- Unload a lesson (if one is open), flushes all data:
	
	self.openedSlideshow = nil
	self:SetPreviousUrl("")
	self:SetCurrentUrl("")
	self:SetNextUrl("")
	self:SetPreviewUrl("")
	self:SetPage_(0)
	self:SetVideoPosition_s(0)
	self.pendingVideoUrl = nil
	self.videoStartedAt = nil
	self.videoStartPosition_s = nil
end

do
	-- Strip the remote control if the player is gone / unavailable:
	
	local function handlePlayerGone(ply)
		for computer in pairs(prop_teacher_computer_mr.getAllComputers()) do
			if computer:GetRemoteOwner() == ply then
				computer:stripRemote()
				-- Do not return in order to handle the should-never-happen case of multiple remotes.
			end
		end
	end
	hook.Add("PostPlayerDeath", "prop_teacher_computer_mr:sv", handlePlayerGone)
	hook.Add("PlayerDisconnected", "prop_teacher_computer_mr:sv", handlePlayerGone)
	hook.Add("OnPlayerChangedTeam", "prop_teacher_computer_mr:sv", handlePlayerGone)
	hook.Add("playerArrested", "prop_teacher_computer_mr:sv", handlePlayerGone) -- DarkRP
end

-- Handle some changes on lessons computers:
hook.Add("Think", "prop_teacher_computer_mr:sv", function()
	for computer in pairs(prop_teacher_computer_mr.getAllComputers()) do
		local state = computer:GetState()
		if state ~= computer.thinkState then -- a state change happened
			computer.thinkState = state -- hold last value
			if state ~= a.SlideshowRun then
				computer:stripRemote()
			end
			if state ~= a.SlideshowOpen and state ~= a.SlideshowRun then
				computer:unloadLesson()
			end
		end
		
		if computer.videoStartedAt then
			-- Refresh the video position for clients to be able to start watching at the current time:
			computer:SetVideoPosition_s(RealTime() - computer.videoStartedAt)
		end
		
		if computer:isComputerOn() then
			-- Put the computer into sleep mode after a timeout:
			if IsValid(computer:GetUser()) then
				computer.sleepTimeout = nil
			elseif not computer.sleepTimeout then
				computer.sleepTimeout = RealTime() + SleepTimeout_s
			elseif RealTime() > computer.sleepTimeout then
				computer:turnComputerOff()
			end
		end
	end
end)

do
	local youTubeUrlParameters = "disablekb=1&fs=0"
	-- https://developers.google.com/youtube/player_parameters?hl=en
	
	function prop_teacher_computer_mr.fixLessonInfo(lesson, lang_server, lang_others)
		-- Fix & normalize a lesson structure in-place
		-- And insert it into the proper language lessons list:
		-- This is used to normalize every slideshow in the JSON database.
		-- If you build a lesson structure, you should call this as well.
		-- After a 1st call, multiple calls are guaranteed to be neutral operations.
		-- lang_server & lang_others: (optional) lessons lists
		
		-- Whitelist (strip "whitelist" and setup "allowed"):
		if lesson.whitelist then
			lesson.allowed = {}
			for _, whiteListItem in ipairs(lesson.whitelist) do
				whiteListItem = tostring(whiteListItem)
				lesson.allowed[whiteListItem] = true
			end
			lesson.whitelist = nil -- cleanup
		end
		-- Transform single-URL slideshow (as string) into array slides list (to be homogeneous):
		if isstring(lesson.slides) then
			lesson.slides = {
				lesson.slides,
			}
		end
		-- Transform string slides into table slides (to be homogeneous):
		for i, slide in ipairs(lesson.slides) do
			if isstring(slide) then
				lesson.slides[i] = {
					url = slide,
				}
			end
		end
		-- Make slides by formatting the 1st slide URL when the "count" field is defined:
		local count = tonumber(lesson.count)
		if count ~= nil and count >= 1 then
			-- Warning: special characters (with '%') in URLs are unsupported here because they are recognized as string.format() items!
			local slides = {}
			for j, slide in ipairs(lesson.slides) do
				if j == 1 then
					-- only format the 1st URL of the list:
					for i = 1, count do
						slides[#slides + 1] = {
							url = string.format(slide.url, i)
							-- if future addition: other fields are not copied!
						}
					end
				else
					slides[#slides + 1] = slide
				end
			end
			lesson.slides = slides
		end
		lesson.count = nil -- safety for multiple calls
		-- Fix URLs:
		for i, slide in ipairs(lesson.slides) do
			local url = slide.url
			if prop_teacher_computer_mr.isYouTubeUrl(url) then
				do
					-- Convert the "start" URL parameter into the "starttime" field:
					local urlPieces = {string.match(url, "^(.+[&%?])start=([^&]*)&?(.*)$")}
					if #urlPieces ~= 0 then
						url = urlPieces[1] .. urlPieces[3]
						if not slide.starttime then
							slide.starttime = tonumber(urlPieces[2])
						end
					end
				end
				if string.find(url, youTubeUrlParameters, 1, true) then
					-- already appended
				elseif string.find(url, "?", 1, true) then
					url = url .. "&" .. youTubeUrlParameters
				else
					url = url .. "?" .. youTubeUrlParameters
				end
			end
			slide.url = url
		end
		-- Fix "starttime" fields:
		for i, slide in ipairs(lesson.slides) do
			slide.starttime = tonumber(slide.starttime)
			if slide.starttime and slide.starttime < 0 then
				slide.starttime = 0
			end
		end
		-- Add the "preview" field if missing (only works if 1st slide is a picture or a YouTube video):
		if not lesson.preview then
			local url = lesson.slides[1].url
			if prop_teacher_computer_mr.isYouTubeUrl(url) then
				local id = string.match(url, "^https?://[^/]+/embed/([^/?&]+)")
				lesson.preview = id and ("https://i.ytimg.com/vi/" .. id .. "/hqdefault.jpg") or "about:blank"
			else
				lesson.preview = url
			end
		end
		-- Language:
		if lang_others or lang_server then
			if lesson.hl and hl ~= lesson.hl then
				local languagePrefix = string.format("[%s] ", lesson.hl)
				if string.sub(lesson.title, 1, #languagePrefix) ~= languagePrefix then -- safety for multiple calls
					-- The title does not have the language prefix yet:
					lesson.title = languagePrefix .. lesson.title
				end
				if lang_others then
					table.insert(lang_others, 1, lesson)
				end
			else
				if lang_server then
					table.insert(lang_server, 1, lesson)
				end
			end
		end
		
		return lesson
	end
end

local luaDefinedLessons = {}
local luaDefinedLessonsNotLoaded = true
do
	-- Load Lua-defined lessons:
	-- timer.Simple() is used in place of pcall() to benefit from Lua refresh without causing breaking errors.
	
	function prop_teacher_computer_mr.registerLesson(category, lesson)
		-- Registers a lesson as if it was from the JSON lessons list:
		-- This is only defined while loading Lua-defined lessons.
		
		category = tostring(category)
		if category == "_language" then
			error('"_language" is not a valid category name!')
		end
		prop_teacher_computer_mr.fixLessonInfo(lesson)
		local register = hook.Run("prop_teacher_computer_mr:registerLuaLesson", lesson)
		if register == nil then
			register = true
		end
		prop_teacher_computer_mr.fixLessonInfo(lesson) -- because lesson can be altered by hooks
		if register then
			luaDefinedLessons[category] = luaDefinedLessons[category] or {}
			luaDefinedLessons[category][lesson] = true
		end
	end
	
	local baseFolder = "slideshows/prop_teacher_computer_mr/"
	local luaFiles = file.Find(baseFolder .. "*.lua", "lsv")
	for _, luaFile in ipairs(luaFiles or {}) do
		luaFile = baseFolder .. luaFile
		timer.Simple(0., function()
			include(luaFile)
		end)
	end
	
	timer.Simple(0., function()
		timer.Simple(0., function()
			prop_teacher_computer_mr.registerLesson = nil
			luaDefinedLessonsNotLoaded = nil
		end)
	end)
end

do
	-- Refresh lessons list:
	
	local function sendNotification(msg, isError)
		if isError then
			ErrorNoHalt(msg .. "\n")
		else
			MsgN(msg)
		end
		for _, ply in ipairs(player.GetAll()) do
			if ply:IsSuperAdmin() then
				ply:ChatPrint(msg)
			end
		end
	end
	
	local nextLessonsRefresh = 0.
	local function httpError(message)
		local now = RealTime()
		nextLessonsRefresh = now + LessonsListRefreshAfterError_s
		local msg = "[prop_teacher_computer_mr] Failed while reading lessons list: " .. tostring(message)
		sendNotification(msg, true)
	end
	
	local forceUpdate = true -- force update when Lua code is changed
	
	local httpLastModified
	local httpETag
	--local httpCookies = {}
	
	local function httpSuccess_(body, size, headers, code)
		-- Decode the received JSON list of slideshows:
		
		--[[
		if headers then
			for header, headerValue in pairs(headers) do
				header = string.lower(header)
				if header == "set-cookie" then
					-- TODO - httpCookies
				end
			end
		end
		]]
		if code == 304 then
			-- no change
		elseif code >= 200 and code <= 399 then
			local lessonsList = util.JSONToTable(body)
			if lessonsList then
				if forceUpdate or body ~= prop_teacher_computer_mr.lessonsListBody then
					-- Dealing with categories:
					local translatedCategories = {}
					for category, data in pairs(lessonsList) do
						-- Process special categories:
						if string.sub(category, 1, 1) == "_" then -- special
							if category == "_language" then
								if data["categories"] then
									-- Load category translations:
									for category, translations in pairs(data["categories"]) do
										translatedCategories[category] = translations[hl]
									end
								end
							end
						end
					end
					do
						-- Translate categories:
						local oldLessonsList = lessonsList
						lessonsList = {}
						for category, lessons in pairs(oldLessonsList) do
							if string.sub(category, 1, 1) ~= "_" then -- not special
								lessonsList[translatedCategories[category] or category] = lessons
							end
						end
					end
					do
						-- Insert Lua-defined lessons:
						-- The categories have already been translated!
						for category, lessons in pairs(luaDefinedLessons) do
							category = translatedCategories[category] or category
							lessonsList[category] = lessonsList[category] or {}
							for lesson in pairs(lessons) do
								table.insert(lessonsList[category], lesson)
							end
						end
					end
					
					-- Dealing with the slideshows:
					for category, lessons in pairs(lessonsList) do
						local lang_server = {} -- lessons using the server's language
						local lang_others = {} -- lessons using other languages
						-- Note: the table must contain fields expected by universityrp_mr_agenda (category & title)
						for i = #lessons, 1, -1 do
							local lesson = table.remove(lessons) -- empty table for language sorting
							-- Category:
							lesson.cat = category
							-- Process:
							local success, message = pcall(prop_teacher_computer_mr.fixLessonInfo, lesson, lang_server, lang_others)
							if not success then
								sendNotification(string.format(
									'[prop_teacher_computer_mr] Error in lesson: %s - "%s": %s',
									category,
									tostring(lesson.title),
									message
								))
							end
						end
						-- Language sorting:
						for _, lesson in ipairs(lang_server) do
							lessons[#lessons + 1] = lesson
						end
						for _, lesson in ipairs(lang_others) do
							lessons[#lessons + 1] = lesson
						end
					end
					-- PrintTable(lessonsList) -- debug
					prop_teacher_computer_mr.lessonsList = lessonsList
					prop_teacher_computer_mr.lessonsListBody = body
					forceUpdate = false
					if headers then
						httpLastModified = nil
						httpETag = nil
						for header, headerValue in pairs(headers) do
							header = string.lower(header)
							if header == "last-modified" then
								httpLastModified = headerValue
							elseif header == "etag" then
								httpETag = headerValue
							end
						end
					end
					sendNotification("[prop_teacher_computer_mr] The lessons list has changed!")
				end
			else
				httpError("Invalid JSON data!")
			end
		else
			-- HTTP error / unhandled status
			httpError("HTTP error " .. code)
		end
	end
	
	local function httpSuccess(body, size, headers, code)
		local success, message = pcall(httpSuccess_, body, size, headers, code)
		if not success then
			httpError(tostring(message))
		end
	end
	
	local lessonsListUrlKind
	if not isstring(LessonsListUrl) then
		lessonsListUrlKind = false
	elseif string.find(LessonsListUrl, "^https?://") then
		lessonsListUrlKind = "http"
	else
		lessonsListUrlKind = "file"
	end
	
	if lessonsListUrlKind then
		hook.Add("Think", "prop_teacher_computer_mr:lessons:sv", function()
			-- Refresh lessons list:
			
			if luaDefinedLessonsNotLoaded then
				-- Lua-defined lessons must be loaded to have luaDefinedLessons filled.
				return
			end
			local now = RealTime()
			if now > nextLessonsRefresh then
				nextLessonsRefresh = now + LessonsListRefresh_s
				if lessonsListUrlKind == "http" then
					local headers = {}
					if httpETag then
						headers["If-None-Match"] = httpETag
					end
					if httpLastModified then
						headers["If-Modified-Since"] = httpLastModified
					end
					http.Fetch(LessonsListUrl, httpSuccess, httpError, headers)
				else
					local f = file.Open(LessonsListUrl, "rb", "GAME")
					if f then
						local body = f:Read(f:Size())
						f:Close()
						httpSuccess(body, #body, nil, 200)
					else
						if file.Exists(LessonsListUrl, "GAME") then
							httpError("Unable to open the file!")
						else
							httpError("The file does not exist!")
						end
					end
				end
			end
		end)
	else
		hook.Remove("Think", "prop_teacher_computer_mr:lessons:sv")
		httpError("The URL is not configured!")
	end
end
