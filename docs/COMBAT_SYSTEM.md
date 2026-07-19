# AnimeArena — Combat System Design

## Philosophy

Combat in AnimeArena is a **deterministic, frame-data-driven system** where every action has explicit startup, active, and recovery frames. Players win through reads, timing, and spacing — never through random chance or stat inflation.

---

## Combat State Machine

The combat state machine is the central authority for what a player can do at any given moment.

### States

```
┌─────────────────────────────────────────────────────────────┐
│                     COMBAT STATES                            │
├─────────────────────────────────────────────────────────────┤
│ Idle              │ Default state, all actions available     │
│ Walking           │ Movement, can cancel into attacks        │
│ Running           │ Sprint state, limited attack options     │
│ Attacking         │ In attack animation (startup/active/rec) │
│ HeavyAttacking    │ Heavy attack, slower, more damage        │
│ Blocking          │ Holding guard, stamina drains on hit     │
│ Parrying          │ Active parry window (frames 1-6)         │
│ ParrySuccess      │ Successful parry, enter riposte window   │
│ Riposte           │ Guaranteed counter after parry           │
│ Staggered         │ Hit confirmed, in hitstun                │
│ Launched          │ Airborne from launch attack              │
│ Juggled           │ Airborne, can be combo'd                 │
│ Grounded          │ On floor after knockdown                 │
│ GettingUp         │ Recovery from ground state               │
│ Rolling           │ I-frames active, repositioning           │
│ Dashing           │ Quick directional movement               │
│ Backstepping      │ Backward evasion with I-frames           │
│ Sidestepping      │ Lateral evasion                          │
│ GuardBroken       │ Guard depleted, vulnerable               │
│ Executing         │ Performing execution attack              │
│ BeingExecuted     │ Receiving execution (cinematic)          │
│ UsingUltimate     │ Ultimate ability active                  │
│ SuperArmor        │ Cannot be staggered (poise active)       │
│ Dead              │ Eliminated                               │
│ Ragdoll           │ Physics ragdoll (knockback)              │
│ WallBounce        │ Hit wall during knockback                │
│ GroundBounce      │ Bounced off ground during juggle         │
│ AirAttacking      │ Attacking while airborne                 │
│ GroundSlamming    │ Descending slam from air                 │
└─────────────────────────────────────────────────────────────┘
```

### State Transition Diagram (Simplified)

```
                    ┌──────────┐
            ┌──────│   Idle   │──────┐
            │      └────┬─────┘      │
            ▼           │            ▼
      ┌──────────┐     │     ┌───────────┐
      │ Blocking │     │     │ Attacking │
      └────┬─────┘     │     └─────┬─────┘
           │           │           │
           ▼           ▼           ▼
      ┌──────────┐ ┌────────┐ ┌──────────┐
      │ Parrying │ │ Moving │ │Staggered │
      └────┬─────┘ └────────┘ └──────────┘
           │                        │
           ▼                        ▼
      ┌──────────┐           ┌──────────┐
      │ Riposte  │           │ Launched │
      └──────────┘           └──────────┘
```

---

## Frame Data System

Every attack is defined by frame data. At 60 ticks/second, 1 frame = ~16.67ms.

### Frame Structure

```
|-- Startup --|-- Active --|-- Recovery --|
|  Cannot hit |  Can hit   |  Vulnerable  |
|  Can cancel*|  Hitbox on |  Cannot act  |
```

### Frame Data Definition

```luau
type FrameData = {
    Startup: number,      -- frames before hitbox activates
    Active: number,       -- frames hitbox is active
    Recovery: number,     -- frames after active before next action
    Hitstun: number,      -- frames opponent is stunned on hit
    Blockstun: number,    -- frames opponent is stunned on block
    HitAdvantage: number, -- frame advantage on hit
    BlockAdvantage: number, -- frame advantage on block (usually negative)
    CancelWindow: {number}, -- frames where cancel into next move is allowed
    IFrames: {number}?,   -- invulnerability frames (for dodges)
    ArmorFrames: {number}?, -- super armor frames (for heavies)
}
```

### Example Frame Data Table

| Move | Startup | Active | Recovery | Hitstun | On Block |
|------|---------|--------|----------|---------|----------|
| Light 1 | 6 | 4 | 12 | 18 | -4 |
| Light 2 | 7 | 4 | 14 | 18 | -5 |
| Light 3 | 8 | 5 | 18 | 22 | -8 |
| Heavy | 14 | 6 | 22 | 28 | -10 |
| Running Attack | 10 | 5 | 16 | 20 | -6 |
| Dash Attack | 8 | 4 | 14 | 16 | -4 |
| Launch | 12 | 4 | 20 | — | -12 |
| Ground Slam | 16 | 8 | 24 | — | -14 |

---

## Combo System

### Combo Routes

Combos are defined as sequences of inputs with cancel windows.

```luau
type ComboRoute = {
    Sequence: {AttackType},  -- e.g., {Light, Light, Heavy}
    CancelPoints: {number}, -- frame windows for chaining
    Damage: number,         -- total combo damage (with scaling)
    Finisher: string,       -- animation for final hit
}
```

### Damage Scaling

Combo damage scales down with each successive hit to prevent infinites:

```
Hit 1: 100% damage
Hit 2: 90% damage
Hit 3: 80% damage
Hit 4: 70% damage
Hit 5+: 60% damage (floor)
```

### Juggle System

- Launch attacks put opponents airborne
- Airborne opponents can be hit a limited number of times (juggle limit: 4)
- Gravity increases per juggle hit (anti-infinite)
- Ground bounce allows one extension
- Wall bounce allows one extension
- Cannot loop: launch → juggle → launch

### Input Buffering

Inputs are buffered for 6 frames (100ms) to allow execution during recovery:

```luau
type InputBuffer = {
    queue: {{action: string, timestamp: number, frame: number}},
    bufferWindow: number, -- 6 frames
}
```

---

## Stamina System

Stamina gates aggressive play and rewards resource management.

### Stamina Costs

| Action | Cost |
|--------|------|
| Light Attack | 8 |
| Heavy Attack | 15 |
| Dash | 12 |
| Roll | 15 |
| Backstep | 10 |
| Block (per hit absorbed) | Variable (= attacker's chip damage) |
| Sprint | 2/second |
| Parry (attempt) | 5 |
| Ultimate | 0 (uses Ultimate Meter) |

### Stamina Rules

- Max stamina: 100
- Regen rate: 12/second (stops during sprint, attacking, blocking)
- Regen delay after action: 1.5 seconds
- At 0 stamina: cannot attack, block, or dodge (vulnerable)
- Guard break occurs when blocking at 0 stamina

---

## Poise System

Poise determines resistance to stagger.

```luau
type PoiseData = {
    maxPoise: number,       -- character-specific
    currentPoise: number,
    regenRate: number,      -- poise/second when not hit
    regenDelay: number,     -- seconds before regen starts
}
```

- Light attacks deal 20 poise damage
- Heavy attacks deal 40 poise damage
- When poise reaches 0: character is staggered regardless of state
- Super armor: poise cannot reach 0 during armor frames
- Poise regens to full after 3 seconds without taking poise damage

---

## Blocking & Parry

### Block

- Reduces damage by 80%
- Costs stamina per hit blocked (chip damage)
- Pushes blocker back slightly (block pushback)
- Heavy attacks deal extra block damage
- Guard breaks if stamina depletes while blocking

### Parry

- 6-frame window (frames 1-6 of parry animation)
- Successful parry: attacker enters ParryStunned state (30 frames)
- Defender enters Riposte window: guaranteed punish
- Perfect parry (frames 1-3): zero stamina cost, extra hitstun
- Failed parry: 20 frame recovery (punishable)

### Guard Break

- Triggered by: depleting opponent's stamina while they block
- Guard break state: 45 frames of vulnerability
- Allows execution attack or full combo

---

## Execution System

- Available when opponent is in GuardBroken or low HP + staggered
- Cinematic attack with unique animation per character
- Deals massive damage (50% max HP)
- Both players locked in animation (interruptible by third party in FFA)
- 2-second window to input execution command

---

## Ultimate System

- Ultimate meter builds from: dealing damage, taking damage, parrying
- Full meter: 100 units
- Gain rates: 1 per damage dealt, 0.5 per damage taken, 10 per parry
- Ultimate is character-specific (unique ability)
- Cannot be interrupted once activated (super armor during startup)
- Cooldown: meter resets to 0 after use

---

## Hit Detection

### Hitbox System

- Hitboxes are spatial regions attached to weapon/limb during active frames
- Server creates hitbox on validated attack
- Hitbox checks against all opponent hurtboxes each tick
- First valid hit registers (no multi-hit on same swing unless designed)

### Hurtbox System

- Hurtboxes are persistent collision regions on character
- Head: 1.5x damage multiplier
- Body: 1.0x damage multiplier
- Legs: 0.8x damage multiplier

### Hit Priority

When two attacks collide simultaneously:

1. Heavy beats Light
2. Equal priority: both trade (both take damage)
3. Armor moves ignore hit of lower priority
4. Parry beats all attacks

---

## Knockback & Physics

### Knockback Formula

```
knockbackForce = baseDamage * knockbackMultiplier * (1 - poiseResistance)
knockbackDirection = attackDirection * knockbackForce
```

### Wall Collision

- If knockback sends player into wall within 5 studs
- Wall bounce: bounce off at 60% force, enter Staggered state
- Wall splat: if force > threshold, stick to wall for 20 frames

### Ground Bounce

- If launched player hits ground with downward velocity > threshold
- Bounce up at 40% original launch height
- One bounce allowed per combo

---

## Hit Effects

| Effect | Trigger | Duration |
|--------|---------|----------|
| Hitstop | Any confirmed hit | 3-6 frames (scales with damage) |
| Camera shake | Heavy hit, finisher | 0.1-0.3 seconds |
| Hit spark | Any confirmed hit | Instantaneous VFX |
| Screen flash | Critical hit, parry | 1-2 frames |
| Slow motion | Execution, ultimate kill | 0.5-1.0 seconds |

---

## Anti-Infinite Measures

1. **Juggle limit** — Max 4 hits in air
2. **Damage scaling** — Reduces per consecutive hit
3. **Gravity scaling** — Opponent falls faster each juggle hit
4. **Ground tech** — Player can tech (recover) after ground bounce with timing
5. **Burst** — Once per round, break out of combo at cost of 50% Ultimate meter
6. **Infinite prevention** — Same move cannot hit more than 2x consecutively in combo
