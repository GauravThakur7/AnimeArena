--!strict
--[[
	KillCam.luau
	Brief cinematic camera on death. Shows the attacker from a dramatic angle.
	
	Duration: 2 seconds
	Effect: Camera snaps to attacker's position, slight slow-motion feel,
	then returns to normal spectator/respawn camera.
	
	Usage:
		local killCam = KillCam.new()
		killCam:Activate(attackerPosition, victimPosition)
		killCam:Update(dt) -- call each frame while active
]]

local TweenService = game:GetService("TweenService")

local KillCam = {}
KillCam.__index = KillCam

export type KillCam = typeof(setmetatable({} :: {
	_active: boolean,
	_duration: number,
	_elapsed: number,
	_camera: Camera?,
	_startCFrame: CFrame,
	_targetCFrame: CFrame,
	_originalCameraType: Enum.CameraType?,
	_onComplete: (() -> ())?,
}, KillCam))

function KillCam.new(): KillCam
	local self = setmetatable({}, KillCam) :: any
	self._active = false
	self._duration = 2.0
	self._elapsed = 0
	self._camera = nil
	self._startCFrame = CFrame.identity
	self._targetCFrame = CFrame.identity
	self._originalCameraType = nil
	self._onComplete = nil
	return self
end

--[[
	Activate the kill cam.
	@param attackerPosition — Where the attacker is standing
	@param victimPosition — Where the victim died
	@param onComplete — Callback when kill cam finishes
]]
function KillCam.Activate(
	self: KillCam,
	attackerPosition: Vector3,
	victimPosition: Vector3,
	onComplete: (() -> ())?
)
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	self._camera = camera
	self._active = true
	self._elapsed = 0
	self._onComplete = onComplete

	-- Store original camera state
	self._originalCameraType = camera.CameraType
	self._startCFrame = camera.CFrame

	-- Calculate cinematic angle: offset from attacker looking at victim
	local dirToVictim = (victimPosition - attackerPosition)
	local flatDir = Vector3.new(dirToVictim.X, 0, dirToVictim.Z)
	if flatDir.Magnitude < 0.1 then
		flatDir = Vector3.new(0, 0, -1)
	end
	flatDir = flatDir.Unit

	-- Position camera behind and above the attacker, looking at the victim
	local cameraPos = attackerPosition - flatDir * 8 + Vector3.new(0, 4, 0)
	local lookAt = victimPosition + Vector3.new(0, 2, 0)

	self._targetCFrame = CFrame.lookAt(cameraPos, lookAt)

	-- Take control of camera
	camera.CameraType = Enum.CameraType.Scriptable
end

--[[
	Update the kill cam each frame. Returns true if still active.
]]
function KillCam.Update(self: KillCam, dt: number): boolean
	if not self._active or not self._camera then
		return false
	end

	self._elapsed += dt

	-- Smooth interpolation from start to target
	local progress = math.clamp(self._elapsed / self._duration, 0, 1)

	-- Ease-out curve for dramatic slow-down feel
	local eased = 1 - (1 - progress) ^ 2

	-- For first 0.3s: quick snap to cinematic angle
	-- For remaining: hold with slight drift
	if self._elapsed < 0.3 then
		local snapAlpha = math.clamp(self._elapsed / 0.3, 0, 1)
		self._camera.CFrame = self._startCFrame:Lerp(self._targetCFrame, snapAlpha)
	else
		-- Slow drift upward for drama
		local drift = Vector3.new(0, 0.3 * (self._elapsed - 0.3), 0)
		self._camera.CFrame = self._targetCFrame + drift
	end

	-- Check completion
	if self._elapsed >= self._duration then
		self:Deactivate()
		return false
	end

	return true
end

--[[
	Deactivate kill cam and restore camera.
]]
function KillCam.Deactivate(self: KillCam)
	if not self._active then
		return
	end

	self._active = false

	-- Restore camera type
	if self._camera and self._originalCameraType then
		self._camera.CameraType = self._originalCameraType
	end

	if self._onComplete then
		self._onComplete()
		self._onComplete = nil
	end
end

--[[
	Check if kill cam is active.
]]
function KillCam.IsActive(self: KillCam): boolean
	return self._active
end

--[[
	Force skip the kill cam (player input).
]]
function KillCam.Skip(self: KillCam)
	if self._active then
		self:Deactivate()
	end
end

return KillCam
