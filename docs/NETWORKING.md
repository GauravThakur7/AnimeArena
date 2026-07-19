# AnimeArena — Networking & Server Authority

## Overview

AnimeArena uses a **server-authoritative model with client-side prediction**. The server owns all gameplay state. Clients predict locally for responsiveness, then reconcile when the server's authoritative state arrives.

---

## Networking Model

```
┌─────────────────────────────────────────────────┐
│                   SERVER                         │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │         Authoritative Simulation          │  │
│  │  - Combat state per player                │  │
│  │  - HP, stamina, poise                     │  │
│  │  - Position (validated)                   │  │
│  │  - Hit detection results                  │  │
│  │  - Match state                            │  │
│  └───────────────┬───────────────────────────┘  │
│                  │                               │
│  ┌───────────────┴───────────────────────────┐  │
│  │         Lag Compensation                  │  │
│  │  - Position history buffer (1 second)     │  │
│  │  - Rewind for hit validation              │  │
│  │  - Timestamp-based reconciliation         │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
└────────────────────┬────────────────────────────┘
                     │
          RemoteEvents (compressed)
                     │
┌────────────────────┴────────────────────────────┐
│                   CLIENT                         │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │         Client Prediction                 │  │
│  │  - Immediate input response               │  │
│  │  - Local state simulation                 │  │
│  │  - Animation plays immediately            │  │
│  │  - Unacknowledged input queue             │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ┌───────────────────────────────────────────┐  │
│  │         Reconciliation                    │  │
│  │  - Compare predicted vs server state      │  │
│  │  - If mismatch: snap to server            │  │
│  │  - Re-apply unacknowledged inputs         │  │
│  │  - Smooth interpolation for visuals       │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
└──────────────────────────────────────────────────┘
```

---

## Remote Event Architecture

### Client → Server (Input Remotes)

| Remote | Payload | Rate Limit |
|--------|---------|------------|
| `AttackRequest` | `{attackType, timestamp, sequenceId}` | 10/sec |
| `BlockRequest` | `{active: bool, timestamp}` | 20/sec |
| `ParryRequest` | `{timestamp, sequenceId}` | 5/sec |
| `DodgeRequest` | `{direction, dodgeType, timestamp}` | 8/sec |
| `MovementInput` | `{moveDir, sprint, timestamp}` | 30/sec |
| `UltimateRequest` | `{timestamp}` | 1/sec |
| `ExecutionRequest` | `{targetId, timestamp}` | 2/sec |

### Server → Client (State Remotes)

| Remote | Payload | Frequency |
|--------|---------|-----------|
| `StateUpdate` | `{combatState, hp, stamina, poise, position, tick}` | Every tick (60Hz) |
| `HitConfirm` | `{attackerId, targetId, damage, hitType, position}` | On hit |
| `ParryConfirm` | `{parrierId, attackerId}` | On parry |
| `MatchState` | `{phase, timer, scores}` | On change |
| `KillEvent` | `{killerId, victimId, method}` | On kill |
| `ComboUpdate` | `{comboCount, scaling, juggleCount}` | On combo hit |

### Server → All Clients (Broadcast)

| Remote | Purpose |
|--------|---------|
| `PlayerStateSync` | Periodic full state for all players (10Hz) |
| `MatchEvent` | Round start, round end, match end |
| `SpawnEvent` | Player respawn |

---

## Tick System

### Server Tick (60Hz Fixed)

```luau
local TICK_RATE = 60
local TICK_INTERVAL = 1 / TICK_RATE

RunService.Heartbeat:Connect(function(dt)
    accumulator += dt
    while accumulator >= TICK_INTERVAL do
        accumulator -= TICK_INTERVAL
        serverTick += 1
        
        ProcessInputQueue()       -- Handle buffered client inputs
        UpdateCombatSimulation()  -- Advance all combat states
        RunHitDetection()         -- Check hitboxes vs hurtboxes
        ValidatePositions()       -- Anti-cheat position checks
        BroadcastState()          -- Send authoritative state to clients
    end
end)
```

### Client Tick (Frame Rate)

```luau
RunService.RenderStepped:Connect(function(dt)
    PollInput()                  -- Gather raw input
    PredictLocally()             -- Run local simulation
    Interpolate()                -- Smooth other players' positions
    UpdateAnimations()           -- Drive animation state machine
    UpdateCamera()               -- Camera follow and effects
    RenderVFX()                  -- Visual effects
end)
```

---

## Spectator & Kill Cam

### Kill Cam

On player death, a brief replay plays from the attacker's perspective:

```luau
type KillCamData = {
    attackerPosition: Vector3,
    attackerLookAt: Vector3,
    victimPosition: Vector3,
    attackType: string,
    duration: number, -- 2-3 seconds
}
```

- Server sends kill cam data on death event
- Client enters cinematic camera mode for 2-3 seconds
- Camera interpolates from victim to attacker perspective
- Slow motion applied during final hit
- Player can skip with any input

### Spectator Mode

After elimination in multi-round modes:

```luau
type SpectatorState = {
    mode: "FreeCam" | "FollowPlayer" | "Cinematic",
    targetPlayer: Player?,
    cameraOffset: Vector3,
}
```

- Cycle between alive players (Tab / shoulder buttons)
- Free camera option (fly around arena)
- Cannot see UI of spectated player (no information advantage)
- Spectator UI shows match timer, scores, and player list

---

## Lag Compensation

### Position History Buffer

The server stores 1 second of position history for every player (60 snapshots).

```luau
type PositionSnapshot = {
    tick: number,
    position: Vector3,
    rotation: CFrame,
    combatState: string,
    hitboxActive: boolean,
    hurtboxBounds: {CFrame},
}

type PositionHistory = {
    snapshots: {PositionSnapshot}, -- circular buffer, 60 entries
    head: number,
}
```

### Hit Validation with Rewind

When the server receives an attack request:

1. Extract client timestamp from request
2. Calculate tick at which client saw the attack land
3. Rewind target's position to that tick (from history buffer)
4. Check hitbox vs rewound hurtbox
5. If hit: confirm. If miss: reject.

```luau
function ValidateHit(attacker, target, clientTimestamp)
    local clientTick = TimestampToTick(clientTimestamp)
    local latency = GetPlayerLatency(attacker)
    local rewindTick = serverTick - TicksFromMs(latency)
    
    -- Clamp rewind to prevent abuse (max 200ms rewind)
    rewindTick = math.max(rewindTick, serverTick - 12)
    
    local targetSnapshot = GetSnapshot(target, rewindTick)
    if not targetSnapshot then return false end
    
    return CheckHitboxOverlap(
        attacker.currentHitbox,
        targetSnapshot.hurtboxBounds
    )
end
```

### Rewind Limits

- Maximum rewind: 200ms (12 ticks at 60Hz)
- Beyond 200ms: hit is rejected (player has too much latency)
- Prevents "shooting around corners" exploits

---

## Client Prediction

### What Is Predicted

| System | Predicted? | Notes |
|--------|-----------|-------|
| Movement position | Yes | Immediate response to input |
| Combat state transitions | Yes | Attack plays immediately |
| Animation | Yes | Animation starts on input |
| Stamina consumption | Yes | UI updates immediately |
| HP changes | No | Server authoritative only |
| Hit confirmation | No | Wait for server |
| Poise | No | Server authoritative |
| Combo counter | Partially | Visual only until confirmed |

### Prediction Algorithm

```luau
function PredictAttack(attackType, inputFrame)
    -- Check if we can attack (predicted state)
    if not CanAttackInState(predictedState) then return end
    if predictedStamina < GetStaminaCost(attackType) then return end
    
    -- Apply prediction locally
    predictedState = CombatState.Attacking
    predictedStamina -= GetStaminaCost(attackType)
    
    -- Play animation immediately
    AnimationController:PlayAttack(attackType)
    
    -- Queue input for server
    SendToServer("AttackRequest", {
        attackType = attackType,
        timestamp = workspace:GetServerTimeNow(),
        sequenceId = nextSequenceId(),
    })
    
    -- Store prediction for reconciliation
    table.insert(unacknowledgedInputs, {
        sequenceId = currentSequenceId,
        predictedState = predictedState,
        frame = inputFrame,
    })
end
```

### Reconciliation

```luau
function OnServerStateReceived(serverState)
    -- Remove acknowledged inputs
    RemoveAcknowledgedInputs(serverState.lastProcessedSequence)
    
    -- Check if prediction matches
    if predictedState ~= serverState.combatState 
       or predictedPosition ~= serverState.position then
        
        -- Snap to server state
        currentState = serverState.combatState
        currentPosition = serverState.position
        
        -- Re-apply unacknowledged inputs
        for _, input in unacknowledgedInputs do
            ReplayInput(input)
        end
        
        -- Smooth visual correction
        StartVisualInterpolation(oldVisualPos, currentPosition, 0.1)
    end
end
```

---

## Anti-Exploit Validation

### Input Validation (Server)

Every incoming remote is validated:

```luau
function ValidateAttackRequest(player, data)
    -- Type check
    if typeof(data.attackType) ~= "string" then return false end
    if typeof(data.timestamp) ~= "number" then return false end
    
    -- Rate limiting
    if not RateLimiter:Check(player, "Attack", 10) then return false end
    
    -- State check
    local state = GetPlayerCombatState(player)
    if not CanAttackFromState(state) then return false end
    
    -- Stamina check
    local stamina = GetPlayerStamina(player)
    if stamina < GetAttackCost(data.attackType) then return false end
    
    -- Timestamp sanity (not too far in past/future)
    local serverTime = workspace:GetServerTimeNow()
    if math.abs(serverTime - data.timestamp) > 0.5 then return false end
    
    return true
end
```

### Position Validation

```luau
function ValidatePosition(player, reportedPosition)
    local lastValid = GetLastValidPosition(player)
    local maxSpeed = GetMaxSpeed(player) * 1.2 -- 20% tolerance
    local dt = GetTimeSinceLastUpdate(player)
    local maxDistance = maxSpeed * dt
    
    local distance = (reportedPosition - lastValid).Magnitude
    if distance > maxDistance then
        -- Teleport detected, snap back
        TeleportPlayer(player, lastValid)
        FlagPlayer(player, "SpeedHack")
        return false
    end
    
    return true
end
```

### Remote Rate Limiting

```luau
type RateLimiter = {
    limits: {[string]: {count: number, window: number}},
    history: {[Player]: {[string]: {number}}},
}

function RateLimiter:Check(player, action, maxPerSecond): boolean
    local history = self.history[player][action]
    local now = os.clock()
    
    -- Remove entries older than 1 second
    while #history > 0 and now - history[1] > 1 do
        table.remove(history, 1)
    end
    
    if #history >= maxPerSecond then
        return false -- Rate limited
    end
    
    table.insert(history, now)
    return true
end
```

---

## Network Optimization

### State Compression

Only send changed fields (delta compression):

```luau
function CompressStateUpdate(current, previous)
    local delta = {}
    if current.hp ~= previous.hp then delta.hp = current.hp end
    if current.stamina ~= previous.stamina then delta.stamina = current.stamina end
    if current.combatState ~= previous.combatState then delta.combatState = current.combatState end
    if current.position ~= previous.position then delta.position = current.position end
    return delta
end
```

### Remote Batching

Multiple state updates batched into single remote per tick:

```luau
-- Instead of:
-- StateRemote:FireClient(player, stateA)
-- StateRemote:FireClient(player, stateB)

-- Batch:
local batch = {}
for _, state in pendingUpdates do
    table.insert(batch, state)
end
BatchRemote:FireClient(player, batch)
pendingUpdates = {}
```

### Unreliable Remotes

For position updates and non-critical data, use UnreliableRemoteEvents (Roblox feature):

```luau
local PositionSync = Instance.new("UnreliableRemoteEvent")
-- Dropped packets are acceptable for position interpolation
```

---

## Connection Quality Handling

### Latency Detection

```luau
function MeasureLatency(player)
    local pingStart = os.clock()
    PingRemote:FireClient(player, pingStart)
    -- Client responds with PongRemote
end

function OnPong(player, originalTimestamp)
    local rtt = os.clock() - originalTimestamp
    local oneWay = rtt / 2
    playerLatency[player] = oneWay
end
```

### Quality Tiers

| Latency | Tier | Behavior |
|---------|------|----------|
| 0-50ms | Excellent | Full prediction, minimal rewind |
| 50-100ms | Good | Standard prediction + reconciliation |
| 100-200ms | Fair | Extended rewind window, visual smoothing |
| 200ms+ | Poor | Warn player, reduce rewind (disadvantaged) |

### Disconnect Handling

- 5 seconds no response: player marked as disconnected
- In ranked: 30 second reconnect window
- After timeout: forfeit match, MMR loss applied
- In casual: bot takes over or player removed

---

## Match Networking

### Match Lifecycle

```
1. Matchmaking finds players
2. Server creates match instance
3. Players teleported / loaded into arena
4. READY_CHECK phase (10 seconds)
5. COUNTDOWN phase (3 seconds)
6. FIGHTING phase (combat enabled)
7. ROUND_END phase (winner declared)
8. MATCH_END phase (results, rewards)
9. CLEANUP (players returned to lobby)
```

### Match State Replication

```luau
type MatchState = {
    phase: "ReadyCheck" | "Countdown" | "Fighting" | "RoundEnd" | "MatchEnd",
    timer: number,
    round: number,
    maxRounds: number,
    scores: {[number]: number}, -- playerId → score
    settings: MatchSettings,
}
```

---

## Security Layers

```
Layer 1: Type Validation    → Reject malformed data
Layer 2: Rate Limiting      → Reject spam
Layer 3: State Validation   → Reject impossible actions
Layer 4: Timestamp Check    → Reject stale/future inputs
Layer 5: Position Check     → Reject teleports/speed hacks
Layer 6: Behavior Analysis  → Flag suspicious patterns
Layer 7: Server Authority   → Client never decides outcomes
```
