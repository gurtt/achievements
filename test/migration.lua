local migrate = require("source.migration")

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
end)
