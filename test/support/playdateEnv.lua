local rstring = require("test.support.rstring")
local json = require("test.support.json")

local playdateEnv = {}

function playdateEnv.init(metadata)
	local meta = metadata
		or {
			name = rstring(),
			author = rstring(),
			description = rstring(),
			bundleID = rstring(),
			version = rstring(),
			buildNumber = math.random(100),
		}
	_G.playdate = {
		metadata = meta,
	}

	_G.json = json
end

function playdateEnv.unInit()
	_G.playdate = nil
	_G.json = nil
end

return playdateEnv
