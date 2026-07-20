--!strict
--[[
	AnimationPlayer.luau
	Handles actual Roblox Animator interaction.
	Loads animation tracks, plays/stops them with crossfading, manages priority layering.
	
	This is the only module that touches Roblox's Animation/Animator API directly.
	All other modules work with string keys and logical state — this bridges to reality.
	
	Usage:
		local player = AnimationPlayer.new()
		player:SetAnimator(humanoid)
		player:LoadSet(animationSet) -- from AnimationSets data
		player:Play("Light1", fadeTime, speed, priority)
		player:Stop(fadeTime)
]]

local AnimationPlayer = {}
AnimationPlayer.__index = AnimationPlayer

export type AnimationPlayer = typeof(setmetatable({} :: {
	_animator: Animator?,
	_loadedTracks: { [string]: AnimationTrack },
	_currentTrack: AnimationTrack?,
	_currentKey: string,
	_animationSet: { [string]: string }, -- key → assetId
}, AnimationPlayer))

function AnimationPlayer.new(): AnimationPlayer
	local self = setmetatable({}, AnimationPlayer) :: any
	self._animator = nil
	self._loadedTracks = {}
	self._currentTrack = nil
	self._currentKey = ""
	self._animationSet = {}
	return self
end

--[[
	Set the Animator instance from a Humanoid.
]]
function AnimationPlayer.SetAnimator(self: AnimationPlayer, humanoid: Humanoid)
	self._animator = humanoid:FindFirstChildOfClass("Animator")
	if not self._animator then
		self._animator = Instance.new("Animator")
		self._animator.Parent = humanoid
	end

	-- Clear loaded tracks (character changed)
	self:_clearTracks()
end

--[[
	Load an animation set (key → assetId mapping).
	Pre-loads all tracks for instant playback.
]]
function AnimationPlayer.LoadSet(self: AnimationPlayer, animSet: { [string]: string })
	self:_clearTracks()
	self._animationSet = animSet

	if not self._animator then
		return
	end

	-- Pre-load all non-empty animation IDs
	for key, assetId in animSet do
		if assetId and assetId ~= "" then
			self:_loadTrack(key, assetId)
		end
	end
end

--[[
	Play an animation by key with crossfade.
	@param key — Animation key from the set
	@param fadeTime — Crossfade duration (seconds)
	@param speed — Playback speed multiplier
	@param priority — Roblox AnimationPriority
	@param looped — Whether the animation loops
]]
function AnimationPlayer.Play(
	self: AnimationPlayer,
	key: string,
	fadeTime: number?,
	speed: number?,
	priority: Enum.AnimationPriority?,
	looped: boolean?
)
	if key == self._currentKey then
		return -- Already playing this animation
	end

	-- Stop current track
	if self._currentTrack then
		self._currentTrack:Stop(fadeTime or 0.1)
	end

	-- Get or load the track
	local track = self._loadedTracks[key]
	if not track then
		local assetId = self._animationSet[key]
		if assetId and assetId ~= "" then
			track = self:_loadTrack(key, assetId)
		end
	end

	if not track then
		-- No animation available for this key (placeholder)
		self._currentKey = key
		self._currentTrack = nil
		return
	end

	-- Configure track
	track.Priority = priority or Enum.AnimationPriority.Action
	track.Looped = looped or false

	-- Play with fade
	track:Play(fadeTime or 0.1)

	-- Adjust speed
	if speed and speed ~= 1.0 then
		track:AdjustSpeed(speed)
	end

	self._currentTrack = track
	self._currentKey = key
end

--[[
	Stop the current animation.
]]
function AnimationPlayer.Stop(self: AnimationPlayer, fadeTime: number?)
	if self._currentTrack then
		self._currentTrack:Stop(fadeTime or 0.1)
		self._currentTrack = nil
		self._currentKey = ""
	end
end

--[[
	Stop all playing tracks (hard reset).
]]
function AnimationPlayer.StopAll(self: AnimationPlayer)
	for _, track in self._loadedTracks do
		if track.IsPlaying then
			track:Stop(0)
		end
	end
	self._currentTrack = nil
	self._currentKey = ""
end

--[[
	Get the currently playing animation key.
]]
function AnimationPlayer.GetCurrentKey(self: AnimationPlayer): string
	return self._currentKey
end

--[[
	Check if any animation is currently playing.
]]
function AnimationPlayer.IsPlaying(self: AnimationPlayer): boolean
	return self._currentTrack ~= nil and self._currentTrack.IsPlaying
end

--[[
	Get the current track's time position (for sync purposes).
]]
function AnimationPlayer.GetTimePosition(self: AnimationPlayer): number
	if self._currentTrack then
		return self._currentTrack.TimePosition
	end
	return 0
end

--[[
	Get the current track's length.
]]
function AnimationPlayer.GetTrackLength(self: AnimationPlayer): number
	if self._currentTrack then
		return self._currentTrack.Length
	end
	return 0
end

--[[
	Adjust speed of the current playing track.
]]
function AnimationPlayer.AdjustSpeed(self: AnimationPlayer, speed: number)
	if self._currentTrack then
		self._currentTrack:AdjustSpeed(speed)
	end
end

-- ═══════════════════════════════════════════════════
-- PRIVATE
-- ═══════════════════════════════════════════════════

function AnimationPlayer._loadTrack(self: AnimationPlayer, key: string, assetId: string): AnimationTrack?
	if not self._animator then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = assetId

	local success, track = pcall(function()
		return self._animator:LoadAnimation(animation)
	end)

	if success and track then
		self._loadedTracks[key] = track
		return track
	end

	return nil
end

function AnimationPlayer._clearTracks(self: AnimationPlayer)
	for _, track in self._loadedTracks do
		track:Stop(0)
		track:Destroy()
	end
	table.clear(self._loadedTracks)
	self._currentTrack = nil
	self._currentKey = ""
end

--[[
	Destroy and clean up all tracks.
]]
function AnimationPlayer.Destroy(self: AnimationPlayer)
	self:_clearTracks()
	self._animator = nil
end

return AnimationPlayer
