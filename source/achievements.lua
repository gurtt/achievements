-- Achievements for Playdate

---Path where the achievements data for the game is saved.
---@type string
local PRIVATE_ACHIEVEMENTS_PATH = "achievements.json"

---The current achievements data schema version.
---@type number
local CURRENT_SCHEMA_VERSION = 2

---The URL for the current schema definition.
---@type string
local SCHEMA_URL = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json"

---@diagnostic disable-next-line: lowercase-global
achievements = {}

---@class (exact) Achievement
---@field id string A unique ID for the achievement.
---@field name string The user-facing name of the achievement.
---@field lockedDescription string The user-facing description of the requirements to unlock the achievement. Displayed when the player hasn't unlocked the achievement.
---@field unlockedDescription string The user-facing description of the requirements that unlocked the achievement. Displayed when the player hasn't unlocked the achievement.
---@field value? boolean|integer The progress of the achievement.
---@field maxValue? number For achievements where `value` is a number, the value needed to consider the achievement granted.

---@class (exact) AchievementDefinitions
---@field achievements Achievement[]

local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == "table" then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

---Get the specified achievement.
---@param achievementID string The ID of the achievement to get.
---@return Achievement # The achievement.
function achievements.get(achievementID)
	if type(achievementID) ~= "string" then
		error('Achievement ID "' .. achievementID .. '" is invalid', 2)
	end

	local ach = achievements.kAchievements[achievementID]

	if not ach then
		error('No achievement with ID "' .. achievementID .. '"', 2)
	end

	return ach
end

---Set the specified achievement to the given value.
---@param achievementID string The ID of the achievement to change.
---@param value boolean|number The value to set the achievement to.
function achievements.set(achievementID, value)
	local ach = achievements.get(achievementID)

	if ach.maxValue then
		if type(value) ~= "number" then
			error('Invalid value type for achievement "' .. ach.id .. '" (expected number)', 2)
		end

		if value < 0 then
			error("Invalid numeric value (expected >= 0)", 2)
		end

		if value % 1 ~= 0 then
			error("Invalid numeric value (expected integer)", 2)
		end

		ach.value = math.min(value, ach.maxValue)
	else
		if type(value) ~= "boolean" then
			error('Invalid value type for achievement "' .. ach.id .. '" (expected boolean)', 2)
		end

		ach.value = value
	end
end

---Migrate data from an old schema version to the current version.
---@param data any The decoded JSON data of the old version.
---@param version any The determined version of `data`.
---@return any
local function migrate(data, version)
	local achievements = {}

	-- https://raw.githubusercontent.com/gurtt/pd-achievements/v1.0.0/schema/achievements-v1.schema.json
	if version == 1 then
		for i, ach in pairs(data.achievements) do
			achievements[i] = {
				id = ach.id,
				name = ach.id,
				lockedDescription = ach.id,
				unlockedDescription = ach.id,
				value = ach.isGranted or false,
			}
		end
	end

	return achievements
end

---Loads saved achievement data for the game.
---@param minimumSchemaVersion? number The earliest version of the achievements data schema to try migrating from. If unspecified, migration is disabled.
local function load(minimumSchemaVersion)
	if minimumSchemaVersion and type(minimumSchemaVersion) ~= "number" then
		error("Invalid minimum schema number type " .. type(minimumSchemaVersion) .. " (expected number)")
	end

	local minimumVersion = minimumSchemaVersion or CURRENT_SCHEMA_VERSION

	if minimumVersion > CURRENT_SCHEMA_VERSION then
		error(
			"Minimum schema version is newer than the current schema version ("
				.. CURRENT_SCHEMA_VERSION
				.. "). Do you need to update your library?"
		)
	end

	-- Check if saved data exists
	local savedData = json.decodeFile(PRIVATE_ACHIEVEMENTS_PATH)

	if not savedData then
		return
	end

	-- Check schema for saved data
	if type(savedData["$schema"]) ~= "string" then
		error("Invalid schema type " .. type(savedData["$schema"]) .. " (expected string)")
	end

	local savedDataVersion = tonumber(
		string.match(
			savedData["$schema"],
			"https://raw%.githubusercontent%.com/gurtt/achievements/v(%d+)%.%d+%.%d+/achievements%.schema%.json"
		)
	)

	if not savedDataVersion then
		error('Could not determine schema version from schema "' .. savedData["$schema"] .. '"')
	end

	if savedDataVersion < minimumVersion then
		error(
			"Saved data is older than the minimum supported version: "
				.. savedDataVersion
				.. " (expected >="
				.. minimumVersion
				.. ")"
		)
	end

	-- Check contents of saved data
	if not savedData.achievements then
		error("Saved data has no achievements")
	end

	if type(savedData.achievements) ~= "table" then
		error("Saved data has invalid achievements data of type " .. type(savedData.achievements) .. '"')
	end

	-- Copy saved data to achievements
	local sAch = {}
	for _, ach in pairs(savedData.achievements) do
		for i, key in ipairs({ "id", "name", "lockedDescription", "unlockedDescription" }) do
			if type(ach[key]) ~= "string" or ach[key] == "" then
				error("Achievement data at index " .. i .. " has invalid " .. key .. ": " .. ach[key])
			end
		end

		if sAch[ach.id] then
			error('Duplicate achievement ID "' .. ach.id .. '"')
		end

		if type(ach.maxValue) ~= "nil" then -- saved ach is numeric
			if type(ach.maxValue) ~= "number" or ach.maxValue % 1 ~= 0 or ach.maxValue < 1 then
				error('Achievement data "' .. ach.id .. '" has invalid maxValue ' .. ach.maxValue)
			end

			if type(ach.value) ~= "number" then
				error(
					'Achievement data"' .. ach.id .. '"has invalid value type' .. type(ach.value)(" (expected number)")
				)
			end
		else -- saved ach is boolean
			if type(ach.value) ~= "boolean" then
				error(
					'Achievement data"'
						.. ach.id
						.. '"has invalid value type'
						.. type(ach.value)
						.. " (expected boolean)"
				)
			end
		end

		sAch[ach.id] = deepcopy(ach)
	end

	return sAch
end

---Set up the achievements system.
-- Loads any existing achievements data from the game directory.
-- The achievement definitions you pass are authoritative; if saved data exists for an achievement you don't define here, that data will be removed next time you call `save()`.
---@param achievementDefs AchievementDefinitions The current achievements definitions for the game.
---@param minimumSchemaVersion? number The minimum supported version of the achievements schema to support. You only need to specify this if you update your game to use a new version of the achievements system.
function achievements.init(achievementDefs, minimumSchemaVersion)
	if achievementDefs == nil or achievementDefs.achievements == nil then
		error("No achievement defs provided during init", 2)
	end

	-- Load achievements from saved data
	local status, sAch = xpcall(load, function(msg)
		warn("Error loading saved achievement data: " .. msg)
	end, minimumSchemaVersion)

	achievements.kAchievements = {}

	-- Load achievements from definitions
	local numAchDef = 0
	for _, achDef in pairs(achievementDefs.achievements) do
		numAchDef = numAchDef + 1
		for i, key in ipairs({ "id", "name", "lockedDescription", "unlockedDescription" }) do
			if type(achDef[key]) ~= "string" or achDef[key] == "" then
				error("Achievement definition at index " .. i .. " has invalid " .. key .. ": " .. achDef[key], 2)
			end
		end

		if type(achDef.maxValue) ~= "nil" then
			if type(achDef.maxValue) ~= "number" or achDef.maxValue % 1 ~= 0 or achDef.maxValue < 1 then
				error(
					'Achievement definition "' .. achDef.id .. '" has invalid maxValue "' .. achDef.maxValue .. '"',
					2
				)
			end
		end

		if achDef.value then
			warn('Achievement definition "' .. achDef.id .. '" has a value. Is this a data table?')
		end

		-- HACK: This is grotesque. So is all of the surrounding code.
		if sAch and sAch[achDef.id] and sAch[achDef.id].value then -- there's saved data for this definition
			if achDef.maxValue then
				if type(sAch[achDef.id].value) == "number" then
					achDef.value = sAch[achDef.id].value
				else
					warn(
						"Achievment definition and saved data for "
							.. achDef.id
							.. "are different types. Ignoring saved data."
					)
				end
			else
				if type(sAch[achDef.id].value) == "boolean" then
					achDef.value = sAch[achDef.id].value
				else
					warn(
						"Achievment definition and saved data for "
							.. achDef.id
							.. "are different types. Ignoring saved data."
					)
				end
			end
		else
			if achDef.maxValue then
				achDef.value = 0
			else
				achDef.value = false
			end
		end

		achievements.kAchievements[achDef.id] = achDef
	end

	if numAchDef == 0 then
		error("No achiemvent defs provided during init", 2)
	end
end

---Persist the current achievements data to storage.
-- It's a good idea to call this during game lifecycle events like `playdate.gameWillTerminate()`, `playdate.deviceWillSleep()`, and `playdate.deviceWillLock()`.
function achievements.save()
	local savedData = {}

	savedData["$schema"] = SCHEMA_URL
	savedData.achievements = achievements.kAchievements

	json.encodeToFile(PRIVATE_ACHIEVEMENTS_PATH, savedData)
end

---Grant the specified achievement if it is a boolean achievement.
-- This only works for boolean achievements. For numeric achievements, use `set` or `increment`.
---@param achievementID string The ID of the achievement to grant.
---@return boolean # Whether or not the value of the achievement was changed.
function achievements.grant(achievementID)
	local ach = achievements.get(achievementID)

	if ach.maxValue then
		error('Achievement "' .. ach.id .. '" is numeric; use set() or increment()', 2)
	end

	if ach.value == true then
		return false
	end

	ach.value = true
	return true
end

---Increments the specified achievement by some amount.
-- This only works for numeric achievements. For boolean achievements, use `set` or `grant`.
---@param achievementID string The ID of the achievement to increment.
---@param increment? number The amount to increment by. Default is 1.
---@return boolean # Whether or not the value of the achievement was changed.
function achievements.increment(achievementID, increment)
	if increment then
		if type(increment) ~= "number" then
			error("Invalid increment type " .. type(increment) .. " (expected number)", 2)
		end

		if increment % 1 ~= 0 then
			error("Invalid increment value (expected integer)", 2)
		end
	end
	local inc = increment or 1

	local ach = achievements.get(achievementID)

	if not ach.maxValue then
		error('Achievement "' .. ach.id .. '" is boolean; use set() or grant()', 2)
	end

	if ach.value == ach.maxValue then
		return false
	end

	if inc < 1 and ach.value == 0 then
		return false
	end

	ach.value = math.max(math.min(ach.value + inc, ach.maxValue), 0)
	return true
end

---Check if the specified achievement has been granted.
---@param achievementID string The ID of the achievement to check.
---@return boolean isGranted Whether or not the achievement has been granted.
function achievements.isGranted(achievementID)
	local ach = achievements.get(achievementID)

	if ach.maxValue then
		return ach.value == ach.maxValue
	end

	return ach.value
end

return achievements
