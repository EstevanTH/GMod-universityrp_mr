local hl = GetConVar("gmod_language"):GetString()

--- CLIENT ---

-- Color of the background:
universityrp_mr_osd.BackgroundColor = Color(0, 0, 0, 191)

-- Background material, usually white + transparency (.png / .vmt without extension):
universityrp_mr_osd.BackgroundMaterial = "vgui/universityrp_mr_osd/background.png"

-- Logo material (.png / .jpg / .vmt without extension):
universityrp_mr_osd.LogoMaterial = "vgui/techcredits/miles"

-- Give a nice displayed name for user groups:
universityrp_mr_osd.Ranks = {
	["user"] = (hl == "fr") and "Utilisateur" or "User",
	["admin"] = (hl == "fr") and "Administrateur" or "Administrator",
	["diffuseur"] = "Diffuseur", --fr
	["broadcaster"] = "Broadcaster", --en
	["moderateur"] = "Modérateur", --fr
	["moderator"] = "Moderator", --en
	["moderateur stagiaire"] = "Modérateur stagiaire", --fr
	["trainee moderator"] = "Trainee moderator", --en
	["noaccess"] = (hl == "fr") and "Banni" or "Banned",
	["pas_serieux"] = "Riche", --fr
	["not serious"] = "Rich", --en
	["superadmin"] = (hl == "fr") and "Super administrateur" or "Super administrator",
	["technicien"] = "Technicien", --fr
	["technician"] = "Technician", --en
}
