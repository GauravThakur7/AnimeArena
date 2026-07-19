--!strict
--[[
	CombatController.luau
	Client-side combat prediction and state management.
	Sends requests to server via network, plays animations immediately (prediction).
	Reconciles when server state arrives.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Signal = Shared.Framework.Signal
local CombatStateMachine = Shared.Modules.CombatStateMachine
local FrameDataEngine = Shared.Modules.FrameDataEngine
local StaminaManager = Shared.Modules.StaminaManager
local InputBuffer = Shared.Modules.InputBuffer
local Constants = Shared.Data.Constants
local CombatState = Shared.Enums.CombatState

local CombatController = {}
CombatController.__index = CombatController

export type CombatController = typeof(setmetatable({} :: {
	_network: any,
	_inputController: any,
	_stateMachine: typeof(CombatStateMachine.new()),
	_frameData: typeof(FrameDataEngine.new()),
	_stamina: typeof(StaminaManager.new()),
	_inputBuffer: typeof(InputBuffer.new()),
	_sequenceId: number,
	_serverState: any,
	_currentFrame: number,
	OnStateChanged: typeof(Signal.new()),
	OnComboUpdate: typeof(Signal.new()),
	OnHitReceived: typeof(Signal.new()),
}, CombatController))

function CombatController.new(network: any): CombatController
	local self = setmetatable({}, CombatController) :: any
	self._network = network
	self._inputController = nil
	self._stateMachine = CombatStateMachine.new()
	self._frameData = FrameDataEngine.new()
	self._stamina = StaminaManager.new()
	self._inputBuffer = InputBuffer.new()
	self._sequenceId = 0
	self._serverState = nil
	self._currentFrame = 0
	self.OnStateChanged = Signal.new()
	self.OnComboUpdate = Signal.new()
	self.OnHitReceived = Signal.new()
	return self
end

function CombatController.Init(self: CombatController, container: any)
	self._inputController = container:Resolve("InputController")

	-- Wire input signals
	self._inputController.OnAttackInput:Connect(function(attackType: string)
		self:_onAttackInput(attackType)
	end)

	self._inputController.OnBlockInput:Connect(function(active: boolean)
		self:_onBlockInput(active)
	end)

	self._inputController.OnParryInput:Connect(function()
		self:_onParryInput()
	end)

	self._inputController.OnDodgeInput:Connect(function(dodgeType: string)
		self:_onDodgeInput(dodgeType)
	end)

	self._inputController.OnUltimateInput:Connect(function()
		self:_onUltimateInput()
	end)

	-- Listen for server state updates
	self._network:OnClientEvent("StateUpdate", function(data: any)
		self:_onServerState(data)
	end)

	-- Listen for hit confirmations
	self._network:OnClientEvent("HitConfirm", function(data: any)
		local DebugLog = require(ReplicatedStorage:WaitForChild("Shared").Util.DebugLog)
		DebugLog.Log("HitConfirm", `Type: {data.HitType} | Damage: {data.Damage} | Attacker: {data.AttackerId} | Target: {data.TargetId}`)
		self.OnHitReceived:Fire(data)
	end)

	-- State change callback for UI/animation
	self._stateMachine:SetOnStateChanged(function(oldState: string, newState: string)
		self.OnStateChanged:Fire(oldState, newState)
	end)
end

function CombatController.Start(self: CombatController)
	-- Client prediction tick runs via Heartbeat (connected in client bootstrap or here)
	local RunService = game:GetService("RunService")
	RunService.Heartbeat:Connect(function(dt)
		self:_clientTick(dt)
	end)
end

--[[
	Get the predicted combat state.
]]
function CombatController.GetState(self: CombatController): string
	return self._stateMachine:GetState()
end

--[[
	Get predicted stamina.
]]
function CombatController.GetStamina(self: CombatController): number
	return self._stamina:GetCurrent()
end

--[[
	Get predicted stamina percent (0-1).
]]
function CombatController.GetStaminaPercent(self: CombatController): number
	return self._stamina:GetPercent()
end

-- ═══════════════════════════════════════════════════
-- CLIENT TICK (PREDICTION)
-- ═══════════════════════════════════════════════════

function CombatController._clientTick(self: CombatController, dt: number)
	self._currentFrame += 1

	-- Advance local prediction
	self._stamina:Tick(dt)
	self._frameData:Tick()

	-- Process input buffer
	local buffered = self._inputBuffer:Peek(self._currentFrame)
	if buffered and self._stateMachine:CanAct() then
		-- Try to consume buffered input
		if buffered == "Light" or buffered == "Heavy" then
			if self._frameData:IsComplete() or self._frameData:InCancelWindow() then
				self._inputBuffer:Consume(self._currentFrame)
				-- Already sent to server when buffered
			end
		end
	end

	-- Auto-return to idle from completed attacks
	if self._frameData:IsComplete() then
		local state = self._stateMachine:GetState()
		if state == CombatState.Attacking or state == CombatState.HeavyAttacking then
			self._stateMachine:ForceState(CombatState.Idle)
		end
		self._frameData:Reset()
	end

	-- Advance state machine
	local context = {
		stamina = self._stamina:GetCurrent(),
		poise = 100,
		hp = 100,
		frameCounter = self._stateMachine:GetStateFrame(),
		isGrounded = true,
		isAirborne = false,
		activeFrameData = nil,
		comboCount = 0,
		ultimateMeter = 0,
		inputBuffer = {},
	}
	self._stateMachine:Tick(context)
end

-- ═══════════════════════════════════════════════════
-- INPUT HANDLERS
-- ═══════════════════════════════════════════════════

function CombatController._onAttackInput(self: CombatController, attackType: string)
	-- Buffer the input
	self._inputBuffer:Push(attackType, self._currentFrame)

	local DebugLog = require(ReplicatedStorage:WaitForChild("Shared").Util.DebugLog)
	DebugLog.Log("Combat", `Attack input: {attackType} | State: {self._stateMachine:GetState()} | Stamina: {math.floor(self._stamina:GetCurrent())}`)

	-- Try to predict locally
	local context = {
		stamina = self._stamina:GetCurrent(),
		poise = 100,
		hp = 100,
		frameCounter = self._stateMachine:GetStateFrame(),
		isGrounded = true,
		isAirborne = false,
		activeFrameData = nil,
		comboCount = 0,
		ultimateMeter = 0,
		inputBuffer = {},
	}

	local targetState = if attackType == "Heavy" then CombatState.HeavyAttacking else CombatState.Attacking
	local canTransition = self._stateMachine:TryTransition(targetState, context)

	if canTransition then
		-- Predict stamina consumption
		local cost = if attackType == "Heavy" then Constants.STAMINA_COST_HEAVY else Constants.STAMINA_COST_LIGHT
		self._stamina:Consume(cost)

		-- Predict frame data
		local fd = if attackType == "Heavy"
			then { Startup = 14, Active = 6, Recovery = 22, CancelWindow = nil }
			else { Startup = 6, Active = 4, Recovery = 12, CancelWindow = { 8, 9, 10 } }
		self._frameData:StartAttack(fd)
	end

	-- Send to server regardless (server is authoritative)
	self._sequenceId += 1
	self._network:FireServer("AttackRequest", {
		AttackType = attackType,
		Timestamp = workspace:GetServerTimeNow(),
		SequenceId = self._sequenceId,
	})
end

function CombatController._onBlockInput(self: CombatController, active: boolean)
	local DebugLog = require(ReplicatedStorage:WaitForChild("Shared").Util.DebugLog)
	DebugLog.Log("Combat", `Block input: Active={tostring(active)} | State: {self._stateMachine:GetState()}`)

	-- Predict locally
	if active then
		local context = {
			stamina = self._stamina:GetCurrent(),
			poise = 100, hp = 100,
			frameCounter = self._stateMachine:GetStateFrame(),
			isGrounded = true, isAirborne = false,
			activeFrameData = nil, comboCount = 0,
			ultimateMeter = 0, inputBuffer = {},
		}
		self._stateMachine:TryTransition(CombatState.Blocking, context)
		self._stamina:PauseRegen()
	else
		if self._stateMachine:GetState() == CombatState.Blocking then
			self._stateMachine:ForceState(CombatState.Idle)
			self._stamina:ResumeRegen()
		end
	end

	-- Send to server
	self._network:FireServer("BlockRequest", {
		Active = active,
		Timestamp = workspace:GetServerTimeNow(),
	})
end

function CombatController._onParryInput(self: CombatController)
	local DebugLog = require(ReplicatedStorage:WaitForChild("Shared").Util.DebugLog)
	DebugLog.Log("Combat", `Parry input | State: {self._stateMachine:GetState()} | Stamina: {math.floor(self._stamina:GetCurrent())}`)

	local context = {
		stamina = self._stamina:GetCurrent(),
		poise = 100, hp = 100,
		frameCounter = self._stateMachine:GetStateFrame(),
		isGrounded = true, isAirborne = false,
		activeFrameData = nil, comboCount = 0,
		ultimateMeter = 0, inputBuffer = {},
	}

	if self._stateMachine:TryTransition(CombatState.Parrying, context) then
		self._stamina:Consume(Constants.STAMINA_COST_PARRY)
	end

	self._network:FireServer("ParryRequest", {
		Timestamp = workspace:GetServerTimeNow(),
	})
end

function CombatController._onDodgeInput(self: CombatController, dodgeType: string)
	local DebugLog = require(ReplicatedStorage:WaitForChild("Shared").Util.DebugLog)
	DebugLog.Log("Combat", `Dodge input: {dodgeType} | State: {self._stateMachine:GetState()} | Stamina: {math.floor(self._stamina:GetCurrent())}`)

	local context = {
		stamina = self._stamina:GetCurrent(),
		poise = 100, hp = 100,
		frameCounter = self._stateMachine:GetStateFrame(),
		isGrounded = true, isAirborne = false,
		activeFrameData = nil, comboCount = 0,
		ultimateMeter = 0, inputBuffer = {},
	}

	local targetState: string
	local cost: number

	if dodgeType == "Roll" then
		targetState = CombatState.Rolling
		cost = Constants.STAMINA_COST_ROLL
	elseif dodgeType == "Dash" then
		targetState = CombatState.Dashing
		cost = Constants.STAMINA_COST_DASH
	elseif dodgeType == "Backstep" then
		targetState = CombatState.Backstepping
		cost = Constants.STAMINA_COST_BACKSTEP
	else
		return
	end

	if self._stateMachine:TryTransition(targetState, context) then
		self._stamina:Consume(cost)
	end

	self._network:FireServer("DodgeRequest", {
		DodgeType = dodgeType,
		Timestamp = workspace:GetServerTimeNow(),
	})
end

function CombatController._onUltimateInput(self: CombatController)
	local DebugLog = require(ReplicatedStorage:WaitForChild("Shared").Util.DebugLog)
	DebugLog.Log("Combat", `Ultimate input | Meter: 0 (not tracked client-side yet)`)

	self._network:FireServer("UltimateRequest", {
		Timestamp = workspace:GetServerTimeNow(),
	})
end

-- ═══════════════════════════════════════════════════
-- SERVER RECONCILIATION
-- ═══════════════════════════════════════════════════

function CombatController._onServerState(self: CombatController, data: any)
	self._serverState = data

	-- Reconcile combat state if prediction was wrong
	local serverCombatState = data.CombatState
	local predictedState = self._stateMachine:GetState()

	if serverCombatState ~= predictedState then
		local DebugLog = require(ReplicatedStorage:WaitForChild("Shared").Util.DebugLog)
		DebugLog.Warn("Reconcile", `State mismatch! Predicted: {predictedState} → Server: {serverCombatState}`)
		-- Server wins — snap to authoritative state
		self._stateMachine:ForceState(serverCombatState)
	end

	-- Reconcile stamina
	local serverStamina = data.Stamina
	local predictedStamina = self._stamina:GetCurrent()
	if math.abs(serverStamina - predictedStamina) > 5 then
		self._stamina:SetCurrent(serverStamina)
	end
end

return CombatController
