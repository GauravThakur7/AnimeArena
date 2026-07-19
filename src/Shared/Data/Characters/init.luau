--!strict
--[[
	Characters/init.luau
	Character registry. Loads all character configs and provides lookup.
	Character data modules added in Phase 6.
]]

local CharacterRegistry = {}

-- Character configs will be registered here in Phase 6
local _configs: { [string]: any } = {}

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
