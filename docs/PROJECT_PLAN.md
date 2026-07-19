# AnimeArena — Project Plan

## Overview

AnimeArena is an original AAA-quality Roblox competitive melee PvP game built on skill-based combat mechanics. The game rewards timing, positioning, spacing, reads, mind games, stamina management, and weapon mastery. There is zero random chance in combat outcomes.

---

## Vision Statement

A fighting game that feels like a AAA action title running on Roblox — tight frame data, server-authoritative hit validation, deep combo systems, and a roster of original archetypes each with distinct playstyles.

---

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| Roblox Studio | Game engine / runtime |
| Luau | Programming language (strict mode) |
| Custom Modular Framework | Service/Controller architecture (Knit-inspired, no Knit) |
| React-Lua | UI component framework |
| Rojo | External file sync for version control |
| Wally | Package manager for dependencies |
| ProfileStore | Data persistence abstraction |
| Selene | Linter |
| StyLua | Code formatter |

---

## Design Principles

1. **Server Authority** — The server is the single source of truth for all gameplay state. The client predicts and renders, but never decides outcomes.
2. **Data-Driven Design** — Weapons, characters, frame data, and combo routes are defined as pure data in ModuleScripts. Adding content never requires modifying engine code.
3. **Component Architecture** — Systems are composed of small, testable components rather than monolithic scripts.
4. **Fixed-Tick Simulation** — Combat runs at a fixed tick rate (60Hz) decoupled from render frame rate for deterministic behavior.
5. **Zero Trust Client** — Every remote event is validated. Rate limiting, sanity checks, and state verification on all inputs.

---

## Target Platforms

| Platform | Target FPS | Priority |
|----------|-----------|----------|
| PC | 120 FPS | Primary |
| Console (Xbox) | 60 FPS | Secondary |
| Mobile | 60 FPS | Tertiary |

---

## Team Simulation (Solo Dev with AI)

Since this is being built by a single developer with AI assistance, the roadmap is structured for incremental delivery. Each phase produces a playable milestone.

---

## Success Criteria

- [ ] Combat feels responsive at < 100ms perceived input latency
- [ ] Server authoritative with no client-exploitable combat outcomes
- [ ] 10 unique characters with distinct playstyles
- [ ] Ranked matchmaking with MMR
- [ ] 60 FPS stable on mobile, 120 FPS on PC
- [ ] All game modes functional (1v1, 2v2, 3v3, FFA, Tournament)
- [ ] Data persistence with zero data loss
- [ ] Anti-cheat covering speed, teleport, fly, and macro exploits

---

## Scope Management

### Phase 1 (MVP — Playable Combat)
- 3 launch characters (Crimson Demon Swordsman, Storm Ronin, Holy Knight Commander)
- Core combat (attacks, blocking, parry, dodge)
- 1v1 mode
- Basic React-Lua HUD
- Server authority
- Training Grounds arena

### Phase 2 (Content Expansion)
- All movement options
- VFX and audio
- Ancient Temple + Frozen Citadel arenas
- Training mode
- Kill Cam + Spectator Mode

### Phase 3 (Competitive)
- Ranked system
- Matchmaking
- Leaderboards
- Anti-cheat hardening

### Phase 4 (Live Service)
- Battle Pass architecture (no seasonal content)
- Cosmetics framework
- Shop (GamePasses, DevProducts, currencies)
- Monetization framework (mock products)

---

## Risk Register

| ID | Risk | Probability | Impact | Mitigation |
|----|------|-------------|--------|------------|
| R1 | Scope creep | High | Critical | Strict phase gates. No phase advances without prior phase stable. |
| R2 | Roblox networking latency | High | High | Client prediction + reconciliation. Accept visual tradeoffs. |
| R3 | Combat doesn't feel good | Medium | Critical | Prototype combat first. Iterate on frame data before building content. |
| R4 | Performance on low-end | Medium | High | Object pooling, LOD, aggressive culling from day 1. |
| R5 | Data store failures | Low | Critical | ProfileStore with session locking, retry logic, backup keys. |
| R6 | Exploits in production | High | High | Server validates everything. Layered anti-cheat. |

---

## Deliverable Schedule

| Phase | Deliverable | Status |
|-------|------------|--------|
| 1 | Project scaffold + Knit bootstrap | Pending |
| 2 | Core combat engine | Pending |
| 3 | Networking layer | Pending |
| 4 | Movement controller | Pending |
| 5 | Weapon framework | Pending |
| 6 | Character framework | Pending |
| 7 | Animation system | Pending |
| 8 | Camera system | Pending |
| 9 | UI/HUD | Pending |
| 10 | VFX system | Pending |
| 11 | Audio system | Pending |
| 12 | AI bots | Pending |
| 13 | Matchmaking | Pending |
| 14 | Progression | Pending |
| 15 | Ranked | Pending |
| 16 | Cosmetics | Pending |
| 17 | Optimization | Pending |
| 18 | Anti-cheat | Pending |
| 19 | Testing | Pending |
| 20 | Documentation | Pending |
