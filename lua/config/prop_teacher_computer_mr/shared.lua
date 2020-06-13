--- SHARED ---

-- Base URLs that have the header X-Frame-Options set to SAMEORIGIN + their substitution URLs:
prop_teacher_computer_mr.UrlsSameorigin = {
	["https://docs.google.com/"] = "https://docs.google.com/presentation/d/",
}

-- Base URLs that are videos:
prop_teacher_computer_mr.UrlsVideo = {
	["http://www.youtube-nocookie.com/embed/"] = true,
	["https://www.youtube-nocookie.com/embed/"] = true,
	["http://www.youtube.com/embed/"] = true,
	["https://www.youtube.com/embed/"] = true,
}

-- Base URLs that are YouTube:
prop_teacher_computer_mr.UrlsYoutube = {
	["http://www.youtube-nocookie.com/embed/"] = true,
	["https://www.youtube-nocookie.com/embed/"] = true,
	["http://www.youtube.com/embed/"] = true,
	["https://www.youtube.com/embed/"] = true,
}

-- Picture extensions:
prop_teacher_computer_mr.ExtensionsPicture = {
	[".png"] = true,
	[".jpg"] = true,
	[".jpeg"] = true,
	[".gif"] = true,
	[".svg"] = true,
	[".webp"] = true,
}

-- The weapon class of the remote control:
prop_teacher_computer_mr.RemoteWeaponClass = "weapon_teacher_remote_mr"

--- CLIENT ---

-- Time before destroying the HTML renderer when considered useless:
prop_teacher_computer_mr.DisplayTimeout_s = 45.

-- Default dimensions of the HTML renderer:
prop_teacher_computer_mr.DefaultRenderWidth = 1280
prop_teacher_computer_mr.DefaultRenderHeight = 960

-- Dimensions of the design (pictures etc.) of the HTML content:
prop_teacher_computer_mr.DesignWidth = 1024
prop_teacher_computer_mr.DesignHeight = 768

-- Background color of the VGUI remote control:
-- From cstrike_pak_dir.vpk/materials/models/props/cs_office/projector.vtf
prop_teacher_computer_mr.RemoteColor = Color(88, 96, 120)
