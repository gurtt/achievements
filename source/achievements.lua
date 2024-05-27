local storage = require("storage")

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
	local _, sAch = xpcall(storage.load, function(msg)
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
				error("invalid value for field 'maxValue' (expected positive integer, got " .. achDef.maxValue .. ")")
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

	local metadata = playdate.metadata

	achievements.meta = {}
	-- load metadata from definitions or from pdxinfo. The idea is that the built-in metadata should be good, but this allows devs to override it if needed for some reason.
	-- TODO: Some of these fields (description?) should be optional (maybe)
	for _, field in ipairs({ "name", "author", "description", "bundleID", "version" }) do
		if achievementDefs[field] ~= nil then -- try to use the field from definitions
			if type(achievementDefs[field]) ~= "string" then
				warn(
					"invalid type for field '"
						.. field
						.. "' in achievement definitions (expected string, got "
						.. type(achievementDefs[field])
						.. ")"
				)
				goto useMetadata
			end

			if achievementDefs[field] == "" then
				warn("invalid value for field '" .. field .. "' in achievement definitions (expected non-empty string)")
				goto useMetadata
			end

			achievements.meta[field] = achievementDefs[field]
			goto continue
		end

		::useMetadata::
		if metadata[field] ~= nil then -- try to use the metadata field
			if metadata[field] == "" then
				warn("invalid value for field '" .. field .. "' in metadata (expected non-empty string)")
			end

			achievements.meta[field] = metadata[field]
			goto continue
		end

		-- there was nothing suitable in either the definitions or the base metadata :(
		error("no valid value available for field '" .. field .. "'", 2)

		::continue::
	end

	-- duplicates work as above but for buildNumber, which should be a number
	local build = achievementDefs.buildNumber

	if build ~= nil then -- try to use the field from definitions
		if type(build) ~= "number" then
			warn(
				"invalid type for field 'buildNumber' in achievement metadata (expected number, got "
					.. type(build)
					.. ")"
			)
			goto bmetadata
		end

		if build % 1 ~= 0 or build < 1 then
			warn(
				"invalid value for field 'buildNumber' in achievement metadata (expected positive integer, got "
					.. build
					.. ")"
			)
			goto bmetadata
		end

		achievements.meta.buildNumber = build
		goto bcontinue
	end

	::bmetadata::
	if metadata.buildNumber ~= nil then -- try to use the metadata field
		achievements.meta.buildNumber = metadata.buildNumber
		goto bcontinue
	end

	error("no valid value available for field 'buildNumber'", 2)

	::bcontinue::
end

function achievements.save()
	storage.save(achievements)
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
