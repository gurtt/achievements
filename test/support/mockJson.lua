local mockJson = {}

mockJson.files = {}

---Adds an entry to the virtual file system.
---@param at string the path to the JSON file to mock.
---@param decodedData table the data to mock decoding from the mocked JSON file.
function mockJson.addFile(at, decodedData)
	mockJson.decodableFiles[at] = decodedData
end

---Removes the entry from the virtual file system.
---@param at string the path to the JSON file to stop mocking.
function mockJson.removeFile(at)
	mockJson.decodableFiles[at] = nil
end

---@diagnostic disable-next-line: lowercase-global
json = {}

---Reads the file at the given `path` and converts it to a Lua table.
---@param path string
---@return table
function json.decodeFile(path)
	return mockJson.files[path]
end

---Encodes the Lua table `table` to JSON and writes it to the given `path`. If `pretty` is true, the output is formatted to make it human-readable. Otherwise, no additional whitespace is added.
---@param path string
---@param pretty? boolean
---@param table table
function json.encodeToFile(path, pretty, table)
	-- TODO: Copy the table to the file system, and support any value for the pretty param
end

return mockJson
