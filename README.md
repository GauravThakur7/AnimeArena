# AnimeArena

An original AAA-quality Roblox competitive melee PvP game. Skill-based combat rewarding timing, positioning, spacing, reads, and mind games.

## Tech Stack

- **Engine:** Roblox Studio
- **Language:** Luau (strict mode)
- **Framework:** Custom modular architecture (DI-based, Knit-inspired)
- **UI:** React-Lua
- **Sync:** Rojo
- **Packages:** Wally
- **Data:** ProfileStore
- **Linting:** Selene
- **Formatting:** StyLua

## Getting Started

### Prerequisites

- [Rojo](https://rojo.space/) (v7+)
- [Wally](https://wally.run/)
- [Selene](https://kampfkarren.github.io/selene/) (optional)
- [StyLua](https://github.com/JohnnyMorganz/StyLua) (optional)
- Roblox Studio

### Setup

```bash
# Install dependencies
wally install

# Start Rojo sync
rojo serve

# In Roblox Studio: Connect to Rojo (localhost:34872)
```

### Project Structure

```
src/
├── Server/         → ServerScriptService (services, server components)
├── Client/         → StarterPlayerScripts (controllers, client components)
├── Shared/         → ReplicatedStorage (framework, types, enums, data, utils)
└── UI/             → ReplicatedFirst (React-Lua UI apps and components)
```

## Architecture

See `docs/ARCHITECTURE.md` for full system design.

- **Server-authoritative** combat with client prediction
- **60Hz fixed-tick** simulation
- **Dependency injection** container (no singletons)
- **Data-driven** weapons, characters, and arenas
- **React-Lua** component UI with reactive state

## Development

Each phase is developed incrementally. See `docs/ROADMAP.md` for the full plan.

## License

Proprietary. All rights reserved.
