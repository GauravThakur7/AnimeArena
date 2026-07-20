--!strict
--[[
	RootMotion.luau
	Applies root motion from animations to character position.
	
	When enabled for an animation, the character's HumanoidRootPart is displaced
	by the animation's root bone movement rather than using Humanoid WalkSpeed.
	
	Used for: attack lunges, dodge rolls, slide displacement, execution cinematics.
	
	Usage:
		local rm = RootMotion.new(rootPart)
		rm:Enable(direction, distance, duration) -- during an attack lunge
		rm:Tick(dt)
		rm:Disable()
]]

local RootMotion = {}
RootMotion.__index = RootMotion

export type RootMotionConfig = {
	Direction: Vector3,
	Distance: number,
	Duration: number,
	EaseType: "Linear" | "EaseOut" | "EaseIn"?,
}

export type RootMotion = typeof(setmetatable({} :: {
	_rootPart: BasePart?,
	_active: boolean,
	_direction: Vector3,
	_distance: number,
	_duration: number,
	_elapsed: number,
	_easeType: string,
	_startPosition: Vector3,
}, RootMotion))

function RootMotion.new(rootPart: BasePart?): RootMotion
	local self = setmetatable({}, RootMotion) :: any
	self._rootPart = rootPart
	self._active = false
	self._direction = Vector3.zero
	self._distance = 0
	self._duration = 0
	self._elapsed = 0
	self._easeType = "EaseOut"
	self._startPosition = Vector3.zero
	return self
end

--[[
	Set the root part reference.
]]
function RootMotion.SetRootPart(self: RootMotion, rootPart: BasePart)
	self._rootPart = rootPart
end

--[[
	Enable root motion with a displacement config.
	Used for attack lunges, forward steps during combos, etc.
]]
function RootMotion.Enable(self: RootMotion, config: RootMotionConfig)
	if not self._rootPart then
		return
	end

	self._active = true
	self._direction = config.Direction.Unit
	self._distance = config.Distance
	self._duration = config.Duration
	self._elapsed = 0
	self._easeType = config.EaseType or "EaseOut"
	self._startPosition = self._rootPart.Position
end

--[[
	Advance root motion by dt. Applies velocity to root part.
	Returns true if still active.
]]
function RootMotion.Tick(self: RootMotion, dt: number): boolean
	if not self._active or not self._rootPart then
		return false
	end

	self._elapsed += dt

	if self._elapsed >= self._duration then
		self._active = false
		-- Zero velocity
		local vel = self._rootPart.AssemblyLinearVelocity
		self._rootPart.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
		return false
	end

	-- Calculate speed based on ease type
	local progress = self._elapsed / self._duration
	local speed: number

	if self._easeType == "EaseOut" then
		-- Fast start, slow end
		speed = (1 - progress * progress) * (self._distance / self._duration) * 2
	elseif self._easeType == "EaseIn" then
		-- Slow start, fast end
		speed = (progress * progress) * (self._distance / self._duration) * 2
	else
		-- Linear
		speed = self._distance / self._duration
	end

	-- Apply velocity
	local velocity = self._direction * speed
	local currentVel = self._rootPart.AssemblyLinearVelocity
	self._rootPart.AssemblyLinearVelocity = Vector3.new(velocity.X, currentVel.Y, velocity.Z)

	return true
end

--[[
	Check if root motion is currently active.
]]
function RootMotion.IsActive(self: RootMotion): boolean
	return self._active
end

--[[
	Cancel root motion immediately.
]]
function RootMotion.Disable(self: RootMotion)
	self._active = false
	if self._rootPart then
		local vel = self._rootPart.AssemblyLinearVelocity
		self._rootPart.AssemblyLinearVelocity = Vector3.new(0, vel.Y, 0)
	end
end

--[[
	Get progress (0-1) of current root motion.
]]
function RootMotion.GetProgress(self: RootMotion): number
	if not self._active then
		return 0
	end
	return math.clamp(self._elapsed / self._duration, 0, 1)
end

return RootMotion
