require("source.achievements")
require("test.support.json")
local defs = require("test.support.defs")
local rstring = require("test.support.rstring")

describe("get", function()
	local ach = {
		id = rstring(),
		name = rstring(),
		lockedDescription = rstring(),
		unlockedDescription = rstring(),
		maxValue = 17,
	}

	local achDefs = defs.generate({ ach })
	achievements.init(achDefs)

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
