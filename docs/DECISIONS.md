# AnimeArena — Design Decisions Record

This document captures all confirmed design decisions for the project. Reference this before making implementation choices.

---

## Decision 1: UI Framework → React-Lua

**Choice:** React-Lua (formerly Roact)

**Reasoning:**
- Component architecture
- Better maintainability
- Easier animations via reactive state
- Scalable state management (hooks, context, reducers)
- Large ecosystem of patterns

**Rejected:** Fusion (unless compelling technical advantage found later)

---

## Decision 2: Launch Characters → 3 Fully Implemented

**Choice:** Build complete framework, fully implement only 3 characters.

**Launch Characters:**
1. Crimson Demon Swordsman (fast, dual-sword, stylish)
2. Storm Ronin (lightning longsword, balanced)
3. Holy Knight Commander (greatsword, defensive)

**Remaining 7:** Exist as data definitions/placeholders. Architecture supports unlimited future characters without engine modifications.

---

## Decision 3: Battle Pass → Architecture Only

**Choice:** Build full architecture, no actual seasonal content.

**Includes:**
- XP system
- Tier progression (100 tiers)
- Reward definitions (type-safe schema)
- Premium/free tracks
- Season configuration
- UI framework

**Does NOT include:** Actual seasonal content, real rewards, or live rotation.

---

## Decision 4: Replay System → Not V1

**Choice:** No full replay system in Version 1.

**Implemented instead:**
- Kill Cam (brief replay of death from attacker perspective)
- Match Highlight Camera (end-of-match)
- Spectator Mode (follow alive players after elimination)

**Architecture note:** Design state snapshots so replay can be added later without major refactoring.

---

## Decision 5: Performance Target

**Primary targets:**
- 60 FPS stable on mobile (mid-range)
- 60 FPS stable on console
- 120+ FPS on PC when hardware allows

**Optimization priorities (in order):**
1. CPU usage
2. Memory
3. Network traffic
4. Object pooling
5. StreamingEnabled
6. Minimal garbage collection

---

## Decision 6: Framework → Custom (No Knit)

**Choice:** Custom modular architecture inspired by Knit, but purpose-built.

**Structure:**
```
Client/
Server/
Shared/
  Services
  Controllers
  Components
  Managers
  Utilities
  Networking
  Configuration
```

**Principles:**
- Dependency injection where appropriate
- No singleton abuse
- No circular dependencies
- Strict typing everywhere
- Testable in isolation

---

## Decision 7: Monetization → Full Framework

**Choice:** Implement complete monetization framework with mock products.

**Includes:**
- GamePasses (Roblox API)
- DevProducts (Roblox API)
- Cosmetic shop
- Premium currency (Robux-purchased)
- Soft currency (gameplay-earned)
- Daily rewards
- Starter bundles
- Featured store (rotating)

**Does NOT include:** Actual purchasable content. Mock products acceptable.

---

## Decision 8: Maps/Arenas → Dynamic Framework + 3 Launch Arenas

**Choice:** Complete arena framework with 3 arenas at launch.

**Launch Arenas:**
1. Training Grounds (simple, no hazards, practice)
2. Ancient Temple (medium complexity, elevation changes)
3. Frozen Citadel (complex, multiple levels)

**Framework supports:**
- Dynamic loading from configuration
- Arena rotation
- Spawn definitions
- Lighting presets
- Ambient audio
- Environmental hazards (future-ready)

**Adding new arenas requires only a data config — no matchmaking or combat system changes.**

---

## Development Process Rules

1. Explain design decisions before generating code.
2. Generate only one phase at a time.
3. Ensure it compiles.
4. Explain how to test it.
5. List possible bugs.
6. Wait for approval before next phase.
7. Never rewrite existing files unless necessary (explain why first).
