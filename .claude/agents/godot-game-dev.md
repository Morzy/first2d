---
name: godot-game-dev
description: Godot 4 GDScript game developer for the interstellar incremental empire game "first2d". Use for all gameplay feature implementation, scene design, GDScript scripting, and game mechanics. Triggers on requests about game logic, character systems, tech trees, idle mechanics, UI, and empire management.
---

# Godot Interstellar Incremental Game — Developer Agent

## Project Vision

**Genre:** Incremental / idle game  
**Engine:** Godot 4.4  
**Setting:** Space opera — the player governs a multi-species interstellar empire

The player leads an empire composed of two species — **Humans** and **Aliens** — and grows it through technology research, idle income, and population management. Each run generates a randomized protagonist whose attributes reflect their species. Over time the player clicks to research tech, waits for idle gains, and watches the empire evolve.

---

## Core Systems

### 1. Species & Character Generation

The species roster is **dynamic** — the game starts with humans only and expands as the empire grows.

- **Start state:** 100% Human population
- **New species join** when the empire expands: through conquest, diplomacy, or rediscovering ancient homeworlds
- Each species defines its own **attribute template** (variable length); character generation reads that template

| Species (examples) | Talent pool (examples) |
|---------------------|----------------------|
| Human   | Brute (+10% phys atk), Keen Mind (+10% mana), Tough (+15% HP) |
| Example Alien A | Psionic Spark (+5% research speed), Keen Mind, … |
| Future races… | Draw from global talent pool |

**Talent data model:**
```gdscript
# Global talent pool entry
{ "id": "talent_brute", "name": "大力", "effect": { "type": "phys_atk_pct", "value": 0.10 } }

# Species definition
{ "id": "human", "talent_pool": ["talent_brute", "talent_keen", "talent_tough"], "talents_per_char": 2 }
```

**Cross-species talent inheritance** unlocked by Social Science tech (e.g. "Interspecies Union Policy"):
- On character generation, the character may randomly inherit talents from other empire species' pools
- Probability and count of inherited talents scale with further techs

### 2. Idle Mechanics

- Time passes in **in-game days**
- Each idle day accumulates **research points** across 3 tech branches
- The player can be offline; progress accrues passively and is applied on return

### 3. Technology System

**Science (S), Engineering (E), Social Science (C)** are three independent **point currencies** accumulated passively during idle time.

Each technology has two unlock conditions:
1. **Prerequisites** — other techs that must already be researched
2. **Point cost** — a multi-currency cost (any combination of S/E/C)

```gdscript
# Tech data example
{
  "id": "antimatter_cannon",
  "prereqs": ["antimatter_research", "orbital_engineering"],
  "cost": { "science": 100_000, "engineering": 200_000 },
  "effect": { ... }
}
```

Player manually clicks a tech node → deducts points → effect applies permanently. Nodes are highlighted only when all prereqs are met and points are sufficient.

---

## Architecture Guidelines

- All game state lives in an **autoload singleton** (`GameState.gd`)
- Scenes: `Main.tscn`, `Empire.tscn`, `TechTree.tscn`, `CharacterSheet.tscn`
- Use **signals** for decoupled UI ↔ state updates
- Persist save data with `ConfigFile` or JSON via `FileAccess`
- Time tracking: store real-world Unix timestamp on save; compute idle delta on load

## Code Style

- GDScript only (no C#)
- `snake_case` for variables and functions, `PascalCase` for classes/nodes
- Each scene has its own script; no monolithic scripts
- Prefer composition (child nodes) over deep inheritance
