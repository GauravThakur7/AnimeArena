--!strict
--[[
	MomentumSystem.luau
	Pure math module for movement momentum (acceleration/deceleration).
	
	Provides smooth speed transitions instead of instant velocity changes.
	Used by MovementController for responsive but weighty movement feel.
	
	Usage:
		local momentum = MomentumSystem.new(config)
		momentum:SetTargetSpeed(28) -- want to sprint
		momentum:Tick(dt)
		local currentSpeed = momentum:GetSpeed()
]]

local MomentumSystem = {}
MomentumSystem.__index = MomentumSystem

export type MomentumConfig = {
	MaxWalkSpeed: number,
	MaxRunSpeed: number,
	MaxSprintSpeed: number,
	Acceleration: number, -- units/sec² to reach target speed
	Deceleration: number, -- units/sec² to stop
	TurnDeceleration: number, -- extra deceleration when changing direction sharply
	AirAcceleration: number, -- reduced acceleration while airborne
	AirDeceleration: number,
}

export type MomentumSystem = typeof(setmetatable({} :: {
	_config: MomentumConfig,
	_currentSpeed: number,
	_targetSpeed: number,
	_currentDirection: Vector3,
	_targetDirection: Vector3,
	_isGrounded: boolean,
}, MomentumSystem))

local DEFAULT_CONFIG: MomentumConfig = {
	MaxWalkSpeed = 12,
	MaxRunSpeed = 20,
	MaxSprintSpeed = 22,
	Acceleration = 50, -- reaches run speed in ~0.4s
	Deceleration = 80, -- stops in ~0.25s from run speed
	TurnDeceleration = 30, -- extra slowdown on sharp turns
	AirAcceleration = 25,
	AirDeceleration = 15,
}

function MomentumSystem.new(config: MomentumConfig?): MomentumSystem
	local self = setmetatable({}, MomentumSystem) :: any
	self._config = config or DEFAULT_CONFIG
	self._currentSpeed = 0
	self._targetSpeed = 0
	self._currentDirection = Vector3.new(0, 0, -1)
	self._targetDirection = Vector3.new(0, 0, -1)
	self._isGrounded = true
	return self
end

--[[
	Set the desired target speed (0 = stop, walk/run/sprint values).
]]
function MomentumSystem.SetTargetSpeed(self: MomentumSystem, speed: number)
	self._targetSpeed = math.clamp(speed, 0, self._config.MaxSprintSpeed)
end

--[[
	Set the desired movement direction (normalized XZ vector).
]]
function MomentumSystem.SetTargetDirection(self: MomentumSystem, direction: Vector3)
	local mag = direction.Magnitude
	if mag < 0.01 then
		return
	end
	self._targetDirection = direction / mag
end

--[[
	Set grounded state (affects acceleration curves).
]]
function MomentumSystem.SetGrounded(self: MomentumSystem, grounded: boolean)
	self._isGrounded = grounded
end

--[[
	Advance momentum simulation by dt seconds.
]]
function MomentumSystem.Tick(self: MomentumSystem, dt: number)
	local accel: number
	local decel: number

	if self._isGrounded then
		accel = self._config.Acceleration
		decel = self._config.Deceleration
	else
		accel = self._config.AirAcceleration
		decel = self._config.AirDeceleration
	end

	-- Apply turn deceleration when changing direction sharply
	local dot = self._currentDirection:Dot(self._targetDirection)
	if dot < 0.5 and self._currentSpeed > 5 then
		-- Sharp turn: apply extra deceleration
		self._currentSpeed = math.max(0, self._currentSpeed - self._config.TurnDeceleration * dt)
	end

	-- Accelerate or decelerate toward target speed
	if self._targetSpeed > self._currentSpeed then
		self._currentSpeed = math.min(self._targetSpeed, self._currentSpeed + accel * dt)
	elseif self._targetSpeed < self._currentSpeed then
		self._currentSpeed = math.max(self._targetSpeed, self._currentSpeed - decel * dt)
	end

	-- Smoothly rotate direction toward target
	if self._currentSpeed > 0.1 then
		local turnRate = 15 -- radians per second equivalent for lerp
		local alpha = math.clamp(turnRate * dt, 0, 1)
		self._currentDirection = self._currentDirection:Lerp(self._targetDirection, alpha).Unit
	else
		self._currentDirection = self._targetDirection
	end
end

--[[
	Get current speed.
]]
function MomentumSystem.GetSpeed(self: MomentumSystem): number
	return self._currentSpeed
end

--[[
	Get current movement direction (normalized).
]]
function MomentumSystem.GetDirection(self: MomentumSystem): Vector3
	return self._currentDirection
end

--[[
	Get the velocity vector (direction × speed).
]]
function MomentumSystem.GetVelocity(self: MomentumSystem): Vector3
	return self._currentDirection * self._currentSpeed
end

--[[
	Get speed as a fraction of max sprint speed (0-1).
]]
function MomentumSystem.GetSpeedPercent(self: MomentumSystem): number
	return self._currentSpeed / self._config.MaxSprintSpeed
end

--[[
	Check if currently moving.
]]
function MomentumSystem.IsMoving(self: MomentumSystem): boolean
	return self._currentSpeed > 0.5
end

--[[
	Check if at sprint speed.
]]
function MomentumSystem.IsSprinting(self: MomentumSystem): boolean
	return self._currentSpeed >= self._config.MaxSprintSpeed * 0.9
end

--[[
	Immediately stop all momentum (e.g., on hit stagger).
]]
function MomentumSystem.HardStop(self: MomentumSystem)
	self._currentSpeed = 0
	self._targetSpeed = 0
end

--[[
	Apply an impulse (instant speed boost in a direction). Used for dashes/knockback.
]]
function MomentumSystem.ApplyImpulse(self: MomentumSystem, direction: Vector3, speed: number)
	local mag = direction.Magnitude
	if mag > 0.01 then
		self._currentDirection = direction / mag
	end
	self._currentSpeed = speed
end

--[[
	Reset to idle state.
]]
function MomentumSystem.Reset(self: MomentumSystem)
	self._currentSpeed = 0
	self._targetSpeed = 0
	self._currentDirection = Vector3.new(0, 0, -1)
	self._targetDirection = Vector3.new(0, 0, -1)
	self._isGrounded = true
end

return MomentumSystem
