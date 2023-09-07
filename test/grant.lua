require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")
local rstring = require("test.support.rstring")

describe("grant", function()
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

	it("should grant boolean achievement when not already granted", function()
		assert(achievements.get(booleanAchId).value == false)

		local didChange = achievements.grant(booleanAchId)

		assert(achievements.get(booleanAchId).value == true)
		assert.is.True(didChange)
	end)

	it("should work if boolean achievement was already granted", function()
		assert(achievements.get(booleanAchId).value == true)

		local didChange = achievements.grant(booleanAchId)

		assert(achievements.get(booleanAchId).value == true)
		assert.is.False(didChange)
	end)

	it("should not work for numeric achievements", function()
		assert(achievements.get(numericAchId).value == 0)

		assert.has.error(function()
			achievements.grant(numericAchId)
		end)
		assert(achievements.get(numericAchId).value == 0)
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.grant(rstring())
		end)
	end)
end)
