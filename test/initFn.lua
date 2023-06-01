require("source.achievements")

describe("init", function()
	it("should load a valid achievement definition without error", function()
		local achDefs = {
			["schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json",
			["achievements"] = {
				{
					id = "open-inventory",
					name = "Taking Inventory",
					lockedDescription = "Open your inventory.",
					unlockedDescription = "Opened your inventory.",
				},
			},
		}

		assert.has.no.error(function()
			achievements.init(achDefs)
		end)
	end)

	it("should ignore values when loading definitions", function()
		local achDefs = {
			["schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json",
			["achievements"] = {
				-- valid with values
				{
					id = "pickup-wood",
					name = "Getting Wood",
					lockedDescription = "Punch a tree until a block of wood pops out.",
					unlockedDescription = "Obtained your first block of wood.",
					value = true,
				},
				{
					id = "craft-all-tools",
					name = "MOAR Tools",
					lockedDescription = "Construct one type of each tool.",
					unlockedDescription = "Constructed one type of each tool.",
					maxValue = 4,
					value = 3,
				},
				-- invalid with values
				{
					id = "craft-dispenser",
					name = "Dispense with This",
					lockedDescription = "Construct a dispenser.",
					unlockedDescription = "Constructed a dispenser.",
					value = 64,
				},
				{
					id = "playtime-100-days",
					name = "Passing the Time",
					lockedDescription = "Play for 100 days.",
					unlockedDescription = "Played for 100 days.",
					maxValue = 100,
					value = 9001,
				},
				{
					id = "craft-porkchop",
					name = "Pork Chop",
					lockedDescription = "Cook and eat a pork chop.",
					unlockedDescription = "Cooked and ate a pork chop.",
					value = { cooked = true, ate = 0 },
				},
				{
					id = "pickup-emeralds",
					name = "The Haggler",
					lockedDescription = "Acquire or spend 30 Emeralds by trading with villagers.",
					unlockedDescription = "Acquired or spent 30 Emeralds by trading with villagers.",
					maxValue = 30,
					value = { villager = 300, wandering_trader = 24 },
				},
			},
		}

		achievements.init(achDefs)

		assert(achievements.get("pickup-wood").value == false)
		assert(achievements.get("craft-all-tools").value == 0)
		assert(achievements.get("craft-dispenser").value == false)
		assert(achievements.get("playtime-100-days").value == 0)
		assert(achievements.get("craft-porkchop").value == false)
		assert(achievements.get("pickup-emeralds").value == 0)
	end)

	it("should make achievements available after init", function()
		local achDefs = {
			["schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json",
			["achievements"] = {
				{
					id = "enter-all-biomes",
					name = "Adventuring Time",
					lockedDescription = "Discover 17 biomes.",
					unlockedDescription = "Discovered 17 biomes.",
					maxValue = 17,
				},
			},
		}
		achievements.init(achDefs)

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
end)

describe("grant", function()
	local achDefs = {
		["schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json",
		["achievements"] = {
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
		},
	}
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

describe("increment", function()
	local achDefs = {
		["schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json",
		["achievements"] = {
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
		},
	}
	achievements.init(achDefs)

	it("should increment numeric achievement by 1", function()
		local didChange = achievements.increment("craft-all-tools")

		assert(achievements.get("craft-all-tools").value == 1)
		assert.is.True(didChange)
	end)

	it("should increment numeric achievement by n", function()
		local didChange = achievements.increment("craft-all-tools", 2)

		assert(achievements.get("craft-all-tools").value == 3)
		assert.is.True(didChange)
	end)

	it("should clamp to maxValue if incremented past maxValue", function()
		local didChange = achievements.increment("craft-all-tools", 100)

		assert(achievements.get("craft-all-tools").value == 4)
		assert.is.True(didChange)
	end)

	it("should do nothing if incremented while at maxValue", function()
		local didChange = achievements.increment("craft-all-tools")

		assert(achievements.get("craft-all-tools").value == 4)
		assert.is.False(didChange)
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

describe("isGranted", function()
	local achDefs = {
		["schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json",
		["achievements"] = {
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
		},
	}
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

describe("set", function()
	local achDefs = {
		["schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json",
		["achievements"] = {
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
		},
	}
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
		assert.is.False(achievements.get("craft-all-tools").value == 0)
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
end)
