local defs = require("test.support.defs")
local rstring = require("test.support.rstring")

describe("init", function()
	before_each(function()
		_G.achievements = require("source.achievements")
		_G.json = require("test.support.json")
	end)

	after_each(function()
		_G.achievements = nil
		_G.json = nil
	end)

	it("should load a valid achievement definition without error", function()
		local achDefs = defs.generate({
			{
				id = rstring(),
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
			},
		})

		assert.has.no.error(function()
			achievements.init(achDefs)
		end)
	end)

	describe("should not load definitions if", function()
		local fieldErrors = {
			["the id is missing"] = {
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
			},
			["the id is not a string"] = {
				id = true,
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
			},
			["the id is an empty string"] = {
				id = "",
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
			},
			["the name is missing"] = {
				id = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
			},
			["the name is not a string"] = {
				id = rstring(),
				name = true,
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
			},
			["the name is an empty string"] = {
				id = rstring(),
				name = "",
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
			},
			["the lockedDescription is missing"] = {
				id = rstring(),
				name = rstring(),
				unlockedDescription = rstring(),
			},
			["the lockedDescription is not a string"] = {
				id = rstring(),
				name = rstring(),
				lockedDescription = true,
				unlockedDescription = rstring(),
			},
			["the lockedDescription is an empty string"] = {
				id = rstring(),
				name = rstring(),
				lockedDescription = "",
				unlockedDescription = rstring(),
			},
			["the unlockedDescription is missing"] = {
				id = rstring(),
				name = rstring(),
				lockedDescription = rstring(),
			},
			["the unlockedDescription is not a string"] = {
				id = rstring(),
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = true,
			},
			["the unlockedDescription is an empty string"] = {
				id = rstring(),
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = "",
			},
			["the maxValue is not a number"] = {
				id = rstring(),
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
				maxValue = true,
			},
			["the maxValue is a negative number"] = {
				id = rstring(),
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
				maxValue = -19,
			},
			["the maxValue is a non-integer number"] = {
				id = rstring(),
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
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
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
				unlockedAt = 100,
				value = true,
			},
			{
				id = "craft-all-tools",
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
				unlockedAt = 100,
				maxValue = 4,
				value = 3,
			},
			-- invalid with values
			{
				id = "craft-dispenser",
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
				value = 64,
			},
			{
				id = "playtime-100-days",
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
				maxValue = 100,
				value = 9001,
			},
			{
				id = "craft-porkchop",
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
				value = { cooked = true, ate = 0 },
			},
			{
				id = "pickup-emeralds",
				name = rstring(),
				lockedDescription = rstring(),
				unlockedDescription = rstring(),
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
		local ach = {
			id = rstring(),
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			maxValue = 17,
		}
		local achDefs = defs.generate({ ach })

		achievements.init(achDefs)

		ach.value = 0
		assert.are.same(ach, achievements.get(ach.id))
	end)

	it("should load valid achievement data from a file", function()
		local booleanAch = {
			id = rstring(),
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
		}
		local numericAch = {
			id = rstring(),
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			maxValue = 4,
		}
		local achDefs = defs.generate({ booleanAch, numericAch })
		booleanAch.value = true
		booleanAch.unlockedAt = 100
		numericAch.value = 3
		local achData = defs.generate({ booleanAch, numericAch })

		json.encodeToFile("achievements.json", achData)
		achievements.init(achDefs)

		assert.is.same(booleanAch, achievements.get(booleanAch.id))
		assert.is.same(numericAch, achievements.get(numericAch.id))
	end)

	it("should not include achievements from file not in definitions", function()
		local booleanAch = {
			id = rstring(),
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
		}
		local numericAch = {
			id = rstring(),
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			maxValue = 4,
		}
		local achDefs = defs.generate({ booleanAch })
		booleanAch.value = true
		booleanAch.unlockedAt = 100
		numericAch.value = 3
		local achData = defs.generate({ booleanAch, numericAch })

		json.encodeToFile("achievements.json", achData)
		achievements.init(achDefs)

		assert.is.same(booleanAch, achievements.get(booleanAch.id))
		assert.has.error(function()
			achievements.get(numericAch.id)
		end)
	end)

	it("should include achievements not from file but in definitions", function()
		local booleanAch = {
			id = rstring(),
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
		}
		local numericAch = {
			id = rstring(),
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			maxValue = 4,
		}
		local achDefs = defs.generate({ booleanAch, numericAch })
		booleanAch.value = true
		booleanAch.unlockedAt = 100
		numericAch.value = 0
		local achData = defs.generate({ booleanAch })

		json.encodeToFile("achievements.json", achData)
		achievements.init(achDefs)

		assert.is.same(booleanAch, achievements.get(booleanAch.id))
		assert.is.same(numericAch, achievements.get(numericAch.id))
	end)

	it("should load definition as boolean if saved data is numeric", function()
		local achId = rstring()
		local booleanAch = {
			id = achId,
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			value = false,
		}
		local numericAch = {
			id = achId,
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			maxValue = 4,
			value = 3,
		}
		local achDefs = defs.generate({ booleanAch })
		local achData = defs.generate({ numericAch })

		json.encodeToFile("achievements.json", achData)
		achievements.init(achDefs)

		assert.is.same(booleanAch, achievements.get(achId))
	end)

	it("should load definition as numeric if saved data is boolean", function()
		local achId = rstring()
		local booleanAch = {
			id = achId,
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			value = true,
		}
		local numericAch = {
			id = achId,
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			maxValue = 4,
			value = 0,
		}
		local achDefs = defs.generate({ numericAch })
		local achData = defs.generate({ booleanAch })

		json.encodeToFile("achievements.json", achData)
		achievements.init(achDefs)

		assert.is.same(numericAch, achievements.get(achId))
	end)

	it("should not work if no achievements are defined", function()
		local achDefs = defs.generate({})

		assert.has.error(function()
			achievements.init(achDefs)
		end)
	end)
end)
