local json = {}

json.files = {}

---Reads the file at the given `path` and converts it to a Lua table.
---@param path string
---@return table
function json.decodeFile(path)
	return json.files[path]
end

---Encodes the Lua table `table` to JSON and writes it to the given `path`. Otherwise, no additional whitespace is added.
-- Use of the `pretty` argument is not supported.
---@param path string
---@param table table
function json.encodeToFile(path, table)
	json.files[path] = table
end

return json
