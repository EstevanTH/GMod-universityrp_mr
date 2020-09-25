--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

include("shared.lua")

local ENT = ENT
local class_name = string.sub(ENT.Folder, 10)

hook.Add("KeyPress", class_name, function(ply, key)
	if key == IN_USE then
		local trace = ply:GetEyeTrace()
		local self = trace.Entity
		if IsValid(self) and ENT.is_instance_of(self) and IsFirstTimePredicted() then -- right class
			if trace.StartPos:DistToSqr(trace.HitPos) < self.use_distance_in2 then
				self:Use(ply, ply, USE_ON)
			end
		end
	end
end)

function ENT:Use(activator)
	universityrp_mr_agenda.showStartLessonConfirm(self)
end

do
	local material_agenda_global
	local material_agenda_room
	local font_name
	local overlay_position = Vector(7.5, -3., 0.1)
	local overlay_angle = Angle(0., 90., 0.)
	local overlay_offsets = {}
	
	function ENT:Draw()
		if not material_agenda_global then
			local material_key_values = {
				-- VertexLitGeneric is not used because of horrible shadows due to the crumpled sheet.
				["$model"] = 1,
				["$nocull"] = 1,
				["$colorfix"] = "{223 223 223}",
				["proxies"] = {
					["equals"] = {
						["srcVar1"] = "$colorfix",
						["resultVar"] = "$color",
					},
				},
			}
			local agenda_texture = Material("mohamed_rachid/universityrp_mr_agenda/prop_agenda_global_mr.png", "smooth"):GetTexture("$basetexture")
			material_agenda_global = CreateMaterial("prop_agenda_global_mr", "UnLitGeneric", material_key_values)
			material_agenda_global:SetTexture("$basetexture", agenda_texture)
			agenda_texture = Material("mohamed_rachid/universityrp_mr_agenda/prop_agenda_room_mr.png", "smooth"):GetTexture("$basetexture")
			material_agenda_room = CreateMaterial("prop_agenda_room_mr", "UnLitGeneric", material_key_values)
			material_agenda_room:SetTexture("$basetexture", agenda_texture)
		end
		
		render.MaterialOverrideByIndex(0, self.room_agenda and material_agenda_room or material_agenda_global)
		self:DrawModel()
		render.MaterialOverrideByIndex(0, nil)
		
		if not font_name then
			font_name = class_name .. ":overlay"
			surface.CreateFont(font_name, {
				extended = true,
				size = 95,
				weight = 1000,
				antialias = false,
				blursize = 0,
				outline = true,
			})
		end
		
		local trace = LocalPlayer():GetEyeTrace()
		local is_pointed = ((trace.Entity == self) and (trace.StartPos:DistToSqr(trace.HitPos) < self.use_distance_in2))
		if not is_pointed then
			surface.SetTextColor(127, 127, 127, 255)
		elseif self.room_agenda then
			surface.SetTextColor(0, 223, 223, 255)
		else
			surface.SetTextColor(223, 0, 223, 255)
		end
		surface.SetFont(font_name)
		local text = self.room_agenda and "Room's agenda" or "Global agenda"
		local text_offset = overlay_offsets[text]
		if not text_offset then
			text_offset = math.floor(surface.GetTextSize(text) / -2.)
			overlay_offsets[text] = text_offset
		end
		surface.SetTextPos(text_offset, 0)
		cam.Start3D2D(self:LocalToWorld(overlay_position), self:LocalToWorldAngles(overlay_angle), 0.02)
			surface.DrawText(text)
		cam.End3D2D()
	end
end
