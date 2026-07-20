--!strict
--[[
	CharacterHandler.luau
	Server-side component that manages character selection and applies
	character stats/passives to a player's CombatEntity.
	
	Usage:
		local handler = CharacterHandler.new(player)
		handler:SelectCharacter("StormRonin")
		handler:ApplyToEntity(combatEntity)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterRegistry = require(ReplicatedStorage.Shared.Data.Characters)
local PassiveSystem = require(ReplicatedStorage.Shared.Modules.PassiveSystem)

local CharacterHandler = {}
CharacterHandler.__index = CharacterHandler

export type CharacterHandler = typeof(setmetatable({} :: {
	_player: Player,
	_characterId: string,
	_characterConfig: any,
}, CharacterHandler))

function CharacterHandler.new(player: Player, defaultCharacterId: string?): CharacterHandler
	local self = setmetatable({}, CharacterHandler) :: any
	self._player = player
	self._characterId = defaultCharacterId or "StormRonin"
	self._characterConfig = CharacterRegistry.Get(self._characterId)
	return self
end

--[[
	Select a character by ID. Returns true if valid.
]]
function CharacterHandler.SelectCharacter(self: CharacterHandler, characterId: string): boolean
	local config = CharacterRegistry.Get(characterId)
	if not config then
		return false
	end
	self._characterId = characterId
	self._characterConfig = config
	return true
end

--[[
	Get the currently selected character ID.
]]
function CharacterHandler.GetCharacterId(self: CharacterHandler): string
	return self._characterId
end

--[[
	Get the character config.
]]
function CharacterHandler.GetConfig(self: CharacterHandler): any?
	return self._characterConfig
end

--[[
	Get the weapon ID associated with the selected character.
]]
function CharacterHandler.GetWeaponId(self: CharacterHandler): string
	if self._characterConfig then
		return self._characterConfig.DefaultWeaponId
	end
	return "Katana"
end

--[[
	Apply character stats to a CombatEntity.
	Sets HP, stamina, poise, speed based on character config.
]]
function CharacterHandler.ApplyToEntity(self: CharacterHandler, entity: any)
	local config = self._characterConfig
	if not config then
		return
	end

	-- Set base stats
	entity.MaxHP = config.MaxHP
	entity.HP = config.MaxHP
	entity.Stamina._max = config.MaxStamina
	entity.Stamina._current = config.MaxStamina
	entity.Stamina._regenRate = config.StaminaRegenRate
	entity.Poise._max = config.MaxPoise
	entity.Poise._current = config.MaxPoise
	entity.Poise._regenRate = config.PoiseRegenRate

	-- Apply passive effect
	if config.PassiveId then
		local weaponConfig = nil -- passive value comes from weapon if available
		local passiveValue = nil

		-- Check if weapon has a matching passive with a value
		-- (weapon passive and character passive can stack)
		PassiveSystem.Apply(entity, config.PassiveId, passiveValue)
	end
end

--[[
	Get movement speed for this character.
]]
function CharacterHandler.GetBaseSpeed(self: CharacterHandler): number
	if self._characterConfig then
		return self._characterConfig.BaseSpeed
	end
	return 20
end

--[[
	Check if this character is unlocked.
]]
function CharacterHandler.IsUnlocked(self: CharacterHandler): boolean
	if self._characterConfig then
		return self._characterConfig.Unlocked == true
	end
	return false
end

--[[
	Get all unlocked character IDs (for character select screen).
]]
function CharacterHandler.GetUnlockedCharacters(): { string }
	local unlocked = {}
	for id, config in CharacterRegistry.GetAll() do
		if config.Unlocked then
			table.insert(unlocked, id)
		end
	end
	return unlocked
end

return CharacterHandler
