--!strict
--[[
	MathUtil.luau
	Common math utilities used across the project.
]]

local MathUtil = {}

--- Linearly interpolate between two numbers.
function MathUtil.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

--- Clamp a number between min and max.
function MathUtil.Clamp(value: number, min: number, max: number): number
	return math.clamp(value, min, max)
end

--- Map a value from one range to another.
function MathUtil.Map(value: number, inMin: number, inMax: number, outMin: number, outMax: number): number
	return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end

--- Round to nearest integer.
function MathUtil.Round(value: number): number
	return math.floor(value + 0.5)
end

--- Round to N decimal places.
function MathUtil.RoundTo(value: number, decimals: number): number
	local mult = 10 ^ decimals
	return math.floor(value * mult + 0.5) / mult
end

--- Check if a number is approximately equal to another (within epsilon).
function MathUtil.ApproxEqual(a: number, b: number, epsilon: number?): boolean
	local eps = epsilon or 0.001
	return math.abs(a - b) <= eps
end

--- Convert frames to seconds at 60Hz tick rate.
function MathUtil.FramesToSeconds(frames: number): number
	return frames / 60
end

--- Convert seconds to frames at 60Hz tick rate.
function MathUtil.SecondsToFrames(seconds: number): number
	return math.floor(seconds * 60)
end

--- Calculate distance between two Vector3 positions (XZ plane only, ignores Y).
function MathUtil.HorizontalDistance(a: Vector3, b: Vector3): number
	local dx = a.X - b.X
	local dz = a.Z - b.Z
	return math.sqrt(dx * dx + dz * dz)
end

--- Get a direction vector from one position to another (normalized, XZ plane).
function MathUtil.DirectionXZ(from: Vector3, to: Vector3): Vector3
	local dir = (to - from) * Vector3.new(1, 0, 1)
	local mag = dir.Magnitude
	if mag < 0.001 then
		return Vector3.zero
	end
	return dir / mag
end

return table.freeze(MathUtil)
