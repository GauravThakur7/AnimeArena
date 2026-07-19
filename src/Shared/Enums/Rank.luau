--!strict
--[[
	Rank.luau
	Ranked tier definitions.
]]

local Rank = {
	Unranked = "Unranked",
	Bronze = "Bronze",
	Silver = "Silver",
	Gold = "Gold",
	Platinum = "Platinum",
	Diamond = "Diamond",
	Master = "Master",
	Mythic = "Mythic",
}

export type Rank = typeof(Rank[any])

-- MMR thresholds for each rank
local RankThresholds = {
	{ Rank = Rank.Bronze, MinMMR = 0, MaxMMR = 499 },
	{ Rank = Rank.Silver, MinMMR = 500, MaxMMR = 999 },
	{ Rank = Rank.Gold, MinMMR = 1000, MaxMMR = 1499 },
	{ Rank = Rank.Platinum, MinMMR = 1500, MaxMMR = 1999 },
	{ Rank = Rank.Diamond, MinMMR = 2000, MaxMMR = 2499 },
	{ Rank = Rank.Master, MinMMR = 2500, MaxMMR = 2999 },
	{ Rank = Rank.Mythic, MinMMR = 3000, MaxMMR = math.huge },
}

return table.freeze({
	Rank = Rank,
	Thresholds = RankThresholds,
})
