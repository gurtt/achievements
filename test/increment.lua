local defs = require("test.support.defs")
local playdateEnv = require("test.support.playdateEnv")
local rstring = require("test.support.rstring")

describe("increment", function()
	before_each(function()
		playdateEnv.init()
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
		playdateEnv.unInit()
		_G.achievements = nil
		_G.booleanAchId = nil
		_G.numericAchId = nil
		_G.achDefs = nil
	end)

	it("should increment numeric achievement by 1", function()
		local didChange = achievements.increment(numericAchId)

		assert(achievements.get(numericAchId).value == 1)
		assert.is.True(didChange)
	end)

	it("should increment numeric achievement by n", function()
		achievements.set(numericAchId, 1)
		local didChange = achievements.increment(numericAchId, 2)

		assert(achievements.get(numericAchId).value == 3)
		assert.is.True(didChange)
	end)

	it("should clamp to maxValue if incremented past maxValue", function()
		achievements.set(numericAchId, 3)
		local didChange = achievements.increment(numericAchId, 100)

		assert(achievements.get(numericAchId).value == 4)
		assert.is.True(didChange)
	end)

	it("should clamp to 0 if decremented past zero", function()
		achievements.set(numericAchId, 1)
		local didChange = achievements.increment(numericAchId, -100)

		assert(achievements.get(numericAchId).value == 0)
		assert.is.True(didChange)
	end)

	it("should do nothing if incremented while at maxValue", function()
		achievements.set(numericAchId, 4)
		local didChange = achievements.increment(numericAchId)

		assert(achievements.get(numericAchId).value == 4)
		assert.is.False(didChange)
	end)

	it("should do nothing if decremented while at 0", function()
		local didChange = achievements.increment(numericAchId, -100)

		assert(achievements.get(numericAchId).value == 0)
		assert.is.False(didChange)
	end)

	it("should not work for non-integer numeric values", function()
		achievements.set(numericAchId, 1)

		assert.has.error(function()
			achievements.increment(numericAchId, 2.5)
		end)
		assert.is.True(achievements.get(numericAchId).value == 1)
	end)

	it("should decrement numeric achievement by n", function()
		achievements.set(numericAchId, 3)
		local didChange = achievements.increment(numericAchId, -2)

		assert(achievements.get(numericAchId).value == 1)
		assert.is.True(didChange)
	end)

	it("should not work for boolean achievements", function()
		assert.has.error(function()
			achievements.increment(booleanAchId)
		end)
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.increment(rstring())
		end)
	end)
end)
