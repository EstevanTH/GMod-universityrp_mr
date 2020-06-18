--- SHARED ---

-- How many items the agenda can contain:
universityrp_mr_agenda.AgendaMax = 3

-- Allow overlapping agenda items:
universityrp_mr_agenda.AgendaAllowConflict = false

-- How much waiting time before a lesson begins / between lessons:
universityrp_mr_agenda.AgendaPrepareTime_s = 120.

-- Minimum lesson duration:
universityrp_mr_agenda.AgendaMinDuration_min = 5

-- Maximum lesson duration:
universityrp_mr_agenda.AgendaMaxDuration_min = 20

-- Delay before canceling a lesson when a teacher is not in the room of their planned lesson:
-- The value can be a number or nil.
universityrp_mr_agenda.TeacherGoneTimeOut_s = 60.

universityrp_mr_agenda.delayedConfiguration = function()
	
	-- Table containing rooms that have an implicit lesson name (a sports room for instance):
	-- The building name & the room name are configured in "lua/config/rooms_lib_mr/maps/".
	universityrp_mr_agenda.RoomsImplicitLesson = {
		--[[
		-- Examples in English:
		[rooms_lib_mr.getFullRoomLabel("Building name", "Room name")] = {
			{cat="Category name", title="Lesson name"},
			<teams table (optional)>
		},
		[rooms_lib_mr.getFullRoomLabel("Building name", "Room name")] = {
			{cat="Category name", title="Lesson name"},
			nil
		},
		[rooms_lib_mr.getFullRoomLabel("Building name", "Room name")] = {
			{cat="Category name", title="Lesson name"},
			{
				[TEAM_UNIVERSITY_DIRECTOR] = true,
				[TEAM_UNIVERSITY_TEACHER_SPORT] = true,
			}
		},
		]]
		--[[
		-- Exemples en français :
		[rooms_lib_mr.getFullRoomLabel("Nom bâtiment", "Nom salle")] = {
			{cat="Intitulé catégorie", title="Intitulé cours"},
			<tableau d'équipes (optionnel)>
		},
		[rooms_lib_mr.getFullRoomLabel("Nom bâtiment", "Nom salle")] = {
			{cat="Intitulé catégorie", title="Intitulé cours"},
			nil
		},
		[rooms_lib_mr.getFullRoomLabel("Nom bâtiment", "Nom salle")] = {
			{cat="Intitulé catégorie", title="Intitulé cours"},
			{
				[TEAM_UNIVERSITY_DIRECTOR] = true,
				[TEAM_UNIVERSITY_TEACHER_SPORT] = true,
			}
		},
		]]
	}
	
end
