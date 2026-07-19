--!strict
--[[
	Weapons/init.luau
	Weapon registry. Loads all weapon configs and provides lookup.
	Weapon data modules added in Phase 5.
]]

local WeaponRegistry = {}

-- Weapon configs will be registered here in Phase 5
local _configs: { [string]: any } = {}

function WeaponRegistry.Get(weaponId: string): any?
	return _configs[weaponId]
end

function WeaponRegistry.GetAll(): { [string]: any }
	return _configs
end

function WeaponRegistry.GetIds(): { string }
	local ids = {}
	for id in _configs do
		table.insert(ids, id)
	end
	return ids
end

return table.freeze(WeaponRegistry)
