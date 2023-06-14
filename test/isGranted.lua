require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")

describe("isGranted", function()
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

	it("should return true or false for boolean achievements", function()
		assert.is.False(achievements.isGranted("pickup-wood"))

		achievements.grant("pickup-wood")

		assert.is.True(achievements.isGranted("pickup-wood"))
	end)

	it("should return false for numeric achievements below maxValue", function()
		assert.is.False(achievements.isGranted("craft-all-tools"))
	end)

	it("should return true for numeric achievements at maxValue", function()
		achievements.increment("craft-all-tools", 100)
		assert.is.True(achievements.isGranted("craft-all-tools"))
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.isGranted("play-terraria")
		end)
	end)
end)
