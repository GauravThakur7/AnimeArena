--!strict
--[[
	Validator.luau
	Input validation utilities for remote event payloads.
	Used by server services to validate data from untrusted clients.
	
	Usage:
		local ok = Validator.IsTable(data)
			and Validator.HasField(data, "attackType", "string")
			and Validator.HasField(data, "timestamp", "number")
]]

local Validator = {}

--- Check if a value is a table.
function Validator.IsTable(value: any): boolean
	return typeof(value) == "table"
end

--- Check if a table has a field of the expected type.
function Validator.HasField(t: { [any]: any }, field: string, expectedType: string): boolean
	return typeof(t[field]) == expectedType
end

--- Check if a value is a number within a range.
function Validator.NumberInRange(value: any, min: number, max: number): boolean
	return typeof(value) == "number" and value >= min and value <= max
end

--- Check if a value is a non-empty string.
function Validator.NonEmptyString(value: any): boolean
	return typeof(value) == "string" and #(value :: string) > 0
end

--- Check if a value is one of a set of allowed strings.
function Validator.IsOneOf(value: any, allowed: { string }): boolean
	if typeof(value) ~= "string" then
		return false
	end
	return table.find(allowed, value) ~= nil
end

--- Check if a value is a valid Vector3.
function Validator.IsVector3(value: any): boolean
	return typeof(value) == "Vector3"
end

--- Check if a value is a valid CFrame.
function Validator.IsCFrame(value: any): boolean
	return typeof(value) == "CFrame"
end

--- Check if a timestamp is within acceptable range of server time.
function Validator.TimestampValid(timestamp: any, maxDriftSeconds: number?): boolean
	if typeof(timestamp) ~= "number" then
		return false
	end
	local drift = maxDriftSeconds or 0.5
	local serverTime = workspace:GetServerTimeNow()
	return math.abs(serverTime - (timestamp :: number)) <= drift
end

--- Validate an entire payload against a schema.
--- Schema format: { fieldName = "expectedType", ... }
function Validator.ValidatePayload(data: any, schema: { [string]: string }): boolean
	if not Validator.IsTable(data) then
		return false
	end
	for field, expectedType in schema do
		if not Validator.HasField(data :: any, field, expectedType) then
			return false
		end
	end
	return true
end

return table.freeze(Validator)
