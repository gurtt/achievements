require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")

describe("set", function()
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

	it("should set the value of boolean achievements", function()
		achievements.set("pickup-wood", true)
		assert.is.True(achievements.get("pickup-wood").value)

		achievements.set("pickup-wood", false)
		assert.is.False(achievements.get("pickup-wood").value)
	end)

	it("should set the value of numeric achievements", function()
		achievements.set("craft-all-tools", 4)
		assert.is.True(achievements.get("craft-all-tools").value == 4)

		achievements.set("craft-all-tools", 0)
		assert.is.True(achievements.get("craft-all-tools").value == 0)
	end)

	it("should clamp to maxValue if set past maxValue", function()
		achievements.set("craft-all-tools", 100)
		assert.is.True(achievements.get("craft-all-tools").value == 4)
	end)

	it("should not work for values of the wrong type", function()
		achievements.set("pickup-wood", false)

		assert.has.error(function()
			achievements.set("pickup-wood", 900)
		end)
		assert.is.True(achievements.get("pickup-wood").value == false)

		achievements.set("craft-all-tools", 2)

		assert.has.error(function()
			achievements.set("craft-all-tools", false)
		end)
		assert.is.True(achievements.get("craft-all-tools").value == 2)
	end)

	it("should not work for non-integer numeric values", function()
		achievements.set("craft-all-tools", 2)

		assert.has.error(function()
			achievements.set("craft-all-tools", 2.5)
		end)
		assert.is.True(achievements.get("craft-all-tools").value == 2)
	end)

	it("should not work for negative numeric values", function()
		achievements.set("craft-all-tools", 2)

		assert.has.error(function()
			achievements.set("craft-all-tools", -10)
		end)
		assert.is.True(achievements.get("craft-all-tools").value == 2)
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.set("play-terraria", 1)
		end)
	end)
end)
