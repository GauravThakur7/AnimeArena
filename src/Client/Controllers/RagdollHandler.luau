--!strict
--[[
	RagdollHandler.luau
	Handles ragdoll physics when a character enters the Dead or Ragdoll state.
	
	Converts the character's joints to physics-based (BallSocketConstraints)
	allowing the body to crumple naturally. Reverts on respawn.
	
	Usage:
		local ragdoll = RagdollHandler.new()
		ragdoll:SetCharacter(character)
		ragdoll:Enable(knockbackDirection) -- activates ragdoll
		ragdoll:Disable() -- reverts to animated
]]

local RagdollHandler = {}
RagdollHandler.__index = RagdollHandler

export type RagdollHandler = typeof(setmetatable({} :: {
	_character: Model?,
	_humanoid: Humanoid?,
	_active: boolean,
	_originalMotors: { { Motor: Motor6D, Parent: Instance } },
	_constraints: { BallSocketConstraint },
}, RagdollHandler))

function RagdollHandler.new(): RagdollHandler
	local self = setmetatable({}, RagdollHandler) :: any
	self._character = nil
	self._humanoid = nil
	self._active = false
	self._originalMotors = {}
	self._constraints = {}
	return self
end

--[[
	Set the character model reference.
]]
function RagdollHandler.SetCharacter(self: RagdollHandler, character: Model)
	self._character = character
	self._humanoid = character:FindFirstChildOfClass("Humanoid")
end

--[[
	Enable ragdoll physics. Disables Humanoid state, converts joints.
	@param knockbackDirection — Optional initial force direction
]]
function RagdollHandler.Enable(self: RagdollHandler, knockbackDirection: Vector3?)
	if self._active or not self._character or not self._humanoid then
		return
	end

	self._active = true

	-- Disable humanoid auto-rotation and movement
	self._humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	self._humanoid.AutoRotate = false

	-- Store and disable all Motor6D joints
	self._originalMotors = {}
	for _, descendant in self._character:GetDescendants() do
		if descendant:IsA("Motor6D") then
			local motor = descendant :: Motor6D
			table.insert(self._originalMotors, {
				Motor = motor,
				Parent = motor.Parent :: Instance,
			})

			-- Create a BallSocketConstraint to replace the motor
			local attachment0 = Instance.new("Attachment")
			attachment0.Name = "RagdollAtt0"
			attachment0.CFrame = motor.C0
			attachment0.Parent = motor.Part0

			local attachment1 = Instance.new("Attachment")
			attachment1.Name = "RagdollAtt1"
			attachment1.CFrame = motor.C1
			attachment1.Parent = motor.Part1

			local constraint = Instance.new("BallSocketConstraint")
			constraint.Name = "RagdollConstraint"
			constraint.Attachment0 = attachment0
			constraint.Attachment1 = attachment1
			constraint.LimitsEnabled = true
			constraint.UpperAngle = 90
			constraint.Parent = motor.Part0

			table.insert(self._constraints, constraint)

			-- Disable the motor
			motor.Enabled = false
		end
	end

	-- Apply knockback impulse
	if knockbackDirection then
		local root = self._character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root:ApplyImpulse(knockbackDirection * root.AssemblyMass * 30)
		end
	end
end

--[[
	Disable ragdoll, restore animated state.
]]
function RagdollHandler.Disable(self: RagdollHandler)
	if not self._active or not self._character or not self._humanoid then
		return
	end

	self._active = false

	-- Remove constraints and their attachments
	for _, constraint in self._constraints do
		if constraint.Attachment0 then
			constraint.Attachment0:Destroy()
		end
		if constraint.Attachment1 then
			constraint.Attachment1:Destroy()
		end
		constraint:Destroy()
	end
	table.clear(self._constraints)

	-- Re-enable motors
	for _, data in self._originalMotors do
		data.Motor.Enabled = true
	end
	table.clear(self._originalMotors)

	-- Restore humanoid state
	self._humanoid.AutoRotate = true
	self._humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
end

--[[
	Check if ragdoll is active.
]]
function RagdollHandler.IsActive(self: RagdollHandler): boolean
	return self._active
end

--[[
	Destroy and clean up.
]]
function RagdollHandler.Destroy(self: RagdollHandler)
	if self._active then
		self:Disable()
	end
end

return RagdollHandler
