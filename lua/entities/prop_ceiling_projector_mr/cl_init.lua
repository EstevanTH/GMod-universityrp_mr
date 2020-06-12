--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("prop_ceiling_projector_mr:cl")

include("shared.lua")

-- Configuration:
ENT.LightRadius = prop_ceiling_projector_mr.LightRadius or 1
ENT.LightSize = prop_ceiling_projector_mr.LightSize or 40
ENT.LightPos = prop_ceiling_projector_mr.LightPos or Vector(1.0, -10.5, 4.8)
local LightColor = prop_ceiling_projector_mr.LightColor or Color(255, 255, 255, 255)
local LightColorNoSignal = prop_ceiling_projector_mr.LightColorNoSignal or Color(128, 128, 255, 255)
local LightColorNoScreen = prop_ceiling_projector_mr.LightColorNoScreen or Color(128, 128, 128, 255)
local LightMat = Material(prop_ceiling_projector_mr.LightMat or "sprites/light_ignorez")

function ENT:Draw()
	self:DrawModel()
end

--local lightColorSample = GetRenderTarget("prop_ceiling_projector_mr_color_sample", 1, 1)

function ENT:DrawTranslucent()
	if self:GetOn() then
		local projector = self:GetProjectorProp()
		if IsValid(projector) then
			if not self.lightPixVis then
				self.lightPixVis = util.GetPixelVisibleHandle()
			end
			if not self.lightAbsPos then
				self.lightAbsPos = projector:LocalToWorld(self.LightPos)
			end
			local visibility = util.PixelVisible(self.lightAbsPos, self.LightRadius, self.lightPixVis)
			local c
			local screen = self:GetProjectorScreen()
			if IsValid(screen) and screen:isDeployed() then
				local computer = self:GetComputer()
				if IsValid(computer) and computer:isComputerOn() then
					--[[
					-- render.CapturePixels() does not refresh its values!
					local textureSmooth
					if computer.materialSmooth then
						textureSmooth = computer.materialSmooth:GetTexture("$basetexture")
					end
					if not textureSmooth then
						textureSmooth = prop_teacher_computer_mr.textureScreenUnloaded
					end
					if textureSmooth then
						render.PushRenderTarget(lightColorSample)
						do
							render.DrawTextureToScreen(textureSmooth)
							render.CapturePixels()
							c = Color(render.ReadPixel(0, 0))
							c.r = 128 + math.floor(c.r * 0.5)
							c.g = 128 + math.floor(c.g * 0.5)
							c.b = 128 + math.floor(c.b * 0.5)
						end
						render.PopRenderTarget()
					else
						c = LightColor
					end
					]]
					c = LightColor
				else
					c = LightColorNoSignal
				end
			else
				c = LightColorNoScreen
			end
			render.SetMaterial(LightMat)
			render.DrawSprite(self.lightAbsPos, self.LightSize, self.LightSize, Color(c.r, c.g, c.b, c.a * visibility))
		end
	else
		self.lightAbsPos = nil -- cleanup
	end
end
