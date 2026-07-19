--!strict
--[[
	LatencyResponder.luau
	Client-side component that responds to server Ping events with Pong.
	This allows the server's LatencyTracker to measure round-trip time.
]]

local LatencyResponder = {}
LatencyResponder.__index = LatencyResponder

export type LatencyResponder = typeof(setmetatable({} :: {
	_network: any,
}, LatencyResponder))

function LatencyResponder.new(network: any): LatencyResponder
	local self = setmetatable({}, LatencyResponder) :: any
	self._network = network
	return self
end

function LatencyResponder.Init(self: LatencyResponder, _container: any)
	-- Respond to server pings immediately
	self._network:OnClientEvent("Ping", function(timestamp: any)
		self._network:FireServer("Pong", timestamp)
	end)
end

function LatencyResponder.Start(self: LatencyResponder)
	-- No-op: purely reactive
end

return LatencyResponder
