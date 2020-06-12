--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

SWEP.HandRemotePos = Vector(1.80, -0.90, 0.)
SWEP.HandRemoteAng = Angle(0., -20., 110.)

function SWEP:Initialize()
	-- nothing
end

function SWEP:CanBePickedUpByNPCs()
	return false
end

function SWEP:ShouldDropOnDie()
	return false
end

hook.Add("PlayerCanPickupWeapon", "weapon_teacher_remote_mr:sv", function(ply, wep)
	if  wep:GetClass() == "weapon_teacher_remote_mr"
	and ply:HasWeapon("weapon_teacher_remote_mr") then
		return false -- just for fun
	end
end)

function SWEP:Deploy()
	do
		-- To draw the model properly in the owner's right hand, a prop_dynamic is used instead:
		local hand = self.Owner:LookupBone("ValveBiped.Bip01_R_Finger2")
		if hand then
			if not IsValid(self.ownedThirdPersonModel) then
				-- Third-person model used when this self is owned:
				self.ownedThirdPersonModel = ents.Create("prop_dynamic")
				self:SetOwnedThirdPersonModel(self.ownedThirdPersonModel)
				self.ownedThirdPersonModel:SetModel(self.WorldModel)
				self.ownedThirdPersonModel:SetSolid(SOLID_NONE)
			end
			self.ownedThirdPersonModel:SetNoDraw(false)
			self.ownedThirdPersonModel:FollowBone(self.Owner, hand)
			self.ownedThirdPersonModel:SetLocalPos(self.HandRemotePos)
			self.ownedThirdPersonModel:SetLocalAngles(self.HandRemoteAng)
		end
	end
	
	if self.Owner and self.Owner:IsPlayer() then
		local viewModel = self.Owner:GetViewModel()
		if IsValid(viewModel) then
			self:setupViewModelSequence(viewModel)
		end
	end
	
	self:SetHoldType("slam")
	return true
end

function SWEP:hideOwnedThirdPersonModel()
	if IsValid(self.ownedThirdPersonModel) then
		self.ownedThirdPersonModel:SetNoDraw(true)
	end
end

function SWEP:Holster()
	-- Checking the active weapon prevents the in-hand model from disappearing when sitting without allowed weapons.
	-- An (undone) extra clientside check must be done if the view model was visible before sitting, otherwise it won't show.
	timer.Simple(0., function()
		if IsValid(self) then
			if not IsValid(self.Owner) or self.Owner:GetActiveWeapon() ~= self then
				self:hideOwnedThirdPersonModel()
			end
		end
	end)
	return true
end

function SWEP:OwnerChanged()
	self:hideOwnedThirdPersonModel()
end

function SWEP:OnDrop()
	self:hideOwnedThirdPersonModel()
end

function SWEP:OnRemove()
	if IsValid(self.ownedThirdPersonModel) then
		self.ownedThirdPersonModel:Remove()
	end
end

function SWEP:PrimaryAttack()
	-- Handled in the KeyPress event for more usage flexibility
end

function SWEP:SecondaryAttack()
	-- Handled in the KeyPress event for more usage flexibility
end

-- Lua refresh:
for _, self in ipairs(ents.FindByClass("weapon_teacher_remote_mr")) do
	if IsValid(self.ownedThirdPersonModel) then
		self.ownedThirdPersonModel:SetLocalPos(SWEP.HandRemotePos)
		self.ownedThirdPersonModel:SetLocalAngles(SWEP.HandRemoteAng)
	end
end
