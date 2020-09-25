--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("tool.universityrp_mr_spawn")

universityrp_mr_spawn = universityrp_mr_spawn or {}

TOOL.Category = "University RP"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.Information = {
	{name = "mode_add", op = 0},
	{name = "mode_remove", op = 1},
	{name = "reload"},
	{name = "left_add", op = 0},
	{name = "right_add", op = 0},
	{name = "left_remove", op = 1},
	{name = "right_remove", op = 1},
}


local hl = GetConVar("gmod_language"):GetString()
TOOL.Name = (
	hl == "fr" and
	"Équipements persistants, gestionnaire (MR)" or
	"Persistent equipments manager (MR)"
)
if CLIENT then
	language.Add("tool.universityrp_mr_spawn.name", TOOL.Name)
	if hl == "fr" then
		language.Add("tool.universityrp_mr_spawn.desc", "Mémorise les équipements University RP / Retire des entités de la carte")
		language.Add("tool.universityrp_mr_spawn.mode_add", "Mode : Enregistrer équipements")
		language.Add("tool.universityrp_mr_spawn.mode_remove", "Mode : Retirer entités de la carte")
		language.Add("tool.universityrp_mr_spawn.reload", "Rafraîchir les informations")
		language.Add("tool.universityrp_mr_spawn.left_add", "Rendre l'équipement persistant")
		language.Add("tool.universityrp_mr_spawn.right_add", "Ne plus rendre l'équipement persistant")
		language.Add("tool.universityrp_mr_spawn.left_remove", "Supprimer l'entité de façon permanente")
		language.Add("tool.universityrp_mr_spawn.right_remove", "Annuler la suppression permanente de l'entité")
	else
		language.Add("tool.universityrp_mr_spawn.desc", "Memorizes University RP equipments / Remove map entities")
		language.Add("tool.universityrp_mr_spawn.mode_add", "Mode: Save equipments")
		language.Add("tool.universityrp_mr_spawn.mode_remove", "Mode: Remove map entities")
		language.Add("tool.universityrp_mr_spawn.reload", "Refresh the information")
		language.Add("tool.universityrp_mr_spawn.left_add", "Make the equipment persistent")
		language.Add("tool.universityrp_mr_spawn.right_add", "Do not make the equipment persistent anymore")
		language.Add("tool.universityrp_mr_spawn.left_remove", "Delete the entity permanently")
		language.Add("tool.universityrp_mr_spawn.right_remove", "Cancel the permanent deletion of the entity")
	end
end


local MESSAGE_FORBIDDEN_NO_EQUIPMENTS = (
	hl == "fr" and
	"Interdit : la carte a été nettoyée avec exclusion des équipements persistants !" or
	"Forbidden: the map has been cleaned up with persistent equipments exclusion!"
)
local MESSAGE_SAVE_SUCCESS = (
	hl == "fr" and
	"Enregistrement effectué !" or
	"Save done!"
)


local WEAK_KEYS = {__mode = "k"}
local INDEX_DEFAULT_EMPTY = {__index = function() return {} end}


local updateEntitiesToClients
local updateEntitiesFromServer
local savedEquipments -- CLIENT only
local entitiesToRemove -- CLIENT only
if SERVER then
	function updateEntitiesToClients()
		local recipients = {}
		for _, ply in ipairs(player.GetAll()) do
			local toolGun = ply:GetActiveWeapon()
			if IsValid(toolGun) and toolGun:GetClass() == "gmod_tool" then
				if toolGun:GetMode() == "universityrp_mr_spawn" then
					recipients[#recipients + 1] = ply
				end
			end
		end
		if #recipients ~= 0 then
			net.Start("tool.universityrp_mr_spawn")
			do
				local savedEquipments = {}
				local entitiesToRemove = {}
				for _, entity in ipairs(ents.GetAll()) do
					if entity.universityrp_mr_spawn then
						savedEquipments[#savedEquipments + 1] = entity
					elseif entity.universityrp_mr_spawn_remove then
						entitiesToRemove[#entitiesToRemove + 1] = entity
					end
				end
				net.WriteUInt(#savedEquipments, 16)
				for i = 1, #savedEquipments do
					net.WriteEntity(savedEquipments[i])
				end
				net.WriteUInt(#entitiesToRemove, 16)
				for i = 1, #entitiesToRemove do
					net.WriteEntity(entitiesToRemove[i])
				end
				net.WriteBool(universityrp_mr_spawn.currentlyNoEquipments)
				net.WriteBool(universityrp_mr_spawn.currentlyWithRemoved)
			end
			net.Send(recipients)
		end
	end
	hook.Add("PostCleanupMap", "tool.universityrp_mr_spawn:sv", function()
		timer.Simple(0., updateEntitiesToClients)
	end)
	timer.Simple(0., updateEntitiesToClients) -- for Lua refresh
else
	savedEquipments = {}
	entitiesToRemove = {}
	function updateEntitiesFromServer()
		savedEquipments = setmetatable({}, WEAK_KEYS)
		for i = 1, net.ReadUInt(16) do
			savedEquipments[net.ReadEntity()] = true
		end
		entitiesToRemove = setmetatable({}, WEAK_KEYS)
		for i = 1, net.ReadUInt(16) do
			entitiesToRemove[net.ReadEntity()] = true
		end
		universityrp_mr_spawn.currentlyNoEquipments = net.ReadBool()
		universityrp_mr_spawn.currentlyWithRemoved = net.ReadBool()
	end
end


local MODE_SAVE_EQUIPMENTS = 0
local MODE_REMOVE_ENTITIES = 1


local universityClasses = {
	["prop_ceiling_projector_mr"] = true,
	["prop_projector_screen_mr"] = true,
	["prop_teacher_computer_mr"] = true,
	["prop_vehicle_prisoner_pod"] = true,
	["prop_agenda_global_mr"] = true,
	["prop_agenda_room_mr"] = true,
}
local basicPropClasses = {
	-- Classes that are converted to prop_dynamic:
	["prop_dynamic"] = true,
	["prop_dynamic_override"] = true,
	["prop_physics"] = true,
	["prop_physics_multiplayer"] = true,
	["prop_physics_override"] = true,
	["prop_teacher_desk_mr"] = true, -- treated as
}


local function setEquipmentSaveStatus(entity, status)
	-- There is a weird bug with the trace coverage when selecting a computer included with a desk.
	-- -> Place yourself on top of the computer and attack it on the top.
	if not universityrp_mr_spawn.currentlyNoEquipments then
		local entityClass = entity:GetClass()
		if universityClasses[entityClass] or basicPropClasses[entityClass] then
			if CLIENT or not entity:CreatedByMap() then
				if SERVER then
					entity.universityrp_mr_spawn = status
					if status then
						-- Make the physics as it would be when restored:
						entity.staticPhysics = true
						entity:PhysicsInitStatic(entity:GetSolid())
					else
						-- Allow proper move again:
						entity.staticPhysics = nil
						entity:PhysicsInit(entity:GetSolid())
						local phys = entity:GetPhysicsObject()
						if IsValid(phys) then
							phys:EnableMotion(false)
						end
					end
					updateEntitiesToClients()
				end
				return true
			end
		end
	else -- safety
		if CLIENT and IsFirstTimePredicted() then
			LocalPlayer():ChatPrint(MESSAGE_FORBIDDEN_NO_EQUIPMENTS)
		end
	end
	return false
end


local function setRemovedStatus(entity, status)
	if CLIENT or entity:CreatedByMap() then
		if SERVER then
			entity.universityrp_mr_spawn_remove = status
			updateEntitiesToClients()
		end
		return true
	end
	return false
end


function TOOL:LeftClick(trace)
	if self:GetOwner():IsSuperAdmin() then
		local entity = trace.Entity
		if IsValid(entity) then
			local operation = self:GetOperation()
			if operation == MODE_SAVE_EQUIPMENTS then
				if setEquipmentSaveStatus(entity, true) then
					return true
				end
			elseif operation == MODE_REMOVE_ENTITIES then
				if setRemovedStatus(entity, true) then
					return true
				end
			end
		end
	end
	return false
end


function TOOL:RightClick(trace)
	if self:GetOwner():IsSuperAdmin() then
		local entity = trace.Entity
		if IsValid(entity) then
			local operation = self:GetOperation()
			if operation == MODE_SAVE_EQUIPMENTS then
				if setEquipmentSaveStatus(entity, nil) then
					return true
				end
			elseif operation == MODE_REMOVE_ENTITIES then
				if setRemovedStatus(entity, nil) then
					return true
				end
			end
		end
	end
	return false
end


local ACTION_ID_SAVE_EQUIPMENTS = 1
local ACTION_ID_SAVE_REMOVED = 5
local ACTION_ID_RESET_MAP = 2
local ACTION_ID_MODE_SAVE_EQUIPMENTS = 3
local ACTION_ID_MODE_REMOVE_ENTITIES = 4


if SERVER then
	util.AddNetworkString("tool.universityrp_mr_spawn")
	
	local function setToolMode(ply, mode)
		local tool
		local toolGun = ply:GetWeapon("gmod_tool")
		if IsValid(toolGun) then
			tool = toolGun:GetToolObject("universityrp_mr_spawn")
			ply:SelectWeapon("gmod_tool")
		end
		if tool then
			tool:SetOperation(mode)
		end
	end
	
	local spawnInfoFilename
	local function fakeTargetnameFor(equipment)
		return "universityrp_mr_" .. equipment:EntIndex()
	end
	local function saveEquipments(ply)
		if not spawnInfoFilename then
			spawnInfoFilename = universityrp_mr_spawn.getSpawnInfoFilename()
		end
		if universityrp_mr_spawn.currentlyNoEquipments then -- safety
			ply:ChatPrint(MESSAGE_FORBIDDEN_NO_EQUIPMENTS)
			return false
		end
		file.CreateDir("universityrp_mr_spawn")
		local spawnInfoFile = file.Open(spawnInfoFilename, "w", "DATA")
		if not spawnInfoFile then
			ply:ChatPrint(
				hl == "fr" and
				"Impossible d'ouvrir le spawnInfoFile en écriture" or
				"Unable to open the spawnInfoFile for write"
			)
			return false
		end
		local linkKeyValuesGetters = universityrp_mr_spawn.linkKeyValuesGetters
		spawnInfoFile:Write("// This file uses the same syntax as the LUMP_ENTITIES of .bsp files, with which it is compatible.\n")
		spawnInfoFile:Write("// The targetnames are actually fake, except when a linked equipment's targetname is not found.\n")
		spawnInfoFile:Write("// The targetnames contain the EntIndex that the equipment had when saving.\n")
		spawnInfoFile:Write("// \"gmod_allowphysgun\" only works in map entities. It does not work here.\n")
		local persistentEquipmentsOrdered = {}
		local persistentEquipments = {}
		for i, equipment in ipairs(ents.GetAll()) do
			if equipment.universityrp_mr_spawn then
				persistentEquipmentsOrdered[#persistentEquipmentsOrdered + 1] = equipment
				persistentEquipments[equipment] = true
			end
		end
		for i, equipment in ipairs(persistentEquipmentsOrdered) do
			if equipment.universityrp_mr_spawn then
				local equipmentClass = equipment:GetClass()
				spawnInfoFile:Write('{\n')
				if equipmentClass == "prop_vehicle_prisoner_pod" then
					spawnInfoFile:Write('"classname" "prop_vehicle_prisoner_pod"\n')
					spawnInfoFile:Write(string.format('"targetname" "%s"\n', fakeTargetnameFor(equipment)))
					spawnInfoFile:Write('"vehiclescript" "scripts/vehicles/prisoner_pod.txt"\n')
					spawnInfoFile:Write('"limitview" "0"\n')
				elseif universityClasses[equipmentClass] then
					spawnInfoFile:Write(string.format('"classname" "%s"\n', equipmentClass))
					spawnInfoFile:Write(string.format('"targetname" "%s"\n', fakeTargetnameFor(equipment)))
					for key, getter in pairs(linkKeyValuesGetters[equipmentClass]) do
						local equipment2 = equipment[getter](equipment)
						if persistentEquipments[equipment2] then -- always valid
							spawnInfoFile:Write(string.format(
								'"%s" "%s"\n',
								key,
								fakeTargetnameFor(equipment2)
							))
						end
					end
				elseif basicPropClasses[equipmentClass] then
					spawnInfoFile:Write('"classname" "prop_dynamic"\n')
					spawnInfoFile:Write(string.format('"skin" "%u"\n', equipment:GetSkin()))
					spawnInfoFile:Write(string.format('"solid" "%u"\n', equipment:GetSolid()))
				end
				spawnInfoFile:Write(string.format('"model" "%s"\n', equipment:GetModel()))
				spawnInfoFile:Write(string.format('"origin" "%s"\n', equipment:GetPos()))
				spawnInfoFile:Write(string.format('"angles" "%s"\n', equipment:GetAngles()))
				spawnInfoFile:Write('"gmod_allowphysgun" "0"\n')
				spawnInfoFile:Write(string.format('"CollisionGroup" "%u"\n', equipment:GetCollisionGroup()))
				local equipmentColor = equipment:GetColor()
				spawnInfoFile:Write(string.format(
					'"rendercolor" "%u %u %u"\n',
					equipmentColor.r,
					equipmentColor.g,
					equipmentColor.b
				))
				spawnInfoFile:Write(string.format('"renderamt" "%u"\n', equipmentColor.a))
				spawnInfoFile:Write(string.format('"rendermode" "%u"\n', equipment:GetRenderMode()))
				spawnInfoFile:Write(string.format('"renderfx" "%u"\n', equipment:GetRenderFX()))
				spawnInfoFile:Write('}\n')
			end
		end
		spawnInfoFile:Close()
		ServerLog("[universityrp_mr_spawn] " .. tostring(ply) .. " saved persistent equipments.\n")
		ply:ChatPrint(MESSAGE_SAVE_SUCCESS)
		return true
	end
	
	local removeInfoFilename
	local function saveRemoved_sort(infoItem1, infoItem2)
		if infoItem1["hammerid"] and infoItem2["hammerid"] then
			return (infoItem1["hammerid"] < infoItem2["hammerid"])
		elseif infoItem1["hammerid"] then
			return true
		elseif infoItem2["hammerid"] then
			return false
		else
			return (infoItem1["MapCreationID"] < infoItem2["MapCreationID"])
		end
	end
	local function saveRemoved(ply)
		if not removeInfoFilename then
			removeInfoFilename = universityrp_mr_spawn.getRemoveInfoFilename()
		end
		-- Read current info:
		local removeInfoItems = universityrp_mr_spawn.readRemoveInfoFile()
		-- Append new info & remove old / duplicates / invalid:
		do
			-- List items from the existing file & remove invalid ones:
			local indexesOfHammerid = setmetatable({}, INDEX_DEFAULT_EMPTY)
			local indexesOfMapCreationID = setmetatable({}, INDEX_DEFAULT_EMPTY)
			for i, infoItem in ipairs(removeInfoItems) do
				if infoItem["hammerid"] then
					indexesOfHammerid[infoItem["hammerid"]] = indexesOfHammerid[infoItem["hammerid"]] or {}
					indexesOfHammerid[infoItem["hammerid"]][i] = true
				end
				if infoItem["MapCreationID"] then
					indexesOfMapCreationID[infoItem["MapCreationID"]] = indexesOfMapCreationID[infoItem["MapCreationID"]] or {}
					indexesOfMapCreationID[infoItem["MapCreationID"]][i] = true
				end
			end
			-- Append currently present entities to remove & remove their duplicates:
			for i, entity in ipairs(ents.GetAll()) do
				if entity.universityrp_mr_spawn_remove then
					local mapCreationId = entity:MapCreationID()
					local infoItem = {
						["hammerid"] = universityrp_mr_spawn.entityToHammerid[entity],
						["MapCreationID"] = mapCreationId,
						["classname"] = entity:GetClass(),
						["model"] = entity:GetModel(),
					}
					if infoItem["hammerid"] then
						for indexToRemove in pairs(indexesOfHammerid[infoItem["hammerid"]]) do
							removeInfoItems[indexToRemove] = false
						end
					end
					do
						for indexToRemove in pairs(indexesOfMapCreationID[mapCreationId]) do
							removeInfoItems[indexToRemove] = false
						end
					end
					removeInfoItems[#removeInfoItems + 1] = infoItem
				end
			end
			-- Remove removed items:
			do
				local removeInfoItems_ = removeInfoItems
				removeInfoItems = {}
				for _, infoItem in ipairs(removeInfoItems_) do
					if infoItem then
						removeInfoItems[#removeInfoItems + 1] = infoItem
					end
				end
			end
			-- Sort items:
			table.sort(removeInfoItems, saveRemoved_sort)
		end
		-- Save:
		file.CreateDir("universityrp_mr_spawn")
		local removeInfoFile = file.Open(removeInfoFilename, "w", "DATA")
		if not removeInfoFile then
			ply:ChatPrint(
				hl == "fr" and
				"Impossible d'ouvrir le removeInfoFile en écriture" or
				"Unable to open the removeInfoFile for write"
			)
			return false
		end
		for i, infoItem in ipairs(removeInfoItems) do
			local success, message = pcall(function()
				if infoItem["hammerid"] then
					removeInfoFile:Write(string.format("hammerid=%u\t", infoItem["hammerid"]))
				else
					removeInfoFile:Write(string.format("MapCreationID=%d\t", infoItem["MapCreationID"]))
				end
				removeInfoFile:Write(string.format("classname=%s\t", infoItem["classname"]))
				removeInfoFile:Write(string.format("model=%s\n", infoItem["model"] or ""))
			end)
			if not success then
				ErrorNoHalt(message .. "\n")
			end
		end
		removeInfoFile:Close()
		ServerLog("[universityrp_mr_spawn] " .. tostring(ply) .. " saved removed entities.\n")
		ply:ChatPrint(MESSAGE_SAVE_SUCCESS)
		return false
	end
	
	local function resetMap(ply, noEquipments, withRemoved)
		if noEquipments then
			universityrp_mr_spawn.noEquipments = true
		end
		if withRemoved then
			universityrp_mr_spawn.withRemoved = true
		end
		game.CleanUpMap()
		ServerLog("[universityrp_mr_spawn] " .. tostring(ply) .. " cleaned up the map.\n")
		ply:ChatPrint(
			hl == "fr" and
			"Vous avez nettoyé la carte." or
			"You have cleaned up the map."
		)
	end
	
	net.Receive("tool.universityrp_mr_spawn", function(len, ply)
		local actionId = net.ReadUInt(8)
		if actionId == ACTION_ID_MODE_SAVE_EQUIPMENTS then
			setToolMode(ply, MODE_SAVE_EQUIPMENTS)
		elseif actionId == ACTION_ID_MODE_REMOVE_ENTITIES then
			setToolMode(ply, MODE_REMOVE_ENTITIES)
		elseif ply:IsSuperAdmin() then
			if actionId == ACTION_ID_SAVE_EQUIPMENTS then
				saveEquipments(ply)
			elseif actionId == ACTION_ID_SAVE_REMOVED then
				saveRemoved(ply)
			elseif actionId == ACTION_ID_RESET_MAP then
				local noEquipments = net.ReadBool()
				local withRemoved = net.ReadBool()
				resetMap(ply, noEquipments, withRemoved)
			end
		else
			ply:ChatPrint(
				hl == "fr" and
				"Accès refusé" or
				"Access denied"
			)
		end
	end)
else
	net.Receive("tool.universityrp_mr_spawn", function()
		updateEntitiesFromServer()
	end)
end


function TOOL:Reload(trace)
	if SERVER then
		updateEntitiesToClients()
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
	local function makeWireframeColor(colorName, colorAsText)
		return CreateMaterial(
			"tool.universityrp_mr_spawn:wireframe:" .. colorName,
			"Wireframe",
			{
				["$model"] = 1,
				["$nocull"] = 1,
				["$ignorez"] = 1,
				["$colorfix"] = colorAsText,
				["proxies"] = {
					["equals"] = {
						["srcVar1"] = "$colorfix",
						["resultVar"] = "$color",
					},
				},
			}
		)
	end
	local wireframeGreen
	local wireframeRed
	
	function TOOL:DrawHUD()
		local highlighted = {}
		local wireframeColor
		do
			local entities
			local operation = self:GetOperation()
			if operation == MODE_SAVE_EQUIPMENTS then
				entities = savedEquipments
				if not wireframeGreen then
					wireframeGreen = makeWireframeColor("green", "{63 255 63}")
				end
				wireframeColor = wireframeGreen
			elseif operation == MODE_REMOVE_ENTITIES then
				entities = entitiesToRemove
				if not wireframeRed then
					wireframeRed = makeWireframeColor("red", "{255 63 63}")
				end
				wireframeColor = wireframeRed
			end
			if entities then
				for equipment in pairs(entities) do
					if IsValid(equipment) and not equipment:IsDormant() then
						highlighted[equipment] = true
					end
				end
			end
		end
		if wireframeColor then
			render.ModelMaterialOverride(wireframeColor)
			render.BrushMaterialOverride(wireframeColor)
			cam.Start3D()
			for equipment in pairs(highlighted) do
				equipment:DrawModel()
			end
			cam.End3D()
			render.ModelMaterialOverride(nil)
			render.BrushMaterialOverride(nil)
		end
	end
	
	function TOOL.BuildCPanel(panel)
		panel:SetName(
			hl == "fr" and
			"Gestionnaire d'équipements persistants (MR)" or
			"Persistent equipments manager (MR)"
		)
		panel:Help(language.GetPhrase("tool.universityrp_mr_spawn.desc"))
		panel:Help(
			hl == "fr" and
			"Sélection du mode :" or
			"Mode selection:"
		):SetFont("DermaDefaultBold")
		local btnModeSaveEquipments = panel:Button(
			hl == "fr" and
			"Mode : Enregistrer équipements" or
			"Mode: Save equipments"
		); do
			btnModeSaveEquipments.DoClick = function()
				net.Start("tool.universityrp_mr_spawn")
				net.WriteUInt(ACTION_ID_MODE_SAVE_EQUIPMENTS, 8)
				net.SendToServer()
			end
		end
		local btnModeResetNoRemove = panel:Button(
			hl == "fr" and
			"Mode : Retirer entités de la carte" or
			"Mode: Remove map entities"
		); do
			btnModeResetNoRemove.DoClick = function()
				net.Start("tool.universityrp_mr_spawn")
				net.WriteUInt(ACTION_ID_MODE_REMOVE_ENTITIES, 8)
				net.SendToServer()
			end
		end
		panel:Help(
			hl == "fr" and
			"Enregistrement :" or
			"Save:"
		):SetFont("DermaDefaultBold")
		local btnSaveEquipments = panel:Button(
			hl == "fr" and
			"Enregistrer équipements persistants" or
			"Save persistent equipments"
		); do
			btnSaveEquipments.DoClick = function()
				net.Start("tool.universityrp_mr_spawn")
				net.WriteUInt(ACTION_ID_SAVE_EQUIPMENTS, 8)
				net.SendToServer()
			end
			btnSaveEquipments:SetTooltip(
				hl == "fr" and
				"ATTENTION\nCeci enregistre uniquement les équipements qui sont actuellement présents.\nLes équipements persistants non présents sont éliminés.\nLes équipements sont enregistrés comme ils sont actuellement (position, et caetera)." or
				"WARNING\nThis only saves equipments that are currently present.\bNon-present persistent equipments are suppressed.\nEquipments are saved as they currently are (position, et caetera)."
			)
		end
		local btnSaveRemoved = panel:Button(
			hl == "fr" and
			"Enregistrer entités supprimées" or
			"Save removed entities"
		); do
			btnSaveRemoved.DoClick = function()
				net.Start("tool.universityrp_mr_spawn")
				net.WriteUInt(ACTION_ID_SAVE_REMOVED, 8)
				net.SendToServer()
			end
			btnSaveRemoved:SetTooltip(
				hl == "fr" and
				"Ceci ajoute les entités à supprimer à la liste actuelle." or
				"This adds entities to remove to the current list."
			)
		end
		panel:Help(
			hl == "fr" and
			"Nettoyage de la carte :" or
			"Map cleanup:"
		):SetFont("DermaDefaultBold")
		local cbNoEquipments = panel:CheckBox(
			hl == "fr" and
			"Sans équipements persistants" or
			"Without persistent equipments"
		)
		local cbWithRemoved = panel:CheckBox(
			hl == "fr" and
			"Avec entités supprimées" or
			"With removed entities"
		)
		local btnResetMap = panel:Button(
			hl == "fr" and
			"Nettoyer la carte" or
			"Cleanup the map"
		); do
			btnResetMap.DoClick = function()
				net.Start("tool.universityrp_mr_spawn")
				net.WriteUInt(ACTION_ID_RESET_MAP, 8)
				net.WriteBool(cbNoEquipments:GetChecked())
				net.WriteBool(cbWithRemoved:GetChecked())
				net.SendToServer()
			end
		end
	end
end
