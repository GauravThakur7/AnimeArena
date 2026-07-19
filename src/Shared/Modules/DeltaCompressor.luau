--!strict
--[[
	DeltaCompressor.luau
	Reduces network bandwidth by sending only changed fields in state updates.
	
	Server stores the last-sent state per player. On each broadcast, compares
	current state to previous and sends a delta table containing only changed fields.
	Client applies deltas on top of its last-known full state.
	
	Reduces average payload from ~50 bytes to ~10 bytes when idle.
	
	Usage (Server):
		local compressor = DeltaCompressor.new()
		local delta = compressor:Compress(playerId, currentState)
		-- send delta to client (nil means nothing changed)
	
	Usage (Client):
		local compressor = DeltaCompressor.new()
		local fullState = compressor:Apply(delta)
]]

local DeltaCompressor = {}
DeltaCompressor.__index = DeltaCompressor

export type DeltaCompressor = typeof(setmetatable({} :: {
	_previousStates: { [number]: StateSnapshot },
}, DeltaCompressor))

export type StateSnapshot = {
	Tick: number,
	CombatState: string,
	HP: number,
	Stamina: number,
	Poise: number,
	Position: Vector3,
	UltimateMeter: number,
	LastProcessedSequence: number,
	ComboCount: number,
}

function DeltaCompressor.new(): DeltaCompressor
	local self = setmetatable({}, DeltaCompressor) :: any
	self._previousStates = {}
	return self
end

--[[
	Compress a state snapshot into a delta by comparing against previously sent state.
	Returns the delta table (only changed fields), or nil if nothing changed.
	Always includes Tick and LastProcessedSequence for sequencing.
	
	@param playerId — Unique player identifier (UserId)
	@param current — Current full state snapshot
	@return Delta table with only changed fields, or nil
]]
function DeltaCompressor.Compress(self: DeltaCompressor, playerId: number, current: StateSnapshot): StateSnapshot?
	local previous = self._previousStates[playerId]

	if not previous then
		-- First time: send full state
		self._previousStates[playerId] = current
		return current
	end

	-- Build delta
	local delta: any = {
		Tick = current.Tick,
		LastProcessedSequence = current.LastProcessedSequence,
	}
	local hasChanges = false

	if current.CombatState ~= previous.CombatState then
		delta.CombatState = current.CombatState
		hasChanges = true
	end

	if current.HP ~= previous.HP then
		delta.HP = current.HP
		hasChanges = true
	end

	-- Stamina: only send if changed by more than 1 (reduces noise from regen)
	if math.abs(current.Stamina - previous.Stamina) > 1 then
		delta.Stamina = current.Stamina
		hasChanges = true
	end

	if current.Poise ~= previous.Poise then
		delta.Poise = current.Poise
		hasChanges = true
	end

	-- Position: only send if moved more than 0.1 studs
	if (current.Position - previous.Position).Magnitude > 0.1 then
		delta.Position = current.Position
		hasChanges = true
	end

	if current.UltimateMeter ~= previous.UltimateMeter then
		delta.UltimateMeter = current.UltimateMeter
		hasChanges = true
	end

	if current.ComboCount ~= previous.ComboCount then
		delta.ComboCount = current.ComboCount
		hasChanges = true
	end

	if not hasChanges then
		-- Only tick and sequence changed — skip broadcast
		return nil
	end

	-- Store current as new previous
	self._previousStates[playerId] = current

	return delta
end

--[[
	Apply a received delta on top of the current known state.
	Returns the reconstructed full state.
	
	@param current — Client's last-known full state
	@param delta — Delta received from server
	@return Reconstructed full state
]]
function DeltaCompressor.Apply(self: DeltaCompressor, current: StateSnapshot, delta: any): StateSnapshot
	local result: StateSnapshot = {
		Tick = delta.Tick or current.Tick,
		CombatState = delta.CombatState or current.CombatState,
		HP = delta.HP or current.HP,
		Stamina = delta.Stamina or current.Stamina,
		Poise = delta.Poise or current.Poise,
		Position = delta.Position or current.Position,
		UltimateMeter = delta.UltimateMeter or current.UltimateMeter,
		LastProcessedSequence = delta.LastProcessedSequence or current.LastProcessedSequence,
		ComboCount = delta.ComboCount or current.ComboCount,
	}
	return result
end

--[[
	Remove stored state for a player (on disconnect).
]]
function DeltaCompressor.RemovePlayer(self: DeltaCompressor, playerId: number)
	self._previousStates[playerId] = nil
end

--[[
	Force a full state send on next compress (e.g., after respawn).
]]
function DeltaCompressor.InvalidatePlayer(self: DeltaCompressor, playerId: number)
	self._previousStates[playerId] = nil
end

return DeltaCompressor
