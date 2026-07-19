--!strict
--[[
	Currency.luau
	Currency type identifiers.
]]

local Currency = {
	Coins = "Coins", -- Earned through gameplay
	Premium = "Premium", -- Purchased with Robux
}

export type Currency = typeof(Currency[any])

return table.freeze(Currency)
