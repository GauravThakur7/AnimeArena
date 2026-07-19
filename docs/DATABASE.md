# AnimeArena — Database & Data Persistence

## Overview

AnimeArena uses **ProfileStore** as the primary data persistence layer, abstracting over Roblox DataStoreService. ProfileStore handles session locking, data integrity, and atomic saves.

---

## Data Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                │
│                                                             │
│  ┌───────────────┐  ┌──────────────┐  ┌────────────────┐   │
│  │ ProfileStore  │  │ OrderedData  │  │ MemoryStore    │   │
│  │ (Player Data) │  │ (Leaderboards)│  │ (Matchmaking)  │   │
│  └───────┬───────┘  └──────┬───────┘  └───────┬────────┘   │
│          │                 │                   │             │
│  ┌───────┴───────┐  ┌─────┴────────┐  ┌──────┴─────────┐  │
│  │ Player Profile│  │ Global Ranks │  │ Queue State    │  │
│  │ Inventory     │  │ Season Stats │  │ Match Lobbies  │  │
│  │ Progression   │  │ All-Time     │  │ Temp Sessions  │  │
│  │ Settings      │  │              │  │                │  │
│  └───────────────┘  └──────────────┘  └────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Player Profile Schema

```luau
type PlayerProfile = {
    -- Meta
    Version: number,               -- Schema version for migrations
    CreatedAt: number,             -- Unix timestamp
    LastLogin: number,             -- Unix timestamp
    PlayTime: number,              -- Total seconds played
    
    -- Progression
    Level: number,                 -- Player level (1-100+)
    Experience: number,            -- Current XP
    ExperienceToNext: number,     -- XP needed for next level
    
    -- Currency
    Coins: number,                 -- Earned currency (gameplay)
    Premium: number,               -- Purchased currency (Robux)
    
    -- Combat Stats
    Stats: {
        TotalMatches: number,
        Wins: number,
        Losses: number,
        Draws: number,
        TotalKills: number,
        TotalDeaths: number,
        TotalDamageDealt: number,
        TotalDamageTaken: number,
        PerfectParries: number,
        LongestCombo: number,
        ExecutionsPerformed: number,
        UltimatesUsed: number,
    },
    
    -- Ranked
    Ranked: {
        MMR: number,                -- Matchmaking Rating (default 1000)
        Rank: string,              -- Display rank (Bronze → Mythic)
        LP: number,                -- League Points (0-100)
        Tier: number,              -- Rank tier (I, II, III)
        WinStreak: number,
        LossStreak: number,
        PlacementGames: number,    -- 0-10 (10 = placed)
        PlacementWins: number,
        SeasonHighMMR: number,
        LastDecayCheck: number,    -- Timestamp
    },
    
    -- Characters
    Characters: {
        [string]: {                -- CharacterId → CharacterData
            Unlocked: boolean,
            Mastery: number,       -- 0-100
            MasteryXP: number,
            GamesPlayed: number,
            Wins: number,
            SelectedSkin: string?,
            SelectedEmote: string?,
        }
    },
    
    -- Weapons
    Weapons: {
        [string]: {                -- WeaponId → WeaponData
            Unlocked: boolean,
            Mastery: number,
            MasteryXP: number,
            SelectedSkin: string?,
        }
    },
    
    -- Inventory
    Inventory: {
        Skins: {string},           -- Owned skin IDs
        Emotes: {string},          -- Owned emote IDs
        Titles: {string},          -- Owned title IDs
        Banners: {string},         -- Owned banner IDs
        KillEffects: {string},     -- Owned kill effect IDs
        VictoryPoses: {string},    -- Owned victory pose IDs
        Trails: {string},          -- Owned trail IDs
    },
    
    -- Equipped Cosmetics
    Equipped: {
        Title: string?,
        Banner: string?,
        KillEffect: string?,
        VictoryPose: string?,
        Trail: string?,
        NameColor: string?,
    },
    
    -- Battle Pass
    BattlePass: {
        Owned: boolean,            -- Premium track owned
        Tier: number,              -- Current tier (1-100)
        XP: number,               -- Current tier XP
        ClaimedFree: {number},    -- Claimed free tier rewards
        ClaimedPremium: {number}, -- Claimed premium tier rewards
        Season: number,           -- Which season this is for
    },
    
    -- Achievements
    Achievements: {
        [string]: {               -- AchievementId → progress
            Completed: boolean,
            Progress: number,
            CompletedAt: number?, -- Timestamp
        }
    },
    
    -- Quests (Daily/Weekly)
    Quests: {
        Daily: {
            [string]: {           -- QuestId → progress
                Progress: number,
                Completed: boolean,
                ClaimedReward: boolean,
            }
        },
        Weekly: {
            [string]: {
                Progress: number,
                Completed: boolean,
                ClaimedReward: boolean,
            }
        },
        LastDailyReset: number,   -- Timestamp
        LastWeeklyReset: number,  -- Timestamp
    },
    
    -- Settings (synced across sessions)
    Settings: {
        MusicVolume: number,      -- 0-100
        SFXVolume: number,        -- 0-100
        CameraSensitivity: number,-- 0.1-5.0
        UIScale: number,          -- 0.5-2.0
        ShowDamageNumbers: boolean,
        ScreenShake: boolean,
        BloodEffects: boolean,
        Colorblind: string?,      -- nil | "protanopia" | "deuteranopia" | "tritanopia"
        ReducedMotion: boolean,
        CrosshairStyle: string,
    },
}
```

---

## Default Profile Template

```luau
local DEFAULT_PROFILE = {
    Version = 1,
    CreatedAt = 0,
    LastLogin = 0,
    PlayTime = 0,
    
    Level = 1,
    Experience = 0,
    ExperienceToNext = 100,
    
    Coins = 0,
    Premium = 0,
    
    Stats = {
        TotalMatches = 0,
        Wins = 0,
        Losses = 0,
        Draws = 0,
        TotalKills = 0,
        TotalDeaths = 0,
        TotalDamageDealt = 0,
        TotalDamageTaken = 0,
        PerfectParries = 0,
        LongestCombo = 0,
        ExecutionsPerformed = 0,
        UltimatesUsed = 0,
    },
    
    Ranked = {
        MMR = 1000,
        Rank = "Unranked",
        LP = 0,
        Tier = 0,
        WinStreak = 0,
        LossStreak = 0,
        PlacementGames = 0,
        PlacementWins = 0,
        SeasonHighMMR = 0,
        LastDecayCheck = 0,
    },
    
    Characters = {},
    Weapons = {},
    
    Inventory = {
        Skins = {},
        Emotes = {},
        Titles = {},
        Banners = {},
        KillEffects = {},
        VictoryPoses = {},
        Trails = {},
    },
    
    Equipped = {
        Title = nil,
        Banner = nil,
        KillEffect = nil,
        VictoryPose = nil,
        Trail = nil,
        NameColor = nil,
    },
    
    BattlePass = {
        Owned = false,
        Tier = 1,
        XP = 0,
        ClaimedFree = {},
        ClaimedPremium = {},
        Season = 1,
    },
    
    Achievements = {},
    Quests = {
        Daily = {},
        Weekly = {},
        LastDailyReset = 0,
        LastWeeklyReset = 0,
    },
    
    Settings = {
        MusicVolume = 80,
        SFXVolume = 100,
        CameraSensitivity = 1.0,
        UIScale = 1.0,
        ShowDamageNumbers = true,
        ScreenShake = true,
        BloodEffects = false,
        Colorblind = nil,
        ReducedMotion = false,
        CrosshairStyle = "Default",
    },
}
```

---

## ProfileStore Integration

### Loading Profiles

```luau
local ProfileStore = require(Packages.ProfileStore)

local PlayerProfileStore = ProfileStore.New("PlayerData_v1", DEFAULT_PROFILE)

function DataService:LoadProfile(player: Player)
    local profile = PlayerProfileStore:StartSessionAsync(
        tostring(player.UserId),
        {
            Cancel = function()
                return player.Parent ~= Players
            end,
        }
    )
    
    if not profile then
        player:Kick("Failed to load data. Please rejoin.")
        return nil
    end
    
    -- Session lock handling
    profile:AddUserId(player.UserId)
    profile:Reconcile() -- Fill missing fields from template
    
    -- Listen for session end
    profile.OnSessionEnd:Connect(function()
        self.profiles[player] = nil
        player:Kick("Session ended. Please rejoin.")
    end)
    
    -- Check if player is still in game
    if player.Parent ~= Players then
        profile:EndSession()
        return nil
    end
    
    self.profiles[player] = profile
    self:MigrateProfile(profile) -- Handle schema migrations
    
    return profile
end
```

### Saving Data

```luau
-- ProfileStore auto-saves periodically
-- Manual save on specific events:

function DataService:SaveProfile(player: Player)
    local profile = self.profiles[player]
    if profile then
        profile:Save()
    end
end

-- Save on player leave
function DataService:OnPlayerRemoving(player: Player)
    local profile = self.profiles[player]
    if profile then
        profile:EndSession()
        self.profiles[player] = nil
    end
end
```

---

## Schema Migrations

```luau
local CURRENT_VERSION = 1

function DataService:MigrateProfile(profile)
    local data = profile.Data
    
    if data.Version < 1 then
        -- Migration from v0 to v1
        data.BattlePass = data.BattlePass or DEFAULT_PROFILE.BattlePass
        data.Quests = data.Quests or DEFAULT_PROFILE.Quests
        data.Version = 1
    end
    
    -- Future migrations go here:
    -- if data.Version < 2 then ... end
end
```

---

## Leaderboards (OrderedDataStore)

### Leaderboard Types

| Leaderboard | Store Key | Update Frequency |
|-------------|----------|-----------------|
| MMR (Ranked) | `Leaderboard_MMR_S{season}` | After each ranked match |
| Total Wins | `Leaderboard_Wins` | After each win |
| Longest Combo | `Leaderboard_Combo` | When new record |
| Character Mastery | `Leaderboard_Mastery_{charId}` | On mastery gain |

### Leaderboard Service

```luau
function LeaderboardService:UpdateEntry(boardName, playerId, value)
    local store = DataStoreService:GetOrderedDataStore(boardName)
    local success, err = pcall(function()
        store:SetAsync(tostring(playerId), value)
    end)
    if not success then
        warn("Leaderboard update failed:", err)
        -- Queue for retry
        table.insert(self.retryQueue, {boardName, playerId, value})
    end
end

function LeaderboardService:GetTopPlayers(boardName, count)
    local store = DataStoreService:GetOrderedDataStore(boardName)
    local pages = store:GetSortedAsync(false, count)
    local entries = pages:GetCurrentPage()
    
    local results = {}
    for rank, entry in entries do
        table.insert(results, {
            Rank = rank,
            PlayerId = tonumber(entry.key),
            Value = entry.value,
        })
    end
    return results
end
```

---

## MemoryStore (Transient Data)

Used for real-time matchmaking and temporary session state.

```luau
local MemoryStoreService = game:GetService("MemoryStoreService")

-- Matchmaking queue
local matchQueue = MemoryStoreService:GetSortedMap("MatchQueue_1v1")

function MatchmakingService:JoinQueue(player, mmr)
    matchQueue:SetAsync(
        tostring(player.UserId),
        {
            MMR = mmr,
            JoinTime = os.time(),
            Region = self:GetRegion(player),
        },
        300 -- 5 minute expiry (auto-remove if stuck)
    )
end

function MatchmakingService:LeaveQueue(player)
    matchQueue:RemoveAsync(tostring(player.UserId))
end
```

---

## Data Security

### Server-Only Access

```luau
-- NEVER expose DataService methods to client
-- All data modifications go through validated service methods

function ProgressionService.Client:RequestPurchase(player, itemId)
    -- Validate item exists
    -- Validate player has currency
    -- Validate item not already owned
    -- Deduct currency
    -- Add item to inventory
    -- Save
    -- Return result
end
```

### Economy Validation

```luau
function EconomyService:DeductCurrency(player, currencyType, amount)
    assert(amount > 0, "Amount must be positive")
    assert(currencyType == "Coins" or currencyType == "Premium")
    
    local profile = DataService:GetProfile(player)
    if not profile then return false, "No profile" end
    
    if profile.Data[currencyType] < amount then
        return false, "Insufficient funds"
    end
    
    profile.Data[currencyType] -= amount
    
    -- Log transaction
    self:LogTransaction(player, {
        Type = "Deduct",
        Currency = currencyType,
        Amount = amount,
        Timestamp = os.time(),
        Balance = profile.Data[currencyType],
    })
    
    return true
end
```

### Transaction Logging

```luau
-- Store last 100 transactions per player for audit
type Transaction = {
    Type: "Earn" | "Deduct" | "Purchase" | "Reward",
    Currency: "Coins" | "Premium",
    Amount: number,
    Timestamp: number,
    Balance: number,
    Reason: string?,
}
```

---

## Data Budget

Roblox DataStore limits:

| Resource | Limit | Our Usage |
|----------|-------|-----------|
| Key size | 50 characters | Well under |
| Value size | 4MB | ~50KB estimated per profile |
| Set requests | 60 + 10×players /min | ProfileStore handles throttling |
| Get requests | 60 + 10×players /min | Cached in memory |
| OrderedDataStore pages | 100 entries/page | Paginated leaderboards |

### Data Size Optimization

- Use short key names in stored data
- Don't store derived values (calculate at runtime)
- Prune old quest data on season rollover
- Cap transaction log at 100 entries
- Archive old season ranked data (keep only summary)

---

## Backup & Recovery

```luau
-- ProfileStore handles session locking automatically
-- Additional safety measures:

-- 1. Version field for migration safety
-- 2. Profile:Reconcile() fills missing template fields
-- 3. Kick on session conflict (prevents duplication)
-- 4. Auto-save interval: 30 seconds (ProfileStore default)
-- 5. Save on player leave
-- 6. Save on server shutdown (BindToClose)

game:BindToClose(function()
    for player, profile in DataService.profiles do
        profile:EndSession()
    end
end)
```

---

## Ranked Season Reset

```luau
function RankedService:PerformSeasonReset(profile)
    local ranked = profile.Data.Ranked
    
    -- Soft reset: compress toward 1000
    ranked.MMR = math.floor(1000 + (ranked.MMR - 1000) * 0.5)
    ranked.Rank = self:CalculateRank(ranked.MMR)
    ranked.LP = 0
    ranked.Tier = self:CalculateTier(ranked.MMR)
    ranked.WinStreak = 0
    ranked.LossStreak = 0
    ranked.PlacementGames = 0
    ranked.PlacementWins = 0
    ranked.SeasonHighMMR = ranked.MMR
    
    -- Archive previous season
    -- (stored in separate key to save space)
end
```
