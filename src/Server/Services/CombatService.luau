--!strict
--[[
	CombatService.luau
	Server-side combat authority. Validates attacks, manages hit detection,
	and broadcasts combat state. Implementation in Phase 2.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local CombatService = {}
CombatService.__index = CombatService

export type CombatService = typeof(setmetatable({} :: {
	_network: Shared.Framework.Network.Network,
	OnHitConfirmed: typeof(Signal.new()),
}, CombatService))

function CombatService.new(network: any): CombatService
	local self = setmetatable({}, CombatService) :: any
	self._network = network
	self.OnHitConfirmed = Signal.new()
	return self
end

function CombatService.Init(self: CombatService, _container: any)
	-- Register remotes (Phase 2 will add handlers)
	self._network:RegisterEvent("AttackRequest")
	self._network:RegisterEvent("BlockRequest")
	self._network:RegisterEvent("ParryRequest")
	self._network:RegisterEvent("DodgeRequest")
	self._network:RegisterEvent("HitConfirm")
	self._network:RegisterEvent("StateUpdate")
	self._network:RegisterUnreliableEvent("PositionSync")
end

function CombatService.Start(self: CombatService)
	-- Combat loop starts in Phase 2
end

return CombatService
