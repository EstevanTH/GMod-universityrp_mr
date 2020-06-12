--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("prop_projector_screen_mr:sh")

prop_projector_screen_mr = prop_projector_screen_mr or {}

include("config/prop_projector_screen_mr/shared.lua")

local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "prop_projector_screen_mr:sh")

ENT.Model = prop_projector_screen_mr.Model or "models/mohamed_rachid/projector_screen_15.mdl"
prop_projector_screen_mr.AllowedModels = prop_projector_screen_mr.AllowedModels or {
	[ENT.Model] = true,
	["models/mohamed_rachid/projector_screen_15.mdl"] = true,
	["models/mohamed_rachid/projector_screen_25.mdl"] = true,
	["models/mohamed_rachid/projector_screen_30.mdl"] = true,
	["models/mohamed_rachid/projector_screen_35.mdl"] = true,
	["models/mohamed_rachid/projector_screen_40.mdl"] = true,
}
local allowedModelsOrdered = {}
for model in pairs(prop_projector_screen_mr.AllowedModels) do
	allowedModelsOrdered[#allowedModelsOrdered + 1] = model
end
table.sort(allowedModelsOrdered)

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.AutomaticFrameAdvance = false -- animation latency when true
ENT.Category = "University RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PrintName = "Projector screen"
ENT.Author = "Mohamed RACHID"
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.MoveDuration_s = prop_projector_screen_mr.MoveDuration_s or 8.

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "LastOpened") -- 0 if closed or closing
	self:NetworkVar("Float", 1, "LastClosed") -- 0 if opened or opening
end

function ENT:GetProjector()
	local projector
	if IsValid(self.lastProjector) and self.lastProjector:GetProjectorScreen() == self then
		projector = self.lastProjector
	else
		-- Inefficient, but the screen requires a projector.
		for _, projector_ in ipairs(ents.FindByClass("prop_ceiling_projector_mr")) do
			if projector_:GetProjectorScreen() == self then
				projector = projector_
				self.lastProjector = projector
				break
			end
		end
	end
	return projector
end

function ENT:GetComputer()
	local computer
	local projector = self:GetProjector()
	if IsValid(projector) then
		computer = projector:GetComputer()
	end
	return computer
end

function ENT:isDeployed()
	local lastOpened = self:GetLastOpened()
	return lastOpened ~= 0 and CurTime() >= lastOpened + self.MoveDuration_s
end

local menuBulletColors = {
	"icon16/bullet_blue.png",
	"icon16/bullet_green.png",
	"icon16/bullet_orange.png",
	"icon16/bullet_pink.png",
	"icon16/bullet_purple.png",
	"icon16/bullet_red.png",
	"icon16/bullet_yellow.png",
}
properties.Add("prop_projector_screen_mr:model", {
	Type = nil,
	MenuLabel = (
		hl == "fr" and
		"Modèle" or
		"Model"
	),
	MenuIcon = "icon16/shape_square_edit.png",
	PrependSpacer = nil,
	Order = 602,
	Filter = function(property, ent)
		return (ent:GetClass() == "prop_projector_screen_mr")
	end,
	Checked = nil,
	Action = nil,
	Receive = function(property, len, ply)
		if ply:IsSuperAdmin() then
			local ent = net.ReadEntity()
			local model = net.ReadString()
			if prop_projector_screen_mr.AllowedModels[model] and IsValid(ent) then
				ent.Model = model
				ent:SetModel(model)
				if ent.staticPhysics then
					ent:PhysicsInitStatic(SOLID_VPHYSICS)
				else
					ent:PhysicsInit(SOLID_VPHYSICS)
					local phys = ent:GetPhysicsObject()
					if IsValid(phys) then
						phys:EnableMotion(false)
					end
				end
			end
		end
	end,
	MenuOpen = function(property, option, ent, tr)
		local choice = option:AddSubMenu()
		local function option_DoClick(option)
			if LocalPlayer():IsSuperAdmin() then
				if IsValid(ent) then
					property:MsgStart()
					net.WriteEntity(ent)
					net.WriteString(option.model)
					property:MsgEnd()
				end
			end
		end
		local currentModel = ent:GetModel()
		for i, model in ipairs(allowedModelsOrdered) do
			local option = choice:AddOption(string.sub(model, 8, -5))
			option.DoClick = option_DoClick
			if model == currentModel then
				option:SetChecked(true)
			else
				option:SetIcon(menuBulletColors[1 + i % #menuBulletColors]) -- starts at 2nd icon
			end
			option.model = model
		end
	end,
	OnCreate = nil,
})
