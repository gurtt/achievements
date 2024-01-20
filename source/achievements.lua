-- Achievements for Playdate

---Path where the achievements data for the game is saved.
---@type string
local PRIVATE_ACHIEVEMENTS_PATH <const> = "achievements.json"

---Expected schema for achievements files.
---@type string
local ACHIEVEMENT_DATA_SCHEMA <const> =
	"https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json"

---@diagnostic disable-next-line: lowercase-global
achievements = {}

---@class (exact) Achievement
---@field id string A unique ID for the achievement.
---@field name string The user-facing name of the achievement.
---@field lockedDescription string The user-facing description of the requirements to unlock the achievement. Displayed when the player hasn't unlocked the achievement.
---@field unlockedDescription string The user-facing description of the requirements that unlocked the achievement. Displayed when the player hasn't unlocked the achievement.
---@field value? boolean|integer The progress of the achievement.
---@field maxValue? number For achievements where `value` is a number, the value needed to consider the achievement granted.

---Loads saved achievement data for the game.
local function loadSavedData()
	local savedData = json.decodeFile(PRIVATE_ACHIEVEMENTS_PATH)

	if not savedData then
		return
	end

	if savedData["$schema"] ~= ACHIEVEMENT_DATA_SCHEMA then
		print(
			'WARN: File at "'
				.. PRIVATE_ACHIEVEMENTS_PATH
				.. '" has unrecognised schema "'
				.. savedData["$schema"]
				.. '"'
		)
		return
	end

	if not savedData.achievements then
		print("WARN: Saved data has no achievements")
		return
	end

	if type(savedData.achievements) ~= "table" then
		print("WARN: Saved data has invalid achievements data of type " .. type(savedData.achievements) .. '"')
		return
	end

	for _, ach in ipairs(savedData.achievements) do
		for i, key in ipairs({ "id", "name", "lockedDescription", "unlockedDescription" }) do
			if type(ach[key]) ~= "string" or ach[key] == "" then
				error("Achievement data at index " .. i .. " has invalid " .. key .. ": " .. ach[key])
			end
		end

		if achievements.kAchievements[ach.id] then
			error('Duplicate achievement ID "' .. ach.id .. '"', 3)
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
---@param achievementDefs Achievement[] The current achievements definitions for the game.
function achievements.init(achievementDefs)
	if achievementDefs == nil then
		error("No data provided during init", 2)
	end

	-- Load achievements from saved data
	loadSavedData()

	-- Load achievements from definitions
	achievements.kAchievements = {}
	for _, achDef in ipairs(achievementDefs) do
		for i, key in ipairs({ "id", "name", "lockedDescription", "unlockedDescription" }) do
			if type(achDef[key]) ~= "string" or achDef[key] == "" then
				error("Achievement definition at index " .. i .. " has invalid " .. key .. ": " .. achDef[key], 2)
			end
		end

		if achievements.kAchievements[achDef.id] then
			error('Duplicate achievement ID "' .. achDef.id .. '"', 2)
		end

		if type(achDef.maxValue) ~= "nil" then
			if type(achDef.maxValue) ~= "number" or achDef % 1 ~= 0 or achDef < 1 then
				error(
					'Achievement definition "' .. achDef.id .. '" has invalid maxValue "' .. achDef.maxValue .. '"',
					2
				)
			end
		end

		if achDef.value then
			warn('Achievement definition "' .. achDef.id .. '" has a value. Is this a data table?')
		end

		achievements.kAchievements[achDef.id] = achDef
	end
end

---Persist the current achievements data to storage.
-- It's a good idea to call this during game lifecycle events like `playdate.gameWillTerminate()`, `playdate.deviceWillSleep()`, and `playdate.deviceWillLock()`.
function achievements.save()
	local savedData = {}

	savedData["$schema"] = ACHIEVEMENT_DATA_SCHEMA
	savedData.achievements = achievements.kAchievements

	json.encodeToFile(PRIVATE_ACHIEVEMENTS_PATH, false, savedData)
end

---Grant the specified achievement.
---@param achievementID string The ID of the achievement to grant.
---@return boolean didChange Whether or not the status of the achievement was changed.
function achievements.grant(achievementID)
	if type(achievementID) ~= "string" then
		error('Achievement ID "' .. achievementID .. '" is invalid', 2)
	end

	local ach = achievements.kAchievements[achievementID]

	if not ach then
		error('No achievement with ID "' .. achievementID .. '"', 2)
	end

	if ach.isGranted then
		return false
	end

	ach.isGranted = true
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

	return ach.isGranted
end

return achievements
