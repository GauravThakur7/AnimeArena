# AnimeArena — UI/UX Design Document

## Philosophy

The UI should be **minimal during combat** and **cinematic in menus**. Players should never feel distracted by HUD elements during a fight, but should feel immersed and rewarded during non-combat screens.

---

## UI Architecture

```
UI Layer Stack (Z-order, bottom to top):
┌─────────────────────────────────────┐
│  Layer 0: World UI (billboards)     │  ← Health bars above players
├─────────────────────────────────────┤
│  Layer 1: HUD (always visible)      │  ← HP, stamina, ult meter
├─────────────────────────────────────┤
│  Layer 2: Combat Feedback           │  ← Damage numbers, hit indicators
├─────────────────────────────────────┤
│  Layer 3: Notifications             │  ← Kill feed, announcements
├─────────────────────────────────────┤
│  Layer 4: Overlays                  │  ← Scoreboard, pause
├─────────────────────────────────────┤
│  Layer 5: Full-screen Menus         │  ← Character select, shop
├─────────────────────────────────────┤
│  Layer 6: Modal Dialogs             │  ← Confirmations, errors
└─────────────────────────────────────┘
```

---

## HUD Layout

### Combat HUD (During Match)

```
┌──────────────────────────────────────────────────────────────┐
│  [Kill Feed]                              [Match Timer: 2:45] │
│                                                              │
│                                                              │
│                                                              │
│                                                              │
│                    [Lock-On Indicator]                        │
│                                                              │
│                    [Combo Counter: 5]                         │
│                                                              │
│  [Hit Direction                         [Damage Numbers]     │
│   Indicator]                                                 │
│                                                              │
│                                                              │
│ ┌─────────────────┐              ┌─────────────────────────┐ │
│ │ [Player HP Bar] │              │ [Opponent HP Bar]        │ │
│ │ [Stamina Bar  ] │              │ [Stamina Bar  ]          │ │
│ │ [Ult Meter    ] │              │                          │ │
│ │ [Skills/CD    ] │              │                          │ │
│ └─────────────────┘              └─────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### HUD Elements

| Element | Position | Behavior |
|---------|----------|----------|
| Player HP | Bottom-left | Animated drain, flash on low HP |
| Opponent HP | Bottom-right | Shows during lock-on |
| Stamina Bar | Below HP | Pulses red when empty |
| Ultimate Meter | Below stamina | Glows when full, flashy animation |
| Combo Counter | Center | Appears on 2+ hits, scales up |
| Damage Numbers | Near hit location | Float up, fade out |
| Hit Indicator | Screen edges | Directional arrows showing damage source |
| Kill Feed | Top-left | Last 5 kills, fades after 5s |
| Match Timer | Top-center | Pulses when < 30s remaining |
| Skill Cooldowns | Bottom-left cluster | Circular cooldown sweep |

---

## Menu Screens

### Main Menu

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│                    ╔═══════════════════╗                      │
│                    ║   ANIME ARENA     ║                      │
│                    ╚═══════════════════╝                      │
│                                                              │
│                    [  PLAY  ]                                 │
│                    [ RANKED ]                                 │
│                    [ TRAINING ]                               │
│                    [ CHARACTER ]                              │
│                    [ INVENTORY ]                              │
│                    [ SHOP ]                                   │
│                    [ SETTINGS ]                               │
│                                                              │
│  [Player Card]                              [News/Events]    │
│  Level 42                                   Season 3 Active  │
│  Rank: Diamond                              New Character!   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Character Select

```
┌──────────────────────────────────────────────────────────────┐
│  [Back]              CHARACTER SELECT              [Confirm]  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │                                                      │    │
│  │              [3D Character Preview]                   │    │
│  │              (rotatable, animated idle)               │    │
│  │                                                      │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐   │
│  │ C1 ││ C2 ││ C3 ││ C4 ││ C5 ││ C6 ││ C7 ││ C8 ││ C9 │   │
│  └────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘   │
│                                                              │
│  ┌─────────────────────┐  ┌──────────────────────────────┐  │
│  │ Stats               │  │ Abilities                    │  │
│  │ ATK: ████████░░     │  │ Passive: Shadow Step         │  │
│  │ DEF: ██████░░░░     │  │ Skill 1: Crimson Slash       │  │
│  │ SPD: █████████░     │  │ Skill 2: Demon Flurry        │  │
│  │ RNG: ██████░░░░     │  │ Ultimate: Thousand Cuts      │  │
│  └─────────────────────┘  └──────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Ranked Menu

```
┌──────────────────────────────────────────────────────────────┐
│  [Back]                  RANKED                               │
│                                                              │
│         ┌──────────────────────────────────┐                 │
│         │      ◆ DIAMOND II ◆              │                 │
│         │      MMR: 1847                   │                 │
│         │      W/L: 142/98                 │                 │
│         │                                  │                 │
│         │   [████████████░░░] 72/100 LP    │                 │
│         │                                  │                 │
│         └──────────────────────────────────┘                 │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  Recent Matches                                      │    │
│  │  W  vs PlayerX    +18 LP   Shadow Blade   2-1        │    │
│  │  L  vs PlayerY    -14 LP   Storm Ronin    1-2        │    │
│  │  W  vs PlayerZ    +16 LP   Holy Knight    2-0        │    │
│  └──────────────────────────────────────────────────────┘    │
│                                                              │
│  [Queue 1v1]    [Queue 2v2]    [Queue 3v3]                   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

### Match Results / MVP Screen

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│                      ★ VICTORY ★                             │
│                                                              │
│         ┌────────────────────────────────┐                   │
│         │                                │                   │
│         │    [Character Victory Pose]    │                   │
│         │                                │                   │
│         └────────────────────────────────┘                   │
│                                                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐         │
│  │ MVP          │ │ Most Damage  │ │ Best Combo   │         │
│  │ PlayerName   │ │ PlayerName   │ │ PlayerName   │         │
│  │ 2450 DMG     │ │ 1820 DMG     │ │ 12 Hits      │         │
│  └──────────────┘ └──────────────┘ └──────────────┘         │
│                                                              │
│  Rewards: +85 XP  |  +18 LP  |  +15 Character Mastery       │
│                                                              │
│              [Continue]        [Rematch]                      │
└──────────────────────────────────────────────────────────────┘
```

---

## UI Animation Guidelines

| Transition | Animation | Duration |
|-----------|-----------|----------|
| Menu open | Slide in from edge + fade | 0.3s ease-out |
| Menu close | Slide out + fade | 0.2s ease-in |
| Button hover | Scale 1.0 → 1.05 + glow | 0.1s |
| Button press | Scale 1.05 → 0.95 → 1.0 | 0.15s |
| HP bar drain | Smooth lerp + delay trail | 0.5s |
| Damage number | Pop in + float up + fade | 1.0s |
| Combo counter | Scale pulse on increment | 0.2s |
| Kill notification | Slide in from right | 0.3s |
| Round transition | Full screen wipe | 0.5s |
| Ultimate activation | Screen flash + zoom | 0.3s |

---

## Responsive Design

### Screen Size Breakpoints

| Device | Resolution | HUD Scale | Adjustments |
|--------|-----------|-----------|-------------|
| PC (1080p+) | 1920×1080 | 1.0x | Full layout |
| PC (720p) | 1280×720 | 0.85x | Slightly smaller elements |
| Tablet | 1024×768 | 0.9x | Larger touch targets |
| Phone | 640×360 | 0.7x | Minimal HUD, larger buttons |

### Mobile Adaptations

- Virtual joystick (left side) for movement
- Attack buttons (right side) - large touch targets
- Simplified HUD (combine bars, remove kill feed)
- Auto-lock-on by default on mobile
- Gesture support: swipe for dodge direction

---

## Controller Support

| Input | Keyboard/Mouse | Controller |
|-------|---------------|-----------|
| Move | WASD | Left Stick |
| Camera | Mouse | Right Stick |
| Light Attack | Left Click | X / Square |
| Heavy Attack | Right Click | Y / Triangle |
| Block | Q | LB / L1 |
| Parry | E (tap) | LB / L1 (tap) |
| Dodge | Space + Direction | A / Cross + Direction |
| Sprint | Shift (hold) | Left Stick Click |
| Lock-On | Tab | Right Stick Click |
| Ultimate | R | LB+RB / L1+R1 |
| Skill 1 | 1 | LT / L2 |
| Skill 2 | 2 | RT / R2 |
| Menu | Escape | Start / Options |
| Scoreboard | Hold Tab | Select / Share |

---

## UI Component Architecture

The UI is built entirely with **React-Lua** (formerly Roact), providing component architecture, reactive state management, and composability.

### React-Lua Component Pattern

```luau
local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local e = React.createElement

-- Functional component with hooks
local function HealthBar(props)
    local currentHP, setCurrentHP = React.useState(props.maxHP)
    local animatedWidth, setAnimatedWidth = React.useState(1)
    
    React.useEffect(function()
        setCurrentHP(props.currentHP)
        -- Animate bar width
        setAnimatedWidth(props.currentHP / props.maxHP)
    end, {props.currentHP})
    
    return e("Frame", {
        Size = UDim2.new(animatedWidth, 0, 1, 0),
        BackgroundColor3 = if animatedWidth < 0.25 
            then Color3.fromRGB(220, 50, 50)
            else Color3.fromRGB(80, 200, 80),
    })
end
```

### Custom Hooks

```luau
-- usePlayerState: subscribes to server state updates
local function usePlayerState(playerId: number)
    local state, setState = React.useState(DEFAULT_PLAYER_STATE)
    
    React.useEffect(function()
        local connection = NetworkClient:Subscribe("StateUpdate", function(data)
            if data.playerId == playerId then
                setState(data)
            end
        end)
        return function()
            connection:Disconnect()
        end
    end, {playerId})
    
    return state
end

-- useCombatState: tracks combat-specific reactive state
local function useCombatState()
    local combat, setCombat = React.useState({
        comboCount = 0,
        isBlocking = false,
        ultimateReady = false,
    })
    
    React.useEffect(function()
        local conn = CombatController.OnStateChanged:Connect(function(newState)
            setCombat(newState)
        end)
        return function() conn:Disconnect() end
    end, {})
    
    return combat
end
```

### UI State Store

```luau
-- Centralized UI state with React context
local UIContext = React.createContext(nil)

local function UIProvider(props)
    local state, dispatch = React.useReducer(UIReducer, {
        currentScreen = "MainMenu",
        hudVisible = true,
        combatMode = false,
        notifications = {},
        settings = DEFAULT_SETTINGS,
    })
    
    return e(UIContext.Provider, {
        value = { state = state, dispatch = dispatch },
    }, props.children)
end

-- Reducer for predictable state transitions
local function UIReducer(state, action)
    if action.type == "NAVIGATE" then
        return TableUtil.merge(state, { currentScreen = action.screen })
    elseif action.type == "TOGGLE_HUD" then
        return TableUtil.merge(state, { hudVisible = not state.hudVisible })
    elseif action.type == "ADD_NOTIFICATION" then
        local notifs = TableUtil.copy(state.notifications)
        table.insert(notifs, action.notification)
        return TableUtil.merge(state, { notifications = notifs })
    end
    return state
end
```

### App Mount System

```luau
-- Client init mounts React tree
local root = ReactRoblox.createRoot(PlayerGui)

root:render(e(UIProvider, {}, {
    HUD = e(HUDApp),
    Menus = e(MenuRouter),
    Overlays = e(OverlayLayer),
    Notifications = e(NotificationLayer),
}))
```

---

## Accessibility

- Colorblind mode: alternate hit indicator colors
- UI scale slider: 0.5x to 2.0x
- High contrast option for HUD elements
- Screen reader labels on all interactive elements
- Subtitles for audio cues (parry sound → "PARRY!" text flash)
- Adjustable HUD opacity
- Damage number size option
- Reduced motion option (disables screen shake, flash)
