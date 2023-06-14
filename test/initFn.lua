require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")

describe("init", function()
	it("should load a valid achievement definition without error", function()
		local achDefs = defs.generate({
			{
				id = "open-inventory",
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
			},
		})

		assert.has.no.error(function()
			achievements.init(achDefs)
		end)
	end)

	describe("should not load definitions if", function()
		local fieldErrors = {
			["the id is missing"] = {
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
			},
			["the id is not a string"] = {
				id = true,
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
			},
			["the id is an empty string"] = {
				id = "",
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
			},
			["the name is missing"] = {
				id = "open-inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
			},
			["the name is not a string"] = {
				id = "open-inventory",
				name = true,
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
			},
			["the name is an empty string"] = {
				id = "open-inventory",
				name = "",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
			},
			["the lockedDescription is missing"] = {
				id = "open-inventory",
				name = "Taking Inventory",
				unlockedDescription = "Opened your inventory.",
			},
			["the lockedDescription is not a string"] = {
				id = "open-inventory",
				name = "Taking Inventory",
				lockedDescription = true,
				unlockedDescription = "Opened your inventory.",
			},
			["the lockedDescription is an empty string"] = {
				id = "open-inventory",
				name = "Taking Inventory",
				lockedDescription = "",
				unlockedDescription = "Opened your inventory.",
			},
			["the unlockedDescription is missing"] = {
				id = "open-inventory",
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
			},
			["the unlockedDescription is not a string"] = {
				id = "open-inventory",
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = true,
			},
			["the unlockedDescription is an empty string"] = {
				id = "open-inventory",
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "",
			},
			["the maxValue is not a number"] = {
				id = "open-inventory",
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
				maxValue = true,
			},
			["the maxValue is a negative number"] = {
				id = "open-inventory",
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
				maxValue = -19,
			},
			["the maxValue is a non-integer number"] = {
				id = "open-inventory",
				name = "Taking Inventory",
				lockedDescription = "Open your inventory.",
				unlockedDescription = "Opened your inventory.",
				maxValue = 2.5,
			},
		}

		for description, achDef in pairs(fieldErrors) do
			it(description, function()
				local achDefs = defs.generate({ achDef })

				assert.has.error(function()
					achievements.init(achDefs)
				end)
			end)
		end
	end)

	it("should ignore values when loading definitions", function()
		local achDefs = defs.generate({
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
		})

		achievements.init(achDefs)

		assert(achievements.get("pickup-wood").value == false)
		assert(achievements.get("craft-all-tools").value == 0)
		assert(achievements.get("craft-dispenser").value == false)
		assert(achievements.get("playtime-100-days").value == 0)
		assert(achievements.get("craft-porkchop").value == false)
		assert(achievements.get("pickup-emeralds").value == 0)
	end)

	it("should make achievements available after init", function()
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

	it("should load valid achievement data from a file", function()
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
		local achData = defs.generate({
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
		})

		json.encodeToFile("achievements.json", achData)
		achievements.init(achDefs)

		assert.is.True(achievements.get("pickup-wood").value == true)
		assert.is.True(achievements.get("craft-all-tools").value == 3)
	end)

	it("should not include achievements from file not in definitions", function()
		local achDefs = defs.generate({
			{
				id = "pickup-wood",
				name = "Getting Wood",
				lockedDescription = "Punch a tree until a block of wood pops out.",
				unlockedDescription = "Obtained your first block of wood.",
			},
		})
		local achData = defs.generate({
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
		})

		json.encodeToFile("achievements.json", achData)
		achievements.init(achDefs)

		assert.is.True(achievements.get("pickup-wood").value == true)
		assert.has.error(function()
			achievements.get("craft-all-tools")
		end)
	end)

	it("should include achievements not from file but in definitions", function()
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
		local achData = defs.generate({
			{
				id = "pickup-wood",
				name = "Getting Wood",
				lockedDescription = "Punch a tree until a block of wood pops out.",
				unlockedDescription = "Obtained your first block of wood.",
				value = true,
			},
		})

		json.encodeToFile("achievements.json", achData)
		achievements.init(achDefs)

		assert.is.True(achievements.get("pickup-wood").value == true)
		assert.is.True(achievements.get("craft-all-tools").value == 0)
	end)

	it("should not work if no achievements are defined", function()
		local achDefs = defs.generate({})

		assert.has.error(function()
			achievements.init(achDefs)
		end)
	end)
end)
