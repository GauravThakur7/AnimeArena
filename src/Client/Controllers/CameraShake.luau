--!strict
--[[
	CameraShake.luau
	Reusable camera shake system with spring-based decay.
	
	Generates randomized offset vectors that decay over time.
	Multiple shakes can stack (additive).
	
	Usage:
		local shake = CameraShake.new()
		shake:Shake(0.5, 1.0) -- intensity 0.5, duration 1.0s
		local offset = shake:Update(dt) -- returns Vector3 offset to apply to camera
]]

local CameraShake = {}
CameraShake.__index = CameraShake

export type ShakeInstance = {
	Intensity: number,
	Duration: number,
	Elapsed: number,
	Frequency: number,
	Seed: number,
}

export type CameraShake = typeof(setmetatable({} :: {
	_shakes: { ShakeInstance },
	_currentOffset: Vector3,
	_maxShakes: number,
}, CameraShake))

function CameraShake.new(): CameraShake
	local self = setmetatable({}, CameraShake) :: any
	self._shakes = {}
	self._currentOffset = Vector3.zero
	self._maxShakes = 5 -- prevent stacking too many
	return self
end

--[[
	Start a new camera shake.
	@param intensity — Maximum displacement in studs (0.1 = subtle, 1.0 = violent)
	@param duration — How long the shake lasts in seconds
	@param frequency — Oscillation speed (default 25)
]]
function CameraShake.Shake(self: CameraShake, intensity: number, duration: number, frequency: number?)
	if #self._shakes >= self._maxShakes then
		-- Replace weakest shake
		local weakest = 1
		for i, s in self._shakes do
			if s.Intensity < self._shakes[weakest].Intensity then
				weakest = i
			end
		end
		table.remove(self._shakes, weakest)
	end

	table.insert(self._shakes, {
		Intensity = intensity,
		Duration = duration,
		Elapsed = 0,
		Frequency = frequency or 25,
		Seed = math.random(0, 1000),
	})
end

--[[
	Preset: Light hit shake.
]]
function CameraShake.ShakeLight(self: CameraShake)
	self:Shake(0.15, 0.12, 30)
end

--[[
	Preset: Heavy hit shake.
]]
function CameraShake.ShakeHeavy(self: CameraShake)
	self:Shake(0.4, 0.2, 20)
end

--[[
	Preset: Parry flash shake.
]]
function CameraShake.ShakeParry(self: CameraShake)
	self:Shake(0.25, 0.15, 35)
end

--[[
	Preset: Ultimate/execution dramatic shake.
]]
function CameraShake.ShakeDramatic(self: CameraShake)
	self:Shake(0.8, 0.5, 15)
end

--[[
	Update all active shakes and return the combined offset.
	Call this every frame.
	@param dt — Delta time
	@return Combined Vector3 offset to add to camera CFrame
]]
function CameraShake.Update(self: CameraShake, dt: number): Vector3
	local totalOffset = Vector3.zero
	local i = 1

	while i <= #self._shakes do
		local shake = self._shakes[i]
		shake.Elapsed += dt

		if shake.Elapsed >= shake.Duration then
			table.remove(self._shakes, i)
			-- don't increment i
		else
			-- Calculate decay (linear fade out)
			local progress = shake.Elapsed / shake.Duration
			local decay = 1.0 - progress

			-- Generate pseudo-random offset using sin waves with seed
			local time = shake.Elapsed * shake.Frequency
			local seed = shake.Seed
			local offsetX = math.sin(time * 1.0 + seed) * shake.Intensity * decay
			local offsetY = math.sin(time * 1.3 + seed * 0.7) * shake.Intensity * decay
			local offsetZ = math.sin(time * 0.8 + seed * 1.3) * shake.Intensity * decay * 0.5

			totalOffset += Vector3.new(offsetX, offsetY, offsetZ)
			i += 1
		end
	end

	self._currentOffset = totalOffset
	return totalOffset
end

--[[
	Get the current shake offset without updating.
]]
function CameraShake.GetOffset(self: CameraShake): Vector3
	return self._currentOffset
end

--[[
	Check if any shake is currently active.
]]
function CameraShake.IsShaking(self: CameraShake): boolean
	return #self._shakes > 0
end

--[[
	Cancel all active shakes.
]]
function CameraShake.Cancel(self: CameraShake)
	table.clear(self._shakes)
	self._currentOffset = Vector3.zero
end

return CameraShake
