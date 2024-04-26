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
local function loadSavedData(minimumSchemaVersion)
	if minimumSchemaVersion and type(minimumSchemaVersion) ~= "number" then
		error("Invalid minimum schema number type " .. type(minimumSchemaVersion) .. " (expected number)")
	end

	if minimumSchemaVersion > CURRENT_SCHEMA_VERSION then
		error(
			"Minimum schema version is newer than the current schema version ("
				.. CURRENT_SCHEMA_VERSION
				.. "). Do you need to update your library?"
		)
	end

	local savedData = json.decodeFile(PRIVATE_ACHIEVEMENTS_PATH)

	if not savedData then
		return
	end

	if type(savedData["$schema"]) ~= "string" then
		error("Invalid schema type " .. type(savedData["$schema"]) .. " (expected string)")
	end

	local savedDataVersion = tonumber(
		string.match(
			savedData["$schema"],
			"https://raw%.githubusercontent%.com/gurtt/achievements/v(\\d+)%.\\d+%.\\d+/achievements%.schema%.json"
		)
	)

	if not savedDataVersion then
		error('Could not determine schema version from schema "' .. savedData["$schema"] .. '"')
	end

	local minimumVersion = minimumSchemaVersion or CURRENT_SCHEMA_VERSION

	if savedDataVersion < minimumVersion then
		error(
			"Saved data is older than the minimum supported version: "
				.. savedDataVersion
				.. " (expected >="
				.. minimumVersion
				.. ")"
		)
	end

	if savedDataVersion == CURRENT_SCHEMA_VERSION then
		return
	end

	savedData.achievements = migrate(savedData.achievements, savedDataVersion)

	if not savedData.achievements then
		error("Saved data has no achievements")
	end

	if type(savedData.achievements) ~= "table" then
		error("Saved data has invalid achievements data of type " .. type(savedData.achievements) .. '"')
	end

	for _, ach in ipairs(savedData.achievements) do
		for i, key in ipairs({ "id", "name", "lockedDescription", "unlockedDescription" }) do
			if type(ach[key]) ~= "string" or ach[key] == "" then
				error("Achievement data at index " .. i .. " has invalid " .. key .. ": " .. ach[key])
			end
		end

		if achievements.kAchievements[ach.id] then
			error('Duplicate achievement ID "' .. ach.id .. '"')
		end

		if type(ach.maxValue) ~= "nil" then
			if type(ach.maxValue) ~= "number" or ach.maxValue % 1 ~= 0 or ach.maxValue < 1 then
				error('Achievement data "' .. ach.id .. '" has invalid maxValue ' .. ach.maxValue)
			end

			if type(ach.value) ~= "number" then
				error(
					'Achievement data"' .. ach.id .. '"has invalid value type' .. type(ach.value)(" (expected number)")
				)
			end
		else
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

		achievements.kAchievements[ach.id] = ach
	end
end

---Set up the achievements system.
-- Loads any existing achievements data from the game directory.
-- The achievement definitions you pass are authoritative; if saved data exists for an achievement you don't define here, that data will be removed next time you call `save()`.
---@param achievementDefs AchievementDefinitions The current achievements definitions for the game.
---@param minimumSchemaVersion? number The minimum supported version of the achievements schema to support. You only need to specify this if you update your game to use a new version of the achievements system.
function achievements.init(achievementDefs, minimumSchemaVersion)
	if achievementDefs == nil then
		error("No achievement defs provided during init", 2)
	end

	-- Load achievements from saved data
	xpcall(loadSavedData, function(msg)
		warn("Error loading saved achievement data: " .. msg)
		-- Clean up any achievements loaded before the error
		achievements.kAchievements = {}
	end, minimumSchemaVersion)

	-- Load achievements from definitions
	for _, achDef in ipairs(achievementDefs.achievements) do
		for i, key in ipairs({ "id", "name", "lockedDescription", "unlockedDescription" }) do
			if type(achDef[key]) ~= "string" or achDef[key] == "" then
				error("Achievement definition at index " .. i .. " has invalid " .. key .. ": " .. achDef[key], 2)
			end
		end

		if achievements.kAchievements[achDef.id] then
			break
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

		if achDef.maxValue then
			achDef.value = 0
		else
			achDef.value = false
		end

		achievements.kAchievements[achDef.id] = achDef
	end
end

---Persist the current achievements data to storage.
-- It's a good idea to call this during game lifecycle events like `playdate.gameWillTerminate()`, `playdate.deviceWillSleep()`, and `playdate.deviceWillLock()`.
function achievements.save()
	local savedData = {}

	savedData["$schema"] = SCHEMA_URL
	savedData.achievements = achievements.kAchievements

	json.encodeToFile(PRIVATE_ACHIEVEMENTS_PATH, false, savedData)
end

---Grant the specified achievement if it is a boolean achievement.
-- This only works for boolean achievements. For numeric achievements, use `set` or `increment`.
---@param achievementID string The ID of the achievement to grant.
---@return boolean # Whether or not the value of the achievement was changed.
function achievements.grant(achievementID)
	if type(achievementID) ~= "string" then
		error('Achievement ID "' .. achievementID .. '" is invalid', 2)
	end

	local ach = achievements.kAchievements[achievementID]

	if not ach then
		error('No achievement with ID "' .. achievementID .. '"', 2)
	end

	if ach.maxValue then
		error('Achievement "' .. ach.id .. '" is numeric; use set() or increment()', 2)
	end

	if ach.value == false then
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
	if increment and type(increment) ~= "number" then
		error("Invalid increment type " .. type(increment) .. " (expected number)", 2)
	end
	local inc = increment or 1

	if type(achievementID) ~= "string" then
		error('Achievement ID "' .. achievementID .. '" is invalid', 2)
	end

	local ach = achievements.kAchievements[achievementID]

	if not ach then
		error('No achievement with ID "' .. achievementID .. '"', 2)
	end

	if not ach.maxValue then
		error('Achievement "' .. ach.id .. '" is boolean; use set() or grant()', 2)
	end

	if ach.value == ach.maxValue then
		return false
	end

	ach.value = math.min(ach.value + inc, ach.maxValue)
	return true
end

---Check if the specified achievement has been granted.
---@param achievementID string The ID of the achievement to check.
---@return boolean isGranted Whether or not the achievement has been granted.
function achievements.isGranted(achievementID)
	if type(achievementID) ~= "string" then
		error('Achievement ID "' .. achievementID .. '" is invalid', 2)
	end

	local ach = achievements.kAchievements[achievementID]

	if not ach then
		error('No achievement with ID "' .. achievementID .. '"', 2)
	end

	if ach.maxValue then
		return ach.value == ach.maxValue
	end

	return ach.value
end

---Set the specified achievement to the given value.
---@param achievementID string The ID of the achievement to change.
---@param value boolean|number The value to set the achievement to.
function achievements.set(achievementID, value)
	if type(achievementID) ~= "string" then
		error('Achievement ID "' .. achievementID .. '" is invalid', 2)
	end

	local ach = achievements.kAchievements[achievementID]

	if not ach then
		error('No achievement with ID "' .. achievementID .. '"', 2)
	end

	if ach.maxValue then
		if type(value) ~= "number" then
			error('Invalid value type for achievement "' .. ach.id .. '" (expected number)', 2)
		end

		ach.value = math.min(value, ach.maxValue)
	else
		if type(value) ~= "boolean" then
			error('Invalid value type for achievement "' .. ach.id .. '" (expected number)', 2)
		end
	end
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

return achievements
