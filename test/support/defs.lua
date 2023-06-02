local defs = {}

---Generates a valid achievement definition collection for the current schema version.
-- This doesn't verify the passed achievement definitions.
---@param defTable table An array of achievement definitions.
---@return table The generated definition collection.
function defs.generate(defTable)
	local defCollection = {}

	defCollection["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json"
	defCollection["achievements"] = defTable

	return defCollection
end

return defs
