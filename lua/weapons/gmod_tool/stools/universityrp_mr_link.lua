--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

TOOL.Category = "University RP"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{name = "reload"},
	{name = "left_0", stage = 0},
	{name = "left_1", stage = 1},
	{name = "right_0", stage = 0},
}


local hl = GetConVar("gmod_language"):GetString()
TOOL.Name = (
	hl == "fr" and
	"Relieur d'équipements (MR)" or
	"Equipments linker (MR)"
)
if CLIENT then
	language.Add("tool.universityrp_mr_link.name", TOOL.Name)
	if hl == "fr" then
		language.Add("tool.universityrp_mr_link.desc", "Relie ensemble les équipements University RP")
		language.Add("tool.universityrp_mr_link.0", "Attaquez un équipement à relier")
		language.Add("tool.universityrp_mr_link.1", "Attaquez un équipement à associer au premier")
		language.Add("tool.universityrp_mr_link.reload", "Annuler l'opération en cours & rafraîchir les informations")
		language.Add("tool.universityrp_mr_link.left_0", "Sélectionner un équipement à relier")
		language.Add("tool.universityrp_mr_link.left_1", "Sélectionner un équipement à relier avec")
		language.Add("tool.universityrp_mr_link.right_0", "Déconnecter les liaisons à cet équipement")
	else
		language.Add("tool.universityrp_mr_link.desc", "Link together University RP equipments")
		language.Add("tool.universityrp_mr_link.0", "Attack an equipment to link")
		language.Add("tool.universityrp_mr_link.1", "Attack an equipment to associate with the first one")
		language.Add("tool.universityrp_mr_link.reload", "Cancel the current operation & refresh the information")
		language.Add("tool.universityrp_mr_link.left_0", "Select an equipment to link")
		language.Add("tool.universityrp_mr_link.left_1", "Select an equipment to link with")
		language.Add("tool.universityrp_mr_link.right_0", "Disconnect the links to this equipment")
	end
end


local WEAK_KEYS = {__mode = "k"}


local registeredEntityClasses = {}
local entityLinkGetters = setmetatable({}, {__index = function() return {} end})
local entityLinkSetters = {
	["prop_teacher_computer_mr"] = {
		["prop_ceiling_projector_mr"] = "SetProjector",
		["prop_vehicle_prisoner_pod"] = "SetSeat",
	},
	["prop_ceiling_projector_mr"] = {
		["prop_projector_screen_mr"] = "SetProjectorScreen",
	},
}
for entityClass1, setters in pairs(entityLinkSetters) do
	registeredEntityClasses[entityClass1] = true
	entityLinkGetters[entityClass1] = {}
	for entityClass2, setter in pairs(setters) do
		registeredEntityClasses[entityClass2] = true
		local getter = string.match(setter, "^Set(.+)$")
		getter = getter and "Get" .. getter
		entityLinkGetters[entityClass1][entityClass2] = getter
	end
end


function TOOL:LeftClick(trace)
	-- Link entities together:
	
	if self:GetOwner():IsSuperAdmin() then
		local entity = trace.Entity
		if IsValid(entity) and registeredEntityClasses[entity:GetClass()] then
			local stage = self:GetStage()
			if stage == 0 then
				self.equipment1 = entity
				if SERVER then
					self:SetStage(1)
				end
				return true
			elseif stage == 1 then
				if self.equipment1 then
					local equipment1
					local equipment2
					local setter
					for _, equipments in ipairs({{self.equipment1, entity}, {entity, self.equipment1}}) do
						local equipment1Class = equipments[1]:GetClass()
						local equipment2Class = equipments[2]:GetClass()
						setter = entityLinkSetters[equipment1Class] and entityLinkSetters[equipment1Class][equipment2Class]
						if setter then
							equipment1 = equipments[1]
							equipment2 = equipments[2]
							break
						end
					end
					if setter then
						if SERVER then
							equipment1[setter](equipment1, equipment2)
						end
						self:Reload(trace)
						return true
					end
				elseif CLIENT then
					-- The action is probably already done, so self.equipment1 is erased.
					-- This means that the animation can keep going.
					return true
				end
			else
				self:Reload(trace)
			end
		end
	end
	return false
end


function TOOL:RightClick(trace)
	-- Disconnect linked equipments (direct lookup only) from the selected equipment:
	
	if self:GetOwner():IsSuperAdmin() then
		local stage = self:GetStage()
		if stage == 0 then
			local entity = trace.Entity
			local setters = entityLinkSetters[entity:GetClass()]
			if setters then
				if SERVER then
					for otherClass, setter in pairs(setters) do
						entity[setter](entity, nil)
					end
				end
				return true
			end
		end
	end
	return false
end


local equipments -- only for CLIENT
local refreshEquipments
if CLIENT then
	function refreshEquipments()
		equipments = setmetatable({}, WEAK_KEYS)
		for _, ent in ipairs(ents.GetAll()) do
			if IsValid(ent) and registeredEntityClasses[ent:GetClass()] then
				equipments[ent] = true
			end
		end
	end
end


function TOOL:Reload(trace)
	-- Reset tool:
	
	self.equipment1 = nil
	if SERVER then
		self:SetStage(0)
	else
		equipments = nil
	end
	return true
end


function TOOL:Think()
	-- nothing
end


function TOOL:Deploy()
	self:Reload(nil)
end


if CLIENT then
	-- Actual values:
	local lineThickness = ScrH() * 0.0041666666666667 -- 3px for ScrH() = 720px
	local spotSize = ScrH() * 0.0125 -- 9px for ScrH() = 720px
	
	-- Values for code:
	lineThickness = math.floor(lineThickness / 2)
	local spotCorner = math.floor(spotSize / 2)
	
	local equipmentsInPvsPrev = nil
	
	function TOOL:DrawHUD()
		-- Show links:
		
		local equipmentsInPvs = setmetatable({}, WEAK_KEYS)
		if not equipments then
			refreshEquipments()
			equipmentsInPvsPrev = nil -- avoid automatic refresh
		end
		local equipmentSpots = {}
		draw.NoTexture()
		surface.SetDrawColor(63, 63, 255, 255)
		for equipment1 in pairs(equipments) do
			local anyLinkInPvs = false
			if IsValid(equipment1) then
				if not equipment1:IsDormant() then
					equipmentsInPvs[equipment1] = true
					anyLinkInPvs = true
				end
				local equipment1ToScreen = equipment1:GetPos():ToScreen()
				for equipment2Class, getter in pairs(entityLinkGetters[equipment1:GetClass()]) do
					local equipment2 = equipment1[getter](equipment1)
					if IsValid(equipment2) then
						if not anyLinkInPvs and not equipment2:IsDormant() then
							anyLinkInPvs = true
						end
						if anyLinkInPvs then
							local equipment2ToScreen = equipment2:GetPos():ToScreen()
							if equipment1ToScreen.visible or equipment2ToScreen.visible then
								-- Draw a line if at least 1 spot is visible.
								-- Its direction can be wrong when visible ~= true for both.
								if math.abs(equipment1ToScreen.x - equipment2ToScreen.x)
								 > math.abs(equipment1ToScreen.y - equipment2ToScreen.y) then
									for yOffset = -lineThickness, lineThickness, 1 do
										surface.DrawLine(
											equipment1ToScreen.x, equipment1ToScreen.y + yOffset,
											equipment2ToScreen.x, equipment2ToScreen.y + yOffset
										)
									end
								else
									for xOffset = -lineThickness, lineThickness, 1 do
										surface.DrawLine(
											equipment1ToScreen.x + xOffset, equipment1ToScreen.y,
											equipment2ToScreen.x + xOffset, equipment2ToScreen.y
										)
									end
								end
							end
							if equipment2ToScreen.visible then
								equipmentSpots[equipment2] = equipment2ToScreen
							end
						end
					end
				end
				if anyLinkInPvs then
					if equipment1ToScreen.visible then
						equipmentSpots[equipment1] = equipment1ToScreen
					end
				end
			end
		end
		for equipment, equipmentToScreen in pairs(equipmentSpots) do
			surface.DrawTexturedRect(
				equipmentToScreen.x - spotCorner, equipmentToScreen.y - spotCorner,
				spotSize, spotSize
			)
		end
		if equipmentsInPvsPrev then
			-- Safety: automatically refresh if any equipment was not in PVS:
			for equipment in pairs(equipmentsInPvs) do
				if not equipmentsInPvsPrev[equipment] then
					refreshEquipments()
					break
				end
			end
		end
		equipmentsInPvsPrev = equipmentsInPvs
	end
	
	function TOOL.BuildCPanel(panel)
		panel:Help(language.GetPhrase("tool.universityrp_mr_link.desc"))
		panel:Help(
			hl == "fr" and
			[[Vous devez relier ensemble :
- le siège avec l'ordinateur
- (si présent) le projecteur avec l'ordinateur
- (si présent) l'écran de projection avec le projecteur]] or
			[[You must link together:
- the seat with the computer
- (if present) the projector with the computer
- (if present) the projector screen with the projector]]
		)
	end
end
