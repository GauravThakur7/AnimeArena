--!strict
--[[
	GameMode.luau
	All supported game modes.
]]

local GameMode = {
	Duel = "Duel", -- 1v1
	Doubles = "Doubles", -- 2v2
	Triples = "Triples", -- 3v3
	FFA = "FFA", -- Free for all
	Tournament = "Tournament",
	Ranked = "Ranked",
	Training = "Training",
	BossRush = "BossRush",
	Survival = "Survival",
	Custom = "Custom",
}

export type GameMode = typeof(GameMode[any])

return table.freeze(GameMode)
