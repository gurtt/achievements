local sets = { { 97, 122 }, { 65, 90 }, { 48, 57 } } -- a-z, A-Z, 0-9

---Generates a random string of any length.
---@param length? number the length of the string. Defaults to 10.
---@return string # the random string.
local function rstring(length)
	if length ~= nil and type(length) ~= "number" then
		error("length must be a number", 2)
	end
	local len = length or 10

	local str = ""
	math.randomseed(math.floor(os.time() * os.clock()))
	for i = 1, len do
		local charset = sets[math.random(1, #sets)]
		str = str .. string.char(math.random(charset[1], charset[2]))
	end
	return str
end

return rstring
