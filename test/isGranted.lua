require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")
local rstring = require("test.support.rstring")

describe("isGranted", function()
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

	it("should return true or false for boolean achievements", function()
		assert.is.False(achievements.isGranted(booleanAchId))

		achievements.grant(booleanAchId)

		assert.is.True(achievements.isGranted(booleanAchId))
	end)

	it("should return false for numeric achievements below maxValue", function()
		assert.is.False(achievements.isGranted(numericAchId))
	end)

	it("should return true for numeric achievements at maxValue", function()
		achievements.increment(numericAchId, 100)
		assert.is.True(achievements.isGranted(numericAchId))
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.isGranted(rstring())
		end)
	end)
end)
