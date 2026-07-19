--!strict
--[[
	LagCompensation.luau
	Provides hit validation with server-side rewind.
	
	When an attacker fires a hit request, the server rewinds the target's position
	to where the attacker SAW them (accounting for network latency), then checks
	whether the hitbox actually overlapped at that historical position.
	
	Rewind is capped at MAX_REWIND_TICKS (12 ticks = 200ms) to prevent abuse.
	
	Usage:
		local lagComp = LagCompensation.new(12)
		local rewindTick = lagComp:CalculateRewindTick(serverTick, attackerLatencyMs)
		local wasHit = lagComp:ValidateHit(hitboxParams, targetHistory, rewindTick)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Data.Constants)

local PositionHistory = require(script.Parent.PositionHistory)

export type RewindResult = {
	Hit: boolean,
	RewindTick: number,
	RewindPosition: Vector3?,
	RewindRotation: CFrame?,
	WasInvulnerable: boolean,
}

local LagCompensation = {}
LagCompensation.__index = LagCompensation

export type LagCompensation = typeof(setmetatable({} :: {
	_maxRewindTicks: number,
}, LagCompensation))

function LagCompensation.new(maxRewindTicks: number?): LagCompensation
	local self = setmetatable({}, LagCompensation) :: any
	self._maxRewindTicks = maxRewindTicks or Constants.MAX_REWIND_TICKS
	return self
end

--[[
	Calculate the tick to rewind to based on attacker's latency.
	@param serverTick — Current server tick
	@param latencyMs — Attacker's one-way latency in milliseconds
	@return The tick to use for target position lookup
]]
function LagCompensation.CalculateRewindTick(self: LagCompensation, serverTick: number, latencyMs: number): number
	local latencyTicks = math.ceil((latencyMs / 1000) * Constants.TICK_RATE)
	latencyTicks = math.min(latencyTicks, self._maxRewindTicks)
	return math.max(0, serverTick - latencyTicks)
end

--[[
	Validate a hit against a target's historical position.
	@param hitboxOrigin — Attacker's CFrame at time of attack
	@param hitboxSize — Size of the hitbox region
	@param hitboxOffset — Offset from attacker's CFrame
	@param targetHistory — Target's PositionHistory buffer
	@param rewindTick — The tick to check against
	@param targetSize — Target's hurtbox bounding size
	@return RewindResult with hit status and rewind data
]]
function LagCompensation.ValidateHit(
	self: LagCompensation,
	hitboxOrigin: CFrame,
	hitboxSize: Vector3,
	hitboxOffset: Vector3,
	targetHistory: typeof(PositionHistory.new()),
	rewindTick: number,
	targetSize: Vector3
): RewindResult
	-- Get target position at rewind tick
	local position, rotation, isInvulnerable = targetHistory:GetInterpolated(rewindTick)

	if not position then
		return {
			Hit = false,
			RewindTick = rewindTick,
			RewindPosition = nil,
			RewindRotation = nil,
			WasInvulnerable = false,
		}
	end

	-- Target was invulnerable at that tick
	if isInvulnerable then
		return {
			Hit = false,
			RewindTick = rewindTick,
			RewindPosition = position,
			RewindRotation = rotation,
			WasInvulnerable = true,
		}
	end

	-- Calculate hitbox world position
	local hitboxCFrame = hitboxOrigin * CFrame.new(hitboxOffset)
	local hitboxMin = hitboxCFrame.Position - hitboxSize / 2
	local hitboxMax = hitboxCFrame.Position + hitboxSize / 2

	-- Calculate target bounds at historical position
	local targetMin = position - targetSize / 2
	local targetMax = position + targetSize / 2

	-- AABB overlap check
	local overlaps = hitboxMin.X <= targetMax.X
		and hitboxMax.X >= targetMin.X
		and hitboxMin.Y <= targetMax.Y
		and hitboxMax.Y >= targetMin.Y
		and hitboxMin.Z <= targetMax.Z
		and hitboxMax.Z >= targetMin.Z

	return {
		Hit = overlaps,
		RewindTick = rewindTick,
		RewindPosition = position,
		RewindRotation = rotation,
		WasInvulnerable = false,
	}
end

--[[
	Get the maximum allowed rewind in ticks.
]]
function LagCompensation.GetMaxRewindTicks(self: LagCompensation): number
	return self._maxRewindTicks
end

--[[
	Check if a given latency exceeds the compensation window.
	Players beyond this threshold are at a disadvantage.
]]
function LagCompensation.IsLatencyExcessive(self: LagCompensation, latencyMs: number): boolean
	local latencyTicks = math.ceil((latencyMs / 1000) * Constants.TICK_RATE)
	return latencyTicks > self._maxRewindTicks
end

return LagCompensation
