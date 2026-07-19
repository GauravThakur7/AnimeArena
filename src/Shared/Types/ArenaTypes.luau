--!strict
--[[
	ArenaTypes.luau
	Type definitions for the arena/map system.
]]

export type SpawnPoint = {
	Position: Vector3,
	Rotation: number, -- Y-axis rotation in degrees
	Team: number?, -- nil for FFA
}

export type LightingPreset = {
	Ambient: Color3,
	Brightness: number,
	ClockTime: number,
	FogEnd: number,
	FogColor: Color3,
	OutdoorAmbient: Color3,
}

export type ArenaConfig = {
	Id: string,
	Name: string,
	Description: string,

	-- Map data
	AssetId: string?, -- if loaded from asset
	ModelPath: string?, -- path in workspace

	-- Gameplay
	SpawnPoints: { SpawnPoint },
	BoundarySize: Vector3, -- arena boundary box
	BoundaryCenter: Vector3,

	-- Environment
	LightingPreset: LightingPreset,
	AmbientSoundId: string?,
	MusicId: string?,

	-- Metadata
	MinPlayers: number,
	MaxPlayers: number,
	SupportedModes: { string }, -- {"1v1", "2v2", "FFA", etc.}

	-- Future-ready
	HasEnvironmentalHazards: boolean,
	HazardConfig: { [string]: any }?,
}

return nil
