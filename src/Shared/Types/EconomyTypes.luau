--!strict
--[[
	EconomyTypes.luau
	Type definitions for monetization and economy systems.
]]

export type CurrencyType = "Coins" | "Premium"

export type ShopItem = {
	Id: string,
	Name: string,
	Description: string,
	Category: string, -- "Skin" | "Emote" | "Title" | "Bundle" | etc.
	Price: number,
	Currency: CurrencyType,
	AssetId: string?,
	Limited: boolean,
	ExpiresAt: number?, -- Unix timestamp, nil = permanent
}

export type BattlePassTier = {
	Tier: number,
	XPRequired: number,
	FreeReward: RewardDef?,
	PremiumReward: RewardDef?,
}

export type RewardDef = {
	Type: string, -- "Currency" | "Skin" | "Emote" | "Title" | "XPBoost"
	ItemId: string?,
	Amount: number?,
}

export type BattlePassConfig = {
	Season: number,
	Name: string,
	StartDate: number,
	EndDate: number,
	MaxTier: number,
	Tiers: { BattlePassTier },
	PremiumPrice: number, -- DevProduct price
}

export type Transaction = {
	Type: string, -- "Earn" | "Deduct" | "Purchase" | "Reward"
	Currency: CurrencyType,
	Amount: number,
	Timestamp: number,
	Balance: number,
	Reason: string?,
}

return nil
