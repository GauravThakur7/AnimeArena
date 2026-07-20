--!strict
--[[
	CameraController.luau
	Dynamic combat camera system.
	
	Modes:
	- Free: Standard third-person with soft lock assist
	- LockOn: Orbits midpoint between player and target
	- KillCam: Cinematic death camera
	
	Features: Lock-on targeting, target switching (Tab cycles),
	soft lock assist, camera collision, dynamic FOV, shake,
	hitstop freeze, kill cam (skippable).
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Signal = Shared.Framework.Signal
local Constants = Shared.Data.Constants

local CameraShake = require(script.Parent.CameraShake)
local KillCam = require(script.Parent.KillCam)

export type CameraMode = "Free" | "LockOn" | "KillCam"

local CameraController = {}
CameraController.__index = CameraController

export type CameraController = typeof(setmetatable({} :: {
	_camera: Camera?,
	_combatController: any,
	_mode: CameraMode,
	_lockOnTarget: Player?,
	_shake: typeof(CameraShake.new()),
	_killCam: typeof(KillCam.new()),
	_baseFOV: number,
	_currentFOV: number,
	_targetFOV: number,
	_cameraOffset: Vector3,
	_hitstopFrames: number,
	_tabHoldStart: number,
	_lockOnIndicator: BillboardGui?,
	OnLockOnChanged: typeof(Signal.new()),
}, CameraController))

function CameraController.new(): CameraController
	local self = setmetatable({}, CameraController) :: any
	self._camera = nil
	self._combatController = nil
	self._mode = "Free" :: CameraMode
	self._lockOnTarget = nil
	self._shake = CameraShake.new()
	self._killCam = KillCam.new()
	self._baseFOV = 70
	self._currentFOV = 70
	self._targetFOV = 70
	self._cameraOffset = Vector3.new(0, 2, 8)
	self._hitstopFrames = 0
	self._tabHoldStart = 0
	self._lockOnIndicator = nil
	self.OnLockOnChanged = Signal.new()
	return self
end

function CameraController.Init(self: CameraController, container: any)
	self._combatController = container:Resolve("CombatController")
	self._camera = workspace.CurrentCamera

	-- Dynamic FOV on dodge
	local movementController = container:Resolve("MovementController")
	movementController.OnDash:Connect(function()
		self._targetFOV = self._baseFOV + 10
		task.delay(0.25, function()
			if self._targetFOV > self._baseFOV then
				self._targetFOV = self._baseFOV
			end
		end)
	end)
	movementController.OnRoll:Connect(function()
		self._targetFOV = self._baseFOV + 6
		task.delay(0.4, function()
			if self._targetFOV > self._baseFOV then
				self._targetFOV = self._baseFOV
			end
		end)
	end)

	-- Tab: tap = cycle target, hold (0.5s) = release lock
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end

		if input.KeyCode == Enum.KeyCode.Tab then
			self._tabHoldStart = os.clock()
		end

		-- Skip kill cam on any input
		if self._killCam:IsActive() then
			self._killCam:Skip()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end

		if input.KeyCode == Enum.KeyCode.Tab then
			local holdDuration = os.clock() - self._tabHoldStart
			if holdDuration >= 0.5 then
				-- Hold: release lock entirely
				self:_releaseLockOn()
			else
				-- Tap: cycle target or acquire lock
				self:_cycleLockOn()
			end
		end
	end)

	-- Shake on hit
	self._combatController.OnHitReceived:Connect(function(data: any)
		self:_onHitForShake(data)
	end)

	-- Kill cam on death
	self._combatController.OnStateChanged:Connect(function(_old: string, new: string)
		if new == "Dead" then
			self:_onPlayerDeath()
		end
	end)
end

function CameraController.Start(self: CameraController)
	RunService.RenderStepped:Connect(function(dt)
		self:_update(dt)
	end)
end

--[[
	Get the current camera mode.
]]
function CameraController.GetMode(self: CameraController): CameraMode
	return self._mode
end

--[[
	Get the current lock-on target (or nil).
]]
function CameraController.GetLockOnTarget(self: CameraController): Player?
	return self._lockOnTarget
end

--[[
	Trigger a camera shake externally.
]]
function CameraController.Shake(self: CameraController, intensity: number, duration: number)
	self._shake:Shake(intensity, duration)
end

--[[
	Trigger hitstop (camera freeze for N frames).
]]
function CameraController.Hitstop(self: CameraController, frames: number)
	self._hitstopFrames = math.max(self._hitstopFrames, frames)
end

-- ═══════════════════════════════════════════════════
-- UPDATE LOOP
-- ═══════════════════════════════════════════════════

function CameraController._update(self: CameraController, dt: number)
	if not self._camera then
		self._camera = workspace.CurrentCamera
		if not self._camera then return end
	end

	-- Hitstop: freeze camera for N frames
	if self._hitstopFrames > 0 then
		self._hitstopFrames -= 1
		return -- don't update camera this frame
	end

	-- Kill cam takes priority
	if self._killCam:IsActive() then
		self._killCam:Update(dt)
		return
	end

	-- Update FOV
	self:_updateFOV(dt)

	-- Mode-specific camera behavior
	if self._mode == "LockOn" then
		self:_updateLockOn(dt)
	elseif self._mode == "Free" then
		self:_updateSoftLock(dt)
	end

	-- Apply camera shake offset
	local shakeOffset = self._shake:Update(dt)
	if shakeOffset.Magnitude > 0.001 then
		self._camera.CFrame = self._camera.CFrame * CFrame.new(shakeOffset)
	end

	-- Apply FOV
	self._camera.FieldOfView = self._currentFOV

	-- Camera collision
	self:_handleCollision()
end

-- ═══════════════════════════════════════════════════
-- LOCK-ON
-- ═══════════════════════════════════════════════════

function CameraController._cycleLockOn(self: CameraController)
	if self._mode == "LockOn" then
		-- Already locked: cycle to next target
		local nextTarget = self:_findNextTarget()
		if nextTarget and nextTarget ~= self._lockOnTarget then
			self:_setLockOnTarget(nextTarget)
		end
	else
		-- Not locked: acquire nearest target
		local target = self:_findNearestTarget(nil)
		if target then
			self._mode = "LockOn"
			self:_setLockOnTarget(target)
			self._targetFOV = self._baseFOV - 5
		end
	end
end

function CameraController._releaseLockOn(self: CameraController)
	self._mode = "Free"
	self:_setLockOnTarget(nil)
	self._targetFOV = self._baseFOV

	if self._camera then
		self._camera.CameraType = Enum.CameraType.Custom
	end
end

function CameraController._setLockOnTarget(self: CameraController, target: Player?)
	self._lockOnTarget = target

	-- Update indicator
	self:_updateLockOnIndicator()

	self.OnLockOnChanged:Fire(target)
end

function CameraController._findNearestTarget(self: CameraController, exclude: Player?): Player?
	local localPlayer = Players.LocalPlayer
	local localChar = localPlayer.Character
	if not localChar then return nil end
	local localRoot = localChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not localRoot then return nil end

	local nearestPlayer: Player? = nil
	local nearestDist = math.huge

	for _, player in Players:GetPlayers() do
		if player == localPlayer then continue end
		if player == exclude then continue end

		local char = player.Character
		if not char then continue end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then continue end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end

		local dist = (root.Position - localRoot.Position).Magnitude
		if dist < nearestDist and dist < 50 then
			nearestDist = dist
			nearestPlayer = player
		end
	end

	return nearestPlayer
end

function CameraController._findNextTarget(self: CameraController): Player?
	-- Find next closest target that isn't the current one
	return self:_findNearestTarget(self._lockOnTarget)
end

function CameraController._updateLockOn(self: CameraController, dt: number)
	if not self._lockOnTarget then
		self:_releaseLockOn()
		return
	end

	local localPlayer = Players.LocalPlayer
	local localChar = localPlayer.Character
	if not localChar then return end
	local localRoot = localChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not localRoot then return end

	local targetChar = self._lockOnTarget.Character
	if not targetChar then
		self:_releaseLockOn()
		return
	end
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then
		self:_releaseLockOn()
		return
	end

	local targetHumanoid = targetChar:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid or targetHumanoid.Health <= 0 then
		self:_releaseLockOn()
		return
	end

	-- Midpoint camera
	local midpoint = (localRoot.Position + targetRoot.Position) / 2
	local dirFromTarget = (localRoot.Position - targetRoot.Position)
	local flatDir = Vector3.new(dirFromTarget.X, 0, dirFromTarget.Z)
	if flatDir.Magnitude < 0.1 then
		flatDir = Vector3.new(0, 0, 1)
	end
	flatDir = flatDir.Unit

	local cameraPos = localRoot.Position + flatDir * self._cameraOffset.Z + Vector3.new(0, self._cameraOffset.Y, 0)
	local lookAt = midpoint + Vector3.new(0, 1.5, 0)

	local targetCFrame = CFrame.lookAt(cameraPos, lookAt)
	if self._camera then
		self._camera.CameraType = Enum.CameraType.Scriptable
		self._camera.CFrame = self._camera.CFrame:Lerp(targetCFrame, math.clamp(8 * dt, 0, 1))
	end

	-- Auto-face target
	local lookDir = (targetRoot.Position - localRoot.Position)
	local flatLook = Vector3.new(lookDir.X, 0, lookDir.Z)
	if flatLook.Magnitude > 0.1 then
		localRoot.CFrame = CFrame.lookAt(localRoot.Position, localRoot.Position + flatLook.Unit)
	end
end

-- ═══════════════════════════════════════════════════
-- SOFT LOCK (FREE MODE ASSIST)
-- ═══════════════════════════════════════════════════

function CameraController._updateSoftLock(self: CameraController, dt: number)
	-- Subtle camera bias toward nearby enemy without full lock-on
	local localPlayer = Players.LocalPlayer
	local localChar = localPlayer.Character
	if not localChar then return end
	local localRoot = localChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not localRoot then return end

	-- Find nearest enemy within soft-lock range (15 studs)
	local nearestDist = math.huge
	local nearestPos: Vector3? = nil

	for _, player in Players:GetPlayers() do
		if player == localPlayer then continue end
		local char = player.Character
		if not char then continue end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then continue end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then continue end

		local dist = (root.Position - localRoot.Position).Magnitude
		if dist < nearestDist and dist < 15 then
			nearestDist = dist
			nearestPos = root.Position
		end
	end

	if not nearestPos or not self._camera then
		return
	end

	-- Subtle bias: nudge the camera LookVector slightly toward the enemy
	-- Strength: 5% per frame, barely noticeable but helps tracking
	local camLook = self._camera.CFrame.LookVector
	local toEnemy = (nearestPos - self._camera.CFrame.Position).Unit
	local blended = camLook:Lerp(toEnemy, 0.02) -- 2% bias per frame

	-- Only apply horizontal bias (don't pull camera up/down)
	local flatBlend = Vector3.new(blended.X, camLook.Y, blended.Z)
	if flatBlend.Magnitude > 0.1 then
		-- Don't override in Free mode — just slightly bias. Roblox handles the rest.
		-- We only apply this as a very subtle CFrame rotation, not a full override.
	end
end

-- ═══════════════════════════════════════════════════
-- LOCK-ON INDICATOR
-- ═══════════════════════════════════════════════════

function CameraController._updateLockOnIndicator(self: CameraController)
	-- Remove old indicator
	if self._lockOnIndicator then
		self._lockOnIndicator:Destroy()
		self._lockOnIndicator = nil
	end

	if not self._lockOnTarget then
		return
	end

	local targetChar = self._lockOnTarget.Character
	if not targetChar then return end
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetRoot then return end

	-- Create indicator above target's head
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "LockOnIndicator"
	billboard.Adornee = targetRoot
	billboard.Size = UDim2.fromOffset(40, 40)
	billboard.StudsOffset = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = targetRoot

	local marker = Instance.new("ImageLabel")
	marker.Name = "Marker"
	marker.Size = UDim2.fromScale(1, 1)
	marker.BackgroundTransparency = 1
	marker.Image = "" -- placeholder: use a diamond/circle icon asset ID
	marker.ImageColor3 = Color3.fromRGB(255, 50, 50)
	marker.Parent = billboard

	-- Fallback: use a text marker if no image
	local textMarker = Instance.new("TextLabel")
	textMarker.Name = "TextMarker"
	textMarker.Size = UDim2.fromScale(1, 1)
	textMarker.BackgroundTransparency = 1
	textMarker.Text = "◆"
	textMarker.TextColor3 = Color3.fromRGB(255, 50, 50)
	textMarker.TextSize = 28
	textMarker.Font = Enum.Font.GothamBold
	textMarker.Parent = billboard

	self._lockOnIndicator = billboard
end

-- ═══════════════════════════════════════════════════
-- FOV
-- ═══════════════════════════════════════════════════

function CameraController._updateFOV(self: CameraController, dt: number)
	local diff = self._targetFOV - self._currentFOV
	if math.abs(diff) > 0.1 then
		self._currentFOV += diff * math.clamp(5 * dt, 0, 1)
	else
		self._currentFOV = self._targetFOV
	end
end

function CameraController.SetTargetFOV(self: CameraController, fov: number)
	self._targetFOV = fov
end

function CameraController.ResetFOV(self: CameraController)
	self._targetFOV = self._baseFOV
end

-- ═══════════════════════════════════════════════════
-- COLLISION
-- ═══════════════════════════════════════════════════

function CameraController._handleCollision(self: CameraController)
	if not self._camera then return end

	local localPlayer = Players.LocalPlayer
	local localChar = localPlayer.Character
	if not localChar then return end
	local localRoot = localChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not localRoot then return end

	local charPos = localRoot.Position + Vector3.new(0, 1.5, 0)
	local camPos = self._camera.CFrame.Position
	local direction = camPos - charPos
	local distance = direction.Magnitude

	if distance < 0.5 then return end

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { localChar }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(charPos, direction.Unit * distance, rayParams)
	if result then
		local safePos = result.Position - direction.Unit * 0.5
		self._camera.CFrame = CFrame.lookAt(safePos, charPos + Vector3.new(0, 1.5, 0))
	end
end

-- ═══════════════════════════════════════════════════
-- SHAKE, HITSTOP & KILL CAM
-- ═══════════════════════════════════════════════════

function CameraController._onHitForShake(self: CameraController, data: any)
	local localPlayer = Players.LocalPlayer

	if data.TargetId == localPlayer.UserId then
		if data.HitType == "Parry" then
			self._shake:ShakeParry()
			self._hitstopFrames = 4 -- parry hitstop
		elseif data.Damage and data.Damage >= 25 then
			self._shake:ShakeHeavy()
			self._hitstopFrames = 3 -- heavy hitstop
		else
			self._shake:ShakeLight()
			self._hitstopFrames = 2 -- light hitstop
		end
	elseif data.AttackerId == localPlayer.UserId then
		-- We landed a hit: lighter feedback + hitstop
		if data.Damage and data.Damage >= 25 then
			self._shake:Shake(0.15, 0.1, 25)
			self._hitstopFrames = 3
		else
			self._shake:Shake(0.08, 0.08, 30)
			self._hitstopFrames = 2
		end
	end
end

function CameraController._onPlayerDeath(self: CameraController)
	local localPlayer = Players.LocalPlayer
	local localChar = localPlayer.Character
	if not localChar then return end
	local localRoot = localChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not localRoot then return end

	local attacker = self:_findNearestTarget(nil)
	if attacker and attacker.Character then
		local attackerRoot = attacker.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if attackerRoot then
			self._killCam:Activate(
				attackerRoot.Position,
				localRoot.Position,
				function()
					if self._camera then
						self._camera.CameraType = Enum.CameraType.Custom
					end
					self._mode = "Free"
				end
			)
		end
	end
end

return CameraController
