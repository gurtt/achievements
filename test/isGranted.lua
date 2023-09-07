local defs = require("test.support.defs")
local rstring = require("test.support.rstring")

describe("isGranted", function()
	before_each(function()
		_G.achievements = require("achievements")

		_G.booleanAchId = rstring()
		_G.numericAchId = rstring()
		_G.achDefs = defs.generate({
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
	end)

	after_each(function()
		_G.achievements = nil
		_G.booleanAchId = nil
		_G.numericAchId = nil
		_G.achDefs = nil
	end)

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
