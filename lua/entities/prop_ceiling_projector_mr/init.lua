--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("prop_ceiling_projector_mr:sv")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("config/prop_ceiling_projector_mr/shared.lua")

-- Configuration:
ENT.ShutdownTimeoutCfg_s = prop_ceiling_projector_mr.ShutdownTimeoutCfg_s or 300.
ENT.SupportModel = prop_ceiling_projector_mr.SupportModel or "models/props_junk/PlasticCrate01a.mdl"
ENT.ProjectorModel = prop_ceiling_projector_mr.ProjectorModel or "models/props/cs_office/projector.mdl"
ENT.ProjectorPos = prop_ceiling_projector_mr.ProjectorPos or Vector(-9.5, 0., 4.)
ENT.ProjectorAng = prop_ceiling_projector_mr.ProjectorAng or Angle(0., -90., -83.)

function ENT:KeyValue(key, value)
	local key = string.lower(key)
	if key == "projectorscreen" then
		self.projectorScreen = value
	elseif key == "gmod_allowphysgun" then
		if value == "0" then
			self.staticPhysics = true
		end
	end
end

function ENT:Initialize()
	self.Projector = ents.Create("prop_physics_multiplayer")
	if IsValid(self.Projector) then
		-- prop_dynamic does not support proper sprite rendering
		self.Projector:SetModel(self.ProjectorModel)
		self.Projector:SetSolid(SOLID_NONE)
		--self.Projector:SetSolid(SOLID_VPHYSICS) -- dev
		self.Projector:SetCollisionGroup(COLLISION_GROUP_WEAPON)
		self.Projector:SetParent(self)
		self.Projector:SetLocalPos(self.ProjectorPos)
		self.Projector:SetLocalAngles(self.ProjectorAng)
		self:SetProjectorProp(self.Projector)
	end
	self:SetModel(self.SupportModel)
	if self.staticPhysics then
		self:PhysicsInitStatic(SOLID_VPHYSICS)
	else
		self:PhysicsInit(SOLID_VPHYSICS)
		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end
	
	if self.projectorScreen and not IsValid(self:GetProjectorScreen()) then
		self:SetProjectorScreen(ents.FindByName(self.projectorScreen)[1])
	end
	self.projectorScreen = nil
end

function ENT:Think()
	if self:GetOn() then
		local screen = self:GetProjectorScreen()
		local computer = self:GetComputer()
		if IsValid(screen) and IsValid(computer) and screen:isDeployed() and computer:isComputerOn() then
			self.shutdownTimeout = nil
		elseif not self.shutdownTimeout then
			self.shutdownTimeout = RealTime() + self.ShutdownTimeoutCfg_s
		elseif RealTime() > self.shutdownTimeout then
			self:SetOn(false)
			self.shutdownTimeout = nil
		end
	end
end
