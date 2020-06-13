--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

--[[
This script replaces the default exit points and prevent seats & players from colliding.
It also restores the view as expected.
Warning: there is a significant risk of conflict with other seat exit managements!
]]

-- TODO - sortir à l'endroit du siège si impossible de sortir à l'endroit prévu
--	Si bit.band(0x7, ply:GetFlags()) == 6 est maintenu alors que la touche IN_DUCK n'est pas maintenue depuis un certain temps, alors le joueur est bloqué. Sortir à l'emplacement du siège (avec incrément z uniquement), si la position n'a pas changé depuis.

print("seat_natural_leaving")

seat_natural_leaving = seat_natural_leaving or {}

include("config/seat_natural_leaving/server.lua")

-- Configuration:
seat_natural_leaving.OutOffset = seat_natural_leaving.OutOffset or Vector(0, -15., 1.)

local avoidPlayerCollisions
do
	local collisionGroupsToFix = {
		[COLLISION_GROUP_NONE] = true,
		[COLLISION_GROUP_VEHICLE] = true,
	}
	local function avoidPlayerCollisions_(seat)
		if collisionGroupsToFix[seat:GetCollisionGroup()] then
			seat:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		end
	end
	function avoidPlayerCollisions(seat, withTimer)
		if withTimer then
			timer.Simple(0., function()
				if IsValid(seat) then
					avoidPlayerCollisions_(seat)
				end
			end)
		else
			avoidPlayerCollisions_(seat)
		end
	end
end

local function should_custom_exit(seat, ply, checkEnteredByUserInput)
	-- Determine if the safe exit logics should be applied:
	-- By default only seats with no parent are involved.
	
	local proceed = false
	if IsValid(seat) and seat:GetClass() == "prop_vehicle_prisoner_pod" then
		proceed = hook.Run("seat_natural_leaving:shouldDo", seat, ply)
		if proceed == nil then
			if checkEnteredByUserInput and not seat.seat_natural_leaving_enteredByUserInput then
				-- Bypass by default if the seat was not entered by user input:
				proceed = false
			else
				proceed = (not IsValid(seat:GetParent()))
			end
		end
	end
	return proceed
end

hook.Add("CanExitVehicle", "seat_natural_leaving", function(seat, ply)
	-- Save the eye angle before exiting the seat:
	
	local eye_ang = ply:EyeAngles(); eye_ang.r = 0
	seat.seat_natural_leaving_eye_ang = eye_ang
end)

hook.Add("PlayerLeaveVehicle", "seat_natural_leaving", function(ply, seat)
	-- On seat exit, lock the seat for 1 second, restore proper eye angle, avoid collision with players:
	
	local shouldCustomExit = should_custom_exit(seat, ply, true)
	seat.seat_natural_leaving_enteredByUserInput = nil
	if shouldCustomExit then
		do
			-- Move player to highest z offset among relative & absolute (safer):
			local pos_seat = seat:GetPos()
			local out_offset = seat_natural_leaving.OutOffset
			local pos_ply = seat:LocalToWorld(out_offset)
			pos_ply.z = math.max(pos_ply.z, pos_seat.z + out_offset.z)
			ply:SetPos(pos_ply)
		end
		do
		-- Check that the point is available
		end
		if seat.seat_natural_leaving_eye_ang then
			ply:SetEyeAngles(seat.seat_natural_leaving_eye_ang)
			seat.seat_natural_leaving_eye_ang = nil
		end
		do
			-- Prevent re-entering the same seat:
			seat.seat_natural_leaving_locked = true
			timer.Simple(1., function()
				if IsValid(seat) then
					seat.seat_natural_leaving_locked = false
				end
			end)
		end
		avoidPlayerCollisions(seat)
	end
end)

hook.Add("CanPlayerEnterVehicle", "seat_natural_leaving", function(ply, seat)
	if seat.seat_natural_leaving_locked then
		return false
	else
		local hookName = "seat_natural_leaving #" .. seat:GetCreationID()
		hook.Add("PlayerEnteredVehicle", hookName, function(ply_, seat_)
			if ply_ == ply and seat_ == seat then
				hook.Remove("PlayerEnteredVehicle", hookName)
				seat.seat_natural_leaving_enteredByUserInput = true
			end
		end)
		hook.Add("Think", hookName, function()
			hook.Remove("Think", hookName)
			hook.Remove("PlayerEnteredVehicle", hookName)
		end)
	end
end)

hook.Add("CanProperty", "seat_natural_leaving", function(ply, property, seat)
	-- Disable collision with players when enabling collisions via the Sandbox context menu:
	
	if property == "collision" then
		if should_custom_exit(seat, ply) then
			avoidPlayerCollisions(seat, true)
		end
	end
end)

hook.Add("OnEntityCreated", "seat_natural_leaving", function(seat)
	-- Disable collision with players for all seats upon their creation:
	
	if seat:GetClass() == "prop_vehicle_prisoner_pod" then
		-- with timer because Entity:Spawn() alters the collision group
		avoidPlayerCollisions(seat, true)
	end
end)
