--!strict
--[[
	PositionHistory.luau
	Circular buffer that stores position snapshots for lag compensation.
	Records one snapshot per tick. Stores up to 1 second of history (60 entries at 60Hz).
	
	Used by server to rewind target positions when validating hits,
	accounting for the attacker's network latency.
	
	Usage:
		local history = PositionHistory.new(60)
		history:Record(tick, position, rotation, combatState, isInvulnerable)
		local snapshot = history:GetAtTick(targetTick)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Data.Constants)

export type Snapshot = {
	Tick: number,
	Position: Vector3,
	Rotation: CFrame,
	CombatState: string,
	IsInvulnerable: boolean,
}

local PositionHistory = {}
PositionHistory.__index = PositionHistory

export type PositionHistory = typeof(setmetatable({} :: {
	_buffer: { Snapshot },
	_capacity: number,
	_head: number,
	_count: number,
}, PositionHistory))

function PositionHistory.new(capacity: number?): PositionHistory
	local cap = capacity or math.ceil(Constants.POSITION_HISTORY_DURATION * Constants.TICK_RATE)
	local self = setmetatable({}, PositionHistory) :: any
	self._buffer = table.create(cap)
	self._capacity = cap
	self._head = 0
	self._count = 0
	return self
end

--[[
	Record a new snapshot. Overwrites oldest entry when buffer is full.
]]
function PositionHistory.Record(
	self: PositionHistory,
	tick: number,
	position: Vector3,
	rotation: CFrame,
	combatState: string,
	isInvulnerable: boolean
)
	self._head = (self._head % self._capacity) + 1
	self._buffer[self._head] = {
		Tick = tick,
		Position = position,
		Rotation = rotation,
		CombatState = combatState,
		IsInvulnerable = isInvulnerable,
	}
	if self._count < self._capacity then
		self._count += 1
	end
end

--[[
	Retrieve the snapshot closest to the given tick.
	Returns nil if no history is available.
]]
function PositionHistory.GetAtTick(self: PositionHistory, targetTick: number): Snapshot?
	if self._count == 0 then
		return nil
	end

	local bestSnapshot: Snapshot? = nil
	local bestDelta = math.huge

	for i = 1, self._count do
		local idx = ((self._head - i) % self._capacity) + 1
		local snapshot = self._buffer[idx]
		if snapshot then
			local delta = math.abs(snapshot.Tick - targetTick)
			if delta < bestDelta then
				bestDelta = delta
				bestSnapshot = snapshot
			end
			-- Buffer is ordered by tick descending from head, so once delta starts increasing we can stop
			if snapshot.Tick < targetTick then
				break
			end
		end
	end

	return bestSnapshot
end

--[[
	Get interpolated position between two snapshots for a fractional tick.
	Falls back to nearest snapshot if interpolation data unavailable.
]]
function PositionHistory.GetInterpolated(self: PositionHistory, targetTick: number): (Vector3?, CFrame?, boolean?)
	if self._count < 2 then
		local snap = self:GetAtTick(targetTick)
		if snap then
			return snap.Position, snap.Rotation, snap.IsInvulnerable
		end
		return nil, nil, nil
	end

	-- Find the two snapshots bracketing targetTick
	local before: Snapshot? = nil
	local after: Snapshot? = nil

	for i = 1, self._count do
		local idx = ((self._head - i) % self._capacity) + 1
		local snapshot = self._buffer[idx]
		if snapshot then
			if snapshot.Tick <= targetTick then
				before = snapshot
				-- The previous iteration (i-1) would be "after"
				local afterIdx = ((self._head - (i - 1)) % self._capacity) + 1
				after = self._buffer[afterIdx]
				break
			end
		end
	end

	if not before then
		local snap = self:GetAtTick(targetTick)
		if snap then
			return snap.Position, snap.Rotation, snap.IsInvulnerable
		end
		return nil, nil, nil
	end

	if not after or before == after then
		return before.Position, before.Rotation, before.IsInvulnerable
	end

	-- Interpolate
	local tickRange = after.Tick - before.Tick
	if tickRange <= 0 then
		return before.Position, before.Rotation, before.IsInvulnerable
	end

	local alpha = (targetTick - before.Tick) / tickRange
	alpha = math.clamp(alpha, 0, 1)

	local position = before.Position:Lerp(after.Position, alpha)
	local rotation = before.Rotation:Lerp(after.Rotation, alpha)
	local isInvulnerable = before.IsInvulnerable or after.IsInvulnerable

	return position, rotation, isInvulnerable
end

--[[
	Get the most recent snapshot.
]]
function PositionHistory.GetLatest(self: PositionHistory): Snapshot?
	if self._count == 0 then
		return nil
	end
	return self._buffer[self._head]
end

--[[
	Get the oldest snapshot still in buffer.
]]
function PositionHistory.GetOldest(self: PositionHistory): Snapshot?
	if self._count == 0 then
		return nil
	end
	local idx = ((self._head - self._count) % self._capacity) + 1
	return self._buffer[idx]
end

--[[
	Get total number of stored snapshots.
]]
function PositionHistory.GetCount(self: PositionHistory): number
	return self._count
end

--[[
	Clear all history.
]]
function PositionHistory.Clear(self: PositionHistory)
	table.clear(self._buffer)
	self._head = 0
	self._count = 0
end

return PositionHistory
