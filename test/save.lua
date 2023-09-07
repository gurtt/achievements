local defs = require("test.support.defs")
local rstring = require("test.support.rstring")
local deepcopy = require("test.support.deepcopy")

describe("save", function()
	before_each(function()
		_G.achievements = require("source.achievements")
		_G.json = require("test.support.json")
	end)

	after_each(function()
		_G.achievements = nil
		_G.json = nil
	end)

	it("saves achievements when called", function()
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
			maxValue = 10,
		}
		local achDefs = defs.generate({ booleanAch, numericAch })
		achievements.init(achDefs)

		achievements.set(booleanAch.id, true)
		achievements.set(numericAch.id, 5)
		achievements.save()

		-- Make a copy of the definitions with values
		booleanAch.value = true
		numericAch.value = 5
		local achData = defs.generate({ booleanAch, numericAch })

		assert.is.same(achData, json.decodeFile("achievements.json"))
	end)
end)
