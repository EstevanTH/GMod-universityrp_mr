--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("universityrp_mr_agenda:sv")

universityrp_mr_agenda = universityrp_mr_agenda or {}

AddCSLuaFile("config/universityrp_mr_agenda/shared.lua")

game.ConsoleCommand("sv_hibernate_think 1\n") -- refresh lessons list even when nobody connected

util.AddNetworkString("universityrp_mr_agenda")

local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "universityrp_mr_agenda:sv")

local function notify(ply, msgtype, len, msg)
	-- Wrapper for DarkRP.notify() compatible when the DarkRP is missing
	
	if DarkRP and DarkRP.notify then
		DarkRP.notify(ply, msgtype, len, msg)
	else
		ply:ChatPrint(msg)
	end
end

local nextAgendaRefresh = 0.

local function sendAgenda(recipients, automatic_event)
	universityrp_mr_agenda.cleanAgenda()
	net.Start("universityrp_mr_agenda")
		net.WriteUInt(#universityrp_mr_agenda.currentLessons, 8)
		for _, lesson in ipairs(universityrp_mr_agenda.currentLessons) do
			net.WriteString(lesson.cat)
			net.WriteString(lesson.title)
			net.WriteFloat(lesson.start)
			net.WriteFloat(lesson.finish)
			if rooms_lib_mr then
				net.WriteUInt(rooms_lib_mr.getIdFromBuilding(lesson.building), 8)
				net.WriteUInt(rooms_lib_mr.getIdFromRoom(lesson.room), 8)
			else
				net.WriteUInt(0, 8)
				net.WriteUInt(0, 8)
			end
			net.WriteEntity(lesson.teacher)
		end
		net.WriteBool(automatic_event) -- no notification sound
	if not recipients then
		net.Broadcast()
		nextAgendaRefresh = RealTime() + 20.
	else
		net.Send(recipients)
	end
end

function universityrp_mr_agenda.cancelLessonByPlayer(ply)
	local anyRemoved = false
	for i = #universityrp_mr_agenda.currentLessons, 1, -1 do
		if universityrp_mr_agenda.currentLessons[i].teacher == ply then
			table.remove(universityrp_mr_agenda.currentLessons, i)
			anyRemoved = true
		end
	end
	if anyRemoved then
		sendAgenda()
	end
end
hook.Add("PostPlayerDeath", "universityrp_mr_agenda:sv", universityrp_mr_agenda.cancelLessonByPlayer)
hook.Add("PlayerDisconnected", "universityrp_mr_agenda:sv", universityrp_mr_agenda.cancelLessonByPlayer)
hook.Add("OnPlayerChangedTeam", "universityrp_mr_agenda:sv", universityrp_mr_agenda.cancelLessonByPlayer)
hook.Add("playerArrested", "universityrp_mr_agenda:sv", universityrp_mr_agenda.cancelLessonByPlayer) -- DarkRP

hook.Add("Think", "universityrp_mr_agenda:sv", function()
	local now = CurTime()
	if rooms_lib_mr and universityrp_mr_agenda.TeacherGoneTimeOut_s then
		for i = #universityrp_mr_agenda.currentLessons, 1, -1 do
			local lesson = universityrp_mr_agenda.currentLessons[i]
			if IsValid(lesson.teacher) then
				local room, _, building = rooms_lib_mr.getRoom(lesson.teacher)
				if building ~= lesson.building or room ~= lesson.room then -- the teacher moved
					if not lesson.goneTimeOut then
						lesson.goneTimeOut = now + universityrp_mr_agenda.TeacherGoneTimeOut_s
					elseif now > lesson.goneTimeOut then
						universityrp_mr_agenda.cancelLessonByPlayer(lesson.teacher) -- remove the planned lesson when teacher leaves the room
					end
				else
					lesson.goneTimeOut = nil
				end
			else
				universityrp_mr_agenda.cancelLessonByPlayer(lesson.teacher) -- one more useless cleanup
			end
		end
	end
	
	local now = RealTime()
	if now > nextAgendaRefresh then
		sendAgenda(nil, true)
		nextAgendaRefresh = now + 20.
	end
end)

local function canAdminCancelLesson(ply)
	local canCancel = hook.Run("canUseLessonsCanceler_mr", ply)
	if canCancel == nil then
		canCancel = ply:IsAdmin()
	end
	return canCancel
end

function universityrp_mr_agenda.insertToAgenda(lesson, duration_min, ply, bypassCountLimit)
	-- Add a lesson to the agenda
	-- lesson: table with fields {cat="Category", title="Lesson title", computer=Entity(.....)}
		-- computer: optional entity used to locate the room (can be nil)
	-- duration_min: lesson duration in minutes
	-- ply: the teacher Player
	-- bypassCountLimit: true to bypass AgendaMax
	
	if (not bypassCountLimit) and #universityrp_mr_agenda.currentLessons >= universityrp_mr_agenda.AgendaMax then
		notify(
			ply, NOTIFY_ERROR, 5,
			(
				hl == "fr" and
				"Le planning est plein." or
				"The schedule is full.")
		)
	else
		local duration_s = 60. * math.Clamp(duration_min, universityrp_mr_agenda.AgendaMinDuration_min, universityrp_mr_agenda.AgendaMaxDuration_min)
		
		-- Find the slot in which to add the lesson:
		local k -- at which index to add the lesson
		local start = CurTime() + universityrp_mr_agenda.AgendaPrepareTime_s
		if #universityrp_mr_agenda.currentLessons ~= 0 then
			-- Here, lessons MUST be ordered properly.
			if not universityrp_mr_agenda.AgendaAllowConflict then
				for i = 1, #universityrp_mr_agenda.currentLessons do
					local lesson_ = universityrp_mr_agenda.currentLessons[i]
					if lesson_.start >= start + duration_s + universityrp_mr_agenda.AgendaPrepareTime_s then -- lesson [i] begins after end of added lesson
						k = i
						break
					end
					-- for next iteration:
					start = lesson_.finish + universityrp_mr_agenda.AgendaPrepareTime_s
				end
			end
		end
		
		local plannedLesson = {}
		plannedLesson.cat = lesson.cat
		plannedLesson.title = lesson.title
		plannedLesson.start = start
		plannedLesson.finish = plannedLesson.start + duration_s
		local room, _, building
		if rooms_lib_mr then
			if lesson.room or lesson.building then
				-- Global agenda:
				room = lesson.room
				building = lesson.building
			else
				-- No agenda or Room's agenda:
				room, _, building = rooms_lib_mr.getRoom(IsValid(lesson.computer) and lesson.computer or ply)
			end
		end
		plannedLesson.building = building
		plannedLesson.room = room
		plannedLesson.teacher = ply
		plannedLesson.computer = lesson.computer
		if not k then
			table.insert(universityrp_mr_agenda.currentLessons, plannedLesson) -- added at the end of the list
		else
			table.insert(universityrp_mr_agenda.currentLessons, k, plannedLesson) -- added before the end of the list
		end
		sendAgenda()
	end
end

net.Receive("universityrp_mr_agenda", function(len, ply)
	universityrp_mr_agenda.cleanAgenda()
	if IsValid(ply) then
		if net.ReadBool() then
			local duration_min = net.ReadUInt(8)
			if duration_min == 0 then -- cancel lesson
				universityrp_mr_agenda.cancelLessonByPlayer(ply)
			elseif duration_min == 255 then -- admin cancel lesson
				if canAdminCancelLesson(ply) then
					local teacher = net.ReadEntity()
					universityrp_mr_agenda.cancelLessonByPlayer(teacher)
				end
			else -- start lesson
				local agenda_prop = net.ReadInt(16)
				local lesson
				if agenda_prop == 0 then
					-- Request from a computer or from a room's implicit lesson:
					lesson = universityrp_mr_agenda.canStartLesson(ply)
				else
					-- Request from an agenda entity:
					agenda_prop = Entity(agenda_prop)
					if not universityrp_mr_agenda.is_agenda_prop(agenda_prop)
					or ply:EyePos():DistToSqr(agenda_prop:WorldSpaceCenter()) > agenda_prop.use_distance_in2 * 2. then -- mult by 2 for extra tolerance
						agenda_prop = nil
					else
						if agenda_prop.room_agenda then
							-- Request from a Room's agenda:
							lesson = {
								computer = agenda_prop,
							}
						else
							-- Request from a Global agenda:
							lesson = {}
							if rooms_lib_mr then
								local room_suitable = false
								lesson.room = rooms_lib_mr.getRoomFromId(net.ReadUInt(8))
								if lesson.room then
									room_suitable = hook.Run("universityrp_mr_agenda:isRoomSuitable", lesson.room, ply)
									if room_suitable == nil then
										room_suitable = true
									end
								end
								if room_suitable then
									lesson.building = lesson.room:getBuilding()
								else
									-- The location is invalid:
									lesson = nil
								end
							else
								net.ReadUInt(8)
							end
						end
						if lesson then
							lesson.cat = net.ReadString()
							lesson.title = net.ReadString()
							if not lesson.cat or #lesson.cat == 0 or not lesson.title or #lesson.title == 0 then
								lesson = nil
							else
								-- Truncate the texts:
								lesson.cat = utf8.sub(lesson.cat, 1, 63)
								lesson.title = utf8.sub(lesson.title, 1, 127)
							end
						end
						if lesson then
							if not universityrp_mr_agenda.canStartThisLesson(ply, lesson) then
								lesson = nil
							end
						end
					end
				end
				if lesson then
					universityrp_mr_agenda.insertToAgenda(lesson, duration_min, ply, false)
				elseif agenda_prop == nil then
					-- Received an agenda entity but incorrect:
					notify(
						ply, NOTIFY_ERROR, 5,
						hl == "fr" and
						"Vous être trop éloigné de l'agenda." or
						"You are too far away from the agenda."
					)
				else
					notify(
						ply, NOTIFY_ERROR, 5,
						hl == "fr" and
						"Vous ne pouvez pas dispenser ce cours." or
						"You cannot teach this lesson."
					)
				end
			end
		else
			sendAgenda(ply, true)
		end
	end
end)

hook.Add("PlayerSay", "universityrp_mr_agenda:sv", function(sender, text, teamChat)
	if text == "!lessons" then
		if canAdminCancelLesson(sender) then
			sender:SendLua('universityrp_mr_agenda.lessonsCanceler()')
		else
			sender:ChatPrint(
				hl == "fr" and
				"Vous n'êtes pas autorisé à utiliser cette commande." or
				"You are not allowed to use this command."
			)
		end
		return ""
	end
end)
