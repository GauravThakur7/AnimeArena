--!strict
--[[
	TableUtil.luau
	Common table utilities.
]]

local TableUtil = {}

--- Shallow copy a table.
function TableUtil.Copy(t: { [any]: any }): { [any]: any }
	local copy = {}
	for k, v in t do
		copy[k] = v
	end
	return copy
end

--- Deep copy a table (recursive).
function TableUtil.DeepCopy(t: { [any]: any }): { [any]: any }
	local copy = {}
	for k, v in t do
		if typeof(v) == "table" then
			copy[k] = TableUtil.DeepCopy(v :: any)
		else
			copy[k] = v
		end
	end
	return copy
end

--- Merge two tables (shallow). Second table overrides first.
function TableUtil.Merge(base: { [any]: any }, override: { [any]: any }): { [any]: any }
	local result = TableUtil.Copy(base)
	for k, v in override do
		result[k] = v
	end
	return result
end

--- Deep merge two tables. Second table overrides first.
function TableUtil.DeepMerge(base: { [any]: any }, override: { [any]: any }): { [any]: any }
	local result = TableUtil.DeepCopy(base)
	for k, v in override do
		if typeof(v) == "table" and typeof(result[k]) == "table" then
			result[k] = TableUtil.DeepMerge(result[k], v :: any)
		else
			result[k] = v
		end
	end
	return result
end

--- Check if a table contains a value.
function TableUtil.Contains(t: { any }, value: any): boolean
	return table.find(t, value) ~= nil
end

--- Get the number of entries in a dictionary-style table.
function TableUtil.Count(t: { [any]: any }): number
	local count = 0
	for _ in t do
		count += 1
	end
	return count
end

--- Filter an array by a predicate function.
function TableUtil.Filter(t: { any }, predicate: (value: any, index: number) -> boolean): { any }
	local result = {}
	for i, v in t do
		if predicate(v, i) then
			table.insert(result, v)
		end
	end
	return result
end

--- Map an array through a transform function.
function TableUtil.Map(t: { any }, transform: (value: any, index: number) -> any): { any }
	local result = {}
	for i, v in t do
		result[i] = transform(v, i)
	end
	return result
end

--- Freeze a table and all nested tables (deep freeze).
function TableUtil.DeepFreeze(t: { [any]: any }): { [any]: any }
	for _, v in t do
		if typeof(v) == "table" then
			TableUtil.DeepFreeze(v :: any)
		end
	end
	return table.freeze(t)
end

return table.freeze(TableUtil)
