--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

--[[ This script provides:
- Removed persistent per-seat zoom level and 3rd-person view
- Ability to zoom in 1st person [hook]
- Ability to use a tri-state view mode switch (1st person, 1st person with computer overlay [hook], 3rd person)
]]

print("universityrp_seats_zoom_thirdperson:cl")

local zoom = 0 -- degrees
local zoomActive = false
local fov_base
local fov_last
local bThirdPersonMode = false
local fCameraDistance = 0.
local eFirstPersonOverlayComputer = nil -- computer entity used for first-person overlay

do
	-- Make third-person & zoom level common to all vehicles:
	local Vehicle = FindMetaTable("Vehicle")
	function Vehicle:SetThirdPersonMode(val)
		bThirdPersonMode = val
	end
	function Vehicle.GetThirdPersonMode()
		return bThirdPersonMode
	end
	function Vehicle:SetCameraDistance(val)
		fCameraDistance = val
	end
	function Vehicle.GetCameraDistance()
		return fCameraDistance
	end
end

local function useableFirstPersonZoom(seat, ply)
	local canZoom
	if seat.GetThirdPersonMode and seat:GetThirdPersonMode() then
		canZoom = false -- 3rd person
	else
		canZoom = hook.Run("canUseFirstPersonZoom_mr", seat, ply)
		canZoom = canZoom or false
	end
	return canZoom
end

hook.Run("newFirstPersonOverlayComputer_mr", nil) -- for Lua refresh

hook.Add("SetupMove", "universityrp_seats_zoom_thirdperson:cl", function(ply, mv, cmd)
	-- StartCommand and CreateMove cannot be used because they are called multiple times while IsFirstTimePredicted() does not work.
	if not IsFirstTimePredicted() then return end
	local ply = LocalPlayer()
	local seat = ply:GetVehicle()
	if IsValid(seat) then
		local onSeat = (seat:GetClass() == "prop_vehicle_prisoner_pod")
		local wheel = cmd:GetMouseWheel()
		-- Third-person (see garrysmod\gamemodes\base\gamemode\init.lua):
		if mv:KeyPressed(IN_DUCK) then
			if onSeat then
				if bThirdPersonMode then -- enter 1st-person view
					bThirdPersonMode = false
					fCameraDistance = 0.
					eFirstPersonOverlayComputer = nil
				else
					if IsValid(eFirstPersonOverlayComputer) then -- enter 3rd-person view
						bThirdPersonMode = true
						fCameraDistance = 0.
						eFirstPersonOverlayComputer = nil
					else -- enter 1st-person view with fullscreen if 1 computer found, or 3rd-person view
						local computer = hook.Run("findFirstPersonOverlayComputer_mr", ply, seat) -- nil if not exactly 1 computer found
						if IsValid(computer) then
							bThirdPersonMode = false
							fCameraDistance = 0.
							eFirstPersonOverlayComputer = computer
						else
							bThirdPersonMode = true
							fCameraDistance = 0.
							eFirstPersonOverlayComputer = nil
						end
					end
				end
			else
				bThirdPersonMode = (not bThirdPersonMode)
				fCameraDistance = 0.
				eFirstPersonOverlayComputer = nil
			end
			hook.Run("newFirstPersonOverlayComputer_mr", eFirstPersonOverlayComputer)
		end
		if wheel ~= 0 then
			seat:SetCameraDistance(math.Clamp(fCameraDistance - (wheel * 0.03 * (1.1 + fCameraDistance)), -1, 10))
		end
		-- First-person zoom:
		if onSeat and useableFirstPersonZoom(seat, ply) then
			zoomActive = true
			if wheel > 0 then
				zoom = math.min(fov_base - 10, zoom + ((fov_base - zoom) * wheel / 20)) -- min FOV: 10°
			elseif wheel < 0 then
				zoom = math.max(0, zoom + ((fov_base - zoom) * wheel / 20)) -- max FOV: fov_base
			end
		else
			zoomActive = false
		end
	else
		-- First-person zoom:
		zoomActive = false
		zoom = 0
		-- Third-person:
		bThirdPersonMode = false
		fCameraDistance = 0.
		if eFirstPersonOverlayComputer ~= nil then
			eFirstPersonOverlayComputer = nil
			hook.Run("newFirstPersonOverlayComputer_mr", nil)
		end
	end
end)

hook.Add("CalcView", "universityrp_seats_zoom_thirdperson:cl", function(ply, pos, ang, fov)
	-- Zoom:
	fov_base = fov
	if zoomActive and zoom ~= 0 then
		fov_last = math.max(10, fov - zoom) -- math.max() prevents excess from suit zoom
		return {fov = fov_last}
	else
		fov_last = fov
	end
end)

hook.Add("AdjustMouseSensitivity", "universityrp_seats_zoom_thirdperson:cl", function()
	-- Zoom:
	if zoomActive and zoom ~= 0 then
		return fov_last / fov_base
	end
end)
