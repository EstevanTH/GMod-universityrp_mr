--[[
Author: Mohamed RACHID - https://steamcommunity.com/profiles/76561198080131369/
License: (copyleft license) Mozilla Public License 2.0 - https://www.mozilla.org/en-US/MPL/2.0/
]]

print("universityrp_mr_spawn")

local WEAK_KEYS = {__mode = "k"}
local WEAK_VALUES = {__mode = "v"}
local INDEX_DEFAULT_EMPTY = {__index = function() return {} end}

universityrp_mr_spawn = universityrp_mr_spawn or {}

local function beforeMapEntitiesCreation()
	universityrp_mr_spawn.duplicatedHammerids = {[0] = true}
	universityrp_mr_spawn.entityToHammerid = setmetatable({}, WEAK_KEYS)
	universityrp_mr_spawn.hammeridToEntity = setmetatable({}, WEAK_VALUES)
	hook.Add("EntityKeyValue", "universityrp_mr_spawn:beforeMapEntitiesCreation", function(entity, key, hammerid)
		if #key == 8 and string.lower(key) == "hammerid" then
			hammerid = tonumber(hammerid)
			if hammerid then
				if hammerid == 0
				or not entity:CreatedByMap() then
					hammerid = nil
				end
			end
		else
			hammerid = nil
		end
		if hammerid then
			if universityrp_mr_spawn.duplicatedHammerids[hammerid] then
				-- duplicated!
			elseif universityrp_mr_spawn.hammeridToEntity[hammerid] then
				-- duplicated!
				universityrp_mr_spawn.duplicatedHammerids[hammerid] = true
				universityrp_mr_spawn.entityToHammerid[universityrp_mr_spawn.hammeridToEntity[hammerid]] = nil
				universityrp_mr_spawn.hammeridToEntity[hammerid] = nil
			else
				universityrp_mr_spawn.entityToHammerid[entity] = hammerid
				universityrp_mr_spawn.hammeridToEntity[hammerid] = entity
			end
		end
	end)
end
hook.Add("PreGamemodeLoaded", "universityrp_mr_spawn", beforeMapEntitiesCreation)
hook.Add("PreCleanupMap", "universityrp_mr_spawn", beforeMapEntitiesCreation)

local linkKeyValuesGetters = setmetatable({}, INDEX_DEFAULT_EMPTY)
local linkKeyValuesSetters = setmetatable(
	{
		-- KeyValues that are for a targetname and their corresponding Lua entity setter:
		["prop_ceiling_projector_mr"] = {
			["projectorscreen"] = "SetProjectorScreen",
		},
		["prop_teacher_computer_mr"] = {
			["projector"] = "SetProjector",
			["seat"] = "SetSeat",
		},
	},
	INDEX_DEFAULT_EMPTY
)
for classname, setters in pairs(linkKeyValuesSetters) do
	linkKeyValuesGetters[classname] = {}
	for key, setter in pairs(setters) do
		local getter = string.match(setter, "^Set(.+)$")
		getter = getter and "Get" .. getter
		linkKeyValuesGetters[classname][key] = getter
	end
end
universityrp_mr_spawn.linkKeyValuesGetters = linkKeyValuesGetters

local spawnInfoFilename = "universityrp_mr_spawn/" .. string.lower(game.GetMap()) .. ".spawn.txt"
function universityrp_mr_spawn.getSpawnInfoFilename()
	return spawnInfoFilename
end

local removeInfoFilename = "universityrp_mr_spawn/" .. string.lower(game.GetMap()) .. ".remove.txt"
function universityrp_mr_spawn.getRemoveInfoFilename()
	return removeInfoFilename
end

local function respawnEquipments()
	-- 1: Read and decode saved information:
	local spawnInfoText
	do
		local spawnInfoFile = file.Open(spawnInfoFilename, "rb", "DATA")
		if spawnInfoFile then
			spawnInfoText = spawnInfoFile:Read(spawnInfoFile:Size())
			spawnInfoFile:Close()
		end
	end
	local entitiesKeyValues = {}
	if spawnInfoText then
		local i = 0
		for entityText in string.gmatch("\x0A" .. spawnInfoText, "\x0D?\x0A({\x0D?\x0A.-\x0D?\x0A})") do
			-- For the pattern, a new line is required before the first entityText.
			i = i + 1
			local entityKeyValues = util.KeyValuesToTable('"entitiesKeyValues[' .. i .. ']"\x0A' .. entityText)
			if entityKeyValues then
				if not entityKeyValues["classname"]
				or not entityKeyValues["origin"]
				or not entityKeyValues["angles"] then
					entityKeyValues = nil
				end
			end
			if entityKeyValues then
				for k, v in pairs(entityKeyValues) do
					entityKeyValues[k] = tostring(v)
				end
				entitiesKeyValues[i] = entityKeyValues
			else
				entitiesKeyValues[i] = false -- to have a contiguous list
				ErrorNoHalt(
					"[universityrp_mr_spawn] Unable to understand the following entity info:\n"
					.. entityText
					.. "\n\n"
				)
			end
		end
	end
	
	-- 2: Make entities and index their fake targetname:
	local entities = {}
	local fakeTargetnamesToEntity = {} -- case-sensitive!
	local collisionGroups = {}
	for i, entityKeyValues in ipairs(entitiesKeyValues) do
		local classname -- case-sensitive!
		local entity
		if entityKeyValues then
			classname = entityKeyValues["classname"]
			entity = ents.Create(classname)
		end
		if IsValid(entity) then
			entities[i] = entity
			entity.universityrp_mr_spawn = true
			for k, v in pairs(entityKeyValues) do
				if k == "classname" then
					-- nothing
				elseif k == "targetname" then
					if #v ~= 0 then
						fakeTargetnamesToEntity[v] = entity
					end
				elseif linkKeyValuesSetters[classname][k] then
					-- done in the next step
				elseif k == "collisiongroup" then
					-- done after Spawn()
					collisionGroups[entity] = tonumber(v)
				else
					entity:SetKeyValue(k, v)
					-- TODO: maybe a few key-values need to be applied through a Lua method instead.
				end
			end
		else
			entities[i] = false -- to have a contiguous list
		end
	end
	
	-- 3: Link and Spawn() entities using their fake targetname (or real targetname if not found):
	for i, entity in ipairs(entities) do
		if entity then
			local entityClass = entity:GetClass()
			for key, targetname2 in pairs(entitiesKeyValues[i]) do
				if #targetname2 ~= 0 then
					local setter = linkKeyValuesSetters[entityClass][key]
					if setter then
						local entity2 = fakeTargetnamesToEntity[targetname2]
						if entity2 then
							entity[setter](entity, entity2)
						else
							entity:SetKeyValue(key, targetname2)
						end
					end
				end
			end
			entity:Spawn()
			if collisionGroups[entity] then
				entity:SetCollisionGroup(collisionGroups[entity])
			end
			if entityClass == "prop_vehicle_prisoner_pod" then
				entity:PhysicsInitStatic(entity:GetSolid())
			end
		end
	end
end

function universityrp_mr_spawn.readRemoveInfoFile()
	local removeInfoItems = {}
	if file.Exists(removeInfoFilename, "DATA") then
		local removeInfoFile = file.Open(removeInfoFilename, "rb", "DATA")
		local removeInfoText
		if removeInfoFile then
			local removeInfoTextLength = removeInfoFile:Size()
			if removeInfoTextLength ~= 0 then
				removeInfoText = removeInfoFile:Read(removeInfoTextLength)
			end
		else
			ErrorNoHalt(
				hl == "fr" and
				"Impossible d'ouvrir le removeInfoFile en lecture\n" or
				"Unable to open the removeInfoFile for read\n"
			)
		end
		if removeInfoFile then
			removeInfoFile:Close()
		end
		if removeInfoText then
			for line in string.gmatch(removeInfoText, "([^\x0D\x0A]+)") do
				local infoItem = {}
				for key, value in string.gmatch(line, "([^\x0D\x0A\t=]+)=([^\x0D\x0A\t]*)") do
					infoItem[key] = value
				end
				infoItem["hammerid"] = tonumber(infoItem["hammerid"])
				infoItem["MapCreationID"] = tonumber(infoItem["MapCreationID"])
				if infoItem["hammerid"] or infoItem["MapCreationID"] then
					removeInfoItems[#removeInfoItems + 1] = infoItem
				end
			end
		end
	end
	return removeInfoItems
end

local function removeMapEntities(withRemoved)
	for _, infoItem in ipairs(universityrp_mr_spawn.readRemoveInfoFile()) do
		local entity
		if infoItem["hammerid"] then
			entity = universityrp_mr_spawn.hammeridToEntity[infoItem["hammerid"]]
		end
		if not entity and infoItem["MapCreationID"] then
			entity = ents.GetMapCreatedEntity(infoItem["MapCreationID"])
		end
		if not entity then
			print(
				"[universityrp_mr_spawn] Could not find this entity to remove:", 
				"hammerid =", infoItem["hammerid"],
				"MapCreationID =", infoItem["MapCreationID"],
				"classname =", infoItem["classname"],
				"model =", infoItem["model"]
			)
		end
		if IsValid(entity) then
			if withRemoved then
				entity.universityrp_mr_spawn_remove = true
			else
				entity:Remove()
			end
		end
	end
end

local function onMapEntitiesSpawned()
	hook.Remove("EntityKeyValue", "universityrp_mr_spawn:beforeMapEntitiesCreation")
	if not universityrp_mr_spawn.noEquipments then
		respawnEquipments()
	end
	universityrp_mr_spawn.currentlyNoEquipments = universityrp_mr_spawn.noEquipments
	universityrp_mr_spawn.noEquipments = nil
	do
		removeMapEntities(universityrp_mr_spawn.withRemoved)
	end
	universityrp_mr_spawn.currentlyWithRemoved = universityrp_mr_spawn.withRemoved
	universityrp_mr_spawn.withRemoved = nil
end
hook.Add("InitPostEntity", "universityrp_mr_spawn", onMapEntitiesSpawned)
hook.Add("PostCleanupMap", "universityrp_mr_spawn", onMapEntitiesSpawned)

local function avoidPickup(ply, entity)
	-- Prevent grabbing saved equipments:
	if entity.universityrp_mr_spawn then
		return false
	end
end
hook.Add("AllowPlayerPickup", "universityrp_mr_spawn", avoidPickup)
hook.Add("GravGunPickupAllowed", "universityrp_mr_spawn", avoidPickup)
hook.Add("PhysgunPickup", "universityrp_mr_spawn", avoidPickup)
