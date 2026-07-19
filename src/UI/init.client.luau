--!strict
--[[
	UI/init.client.luau
	React-Lua UI bootstrap. Mounts the root React tree into PlayerGui.
	Full UI implementation in Phase 9.
	
	This runs from ReplicatedFirst for fast loading.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for packages to replicate
local Packages = ReplicatedStorage:WaitForChild("Packages")
local React = require(Packages:WaitForChild("React"))
local ReactRoblox = require(Packages:WaitForChild("ReactRoblox"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════
-- ROOT APP (placeholder until Phase 9)
-- ═══════════════════════════════════════════════════

local function App()
	return React.createElement("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		LoadingIndicator = React.createElement("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "AnimeArena",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 48,
			Font = Enum.Font.GothamBold,
			Visible = false, -- Hidden by default, shown during loading
		}),
	})
end

-- Mount React tree
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnimeArenaUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local uiRoot = ReactRoblox.createRoot(screenGui)
uiRoot:render(React.createElement(App))

print("[AnimeArena UI] React tree mounted.")
