--!strict
--[[
	HitboxSystem.luau
	Server-side spatial hit detection using overlap region checks.
	Creates temporary hitbox regions during active attack frames,
	checks them against target hurtboxes, and returns hit results.
	
	Does NOT create Instances — works with pure math for server validation.
	Visual hitbox debug rendering is handled separately on client.
	
	Usage:
		local hitbox = HitboxSystem.new()
		local hits = hitbox:CheckHit(attackerCFrame, hitboxSize, hitboxOffset, targets)
]]

export type HitboxParams = {
	Origin: CFrame, -- attacker's CFrame
	Size: Vector3, -- hitbox dimensions
	Offset: Vector3, -- offset from origin (usually forward)
	OwnerId: number, -- player UserId who owns this hitbox
}

export type HurtboxData = {
	PlayerId: number,
	Position: Vector3,
	Size: Vector3, -- character bounding box
	Zone: string, -- "Head" | "Body" | "Legs" based on hit point
	IsInvulnerable: boolean,
}

export type HitResult = {
	TargetId: number,
	HitPosition: Vector3,
	HurtboxZone: string,
	Distance: number,
}

local HitboxSystem = {}
HitboxSystem.__index = HitboxSystem

export type HitboxSystem = typeof(setmetatable({} :: {
	_hitHistory: { [string]: number }, -- "attackerId_targetId_tick" → tick (prevents double-hit)
	_currentTick: number,
}, HitboxSystem))

function HitboxSystem.new(): HitboxSystem
	local self = setmetatable({}, HitboxSystem) :: any
	self._hitHistory = {}
	self._currentTick = 0
	return self
end

--[[
	Set the current server tick (for hit history tracking).
]]
function HitboxSystem.SetTick(self: HitboxSystem, tick: number)
	self._currentTick = tick
end

--[[
	Check for hits between an attacker's hitbox and a list of potential targets.
	Returns a list of HitResults for all targets whose hurtbox overlaps the hitbox.
	Filters out: self-hit, invulnerable targets, already-hit-this-swing targets.
]]
function HitboxSystem.CheckHit(self: HitboxSystem, params: HitboxParams, targets: { HurtboxData }): { HitResult }
	local results: { HitResult } = {}

	-- Calculate world-space hitbox bounds
	local hitboxCFrame = params.Origin * CFrame.new(params.Offset)
	local hitboxMin = hitboxCFrame.Position - params.Size / 2
	local hitboxMax = hitboxCFrame.Position + params.Size / 2

	for _, target in targets do
		-- Skip self
		if target.PlayerId == params.OwnerId then
			continue
		end

		-- Skip invulnerable
		if target.IsInvulnerable then
			continue
		end

		-- Skip already hit this swing
		local hitKey = `{params.OwnerId}_{target.PlayerId}_{self._currentTick}`
		if self._hitHistory[hitKey] then
			continue
		end

		-- AABB overlap check
		local targetMin = target.Position - target.Size / 2
		local targetMax = target.Position + target.Size / 2

		if self:_aabbOverlap(hitboxMin, hitboxMax, targetMin, targetMax) then
			-- Determine hit zone based on vertical hit point
			local hitPoint = self:_getHitPoint(hitboxCFrame.Position, target.Position, target.Size)
			local zone = self:_determineZone(hitPoint, target.Position, target.Size)
			local distance = (hitboxCFrame.Position - target.Position).Magnitude

			-- Record hit to prevent double-hit
			self._hitHistory[hitKey] = self._currentTick

			table.insert(results, {
				TargetId = target.PlayerId,
				HitPosition = hitPoint,
				HurtboxZone = zone,
				Distance = distance,
			})
		end
	end

	return results
end

--[[
	Clear hit history for a specific attacker (new swing starts).
]]
function HitboxSystem.ClearHitHistory(self: HitboxSystem, attackerId: number)
	local keysToRemove = {}
	for key in self._hitHistory do
		if string.find(key, tostring(attackerId) .. "_") == 1 then
			table.insert(keysToRemove, key)
		end
	end
	for _, key in keysToRemove do
		self._hitHistory[key] = nil
	end
end

--[[
	Clear all hit history older than N ticks (garbage collection).
]]
function HitboxSystem.PruneHistory(self: HitboxSystem, maxAge: number)
	local keysToRemove = {}
	for key, tick in self._hitHistory do
		if self._currentTick - tick > maxAge then
			table.insert(keysToRemove, key)
		end
	end
	for _, key in keysToRemove do
		self._hitHistory[key] = nil
	end
end

-- ═══════════════════════════════════════════════════
-- PRIVATE
-- ═══════════════════════════════════════════════════

--[[
	Axis-Aligned Bounding Box overlap check.
]]
function HitboxSystem._aabbOverlap(
	self: HitboxSystem,
	aMin: Vector3,
	aMax: Vector3,
	bMin: Vector3,
	bMax: Vector3
): boolean
	return aMin.X <= bMax.X
		and aMax.X >= bMin.X
		and aMin.Y <= bMax.Y
		and aMax.Y >= bMin.Y
		and aMin.Z <= bMax.Z
		and aMax.Z >= bMin.Z
end

--[[
	Get the approximate hit point (closest point on target to hitbox center).
]]
function HitboxSystem._getHitPoint(self: HitboxSystem, hitboxCenter: Vector3, targetPos: Vector3, targetSize: Vector3): Vector3
	local halfSize = targetSize / 2
	local clamped = Vector3.new(
		math.clamp(hitboxCenter.X, targetPos.X - halfSize.X, targetPos.X + halfSize.X),
		math.clamp(hitboxCenter.Y, targetPos.Y - halfSize.Y, targetPos.Y + halfSize.Y),
		math.clamp(hitboxCenter.Z, targetPos.Z - halfSize.Z, targetPos.Z + halfSize.Z)
	)
	return clamped
end

--[[
	Determine which zone (Head/Body/Legs) was hit based on vertical position.
]]
function HitboxSystem._determineZone(self: HitboxSystem, hitPoint: Vector3, targetPos: Vector3, targetSize: Vector3): string
	local relativeY = (hitPoint.Y - targetPos.Y) / targetSize.Y + 0.5 -- 0 = bottom, 1 = top

	if relativeY >= 0.75 then
		return "Head"
	elseif relativeY >= 0.35 then
		return "Body"
	else
		return "Legs"
	end
end

return HitboxSystem
