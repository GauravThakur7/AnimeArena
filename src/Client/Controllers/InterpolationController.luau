--!strict
--[[
	InterpolationController.luau
	Smoothly interpolates other players' visual positions between server updates.
	
	Instead of relying solely on Roblox's built-in character replication (which can be jerky
	at high latency), this stores received position data and interpolates between snapshots.
	
	Renders other players at a slight delay (interpolation buffer) for smooth visuals.
	Local player is NOT interpolated — they use prediction.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Data.Constants

local INTERPOLATION_DELAY = 3 -- ticks behind (50ms at 60Hz) for smooth rendering
local MAX_SNAP_DISTANCE = 10 -- studs: if error exceeds this, snap instead of lerp
local LERP_SPEED = 15 -- units per second for smooth correction

export type PlayerSnapshot = {
	Tick: number,
	Position: Vector3,
	Timestamp: number,
}

local InterpolationController = {}
InterpolationController.__index = InterpolationController

export type InterpolationController = typeof(setmetatable({} :: {
	_network: any,
	_buffers: { [number]: { PlayerSnapshot } }, -- userId → snapshot buffer
	_maxBufferSize: number,
	_enabled: boolean,
}, InterpolationController))

function InterpolationController.new(network: any): InterpolationController
	local self = setmetatable({}, InterpolationController) :: any
	self._network = network
	self._buffers = {}
	self._maxBufferSize = 20
	self._enabled = true
	return self
end

function InterpolationController.Init(self: InterpolationController, _container: any)
	-- Listen for position sync from other players
	self._network:OnClientUnreliableEvent("PositionSync", function(data: any)
		if typeof(data) ~= "table" then
			return
		end
		self:_onPositionReceived(data)
	end)

	-- Clean up buffers when players leave
	Players.PlayerRemoving:Connect(function(player)
		self._buffers[player.UserId] = nil
	end)
end

function InterpolationController.Start(self: InterpolationController)
	if not self._enabled then
		return
	end

	local localPlayer = Players.LocalPlayer
	local localUserId = localPlayer.UserId

	RunService.RenderStepped:Connect(function(dt)
		self:_interpolateTick(dt, localUserId)
	end)
end

--[[
	Enable or disable interpolation (can be toggled for debugging).
]]
function InterpolationController.SetEnabled(self: InterpolationController, enabled: boolean)
	self._enabled = enabled
end

-- ═══════════════════════════════════════════════════
-- PRIVATE
-- ═══════════════════════════════════════════════════

function InterpolationController._onPositionReceived(self: InterpolationController, data: any)
	local userId = data.UserId :: number?
	local position = data.Position :: Vector3?
	local tick = data.Tick :: number?

	if not userId or not position or not tick then
		return
	end

	-- Don't interpolate self
	if userId == Players.LocalPlayer.UserId then
		return
	end

	if not self._buffers[userId] then
		self._buffers[userId] = {}
	end

	local buffer = self._buffers[userId]
	table.insert(buffer, {
		Tick = tick,
		Position = position,
		Timestamp = os.clock(),
	})

	-- Trim buffer
	while #buffer > self._maxBufferSize do
		table.remove(buffer, 1)
	end
end

function InterpolationController._interpolateTick(self: InterpolationController, dt: number, localUserId: number)
	local now = os.clock()
	local renderDelay = INTERPOLATION_DELAY * Constants.TICK_INTERVAL -- convert ticks to seconds

	for userId, buffer in self._buffers do
		if userId == localUserId then
			continue
		end
		if #buffer < 2 then
			continue
		end

		-- Find the player's character
		local player = Players:GetPlayerByUserId(userId)
		if not player then
			continue
		end
		local character = player.Character
		if not character then
			continue
		end
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end

		-- Find two snapshots that bracket our render time
		local renderTime = now - renderDelay
		local before: PlayerSnapshot? = nil
		local after: PlayerSnapshot? = nil

		for i = #buffer, 1, -1 do
			if buffer[i].Timestamp <= renderTime then
				before = buffer[i]
				if i < #buffer then
					after = buffer[i + 1]
				end
				break
			end
		end

		if not before then
			continue
		end

		local targetPosition: Vector3
		if after then
			-- Interpolate between the two snapshots
			local timeRange = after.Timestamp - before.Timestamp
			if timeRange > 0 then
				local alpha = math.clamp((renderTime - before.Timestamp) / timeRange, 0, 1)
				targetPosition = before.Position:Lerp(after.Position, alpha)
			else
				targetPosition = before.Position
			end
		else
			targetPosition = before.Position
		end

		-- Apply interpolated position (smooth correction)
		local currentPos = root.Position
		local error = (targetPosition - currentPos).Magnitude

		if error > MAX_SNAP_DISTANCE then
			-- Snap: error too large (teleport or major desync)
			root.CFrame = CFrame.new(targetPosition) * (root.CFrame - root.CFrame.Position)
		elseif error > 0.1 then
			-- Smooth lerp toward target
			local lerpAlpha = math.clamp(LERP_SPEED * dt, 0, 1)
			local newPos = currentPos:Lerp(targetPosition, lerpAlpha)
			root.CFrame = CFrame.new(newPos) * (root.CFrame - root.CFrame.Position)
		end
	end
end

return InterpolationController
