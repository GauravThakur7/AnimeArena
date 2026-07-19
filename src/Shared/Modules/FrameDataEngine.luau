--!strict
--[[
	FrameDataEngine.luau
	Processes frame-by-frame timing for attacks.
	Tracks startup → active → recovery phases.
	Determines when hitbox should be active, when cancels are allowed,
	and when invulnerability/armor frames are active.
	
	Usage:
		local engine = FrameDataEngine.new()
		engine:StartAttack(frameData)
		engine:Tick() -- call every game tick
		engine:GetPhase() -- "Startup" | "Active" | "Recovery" | "None"
		engine:IsHitboxActive() -- true during Active phase
		engine:IsComplete() -- true when recovery ends
]]

export type FrameDataInput = {
	Startup: number,
	Active: number,
	Recovery: number,
	CancelWindow: { number }?, -- frames during recovery where cancel is allowed
	IFrames: { number }?, -- frame numbers with invulnerability
	ArmorFrames: { number }?, -- frame numbers with super armor
}

export type Phase = "None" | "Startup" | "Active" | "Recovery" | "Complete"

local FrameDataEngine = {}
FrameDataEngine.__index = FrameDataEngine

export type FrameDataEngine = typeof(setmetatable({} :: {
	_frameData: FrameDataInput?,
	_currentFrame: number,
	_totalFrames: number,
	_phase: Phase,
	_active: boolean,
}, FrameDataEngine))

function FrameDataEngine.new(): FrameDataEngine
	local self = setmetatable({}, FrameDataEngine) :: any
	self._frameData = nil
	self._currentFrame = 0
	self._totalFrames = 0
	self._phase = "None" :: Phase
	self._active = false
	return self
end

--[[
	Begin processing an attack's frame data.
]]
function FrameDataEngine.StartAttack(self: FrameDataEngine, frameData: FrameDataInput)
	self._frameData = frameData
	self._currentFrame = 0
	self._totalFrames = frameData.Startup + frameData.Active + frameData.Recovery
	self._phase = "Startup"
	self._active = true
end

--[[
	Advance by one tick. Call this every game tick while an attack is active.
]]
function FrameDataEngine.Tick(self: FrameDataEngine)
	if not self._active or not self._frameData then
		return
	end

	self._currentFrame += 1

	local fd = self._frameData
	local frame = self._currentFrame

	if frame <= fd.Startup then
		self._phase = "Startup"
	elseif frame <= fd.Startup + fd.Active then
		self._phase = "Active"
	elseif frame <= self._totalFrames then
		self._phase = "Recovery"
	else
		self._phase = "Complete"
		self._active = false
	end
end

--[[
	Get the current phase of the attack.
]]
function FrameDataEngine.GetPhase(self: FrameDataEngine): Phase
	return self._phase
end

--[[
	Get the current frame number (1-indexed from attack start).
]]
function FrameDataEngine.GetCurrentFrame(self: FrameDataEngine): number
	return self._currentFrame
end

--[[
	Get total frames for the current attack.
]]
function FrameDataEngine.GetTotalFrames(self: FrameDataEngine): number
	return self._totalFrames
end

--[[
	Returns true if hitbox should be active (during Active phase).
]]
function FrameDataEngine.IsHitboxActive(self: FrameDataEngine): boolean
	return self._phase == "Active"
end

--[[
	Returns true if the attack has completed all phases.
]]
function FrameDataEngine.IsComplete(self: FrameDataEngine): boolean
	return self._phase == "Complete" or not self._active
end

--[[
	Returns true if currently in a cancel window.
	Cancel windows are frame numbers during Recovery where the player
	can chain into the next attack.
]]
function FrameDataEngine.InCancelWindow(self: FrameDataEngine): boolean
	if not self._frameData or not self._frameData.CancelWindow then
		return false
	end
	if self._phase ~= "Recovery" then
		return false
	end

	-- Calculate frame within recovery
	local fd = self._frameData
	local recoveryFrame = self._currentFrame - (fd.Startup + fd.Active)
	return table.find(fd.CancelWindow, recoveryFrame) ~= nil
end

--[[
	Returns true if the current frame has invulnerability.
]]
function FrameDataEngine.HasIFrames(self: FrameDataEngine): boolean
	if not self._frameData or not self._frameData.IFrames then
		return false
	end
	return table.find(self._frameData.IFrames, self._currentFrame) ~= nil
end

--[[
	Returns true if the current frame has super armor.
]]
function FrameDataEngine.HasArmorFrames(self: FrameDataEngine): boolean
	if not self._frameData or not self._frameData.ArmorFrames then
		return false
	end
	return table.find(self._frameData.ArmorFrames, self._currentFrame) ~= nil
end

--[[
	Returns frames remaining in current phase.
]]
function FrameDataEngine.GetFramesRemaining(self: FrameDataEngine): number
	if not self._frameData then
		return 0
	end

	local fd = self._frameData
	local frame = self._currentFrame

	if self._phase == "Startup" then
		return fd.Startup - frame
	elseif self._phase == "Active" then
		return (fd.Startup + fd.Active) - frame
	elseif self._phase == "Recovery" then
		return self._totalFrames - frame
	end

	return 0
end

--[[
	Reset the engine (cancel current attack).
]]
function FrameDataEngine.Reset(self: FrameDataEngine)
	self._frameData = nil
	self._currentFrame = 0
	self._totalFrames = 0
	self._phase = "None"
	self._active = false
end

--[[
	Returns true if an attack is currently being processed.
]]
function FrameDataEngine.IsActive(self: FrameDataEngine): boolean
	return self._active
end

return FrameDataEngine
