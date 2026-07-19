# AnimeArena — Architecture Document

## System Overview

AnimeArena follows a **server-authoritative client-predicted architecture** built on Roblox's networking model. The game uses the Knit framework for service/controller organization with a component-based entity system layered on top.

---

## High-Level Architecture

AnimeArena uses a **custom modular framework** (inspired by Knit but lighter, with dependency injection and no singleton abuse). UI is built with **React-Lua** for component architecture and reactive state management.

```
┌─────────────────────────────────────────────────────────────┐
│                        SERVER                                │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Services Layer                          │    │
│  │  CombatService | MatchService | ProgressionService  │    │
│  │  InventoryService | RankedService | AIService       │    │
│  │  MonetizationService | ArenaService                 │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                   │
│  ┌──────────────────────┴──────────────────────────────┐    │
│  │            Core Systems Layer                        │    │
│  │  HitValidation | LagCompensation | AntiCheat        │    │
│  │  StateAuthority | TickSimulation | Rollback          │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                   │
│  ┌──────────────────────┴──────────────────────────────┐    │
│  │           Component Layer                            │    │
│  │  HitboxComp | CombatStateComp | StaminaComp         │    │
│  │  PoiseComp | HealthComp | BuffComp                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└────────────────────────────┬────────────────────────────────┘
                             │
                     RemoteEvents / RemoteFunctions
                     (validated, rate-limited)
                             │
┌────────────────────────────┴────────────────────────────────┐
│                        CLIENT                                │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Controllers Layer                       │    │
│  │  InputCtrl | CombatCtrl | MovementCtrl | CameraCtrl │    │
│  │  AnimCtrl | VFXCtrl | AudioCtrl                     │    │
│  └──────────────────────┬──────────────────────────────┘    │
│                         │                                   │
│  ┌──────────────────────┴──────────────────────────────┐    │
│  │           Prediction & Rendering Layer              │    │
│  │  ClientPrediction | Reconciliation | Interpolation  │    │
│  │  AnimationStateMachine | ParticlePool | SoundPool   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              UI Layer (React-Lua)                    │    │
│  │  HUD | Menus | Overlays | Notifications             │    │
│  │  State Store | Bindings | Component Library         │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Folder → Roblox Mapping (Rojo)

| Source Folder | Roblox Location | Purpose |
|--------------|-----------------|---------|
| `src/Server/` | ServerScriptService | Server-only code (Services, Components) |
| `src/Client/` | StarterPlayerScripts | Client-only code (Controllers, Components) |
| `src/Shared/` | ReplicatedStorage | Shared modules, types, data, framework |
| `src/UI/` | StarterPlayerScripts (mounted via React-Lua) | React-Lua UI apps and components |
| `assets/` | Various | Animations, sounds, particles, models |

### Complete Folder Structure

```
AnimeArena/
├── default.project.json
├── wally.toml
├── wally.lock
├── selene.toml
├── stylua.toml
├── .luaurc
│
├── src/
│   ├── Server/
│   │   ├── Services/
│   │   │   ├── CombatService.luau
│   │   │   ├── MatchmakingService.luau
│   │   │   ├── RankedService.luau
│   │   │   ├── ProgressionService.luau
│   │   │   ├── InventoryService.luau
│   │   │   ├── MonetizationService.luau
│   │   │   ├── AntiCheatService.luau
│   │   │   ├── AIService.luau
│   │   │   ├── ArenaService.luau
│   │   │   └── DataService.luau
│   │   ├── Components/
│   │   │   ├── HitboxComponent.luau
│   │   │   ├── CombatStateComponent.luau
│   │   │   ├── StaminaComponent.luau
│   │   │   ├── PoiseComponent.luau
│   │   │   └── HealthComponent.luau
│   │   ├── Managers/
│   │   │   ├── MatchManager.luau
│   │   │   ├── PlayerManager.luau
│   │   │   └── ArenaManager.luau
│   │   └── init.server.luau
│   │
│   ├── Client/
│   │   ├── Controllers/
│   │   │   ├── InputController.luau
│   │   │   ├── CombatController.luau
│   │   │   ├── MovementController.luau
│   │   │   ├── CameraController.luau
│   │   │   ├── AnimationController.luau
│   │   │   ├── VFXController.luau
│   │   │   └── AudioController.luau
│   │   ├── Components/
│   │   │   ├── PredictionComponent.luau
│   │   │   └── ReconciliationComponent.luau
│   │   ├── Managers/
│   │   │   ├── UIManager.luau
│   │   │   └── SpectatorManager.luau
│   │   └── init.client.luau
│   │
│   ├── Shared/
│   │   ├── Framework/
│   │   │   ├── Container.luau         -- DI container
│   │   │   ├── ServiceBase.luau       -- Base class for services
│   │   │   ├── ControllerBase.luau    -- Base class for controllers
│   │   │   ├── Signal.luau            -- Event system
│   │   │   └── Network.luau           -- Remote abstraction
│   │   ├── Modules/
│   │   │   ├── CombatStateMachine.luau
│   │   │   ├── ComboStateMachine.luau
│   │   │   ├── FrameDataEngine.luau
│   │   │   ├── InputBuffer.luau
│   │   │   ├── StaminaManager.luau
│   │   │   ├── PoiseManager.luau
│   │   │   └── MomentumSystem.luau
│   │   ├── Data/
│   │   │   ├── Weapons/
│   │   │   │   ├── Katana.luau
│   │   │   │   ├── Greatsword.luau
│   │   │   │   ├── DualSwords.luau
│   │   │   │   └── init.luau          -- Registry
│   │   │   ├── Characters/
│   │   │   │   ├── CrimsonDemonSwordsman.luau
│   │   │   │   ├── StormRonin.luau
│   │   │   │   ├── HolyKnightCommander.luau
│   │   │   │   └── init.luau          -- Registry
│   │   │   ├── Arenas/
│   │   │   │   ├── TrainingGrounds.luau
│   │   │   │   ├── AncientTemple.luau
│   │   │   │   ├── FrozenCitadel.luau
│   │   │   │   └── init.luau          -- Registry
│   │   │   ├── FrameData/
│   │   │   ├── ComboRoutes/
│   │   │   ├── BattlePass/
│   │   │   ├── Shop/
│   │   │   └── Constants.luau
│   │   ├── Types/
│   │   │   ├── CombatTypes.luau
│   │   │   ├── WeaponTypes.luau
│   │   │   ├── CharacterTypes.luau
│   │   │   ├── NetworkTypes.luau
│   │   │   ├── UITypes.luau
│   │   │   ├── ArenaTypes.luau
│   │   │   └── EconomyTypes.luau
│   │   ├── Enums/
│   │   │   ├── CombatState.luau
│   │   │   ├── AttackType.luau
│   │   │   ├── Rank.luau
│   │   │   ├── GameMode.luau
│   │   │   └── Currency.luau
│   │   └── Util/
│   │       ├── ObjectPool.luau
│   │       ├── MathUtil.luau
│   │       ├── TableUtil.luau
│   │       ├── RateLimiter.luau
│   │       └── Validator.luau
│   │
│   └── UI/
│       ├── Apps/
│       │   ├── HUDApp.luau
│       │   ├── MainMenuApp.luau
│       │   ├── CharacterSelectApp.luau
│       │   ├── InventoryApp.luau
│       │   ├── ShopApp.luau
│       │   ├── RankedApp.luau
│       │   └── SettingsApp.luau
│       ├── Components/
│       │   ├── HealthBar.luau
│       │   ├── StaminaBar.luau
│       │   ├── UltMeter.luau
│       │   ├── DamageNumber.luau
│       │   ├── ComboCounter.luau
│       │   ├── KillFeed.luau
│       │   ├── Scoreboard.luau
│       │   ├── Button.luau
│       │   └── Modal.luau
│       ├── Hooks/
│       │   ├── usePlayerState.luau
│       │   ├── useCombatState.luau
│       │   └── useSettings.luau
│       ├── Store/
│       │   ├── UIStore.luau
│       │   └── Actions.luau
│       └── Theme.luau
│
├── Packages/                      -- Wally output
│
├── assets/
│   ├── Animations/
│   ├── Sounds/
│   ├── Particles/
│   └── Models/
│
├── tests/
│   ├── Server/
│   ├── Client/
│   └── Shared/
│
└── docs/
    ├── PROJECT_PLAN.md
    ├── ARCHITECTURE.md
    ├── COMBAT_SYSTEM.md
    ├── NETWORKING.md
    ├── UI.md
    ├── DATABASE.md
    └── ROADMAP.md
```

---

## Core Design Patterns

### 1. Service/Controller Pattern (Custom Framework)

The framework is Knit-inspired but lighter — no global singletons, dependency injection for testability, strict typing.

**Server Services** own game state and register remote endpoints.

```luau
-- Server Service definition
local CombatService = {}
CombatService.__index = CombatService

export type CombatService = typeof(CombatService)

function CombatService.new(deps: {
    hitValidator: HitValidator,
    staminaManager: StaminaManager,
    networkManager: NetworkManager,
})
    local self = setmetatable({}, CombatService)
    self._hitValidator = deps.hitValidator
    self._staminaManager = deps.staminaManager
    self._network = deps.networkManager
    return self
end

function CombatService:Init()
    self._network:RegisterRemote("AttackRequest", function(player, data)
        self:_handleAttackRequest(player, data)
    end)
end
```

**Client Controllers** manage input, rendering, and prediction.

```luau
-- Client Controller definition
local CombatController = {}
CombatController.__index = CombatController

function CombatController.new(deps: {
    inputController: InputController,
    animationController: AnimationController,
    networkClient: NetworkClient,
})
    local self = setmetatable({}, CombatController)
    self._input = deps.inputController
    self._animation = deps.animationController
    self._network = deps.networkClient
    return self
end
```

### 2. Dependency Injection Container

```luau
-- Framework bootstrap
local Container = require(shared.Framework.Container)

local container = Container.new()

-- Register dependencies
container:Register("NetworkManager", NetworkManager.new())
container:Register("HitValidator", HitValidator.new())
container:Register("StaminaManager", StaminaManager.new())

-- Resolve with auto-injection
local combatService = container:Resolve("CombatService")
```

### 2. Component Pattern

Gameplay entities (players, NPCs) are composed of components that encapsulate specific behavior.

```luau
-- Component definition
local CombatStateComponent = {}
CombatStateComponent.__index = CombatStateComponent

function CombatStateComponent.new(entity)
    return setmetatable({
        entity = entity,
        currentState = CombatState.Idle,
        stateTimer = 0,
        frameCounter = 0,
    }, CombatStateComponent)
end
```

### 3. Data-Driven Configuration

All content (weapons, characters, frame data) lives in pure data modules.

```luau
-- src/shared/Data/Weapons/Katana.luau
return {
    Name = "Katana",
    Damage = { Light = 12, Heavy = 28 },
    SwingSpeed = 1.2,
    Range = 8.5,
    ComboRoutes = { "LLL", "LLH", "LH", "HH" },
    FrameData = {
        LightAttack = { Startup = 6, Active = 4, Recovery = 12 },
        HeavyAttack = { Startup = 14, Active = 6, Recovery = 22 },
    },
}
```

### 4. State Machine Pattern

Combat and animation use explicit finite state machines with guarded transitions.

```luau
StateMachine:AddTransition({
    From = CombatState.Idle,
    To = CombatState.Attacking,
    Guard = function(context)
        return context.stamina >= context.attackCost
            and context.frameCounter >= context.recoveryEnd
    end,
})
```

### 5. Object Pooling

VFX, projectiles, damage numbers, and hitbox visualizers use pre-allocated pools.

```luau
local pool = ObjectPool.new(SlashTrailTemplate, 50)
local trail = pool:Get()
-- use trail
pool:Return(trail)
```

---

## Module Dependency Rules

1. **Server modules NEVER require client modules.**
2. **Client modules NEVER require server modules** (communicate via Knit remotes).
3. **Shared modules are pure** — no side effects, no Instance references, no network calls.
4. **Data modules have zero dependencies** — they return plain tables.
5. **Types are shared** — both client and server import from `shared/Types/`.

---

## Communication Flow

### Attack Request Flow

```
1. [Client] Player presses attack
2. [Client] InputController fires to CombatController
3. [Client] CombatController checks local state (prediction)
4. [Client] Plays animation immediately (client prediction)
5. [Client] Sends AttackRequest remote to server with timestamp
6. [Server] CombatService receives request
7. [Server] Validates: state, stamina, cooldown, rate limit
8. [Server] If valid: execute attack in simulation
9. [Server] HitboxComponent checks for hits (with lag compensation)
10. [Server] If hit: apply damage, notify both players
11. [Client] Receives OnHitConfirmed, plays VFX/SFX
12. [Client] Reconciles if prediction was wrong
```

### State Reconciliation Flow

```
1. [Server] Sends authoritative state snapshot every tick
2. [Client] Compares predicted state vs server state
3. [Client] If mismatch: rolls back to server state
4. [Client] Re-applies unacknowledged inputs
5. [Client] Smoothly interpolates visual position
```

---

## Threading Model

| Thread | Responsibility | Rate |
|--------|---------------|------|
| Server Heartbeat | Combat simulation, hit detection, state broadcast | 60 Hz |
| Client RenderStepped | Input polling, animation, camera, VFX | Frame rate |
| Client Heartbeat | Prediction tick, reconciliation | 60 Hz |

---

## Error Handling

- All remote handlers wrapped in pcall with structured error logging
- State machine prevents invalid transitions (returns to safe state)
- DataStore operations use retry with exponential backoff
- Component initialization validates required dependencies

---

## Scalability Considerations

- Object pooling prevents GC pressure from VFX/hitboxes
- Streaming Enabled for large maps (arena loading)
- LOD system for character models at distance
- Remote batching to reduce network overhead
- Deferred event processing to prevent frame spikes
