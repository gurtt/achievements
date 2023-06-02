---Generates a valid achievement definition collection for the current schema version.
-- This doesn't verify the passed achievement definitions.
---@param defs table An array of achievement definitions.
---@return table The generated definition collection.
local function generateDefs(defs)
	local defCollection = {}

	defCollection["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json"
	defCollection["achievements"] = defs

	return defCollection
end

return generateDefs
