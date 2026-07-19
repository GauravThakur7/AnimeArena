--!strict
--[[
	Arenas/init.luau
	Arena registry. Loads all arena configs and provides lookup.
	Arena data modules added in Phase 13.
]]

local ArenaRegistry = {}

-- Arena configs will be registered here in Phase 13
local _configs: { [string]: any } = {}

function ArenaRegistry.Get(arenaId: string): any?
	return _configs[arenaId]
end

function ArenaRegistry.GetAll(): { [string]: any }
	return _configs
end

function ArenaRegistry.GetIds(): { string }
	local ids = {}
	for id in _configs do
		table.insert(ids, id)
	end
	return ids
end

function ArenaRegistry.GetForMode(mode: string): { any }
	local result = {}
	for _, config in _configs do
		if table.find(config.SupportedModes, mode) then
			table.insert(result, config)
		end
	end
	return result
end

return table.freeze(ArenaRegistry)
