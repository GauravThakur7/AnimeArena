--!strict
--[[
	Client/init.client.luau
	Client bootstrap. Initializes the DI container, registers all controllers, then starts them.
	
	Lifecycle:
	1. Wait for Shared to replicate
	2. Create Network instance (client mode)
	3. Create Container
	4. Register all controllers
	5. InitAll (controllers set up listeners)
	6. StartAll (controllers begin their loops)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

local Container = Shared.Framework.Container
local Network = Shared.Framework.Network

-- Controllers
local InputController = require(script.Controllers.InputController)
local CombatController = require(script.Controllers.CombatController)
local MovementController = require(script.Controllers.MovementController)
local CameraController = require(script.Controllers.CameraController)
local AnimationController = require(script.Controllers.AnimationController)
local VFXController = require(script.Controllers.VFXController)
local AudioController = require(script.Controllers.AudioController)

-- ═══════════════════════════════════════════════════
-- BOOTSTRAP
-- ═══════════════════════════════════════════════════

print("[AnimeArena Client] Initializing...")

-- Create shared network instance (client mode)
local network = Network.new()

-- Create DI container
local container = Container.new()

-- Register core dependencies
container:Register("Network", network)

-- Register controllers
container:Register("InputController", InputController.new())
container:Register("CombatController", CombatController.new(network))
container:Register("MovementController", MovementController.new())
container:Register("CameraController", CameraController.new())
container:Register("AnimationController", AnimationController.new())
container:Register("VFXController", VFXController.new())
container:Register("AudioController", AudioController.new())

-- Initialize all (set up listeners, prepare state)
container:InitAll()

-- Start all (begin loops)
container:StartAll()

print("[AnimeArena Client] All controllers started successfully.")
