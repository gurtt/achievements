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
			},
		}

		achievements.init(achDefs)

		assert.is.False(achievements.get("pickup-wood").value)
		assert.is.False(achievements.get("craft-all-tools").value ~= 0)
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
			id = "open-inventory",
			name = "Taking Inventory",
			lockedDescription = "Open your inventory.",
			unlockedDescription = "Opened your inventory.",
			value = false,
		}
		local actual = achievements.get("open-inventory")

		assert.are.same(expected, actual)
	end)
end)
