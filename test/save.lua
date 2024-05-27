local defs = require("test.support.defs")
local playdateEnv = require("test.support.playdateEnv")
local rstring = require("test.support.rstring")

describe("save", function()
	before_each(function()
		playdateEnv.init()
		_G.achievements = require("achievements")
	end)

	after_each(function()
		playdateEnv.unInit()
		_G.achievements = nil
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

		local localSavedAchData = json.decodeFile("achievements.json").achievements
		local sharedSavedAchData =
			json.decodeFile("/Shared/Data/" .. playdate.metadata.bundleID .. "/achievements.json").achievements

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

		assert.is.True(contains(localSavedAchData, booleanAch))
		assert.is.True(contains(localSavedAchData, numericAch))
		assert.is.True(contains(sharedSavedAchData, booleanAch))
		assert.is.True(contains(sharedSavedAchData, numericAch))
	end)
end)
