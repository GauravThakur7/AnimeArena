--!strict
--[[
	CombatStateMachine.luau
	Finite state machine that governs all combat state transitions.
	Used by both server (authoritative) and client (prediction).
	
	Each state has:
	- Allowed transitions (what states you can go TO from here)
	- Guards (conditions that must be true for a transition)
	- Duration (optional, auto-transitions after N frames)
	
	Usage:
		local sm = CombatStateMachine.new()
		sm:SetState("Idle")
		sm:TryTransition("Attacking", context) -- returns true/false
		sm:Tick(context) -- advance timers, check auto-transitions
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatState = require(ReplicatedStorage.Shared.Enums.CombatState)
local Constants = require(ReplicatedStorage.Shared.Data.Constants)

export type TransitionGuard = (context: CombatContext) -> boolean

export type CombatContext = {
	stamina: number,
	poise: number,
	hp: number,
	frameCounter: number,
	isGrounded: boolean,
	isAirborne: boolean,
	activeFrameData: FrameTimers?,
	comboCount: number,
	ultimateMeter: number,
	inputBuffer: { string },
}

export type FrameTimers = {
	startupRemaining: number,
	activeRemaining: number,
	recoveryRemaining: number,
	totalDuration: number,
	currentPhase: "Startup" | "Active" | "Recovery" | "Complete",
}

export type StateConfig = {
	canCancel: boolean,
	duration: number?, -- frames, nil = indefinite
	autoTransitionTo: string?, -- state to go to when duration expires
	allowedTransitions: { string },
	iFrames: boolean?,
	armorFrames: boolean?,
}

local CombatStateMachine = {}
CombatStateMachine.__index = CombatStateMachine

export type CombatStateMachine = typeof(setmetatable({} :: {
	_currentState: string,
	_previousState: string,
	_stateFrame: number,
	_stateConfigs: { [string]: StateConfig },
	_transitionGuards: { [string]: { [string]: TransitionGuard } },
	_onStateChanged: ((oldState: string, newState: string) -> ())?,
}, CombatStateMachine))

function CombatStateMachine.new(): CombatStateMachine
	local self = setmetatable({}, CombatStateMachine) :: any
	self._currentState = CombatState.Idle
	self._previousState = CombatState.Idle
	self._stateFrame = 0
	self._stateConfigs = {}
	self._transitionGuards = {}
	self._onStateChanged = nil

	self:_registerDefaultStates()
	self:_registerDefaultGuards()

	return self
end

function CombatStateMachine.GetState(self: CombatStateMachine): string
	return self._currentState
end

function CombatStateMachine.GetPreviousState(self: CombatStateMachine): string
	return self._previousState
end

function CombatStateMachine.GetStateFrame(self: CombatStateMachine): number
	return self._stateFrame
end

function CombatStateMachine.SetOnStateChanged(self: CombatStateMachine, callback: (string, string) -> ())
	self._onStateChanged = callback
end

--[[
	Force-set the state (used for server corrections / reconciliation).
]]
function CombatStateMachine.ForceState(self: CombatStateMachine, state: string, frame: number?)
	local old = self._currentState
	self._previousState = old
	self._currentState = state
	self._stateFrame = frame or 0
	if self._onStateChanged and old ~= state then
		self._onStateChanged(old, state)
	end
end

--[[
	Attempt a state transition. Returns true if successful.
]]
function CombatStateMachine.TryTransition(self: CombatStateMachine, targetState: string, context: CombatContext): boolean
	local config = self._stateConfigs[self._currentState]
	if not config then
		return false
	end

	-- Check if transition is allowed from current state
	if not table.find(config.allowedTransitions, targetState) then
		return false
	end

	-- Check guard conditions
	local guards = self._transitionGuards[self._currentState]
	if guards and guards[targetState] then
		if not guards[targetState](context) then
			return false
		end
	end

	-- Transition
	self._previousState = self._currentState
	self._currentState = targetState
	self._stateFrame = 0

	if self._onStateChanged then
		self._onStateChanged(self._previousState, targetState)
	end

	return true
end

--[[
	Advance state machine by one tick. Handles auto-transitions on duration expiry.
]]
function CombatStateMachine.Tick(self: CombatStateMachine, context: CombatContext)
	self._stateFrame += 1

	local config = self._stateConfigs[self._currentState]
	if not config then
		return
	end

	-- Check duration-based auto-transition
	if config.duration and self._stateFrame >= config.duration then
		local target = config.autoTransitionTo or CombatState.Idle
		self._previousState = self._currentState
		self._currentState = target
		self._stateFrame = 0
		if self._onStateChanged then
			self._onStateChanged(self._previousState, target)
		end
	end
end

--[[
	Check if current state has i-frames active.
]]
function CombatStateMachine.HasIFrames(self: CombatStateMachine): boolean
	local config = self._stateConfigs[self._currentState]
	return config ~= nil and config.iFrames == true
end

--[[
	Check if current state has armor frames active.
]]
function CombatStateMachine.HasArmor(self: CombatStateMachine): boolean
	local config = self._stateConfigs[self._currentState]
	return config ~= nil and config.armorFrames == true
end

--[[
	Check if current state can be cancelled (for combo chaining).
]]
function CombatStateMachine.CanCancel(self: CombatStateMachine): boolean
	local config = self._stateConfigs[self._currentState]
	return config ~= nil and config.canCancel
end

--[[
	Returns true if the entity is in a "vulnerable" state (can be hit).
]]
function CombatStateMachine.IsVulnerable(self: CombatStateMachine): boolean
	local state = self._currentState
	return state ~= CombatState.Dead
		and state ~= CombatState.BeingExecuted
		and state ~= CombatState.Executing
		and not self:HasIFrames()
end

--[[
	Returns true if the entity can act (not locked in a state).
]]
function CombatStateMachine.CanAct(self: CombatStateMachine): boolean
	local state = self._currentState
	local locked = {
		CombatState.Staggered,
		CombatState.Launched,
		CombatState.Juggled,
		CombatState.Grounded,
		CombatState.GuardBroken,
		CombatState.BeingExecuted,
		CombatState.Dead,
		CombatState.Ragdoll,
		CombatState.WallBounce,
		CombatState.GroundBounce,
	}
	return not table.find(locked, state)
end

-- ═══════════════════════════════════════════════════
-- STATE REGISTRATION
-- ═══════════════════════════════════════════════════

function CombatStateMachine._registerDefaultStates(self: CombatStateMachine)
	-- Idle: can do anything
	self._stateConfigs[CombatState.Idle] = {
		canCancel = true,
		allowedTransitions = {
			CombatState.Attacking,
			CombatState.HeavyAttacking,
			CombatState.Blocking,
			CombatState.Parrying,
			CombatState.Rolling,
			CombatState.Dashing,
			CombatState.Backstepping,
			CombatState.Sidestepping,
			CombatState.Sprinting,
			CombatState.Walking,
			CombatState.Running,
			CombatState.UsingUltimate,
			CombatState.AirAttacking,
			CombatState.GroundSlamming,
			CombatState.Staggered,
			CombatState.Launched,
			CombatState.Dead,
		},
	}

	-- Walking/Running/Sprinting: can attack, block, dodge
	for _, moveState in { CombatState.Walking, CombatState.Running, CombatState.Sprinting } do
		self._stateConfigs[moveState] = {
			canCancel = true,
			allowedTransitions = {
				CombatState.Idle,
				CombatState.Attacking,
				CombatState.HeavyAttacking,
				CombatState.Blocking,
				CombatState.Parrying,
				CombatState.Rolling,
				CombatState.Dashing,
				CombatState.Backstepping,
				CombatState.Sidestepping,
				CombatState.UsingUltimate,
				CombatState.Staggered,
				CombatState.Launched,
				CombatState.Dead,
			},
		}
	end

	-- Attacking: can cancel into next combo hit, or be interrupted
	self._stateConfigs[CombatState.Attacking] = {
		canCancel = false, -- cancel windows handled by FrameDataEngine
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Attacking, -- combo chain
			CombatState.HeavyAttacking, -- combo chain
			CombatState.Staggered,
			CombatState.Launched,
			CombatState.Dead,
			CombatState.Rolling, -- cancel if in window
			CombatState.Dashing,
		},
	}

	-- Heavy Attacking: slower, has armor, limited cancels
	self._stateConfigs[CombatState.HeavyAttacking] = {
		canCancel = false,
		armorFrames = true,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Staggered,
			CombatState.Launched,
			CombatState.Dead,
		},
	}

	-- Blocking: hold state, can parry or release
	self._stateConfigs[CombatState.Blocking] = {
		canCancel = true,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Parrying,
			CombatState.GuardBroken,
			CombatState.Staggered,
			CombatState.Rolling,
			CombatState.Backstepping,
			CombatState.Dead,
		},
	}

	-- Parrying: short window, transitions to success or recovery
	self._stateConfigs[CombatState.Parrying] = {
		canCancel = false,
		duration = Constants.PARRY_WINDOW_FRAMES + Constants.FAILED_PARRY_RECOVERY_FRAMES,
		autoTransitionTo = CombatState.Idle,
		allowedTransitions = {
			CombatState.ParrySuccess,
			CombatState.Idle, -- failed parry recovery ends
			CombatState.Staggered,
			CombatState.Dead,
		},
	}

	-- ParrySuccess: brief window to riposte
	self._stateConfigs[CombatState.ParrySuccess] = {
		canCancel = false,
		duration = Constants.PARRY_STUN_FRAMES,
		autoTransitionTo = CombatState.Idle,
		allowedTransitions = {
			CombatState.Riposte,
			CombatState.Idle,
			CombatState.Attacking,
		},
	}

	-- Riposte: guaranteed counter attack
	self._stateConfigs[CombatState.Riposte] = {
		canCancel = false,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Dead,
		},
	}

	-- Staggered: hit confirmed, in hitstun
	self._stateConfigs[CombatState.Staggered] = {
		canCancel = false,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Launched,
			CombatState.Staggered, -- re-stagger
			CombatState.GuardBroken,
			CombatState.Dead,
		},
	}

	-- Launched: airborne from launch attack
	self._stateConfigs[CombatState.Launched] = {
		canCancel = false,
		allowedTransitions = {
			CombatState.Juggled,
			CombatState.Grounded,
			CombatState.GroundBounce,
			CombatState.WallBounce,
			CombatState.Dead,
		},
	}

	-- Juggled: in air, being combo'd
	self._stateConfigs[CombatState.Juggled] = {
		canCancel = false,
		allowedTransitions = {
			CombatState.Juggled,
			CombatState.Grounded,
			CombatState.GroundBounce,
			CombatState.WallBounce,
			CombatState.Dead,
		},
	}

	-- Grounded: on floor after knockdown
	self._stateConfigs[CombatState.Grounded] = {
		canCancel = false,
		duration = 30, -- half second
		autoTransitionTo = CombatState.GettingUp,
		allowedTransitions = {
			CombatState.GettingUp,
			CombatState.Dead,
		},
	}

	-- GettingUp: recovery from ground
	self._stateConfigs[CombatState.GettingUp] = {
		canCancel = false,
		duration = 20,
		autoTransitionTo = CombatState.Idle,
		iFrames = true, -- invulnerable while getting up
		allowedTransitions = {
			CombatState.Idle,
		},
	}

	-- Rolling: evasion with i-frames
	self._stateConfigs[CombatState.Rolling] = {
		canCancel = false,
		duration = math.floor(Constants.ROLL_DURATION * Constants.TICK_RATE),
		autoTransitionTo = CombatState.Idle,
		iFrames = true,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Attacking, -- roll attack
			CombatState.Dead,
		},
	}

	-- Dashing: quick directional movement
	self._stateConfigs[CombatState.Dashing] = {
		canCancel = false,
		duration = math.floor(Constants.DASH_DURATION * Constants.TICK_RATE),
		autoTransitionTo = CombatState.Idle,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Attacking, -- dash attack
			CombatState.Dead,
		},
	}

	-- Backstepping
	self._stateConfigs[CombatState.Backstepping] = {
		canCancel = false,
		duration = math.floor(Constants.BACKSTEP_DURATION * Constants.TICK_RATE),
		autoTransitionTo = CombatState.Idle,
		iFrames = true,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Dead,
		},
	}

	-- Sidestepping
	self._stateConfigs[CombatState.Sidestepping] = {
		canCancel = false,
		duration = 12,
		autoTransitionTo = CombatState.Idle,
		iFrames = true,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Attacking,
			CombatState.Dead,
		},
	}

	-- GuardBroken: vulnerable after block depletes
	self._stateConfigs[CombatState.GuardBroken] = {
		canCancel = false,
		duration = Constants.GUARD_BREAK_STUN_FRAMES,
		autoTransitionTo = CombatState.Idle,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.BeingExecuted,
			CombatState.Dead,
		},
	}

	-- Executing: performing execution on opponent
	self._stateConfigs[CombatState.Executing] = {
		canCancel = false,
		allowedTransitions = {
			CombatState.Idle,
		},
	}

	-- BeingExecuted: receiving execution
	self._stateConfigs[CombatState.BeingExecuted] = {
		canCancel = false,
		allowedTransitions = {
			CombatState.Dead,
			CombatState.Idle, -- if interrupted by third party
		},
	}

	-- UsingUltimate: ultimate ability active
	self._stateConfigs[CombatState.UsingUltimate] = {
		canCancel = false,
		armorFrames = true,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Dead,
		},
	}

	-- SuperArmor: cannot be staggered
	self._stateConfigs[CombatState.SuperArmor] = {
		canCancel = false,
		armorFrames = true,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Attacking,
			CombatState.Dead,
		},
	}

	-- AirAttacking
	self._stateConfigs[CombatState.AirAttacking] = {
		canCancel = false,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Staggered,
			CombatState.Dead,
		},
	}

	-- GroundSlamming
	self._stateConfigs[CombatState.GroundSlamming] = {
		canCancel = false,
		allowedTransitions = {
			CombatState.Idle,
			CombatState.Staggered,
			CombatState.Dead,
		},
	}

	-- WallBounce
	self._stateConfigs[CombatState.WallBounce] = {
		canCancel = false,
		duration = 12,
		autoTransitionTo = CombatState.Staggered,
		allowedTransitions = {
			CombatState.Staggered,
			CombatState.Dead,
		},
	}

	-- GroundBounce
	self._stateConfigs[CombatState.GroundBounce] = {
		canCancel = false,
		duration = 10,
		autoTransitionTo = CombatState.Juggled,
		allowedTransitions = {
			CombatState.Juggled,
			CombatState.Grounded,
			CombatState.Dead,
		},
	}

	-- Ragdoll
	self._stateConfigs[CombatState.Ragdoll] = {
		canCancel = false,
		duration = 60,
		autoTransitionTo = CombatState.Grounded,
		allowedTransitions = {
			CombatState.Grounded,
			CombatState.Dead,
		},
	}

	-- Dead: terminal state
	self._stateConfigs[CombatState.Dead] = {
		canCancel = false,
		allowedTransitions = {
			CombatState.Idle, -- respawn
		},
	}
end

-- ═══════════════════════════════════════════════════
-- TRANSITION GUARDS
-- ═══════════════════════════════════════════════════

function CombatStateMachine._registerDefaultGuards(self: CombatStateMachine)
	self._transitionGuards = {}

	-- Helper to add a guard
	local function addGuard(fromState: string, toState: string, guard: TransitionGuard)
		if not self._transitionGuards[fromState] then
			self._transitionGuards[fromState] = {}
		end
		self._transitionGuards[fromState][toState] = guard
	end

	-- Must have stamina to attack
	addGuard(CombatState.Idle, CombatState.Attacking, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_LIGHT
	end)

	addGuard(CombatState.Idle, CombatState.HeavyAttacking, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_HEAVY
	end)

	-- Must have stamina to dodge
	addGuard(CombatState.Idle, CombatState.Rolling, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_ROLL
	end)

	addGuard(CombatState.Idle, CombatState.Dashing, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_DASH
	end)

	addGuard(CombatState.Idle, CombatState.Backstepping, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_BACKSTEP
	end)

	-- Must have stamina to parry
	addGuard(CombatState.Idle, CombatState.Parrying, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_PARRY
	end)

	addGuard(CombatState.Blocking, CombatState.Parrying, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_PARRY
	end)

	-- Must have full ultimate meter
	addGuard(CombatState.Idle, CombatState.UsingUltimate, function(ctx)
		return ctx.ultimateMeter >= Constants.ULTIMATE_METER_MAX
	end)

	-- Combo chain: must have stamina and be in cancel window
	addGuard(CombatState.Attacking, CombatState.Attacking, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_LIGHT
	end)

	addGuard(CombatState.Attacking, CombatState.HeavyAttacking, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_HEAVY
	end)

	-- Roll from block: must have stamina
	addGuard(CombatState.Blocking, CombatState.Rolling, function(ctx)
		return ctx.stamina >= Constants.STAMINA_COST_ROLL
	end)

	-- Same guards for movement states
	for _, moveState in { CombatState.Walking, CombatState.Running, CombatState.Sprinting } do
		addGuard(moveState, CombatState.Attacking, function(ctx)
			return ctx.stamina >= Constants.STAMINA_COST_LIGHT
		end)
		addGuard(moveState, CombatState.HeavyAttacking, function(ctx)
			return ctx.stamina >= Constants.STAMINA_COST_HEAVY
		end)
		addGuard(moveState, CombatState.Rolling, function(ctx)
			return ctx.stamina >= Constants.STAMINA_COST_ROLL
		end)
		addGuard(moveState, CombatState.Dashing, function(ctx)
			return ctx.stamina >= Constants.STAMINA_COST_DASH
		end)
		addGuard(moveState, CombatState.Backstepping, function(ctx)
			return ctx.stamina >= Constants.STAMINA_COST_BACKSTEP
		end)
		addGuard(moveState, CombatState.Parrying, function(ctx)
			return ctx.stamina >= Constants.STAMINA_COST_PARRY
		end)
		addGuard(moveState, CombatState.UsingUltimate, function(ctx)
			return ctx.ultimateMeter >= Constants.ULTIMATE_METER_MAX
		end)
	end
end

return CombatStateMachine
