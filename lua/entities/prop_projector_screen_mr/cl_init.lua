--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

-- TODO - réessayer de faire un poseparameter pur, avec un groupe de vertex
-- BOGUE : Lorsqu'un bureau est supprimé, l'écran de projection perd ses render bounds et son poseparameter !

print("prop_projector_screen_mr:cl")

include("shared.lua")

local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "prop_projector_screen_mr:cl")

ENT.MaterialPathNoSignal = (
	prop_projector_screen_mr.MaterialPathNoSignal or
	"models/mohamed_rachid/projector_screen_no_signal_" .. (hl == "fr" and "fr" or "en")
)

function ENT:Think()
	-- nothing
end


local drawn = {}
do
	local manipulateVector = Vector(1, 0, 1)
	hook.Add("PreRender", "prop_projector_screen_mr:cl", function()
		for self in pairs(drawn) do
			if IsValid(self) then
				local lastOpened = self:GetLastOpened()
				local lastClosed = self:GetLastClosed()
				local moveDuration_s = self.MoveDuration_s
				local ratio
				if lastOpened ~= 0 then
					ratio = (CurTime() - lastOpened) / moveDuration_s
					manipulateVector.y = math.Clamp(ratio, 0., 1.)
					ratio = 1 - ratio
				else
					ratio = (CurTime() - lastClosed) / moveDuration_s
					manipulateVector.y = 1. - math.Clamp(ratio, 0., 1.)
				end
				self:ManipulateBoneScale(1, manipulateVector) -- cannot wait for ENT:Draw()
				self:SetPoseParameter("projector_screen_retract", ratio)
			end
		end
		drawn = {}
		for _, self in ipairs(ents.FindByClass("prop_projector_screen_mr")) do
			-- TODO - corriger modèles
			self:SetRenderBounds(self:GetModelBounds()) -- dear buggy model, fix this on every frame
		end
	end)
end

local materialNoSignal
function ENT:Draw()
	drawn[self] = true
	if self:isDeployed() then
		local projector = self:GetProjector()
		if IsValid(projector) and projector:GetOn() then
			prop_teacher_computer_mr.fixHdr()
			local computer = projector:GetComputer()
			if IsValid(computer) and computer:isComputerOn() then
				computer:renderScreenAndOverrideMaterial(2)
			else
				if not materialNoSignal then
					materialNoSignal = Material(self.MaterialPathNoSignal)
				end
				render.MaterialOverrideByIndex(2, materialNoSignal)
			end
		end
	end
	self:DrawModel()
	render.MaterialOverrideByIndex(2, nil)
end
