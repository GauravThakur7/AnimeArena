--!strict
--[[
	Server/init.server.luau
	Server bootstrap. Initializes the DI container, registers all services, then starts them.
	
	Lifecycle:
	1. Create Network instance
	2. Create Container
	3. Register all services
	4. InitAll (services register remotes, set up connections)
	5. StartAll (services begin their loops)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage.Shared)

local Container = Shared.Framework.Container
local Network = Shared.Framework.Network

-- Services
local CombatService = require(script.Services.CombatService)
local DataService = require(script.Services.DataService)
local MatchmakingService = require(script.Services.MatchmakingService)
local AntiCheatService = require(script.Services.AntiCheatService)
local ArenaService = require(script.Services.ArenaService)
local ProgressionService = require(script.Services.ProgressionService)
local MonetizationService = require(script.Services.MonetizationService)

-- ═══════════════════════════════════════════════════
-- BOOTSTRAP
-- ═══════════════════════════════════════════════════

print("[AnimeArena Server] Initializing...")

-- Create shared network instance
local network = Network.new()

-- Create DI container
local container = Container.new()

-- Register core dependencies
container:Register("Network", network)

-- Register services
container:Register("CombatService", CombatService.new(network))
container:Register("DataService", DataService.new())
container:Register("MatchmakingService", MatchmakingService.new(network))
container:Register("AntiCheatService", AntiCheatService.new())
container:Register("ArenaService", ArenaService.new())
container:Register("ProgressionService", ProgressionService.new(network))
container:Register("MonetizationService", MonetizationService.new(network))

-- Initialize all (register remotes, set up connections)
container:InitAll()

-- Start all (begin loops, activate systems)
container:StartAll()

print("[AnimeArena Server] All services started successfully.")
