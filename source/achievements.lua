-- Achievements for Playdate

---Path where the achievements data for the game is saved.
---@type string
local PRIVATE_ACHIEVEMENTS_PATH <const> = "achievements.json"

---Expected schema for achievements files.
---@type string
local ACHIEVEMENT_DATA_SCHEMA <const> =
	"https://raw.githubusercontent.com/gurtt/pd-achievements/main/schema/achievements-v1.schema.json"

---@diagnostic disable-next-line: lowercase-global
achievements = {}

---@class (exact) Achievement
---@field id string A unique ID for the achievement.
---@field isGranted? boolean Whether or not the achievement has been granted.

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
		if type(ach.id) ~= "string" or ach.id == "" then
			error('Saved achievement has invalid ID"' .. ach.id .. '"')
		end

		if achievements.kAchievements[ach.id] then
			error('Duplicate achievement ID "' .. ach.id .. '"')
		end

		if not ach.isGranted then
			print('WARN: Achievement "' .. ach.id .. '" has no achievement data: isGranted. Is this a definition file?')
		elseif type(ach.isGranted) ~= "boolean" then
			error(
				'Achievement "' .. ach.id .. '" has invalid data: isGranted with type "' .. type(ach.isGranted) .. '"'
			)
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
		if type(achDef.id) ~= "string" or achDef.id == "" then
			error('Achievement has invalid ID "' .. achDef.id .. '"', 2)
		end

		if achievements.kAchievements[achDef.id] then
			error('Duplicate achievement ID "' .. achDef.id .. '"', 2)
		end

		if type(achDef.isGranted) ~= "nil" then
			print(
				'WARN: Achievement definition "'
					.. achDef.id
					.. '" has achievement data: isGranted. Is this a data table?',
				2
			)
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

return achievements
