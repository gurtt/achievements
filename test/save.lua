local defs = require("test.support.defs")
local rstring = require("test.support.rstring")

describe("save", function()
	before_each(function()
		_G.achievements = require("achievements")
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

		booleanAch.value = true
		numericAch.value = 5

		local savedAchData = json.decodeFile("achievements.json").achievements

		local function contains(table, subject)
			-- using ipairs because saved data shouldn't be keyed anymore
			for _, candidate in ipairs(table) do
				-- this isn't a full deep compare but we don't need it
				if candidate.id == subject.id and candidate.value == subject.value then
					return true
				end
			end
			return false
		end
		assert.is.True(contains(savedAchData, booleanAch))
		assert.is.True(contains(savedAchData, numericAch))
	end)
end)
