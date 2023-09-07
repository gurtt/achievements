local defs = require("test.support.defs")
local rstring = require("test.support.rstring")

describe("get", function()
	before_each(function()
		_G.achievements = require("source.achievements")

		_G.ach = {
			id = rstring(),
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
			maxValue = 17,
		}

		local achDefs = defs.generate({ ach })
		achievements.init(achDefs)
	end)

	after_each(function()
		_G.achievements = nil
		_G.ach = nil
	end)

	it("should return the whole achievement object", function()
		ach.value = 0
		local actual = achievements.get(ach.id)

		assert.are.same(ach, actual)
	end)

	it("should not work for non-existent achievement", function()
		assert.has.error(function()
			achievements.get(rstring())
		end)
	end)
end)
