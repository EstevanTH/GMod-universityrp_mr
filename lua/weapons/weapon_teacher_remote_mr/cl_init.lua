--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

include("shared.lua")

local MATERIAL_REMOTE = CreateMaterial(
	"weapon_teacher_remote_mr_view_model",
	"vertexlitgeneric",
	{
		["$model"] = 1,
		["$colorfix"] = "{88 96 120}", -- from cstrike_pak_dir.vpk/materials/models/props/cs_office/projector.vtf
		["Proxies"] = {
			["Equals"] = {
				["srcVar1"] = "$colorfix",
				["resultVar"] = "$color",
			},
		},
	}
)
--local VECTOR_NULL = Vector(0., 0., 0.)
--local VECTOR_DEFAULT = Vector(1., 1., 1.)

function SWEP:PreDrawViewModel(viewModel)
	-- Set a proper remote control only idle sequence:
	self:setupViewModelSequence(viewModel) -- only works in single-player
	
	-- Make the mine invisible, which would be visible when deploying:
	-- This does not work very well because it needs to be restored.
	--viewModel:ManipulateBoneScale(40, VECTOR_NULL)
	--viewModel:ManipulateBoneScale(41, VECTOR_NULL)
	
	-- Remplace the color of the remote control:
	render.MaterialOverride(MATERIAL_REMOTE)
	
	-- Only other players should see the ownedThirdPersonModel:
	local ownedThirdPersonModel = self:GetOwnedThirdPersonModel()
	if IsValid(ownedThirdPersonModel) then
		ownedThirdPersonModel:SetNoDraw(true)
	end
end

function SWEP:ViewModelDrawn(viewModel)
	--viewModel:ManipulateBoneScale(40, VECTOR_DEFAULT)
	--viewModel:ManipulateBoneScale(41, VECTOR_DEFAULT)
	render.MaterialOverride(nil)
end

function SWEP:PrimaryAttack()
	-- nothing
end

function SWEP:SecondaryAttack()
	-- nothing
end

function SWEP:Reload()
	-- nothing
end

function SWEP:CustomAmmoDisplay()
	local newData = {
		Draw = false,
	}
	local computer = prop_teacher_computer_mr.getComputerFromPlayer(LocalPlayer())
	if IsValid(computer) then
		newData.Draw = true
		newData.PrimaryClip = computer:GetPage()
		newData.PrimaryAmmo = computer:GetSlideshowPages()
	end
	return newData
end

function SWEP:DrawWorldModel()
	if IsValid(self.Owner) then
		-- Only other players should see the ownedThirdPersonModel:
		local ownedThirdPersonModel = self:GetOwnedThirdPersonModel()
		if IsValid(ownedThirdPersonModel) then
			-- equiped
			ownedThirdPersonModel:SetNoDraw(false)
		else
			-- not equiped, but self.Owner is set when taken with the gravity gun, bad!
			self:DrawModel()
		end
	else
		self:DrawModel()
	end
end
