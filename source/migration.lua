local deepCopy = require("deepcopy")
local CURRENT_SCHEMA_VERSION = 3

---Migrates a table of achievement data to the current schema version.
---@param achData table The achievement data to migrate.
---@param minimumSchemaVersion? number The earliest schema version to support.
local function migrate(achData, minimumSchemaVersion)
	-- Verify the minimum version, if supplied, is valid
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

	-- Check schema for saved data
	if type(achData["$schema"]) ~= "string" then
		error("Invalid schema type " .. type(achData["$schema"]) .. " (expected string)")
	end

	local achDataVersion = tonumber(
		string.match(
			achData["$schema"],
			"https://raw%.githubusercontent%.com/gurtt/achievements/v(%d+)%.%d+%.%d+/achievements%.schema%.json"
		)
	)

	if not achDataVersion then
		error('Could not determine schema version from schema "' .. achData["$schema"] .. '"')
	end

	if achDataVersion < minimumVersion then
		error(
			"Data is older than the minimum supported version: "
				.. achDataVersion
				.. " (expected >="
				.. minimumVersion
				.. ")"
		)
	end

	-- Check contents of saved data
	if not achData.achievements then
		error("Data has no achievements")
	end

	if type(achData.achievements) ~= "table" then
		error("Data has invalid achievements data of type " .. type(achData.achievements) .. '"')
	end

	local workingData = deepCopy(achData)

	-- Migrate 1 -> 2
	if achDataVersion == 1 then
		local achievements = {}
		for _, ach in pairs(workingData.achievements) do
			table.insert(achievements, {
				id = ach.id,
				name = ach.id,
				lockedDescription = ach.id,
				unlockedDescription = ach.id,
				value = ach.isGranted or false,
			})
		end
		workingData.achievements = achievements
		workingData["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json"

		achDataVersion = 2
	end

	-- Migrate 2 -> 3
	if achDataVersion == 2 then
		for _, ach in pairs(workingData.achievements) do
			if (ach.maxValue and ach.value >= ach.maxValue) or ach.value == true then
				ach.unlockedAt = os.time()
			end
		end
		workingData["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v3.0.0/achievements.schema.json"

		achDataVersion = 3
	end

	return workingData
end

return migrate
