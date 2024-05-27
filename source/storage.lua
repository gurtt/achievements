local deepCopy = require("deepCopy")
local migrate = require("migration")

local ACHIEVEMENTS_FILE_NAME = "achievements.json"
local PRIVATE_ACHIEVEMENTS_PATH = ""
local SHARED_ACHIEVEMENTS_PATH = "/Shared/Data/"
local SCHEMA_URL = "https://raw.githubusercontent.com/gurtt/achievements/v3.0.0/achievements.schema.json"

local storage = {}
---Loads saved achievement data for the game.
---@param minimumSchemaVersion? number The earliest version of the achievements data schema to try migrating from. If unspecified, migration is disabled.
function storage.load(minimumSchemaVersion)
	if minimumSchemaVersion and type(minimumSchemaVersion) ~= "number" then
		error("bad argument #1 to 'load' (expected number, got " .. type(minimumSchemaVersion) .. ")", 2)
	end

	-- Check if saved data exists
	local savedData = json.decodeFile(PRIVATE_ACHIEVEMENTS_PATH .. ACHIEVEMENTS_FILE_NAME)

	if not savedData then
		return
	end

	migrate(savedData, minimumSchemaVersion)

	-- Copy saved data to achievements
	local sAch = {}
	for _, ach in ipairs(savedData.achievements) do
		for _, key in ipairs({ "id", "name", "lockedDescription", "unlockedDescription" }) do
			if type(ach[key]) ~= "string" then
				error("invalid type for field '" .. key .. "' (expected string, got " .. type(ach[key]) .. ")")
			end
			if ach[key] == "" then
				error("invalid value for field '" .. key .. "' (expected non-empty string)")
			end
		end

		if sAch[ach.id] then
			error("invalid value for field 'ID' (expected unique value)")
		end

		if type(ach.maxValue) ~= "nil" then -- saved ach is numeric
			if type(ach.maxValue) ~= "number" then
				error("invalid type for field 'maxValue' (expected number, got " .. type(ach.maxValue) .. ")")
			end

			if ach.maxValue % 1 ~= 0 or ach.maxValue < 1 then
				error("invalid value for field 'maxValue' (expected positive integer, got " .. ach.maxValue .. ")")
			end

			if type(ach.value) ~= "number" then
				error("invalid value for field 'value' (expected number, got " .. type(ach.value) .. ")")
			end

			if ach.value >= ach.maxValue then
				if type(ach.unlockedAt) ~= "number" then
					error("invalid type for field 'unlockedAt' (expected number, got " .. type(ach.unlockedAt) .. ")")
				end

				if ach.unlockedAt % 1 ~= 0 or ach.unlockedAt < 0 then
					error(
						"invalid value for field 'unlockedAt' (expected positive integer, got " .. ach.unlockedAt .. ")"
					)
				end
			end
		else -- saved ach is boolean
			if type(ach.value) ~= "boolean" then
				error("invalid type for field 'value' (expected boolean, got " .. type(ach.value) .. ")")
			end

			if ach.value == true then
				if type(ach.unlockedAt) ~= "number" then
					error("invalid type for field 'unlockedAt' (expected number, got " .. type(ach.unlockedAt) .. ")")
				end

				if ach.unlockedAt % 1 ~= 0 or ach.unlockedAt < 0 then
					error(
						"invalid value for field 'unlockedAt' (expected positive integer, got " .. ach.unlockedAt .. ")"
					)
				end
			end
		end

		sAch[ach.id] = deepCopy(ach)
	end

	return sAch
end

---Persist the current achievements data to storage.
-- It's a good idea to call this during game lifecycle events like `playdate.gameWillTerminate()`, `playdate.deviceWillSleep()`, and `playdate.deviceWillLock()`.
function storage.save(achData)
	local savedData = {}

	savedData["$schema"] = SCHEMA_URL
	savedData.achievements = {}
	for _, ach in pairs(achData.kAchievements) do
		table.insert(savedData.achievements, ach)
	end

	for _, field in ipairs({ "name", "author", "description", "bundleID", "version", "buildNumber" }) do
		savedData[field] = achData.meta[field]
	end

	json.encodeToFile(PRIVATE_ACHIEVEMENTS_PATH .. ACHIEVEMENTS_FILE_NAME, savedData)
	json.encodeToFile(SHARED_ACHIEVEMENTS_PATH .. achData.meta.bundleID .. "/" .. ACHIEVEMENTS_FILE_NAME, savedData)
end

return storage
