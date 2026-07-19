--!strict
--[[
	MonetizationService.luau
	Handles GamePasses, DevProducts, shop, and currency transactions.
	Implementation in Phase 16.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal

local MonetizationService = {}
MonetizationService.__index = MonetizationService

export type MonetizationService = typeof(setmetatable({} :: {
	_network: any,
	OnPurchaseComplete: typeof(Signal.new()),
}, MonetizationService))

function MonetizationService.new(network: any): MonetizationService
	local self = setmetatable({}, MonetizationService) :: any
	self._network = network
	self.OnPurchaseComplete = Signal.new()
	return self
end

function MonetizationService.Init(self: MonetizationService, _container: any)
	self._network:RegisterEvent("ShopData")
	self._network:RegisterEvent("PurchaseRequest")
	self._network:RegisterEvent("PurchaseResult")
end

function MonetizationService.Start(self: MonetizationService)
	-- GamePass/DevProduct callbacks in Phase 16
end

return MonetizationService
