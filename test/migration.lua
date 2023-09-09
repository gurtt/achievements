local rstring = require("rstring")
local migrate = require("migration")

describe("migrate", function()
	describe("should not migrate if the minimum schema is", function()
		local versions = {
			["too high"] = 100,
			["not an integer"] = 2.5,
			["negative"] = -10,
			["not a number"] = true,
		}
		for k, v in pairs(versions) do
			it(k, function()
				assert.has.error(function()
					---@diagnostic disable-next-line
					migrate({}, v)
				end)
			end)
		end
	end)

	describe("should migrate data to current version from", function()
		local timeSpy = function()
			return 100
		end

		before_each(function()
			stub(os, "time", timeSpy())
		end)

		after_each(function()
			---@diagnostic disable-next-line
			os.time:revert()
		end)

		local versions = {
			[1] = {
				["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v1.0.0/achievements.schema.json",
				achievements = {
					{
						id = "lockedBoolean",
						isGranted = false,
					},
					{
						id = "unlockedBoolean",
						isGranted = true,
					},
				},
			},
			[2] = {
				["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v2.0.0/achievements.schema.json",
				achievements = {
					{
						id = "lockedBoolean",
						name = "lockedBoolean",
						lockedDescription = "lockedBoolean",
						unlockedDescription = "lockedBoolean",
						value = false,
					},
					{
						id = "unlockedBoolean",
						name = "unlockedBoolean",
						lockedDescription = "unlockedBoolean",
						unlockedDescription = "unlockedBoolean",
						value = true,
					},
					{
						id = "lockedNumeric",
						name = "lockedNumeric",
						lockedDescription = "lockedNumeric",
						unlockedDescription = "lockedNumeric",
						maxValue = 10,
						value = 5,
					},
					{
						id = "unlockedNumeric",
						name = "unlockedNumeric",
						lockedDescription = "unlockedNumeric",
						unlockedDescription = "unlockedNumeric",
						maxValue = 10,
						value = 10,
					},
				},
			},
		}
		local latestVersionData = {
			[1] = {
				["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v3.0.0/achievements.schema.json",
				achievements = {
					{
						id = "lockedBoolean",
						name = "lockedBoolean",
						lockedDescription = "lockedBoolean",
						unlockedDescription = "lockedBoolean",
						value = false,
					},
					{
						id = "unlockedBoolean",
						name = "unlockedBoolean",
						lockedDescription = "unlockedBoolean",
						unlockedDescription = "unlockedBoolean",
						unlockedAt = 100,
						value = true,
					},
				},
			},
			[2] = {
				["$schema"] = "https://raw.githubusercontent.com/gurtt/achievements/v3.0.0/achievements.schema.json",
				achievements = {
					{
						id = "lockedBoolean",
						name = "lockedBoolean",
						lockedDescription = "lockedBoolean",
						unlockedDescription = "lockedBoolean",
						value = false,
					},
					{
						id = "unlockedBoolean",
						name = "unlockedBoolean",
						lockedDescription = "unlockedBoolean",
						unlockedDescription = "unlockedBoolean",
						unlockedAt = 100,
						value = true,
					},
					{
						id = "lockedNumeric",
						name = "lockedNumeric",
						lockedDescription = "lockedNumeric",
						unlockedDescription = "lockedNumeric",
						maxValue = 10,
						value = 5,
					},
					{
						id = "unlockedNumeric",
						name = "unlockedNumeric",
						lockedDescription = "unlockedNumeric",
						unlockedDescription = "unlockedNumeric",
						unlockedAt = 100,
						maxValue = 10,
						value = 10,
					},
				},
			},
		}

		for version, data in pairs(versions) do
			it("v" .. version, function()
				local migratedData = migrate(data, version)
				assert.is.same(latestVersionData[version], migratedData)
			end)
		end
	end)
end)
