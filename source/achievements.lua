local deepCopy = require("deepCopy")
local migrate = require("migration")
---Path where the achievements data for the game is saved.
---@type string
local PRIVATE_ACHIEVEMENTS_PATH = "achievements.json"

---Current achievements data schema version.
---@type number
local CURRENT_SCHEMA_VERSION = 3

---URL for the current schema definition.
---@type string
local SCHEMA_URL = "https://raw.githubusercontent.com/gurtt/achievements/v3.0.0/achievements.schema.json"

---@diagnostic disable-next-line: lowercase-global
achievements = {}

---@class (exact) Achievement
---@field id string A unique ID for the achievement.
---@field name string The user-facing name of the achievement.
---@field lockedDescription string The user-facing description of the requirements to unlock the achievement. Displayed when the player hasn't unlocked the achievement.
---@field unlockedDescription string The user-facing description of the requirements that unlocked the achievement. Displayed when the player hasn't unlocked the achievement.
---@field unlockedAt? number The seconds since epoch when the achievement was unlocked. Ignored if not unlocked.
---@field value? boolean|integer The progress of the achievement.
---@field maxValue? number For achievements where `value` is a number, the value needed to consider the achievement granted.

---@class (exact) AchievementDefinitions
---@field achievements Achievement[]

---Get the specified achievement.
---@param achievementID string The ID of the achievement to get.
---@return Achievement # The achievement.
function achievements.get(achievementID)
	if type(achievementID) ~= "string" then
		error("bad argument #1 to 'get' (string expected, got " .. type(achievementID) .. ")", 2)
	end

	local ach = achievements.kAchievements[achievementID]

	if not ach then
		error("attempt to get nil achievement (ID '" .. achievementID .. "')", 2)
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
			error("bad argument #2 to 'set' (expected number, got " .. type(value) .. ")", 2)
		end

		if value < 0 then
			error("bad argument #2 to 'set' (expected >= 0, got " .. value .. ")", 2)
		end

		if value % 1 ~= 0 then
			error("bad argument #2 to 'set' (expected integer, got " .. value .. ")", 2)
		end

		local wasUnlocked = achievements.isUnlocked(ach.id)
		ach.value = math.min(value, ach.maxValue)

		if (not wasUnlocked) and achievements.isUnlocked(ach.id) then
			ach.unlockedAt = os.time()
		end

		if wasUnlocked and (not achievements.isUnlocked(ach.id)) then
			ach.unlockedAt = nil
		end
	else
		if type(value) ~= "boolean" then
			error("bad argument #2 to 'set' (expected boolean, got " .. type(value) .. ")", 2)
		end

		ach.value = value
	end
end

---Loads saved achievement data for the game.
---@param minimumSchemaVersion? number The earliest version of the achievements data schema to try migrating from. If unspecified, migration is disabled.
local function load(minimumSchemaVersion)
	if minimumSchemaVersion and type(minimumSchemaVersion) ~= "number" then
		error("bad argument #1 to 'load' (expected number, got " .. type(minimumSchemaVersion) .. ")", 2)
	end

	-- Check if saved data exists
	local savedData = json.decodeFile(PRIVATE_ACHIEVEMENTS_PATH)

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

---Set up the achievements system.
-- Loads any existing achievements data from the game directory.
-- The achievement definitions you pass are authoritative; if saved data exists for an achievement you don't define here, that data will be removed next time you call `save()`.
---@param achievementDefs AchievementDefinitions The current achievements definitions for the game.
---@param minimumSchemaVersion? number The minimum supported version of the achievements schema to support. You only need to specify this if you update your game to use a new version of the achievements system.
function achievements.init(achievementDefs, minimumSchemaVersion)
	if type(achievementDefs) ~= "table" then
		error("bad argument #1 to 'init' (expected table, got " .. type(achievementDefs) .. ")", 2)
	end
	if type(achievementDefs.achievements) ~= "table" then
		error(
			"invalid type for field 'achievements' (expected table, got " .. type(achievementDefs.achievements) .. ")",
			2
		)
	end

	-- Load achievements from saved data
	local _, sAch = xpcall(load, function(msg)
		warn("Error loading saved achievement data: " .. msg)
	end, minimumSchemaVersion)

	achievements.kAchievements = {}

	-- Load achievements from definitions
	local numAchDef = 0
	for _, achDef in ipairs(achievementDefs.achievements) do
		numAchDef = numAchDef + 1
		for _, key in ipairs({ "id", "name", "lockedDescription", "unlockedDescription" }) do
			if type(achDef[key]) ~= "string" then
				error("invalid type for field '" .. key .. "' (expected string, got " .. type(achDef[key]) .. ")")
			end
			if achDef[key] == "" then
				error("invalid value for field '" .. key .. "' (expected non-empty string)")
			end
		end

		if type(achDef.maxValue) ~= "nil" then
			if type(achDef.maxValue) ~= "number" then
				error("invalid type for field 'maxValue' (expected number, got " .. type(achDef.maxValue) .. ")")
			end

			if achDef.maxValue % 1 ~= 0 or achDef.maxValue < 1 then
				error("invalid value for field 'maxValue' (expected positive integer, got " .. achdef.maxValue .. ")")
			end
		end

		if achDef.value then
			warn(
				"invalid value for field 'value' (expected nil, got "
					.. type(achDef.value)
					.. "). Is this a data table?"
			)
		end

		-- HACK: This is grotesque. So is all of the surrounding code.
		if sAch and sAch[achDef.id] and sAch[achDef.id].value then -- there's saved data for this definition
			if achDef.maxValue then
				if type(sAch[achDef.id].value) == "number" then
					achDef.value = sAch[achDef.id].value
					achDef.unlockedAt = sAch[achDef.id].unlockedAt
				else
					warn(
						"invalid value for field 'value' (expected number, got "
							.. type(sAch[achDef.id].value)
							.. "). Ignoring saved data."
					)
				end
			else
				if type(sAch[achDef.id].value) == "boolean" then
					achDef.value = sAch[achDef.id].value
					achDef.unlockedAt = sAch[achDef.id].unlockedAt
				else
					warn(
						"invalid value for field 'value' (expected boolean, got "
							.. type(sAch[achDef.id].value)
							.. "). Ignoring saved data."
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
		error("bad argument #1 to 'init (expected valid achievement definitions, got none)", 2)
	end
end

---Persist the current achievements data to storage.
-- It's a good idea to call this during game lifecycle events like `playdate.gameWillTerminate()`, `playdate.deviceWillSleep()`, and `playdate.deviceWillLock()`.
function achievements.save()
	local savedData = {}

	savedData["$schema"] = SCHEMA_URL
	savedData.achievements = {}
	for _, ach in pairs(achievements.kAchievements) do
		table.insert(savedData.achievements, ach)
	end

	json.encodeToFile(PRIVATE_ACHIEVEMENTS_PATH, savedData)
end

---Grant the specified achievement if it is a boolean achievement.
-- This only works for boolean achievements. For numeric achievements, use `set` or `increment`.
---@param achievementID string The ID of the achievement to unlock.
---@return boolean # Whether or not the value of the achievement was changed.
---@deprecated Use unlock
function achievements.grant(achievementID)
	return achievements.unlock(achievementID)
end

---Grant the specified achievement if it is a boolean achievement.
-- This only works for boolean achievements. For numeric achievements, use `set` or `increment`.
---@param achievementID string The ID of the achievement to unlock.
---@return boolean # Whether or not the value of the achievement was changed.
function achievements.unlock(achievementID)
	local ach = achievements.get(achievementID)

	if ach.maxValue then
		error("attempt to unlock numeric achievement", 2)
	end

	if ach.value == true then
		return false
	end

	ach.value = true
	ach.unlockedAt = os.time()
	return true
end

---Increments the specified achievement by some amount.
-- This only works for numeric achievements. For boolean achievements, use `set` or `unlock`.
---@param achievementID string The ID of the achievement to increment.
---@param increment? number The amount to increment by. Default is 1.
---@return boolean # Whether or not the value of the achievement was changed.
function achievements.increment(achievementID, increment)
	if increment then
		if type(increment) ~= "number" then
			error("bad argument #2 to 'increment' (expected number, got " .. type(increment) .. ")", 2)
		end

		if increment % 1 ~= 0 then
			error("bad argument #2 to 'increment' (expected integer, got " .. increment .. ")", 2)
		end
	end
	local inc = increment or 1

	local ach = achievements.get(achievementID)

	if not ach.maxValue then
		error("attempt to increment boolean achievement", 2)
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

---Check if the specified achievement has been unlocked.
---@param achievementID string The ID of the achievement to check.
---@return boolean isGranted Whether or not the achievement has been unlocked.
---@deprecated Use isUnlocked
function achievements.isGranted(achievementID)
	return achievements.isUnlocked(achievementID)
end

---Check if the specified achievement has been unlocked.
---@param achievementID string The ID of the achievement to check.
---@return boolean isGranted Whether or not the achievement has been unlocked.
function achievements.isUnlocked(achievementID)
	local ach = achievements.get(achievementID)

	if ach.maxValue then
		return ach.value == ach.maxValue
	end

	return ach.value
end

return achievements
