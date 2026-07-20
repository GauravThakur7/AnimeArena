--!strict
--[[
	AnimationStateMachine.luau
	Maps combat states to animation keys and defines transition rules.
	
	This is a pure logic module — it decides WHICH animation should play
	based on the current combat state, weapon, and combo position.
	It does NOT interact with Roblox's Animator directly.
	
	Usage:
		local asm = AnimationStateMachine.new()
		local animKey = asm:GetAnimationKey(combatState, attackType, comboPosition)
		local priority = asm:GetPriority(combatState)
		local fadeTime = asm:GetFadeTime(fromState, toState)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatState = require(ReplicatedStorage.Shared.Enums.CombatState)

export type AnimationPriority = "Idle" | "Movement" | "Action" | "Core"

export type TransitionRule = {
	FadeTime: number, -- crossfade duration in seconds
	Priority: AnimationPriority,
	Looped: boolean,
	Speed: number?, -- playback speed multiplier
}

local AnimationStateMachine = {}
AnimationStateMachine.__index = AnimationStateMachine

export type AnimationStateMachine = typeof(setmetatable({} :: {
	_currentKey: string,
	_currentPriority: AnimationPriority,
	_rules: { [string]: TransitionRule },
}, AnimationStateMachine))

function AnimationStateMachine.new(): AnimationStateMachine
	local self = setmetatable({}, AnimationStateMachine) :: any
	self._currentKey = "Idle"
	self._currentPriority = "Idle"
	self._rules = {}
	self:_registerDefaultRules()
	return self
end

--[[
	Get the animation key for a given combat state.
	@param combatState — Current combat state string
	@param attackType — "Light" | "Heavy" | nil
	@param comboPosition — Which hit in the combo (1, 2, 3...)
	@return Animation key string that maps to AnimationSets
]]
function AnimationStateMachine.GetAnimationKey(
	self: AnimationStateMachine,
	combatState: string,
	attackType: string?,
	comboPosition: number?
): string
	if combatState == CombatState.Attacking then
		local pos = comboPosition or 1
		return "Light" .. tostring(pos)
	elseif combatState == CombatState.HeavyAttacking then
		return "Heavy"
	elseif combatState == CombatState.Blocking then
		return "Block"
	elseif combatState == CombatState.Parrying then
		return "Parry"
	elseif combatState == CombatState.ParrySuccess then
		return "ParrySuccess"
	elseif combatState == CombatState.Riposte then
		return "Light1" -- riposte uses first light animation
	elseif combatState == CombatState.Rolling then
		return "Roll"
	elseif combatState == CombatState.Dashing then
		return "Dash"
	elseif combatState == CombatState.Backstepping then
		return "Backstep"
	elseif combatState == CombatState.Sliding then
		return "Slide"
	elseif combatState == CombatState.Staggered then
		return "Stagger"
	elseif combatState == CombatState.Launched then
		return "Launched"
	elseif combatState == CombatState.Juggled then
		return "Launched"
	elseif combatState == CombatState.Grounded then
		return "Grounded"
	elseif combatState == CombatState.GettingUp then
		return "GetUp"
	elseif combatState == CombatState.GuardBroken then
		return "GuardBreak"
	elseif combatState == CombatState.UsingUltimate then
		return "Ultimate"
	elseif combatState == CombatState.Executing then
		return "Execution"
	elseif combatState == CombatState.BeingExecuted then
		return "BeingExecuted"
	elseif combatState == CombatState.Dead then
		return "Death"
	elseif combatState == CombatState.AirAttacking then
		return "AirAttack"
	elseif combatState == CombatState.GroundSlamming then
		return "GroundSlam"
	elseif combatState == CombatState.Sprinting then
		return "Sprint"
	elseif combatState == CombatState.Running then
		return "Run"
	elseif combatState == CombatState.Walking then
		return "Walk"
	end

	return "CombatIdle"
end

--[[
	Get the transition rule for a given animation key.
]]
function AnimationStateMachine.GetRule(self: AnimationStateMachine, animKey: string): TransitionRule
	return self._rules[animKey] or {
		FadeTime = 0.1,
		Priority = "Action",
		Looped = false,
		Speed = 1.0,
	}
end

--[[
	Get crossfade time for a state transition.
]]
function AnimationStateMachine.GetFadeTime(self: AnimationStateMachine, fromKey: string, toKey: string): number
	-- Instant transitions for combat-critical changes
	local instantPairs = {
		Stagger = true,
		Launched = true,
		GuardBreak = true,
		Death = true,
	}
	if instantPairs[toKey] then
		return 0.05 -- near-instant for hit reactions
	end

	-- Quick transitions for attacks (responsive feel)
	if string.find(toKey, "Light") or toKey == "Heavy" then
		return 0.08
	end

	-- Standard crossfade
	local rule = self._rules[toKey]
	if rule then
		return rule.FadeTime
	end

	return 0.15
end

--[[
	Get the Roblox AnimationPriority equivalent.
]]
function AnimationStateMachine.GetRobloxPriority(self: AnimationStateMachine, animKey: string): Enum.AnimationPriority
	local rule = self._rules[animKey]
	if not rule then
		return Enum.AnimationPriority.Action
	end

	if rule.Priority == "Idle" then
		return Enum.AnimationPriority.Idle
	elseif rule.Priority == "Movement" then
		return Enum.AnimationPriority.Movement
	elseif rule.Priority == "Action" then
		return Enum.AnimationPriority.Action
	elseif rule.Priority == "Core" then
		return Enum.AnimationPriority.Action4
	end

	return Enum.AnimationPriority.Action
end

--[[
	Check if an animation should loop.
]]
function AnimationStateMachine.IsLooped(self: AnimationStateMachine, animKey: string): boolean
	local rule = self._rules[animKey]
	if rule then
		return rule.Looped
	end
	return false
end

-- ═══════════════════════════════════════════════════
-- DEFAULT RULES
-- ═══════════════════════════════════════════════════

function AnimationStateMachine._registerDefaultRules(self: AnimationStateMachine)
	-- Idle & Movement (looped, low priority)
	self._rules["Idle"] = { FadeTime = 0.2, Priority = "Idle", Looped = true }
	self._rules["CombatIdle"] = { FadeTime = 0.15, Priority = "Idle", Looped = true }
	self._rules["Walk"] = { FadeTime = 0.15, Priority = "Movement", Looped = true }
	self._rules["Run"] = { FadeTime = 0.15, Priority = "Movement", Looped = true }
	self._rules["Sprint"] = { FadeTime = 0.15, Priority = "Movement", Looped = true }

	-- Attacks (single-shot, action priority, fast fade-in)
	self._rules["Light1"] = { FadeTime = 0.08, Priority = "Action", Looped = false, Speed = 1.0 }
	self._rules["Light2"] = { FadeTime = 0.06, Priority = "Action", Looped = false, Speed = 1.0 }
	self._rules["Light3"] = { FadeTime = 0.06, Priority = "Action", Looped = false, Speed = 1.0 }
	self._rules["Light4"] = { FadeTime = 0.06, Priority = "Action", Looped = false, Speed = 1.0 }
	self._rules["Light5"] = { FadeTime = 0.06, Priority = "Action", Looped = false, Speed = 1.0 }
	self._rules["Heavy"] = { FadeTime = 0.1, Priority = "Action", Looped = false, Speed = 1.0 }
	self._rules["DashAttack"] = { FadeTime = 0.08, Priority = "Action", Looped = false }
	self._rules["Launch"] = { FadeTime = 0.08, Priority = "Action", Looped = false }
	self._rules["AirAttack"] = { FadeTime = 0.08, Priority = "Action", Looped = false }
	self._rules["GroundSlam"] = { FadeTime = 0.08, Priority = "Action", Looped = false }

	-- Defense
	self._rules["Block"] = { FadeTime = 0.1, Priority = "Action", Looped = true }
	self._rules["BlockHit"] = { FadeTime = 0.05, Priority = "Action", Looped = false }
	self._rules["Parry"] = { FadeTime = 0.08, Priority = "Action", Looped = false }
	self._rules["ParrySuccess"] = { FadeTime = 0.05, Priority = "Action", Looped = false }
	self._rules["GuardBreak"] = { FadeTime = 0.05, Priority = "Core", Looped = false }

	-- Movement Actions
	self._rules["Roll"] = { FadeTime = 0.08, Priority = "Action", Looped = false }
	self._rules["Dash"] = { FadeTime = 0.06, Priority = "Action", Looped = false }
	self._rules["Backstep"] = { FadeTime = 0.08, Priority = "Action", Looped = false }
	self._rules["Slide"] = { FadeTime = 0.08, Priority = "Action", Looped = false }

	-- Hit Reactions (instant, highest priority)
	self._rules["Stagger"] = { FadeTime = 0.05, Priority = "Core", Looped = false }
	self._rules["HitLight"] = { FadeTime = 0.05, Priority = "Core", Looped = false }
	self._rules["HitHeavy"] = { FadeTime = 0.05, Priority = "Core", Looped = false }
	self._rules["HitLeft"] = { FadeTime = 0.05, Priority = "Core", Looped = false }
	self._rules["HitRight"] = { FadeTime = 0.05, Priority = "Core", Looped = false }
	self._rules["HitBack"] = { FadeTime = 0.05, Priority = "Core", Looped = false }
	self._rules["Launched"] = { FadeTime = 0.05, Priority = "Core", Looped = false }
	self._rules["Grounded"] = { FadeTime = 0.1, Priority = "Core", Looped = true }
	self._rules["GetUp"] = { FadeTime = 0.1, Priority = "Action", Looped = false }

	-- Special
	self._rules["Ultimate"] = { FadeTime = 0.1, Priority = "Core", Looped = false }
	self._rules["SpecialSkill"] = { FadeTime = 0.08, Priority = "Action", Looped = false }
	self._rules["Execution"] = { FadeTime = 0.1, Priority = "Core", Looped = false }
	self._rules["BeingExecuted"] = { FadeTime = 0.1, Priority = "Core", Looped = false }
	self._rules["Victory"] = { FadeTime = 0.2, Priority = "Action", Looped = true }
	self._rules["Death"] = { FadeTime = 0.1, Priority = "Core", Looped = false }
end

return AnimationStateMachine
