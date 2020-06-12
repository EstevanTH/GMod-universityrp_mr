--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.Model = "models/props/de_inferno/tableantique.mdl" -- included in CS:S & CS:GO
ENT.SeatModel = "models/nova/chair_wood01.mdl"
ENT.SeatPos = Vector(27., 0., 0.)
ENT.SeatAng = Angle(0., 90., 0.)
ENT.ComputerPos = Vector(0.80, 0., 31.05)
ENT.ComputerAng = Angle(0., 0., 0.)

function ENT:KeyValue(key, value)
	local key = string.lower(key)
	if key == "model" then
		self.Model = value
	elseif key == "gmod_allowphysgun" then
		if value == "0" then
			self.staticPhysics = true
		end
	end
end

local invalidModels = {
	["models/error.mdl"] = true,
	[""] = true,
}

function ENT:Initialize()
	if invalidModels[self:GetModel()] then
		self:SetModel(self.Model)
	end
	if self.staticPhysics then
		self:PhysicsInitStatic(SOLID_VPHYSICS)
	else
		self:PhysicsInit(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end
	
	self.Seat = ents.Create("prop_vehicle_prisoner_pod")
	if IsValid(self.Seat) then
		self.Seat:SetParent(self)
		self.Seat:SetLocalPos(self.SeatPos)
		self.Seat:SetLocalAngles(self.SeatAng)
		self.Seat:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")
		self.Seat:SetKeyValue("limitview", "0")
		self.Seat:SetModel(self.SeatModel)
		self.Seat:Spawn()
		self.Seat:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self.Seat:PhysicsDestroy()
		if self.Seat.setKeysNonOwnable then
			self.Seat:setKeysNonOwnable(true)
		end
	end
	
	self.Computer = ents.Create("prop_teacher_computer_mr")
	if IsValid(self.Computer) then
		self.Computer:SetParent(self)
		self.Computer:SetLocalPos(self.ComputerPos)
		self.Computer:SetLocalAngles(self.ComputerAng)
		self.Computer:SetSeat(self.Seat)
		self.Computer:Spawn()
	end
end

--[[
do -- dev
	for _, self in ipairs(ents.FindByClass("prop_teacher_desk_mr")) do
		self.Seat:SetLocalPos(ENT.SeatPos)
		self.Seat:SetLocalAngles(ENT.SeatAng)
		self.Computer:SetLocalPos(ENT.ComputerPos)
		self.Computer:SetLocalAngles(ENT.ComputerAng)
	end
end
]]
