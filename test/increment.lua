require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")

describe("increment", function()
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

	it("should increment numeric achievement by 1", function()
		achievements.set("craft-all-tools", 0)
		local didChange = achievements.increment("craft-all-tools")

		assert(achievements.get("craft-all-tools").value == 1)
		assert.is.True(didChange)
	end)

	it("should increment numeric achievement by n", function()
		achievements.set("craft-all-tools", 1)
		local didChange = achievements.increment("craft-all-tools", 2)

		assert(achievements.get("craft-all-tools").value == 3)
		assert.is.True(didChange)
	end)

	it("should clamp to maxValue if incremented past maxValue", function()
		achievements.set("craft-all-tools", 3)
		local didChange = achievements.increment("craft-all-tools", 100)

		assert(achievements.get("craft-all-tools").value == 4)
		assert.is.True(didChange)
	end)

	it("should clamp to 0 if decremented past zero", function()
		achievements.set("craft-all-tools", 1)
		local didChange = achievements.increment("craft-all-tools", -100)

		assert(achievements.get("craft-all-tools").value == 0)
		assert.is.True(didChange)
	end)

	it("should do nothing if incremented while at maxValue", function()
		achievements.set("craft-all-tools", 4)
		local didChange = achievements.increment("craft-all-tools")

		assert(achievements.get("craft-all-tools").value == 4)
		assert.is.False(didChange)
	end)

	it("should do nothing if decremented while at 0", function()
		achievements.set("craft-all-tools", 0)
		local didChange = achievements.increment("craft-all-tools", -100)

		assert(achievements.get("craft-all-tools").value == 0)
		assert.is.False(didChange)
	end)

	it("should not work for non-integer numeric values", function()
		achievements.set("craft-all-tools", 1)

		assert.has.error(function()
			achievements.increment("craft-all-tools", 2.5)
		end)
		assert.is.True(achievements.get("craft-all-tools").value == 1)
	end)

	it("should decrement numeric achievement by n", function()
		achievements.set("craft-all-tools", 3)
		local didChange = achievements.increment("craft-all-tools", -2)

		assert(achievements.get("craft-all-tools").value == 1)
		assert.is.True(didChange)
	end)

	it("should not work for boolean achievements", function()
		assert.has.error(function()
			achievements.increment("pickup-wood")
		end)
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.increment("play-terraria")
		end)
	end)
end)
