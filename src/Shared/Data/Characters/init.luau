--!strict
--[[
	Characters/init.luau
	Character registry. Loads all character configs and provides lookup.
]]

local CrimsonDemonSwordsman = require(script.CrimsonDemonSwordsman)
local StormRonin = require(script.StormRonin)
local HolyKnightCommander = require(script.HolyKnightCommander)
local ShadowBladeWanderer = require(script.ShadowBladeWanderer)
local AbyssReaper = require(script.AbyssReaper)
local ArcaneSpellblade = require(script.ArcaneSpellblade)
local DragonSlayer = require(script.DragonSlayer)
local CelestialSamurai = require(script.CelestialSamurai)
local PhantomAssassin = require(script.PhantomAssassin)
local BeastHunter = require(script.BeastHunter)

local CharacterRegistry = {}

local _configs: { [string]: any } = {
	CrimsonDemonSwordsman = CrimsonDemonSwordsman,
	StormRonin = StormRonin,
	HolyKnightCommander = HolyKnightCommander,
	ShadowBladeWanderer = ShadowBladeWanderer,
	AbyssReaper = AbyssReaper,
	ArcaneSpellblade = ArcaneSpellblade,
	DragonSlayer = DragonSlayer,
	CelestialSamurai = CelestialSamurai,
	PhantomAssassin = PhantomAssassin,
	BeastHunter = BeastHunter,
}

function CharacterRegistry.Get(characterId: string): any?
	return _configs[characterId]
end

function CharacterRegistry.GetAll(): { [string]: any }
	return _configs
end

function CharacterRegistry.GetIds(): { string }
	local ids = {}
	for id in _configs do
		table.insert(ids, id)
	end
	return ids
end

return table.freeze(CharacterRegistry)
