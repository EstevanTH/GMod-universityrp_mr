--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

-- TODO - Ajouter un son pendant l'action de l'écran "plats/elevator_loop1.wav"

print("prop_projector_screen_mr:sv")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
AddCSLuaFile("config/prop_projector_screen_mr/shared.lua")

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
	self:SetSaveValue("m_bClientSideAnimation", true)
end

function ENT:openScreen()
	if self:GetLastOpened() == 0 then
		local lastClosed = self:GetLastClosed()
		local now = CurTime()
		local remaining_s = now - lastClosed - self.MoveDuration_s
		if lastClosed == 0 or now >= lastClosed + self.MoveDuration_s then
			self:SetLastOpened(now)
		else
			self:SetLastOpened(now + remaining_s)
		end
		self:SetLastClosed(0)
	end
end

function ENT:closeScreen()
	local lastOpened = self:GetLastOpened()
	if self:GetLastClosed() == 0 and lastOpened ~= 0 then -- lastOpened ~= 0 tested because of initial values
		local now = CurTime()
		local remaining_s = now - lastOpened - self.MoveDuration_s
		if lastOpened == 0 or now >= lastOpened + self.MoveDuration_s then
			self:SetLastClosed(now)
		else
			self:SetLastClosed(now + remaining_s)
		end
		self:SetLastOpened(0)
	end
end
