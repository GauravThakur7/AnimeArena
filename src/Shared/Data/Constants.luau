--!strict
--[[
	Constants.luau
	Global constants used throughout the project.
	All gameplay-affecting numbers live here for easy tuning.
]]

local Constants = {
	-- Tick rate
	TICK_RATE = 60,
	TICK_INTERVAL = 1 / 60,

	-- Combat
	MAX_HP = 100,
	MAX_STAMINA = 100,
	MAX_POISE = 100,
	STAMINA_REGEN_RATE = 12, -- per second
	STAMINA_REGEN_DELAY = 1.5, -- seconds after last action
	POISE_REGEN_RATE = 25, -- per second
	POISE_REGEN_DELAY = 3.0, -- seconds after last hit
	ULTIMATE_METER_MAX = 100,
	ULTIMATE_GAIN_PER_DAMAGE = 1,
	ULTIMATE_GAIN_PER_HIT_TAKEN = 0.5,
	ULTIMATE_GAIN_PER_PARRY = 10,

	-- Input buffer
	INPUT_BUFFER_FRAMES = 6, -- ~100ms at 60Hz

	-- Damage scaling (combo)
	DAMAGE_SCALING = { 1.0, 0.9, 0.8, 0.7, 0.6 }, -- floors at 60%
	DAMAGE_SCALING_FLOOR = 0.6,
	JUGGLE_LIMIT = 4,

	-- Parry
	PARRY_WINDOW_FRAMES = 6,
	PERFECT_PARRY_FRAMES = 3,
	PARRY_STUN_FRAMES = 30,
	FAILED_PARRY_RECOVERY_FRAMES = 20,

	-- Guard break
	GUARD_BREAK_STUN_FRAMES = 45,

	-- Blocking
	BLOCK_DAMAGE_REDUCTION = 0.8, -- 80% reduction

	-- Movement
	BASE_WALK_SPEED = 12,
	BASE_RUN_SPEED = 20,
	BASE_SPRINT_SPEED = 22,
	DASH_DISTANCE = 12,
	DASH_DURATION = 0.25,
	ROLL_DISTANCE = 10,
	ROLL_DURATION = 0.4,
	ROLL_IFRAMES = 8, -- frames of invulnerability
	BACKSTEP_DISTANCE = 6,
	BACKSTEP_DURATION = 0.3,

	-- Stamina costs
	STAMINA_COST_LIGHT = 8,
	STAMINA_COST_HEAVY = 15,
	STAMINA_COST_DASH = 12,
	STAMINA_COST_ROLL = 15,
	STAMINA_COST_BACKSTEP = 10,
	STAMINA_COST_PARRY = 5,
	STAMINA_COST_SPRINT_PER_SECOND = 2,

	-- Networking
	MAX_REWIND_MS = 200, -- max lag compensation rewind
	MAX_REWIND_TICKS = 12, -- 200ms at 60Hz
	POSITION_HISTORY_DURATION = 1.0, -- seconds of history stored
	STATE_BROADCAST_RATE = 60, -- Hz (every tick)
	FULL_SYNC_RATE = 10, -- Hz (periodic full state)

	-- Anti-cheat
	SPEED_TOLERANCE = 2.5, -- 150% tolerance on movement speed (accounts for physics jitter)
	MAX_REMOTE_DRIFT_SECONDS = 0.5, -- timestamp validity window
	DISCONNECT_TIMEOUT = 5.0, -- seconds before marking disconnected
	RANKED_RECONNECT_WINDOW = 30.0, -- seconds to reconnect in ranked

	-- Match
	READY_CHECK_DURATION = 10,
	COUNTDOWN_DURATION = 3,
	DEFAULT_ROUND_TIME = 180, -- 3 minutes
	DEFAULT_BEST_OF = 3,

	-- Progression
	BASE_XP_PER_MATCH = 50,
	XP_PER_KILL = 25,
	XP_PER_WIN = 100,

	-- UI
	DAMAGE_NUMBER_DURATION = 1.0,
	KILL_FEED_DURATION = 5.0,
	NOTIFICATION_DURATION = 3.0,
}

return table.freeze(Constants)
