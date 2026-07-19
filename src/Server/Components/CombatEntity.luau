--!strict
--[[
	CombatEntity.luau
	Server-side component representing one player's combat state.
	Composes: CombatStateMachine, FrameDataEngine, StaminaManager, PoiseManager, ComboStateMachine.
	
	One CombatEntity is created per player when they join a match.
	The CombatService orchestrates entities and runs the tick loop.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)

local CombatStateMachine = Shared.Modules.CombatStateMachine
local FrameDataEngine = Shared.Modules.FrameDataEngine
local StaminaManager = Shared.Modules.StaminaManager
local PoiseManager = Shared.Modules.PoiseManager
local ComboStateMachine = Shared.Modules.ComboStateMachine
local Constants = Shared.Data.Constants
local CombatState = Shared.Enums.CombatState
local Signal = Shared.Framework.Signal

local CombatEntity = {}
CombatEntity.__index = CombatEntity

export type CombatEntity = typeof(setmetatable({} :: {
	Player: Player,
	PlayerId: number,

	-- Sub-systems
	StateMachine: typeof(CombatStateMachine.new()),
	FrameData: typeof(FrameDataEngine.new()),
	Stamina: typeof(StaminaManager.new()),
	Poise: typeof(PoiseManager.new()),
	Combo: typeof(ComboStateMachine.new()),

	-- State
	HP: number,
	MaxHP: number,
	UltimateMeter: number,
	Position: Vector3,
	Rotation: CFrame,
	LastProcessedSequence: number,
	HitstunRemaining: number,
	IsAlive: boolean,

	-- Signals
	OnDeath: typeof(Signal.new()),
	OnHit: typeof(Signal.new()),
	OnStateChanged: typeof(Signal.new()),
}, CombatEntity))

function CombatEntity.new(player: Player, config: { MaxHP: number?, MaxStamina: number?, MaxPoise: number? }?): CombatEntity
	local self = setmetatable({}, CombatEntity) :: any

	self.Player = player
	self.PlayerId = player.UserId

	-- Initialize sub-systems
	local cfg = config or {}
	self.StateMachine = CombatStateMachine.new()
	self.FrameData = FrameDataEngine.new()
	self.Stamina = StaminaManager.new(cfg.MaxStamina)
	self.Poise = PoiseManager.new(cfg.MaxPoise)
	self.Combo = ComboStateMachine.new()

	-- State
	self.HP = cfg.MaxHP or Constants.MAX_HP
	self.MaxHP = cfg.MaxHP or Constants.MAX_HP
	self.UltimateMeter = 0
	self.Position = Vector3.zero
	self.Rotation = CFrame.identity
	self.LastProcessedSequence = 0
	self.HitstunRemaining = 0
	self.IsAlive = true

	-- Signals
	self.OnDeath = Signal.new()
	self.OnHit = Signal.new()
	self.OnStateChanged = Signal.new()

	-- Wire state change callback
	self.StateMachine:SetOnStateChanged(function(oldState: string, newState: string)
		self.OnStateChanged:Fire(oldState, newState)
	end)

	return self
end

--[[
	Advance all sub-systems by one tick.
	@param dt — delta time in seconds (typically 1/60)
]]
function CombatEntity.Tick(self: CombatEntity, dt: number)
	if not self.IsAlive then
		return
	end

	-- Advance stamina regen
	self.Stamina:Tick(dt)

	-- Advance poise regen
	self.Poise:Tick(dt)

	-- Advance frame data engine
	self.FrameData:Tick()

	-- Advance combo timer
	self.Combo:Tick()

	-- Advance hitstun
	if self.HitstunRemaining > 0 then
		self.HitstunRemaining -= 1
		if self.HitstunRemaining <= 0 then
			self.HitstunRemaining = 0
			-- Exit stagger when hitstun ends
			local state = self.StateMachine:GetState()
			if state == CombatState.Staggered then
				self.StateMachine:ForceState(CombatState.Idle)
			end
		end
	end

	-- Advance state machine (auto-transitions based on duration)
	local context = self:_buildContext()
	self.StateMachine:Tick(context)

	-- Check if attack frame data completed → return to idle
	if self.FrameData:IsComplete() then
		local state = self.StateMachine:GetState()
		if state == CombatState.Attacking or state == CombatState.HeavyAttacking then
			self.StateMachine:ForceState(CombatState.Idle)
		end
		self.FrameData:Reset()
	end
end

--[[
	Attempt to perform a light attack.
	Returns true if the attack was accepted.
]]
function CombatEntity.TryLightAttack(self: CombatEntity, frameData: any): boolean
	local context = self:_buildContext()
	local currentState = self.StateMachine:GetState()

	-- Check if in cancel window (combo chaining)
	local canChain = currentState == CombatState.Attacking and self.FrameData:InCancelWindow()

	if currentState == CombatState.Attacking and not canChain then
		return false
	end

	if not self.StateMachine:TryTransition(CombatState.Attacking, context) then
		return false
	end

	-- Consume stamina
	if not self.Stamina:Consume(Constants.STAMINA_COST_LIGHT) then
		self.StateMachine:ForceState(CombatState.Idle)
		return false
	end

	-- Start frame data
	self.FrameData:StartAttack(frameData)

	return true
end

--[[
	Attempt to perform a heavy attack.
]]
function CombatEntity.TryHeavyAttack(self: CombatEntity, frameData: any): boolean
	local context = self:_buildContext()

	if not self.StateMachine:TryTransition(CombatState.HeavyAttacking, context) then
		return false
	end

	if not self.Stamina:Consume(Constants.STAMINA_COST_HEAVY) then
		self.StateMachine:ForceState(CombatState.Idle)
		return false
	end

	self.FrameData:StartAttack(frameData)

	return true
end

--[[
	Attempt to start blocking.
]]
function CombatEntity.TryBlock(self: CombatEntity): boolean
	local context = self:_buildContext()

	if self.StateMachine:GetState() == CombatState.Blocking then
		return true -- Already blocking
	end

	if self.StateMachine:TryTransition(CombatState.Blocking, context) then
		self.Stamina:PauseRegen()
		return true
	end

	return false
end

--[[
	Stop blocking (release guard).
]]
function CombatEntity.StopBlock(self: CombatEntity)
	if self.StateMachine:GetState() == CombatState.Blocking then
		self.StateMachine:ForceState(CombatState.Idle)
		self.Stamina:ResumeRegen()
	end
end

--[[
	Attempt to parry.
]]
function CombatEntity.TryParry(self: CombatEntity): boolean
	local context = self:_buildContext()

	if not self.StateMachine:TryTransition(CombatState.Parrying, context) then
		return false
	end

	self.Stamina:Consume(Constants.STAMINA_COST_PARRY)
	return true
end

--[[
	Attempt a roll dodge.
]]
function CombatEntity.TryRoll(self: CombatEntity): boolean
	local context = self:_buildContext()

	if not self.StateMachine:TryTransition(CombatState.Rolling, context) then
		return false
	end

	self.Stamina:Consume(Constants.STAMINA_COST_ROLL)
	return true
end

--[[
	Attempt a dash.
]]
function CombatEntity.TryDash(self: CombatEntity): boolean
	local context = self:_buildContext()

	if not self.StateMachine:TryTransition(CombatState.Dashing, context) then
		return false
	end

	self.Stamina:Consume(Constants.STAMINA_COST_DASH)
	return true
end

--[[
	Attempt a backstep.
]]
function CombatEntity.TryBackstep(self: CombatEntity): boolean
	local context = self:_buildContext()

	if not self.StateMachine:TryTransition(CombatState.Backstepping, context) then
		return false
	end

	self.Stamina:Consume(Constants.STAMINA_COST_BACKSTEP)
	return true
end

--[[
	Apply damage to this entity. Returns actual damage dealt.
]]
function CombatEntity.TakeDamage(self: CombatEntity, damage: number, poiseDamage: number, hitstunFrames: number, knockback: Vector3?): number
	if not self.IsAlive then
		return 0
	end

	-- Check invulnerability
	if self.StateMachine:HasIFrames() then
		return 0
	end

	-- Apply HP damage
	self.HP = math.max(0, self.HP - damage)

	-- Apply poise damage (if not in armor)
	local staggerTriggered = false
	if not self.StateMachine:HasArmor() then
		staggerTriggered = self.Poise:TakeDamage(poiseDamage)
	end

	-- Build ult meter from taking damage
	self.UltimateMeter = math.min(
		Constants.ULTIMATE_METER_MAX,
		self.UltimateMeter + damage * Constants.ULTIMATE_GAIN_PER_HIT_TAKEN
	)

	-- Apply hitstun / stagger
	if staggerTriggered or (hitstunFrames > 0 and not self.StateMachine:HasArmor()) then
		self.StateMachine:ForceState(CombatState.Staggered)
		self.HitstunRemaining = hitstunFrames
		self.FrameData:Reset() -- interrupt any current attack
		self.Stamina:ResumeRegen()
	end

	-- Check death
	if self.HP <= 0 then
		self.IsAlive = false
		self.StateMachine:ForceState(CombatState.Dead)
		self.OnDeath:Fire()
	end

	self.OnHit:Fire(damage, poiseDamage)

	return damage
end

--[[
	Apply launch (sends entity airborne).
]]
function CombatEntity.ApplyLaunch(self: CombatEntity, hitstunFrames: number)
	if not self.IsAlive or self.StateMachine:HasIFrames() then
		return
	end

	self.StateMachine:ForceState(CombatState.Launched)
	self.HitstunRemaining = hitstunFrames
	self.FrameData:Reset()
end

--[[
	Notify that a parry succeeded (called on the ATTACKER entity).
]]
function CombatEntity.OnParried(self: CombatEntity)
	self.StateMachine:ForceState(CombatState.Staggered)
	self.HitstunRemaining = Constants.PARRY_STUN_FRAMES
	self.FrameData:Reset()
end

--[[
	Grant ultimate meter.
]]
function CombatEntity.AddUltimateMeter(self: CombatEntity, amount: number)
	self.UltimateMeter = math.min(Constants.ULTIMATE_METER_MAX, self.UltimateMeter + amount)
end

--[[
	Use ultimate (consumes full meter).
]]
function CombatEntity.TryUltimate(self: CombatEntity): boolean
	local context = self:_buildContext()

	if self.UltimateMeter < Constants.ULTIMATE_METER_MAX then
		return false
	end

	if not self.StateMachine:TryTransition(CombatState.UsingUltimate, context) then
		return false
	end

	self.UltimateMeter = 0
	return true
end

--[[
	Reset entity to full state (for respawn / new round).
]]
function CombatEntity.Reset(self: CombatEntity)
	self.HP = self.MaxHP
	self.UltimateMeter = 0
	self.HitstunRemaining = 0
	self.IsAlive = true
	self.LastProcessedSequence = 0
	self.StateMachine:ForceState(CombatState.Idle)
	self.FrameData:Reset()
	self.Stamina:Reset()
	self.Poise:Reset()
	self.Combo:Reset()
end

--[[
	Get a snapshot of current state for network replication.
]]
function CombatEntity.GetSnapshot(self: CombatEntity): any
	return {
		Tick = 0, -- set by CombatService
		CombatState = self.StateMachine:GetState(),
		HP = self.HP,
		Stamina = self.Stamina:GetCurrent(),
		Poise = self.Poise:GetCurrent(),
		Position = self.Position,
		UltimateMeter = self.UltimateMeter,
		LastProcessedSequence = self.LastProcessedSequence,
		ComboCount = self.Combo:GetHitCount(),
	}
end

--[[
	Destroy and clean up.
]]
function CombatEntity.Destroy(self: CombatEntity)
	self.OnDeath:Destroy()
	self.OnHit:Destroy()
	self.OnStateChanged:Destroy()
end

-- ═══════════════════════════════════════════════════
-- PRIVATE
-- ═══════════════════════════════════════════════════

function CombatEntity._buildContext(self: CombatEntity): any
	return {
		stamina = self.Stamina:GetCurrent(),
		poise = self.Poise:GetCurrent(),
		hp = self.HP,
		frameCounter = self.StateMachine:GetStateFrame(),
		isGrounded = true, -- TODO: integrate with movement system
		isAirborne = false,
		activeFrameData = nil,
		comboCount = self.Combo:GetHitCount(),
		ultimateMeter = self.UltimateMeter,
		inputBuffer = {},
	}
end

return CombatEntity
