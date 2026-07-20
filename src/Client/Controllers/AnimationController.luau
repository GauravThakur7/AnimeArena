--!strict
--[[
	AnimationController.luau
	Bridges CombatController state changes to AnimationPlayer playback.
	
	Listens for combat state transitions, resolves the correct animation key
	via AnimationStateMachine, then plays it via AnimationPlayer with proper
	crossfade timing and priority.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Signal = Shared.Framework.Signal
local AnimStateMachine = Shared.Modules.AnimationStateMachine
local AnimationSets = require(ReplicatedStorage.Shared.Data.AnimationSets)

local AnimationPlayer = require(script.Parent.AnimationPlayer)
local RagdollHandler = require(script.Parent.RagdollHandler)
local RootMotion = require(script.Parent.RootMotion)

local AnimationController = {}
AnimationController.__index = AnimationController

export type AnimationController = typeof(setmetatable({} :: {
	_combatController: any,
	_movementController: any,
	_animPlayer: typeof(AnimationPlayer.new()),
	_animStateMachine: typeof(AnimStateMachine.new()),
	_currentWeaponSet: string,
	_comboPosition: number,
	OnAnimationChanged: typeof(Signal.new()),
}, AnimationController))

function AnimationController.new(): AnimationController
	local self = setmetatable({}, AnimationController) :: any
	self._combatController = nil
	self._movementController = nil
	self._animPlayer = AnimationPlayer.new()
	self._animStateMachine = AnimStateMachine.new()
	self._ragdoll = RagdollHandler.new()
	self._rootMotion = RootMotion.new(nil)
	self._currentWeaponSet = "Katana"
	self._comboPosition = 1
	self._lastHitDirection = nil :: string?
	self.OnAnimationChanged = Signal.new()
	return self
end

function AnimationController.Init(self: AnimationController, container: any)
	self._combatController = container:Resolve("CombatController")
	self._movementController = container:Resolve("MovementController")

	-- Setup character and animator
	local player = Players.LocalPlayer
	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
		if humanoid then
			self._animPlayer:SetAnimator(humanoid)
			self:_loadWeaponSet(self._currentWeaponSet)
		end

		-- Setup ragdoll and root motion for this character
		self._ragdoll:SetCharacter(character)
		local root = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if root then
			self._rootMotion:SetRootPart(root)
		end

		-- Disable ragdoll on respawn (in case it was active from previous life)
		if self._ragdoll:IsActive() then
			self._ragdoll:Disable()
		end
	end

	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)

	-- Listen for combat state changes
	self._combatController.OnStateChanged:Connect(function(oldState: string, newState: string)
		self:_onCombatStateChanged(oldState, newState)
	end)

	-- Listen for hit confirmations (to play hit reaction on self)
	self._combatController.OnHitReceived:Connect(function(data: any)
		self:_onHitReceived(data)
	end)

	-- Listen for character select to switch animation set
	local network = container:Resolve("Network")
	network:OnClientEvent("StateUpdate", function(data: any)
		-- Full state sync includes weapon info if character changed
		-- We detect weapon change by checking if the set differs
	end)

	-- Listen for CharacterSelect confirmation (server echoes back via StateUpdate)
	network:OnClientEvent("CharacterSelect", function(data: any)
		if data and data.WeaponSet then
			self:SetWeaponSet(data.WeaponSet)
		end
	end)
end

function AnimationController.Start(self: AnimationController)
	-- Play idle animation on start
	task.delay(1, function()
		self:_playAnimation("CombatIdle")
	end)

	-- Tick root motion each frame
	local RunService = game:GetService("RunService")
	RunService.RenderStepped:Connect(function(dt)
		if self._rootMotion:IsActive() then
			self._rootMotion:Tick(dt)
		end
	end)
end

--[[
	Set the weapon animation set (called when character/weapon changes).
]]
function AnimationController.SetWeaponSet(self: AnimationController, weaponCategory: string)
	self._currentWeaponSet = weaponCategory
	self:_loadWeaponSet(weaponCategory)
end

--[[
	Set combo position (for correct Light1/Light2/Light3 animation).
]]
function AnimationController.SetComboPosition(self: AnimationController, position: number)
	self._comboPosition = position
end

-- ═══════════════════════════════════════════════════
-- STATE HANDLING
-- ═══════════════════════════════════════════════════

function AnimationController._onCombatStateChanged(self: AnimationController, _oldState: string, newState: string)
	-- Resolve animation key from combat state
	local animKey: string

	-- Use directional hit reaction for stagger
	if newState == "Staggered" and self._lastHitDirection then
		animKey = self._lastHitDirection
		self._lastHitDirection = nil
	else
		animKey = self._animStateMachine:GetAnimationKey(
			newState,
			nil,
			self._comboPosition
		)
	end

	-- Ragdoll on Death or Ragdoll state
	if newState == "Dead" or newState == "Ragdoll" then
		self._animPlayer:StopAll()
		self._ragdoll:Enable(nil) -- knockback direction could be passed from hit data
		return
	end

	-- Disable ragdoll if leaving Dead/Ragdoll (respawn)
	if self._ragdoll:IsActive() and newState == "Idle" then
		self._ragdoll:Disable()
	end

	-- Root motion for attacks (small forward lunge)
	if newState == "Attacking" or newState == "HeavyAttacking" then
		local character = Players.LocalPlayer.Character
		if character then
			local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local lungeDistance = if newState == "HeavyAttacking" then 3.0 else 1.5
				local lungeDuration = if newState == "HeavyAttacking" then 0.2 else 0.1
				self._rootMotion:Enable({
					Direction = root.CFrame.LookVector,
					Distance = lungeDistance,
					Duration = lungeDuration,
					EaseType = "EaseOut",
				})
			end
		end
	end

	-- Cancel root motion on stagger/hit
	if newState == "Staggered" or newState == "Launched" or newState == "GuardBroken" then
		self._rootMotion:Disable()
	end

	self:_playAnimation(animKey)

	-- Track combo position for attacks
	if newState == "Attacking" then
		self._comboPosition += 1
	elseif newState == "Idle" then
		-- Reset combo position after returning to idle (with delay for cancel window)
		task.delay(0.5, function()
			if self._combatController:GetState() == "Idle" then
				self._comboPosition = 1
			end
		end)
	end

	self.OnAnimationChanged:Fire(animKey)
end

function AnimationController._onHitReceived(self: AnimationController, data: any)
	local localPlayer = Players.LocalPlayer
	if data.TargetId == localPlayer.UserId then
		-- Determine hit direction for directional reactions
		local character = localPlayer.Character
		if not character then return end
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return end

		local hitPos = data.Position
		if typeof(hitPos) == "Vector3" then
			local directionKey = self:_resolveHitDirection(root, hitPos)
			-- Play directional hit reaction (system handles via combat state change)
			-- Store direction for when Stagger state triggers the animation
			self._lastHitDirection = directionKey
		end
	end
end

--[[
	Resolve which directional hit animation to use based on hit position relative to character.
]]
function AnimationController._resolveHitDirection(self: AnimationController, root: BasePart, hitPosition: Vector3): string
	local toHit = (hitPosition - root.Position)
	local flatDir = Vector3.new(toHit.X, 0, toHit.Z)
	if flatDir.Magnitude < 0.1 then
		return "Stagger"
	end

	local charForward = root.CFrame.LookVector
	local charRight = root.CFrame.RightVector

	local dot_forward = flatDir.Unit:Dot(charForward)
	local dot_right = flatDir.Unit:Dot(charRight)

	-- Determine quadrant
	if math.abs(dot_forward) > math.abs(dot_right) then
		if dot_forward < 0 then
			return "HitBack" -- hit from behind
		else
			return "Stagger" -- hit from front (default stagger)
		end
	else
		if dot_right > 0 then
			return "HitRight"
		else
			return "HitLeft"
		end
	end
end

-- ═══════════════════════════════════════════════════
-- PLAYBACK
-- ═══════════════════════════════════════════════════

function AnimationController._playAnimation(self: AnimationController, animKey: string)
	local rule = self._animStateMachine:GetRule(animKey)
	local fadeTime = rule.FadeTime
	local priority = self._animStateMachine:GetRobloxPriority(animKey)
	local looped = rule.Looped
	local speed = rule.Speed or 1.0

	self._animPlayer:Play(animKey, fadeTime, speed, priority, looped)
end

function AnimationController._loadWeaponSet(self: AnimationController, weaponCategory: string)
	local animSet = (AnimationSets :: any)[weaponCategory]
	if animSet then
		self._animPlayer:LoadSet(animSet)
	end
end

return AnimationController
