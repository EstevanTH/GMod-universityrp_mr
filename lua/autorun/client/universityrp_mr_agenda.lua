--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("universityrp_mr_agenda:cl")

universityrp_mr_agenda = universityrp_mr_agenda or {}

local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "universityrp_mr_agenda:sv")

local text_teach_this_lesson = (
	hl == "fr" and
	"Enseigner ce cours" or
	"Teach this lesson"
)
local text_teach_a_lesson_here = (
	hl == "fr" and
	"Enseigner un cours ici" or
	"Teach a lesson here"
)
local text_teach_a_lesson = (
	hl == "fr" and
	"Enseigner un cours" or
	"Teach a lesson"
)

function universityrp_mr_agenda.showStartLessonConfirm(agenda_prop)
	-- agenda_prop: agenda entity (only if used)
	
	if IsValid(universityrp_mr_agenda.startLessonConfirm) then
		universityrp_mr_agenda.startLessonConfirm:Remove()
	end
	local ply = LocalPlayer()
	local lesson
	if agenda_prop then
		if not universityrp_mr_agenda.is_agenda_prop(agenda_prop) then
			-- Specified an invalid agenda entity:
			return
		end
	else
		lesson = universityrp_mr_agenda.canStartLesson(ply) -- refreshed
	end
	if agenda_prop or lesson then
		universityrp_mr_agenda.startLessonConfirm = vgui.Create("DFrame"); do
			local startLessonConfirm = universityrp_mr_agenda.startLessonConfirm
			startLessonConfirm:MakePopup()
			local text
			if agenda_prop then
				if agenda_prop.room_agenda then
					text = text_teach_a_lesson_here
				else
					text = text_teach_a_lesson
				end
			elseif IsValid(lesson.computer) then
				text = text_teach_this_lesson
			else
				text = text_teach_a_lesson_here
			end
			if lesson then
				-- Case with no text fields, so keyboard input can be disabled:
				startLessonConfirm:SetKeyboardInputEnabled(false)
			end
			startLessonConfirm:SetTitle(text)
			local w = 300 - 8 - 8
			local x, y = 8, 30
			local isOkayCategory = true
			local isOkayTitle = true
			local categoryField
			local titleField
			if agenda_prop then
				isOkayCategory = false
				isOkayTitle = false
				categoryField = vgui.Create("DTextEntry", startLessonConfirm); do
					categoryField:SetPos(x, y)
					categoryField:SetWide(w)
					categoryField:SetPlaceholderText(
						hl == "fr" and
						"Matière / Catégorie" or
						"Subject / Category"
					)
					categoryField.OnLoseFocus = function(self)
						self:SetText(utf8.sub(self:GetText(), 1, 63))
					end
					categoryField.OnChange = function(self)
						isOkayCategory = (#self:GetText() ~= 0)
					end
					y = y + categoryField:GetTall() + 8
				end
				titleField = vgui.Create("DTextEntry", startLessonConfirm); do
					titleField:SetPos(x, y)
					titleField:SetWide(w)
					titleField:SetPlaceholderText(
						hl == "fr" and
						"Titre" or
						"Title"
					)
					titleField.OnLoseFocus = function(self)
						self:SetText(utf8.sub(self:GetText(), 1, 127))
					end
					titleField.OnChange = function(self)
						isOkayTitle = (#self:GetText() ~= 0)
					end
					y = y + titleField:GetTall() + 8
				end
			else
				titleField = vgui.Create("DLabel", startLessonConfirm); do
					titleField:SetPos(x, y)
					titleField:SetText(lesson.title)
					titleField:SizeToContents()
					y = y + titleField:GetTall() + 8
				end
			end
			local delayLabel = vgui.Create("DLabel", startLessonConfirm); do
				delayLabel:SetPos(x, y)
				delayLabel:SetText(string.format(
					hl == "fr" and
					"Début dans %u secondes" .. (universityrp_mr_agenda.AgendaAllowConflict and "" or " après 1er créneau disponible") or
					"Begins in %u seconds" .. (universityrp_mr_agenda.AgendaAllowConflict and "" or " after the 1st available time slot"), universityrp_mr_agenda.AgendaPrepareTime_s
				))
				delayLabel:SizeToContents()
				y = y + delayLabel:GetTall() + 8
			end
			local confirmButton
			local isOkayDuration = false
			local selectedDuration_min
			local durationSelector = vgui.Create("DNumSlider", startLessonConfirm); do
				durationSelector:SetPos(x, y)
				durationSelector:SetSize(w, 20)
				durationSelector:SetText(
					hl == "fr" and
					"Durée (minutes) :" or
					"Duration (minutes):"
				)
				durationSelector:SetMin(universityrp_mr_agenda.AgendaMinDuration_min)
				durationSelector:SetMax(universityrp_mr_agenda.AgendaMaxDuration_min)
				durationSelector:SetDecimals(0)
				durationSelector:SetValue(0)
				durationSelector.OnValueChanged = function(self, selectedDuration_)
					selectedDuration_min = math.Round(selectedDuration_)
					isOkayDuration = (
						selectedDuration_min >= universityrp_mr_agenda.AgendaMinDuration_min or
						selectedDuration_min <= universityrp_mr_agenda.AgendaMaxDuration_min
					)
				end
				y = y + durationSelector:GetTall() + 8
			end
			local isOkayLocation = true
			local locationLabel
			if agenda_prop and not agenda_prop.room_agenda then
				-- Global agenda:
				locationLabel = vgui.Create("DComboBox", startLessonConfirm); do
					locationLabel:SetPos(x, y)
					locationLabel:SetSortItems(false)
					locationLabel:AddChoice(
						(
							hl == "fr" and
							"Sélectionne une salle :" or
							"Select a room:"
						),
						nil, -- data
						true -- selected
					)
					if rooms_lib_mr then
						isOkayLocation = false
						for id, room in ipairs(rooms_lib_mr.getRooms()) do
							local room_suitable = hook.Run("universityrp_mr_agenda:isRoomSuitable", room, ply)
							if room_suitable == nil then
								room_suitable = true
							end
							if room_suitable then
								locationLabel:AddChoice(
									rooms_lib_mr.getFullRoomLabel(
										room:getBuildingName(),
										room:getName()
									),
									id
								)
							end
						end
					end
					locationLabel:SetWide(w)
					locationLabel.OnSelect = function(self, _, _, id)
						if rooms_lib_mr then
							isOkayLocation = (id ~= nil and id > 0)
						end
					end
					y = y + locationLabel:GetTall() + 8
				end
			else
				-- No agenda or Room's agenda:
				locationLabel = vgui.Create("DLabel", startLessonConfirm); do
					locationLabel:SetPos(x, y)
					if rooms_lib_mr then
						local _, room_name, _, building_name = rooms_lib_mr.getRoom(
							(lesson and IsValid(lesson.computer) and lesson.computer) or
							agenda_prop or
							ply
						)
						locationLabel:SetText(rooms_lib_mr.getFullRoomLabel(building_name, room_name))
					end
					locationLabel:SizeToContents()
					y = y + locationLabel:GetTall() + 8
				end
			end
			local teacherLabel = vgui.Create("DLabel", startLessonConfirm); do
				teacherLabel:SetPos(x, y)
				teacherLabel:SetText(ply:Nick())
				teacherLabel:SizeToContents()
				y = y + teacherLabel:GetTall() + 8
			end
			confirmButton = vgui.Create("DButton", startLessonConfirm); do
				confirmButton:SetPos(x, y)
				confirmButton:SetSize(w, 20)
				confirmButton:SetText(
					hl == "fr" and
					"Planifier le cours" or
					"Schedule the lesson"
				)
				confirmButton.DoClick = function(self)
					net.Start("universityrp_mr_agenda")
						net.WriteBool(true)
						net.WriteUInt(selectedDuration_min, 8)
						if agenda_prop then
							-- Agenda entity used:
							net.WriteUInt(agenda_prop:EntIndex(), 16)
							if not agenda_prop.room_agenda then
								net.WriteUInt(({locationLabel:GetSelected()})[2], 8) -- room id
							end
							net.WriteString(utf8.sub(categoryField:GetText(), 1, 63))
							net.WriteString(utf8.sub(titleField:GetText(), 1, 127))
						else
							-- No agenda entity:
							net.WriteUInt(0, 16)
						end
					net.SendToServer()
					startLessonConfirm:Remove()
				end
				confirmButton.Think = function(self)
					confirmButton:SetEnabled(
						isOkayCategory and
						isOkayTitle and
						isOkayDuration and
						isOkayLocation
					)
				end
				y = y + confirmButton:GetTall() + 8
			end
			startLessonConfirm:SetSize(8 + w + 8, y)
			startLessonConfirm:Center()
		end
	end
end

hook.Add("Tick", "universityrp_mr_agenda:cl", function()
	universityrp_mr_agenda.cleanAgenda()
	local ply = LocalPlayer()
	local hasScheduled = universityrp_mr_agenda.getScheduled(ply)
	
	-- Destroy the stopLessonButton button when needed:
	if not hasScheduled then
		if IsValid(universityrp_mr_agenda.stopLessonButton) then
			universityrp_mr_agenda.stopLessonButton:Remove()
			universityrp_mr_agenda.stopLessonButton = nil
		end
	end
	
	local lesson = universityrp_mr_agenda.canStartLesson(ply)
	if lesson then
		-- Create the startLessonButton when appropriate:
		if not IsValid(universityrp_mr_agenda.startLessonButton) then
			universityrp_mr_agenda.startLessonButton = vgui.Create("DButton"); do
				local startLessonButton = universityrp_mr_agenda.startLessonButton
				startLessonButton:SetPos(ScrW() - 377, 1)
				startLessonButton:SetSize(267, 20)
				local text
				if IsValid(lesson.computer) then
					text = text_teach_this_lesson
				else
					text = text_teach_a_lesson_here
				end
				startLessonButton:SetText(text)
				startLessonButton.DoClick = function(self)
					universityrp_mr_agenda.showStartLessonConfirm()
				end
			end
		end
		
		-- Disable startLessonButton if agenda is full:
		universityrp_mr_agenda.startLessonButton:SetDisabled(#universityrp_mr_agenda.currentLessons >= universityrp_mr_agenda.AgendaMax)
	else
		-- Destroy the startLessonButton button when needed:
		if IsValid(universityrp_mr_agenda.startLessonButton) then
			universityrp_mr_agenda.startLessonButton:Remove()
			universityrp_mr_agenda.startLessonButton = nil
		end
	end
	
	-- Create the stopLessonButton when appropriate:
	if hasScheduled and not IsValid(universityrp_mr_agenda.stopLessonButton) then
		universityrp_mr_agenda.stopLessonButton = vgui.Create("DButton"); do
			local stopLessonButton = universityrp_mr_agenda.stopLessonButton
			stopLessonButton:SetPos(ScrW() - 377, 1)
			stopLessonButton:SetSize(267, 20)
			local text = (
				hl == "fr" and
				"Annuler votre cours" or
				"Cancel your lesson"
			)
			stopLessonButton:SetText(text)
			stopLessonButton.DoClick = function(self)
				Derma_Query(
					(
						hl == "fr" and
						"Êtes-vous sûr de vouloir annuler votre cours ?" or
						"Are you sure you want to cancel your lesson?"),
					text,
					(
						hl == "fr" and
						"Oui" or
						"Yes"),
					function()
						net.Start("universityrp_mr_agenda")
							net.WriteBool(true)
							net.WriteUInt(0, 8)
						net.SendToServer()
					end,
					(
						hl == "fr" and
						"Annuler" or
						"Cancel"),
					nil
				)
			end
		end
	end
end)

-- Lua live-refresh:
if IsValid(universityrp_mr_agenda.startLessonButton) then
	universityrp_mr_agenda.startLessonButton:Remove()
	universityrp_mr_agenda.startLessonButton = nil
end
if IsValid(universityrp_mr_agenda.stopLessonButton) then
	universityrp_mr_agenda.stopLessonButton:Remove()
	universityrp_mr_agenda.stopLessonButton = nil
end

net.Receive("universityrp_mr_agenda", function()
	-- refresh the lessons list:
	universityrp_mr_agenda.currentLessons = {}
	local count = net.ReadUInt(8)
	for i = 1, count do
		local plannedLesson = {}
		plannedLesson.cat = net.ReadString()
		plannedLesson.title = net.ReadString()
		plannedLesson.start = net.ReadFloat()
		plannedLesson.finish = net.ReadFloat()
		if rooms_lib_mr then
			plannedLesson.building = rooms_lib_mr.getBuildingFromId(net.ReadUInt(8))
			plannedLesson.room = rooms_lib_mr.getRoomFromId(net.ReadUInt(8))
		else
			net.ReadUInt(8)
			net.ReadUInt(8)
		end
		plannedLesson.teacher = net.ReadEntity()
		universityrp_mr_agenda.currentLessons[i] = plannedLesson
	end
	if not net.ReadBool() then
		-- newly planned / cancelled lesson:
		surface.PlaySound("garrysmod/content_downloaded.wav")
	end
end)

local function format_time(time)
	return string.format("%02u:%02u", math.floor(time / 60), math.floor(time % 60))
end

do
	local bg_early = Color(0, 96, 48, 192)
	local bg_begun = Color(96, 48, 48, 192)
	local col_cat = Color(255, 255, 0, 255)
	local col_title = Color(255, 255, 0, 255)
	local col_timer = Color(192, 192, 192, 255)
	local col_duration = Color(192, 192, 192, 255)
	local col_place = Color(255, 255, 255, 255)
	local col_teacher = Color(255, 255, 255, 255)
	local col_outofroom = Color(255, 0, 0, 255)
	
	local gone_time_out
	
	hook.Add("HUDPaint", "universityrp_mr_agenda:cl", function()
		-- Display planned lessons:
		local x_base, y_base = ScrW() - 377, 22
		local x, y
		local now = CurTime() -- must be a time value synchronized with server
		for i, lesson in ipairs(universityrp_mr_agenda.currentLessons) do
			local shouldSee = (now < lesson.finish and IsValid(lesson.teacher))
			if shouldSee then
				shouldSee = hook.Run("universityrp_mr_agenda:shouldSeeLesson", lesson)
				if shouldSee == nil then
					shouldSee = true
				end
			end
			if shouldSee then
				if now > lesson.start then
					draw.RoundedBox(4, x_base, y_base, 267, 54, bg_begun)
				else
					draw.RoundedBox(4, x_base, y_base, 267, 54, bg_early)
				end
				x = x_base + 3; y = y_base
				draw.SimpleText(lesson.cat, "CenterPrintText", x, y, col_cat)
				x = x_base + 3; y = y_base + 16
				draw.SimpleText(lesson.title, "Default", x, y, col_title)
				x = x_base + 3; y = y_base + 28
				if now < lesson.start then
					draw.SimpleText(
						string.format(
							(
								hl == "fr" and
								"Début dans %s" or
								"Beginning in %s"),
							format_time(lesson.start - now)
						),
						"Default", x, y, col_timer
					)
				else
					draw.SimpleText(
						string.format(
							(
								hl == "fr" and
								"Fin dans %s" or
								"End in %s"),
							format_time(lesson.finish - now)),
						"Default", x, y, col_timer
					)
				end
				x = x_base + 3; y = y_base + 40
				draw.SimpleText(
					string.format(
						(
							hl == "fr" and
							"Durée : %.0f minutes" or
							"Duration: %.0f minutes"),
						(lesson.finish - lesson.start) / 60
					),
					"Default", x, y, col_duration
				)
				x = x_base + 120; y = y_base + 28
				if rooms_lib_mr then
					draw.SimpleText(
						rooms_lib_mr.getFullRoomLabel(
							rooms_lib_mr.getNameFromBuilding(lesson.building),
							rooms_lib_mr.getNameFromRoom(lesson.room)
						), "Default", x, y, col_place
					)
				end
				x = x_base + 120; y = y_base + 40
				draw.SimpleText(lesson.teacher:Nick(), "Default", x, y, col_teacher)
				y_base = y_base + 55
			end
		end
		
		-- Display warning if teacher is out of the planned lesson's room:
		if rooms_lib_mr and universityrp_mr_agenda.TeacherGoneTimeOut_s then
			local lesson = universityrp_mr_agenda.getScheduled(ply)
			if lesson then
				local room, _, building = rooms_lib_mr.getRoom(lesson.teacher)
				if building ~= lesson.building or room ~= lesson.room then -- the teacher moved
					if not gone_time_out then
						gone_time_out = now + universityrp_mr_agenda.TeacherGoneTimeOut_s
					end
					draw.SimpleText(
						string.format(
							(
								hl == "fr" and
								"Veuillez rejoindre %s avant %u secondes !" or
								"Please go back to %s within %u seconds!"),
							rooms_lib_mr.getFullRoomLabel(
								rooms_lib_mr.getNameFromBuilding(lesson.building),
								rooms_lib_mr.getNameFromRoom(lesson.room)
							),
							math.max(math.floor(gone_time_out - now), 0)
						),
						"ChatFont", 10, 128, col_outofroom
					)
				else
					gone_time_out = nil
				end
			else
				gone_time_out = nil
			end
		end
	end)
end

do
	-- Lessons canceler:
	
	local function make_list()
		local lessonsCancelerBox = universityrp_mr_agenda.lessonsCancelerBox
		lessonsCancelerBox.elements = {}
		local x_base, y_base = 0, 4
		local x, y
		local now = CurTime()
		for i, lesson in ipairs(universityrp_mr_agenda.currentLessons) do
			if now < lesson.finish and IsValid(lesson.teacher) then
				x = x_base + 4; y = y_base
				local label_cat = vgui.Create("DLabel", lessonsCancelerBox.container)
					label_cat:SetText(lesson.cat)
					label_cat:SetPos(x, y)
					label_cat:SizeToContents()
					table.insert(lessonsCancelerBox.elements, label_cat)
				x = x_base + 4; y = y_base + 16
				local label_title = vgui.Create("DLabel", lessonsCancelerBox.container)
					label_title:SetText(lesson.title)
					label_title:SetPos(x, y)
					label_title:SizeToContents()
					table.insert(lessonsCancelerBox.elements, label_title)
				x = x_base + 4; y = y_base + 32
				local label_duration = vgui.Create("DLabel", lessonsCancelerBox.container)
					label_duration:SetText(string.format(
						(
							hl == "fr" and
							"Durée : %u minutes" or
							"Duration: %u minutes"),
						math.ceil((lesson.finish - lesson.start) / 60)
					))
					label_duration:SetPos(x, y)
					label_duration:SizeToContents()
					table.insert(lessonsCancelerBox.elements, label_duration)
				x = x_base + 120; y = y_base + 32
				local label_place = vgui.Create("DLabel", lessonsCancelerBox.container)
					if rooms_lib_mr then
						label_place:SetText(rooms_lib_mr.getFullRoomLabel(
							rooms_lib_mr.getNameFromBuilding(lesson.building),
							rooms_lib_mr.getNameFromRoom(lesson.room)
						))
					end
					label_place:SetPos(x, y)
					label_place:SizeToContents()
					table.insert(lessonsCancelerBox.elements, label_place)
				x = x_base + 4; y = y_base + 48
				local label_teacher = vgui.Create("DLabel", lessonsCancelerBox.container)
					label_teacher:SetText(string.format(
						"%s <%s>",
						lesson.teacher:Nick(),
						lesson.teacher:SteamID()
					))
					label_teacher:SetPos(x, y)
					label_teacher:SizeToContents()
					table.insert(lessonsCancelerBox.elements, label_teacher)
				x = 412; y = y_base
				local button_remove = vgui.Create("DButton", lessonsCancelerBox.container)
					button_remove:SetPos(x, y)
					button_remove:SetSize(64, 64)
					local remove_text = (
						hl == "fr" and
						"Supprimer" or
						"Remove"
					)
					button_remove:SetText(remove_text)
					local teacher = lesson.teacher
					button_remove.DoClick = function(self)
						Derma_Query(
							(
								hl == "fr" and
								"Êtes-vous sûr de vouloir annuler ce cours ?" or
								"Are you sure you want to cancel this lesson?"),
							remove_text,
							(
								hl == "fr" and
								"Oui" or
								"Yes"),
							function()
								net.Start("universityrp_mr_agenda")
									net.WriteBool(true)
									net.WriteUInt(255, 8)
									net.WriteEntity(teacher)
								net.SendToServer()
							end,
							(
								hl == "fr" and
								"Annuler" or
								"Cancel"),
							nil
						)
					end
					table.insert(lessonsCancelerBox.elements, button_remove)
				y_base = y_base + 80
			end
		end
	end
	
	local function clear_list()
		local lessonsCancelerBox = universityrp_mr_agenda.lessonsCancelerBox
		for _, element in ipairs(lessonsCancelerBox.elements) do
			element:Remove()
		end
		lessonsCancelerBox.elements = nil
	end
	
	local function refresh_list()
		clear_list()
		make_list()
	end
	
	function universityrp_mr_agenda.lessonsCanceler()
		if IsValid(universityrp_mr_agenda.lessonsCancelerBox) then
			universityrp_mr_agenda.lessonsCancelerBox:Remove()
		end
		universityrp_mr_agenda.lessonsCancelerBox = vgui.Create("DFrame"); do
			local lessonsCancelerBox = universityrp_mr_agenda.lessonsCancelerBox
			lessonsCancelerBox:MakePopup()
			lessonsCancelerBox:SetKeyboardInputEnabled(false)
			lessonsCancelerBox:SetSize(480, 480)
			lessonsCancelerBox:SetTitle(
				hl == "fr" and
				"Annuler des cours" or
				"Cancel lessons"
			)
			lessonsCancelerBox:Center()
			lessonsCancelerBox.container = vgui.Create("DScrollPanel", lessonsCancelerBox); do
				local container = lessonsCancelerBox.container
				local w, h = lessonsCancelerBox:GetSize(); h = h - 24
				container:SetSize(w, h)
				container:SetPos(0, 24)
			end
			lessonsCancelerBox.RefreshButton = vgui.Create("DButton", lessonsCancelerBox); do
				local RefreshButton = lessonsCancelerBox.RefreshButton
				RefreshButton:SetPos(360, 3)
				RefreshButton:SetSize(84, 18)
				RefreshButton:SetText(
					hl == "fr" and
					"Rafraîchir" or
					"Refresh"
				)
				RefreshButton.DoClick = refresh_list
			end
			make_list()
		end
	end
end
