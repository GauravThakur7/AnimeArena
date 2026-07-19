--!strict
--[[
	UITypes.luau
	Type definitions for UI state and components.
]]

export type Screen = "MainMenu" | "CharacterSelect" | "Settings" | "Ranked" | "Shop" | "Inventory" | "InMatch"

export type HUDState = {
	Visible: boolean,
	PlayerHP: number,
	PlayerMaxHP: number,
	PlayerStamina: number,
	PlayerMaxStamina: number,
	UltimateMeter: number,
	ComboCount: number,
	MatchTimer: number,
}

export type Notification = {
	Id: string,
	Type: string, -- "Kill" | "Achievement" | "Reward" | "System"
	Message: string,
	Duration: number,
	Timestamp: number,
}

export type SettingsData = {
	MusicVolume: number,
	SFXVolume: number,
	CameraSensitivity: number,
	UIScale: number,
	ShowDamageNumbers: boolean,
	ScreenShake: boolean,
	BloodEffects: boolean,
	Colorblind: string?,
	ReducedMotion: boolean,
}

return nil
