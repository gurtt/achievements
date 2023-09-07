require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")
local rstring = require("test.support.rstring")

describe("set", function()
	local booleanAchId = rstring()
	local numericAchId = rstring()
	local achDefs = defs.generate({
		{
			id = booleanAchId,
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
		},
		{
			id = numericAchId,
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			maxValue = 4,
		},
	})
	achievements.init(achDefs)

	it("should set the value of boolean achievements", function()
		achievements.set(booleanAchId, true)
		assert.is.True(achievements.get(booleanAchId).value)

		achievements.set(booleanAchId, false)
		assert.is.False(achievements.get(booleanAchId).value)
	end)

	it("should set the value of numeric achievements", function()
		achievements.set(numericAchId, 4)
		assert.is.True(achievements.get(numericAchId).value == 4)

		achievements.set(numericAchId, 0)
		assert.is.True(achievements.get(numericAchId).value == 0)
	end)

	it("should clamp to maxValue if set past maxValue", function()
		achievements.set(numericAchId, 100)
		assert.is.True(achievements.get(numericAchId).value == 4)
	end)

	it("should not work for values of the wrong type", function()
		achievements.set(booleanAchId, false)

		assert.has.error(function()
			achievements.set(booleanAchId, 900)
		end)
		assert.is.True(achievements.get(booleanAchId).value == false)

		achievements.set(numericAchId, 2)

		assert.has.error(function()
			achievements.set(numericAchId, false)
		end)
		assert.is.True(achievements.get(numericAchId).value == 2)
	end)

	it("should not work for non-integer numeric values", function()
		achievements.set(numericAchId, 2)

		assert.has.error(function()
			achievements.set(numericAchId, 2.5)
		end)
		assert.is.True(achievements.get(numericAchId).value == 2)
	end)

	it("should not work for negative numeric values", function()
		achievements.set(numericAchId, 2)

		assert.has.error(function()
			achievements.set(numericAchId, -10)
		end)
		assert.is.True(achievements.get(numericAchId).value == 2)
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.set(rstring(), 1)
		end)
	end)
end)
