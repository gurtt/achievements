require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")

describe("grant", function()
	local achDefs = defs.generate({
		{
			id = "pickup-wood",
			name = "Getting Wood",
			lockedDescription = "Punch a tree until a block of wood pops out.",
			unlockedDescription = "Obtained your first block of wood.",
		},
		{
			id = "craft-all-tools",
			name = "MOAR Tools",
			lockedDescription = "Construct one type of each tool.",
			unlockedDescription = "Constructed one type of each tool.",
			maxValue = 4,
		},
	})
	achievements.init(achDefs)

	it("should grant boolean achievement when not already granted", function()
		assert(achievements.get("pickup-wood").value == false)

		local didChange = achievements.grant("pickup-wood")

		assert(achievements.get("pickup-wood").value == true)
		assert.is.True(didChange)
	end)

	it("should work if boolean achievement was already granted", function()
		assert(achievements.get("pickup-wood").value == true)

		local didChange = achievements.grant("pickup-wood")

		assert(achievements.get("pickup-wood").value == true)
		assert.is.False(didChange)
	end)

	it("should not work for numeric achievements", function()
		assert(achievements.get("craft-all-tools").value == 0)

		assert.has.error(function()
			achievements.grant("craft-all-tools")
		end)
		assert(achievements.get("craft-all-tools").value == 0)
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.grant("play-terraria")
		end)
	end)
end)
