--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("prop_teacher_computer_mr:sh")

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.Category = "University RP"
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.PrintName = "Lessons computer"
ENT.Author = "Mohamed RACHID"
ENT.RenderGroup = RENDERGROUP_OPAQUE

prop_teacher_computer_mr = prop_teacher_computer_mr or {}

include("config/prop_teacher_computer_mr/shared.lua")

-- Configuration:
local UrlsSameorigin = prop_teacher_computer_mr.UrlsSameorigin or {
	["https://docs.google.com/"] = "https://docs.google.com/presentation/d/",
}
local UrlsVideo = prop_teacher_computer_mr.UrlsVideo or {
	["http://www.youtube-nocookie.com/embed/"] = true,
	["https://www.youtube-nocookie.com/embed/"] = true,
	["http://www.youtube.com/embed/"] = true,
	["https://www.youtube.com/embed/"] = true,
}
local UrlsYoutube = prop_teacher_computer_mr.UrlsYoutube or {
	["http://www.youtube-nocookie.com/embed/"] = true,
	["https://www.youtube-nocookie.com/embed/"] = true,
	["http://www.youtube.com/embed/"] = true,
	["https://www.youtube.com/embed/"] = true,
}
local ExtensionsPicture = prop_teacher_computer_mr.ExtensionsPicture or {
	[".png"] = true,
	[".jpg"] = true,
	[".jpeg"] = true,
	[".gif"] = true,
	[".svg"] = true,
	[".webp"] = true,
}
ENT.RemoteWeaponClass = prop_teacher_computer_mr.RemoteWeaponClass or "weapon_teacher_remote_mr"

function ENT:SetupDataTables()
	-- Networked accessors
	
	self:NetworkVar("Entity", 0, "Projector_") -- internal
	self:NetworkVar("Entity", 1, "RemoteOwner")
	self:NetworkVar("Entity", 2, "Seat")
	self:NetworkVar("Bool", 0, "ForTechnician")
	self:NetworkVar("String", 0, "PreviewUrl") -- contains the preview picture URL
	self:NetworkVar("String", 1, "PreviousUrl") -- empty if no preload available
	self:NetworkVar("String", 2, "CurrentUrl")
	self:NetworkVar("String", 3, "NextUrl") -- empty if no preload available
	self:NetworkVar("Int", 0, "State_") -- internal
	self:NetworkVar("Int", 1, "Page_") -- internal
	self:NetworkVar("Int", 2, "SlideshowPages") -- -1 if unknown
	self:NetworkVar("Int", 3, "VideoPosition_s") -- current video time, for YouTube start time
end

prop_teacher_computer_mr.actions = {
	-- computer control:
	ComputerSleep  = 0x00, -- STATE: off (must be 0 because default state)
	ComputerWake   = 0x01, -- STATE: desktop screen
	ProgramOpen    = 0x02, -- STATE: OpenOffice, welcome
	ProgramClose   = 0x03,
	-- projector screen control:
	ScreenOpen     = 0x11,
	ScreenClose    = 0x12,
	-- slideshow control:
	SlideNext      = 0x21,
	SlidePrevious  = 0x22,
	SlideSetPage   = 0x23,
	SlideshowRun   = 0x24, -- STATE: OpenOffice, fullscreen slideshow
	SlideshowExit  = 0x25,
	SlideshowOpen  = 0x26, -- STATE: OpenOffice, opened slideshow
	SlideshowClose = 0x27,
	-- projector control:
	ProjectorOn    = 0x31,
	ProjectorOff   = 0x32,
}
local a = prop_teacher_computer_mr.actions -- shortcut

local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "prop_teacher_computer_mr:sh")

function ENT:GetProjector()
	return self:GetProjector_()
end

if SERVER then
	function ENT:SetProjector(projector)
		if IsValid(projector) then
			self:makeRemoteProp()
		else
			self:removeRemoteProp()
		end
		self:SetProjector_(projector)
	end
end

function ENT:GetProjectorScreen()
	local projectorScreen
	local projector = self:GetProjector()
	if IsValid(projector) then
		projectorScreen = projector:GetProjectorScreen()
	end
	return projectorScreen
end

function ENT:GetFilename()
	return self:GetNWString("filename") or ""
end

if SERVER then
	function ENT:SetFilename(filename)
		self:SetNWString("filename", filename)
	end
end

function ENT:GetState()
	-- values should be with the 1st matching element of prop_teacher_computer_mr.actions
	return self:GetState_()
end

if SERVER then
	function ENT:SetState(state)
		self:SetState_(state)
		if state == a.ComputerSleep then
			self:SetSkin(1)
			self.sleepTimeout = nil
		else
			self:SetSkin(0)
		end
	end
end

function ENT:isComputerOn()
	return self:GetState() ~= a.ComputerSleep
end

function ENT:GetPage()
	-- 0 if invalid
	return self:GetPage_()
end

if SERVER then
	function ENT:SetPage(page)
		-- Update the page and set all fields (URL etc.) accordingly:
		
		local lesson = self.openedSlideshow
		if lesson and page > 0 then
			page = math.min(page, #lesson.slides)
			local previousSlide = lesson.slides[page - 1]
			local currentSlide = lesson.slides[page]
			local nextSlide = lesson.slides[page + 1]
			local previousUrl = previousSlide and previousSlide.url or ""
			local currentUrl = currentSlide and currentSlide.url or ""
			local nextUrl = nextSlide and nextSlide.url or ""
			if not prop_teacher_computer_mr.isVideoUrl(previousUrl) then
				self:SetPreviousUrl(previousUrl)
			else
				self:SetPreviousUrl("") -- no background playing for videos
			end
			self:SetCurrentUrl(currentUrl)
			if not prop_teacher_computer_mr.isVideoUrl(nextUrl) then
				self:SetNextUrl(nextUrl)
			else
				self:SetNextUrl("") -- no background playing for videos
			end
			self:SetPage_(page)
			if self:GetState() ~= a.SlideshowRun and prop_teacher_computer_mr.isVideoUrl(currentUrl) then
				self.pendingVideoUrl = currentUrl -- unload video if slideshow not running, but hold the value
				self:SetCurrentUrl("")
			else
				self.pendingVideoUrl = nil
				self:SetCurrentUrl(currentUrl)
			end
			if prop_teacher_computer_mr.isVideoUrl(currentUrl) then
				local videoStartPosition_s = currentSlide.starttime or 0
				if videoStartPosition_s >= 0 then
					self.videoStartPosition_s = videoStartPosition_s
					if self.pendingVideoUrl then -- video starting later
						self.videoStartedAt = nil
					else -- video starting now
						self.videoStartedAt = RealTime() - videoStartPosition_s
						self:SetVideoPosition_s(videoStartPosition_s)
					end
				else -- invalid (negative starttime)
					self.videoStartedAt = nil
					self.videoStartPosition_s = nil
				end
			else
				self:SetVideoPosition_s(0.)
				self.videoStartedAt = nil
				self.videoStartPosition_s = nil
			end
		end
	end
else
	function ENT:SetPage(page)
		-- The client variant is only here for prediction of the slide number.
		-- A check of self:GetState() is considered already done.
		
		if page > 0 then
			page = math.min(page, self:GetSlideshowPages())
			self:SetPage_(page)
		end
	end
end

function ENT:actionSlideSetPage(page)
	local state = self:GetState()
	if state == a.SlideshowOpen or state == a.SlideshowRun then
		self:SetPage(page)
	end
end

for method, increment in pairs({
	actionSlideNext = 1,
	actionSlidePrevious = -1,
}) do
	ENT[method] = function(self)
		self:actionSlideSetPage(self:GetPage() + increment)
	end
end

function prop_teacher_computer_mr.getSameOriginFixingUrl(url)
	-- Returns the substitution URL if the URL has a SAMEORIGIN X-Frame-Options rule, or false
	
	for base, substitute_url in pairs(UrlsSameorigin) do
		if string.sub(url, 1, #base) == base then -- compare the base URL
			return substitute_url -- return origin substitution URL
		end
	end
	return false -- no origin substitution required
end

function prop_teacher_computer_mr.isVideoUrl(url)
	-- Returns if the URL is a video
	
	for base in pairs(UrlsVideo) do
		if string.sub(url, 1, #base) == base then -- compare the base URL
			return true
		end
	end
	return false
end

function prop_teacher_computer_mr.isYouTubeUrl(url)
	-- Returns if the URL is from YouTube
	
	for base in pairs(UrlsYoutube) do
		if string.sub(url, 1, #base) == base then -- compare the base URL
			return true
		end
	end
	return false
end

function prop_teacher_computer_mr.isPictureUrl(url)
	-- Returns if the URL is a picture
	
	local isPicture = false
	do
		local extension = string.match(url, "(%.[a-zA-Z]+)$")
		if not extension then
			extension = string.match(url, "(%.[a-zA-Z]+)%?")
		end
		if extension then
			extension = string.lower(extension)
		end
		isPicture = ExtensionsPicture[extension] or false
	end
	if not isPicture then
		isPicture = string.find(url, "^https?://steamuserimages%-a%.akamaihd%.net/")
		isPicture = isPicture and true or false
	end
	return isPicture
end

function prop_teacher_computer_mr.getComputerFromSeat(seat, allComputers)
	-- Returns the seat belonging to the computer (or nil)
	-- allComputers: (optional) cached set of computer entities
	
	local computer
	
	if allComputers == nil then
		allComputers = prop_teacher_computer_mr.getAllComputers()
	end
	for computer_ in pairs(allComputers) do
		if computer_:GetSeat() == seat then
			computer = computer_
			break
		end
	end
	
	return computer
end

function prop_teacher_computer_mr.getComputerFromPlayer(ply, allComputers)
	-- Returns the computer (or nil) and if the player is seated on the computer's seat (or false)
	-- allComputers: (optional) cached set of computer entities
	
	local computer
	local on_computer_seat = false
	
	if allComputers == nil then
		allComputers = prop_teacher_computer_mr.getAllComputers()
	end
	local seat = ply:GetVehicle()
	if IsValid(seat) then
		local computer_ = prop_teacher_computer_mr.getComputerFromSeat(seat, allComputers)
		if computer_ then
			computer = computer_
			on_computer_seat = true
		end
	end
	if not computer then
		for computer_ in pairs(allComputers) do
			if computer_:GetRemoteOwner() == ply then
				computer = computer_
				on_computer_seat = false
				break
			end
		end
	end
	
	return computer, on_computer_seat
end

function prop_teacher_computer_mr.findStartableLesson(ply)
	-- Find a startable lesson for ply
	-- This is only for prop_teacher_computer_mr.
	
	local computer, on_seat = prop_teacher_computer_mr.getComputerFromPlayer(ply)
	if on_seat and IsValid(computer:GetProjector()) and IsValid(computer:GetProjector()) then
		local state = computer:GetState()
		if state == a.SlideshowOpen or state == a.SlideshowRun then
			if CLIENT then
				return {
					cat = (
						hl == "fr" and
						"Catégorie inconnue" or
						"Unknown category"),
					title = computer:GetFilename(),
					computer = computer,
				}
			else
				local lesson_to_copy = computer.openedSlideshow
				return {
					cat = lesson_to_copy.cat,
					title = lesson_to_copy.title,
					computer = computer,
				}
			end
		end
	end
end
hook.Add("findStartableLesson_mr", "prop_teacher_computer_mr:sh", prop_teacher_computer_mr.findStartableLesson)

local allComputers

do
	local weakKeys = {__mode = "k"}
	
	function prop_teacher_computer_mr.getAllComputers()
		-- Returns a set of all computers (not a copy):
		-- This is probably faster than calling ents.FindByClass().
		
		if not allComputers then
			allComputers = setmetatable({}, weakKeys)
			for _, computer in ipairs(ents.FindByClass("prop_teacher_computer_mr")) do
				if IsValid(computer) then -- because clientside errors after cleanup
					allComputers[computer] = true
				end
			end
		elseif CLIENT then
			-- Exclude computers that are not in PVS or just became invalid:
			local allComputerUpdated = setmetatable({}, weakKeys)
			for computer in pairs(allComputers) do
				if computer:IsValid() and computer:GetClass() == "prop_teacher_computer_mr" then
					allComputerUpdated[computer] = true
				end
			end
			allComputers = allComputerUpdated
		end
		return allComputers
	end
end

if SERVER then
	-- Internal usage only:
	function prop_teacher_computer_mr._markAsCreated(computer)
		allComputers[computer] = true
	end
	function prop_teacher_computer_mr._markAsDestroyed(computer)
		allComputers[computer] = nil
	end
	prop_teacher_computer_mr.getAllComputers() -- create allComputers
else
	hook.Add("Tick", "prop_teacher_computer_mr:sh:allComputers", function()
		-- Force refreshing allComputers with the current PVS:
		-- Warning: "NULL Entity" errors can happen if computers get invalid.
		-- The job is done too late in the Tick event.
		allComputers = nil
	end)
end
