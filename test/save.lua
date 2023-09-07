local defs = require("test.support.defs")
local rstring = require("test.support.rstring")

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
		local ach = {
			id = rstring(),
			name = rstring(),
			lockedDescription = rstring(),
			unlockedDescription = rstring(),
		}
		local achDefs = defs.generate({ ach })
		achievements.init(achDefs)

		achievements.grant(ach.id)
		achievements.save()

		-- TODO: Inspect file in JSON table
	end)
end)
