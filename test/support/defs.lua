local deepcopy = require("test.support.deepcopy")
local defs = {}

---Generates a valid achievement definition collection for the current schema version.
-- This doesn't verify the passed achievement definitions.
-- Achievement definitions are deep-copied.
---@param defTable table An array of achievement definitions.
---@return table The generated definition collection.
function defs.generate(defTable)
	local defCollection = {}

	defCollection["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json"

	defCollection.achievements = {}
	for _, def in pairs(defTable) do
		-- add the definition keyed with its ID if present, or with a numeric key otherwise. Allows testing for definitions with a missing id
		if def.id then
			defCollection.achievements[def.id] = deepcopy(def)
		else
			table.insert(defCollection, deepcopy(def))
		end
	end

	return defCollection
end

return defs
