--!strict
--[[
	LatencyTracker.luau
	Measures per-player round-trip time (RTT) using periodic pings.
	Stores a rolling average of the last N samples for stable latency estimation.
	
	The server fires a ping with a timestamp, the client echoes it back immediately,
	and the server calculates RTT. One-way latency = RTT / 2.
	
	Usage:
		local tracker = LatencyTracker.new(network)
		tracker:Init()
		tracker:GetLatency(player) -- one-way latency in ms
		tracker:GetQualityTier(player) -- "Excellent" | "Good" | "Fair" | "Poor"
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Data.Constants)

local LatencyTracker = {}
LatencyTracker.__index = LatencyTracker

export type QualityTier = "Excellent" | "Good" | "Fair" | "Poor"

export type LatencyTracker = typeof(setmetatable({} :: {
	_network: any,
	_samples: { [Player]: { number } },
	_pendingPings: { [Player]: number },
	_maxSamples: number,
	_pingInterval: number,
	_lastPingTime: { [Player]: number },
}, LatencyTracker))

function LatencyTracker.new(network: any): LatencyTracker
	local self = setmetatable({}, LatencyTracker) :: any
	self._network = network
	self._samples = {}
	self._pendingPings = {}
	self._maxSamples = 10
	self._pingInterval = 2.0 -- seconds between pings
	self._lastPingTime = {}
	return self
end

function LatencyTracker.Init(self: LatencyTracker)
	self._network:RegisterEvent("Ping")
	self._network:RegisterEvent("Pong")

	self._network:OnServerEvent("Pong", function(player: Player, data: any)
		self:_onPong(player, data)
	end)

	Players.PlayerAdded:Connect(function(player)
		self._samples[player] = {}
		self._lastPingTime[player] = 0
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._samples[player] = nil
		self._pendingPings[player] = nil
		self._lastPingTime[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		self._samples[player] = {}
		self._lastPingTime[player] = 0
	end
end

--[[
	Should be called every server tick. Sends pings at the configured interval.
]]
function LatencyTracker.Tick(self: LatencyTracker)
	local now = os.clock()

	for player in self._samples do
		local lastPing = self._lastPingTime[player] or 0
		if now - lastPing >= self._pingInterval then
			self:_sendPing(player)
			self._lastPingTime[player] = now
		end
	end
end

--[[
	Get the estimated one-way latency for a player in milliseconds.
	Returns 0 if no samples have been collected yet.
]]
function LatencyTracker.GetLatency(self: LatencyTracker, player: Player): number
	local samples = self._samples[player]
	if not samples or #samples == 0 then
		return 0
	end

	local sum = 0
	for _, rtt in samples do
		sum += rtt
	end
	local avgRtt = sum / #samples
	return avgRtt / 2 -- one-way
end

--[[
	Get the RTT (round-trip time) in milliseconds.
]]
function LatencyTracker.GetRTT(self: LatencyTracker, player: Player): number
	local samples = self._samples[player]
	if not samples or #samples == 0 then
		return 0
	end

	local sum = 0
	for _, rtt in samples do
		sum += rtt
	end
	return sum / #samples
end

--[[
	Get quality tier based on latency thresholds.
]]
function LatencyTracker.GetQualityTier(self: LatencyTracker, player: Player): QualityTier
	local latency = self:GetLatency(player)

	if latency <= 50 then
		return "Excellent"
	elseif latency <= 100 then
		return "Good"
	elseif latency <= 200 then
		return "Fair"
	else
		return "Poor"
	end
end

--[[
	Check if a player's latency exceeds the lag compensation window.
]]
function LatencyTracker.IsExcessive(self: LatencyTracker, player: Player): boolean
	return self:GetLatency(player) > (Constants.MAX_REWIND_MS)
end

-- ═══════════════════════════════════════════════════
-- PRIVATE
-- ═══════════════════════════════════════════════════

function LatencyTracker._sendPing(self: LatencyTracker, player: Player)
	local timestamp = os.clock() * 1000 -- ms precision
	self._pendingPings[player] = timestamp
	self._network:FireClient("Ping", player, timestamp)
end

function LatencyTracker._onPong(self: LatencyTracker, player: Player, data: any)
	if typeof(data) ~= "number" then
		return
	end

	local sentTimestamp = self._pendingPings[player]
	if not sentTimestamp then
		return
	end

	local now = os.clock() * 1000
	local rtt = now - sentTimestamp

	-- Sanity check: reject negative or impossibly high values
	if rtt < 0 or rtt > 5000 then
		return
	end

	self._pendingPings[player] = nil

	-- Add to rolling samples
	local samples = self._samples[player]
	if not samples then
		return
	end

	table.insert(samples, rtt)
	while #samples > self._maxSamples do
		table.remove(samples, 1)
	end
end

return LatencyTracker
