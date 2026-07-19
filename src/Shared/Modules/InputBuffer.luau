--!strict
--[[
	InputBuffer.luau
	Rolling input buffer that stores recent inputs for a configurable window.
	Allows players to input commands slightly before they become valid,
	and the system will execute them on the first valid frame.
	
	Usage:
		local buffer = InputBuffer.new(6) -- 6 frame window
		buffer:Push("Light", currentFrame)
		local input = buffer:Consume(currentFrame) -- returns oldest valid input or nil
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Data.Constants)

export type BufferedInput = {
	Action: string,
	Frame: number,
	Timestamp: number,
	Consumed: boolean,
}

local InputBuffer = {}
InputBuffer.__index = InputBuffer

export type InputBuffer = typeof(setmetatable({} :: {
	_buffer: { BufferedInput },
	_bufferWindow: number,
	_maxSize: number,
}, InputBuffer))

function InputBuffer.new(bufferWindow: number?): InputBuffer
	local self = setmetatable({}, InputBuffer) :: any
	self._buffer = {}
	self._bufferWindow = bufferWindow or Constants.INPUT_BUFFER_FRAMES
	self._maxSize = 16 -- prevent memory issues from spam
	return self
end

--[[
	Push a new input into the buffer.
	@param action — The input action (e.g., "Light", "Heavy", "Parry", "Dodge")
	@param frame — The current game frame when the input was received
]]
function InputBuffer.Push(self: InputBuffer, action: string, frame: number)
	local entry: BufferedInput = {
		Action = action,
		Frame = frame,
		Timestamp = os.clock(),
		Consumed = false,
	}

	table.insert(self._buffer, entry)

	-- Trim to max size (remove oldest)
	while #self._buffer > self._maxSize do
		table.remove(self._buffer, 1)
	end
end

--[[
	Consume the oldest valid (non-expired, non-consumed) input.
	Returns the action string if found, nil otherwise.
	@param currentFrame — The current game frame
]]
function InputBuffer.Consume(self: InputBuffer, currentFrame: number): string?
	self:_pruneExpired(currentFrame)

	for _, entry in self._buffer do
		if not entry.Consumed then
			entry.Consumed = true
			return entry.Action
		end
	end

	return nil
end

--[[
	Peek at the next buffered input without consuming it.
]]
function InputBuffer.Peek(self: InputBuffer, currentFrame: number): string?
	self:_pruneExpired(currentFrame)

	for _, entry in self._buffer do
		if not entry.Consumed then
			return entry.Action
		end
	end

	return nil
end

--[[
	Check if there's a specific action in the buffer.
]]
function InputBuffer.Has(self: InputBuffer, action: string, currentFrame: number): boolean
	self:_pruneExpired(currentFrame)

	for _, entry in self._buffer do
		if not entry.Consumed and entry.Action == action then
			return true
		end
	end

	return false
end

--[[
	Consume a specific action from the buffer (not just the oldest).
	Returns true if found and consumed.
]]
function InputBuffer.ConsumeSpecific(self: InputBuffer, action: string, currentFrame: number): boolean
	self:_pruneExpired(currentFrame)

	for _, entry in self._buffer do
		if not entry.Consumed and entry.Action == action then
			entry.Consumed = true
			return true
		end
	end

	return false
end

--[[
	Clear all buffered inputs.
]]
function InputBuffer.Clear(self: InputBuffer)
	table.clear(self._buffer)
end

--[[
	Get the number of unconsumed inputs currently buffered.
]]
function InputBuffer.Count(self: InputBuffer, currentFrame: number): number
	self:_pruneExpired(currentFrame)

	local count = 0
	for _, entry in self._buffer do
		if not entry.Consumed then
			count += 1
		end
	end
	return count
end

-- ═══════════════════════════════════════════════════
-- PRIVATE
-- ═══════════════════════════════════════════════════

function InputBuffer._pruneExpired(self: InputBuffer, currentFrame: number)
	local i = 1
	while i <= #self._buffer do
		local entry = self._buffer[i]
		local age = currentFrame - entry.Frame
		if age > self._bufferWindow or entry.Consumed then
			table.remove(self._buffer, i)
		else
			i += 1
		end
	end
end

return InputBuffer
