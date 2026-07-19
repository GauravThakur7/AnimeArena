--!strict
--[[
	PositionValidator.luau
	Anti-speed and anti-teleport detection.
	
	Each tick, validates that a player's position delta does not exceed
	the maximum possible movement speed (with tolerance).
	
	After consecutive violations exceed the threshold, snaps the player
	back to their last valid position and flags them.
	
	Usage:
		local validator = PositionValidator.new()
		validator:Update(player, currentPosition, dt, maxSpeed)
		if validator:IsViolating(player) then ... end
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Data.Constants)

local PositionValidator = {}
PositionValidator.__index = PositionValidator

export type PlayerValidationState = {
	LastValidPosition: Vector3,
	LastUpdateTime: number,
	ConsecutiveViolations: number,
	TotalViolations: number,
	IsFlagged: boolean,
}

export type PositionValidator = typeof(setmetatable({} :: {
	_states: { [Player]: PlayerValidationState },
	_tolerance: number,
	_maxConsecutiveViolations: number,
	_flagThreshold: number,
	_onViolation: ((player: Player, distance: number, maxAllowed: number) -> ())?,
	_onFlag: ((player: Player, totalViolations: number) -> ())?,
}, PositionValidator))

function PositionValidator.new(): PositionValidator
	local self = setmetatable({}, PositionValidator) :: any
	self._states = {}
	self._tolerance = Constants.SPEED_TOLERANCE -- 1.2x (20% over max speed allowed)
	self._maxConsecutiveViolations = 3
	self._flagThreshold = 10 -- total violations before flagging
	self._onViolation = nil
	self._onFlag = nil
	return self
end

--[[
	Set callback for when a violation is detected.
]]
function PositionValidator.SetOnViolation(self: PositionValidator, callback: (Player, number, number) -> ())
	self._onViolation = callback
end

--[[
	Set callback for when a player is flagged (excessive violations).
]]
function PositionValidator.SetOnFlag(self: PositionValidator, callback: (Player, number) -> ())
	self._onFlag = callback
end

--[[
	Initialize tracking for a player.
]]
function PositionValidator.AddPlayer(self: PositionValidator, player: Player, initialPosition: Vector3)
	self._states[player] = {
		LastValidPosition = initialPosition,
		LastUpdateTime = os.clock(),
		ConsecutiveViolations = 0,
		TotalViolations = 0,
		IsFlagged = false,
	}
end

--[[
	Remove tracking for a player.
]]
function PositionValidator.RemovePlayer(self: PositionValidator, player: Player)
	self._states[player] = nil
end

--[[
	Validate a player's current position against their last valid position.
	@param player — The player to validate
	@param currentPosition — Their current position
	@param dt — Delta time since last check
	@param maxSpeed — Maximum allowed speed for this player (accounts for buffs/debuffs)
	@return true if position is valid, false if violation detected
]]
function PositionValidator.Validate(
	self: PositionValidator,
	player: Player,
	currentPosition: Vector3,
	dt: number,
	maxSpeed: number?
): boolean
	local state = self._states[player]
	if not state then
		return true -- Not tracked
	end

	local speed = maxSpeed or Constants.BASE_SPRINT_SPEED
	local maxAllowedDistance = speed * self._tolerance * dt

	-- Account for physics (falling, being launched) — allow vertical movement
	local horizontalDelta = Vector3.new(
		currentPosition.X - state.LastValidPosition.X,
		0,
		currentPosition.Z - state.LastValidPosition.Z
	).Magnitude

	if horizontalDelta <= maxAllowedDistance then
		-- Valid movement
		state.LastValidPosition = currentPosition
		state.LastUpdateTime = os.clock()
		state.ConsecutiveViolations = 0
		return true
	end

	-- Violation detected
	state.ConsecutiveViolations += 1
	state.TotalViolations += 1

	if self._onViolation then
		self._onViolation(player, horizontalDelta, maxAllowedDistance)
	end

	-- Check if threshold exceeded
	if state.ConsecutiveViolations >= self._maxConsecutiveViolations then
		-- Snap back to last valid position
		local character = player.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				root.CFrame = CFrame.new(state.LastValidPosition)
			end
		end
		state.ConsecutiveViolations = 0
	end

	-- Flag player if total violations excessive
	if state.TotalViolations >= self._flagThreshold and not state.IsFlagged then
		state.IsFlagged = true
		if self._onFlag then
			self._onFlag(player, state.TotalViolations)
		end
	end

	return false
end

--[[
	Get the last valid position for a player.
]]
function PositionValidator.GetLastValidPosition(self: PositionValidator, player: Player): Vector3?
	local state = self._states[player]
	if state then
		return state.LastValidPosition
	end
	return nil
end

--[[
	Check if a player is currently flagged.
]]
function PositionValidator.IsFlagged(self: PositionValidator, player: Player): boolean
	local state = self._states[player]
	return state ~= nil and state.IsFlagged
end

--[[
	Check if player has active consecutive violations.
]]
function PositionValidator.IsViolating(self: PositionValidator, player: Player): boolean
	local state = self._states[player]
	return state ~= nil and state.ConsecutiveViolations > 0
end

--[[
	Get violation stats for a player.
]]
function PositionValidator.GetStats(self: PositionValidator, player: Player): PlayerValidationState?
	return self._states[player]
end

--[[
	Reset all violation counts for a player (e.g., after teleport by game logic).
]]
function PositionValidator.ResetViolations(self: PositionValidator, player: Player, newPosition: Vector3?)
	local state = self._states[player]
	if state then
		state.ConsecutiveViolations = 0
		if newPosition then
			state.LastValidPosition = newPosition
		end
	end
end

return PositionValidator
