local defs = require("test.support.defs")
local playdateEnv = require("test.support.playdateEnv")
local rstring = require("test.support.rstring")

describe("grant", function()
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

	it("should grant boolean achievement when not already granted", function()
		local didChange = achievements.unlock(booleanAchId)

		assert(achievements.get(booleanAchId).value == true)
		assert(math.abs(achievements.get(booleanAchId).unlockedAt - os.time()) < 2)
		assert.is.True(didChange)
	end)

	it("should work if boolean achievement was already granted", function()
		achievements.unlock(booleanAchId)

		local didChange = achievements.unlock(booleanAchId)

		assert(achievements.get(booleanAchId).value == true)
		assert.is.False(didChange)
	end)

	it("should not work for numeric achievements", function()
		assert.has.error(function()
			achievements.unlock(numericAchId)
		end)
		assert(achievements.get(numericAchId).value == 0)
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.unlock(rstring())
		end)
	end)
end)
