--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

resource.AddWorkshop("2133754720")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.Model = "models/props_c17/paper01.mdl"

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

local flattening_scale = Vector(1., 1., 0.001) -- because the sheet is crumpled

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
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:ManipulateBoneScale(0, flattening_scale)
	self:SetUseType(SIMPLE_USE)
end

if game.SinglePlayer() then
	function ENT:Use(activator, caller, useType)
		if activator.SendLua then -- only a player
			activator:SendLua(string.format(
				-- Explicitly called in single-player because KeyPress is predicted:
				"Entity(%u):Use(Entity(%u),Entity(%u),%u)",
				activator:EntIndex(),
				activator:EntIndex(),
				caller:EntIndex(),
				useType
			))
		end
	end
end
