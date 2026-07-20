--!strict
--[[
	PassiveSystem.luau
	Applies passive effects from character configs to combat entities.
	
	Passives are stat modifiers or conditional effects that are always active.
	This module handles the application logic — each passive is identified
	by a string key that maps to a handler function.
	
	Usage:
		PassiveSystem.Apply(entity, passiveId, weaponConfig)
]]

local PassiveSystem = {}

export type PassiveEffect = {
	Id: string,
	Apply: (entity: any, value: number?) -> (),
	Description: string,
}

-- Registry of passive effect handlers
local _handlers: { [string]: (entity: any, value: number?) -> () } = {}

--[[
	Register a passive effect handler.
]]
function PassiveSystem.Register(id: string, handler: (entity: any, value: number?) -> ())
	_handlers[id] = handler
end

--[[
	Apply a passive effect to an entity.
	@param entity — The CombatEntity to modify
	@param passiveId — The passive effect key from character/weapon config
	@param value — Optional numeric value for the effect
]]
function PassiveSystem.Apply(entity: any, passiveId: string, value: number?)
	local handler = _handlers[passiveId]
	if handler then
		handler(entity, value)
	end
end

--[[
	Check if a passive is registered.
]]
function PassiveSystem.HasPassive(passiveId: string): boolean
	return _handlers[passiveId] ~= nil
end

-- ═══════════════════════════════════════════════════
-- DEFAULT PASSIVE HANDLERS
-- ═══════════════════════════════════════════════════

-- Blood Frenzy: Each hit increases attack speed (tracked externally via combo count)
-- This is a marker passive — actual speed boost is applied in FrameDataEngine scaling
PassiveSystem.Register("BloodFrenzy", function(_entity: any, _value: number?)
	-- Marker: CombatService checks combo count and applies speed scaling
end)

-- Storm Conductor: Parry boosts next attack damage by 30%
-- Marker: CombatService applies damage multiplier after successful parry
PassiveSystem.Register("StormConductor", function(_entity: any, _value: number?)
	-- Marker: tracked via entity._parryDamageBoost flag
end)

-- Unbreakable Will: Poise regenerates 50% faster
PassiveSystem.Register("UnbreakableWill", function(entity: any, value: number?)
	local mult = value or 1.5
	local currentRate = entity.Poise._regenRate
	entity.Poise._regenRate = currentRate * mult
end)

-- Poise Regen Boost (alias for weapon passive)
PassiveSystem.Register("PoiseRegenBoost", function(entity: any, value: number?)
	local mult = value or 1.5
	entity.Poise._regenRate = entity.Poise._regenRate * mult
end)

-- Parry Damage Boost (sets a flag for CombatService to check)
PassiveSystem.Register("ParryDamageBoost", function(entity: any, value: number?)
	entity._parryDamageBoostMult = value or 1.3
	entity._parryDamageBoostActive = false
end)

-- Combo Speed Boost (marker — CombatService reads combo count)
PassiveSystem.Register("ComboSpeedBoost", function(entity: any, value: number?)
	entity._comboSpeedBoostPerHit = value or 0.05
end)

-- Life Drain (placeholder — will heal on hit)
PassiveSystem.Register("LifeDrain", function(entity: any, _value: number?)
	entity._hasLifeDrain = true
end)

-- Shadow Step (placeholder — enhanced dodge)
PassiveSystem.Register("ShadowStep", function(entity: any, _value: number?)
	entity._hasShadowStep = true
end)

-- Arcane Infusion (placeholder)
PassiveSystem.Register("ArcaneInfusion", function(entity: any, _value: number?)
	entity._hasArcaneInfusion = true
end)

-- Dragon Scale (placeholder — damage reduction)
PassiveSystem.Register("DragonScale", function(entity: any, _value: number?)
	entity._hasDragonScale = true
end)

-- Perfect Read (placeholder — extended parry window)
PassiveSystem.Register("PerfectRead", function(entity: any, _value: number?)
	entity._hasExtendedParry = true
end)

-- Vanish (placeholder — stealth after dodge)
PassiveSystem.Register("Vanish", function(entity: any, _value: number?)
	entity._hasVanish = true
end)

-- Adaptive Hunt (placeholder — weapon mode switch)
PassiveSystem.Register("AdaptiveHunt", function(entity: any, _value: number?)
	entity._hasAdaptiveHunt = true
end)

return table.freeze(PassiveSystem)
