--!strict
--[[
	CombatService.luau
	Server-side combat authority. Validates attacks, manages hit detection,
	and broadcasts combat state. Orchestrates CombatEntity instances.
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)
local Signal = Shared.Framework.Signal
local Constants = Shared.Data.Constants
local CombatState = Shared.Enums.CombatState
local HitboxSystem = Shared.Modules.HitboxSystem
local DamageCalculator = Shared.Modules.DamageCalculator
local Validator = Shared.Util.Validator
local RateLimiter = Shared.Util.RateLimiter
local DebugLog = require(ReplicatedStorage.Shared.Util.DebugLog)

local CombatEntity = require(script.Parent.Parent.Components.CombatEntity)
local LatencyTracker = require(script.Parent.Parent.Components.LatencyTracker)
local PositionValidator = require(script.Parent.Parent.Components.PositionValidator)
local PositionHistory = Shared.Modules.PositionHistory
local LagCompensation = Shared.Modules.LagCompensation
local DeltaCompressor = Shared.Modules.DeltaCompressor

local CombatService = {}
CombatService.__index = CombatService

export type CombatService = typeof(setmetatable({} :: {
	_network: any,
	_entities: { [Player]: typeof(CombatEntity.new(nil :: any)) },
	_hitbox: typeof(HitboxSystem.new()),
	_rateLimiter: typeof(RateLimiter.new()),
	_serverTick: number,
	_accumulator: number,
	OnHitConfirmed: typeof(Signal.new()),
}, CombatService))

function CombatService.new(network: any): CombatService
	local self = setmetatable({}, CombatService) :: any
	self._network = network
	self._entities = {}
	self._hitbox = HitboxSystem.new()
	self._rateLimiter = RateLimiter.new()
	self._serverTick = 0
	self._accumulator = 0
	self.OnHitConfirmed = Signal.new()

	-- Phase 3: Networking systems
	self._latencyTracker = LatencyTracker.new(network)
	self._positionValidator = PositionValidator.new()
	self._lagCompensation = LagCompensation.new()
	self._deltaCompressor = DeltaCompressor.new()
	self._positionHistories = {} :: { [Player]: typeof(PositionHistory.new()) }

	return self
end

function CombatService.Init(self: CombatService, _container: any)
	-- Register remotes
	self._network:RegisterEvent("AttackRequest")
	self._network:RegisterEvent("BlockRequest")
	self._network:RegisterEvent("ParryRequest")
	self._network:RegisterEvent("DodgeRequest")
	self._network:RegisterEvent("UltimateRequest")
	self._network:RegisterEvent("HitConfirm")
	self._network:RegisterEvent("StateUpdate")
	self._network:RegisterEvent("CombatStateSync")
	self._network:RegisterUnreliableEvent("PositionSync")
	self._network:RegisterUnreliableEvent("StateDelta")
	self._network:RegisterUnreliableEvent("MovementState")

	-- Set rate limits
	self._rateLimiter:SetLimit("Attack", 10)
	self._rateLimiter:SetLimit("Block", 20)
	self._rateLimiter:SetLimit("Parry", 5)
	self._rateLimiter:SetLimit("Dodge", 8)
	self._rateLimiter:SetLimit("Ultimate", 1)

	-- Register remote handlers
	self._network:OnServerEvent("AttackRequest", function(player: Player, data: any)
		self:_handleAttackRequest(player, data)
	end)

	self._network:OnServerEvent("BlockRequest", function(player: Player, data: any)
		self:_handleBlockRequest(player, data)
	end)

	self._network:OnServerEvent("ParryRequest", function(player: Player, data: any)
		self:_handleParryRequest(player, data)
	end)

	self._network:OnServerEvent("DodgeRequest", function(player: Player, data: any)
		self:_handleDodgeRequest(player, data)
	end)

	self._network:OnServerEvent("UltimateRequest", function(player: Player, data: any)
		self:_handleUltimateRequest(player, data)
	end)

	-- Phase 3: Initialize networking subsystems
	self._latencyTracker:Init()
	self._positionValidator:SetOnViolation(function(player: Player, distance: number, maxAllowed: number)
		DebugLog.Warn("AntiCheat", `{player.Name} speed violation: moved {string.format("%.1f", distance)} studs (max {string.format("%.1f", maxAllowed)})`)
	end)
	self._positionValidator:SetOnFlag(function(player: Player, totalViolations: number)
		DebugLog.Warn("AntiCheat", `{player.Name} FLAGGED for speed hacking ({totalViolations} violations)`)
	end)

	-- Player lifecycle
	Players.PlayerAdded:Connect(function(player)
		self:_createEntity(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_removeEntity(player)
		self._rateLimiter:RemovePlayer(player)
	end)

	-- Handle players already in game
	for _, player in Players:GetPlayers() do
		self:_createEntity(player)
	end
end

function CombatService.Start(self: CombatService)
	-- Fixed tick combat simulation loop
	RunService.Heartbeat:Connect(function(dt)
		self._accumulator += dt

		while self._accumulator >= Constants.TICK_INTERVAL do
			self._accumulator -= Constants.TICK_INTERVAL
			self._serverTick += 1
			self:_simulationTick()
		end
	end)
end

--[[
	Get a player's combat entity.
]]
function CombatService.GetEntity(self: CombatService, player: Player): typeof(CombatEntity.new(nil :: any))?
	return self._entities[player]
end

--[[
	Get current server tick.
]]
function CombatService.GetServerTick(self: CombatService): number
	return self._serverTick
end

-- ═══════════════════════════════════════════════════
-- SIMULATION
-- ═══════════════════════════════════════════════════

function CombatService._simulationTick(self: CombatService)
	local dt = Constants.TICK_INTERVAL

	-- Update hitbox system tick
	self._hitbox:SetTick(self._serverTick)

	-- Tick latency tracker
	self._latencyTracker:Tick()

	-- Tick all entities
	for player, entity in self._entities do
		entity.Tick(entity, dt)

		-- Update position from character
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local pos = root.Position
				entity.Position = pos
				entity.Rotation = root.CFrame

				-- Record position history for lag compensation
				local history = self._positionHistories[player]
				if history then
					history:Record(
						self._serverTick,
						pos,
						root.CFrame,
						entity.StateMachine:GetState(),
						entity.StateMachine:HasIFrames()
					)
				end

				-- Validate position (anti-speed/teleport)
				-- Skip validation briefly after a dodge action (displacement is legitimate)
				local lastDodgeTick = entity._lastDodgeTick or 0
				local ticksSinceDodge = self._serverTick - lastDodgeTick
				if ticksSinceDodge < 30 then -- ~0.5 seconds grace after dodge
					-- Exempt: recently dodged, high velocity is expected
					self._positionValidator:ResetViolations(player, pos)
				else
					local entityState = entity.StateMachine:GetState()
					local actionStates = {
						Rolling = true,
						Dashing = true,
						Backstepping = true,
						Sliding = true,
						Launched = true,
						WallBounce = true,
						GroundBounce = true,
						Ragdoll = true,
					}
					local maxSpeed = if actionStates[entityState]
						then Constants.BASE_SPRINT_SPEED * 4
						else Constants.BASE_SPRINT_SPEED
					self._positionValidator:Validate(player, pos, dt, maxSpeed)
				end
			end
		end

		-- Run hit detection during active frames
		if entity.FrameData:IsHitboxActive() then
			self:_runHitDetection(player, entity)
		end
	end

	-- Broadcast state with delta compression
	self:_broadcastState()

	-- Broadcast positions for client interpolation (20Hz = every 3rd tick)
	if self._serverTick % 3 == 0 then
		self:_broadcastPositions()
	end

	-- Prune hit history periodically
	if self._serverTick % 60 == 0 then
		self._hitbox:PruneHistory(120)
	end
end

function CombatService._runHitDetection(self: CombatService, attacker: Player, attackerEntity: any)
	-- Get attacker latency for rewind calculation
	local attackerLatency = self._latencyTracker:GetLatency(attacker)
	local rewindTick = self._lagCompensation:CalculateRewindTick(self._serverTick, attackerLatency)

	local hitboxSize = Vector3.new(5, 4, 6) -- default (overridden by weapon data in Phase 5)
	local hitboxOffset = Vector3.new(0, 0, -3) -- forward offset

	for targetPlayer, targetEntity in self._entities do
		if targetPlayer == attacker then
			continue
		end
		if not targetEntity.IsAlive then
			continue
		end

		-- Skip if already hit this swing
		local hitKey = `{attacker.UserId}_{targetPlayer.UserId}_{self._serverTick}`
		if self._hitbox._hitHistory[hitKey] then
			continue
		end

		-- Use lag compensation: check against target's historical position
		local targetHistory = self._positionHistories[targetPlayer]
		if not targetHistory then
			continue
		end

		local targetSize = Vector3.new(4, 5, 4) -- approximate character bounds
		local result = self._lagCompensation:ValidateHit(
			attackerEntity.Rotation,
			hitboxSize,
			hitboxOffset,
			targetHistory,
			rewindTick,
			targetSize
		)

		if result.Hit and not result.WasInvulnerable then
			-- Determine hurtbox zone from hit point
			local hitPosition = result.RewindPosition or targetEntity.Position
			local zone = "Body"
			if result.RewindPosition then
				local relY = (attackerEntity.Position.Y - result.RewindPosition.Y) / targetSize.Y + 0.5
				if relY >= 0.75 then
					zone = "Head"
				elseif relY < 0.35 then
					zone = "Legs"
				end
			end

			-- Record hit to prevent double-hit
			self._hitbox._hitHistory[hitKey] = self._serverTick

			self:_processHit(attacker, attackerEntity, {
				TargetId = targetPlayer.UserId,
				HitPosition = hitPosition,
				HurtboxZone = zone,
				Distance = (attackerEntity.Position - hitPosition).Magnitude,
			})
		end
	end
end

function CombatService._processHit(self: CombatService, attacker: Player, attackerEntity: any, hit: any)
	-- Find target entity
	local targetPlayer: Player? = nil
	local targetEntity: any = nil

	for player, entity in self._entities do
		if player.UserId == hit.TargetId then
			targetPlayer = player
			targetEntity = entity
			break
		end
	end

	if not targetPlayer or not targetEntity then
		return
	end

	-- Check if target is blocking
	local isBlocked = targetEntity.StateMachine:GetState() == CombatState.Blocking

	-- Check if target is in parry window
	local isParried = targetEntity.StateMachine:GetState() == CombatState.Parrying
		and targetEntity.StateMachine:GetStateFrame() <= Constants.PARRY_WINDOW_FRAMES

	if isParried then
		-- Parry success!
		targetEntity.StateMachine:ForceState(CombatState.ParrySuccess)
		attackerEntity:OnParried()

		-- Grant ult meter to defender
		targetEntity:AddUltimateMeter(Constants.ULTIMATE_GAIN_PER_PARRY)

		DebugLog.Log("Combat", `PARRY! {targetPlayer.Name} parried {attacker.Name}'s attack`)

		-- Notify clients
		self._network:FireAllClients("HitConfirm", {
			AttackerId = attacker.UserId,
			TargetId = hit.TargetId,
			Damage = 0,
			HitType = "Parry",
			Position = hit.HitPosition,
			Tick = self._serverTick,
		})
		return
	end

	-- Calculate damage
	local damageResult = DamageCalculator.Calculate({
		BaseDamage = 15, -- TODO: get from weapon/attack data
		ComboHitNumber = attackerEntity.Combo:GetHitCount(),
		IsBlocked = isBlocked,
		HasArmor = targetEntity.StateMachine:HasArmor(),
		HurtboxZone = hit.HurtboxZone,
		IsCritical = false,
		PoiseDamage = 20, -- TODO: get from attack data
		AttackerBuff = 1.0,
		DefenderBuff = 1.0,
	})

	-- Apply damage
	local hitstun = DamageCalculator.CalculateHitstun(18, attackerEntity.Combo:GetHitCount())

	if isBlocked then
		-- Block: chip stamina damage, reduced hitstun
		targetEntity.Stamina:ForceConsume(damageResult.ChipDamage)
		targetEntity:TakeDamage(damageResult.FinalDamage, damageResult.PoiseDamage, math.floor(hitstun * 0.5))

		-- Check guard break
		if targetEntity.Stamina:IsDepleted() then
			targetEntity.StateMachine:ForceState(CombatState.GuardBroken)
			targetEntity.Stamina:ResumeRegen()
		end
	else
		-- Clean hit
		targetEntity:TakeDamage(damageResult.FinalDamage, damageResult.PoiseDamage, hitstun)
	end

	-- Grant ult meter to attacker
	attackerEntity:AddUltimateMeter(DamageCalculator.CalculateUltGain(damageResult.FinalDamage, "Deal"))

	-- Register combo hit
	attackerEntity.Combo:RegisterHit()

	local targetName = targetPlayer and targetPlayer.Name or "Unknown"
	if isBlocked then
		DebugLog.Log("Combat", `HIT (BLOCKED): {attacker.Name} → {targetName} | Chip: {damageResult.ChipDamage} | Target Stamina: {math.floor(targetEntity.Stamina:GetCurrent())}`)
	else
		DebugLog.Log("Combat", `HIT: {attacker.Name} → {targetName} | Damage: {damageResult.FinalDamage} | Zone: {hit.HurtboxZone} | Target HP: {targetEntity.HP}`)
	end

	-- Notify clients
	self._network:FireAllClients("HitConfirm", {
		AttackerId = attacker.UserId,
		TargetId = hit.TargetId,
		Damage = damageResult.FinalDamage,
		HitType = if isBlocked then "Blocked" else "Hit",
		Position = hit.HitPosition,
		Tick = self._serverTick,
	})

	self.OnHitConfirmed:Fire(attacker, targetPlayer, damageResult)
end

function CombatService._broadcastState(self: CombatService)
	local isFullSync = (self._serverTick % Constants.TICK_RATE == 0) -- full sync every second

	for player, entity in self._entities do
		local snapshot = entity:GetSnapshot()
		snapshot.Tick = self._serverTick

		if isFullSync then
			-- Reliable full state sync (once per second for recovery from dropped packets)
			self._deltaCompressor:InvalidatePlayer(player.UserId)
			self._network:FireClient("StateUpdate", player, snapshot)
		else
			-- Unreliable delta-compressed update (60Hz, dropped packets acceptable)
			local delta = self._deltaCompressor:Compress(player.UserId, snapshot)
			if delta then
				self._network:FireClientUnreliable("StateDelta", player, delta)
			end
		end
	end
end

function CombatService._broadcastPositions(self: CombatService)
	-- Send all player positions to all other players (for client interpolation)
	-- Uses unreliable remote — dropped packets are fine, next update arrives in 50ms
	for player, entity in self._entities do
		local posData = {
			UserId = player.UserId,
			Position = entity.Position,
			Tick = self._serverTick,
		}
		-- Send to all OTHER players
		for otherPlayer in self._entities do
			if otherPlayer ~= player then
				self._network:FireClientUnreliable("PositionSync", otherPlayer, posData)
			end
		end
	end
end

-- ═══════════════════════════════════════════════════
-- REQUEST HANDLERS
-- ═══════════════════════════════════════════════════

function CombatService._handleAttackRequest(self: CombatService, player: Player, data: any)
	-- Rate limit
	if not self._rateLimiter:Check(player, "Attack") then
		return
	end

	-- Validate payload
	if not Validator.IsTable(data) then
		return
	end
	if not Validator.HasField(data, "AttackType", "string") then
		return
	end
	if not Validator.HasField(data, "SequenceId", "number") then
		return
	end

	local entity = self._entities[player]
	if not entity or not entity.IsAlive then
		return
	end

	-- Default frame data (will be overridden by weapon system in Phase 5)
	local frameData = {
		Startup = 6,
		Active = 4,
		Recovery = 12,
		CancelWindow = { 8, 9, 10 }, -- frames 8-10 of recovery allow cancel
	}

	local success: boolean
	if data.AttackType == "Heavy" then
		frameData = {
			Startup = 14,
			Active = 6,
			Recovery = 22,
			CancelWindow = nil,
		}
		success = entity:TryHeavyAttack(frameData)
	else
		success = entity:TryLightAttack(frameData)
	end

	if success then
		entity.LastProcessedSequence = data.SequenceId
		-- Register with combo system
		entity.Combo:InputAttack(data.AttackType)
		-- Clear hit history for new swing
		self._hitbox:ClearHitHistory(player.UserId)
		DebugLog.Log("Combat", `{player.Name} attack accepted: {data.AttackType} | Stamina: {math.floor(entity.Stamina:GetCurrent())}`)
	else
		DebugLog.Log("Combat", `{player.Name} attack REJECTED: {data.AttackType} | State: {entity.StateMachine:GetState()}`)
	end
end

function CombatService._handleBlockRequest(self: CombatService, player: Player, data: any)
	if not self._rateLimiter:Check(player, "Block") then
		return
	end

	if not Validator.IsTable(data) then
		return
	end
	if not Validator.HasField(data, "Active", "boolean") then
		return
	end

	local entity = self._entities[player]
	if not entity or not entity.IsAlive then
		return
	end

	if data.Active then
		entity:TryBlock()
		DebugLog.Log("Combat", `{player.Name} BLOCK START | Stamina: {math.floor(entity.Stamina:GetCurrent())}`)
	else
		entity:StopBlock()
		DebugLog.Log("Combat", `{player.Name} BLOCK END`)
	end

	if data.SequenceId then
		entity.LastProcessedSequence = data.SequenceId
	end
end

function CombatService._handleParryRequest(self: CombatService, player: Player, data: any)
	if not self._rateLimiter:Check(player, "Parry") then
		return
	end

	local entity = self._entities[player]
	if not entity or not entity.IsAlive then
		return
	end

	local success = entity:TryParry()
	DebugLog.Log("Combat", `{player.Name} PARRY attempt: {if success then "ACCEPTED" else "REJECTED"} | State: {entity.StateMachine:GetState()}`)

	if data and typeof(data) == "table" and data.SequenceId then
		entity.LastProcessedSequence = data.SequenceId
	end
end

function CombatService._handleDodgeRequest(self: CombatService, player: Player, data: any)
	if not self._rateLimiter:Check(player, "Dodge") then
		return
	end

	if not Validator.IsTable(data) then
		return
	end
	if not Validator.HasField(data, "DodgeType", "string") then
		return
	end

	local entity = self._entities[player]
	if not entity or not entity.IsAlive then
		return
	end

	local dodgeType = data.DodgeType
	local success = false

	if dodgeType == "Roll" then
		success = entity:TryRoll()
	elseif dodgeType == "Dash" then
		success = entity:TryDash()
	elseif dodgeType == "Backstep" then
		success = entity:TryBackstep()
	end

	if success then
		entity._lastDodgeTick = self._serverTick
	end

	DebugLog.Log("Combat", `{player.Name} DODGE ({dodgeType}): {if success then "ACCEPTED" else "REJECTED"} | Stamina: {math.floor(entity.Stamina:GetCurrent())}`)

	if data.SequenceId then
		entity.LastProcessedSequence = data.SequenceId
	end
end

function CombatService._handleUltimateRequest(self: CombatService, player: Player, _data: any)
	if not self._rateLimiter:Check(player, "Ultimate") then
		return
	end

	local entity = self._entities[player]
	if not entity or not entity.IsAlive then
		return
	end

	local success = entity:TryUltimate()
	DebugLog.Log("Combat", `{player.Name} ULTIMATE: {if success then "ACTIVATED" else "REJECTED (meter: " .. math.floor(entity.UltimateMeter) .. ")"}`)

	if _data and typeof(_data) == "table" and _data.SequenceId then
		entity.LastProcessedSequence = _data.SequenceId
	end
end

-- ═══════════════════════════════════════════════════
-- ENTITY MANAGEMENT
-- ═══════════════════════════════════════════════════

function CombatService._createEntity(self: CombatService, player: Player)
	if self._entities[player] then
		return
	end

	local entity = CombatEntity.new(player)
	self._entities[player] = entity

	-- Phase 3: Create position history buffer
	self._positionHistories[player] = PositionHistory.new()

	-- Phase 3: Register with position validator
	local char = player.Character
	local initialPos = if char and char:FindFirstChild("HumanoidRootPart")
		then (char:FindFirstChild("HumanoidRootPart") :: BasePart).Position
		else Vector3.zero
	self._positionValidator:AddPlayer(player, initialPos)

	-- Re-register on respawn
	player.CharacterAdded:Connect(function(newChar)
		local root = newChar:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if root then
			self._positionValidator:ResetViolations(player, root.Position)
		end
	end)

	entity.OnDeath:Connect(function()
		-- Death handling (Phase 13 match system)
		self._deltaCompressor:InvalidatePlayer(player.UserId)
	end)
end

function CombatService._removeEntity(self: CombatService, player: Player)
	local entity = self._entities[player]
	if entity then
		entity:Destroy()
		self._entities[player] = nil
	end

	-- Phase 3: Clean up networking state
	self._positionHistories[player] = nil
	self._positionValidator:RemovePlayer(player)
	self._deltaCompressor:RemovePlayer(player.UserId)
end

return CombatService
