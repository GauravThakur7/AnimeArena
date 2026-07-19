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

local CombatEntity = require(script.Parent.Parent.Components.CombatEntity)

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

	-- Tick all entities
	for player, entity in self._entities do
		entity.Tick(entity, dt)

		-- Update position from character
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				entity.Position = root.Position
				entity.Rotation = root.CFrame
			end
		end

		-- Run hit detection during active frames
		if entity.FrameData:IsHitboxActive() then
			self:_runHitDetection(player, entity)
		end
	end

	-- Broadcast state every tick
	self:_broadcastState()

	-- Prune hit history periodically
	if self._serverTick % 60 == 0 then
		self._hitbox:PruneHistory(120)
	end
end

function CombatService._runHitDetection(self: CombatService, attacker: Player, attackerEntity: any)
	-- Build target hurtbox data
	local targets = {}
	for targetPlayer, targetEntity in self._entities do
		if targetPlayer == attacker then
			continue
		end
		if not targetEntity.IsAlive then
			continue
		end

		local char = targetPlayer.Character
		if not char then
			continue
		end
		local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then
			continue
		end

		table.insert(targets, {
			PlayerId = targetPlayer.UserId,
			Position = root.Position,
			Size = Vector3.new(4, 5, 4), -- approximate character bounds
			Zone = "Body",
			IsInvulnerable = not targetEntity.StateMachine:IsVulnerable(),
		})
	end

	-- Check hitbox
	local hitResults = self._hitbox:CheckHit({
		Origin = attackerEntity.Rotation,
		Size = Vector3.new(5, 4, 6), -- default hitbox size (overridden by weapon data)
		Offset = Vector3.new(0, 0, -3), -- forward offset
		OwnerId = attacker.UserId,
	}, targets)

	-- Process hits
	for _, hit in hitResults do
		self:_processHit(attacker, attackerEntity, hit)
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
	for player, entity in self._entities do
		local snapshot = entity:GetSnapshot()
		snapshot.Tick = self._serverTick
		self._network:FireClient("StateUpdate", player, snapshot)
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
	else
		entity:StopBlock()
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

	entity:TryParry()
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

	if dodgeType == "Roll" then
		entity:TryRoll()
	elseif dodgeType == "Dash" then
		entity:TryDash()
	elseif dodgeType == "Backstep" then
		entity:TryBackstep()
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

	entity:TryUltimate()
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

	entity.OnDeath:Connect(function()
		-- Death handling (Phase 13 match system)
	end)
end

function CombatService._removeEntity(self: CombatService, player: Player)
	local entity = self._entities[player]
	if entity then
		entity:Destroy()
		self._entities[player] = nil
	end
end

return CombatService
