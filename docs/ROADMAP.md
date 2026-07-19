# AnimeArena — Development Roadmap

## Phased Development Plan

Each phase produces a **playable milestone**. No phase advances until the previous phase is stable and tested.

---

## Phase 1: Project Scaffold & Bootstrap

**Goal:** Rojo-compatible project structure, custom modular framework initialized, type system established, build pipeline working.

### Deliverables
- [ ] `default.project.json` (Rojo config)
- [ ] `wally.toml` with dependencies (React-Lua, ProfileStore, etc.)
- [ ] `selene.toml` and `stylua.toml` for code quality
- [ ] `.luaurc` with strict type checking
- [ ] Folder structure matching architecture doc
- [ ] Custom framework core:
  - [ ] `Container.luau` (dependency injection)
  - [ ] `ServiceBase.luau` (server service base class)
  - [ ] `ControllerBase.luau` (client controller base class)
  - [ ] `Signal.luau` (event system)
  - [ ] `Network.luau` (remote abstraction with validation)
- [ ] Server bootstrap (`init.server.luau`)
- [ ] Client bootstrap (`init.client.luau`)
- [ ] All shared Type definitions
- [ ] All shared Enum definitions
- [ ] Utility modules (ObjectPool, MathUtil, TableUtil, RateLimiter, Validator)
- [ ] Constants module

### Exit Criteria
- Rojo syncs cleanly to Roblox Studio
- Framework starts on both server and client without errors
- Types pass strict mode checking
- DI container resolves services correctly

---

## Phase 2: Core Combat Engine

**Goal:** A single player can attack, block, parry, and dodge against a training dummy. Frame data drives all timing. Combat state machine prevents invalid actions.

### Deliverables
- [ ] `CombatStateMachine.luau` — all states, transitions, guards
- [ ] `ComboStateMachine.luau` — combo routes, cancel windows
- [ ] `FrameDataEngine.luau` — startup/active/recovery processing
- [ ] `InputBuffer.luau` — 6-frame input buffering
- [ ] `StaminaManager.luau` — costs, regen, depletion
- [ ] `PoiseManager.luau` — poise damage, stagger threshold
- [ ] `HitboxSystem.luau` — spatial hit detection
- [ ] `HurtboxSystem.luau` — character collision regions
- [ ] `KnockbackSystem.luau` — launch, juggle, wall/ground bounce
- [ ] `DamageCalculator.luau` — scaling, multipliers, armor
- [ ] Server `CombatService.luau` — orchestrates combat
- [ ] Client `CombatController.luau` — input handling, prediction
- [ ] Training dummy entity for testing

### Exit Criteria
- Player can execute full combo (Light × 3, Light → Heavy)
- Blocking reduces damage, costs stamina
- Parry window works (6 frames)
- Dodge has I-frames
- Stamina gates actions when depleted
- Frame data visibly affects timing
- No exploitable states (infinite combos, stuck states)

---

## Phase 3: Networking & Server Authority

**Goal:** Two players can fight with server-authoritative hit detection. Lag compensation allows fair play up to 150ms latency.

### Deliverables
- [ ] Remote event architecture (all attack/block/dodge remotes)
- [ ] Server-side input validation
- [ ] Rate limiting per remote
- [ ] Position history buffer (lag compensation)
- [ ] Hit validation with rewind
- [ ] Client prediction system
- [ ] Server reconciliation
- [ ] State synchronization (60Hz tick)
- [ ] Delta compression for state updates
- [ ] Latency measurement system

### Exit Criteria
- Two players can fight from different clients
- Hits register fairly regardless of latency (up to 150ms)
- Exploited clients (speed/teleport) are detected and rejected
- No desync on combat state between players
- Smooth visual interpolation for opponent movement

---

## Phase 4: Movement Controller

**Goal:** Fluid, responsive character movement with all movement options integrated into combat states.

### Deliverables
- [ ] `MovementController.luau` — core movement
- [ ] `MomentumSystem.luau` — acceleration, deceleration
- [ ] Walk / Run / Sprint
- [ ] Dash (directional, costs stamina)
- [ ] Roll (I-frames, directional)
- [ ] Backstep
- [ ] Sidestep
- [ ] Double jump
- [ ] Fast fall
- [ ] Jump cancel
- [ ] Slide
- [ ] Wall jump
- [ ] Ledge grab
- [ ] Vault
- [ ] Camera-relative input translation
- [ ] Combat state integration (can't dash while attacking, etc.)

### Exit Criteria
- Movement feels responsive (< 50ms perceived)
- All movement options cancel correctly into/from combat
- Momentum system creates satisfying weight
- Works on controller and keyboard
- Server validates movement speed

---

## Phase 5: Weapon Framework

**Goal:** Data-driven weapon system where new weapons are added by creating a config module with zero engine changes.

### Deliverables
- [ ] `WeaponBase.luau` — base class for all weapons
- [ ] `WeaponRegistry.luau` — loads and indexes weapon configs
- [ ] Weapon data schema and type
- [ ] 3 initial weapon configs:
  - [ ] Katana (fast, medium range)
  - [ ] Greatsword (slow, long range, armor)
  - [ ] Dual Swords (very fast, short range, combo-heavy)
- [ ] Weapon switching system
- [ ] Weapon-specific frame data
- [ ] Weapon-specific combo routes
- [ ] Weapon-specific animations (placeholder)
- [ ] Special skill system (per weapon)
- [ ] Ultimate ability framework

### Exit Criteria
- Katana, Greatsword, and Dual Swords all feel distinct
- Adding a new weapon requires only a data module
- Special skills work with cooldowns
- Ultimate builds meter and activates correctly

---

## Phase 6: Character Framework

**Goal:** Original character archetypes with unique abilities, stats, and personalities. Architecture supports unlimited future characters. 3 fully implemented at launch.

### Deliverables
- [ ] `CharacterBase.luau` — base class
- [ ] `CharacterRegistry.luau` — loads and indexes characters
- [ ] Character data schema
- [ ] 3 fully implemented launch characters:
  - [ ] Crimson Demon Swordsman (Dual Swords — fast, stylish)
  - [ ] Storm Ronin (Longsword — lightning-infused, balanced)
  - [ ] Holy Knight Commander (Greatsword — defensive, armored)
- [ ] 7 placeholder character data definitions (for future implementation)
- [ ] Passive ability system
- [ ] Character-specific ultimate
- [ ] Character stat modifiers (speed, HP, stamina, poise)
- [ ] Character selection flow

### Exit Criteria
- Each of the 3 launch characters feels meaningfully different
- Passives affect gameplay
- Ultimates are impactful and fair
- Characters have clear strengths/weaknesses
- Placeholder characters load without error (just missing animations/VFX)

---

## Phase 7: Animation System

**Goal:** Smooth, cancelable animations driven by state machines with proper blending.

### Deliverables
- [ ] `AnimationStateMachine.luau` — manages animation states
- [ ] Animation blending system
- [ ] Cancel system (animation interrupts)
- [ ] Root motion handling
- [ ] Weapon-specific animation sets
- [ ] Combat idle, breathing, injury variations
- [ ] Parry, execution, ultimate cinematic animations
- [ ] Animation priority management
- [ ] Hit reaction animations
- [ ] Ragdoll integration

### Exit Criteria
- Animations blend smoothly between states
- Cancels are visually clean (no snapping)
- Each weapon has distinct animation set
- Hit reactions match damage direction

---

## Phase 8: Camera System

**Goal:** Dynamic combat camera that enhances readability and dramatic moments.

### Deliverables
- [ ] `CameraController.luau` — core camera
- [ ] Lock-on system (target nearest enemy)
- [ ] Free camera mode
- [ ] Soft lock (gentle tracking)
- [ ] Target switching (tab/stick flick)
- [ ] Camera collision (no clipping through walls)
- [ ] Dynamic FOV (wider during sprint)
- [ ] Camera shake (on hit, configurable)
- [ ] Ultimate camera (cinematic zoom)
- [ ] Execution camera (close-up angles)
- [ ] Kill cam (brief replay of kill from attacker POV)

### Exit Criteria
- Lock-on stays reliable during fast combat
- Camera never clips through geometry
- Dramatic moments (ult, execution) feel cinematic
- Camera doesn't cause motion sickness

---

## Phase 9: UI/HUD

**Goal:** Clean, animated React-Lua UI for all screens. HUD is minimal during combat.

### Deliverables
- [ ] React-Lua integration and mount system
- [ ] UI state store (reactive state management)
- [ ] Custom hooks (usePlayerState, useCombatState, useSettings)
- [ ] Theme system (colors, fonts, sizing)
- [ ] HUD: HP, stamina, ult meter, combo counter
- [ ] Damage numbers (floating, scaling)
- [ ] Hit direction indicators
- [ ] Kill feed
- [ ] Match timer and score
- [ ] Main menu
- [ ] Character select screen
- [ ] Settings menu
- [ ] Ranked menu with rank display
- [ ] Match results / MVP screen
- [ ] Scoreboard (hold Tab)
- [ ] Mobile virtual joystick and buttons
- [ ] Controller navigation support
- [ ] UI animation system (spring-based transitions)
- [ ] Responsive scaling

### Exit Criteria
- HUD is readable without being distracting
- All menus are navigable with controller
- Mobile layout is playable
- Animations feel polished
- React-Lua components are reusable and composable

---

## Phase 10: VFX System

**Goal:** Impactful visual effects for all combat events, optimized with object pooling.

### Deliverables
- [ ] Slash trails (weapon-specific)
- [ ] Hit sparks (contact point)
- [ ] Parry flash (bright flash + ring)
- [ ] Block impact (shield ripple)
- [ ] Shockwaves (heavy hits, ult)
- [ ] Dust/wind (dashes, landings)
- [ ] Element effects (fire, ice, lightning, dark)
- [ ] Ultimate VFX (per character)
- [ ] Execution VFX
- [ ] Object pool for all particle emitters
- [ ] LOD system (reduce particles at distance)
- [ ] Blood toggle (on/off in settings)

### Exit Criteria
- Every attack has satisfying visual feedback
- Performance stays above 60 FPS with max particles
- Object pool prevents GC spikes
- Effects are readable (don't obscure gameplay)

---

## Phase 11: Audio System

**Goal:** Dynamic audio that responds to combat events and enhances immersion.

### Deliverables
- [ ] `AudioController.luau` — manages all sound
- [ ] Sound pool (pre-loaded, reused)
- [ ] Combat SFX: sword clash, hit, heavy hit, parry
- [ ] Movement SFX: footsteps (surface-aware), dash whoosh
- [ ] UI SFX: button click, menu transition
- [ ] Ambient system (per-map background)
- [ ] Dynamic combat music (layers intensity with action)
- [ ] Music transitions (menu → combat → victory)
- [ ] Spatial audio (3D positioned sounds)
- [ ] Volume mixing (combat > ambient > music)

### Exit Criteria
- Every action has an audio response
- Music adapts to match intensity
- No audio clipping or overlap issues
- Volume settings respected

---

## Phase 12: AI Bots

**Goal:** AI opponents that can fight at multiple difficulty levels for training and bot-fill.

### Deliverables
- [ ] `AIController.luau` — decision-making core
- [ ] Difficulty levels: Easy, Medium, Hard, Expert
- [ ] Basic behavior: approach, attack, block
- [ ] Parry logic (timing-based, difficulty scales accuracy)
- [ ] Combo execution (follows combo routes)
- [ ] Spacing awareness (maintain optimal range)
- [ ] Whiff punishment (attack when opponent misses)
- [ ] Bait patterns (fake openings)
- [ ] Anti-pattern (doesn't repeat same sequence)
- [ ] Team AI (2v2, 3v3 coordination)
- [ ] Boss AI (for Boss Rush mode)
- [ ] Training mode integration (bot follows user settings)

### Exit Criteria
- Easy bots are beatable by new players
- Expert bots challenge experienced players
- Bots don't cheat (no reading inputs directly)
- Bots feel like fighting a human (varied patterns)

---

## Phase 13: Matchmaking & Game Modes

**Goal:** Players can queue for matches and play all game modes. Arena framework loads maps dynamically.

### Deliverables
- [ ] `MatchmakingService.luau` — queue management
- [ ] MMR-based matching (±200 range, expands over time)
- [ ] Queue UI (estimated wait time)
- [ ] Game modes: 1v1, 2v2, 3v3, FFA
- [ ] Tournament mode (bracket system)
- [ ] Custom match creation
- [ ] Private server support
- [ ] Training mode (free practice)
- [ ] Boss Rush mode
- [ ] Endless Survival mode
- [ ] Match lifecycle (ready check → countdown → fight → results)
- [ ] Arena framework:
  - [ ] Dynamic arena loading from config
  - [ ] Arena rotation system
  - [ ] Spawn point definitions
  - [ ] Lighting presets per arena
  - [ ] Ambient audio per arena
  - [ ] Environmental hazard hooks (future-ready)
- [ ] 3 launch arenas:
  - [ ] Training Grounds (simple, no hazards)
  - [ ] Ancient Temple (medium, elevation changes)
  - [ ] Frozen Citadel (complex, multiple levels)
- [ ] Bot backfill (fill empty slots with AI)
- [ ] Kill Cam system
- [ ] Spectator mode
- [ ] Match highlight camera

### Exit Criteria
- Queuing finds a match within 60 seconds (with bots if needed)
- All game modes playable
- MMR matching produces fair fights
- Custom matches work for private groups
- All 3 arenas load and play correctly
- Adding new arenas requires only a data config
- Kill cam plays on death
- Spectator mode works for eliminated players

---

## Phase 14: Progression & Data

**Goal:** Players earn XP, level up, unlock content, and have persistent profiles. Battle Pass architecture ready.

### Deliverables
- [ ] ProfileStore integration (full schema)
- [ ] Player leveling (XP → level up)
- [ ] Character mastery (XP per character)
- [ ] Weapon mastery (XP per weapon)
- [ ] Achievement system (conditions → rewards)
- [ ] Daily quests (3 per day, auto-generated)
- [ ] Weekly quests (3 per week)
- [ ] Battle Pass architecture:
  - [ ] Tier progression (100 tiers)
  - [ ] Free track rewards
  - [ ] Premium track rewards
  - [ ] Season configuration
  - [ ] XP requirements per tier
  - [ ] UI framework for battle pass display
  - [ ] No actual seasonal content (mock rewards)
- [ ] Reward claiming
- [ ] XP sources (match completion, kills, objectives, quests)
- [ ] Daily login rewards framework

### Exit Criteria
- Data persists across sessions
- No data loss on disconnect/crash
- Progression feels rewarding (appropriate XP rates)
- Quests generate variety
- Battle Pass architecture works end-to-end with mock data
- Adding actual BP content requires only data definitions

---

## Phase 15: Ranked System

**Goal:** Competitive ladder with meaningful progression and season resets.

### Deliverables
- [ ] MMR algorithm (Elo-based with K-factor adjustment)
- [ ] Rank tiers: Bronze → Silver → Gold → Platinum → Diamond → Master → Mythic
- [ ] Placement matches (10 games)
- [ ] LP system (gain/lose LP, promote/demote at thresholds)
- [ ] Rank decay (inactivity penalty above Platinum)
- [ ] Win/loss streak bonuses
- [ ] Leaderboards (top 100 global, friends)
- [ ] Season system (3-month seasons)
- [ ] Season rewards (based on peak rank)
- [ ] Ranked statistics dashboard
- [ ] Anti-smurf detection

### Exit Criteria
- Ranks accurately reflect player skill
- Climbing feels achievable but challenging
- Season resets don't feel punishing (soft reset)
- Leaderboards update in real-time

---

## Phase 16: Cosmetics & Shop

**Goal:** Complete monetization framework with all systems ready. Mock products acceptable — no actual purchasable content required.

### Deliverables
- [ ] Monetization framework:
  - [ ] GamePass integration (Roblox API)
  - [ ] DevProduct integration (Roblox API)
  - [ ] Premium currency (Robux-purchased)
  - [ ] Soft currency (gameplay-earned)
  - [ ] Transaction logging and validation
- [ ] Shop system:
  - [ ] Featured store (rotating items)
  - [ ] Daily deals
  - [ ] Starter bundles
  - [ ] Category browsing
- [ ] Cosmetic systems:
  - [ ] Skin system (weapon skins, character skins)
  - [ ] Emotes (equipped, usable out of combat)
  - [ ] Titles (displayed with name)
  - [ ] Banners (profile card)
  - [ ] Kill effects (visual on eliminating opponent)
  - [ ] Victory poses (end of match)
  - [ ] Trails (movement particles)
- [ ] Daily rewards system
- [ ] Inventory management UI
- [ ] Purchase confirmation flow
- [ ] Mock product catalog

### Exit Criteria
- Cosmetics are purely visual (no gameplay advantage)
- Full purchase flow works end-to-end (with mock products)
- Inventory displays all owned items
- Equipped cosmetics visible in-game
- GamePass and DevProduct callbacks work correctly
- Adding real products requires only data definitions

---

## Phase 17: Optimization

**Goal:** Stable 60 FPS on mobile/console, 120+ FPS on PC. Minimize CPU, memory, network, and GC pressure.

### Deliverables
- [ ] Streaming Enabled configuration
- [ ] LOD system for character models
- [ ] Object pooling audit (all VFX, projectiles, UI elements)
- [ ] Memory profiling and optimization
- [ ] Network bandwidth optimization
- [ ] Draw call reduction
- [ ] Particle budget system
- [ ] Mobile-specific optimizations (reduced VFX, lower LOD)
- [ ] Console optimization
- [ ] Frame time profiling and hotspot elimination
- [ ] Garbage collection minimization (avoid table churn)
- [ ] Script performance audit
- [ ] Remote event batching optimization

### Exit Criteria
- 120+ FPS on modern PC
- 60 FPS stable on mobile (mid-range device)
- 60 FPS stable on console
- No frame spikes during combat
- Memory usage stays flat over time (no leaks)
- Network traffic under budget (< 50KB/s per player)

---

## Phase 18: Anti-Cheat

**Goal:** Layered security that prevents common exploits without false positives.

### Deliverables
- [ ] Speed hack detection (velocity validation)
- [ ] Teleport detection (position delta checks)
- [ ] Fly detection (ground contact validation)
- [ ] Macro detection (input timing analysis)
- [ ] Remote abuse detection (impossible state transitions)
- [ ] Economy exploit prevention (server-side validation)
- [ ] Inventory manipulation prevention
- [ ] Damage validation (server-calculated only)
- [ ] Cooldown enforcement (server timers)
- [ ] Logging and flagging system
- [ ] Ban system (temp → permanent escalation)
- [ ] Report system (player reports)

### Exit Criteria
- Common exploits (speed, teleport, fly) detected within 2 seconds
- Zero false positives on legitimate high-skill play
- Flagged players logged for review
- No client-side values affect outcomes

---

## Phase 19: Testing

**Goal:** Automated and manual test coverage for critical systems.

### Deliverables
- [ ] Unit tests for combat state machine
- [ ] Unit tests for frame data engine
- [ ] Unit tests for damage calculator
- [ ] Unit tests for MMR algorithm
- [ ] Integration tests for remote validation
- [ ] Integration tests for data persistence
- [ ] Stress test for matchmaking
- [ ] Performance benchmark suite
- [ ] Network simulation (artificial latency testing)
- [ ] Exploit test cases (verify rejection)
- [ ] Test documentation

### Exit Criteria
- All critical paths have test coverage
- Tests pass on CI (or manual run)
- Known edge cases documented and tested

---

## Phase 20: Documentation

**Goal:** Complete documentation for maintenance and onboarding.

### Deliverables
- [ ] API documentation for all services/controllers
- [ ] Module dependency diagram
- [ ] Data flow diagrams
- [ ] Combat design document (frame data tables)
- [ ] Networking protocol reference
- [ ] Content creation guide (how to add weapons/characters)
- [ ] Deployment checklist
- [ ] Performance tuning guide
- [ ] Known issues and workarounds
- [ ] Changelog

### Exit Criteria
- A new developer can understand the codebase from docs alone
- All public APIs documented with types and examples
- Content creators can add weapons/characters without engineering help

---

## Timeline Estimate

| Phase | Effort (Solo + AI) | Cumulative |
|-------|-------------------|-----------|
| Phase 1 | 1 day | 1 day |
| Phase 2 | 3-4 days | ~5 days |
| Phase 3 | 3-4 days | ~9 days |
| Phase 4 | 2-3 days | ~12 days |
| Phase 5 | 2 days | ~14 days |
| Phase 6 | 2-3 days | ~17 days |
| Phase 7 | 2 days | ~19 days |
| Phase 8 | 1-2 days | ~21 days |
| Phase 9 | 3 days | ~24 days |
| Phase 10 | 2 days | ~26 days |
| Phase 11 | 1-2 days | ~28 days |
| Phase 12 | 3 days | ~31 days |
| Phase 13 | 3 days | ~34 days |
| Phase 14 | 2 days | ~36 days |
| Phase 15 | 2 days | ~38 days |
| Phase 16 | 2 days | ~40 days |
| Phase 17 | 2-3 days | ~43 days |
| Phase 18 | 2 days | ~45 days |
| Phase 19 | 2-3 days | ~48 days |
| Phase 20 | 1-2 days | ~50 days |

**Total estimated: ~50 working days** (assuming AI-assisted development with focused sessions)

---

## Milestone Markers

| Milestone | Phase | What's Playable |
|-----------|-------|-----------------|
| **Alpha** | After Phase 4 | Single player can fight dummy with movement |
| **Pre-Beta** | After Phase 8 | Two players can fight (all systems basic) |
| **Beta** | After Phase 13 | Full game loop (queue → fight → reward) |
| **Release Candidate** | After Phase 18 | Production-ready with security |
| **Launch** | After Phase 20 | Documented, tested, optimized |
