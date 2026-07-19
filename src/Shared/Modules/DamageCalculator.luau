--!strict
--[[
	DamageCalculator.luau
	Computes final damage from an attack considering:
	- Base damage
	- Combo scaling
	- Block reduction
	- Armor reduction
	- Critical multiplier
	- Hurtbox multiplier (head/body/legs)
	
	Pure function module — no state, no side effects.
	
	Usage:
		local result = DamageCalculator.Calculate(params)
		-- result.finalDamage, result.wasBlocked, result.poiseDamage, etc.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Data.Constants)

export type DamageParams = {
	BaseDamage: number,
	ComboHitNumber: number, -- 1 = first hit, 2 = second, etc.
	IsBlocked: boolean,
	HasArmor: boolean, -- target has super armor
	HurtboxZone: string, -- "Head" | "Body" | "Legs"
	IsCritical: boolean?,
	PoiseDamage: number,
	AttackerBuff: number?, -- multiplier (default 1.0)
	DefenderBuff: number?, -- reduction multiplier (default 1.0)
}

export type DamageResult = {
	FinalDamage: number,
	PoiseDamage: number,
	WasBlocked: boolean,
	ChipDamage: number, -- damage dealt through block to stamina
	Scaling: number, -- the scaling multiplier applied
	HurtboxMultiplier: number,
}

local DamageCalculator = {}

local HURTBOX_MULTIPLIERS = {
	Head = 1.5,
	Body = 1.0,
	Legs = 0.8,
}

--[[
	Calculate final damage from an attack.
]]
function DamageCalculator.Calculate(params: DamageParams): DamageResult
	local baseDmg = params.BaseDamage
	local comboHit = params.ComboHitNumber

	-- 1. Apply combo damage scaling
	local scaling: number
	if comboHit <= #Constants.DAMAGE_SCALING then
		scaling = Constants.DAMAGE_SCALING[comboHit]
	else
		scaling = Constants.DAMAGE_SCALING_FLOOR
	end

	local damage = baseDmg * scaling

	-- 2. Apply hurtbox multiplier
	local hurtboxMult = HURTBOX_MULTIPLIERS[params.HurtboxZone] or 1.0
	damage *= hurtboxMult

	-- 3. Apply attacker buff
	local atkBuff = params.AttackerBuff or 1.0
	damage *= atkBuff

	-- 4. Apply defender buff (damage reduction)
	local defBuff = params.DefenderBuff or 1.0
	damage *= defBuff

	-- 5. Apply critical multiplier
	if params.IsCritical then
		damage *= 1.5
	end

	-- 6. Handle blocking
	local chipDamage = 0
	local wasBlocked = params.IsBlocked

	if wasBlocked then
		chipDamage = damage * (1 - Constants.BLOCK_DAMAGE_REDUCTION)
		damage *= (1 - Constants.BLOCK_DAMAGE_REDUCTION) -- reduced damage through block
	end

	-- 7. Poise damage (not affected by blocking — still applies through block)
	local poiseDmg = params.PoiseDamage
	if wasBlocked then
		poiseDmg *= 0.5 -- halved when blocked
	end

	-- Floor damage to prevent fractional HP
	damage = math.floor(damage)
	chipDamage = math.floor(chipDamage)

	return {
		FinalDamage = damage,
		PoiseDamage = poiseDmg,
		WasBlocked = wasBlocked,
		ChipDamage = chipDamage,
		Scaling = scaling,
		HurtboxMultiplier = hurtboxMult,
	}
end

--[[
	Calculate how many frames of hitstun to apply based on the attack's frame data.
]]
function DamageCalculator.CalculateHitstun(baseHitstun: number, comboHit: number): number
	-- Reduce hitstun slightly per combo hit to prevent infinites
	local reduction = math.max(0, (comboHit - 1) * 2)
	return math.max(8, baseHitstun - reduction) -- minimum 8 frames hitstun
end

--[[
	Calculate knockback force with combo scaling.
]]
function DamageCalculator.CalculateKnockback(baseForce: number, comboHit: number): number
	-- Knockback increases slightly per combo hit (for juggle physics)
	local multiplier = 1.0 + (comboHit - 1) * 0.1
	return baseForce * multiplier
end

--[[
	Calculate ultimate meter gain from dealing damage.
]]
function DamageCalculator.CalculateUltGain(damage: number, source: "Deal" | "Receive" | "Parry"): number
	if source == "Deal" then
		return damage * Constants.ULTIMATE_GAIN_PER_DAMAGE
	elseif source == "Receive" then
		return damage * Constants.ULTIMATE_GAIN_PER_HIT_TAKEN
	elseif source == "Parry" then
		return Constants.ULTIMATE_GAIN_PER_PARRY
	end
	return 0
end

return table.freeze(DamageCalculator)
