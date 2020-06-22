-- Path to JSON lessons library, can be a file relative to "garrysmod/" or a URL (http / https):
prop_teacher_computer_mr.LessonsListUrl = "data/prop_teacher_computer_mr/lessons_library.json"
--prop_teacher_computer_mr.LessonsListUrl = "http://www.example.ext/slideshows/lessons_library.json"

-- Refesh rates of the lessons library:
prop_teacher_computer_mr.LessonsListRefresh_s = 45.
prop_teacher_computer_mr.LessonsListRefreshAfterError_s = 10.

-- Allowed domains for slides in Lua-defined slideshows:
-- Do not use a preceding dot. Sub-domains are included implicitly.
prop_teacher_computer_mr.LuaDefinedAllowedDomains = {
	--"example.ext",
}

-- Inactivity timeout before turning the computer into sleep mode:
prop_teacher_computer_mr.SleepTimeout_s = 600.

-- When a computer is linked with a projector, must the player be a teacher to use it?
-- The module "universityrp_mr_agenda" must be installed.
prop_teacher_computer_mr.OnlyTeachersIfProjector = false

-- Default computer model (skins must be equivalent to default):
prop_teacher_computer_mr.Model = "models/props/cs_office/computer.mdl"

-- Characteristics of the on-desk remote control:
prop_teacher_computer_mr.RemoteModel = "models/props/cs_office/projector_remote.mdl"
prop_teacher_computer_mr.RemotePos = Vector(-1.00, 12.00, 0.00)
prop_teacher_computer_mr.RemoteAng = Angle(0., -70., 0.)

-- Characteristics of the decorative on-desk phone:
prop_teacher_computer_mr.PhoneModel = "models/props/cs_office/phone.mdl"
prop_teacher_computer_mr.PhonePos = Vector(-7.00, 25.00, 0.00)
prop_teacher_computer_mr.PhoneAng = Angle(0., -15., 0.)
