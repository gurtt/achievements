local deepCopy = require("deepcopy")
local CURRENT_SCHEMA_VERSION = 3

---Migrates a table of achievement data to the current schema version.
---@param achData table The achievement data to migrate.
---@param minimumSchemaVersion? number The earliest schema version to support.
local function migrate(achData, minimumSchemaVersion)
	-- Verify the minimum version, if supplied, is valid
	if minimumSchemaVersion and type(minimumSchemaVersion) ~= "number" then
		error("bad argument #2 to 'migrate' (expected number, got " .. type(minimumSchemaVersion) .. ")", 2)
	end

	local minimumVersion = minimumSchemaVersion or CURRENT_SCHEMA_VERSION

	if minimumVersion > CURRENT_SCHEMA_VERSION then
		error(
			"bad argument #2 to 'migrate' (expected <= "
				.. CURRENT_SCHEMA_VERSION
				.. ", got "
				.. minimumVersion
				.. "). Do you need to update your library?"
		)
	end

	-- Check schema for saved data
	if type(achData["$schema"]) ~= "string" then
		error("invalid type for field '$schema' (expected string, got " .. type(achData["$schema"]) .. ")")
	end

	local achDataVersion = tonumber(
		string.match(
			achData["$schema"],
			"https://raw%.githubusercontent%.com/gurtt/achievements/v(%d+)%.%d+%.%d+/achievements%.schema%.json"
		)
	)

	if not achDataVersion then
		error("invalid format for field '$schema' ('" .. achData["$schema"] .. "')")
	end

	if achDataVersion < minimumVersion then
		error("invalid version for saved data (expected >= " .. minimumVersion .. ", got " .. achDataVersion .. ")")
	end

	-- Check contents of saved data
	if not achData.achievements then
		error("saved data has no achievements")
	end

	if type(achData.achievements) ~= "table" then
		error("invalid type for field 'achievements' (expected table, got " .. type(savedData.achievements) .. ")")
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
