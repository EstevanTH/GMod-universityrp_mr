--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

local class_name = string.sub(ENT.Folder, 10)
universityrp_mr_agenda = universityrp_mr_agenda or {}

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.AutomaticFrameAdvance = false
ENT.Category = "University RP"
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.PrintName = "Global agenda"
ENT.Author = "Mohamed RACHID"
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.use_distance_in2 = 3487.5 -- distance 1.5 m maxi to Use

do
	local class_name_is = "is " .. class_name
	ENT[class_name_is] = true
	
	function ENT.is_instance_of(ent)
		if ent[class_name_is] and IsValid(ent) then
			return true
		end
	end
	
	universityrp_mr_agenda.is_agenda_prop = ENT.is_instance_of
end
