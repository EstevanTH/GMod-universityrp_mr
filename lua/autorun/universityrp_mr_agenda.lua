--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("universityrp_mr_agenda:sh")

universityrp_mr_agenda = universityrp_mr_agenda or {}

include("config/universityrp_mr_agenda/shared.lua")

-- Configuration:
universityrp_mr_agenda.AgendaMax = universityrp_mr_agenda.AgendaMax or 3
universityrp_mr_agenda.AgendaAllowConflict = universityrp_mr_agenda.AgendaAllowConflict or false
universityrp_mr_agenda.AgendaPrepareTime_s = universityrp_mr_agenda.AgendaPrepareTime_s or 120.
universityrp_mr_agenda.AgendaMinDuration_min = universityrp_mr_agenda.AgendaMinDuration_min or 5
universityrp_mr_agenda.AgendaMaxDuration_min = universityrp_mr_agenda.AgendaMaxDuration_min or 20
universityrp_mr_agenda.TeacherGoneTimeOut_s = universityrp_mr_agenda.TeacherGoneTimeOut_s or 60. -- can be nil
universityrp_mr_agenda.RoomsImplicitLesson = universityrp_mr_agenda.RoomsImplicitLesson or {}

local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "universityrp_mr_agenda:sh")

do
	local function delayedConfiguration()
		-- Avoid erroring when teams do not exist (wrong gamemode etc.):
		if universityrp_mr_agenda.delayedConfiguration then
			local success, message = pcall(universityrp_mr_agenda.delayedConfiguration)
			if not success then
				universityrp_mr_agenda.RoomsImplicitLesson = universityrp_mr_agenda.RoomsImplicitLesson or {}
				ErrorNoHalt(message .. "\n")
			end
		end
	end
	local hooks = hook.GetTable()["PostGamemodeLoaded"]
	if hooks["universityrp_mr_agenda:sh"] then
		-- only execute on Lua refresh:
		delayedConfiguration()
	end
	hook.Add("PostGamemodeLoaded", "universityrp_mr_agenda:sh", delayedConfiguration)
end

universityrp_mr_agenda.currentLessons = universityrp_mr_agenda.currentLessons or {} -- the table is erased clientside on updates!

function universityrp_mr_agenda.getScheduled(ply)
	-- Returns the lesson scheduled by the player, or nil
	
	for _, lesson in ipairs(universityrp_mr_agenda.currentLessons) do
		if lesson.teacher == ply then
			return lesson
		end
	end
	return nil
end

function universityrp_mr_agenda.playerIsTeacher(ply)
	local isTeacher = false
	local jobTable
	if IsValid(ply) then
		if RPExtraTeams then
			jobTable = RPExtraTeams[ply:Team()]
		else
			-- not DarkRP, fallback:
			isTeacher = true
		end
	end
	if jobTable and jobTable.teacher then
		isTeacher = true
	end
	return isTeacher
end

function universityrp_mr_agenda.canStartThisLesson(ply, lesson)
	-- Determine if ply can start the specified lesson
	-- Returns true / false
	
	if not lesson then
		return false
	end
	local canSchedule = hook.Run("canScheduleLesson_mr", ply, lesson)
	if canSchedule == nil then
		canSchedule = universityrp_mr_agenda.playerIsTeacher(ply)
	end
	return canSchedule
end

local eventsFindStartableLesson = {"findStartableLesson_mr", "findStartableImplicitLesson_mr"}
function universityrp_mr_agenda.canStartLesson(ply)
	-- If can start a lesson, returns {cat="Category name", title="Lesson name", computer=Entity(.....)}
	-- If cannot start a lesson, returns false
	-- The computer field is only filled if a computer matched.
	
	if not IsValid(ply) then
		return false
	end
	
	if not universityrp_mr_agenda.getScheduled(ply) then
		local lesson
		for i = 1, #eventsFindStartableLesson do
			lesson = hook.Run(eventsFindStartableLesson[i], ply)
			if lesson then
				local canSchedule = universityrp_mr_agenda.canStartThisLesson(ply, lesson)
				if not canSchedule then
					lesson = nil
				end
			end
			if lesson then
				break
			end
		end
		if lesson then
			return lesson
		end
	end
	return false
end

function universityrp_mr_agenda.cleanAgenda()
	-- Removes agenda items that should not exist anymore
	
	local result = false
	for i = #universityrp_mr_agenda.currentLessons, 1, -1 do
		local lesson = universityrp_mr_agenda.currentLessons[i]
		if CurTime() > lesson.finish or not universityrp_mr_agenda.playerIsTeacher(lesson.teacher) then
			table.remove(universityrp_mr_agenda.currentLessons, i)
			result = true
		end
	end
	return result
end

hook.Add("findStartableImplicitLesson_mr", "universityrp_mr_agenda:roomImplicitLesson:sh", function(ply)
	-- Find an implicit startable lesson for ply in their current room:
	
	if rooms_lib_mr then
		local _, room_name, _, building_name = rooms_lib_mr.getRoom(ply)
		if building_name and room_name then
			local info = universityrp_mr_agenda.RoomsImplicitLesson[rooms_lib_mr.getFullRoomLabel(building_name, room_name)]
			if info and (not info[2] or info[2][Team]) then
				local lesson_to_copy = info[1]
				return {
					cat = lesson_to_copy.cat,
					title = lesson_to_copy.title,
				}
			end
		end
	end
end)
