--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

-- Remote control for "prop_teacher_computer_mr"
-- The responsibility of entity relationships is not handled in this entity, it is totally passive.


local hl = GetConVar("gmod_language"):GetString()
cvars.AddChangeCallback("gmod_language", function(convar, oldValue, newValue)
	hl = newValue
end, "weapon_teacher_remote_mr:sv")

SWEP.Category = "University RP"
SWEP.Spawnable = false
SWEP.PrintName = (
	hl == "fr" and
	"Télécommande de diaporama" or
	"Slideshow remote"
)
SWEP.Author = "Mohamed RACHID"
SWEP.Instructions = (
	hl == "fr" and
	[[Attaque : diapositive suivante
Attaque2 : diapositive précédente]] or
	[[Attack: next slide
Attack2: previous slide]]
)
SWEP.ViewModel = "models/weapons/c_slam.mdl"
SWEP.ViewModelFlip = true
SWEP.WorldModel = "models/props/cs_office/projector_remote.mdl"
SWEP.DrawWeaponInfoBox = true
SWEP.DrawAmmo = true
SWEP.DrawCrosshair = false
SWEP.RenderGroup = RENDERGROUP_OPAQUE
SWEP.Slot = 1
SWEP.SlotPos = 1
-- SWEP.WepSelectIcon = surface.GetTextureID("weapons/swep")
SWEP.Primary.Ammo = ""
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Secondary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.UseHands = true
SWEP.DisableDuplicator = true

local SEQUENCE_VIEW_MODEL_IDLE

function SWEP:SetupDataTables()
	-- Networked accessors
	
	self:NetworkVar("Entity", 0, "OwnedThirdPersonModel")
end

function SWEP:setupViewModelSequence(viewModel)
	-- In multiplayer, this only works serverside.
	if not SEQUENCE_VIEW_MODEL_IDLE then
		SEQUENCE_VIEW_MODEL_IDLE = viewModel:LookupSequence("stickwall_attach2")
		-- can also be "detonator_idle", "throw_throw2", "detonator_draw", "detonator_detonate"
	end
	viewModel:SetSequence(SEQUENCE_VIEW_MODEL_IDLE)
end

do
	-- This code does the actions triggered by +attack & +attack2.
	-- It has more flexibility than SWEP:PrimaryAttack() and SWEP:SecondaryAttack().
	-- In addition to the usual weapon behavior, it can be used when sitting:
	-- - on the seat of the computer (even when not owning the remote)
	-- - on any seat if the remote is the active weapon.
	-- Side effects are only observed if weapons are allowed on the seat of the computer.
	
	local keyToActionMethod = {
		[IN_ATTACK]  = "actionSlideNext",
		[IN_ATTACK2] = "actionSlidePrevious",
	}
	hook.Add("KeyPress", "weapon_teacher_remote_mr:sh", function(ply, key)
		local method = keyToActionMethod[key]
		if method then
			local doAction = false
			local computer
			if SERVER or IsFirstTimePredicted() then
				local on_seat
				computer, on_seat = prop_teacher_computer_mr.getComputerFromPlayer(ply)
				if computer then
					if on_seat then
						doAction = true
					else
						local activeWeapon = ply:GetActiveWeapon()
						if IsValid(activeWeapon) and activeWeapon:GetClass() == computer.RemoteWeaponClass then
							doAction = true
						end
					end
				end
			end
			if doAction then
				computer[method](computer)
			end
		end
	end)
end
