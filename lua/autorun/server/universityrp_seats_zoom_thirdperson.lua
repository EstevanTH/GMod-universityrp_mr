--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("universityrp_seats_zoom_thirdperson:sv")

do
	-- Disable serverside vehicle third person:
	local Vehicle = FindMetaTable("Vehicle")
	local doNothing = function()end
	Vehicle.SetThirdPersonMode = doNothing
	Vehicle.SetCameraDistance = doNothing
	Vehicle.GetThirdPersonMode = function()
		return false
	end
	Vehicle.GetCameraDistance = function()
		return 0.
	end
end
