--!strict
--[[
	MovementController.luau
	Client-side character movement controller.
	
	Handles: walk, run, sprint, dash, roll, backstep, double jump, fast fall,
	camera-relative input translation, and integration with combat state machine.
	
	Movement is client-authoritative (Roblox standard) with server-side validation
	via PositionValidator (Phase 3).
]]

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Signal = Shared.Framework.Signal
local Constants = Shared.Data.Constants
local CombatState = Shared.Enums.CombatState
local MomentumSystem = Shared.Modules.MomentumSystem

local MovementActions = require(script.Parent.MovementActions)

local MovementController = {}
MovementController.__index = MovementController

export type MovementController = typeof(setmetatable({} :: {
	_combatController: any,
	_inputController: any,
	_momentum: typeof(MomentumSystem.new()),
	_actions: typeof(MovementActions.new()),
	_humanoid: Humanoid?,
	_rootPart: BasePart?,
	_camera: Camera?,
	_isSprinting: boolean,
	_jumpCount: number,
	_maxJumps: number,
	_fastFalling: boolean,
	_isGrounded: boolean,
	OnDash: typeof(Signal.new()),
	OnRoll: typeof(Signal.new()),
	OnSprint: typeof(Signal.new()),
	OnJump: typeof(Signal.new()),
}, MovementController))

function MovementController.new(): MovementController
	local self = setmetatable({}, MovementController) :: any
	self._combatController = nil
	self._inputController = nil
	self._momentum = MomentumSystem.new()
	self._actions = MovementActions.new()
	self._humanoid = nil
	self._rootPart = nil
	self._camera = nil
	self._isSprinting = false
	self._jumpCount = 0
	self._maxJumps = 2 -- double jump
	self._fastFalling = false
	self._isGrounded = true
	self.OnDash = Signal.new()
	self.OnRoll = Signal.new()
	self.OnSprint = Signal.new()
	self.OnJump = Signal.new()
	return self
end

function MovementController.Init(self: MovementController, container: any)
	self._combatController = container:Resolve("CombatController")
	self._inputController = container:Resolve("InputController")
	self._camera = workspace.CurrentCamera

	-- Setup character references
	local player = Players.LocalPlayer
	local function onCharacter(character: Model)
		self._humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
		self._rootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		self._actions:SetRootPart(self._rootPart :: BasePart)
		self._jumpCount = 0
		self._fastFalling = false

		if self._humanoid then
			self._humanoid.StateChanged:Connect(function(_, newState)
				self:_onHumanoidStateChanged(newState)
			end)
		end
	end

	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)

	-- Wire dodge inputs from InputController to actual movement execution
	self._inputController.OnDodgeInput:Connect(function(dodgeType: string)
		self:_executeDodge(dodgeType)
	end)

	-- Double jump via space when airborne
	UserInputService.JumpRequest:Connect(function()
		self:_onJumpRequest()
	end)

	-- Fast fall (S key while airborne)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.S and not self._isGrounded then
			self._fastFalling = true
		end
	end)
end

function MovementController.Start(self: MovementController)
	RunService.RenderStepped:Connect(function(dt)
		self:_movementTick(dt)
	end)
end

--[[
	Get the current movement speed.
]]
function MovementController.GetSpeed(self: MovementController): number
	return self._momentum:GetSpeed()
end

--[[
	Check if player is sprinting.
]]
function MovementController.IsSprinting(self: MovementController): boolean
	return self._isSprinting
end

--[[
	Check if player is grounded.
]]
function MovementController.IsGrounded(self: MovementController): boolean
	return self._isGrounded
end

--[[
	Check if a movement action (dash/roll) is active.
]]
function MovementController.IsActionActive(self: MovementController): boolean
	return self._actions:IsActive()
end

-- ═══════════════════════════════════════════════════
-- MOVEMENT TICK
-- ═══════════════════════════════════════════════════

function MovementController._movementTick(self: MovementController, dt: number)
	if not self._humanoid or not self._rootPart then
		return
	end

	-- If a movement action (dash/roll/backstep) is active, let it drive movement
	if self._actions:IsActive() then
		local stillActive = self._actions:Tick(dt)
		if not stillActive then
			self._actions:StopVelocity()
		end
		return
	end

	-- Don't apply movement during locked combat states
	local combatState = self._combatController:GetState()
	if not self:_canMove(combatState) then
		self._momentum:SetTargetSpeed(0)
		self._momentum:Tick(dt)
		self._humanoid.WalkSpeed = 0
		return
	end

	-- Read movement input (WASD / stick)
	local moveDir = self:_getInputDirection()

	-- Determine target speed based on sprint state
	local targetSpeed: number
	if moveDir.Magnitude < 0.1 then
		targetSpeed = 0
	elseif self._isSprinting and self:_canSprint() then
		targetSpeed = Constants.BASE_SPRINT_SPEED
	else
		targetSpeed = Constants.BASE_RUN_SPEED
	end

	-- Sprint toggle: hold shift
	self._isSprinting = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
		and moveDir.Magnitude > 0.1

	-- Update momentum
	self._momentum:SetTargetSpeed(targetSpeed)
	if moveDir.Magnitude > 0.1 then
		self._momentum:SetTargetDirection(moveDir)
	end
	self._momentum:SetGrounded(self._isGrounded)
	self._momentum:Tick(dt)

	-- Apply to humanoid
	local speed = self._momentum:GetSpeed()
	self._humanoid.WalkSpeed = speed

	-- Set humanoid move direction (camera-relative)
	if moveDir.Magnitude > 0.1 then
		self._humanoid:Move(moveDir, false)
	else
		self._humanoid:Move(Vector3.zero, false)
	end

	-- Apply fast fall
	if self._fastFalling and not self._isGrounded and self._rootPart then
		local vel = self._rootPart.AssemblyLinearVelocity
		if vel.Y > -80 then
			self._rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, vel.Y - 120 * dt, vel.Z)
		end
	end
end

-- ═══════════════════════════════════════════════════
-- INPUT
-- ═══════════════════════════════════════════════════

--[[
	Get camera-relative movement direction from WASD/stick input.
]]
function MovementController._getInputDirection(self: MovementController): Vector3
	local moveVector = Vector3.zero

	-- Read keyboard
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveVector += Vector3.new(0, 0, -1)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveVector += Vector3.new(0, 0, 1)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveVector += Vector3.new(-1, 0, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveVector += Vector3.new(1, 0, 0)
	end

	if moveVector.Magnitude < 0.1 then
		return Vector3.zero
	end

	-- Convert to camera-relative direction
	local camera = self._camera
	if not camera then
		return moveVector.Unit
	end

	local cameraLook = camera.CFrame.LookVector
	local cameraRight = camera.CFrame.RightVector

	-- Flatten to XZ plane
	local forward = Vector3.new(cameraLook.X, 0, cameraLook.Z)
	if forward.Magnitude < 0.01 then
		forward = Vector3.new(0, 0, -1)
	else
		forward = forward.Unit
	end

	local right = Vector3.new(cameraRight.X, 0, cameraRight.Z)
	if right.Magnitude < 0.01 then
		right = Vector3.new(1, 0, 0)
	else
		right = right.Unit
	end

	local worldDir = forward * -moveVector.Z + right * moveVector.X
	if worldDir.Magnitude < 0.01 then
		return Vector3.zero
	end

	return worldDir.Unit
end

-- ═══════════════════════════════════════════════════
-- ACTIONS
-- ═══════════════════════════════════════════════════

function MovementController._executeDodge(self: MovementController, dodgeType: string)
	if not self._rootPart then
		return
	end

	-- Don't execute if combat controller already rejected (no stamina, wrong state)
	-- The CombatController handles validation and sends to server.
	-- We just execute the visual/physics movement here.

	local combatState = self._combatController:GetState()

	-- Determine direction
	local moveDir = self:_getInputDirection()
	local direction: Vector3

	if dodgeType == "Backstep" then
		-- Always backward relative to character facing
		direction = -self._rootPart.CFrame.LookVector
	elseif moveDir.Magnitude > 0.1 then
		direction = moveDir
	else
		-- Default: forward
		direction = self._rootPart.CFrame.LookVector
	end

	-- Flatten to XZ
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.01 then
		direction = Vector3.new(0, 0, -1)
	else
		direction = direction.Unit
	end

	local startPos = self._rootPart.Position

	if dodgeType == "Roll" and (combatState == CombatState.Rolling or combatState == CombatState.Idle) then
		self._actions:StartRoll(direction, startPos)
		self._momentum:HardStop()
		self.OnRoll:Fire(direction)
	elseif dodgeType == "Dash" and (combatState == CombatState.Dashing or combatState == CombatState.Idle) then
		self._actions:StartDash(direction, startPos)
		self._momentum:HardStop()
		self.OnDash:Fire(direction)
	elseif dodgeType == "Backstep" and (combatState == CombatState.Backstepping or combatState == CombatState.Idle) then
		self._actions:StartBackstep(direction, startPos)
		self._momentum:HardStop()
	end
end

function MovementController._onJumpRequest(self: MovementController)
	if not self._humanoid or not self._rootPart then
		return
	end

	-- Don't jump during locked states
	local combatState = self._combatController:GetState()
	if not self:_canMove(combatState) then
		return
	end

	if self._isGrounded then
		-- Normal jump (handled by Humanoid default)
		self._jumpCount = 1
		self._fastFalling = false
		self.OnJump:Fire(1)
	elseif self._jumpCount < self._maxJumps then
		-- Double jump
		self._jumpCount += 1
		self._fastFalling = false

		-- Apply upward velocity for double jump
		local vel = self._rootPart.AssemblyLinearVelocity
		self._rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, self._humanoid.JumpPower * 0.85, vel.Z)
		self.OnJump:Fire(self._jumpCount)
	end
end

-- ═══════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════

function MovementController._canMove(self: MovementController, combatState: string): boolean
	local lockedStates = {
		[CombatState.Staggered] = true,
		[CombatState.Launched] = true,
		[CombatState.Juggled] = true,
		[CombatState.Grounded] = true,
		[CombatState.GettingUp] = true,
		[CombatState.GuardBroken] = true,
		[CombatState.BeingExecuted] = true,
		[CombatState.Executing] = true,
		[CombatState.Dead] = true,
		[CombatState.Ragdoll] = true,
		[CombatState.WallBounce] = true,
		[CombatState.GroundBounce] = true,
	}
	return not lockedStates[combatState]
end

function MovementController._canSprint(self: MovementController): boolean
	local combatState = self._combatController:GetState()
	-- Can sprint in idle and movement states, not during attacks/blocks
	local sprintable = {
		[CombatState.Idle] = true,
		[CombatState.Walking] = true,
		[CombatState.Running] = true,
		[CombatState.Sprinting] = true,
	}
	return sprintable[combatState] == true
end

function MovementController._onHumanoidStateChanged(self: MovementController, newState: Enum.HumanoidStateType)
	local wasGrounded = self._isGrounded

	if newState == Enum.HumanoidStateType.Landed then
		self._isGrounded = true
		self._jumpCount = 0
		self._fastFalling = false
	elseif newState == Enum.HumanoidStateType.Freefall
		or newState == Enum.HumanoidStateType.Jumping then
		self._isGrounded = false
	elseif newState == Enum.HumanoidStateType.Running then
		self._isGrounded = true
		self._jumpCount = 0
		self._fastFalling = false
	end

	-- Notify momentum system
	self._momentum:SetGrounded(self._isGrounded)
end

return MovementController
