--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("prop_ceiling_projector_mr:sh")

prop_ceiling_projector_mr = prop_ceiling_projector_mr or {}

include("config/prop_ceiling_projector_mr/shared.lua")

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.AutomaticFrameAdvance = false
ENT.Category = "University RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PrintName = "Ceiling projector"
ENT.Author = "Mohamed RACHID"
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "ProjectorProp")
	self:NetworkVar("Entity", 1, "ProjectorScreen")
	self:NetworkVar("Bool", 0, "On")
end

function ENT:GetComputer()
	local computer
	if IsValid(self.lastComputer) and self.lastComputer:GetProjector() == self then
		computer = self.lastComputer
	else
		-- Inefficient, but the projector requires a computer.
		for _, computer_ in ipairs(ents.FindByClass("prop_teacher_computer_mr")) do
			if computer_:GetProjector() == self then
				computer = computer_
				self.lastComputer = computer
				break
			end
		end
	end
	return computer
end
