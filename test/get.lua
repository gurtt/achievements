require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")

describe("get", function()
	local achDefs = defs.generate({
		{
			id = "enter-all-biomes",
			name = "Adventuring Time",
			lockedDescription = "Discover 17 biomes.",
			unlockedDescription = "Discovered 17 biomes.",
			maxValue = 17,
		},
	})
	achievements.init(achDefs)

	it("should return the whole achievement object", function()
		local expected = {
			id = "enter-all-biomes",
			name = "Adventuring Time",
			lockedDescription = "Discover 17 biomes.",
			unlockedDescription = "Discovered 17 biomes.",
			maxValue = 17,
			value = 0,
		}
		local actual = achievements.get("enter-all-biomes")

		assert.are.same(expected, actual)
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.get("play-terraria")
		end)
	end)
end)
