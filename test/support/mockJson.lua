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

---Returns the entry from the virtual file system.
---@param at string the path to the JSON file to retrive the mock for.
---@return table
function mockJson.getFile(at)
	return mockJson.files[at]
end

---@diagnostic disable-next-line: lowercase-global
json = {}

---Reads the file at the given `path` and converts it to a Lua table.
---@param path string
---@return table
function json.decodeFile(path)
	return mockJson.files[path]
end

---Encodes the Lua table `table` to JSON and writes it to the given `path`. Otherwise, no additional whitespace is added.
-- Use of the `pretty` argument is not supported.
---@param path string
---@param table table
function json.encodeToFile(path, table)
	mockJson.files[path] = table
end

return mockJson
