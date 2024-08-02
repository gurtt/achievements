local deepcopy = require("test.support.deepcopy")
local defs = {}

---Generates a valid achievement definition collection for the current schema version.
-- This doesn't verify the passed achievement definitions.
-- Achievement definitions are deep-copied.
---@param defTable table An array of achievement definitions.
---@return table The generated definition collection.
function defs.generate(defTable)
	local defCollection = {}

	defCollection["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v1.0.0/achievements.schema.json"

	defCollection.achievements = {}
	for _, def in pairs(defTable) do
		table.insert(defCollection.achievements, deepcopy(def))
	end

	return defCollection
end

return defs
