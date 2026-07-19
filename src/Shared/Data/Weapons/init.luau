--!strict
--[[
	Weapons/init.luau
	Weapon registry. Loads all weapon configs and provides lookup.
]]

local Katana = require(script.Katana)
local Greatsword = require(script.Greatsword)
local DualSwords = require(script.DualSwords)

local WeaponRegistry = {}

local _configs: { [string]: any } = {
	Katana = Katana,
	Greatsword = Greatsword,
	DualSwords = DualSwords,
}

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
