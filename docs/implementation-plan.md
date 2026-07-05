# Implementation Plan

**Engine**: Godot
**Language**: GDScript
**Platform**: Desktop (macOS/Windows/Linux), network layer for social features

---

## Phase 1: Core Simulation

### 1.1 World grid
- `World` node with 2D tile-based grid
- Tile types: равнина, трясина, возвышенность, разлом
- Each tile holds: type, fragment count, anomaly flag

### 1.2 Fragments (resources)
- Spawn logic: random distribution, clumps, or zones
- Regeneration timer per tile
- Visual: light dots on tiles

### 1.3 Agents
- `Agent` scene (Area2D or CharacterBody2D)
- State: energy, health, age, position
- Sensors: read tiles and nearby agents in range
- Actions: move, collect, wait, reproduce, attack, evade

### 1.4 Tick system
- `SimulationTick` autoload — drives all agents each frame or at fixed rate
- Pause/resume control

---

## Phase 2: DNA & Evolution

### 2.1 DNA structure
- `DNA` resource with 18 floats (5 sensor weights, 3 thresholds, 6 action priorities, 4 agent params)
- All values clamped 0.0–1.0

### 2.2 Decision cycle
- Agent reads sensors → multiplies by DNA weights → compares against thresholds → picks action by priority → executes

### 2.3 Reproduction
- Energy check + cooldown
- Crossover: each gene inherited randomly from either parent
- Mutation: per-gene chance based on mutability, small ±0.01–0.05 shift
- Rare gene duplication/reset

### 2.4 Natural selection
- Agents die when energy or health reaches 0
- Longer-living agents reproduce more → their DNA spreads

---

## Phase 3: Player Interaction

### 3.1 Camera
- Zoom in/out, pan over world

### 3.2 Tools
- Terrain brush: paint tiles (равнина, трясина, возвышенность, разлом)
- Impulse trigger: boost fragment regen in area
- Sanctuary zone: blocks anomaly damage
- Selective breeding: boost reproduction chance for chosen agents
- Relocate: move agent to another position

### 3.3 HUD
- Population stats panel (count, avg energy, avg age)
- Genetic tree (simple graph showing lineage branches)
- Tool palette

### 3.4 Agent inspection
- Click agent → popup showing DNA values, state, lineage

---

## Phase 4: Threats & Dynamics

### 4.1 Anomalies
- Zones on map that damage agents inside them
- Placed at world generation, can shift

### 4.2 Impulses
- Periodic global waves: fragment regen stops for N ticks
- Agents with high stored energy survive, others starve

### 4.3 Noise
- Random tiles where sensor accuracy is reduced
- Agents make suboptimal choices while inside

### 4.4 Resource cycles (adaptive difficulty)
- Regen rate fixed → population grows → consumption > regen → scarcity → population crash → recovery
- Cycle repeats with increasing pressure

---

## Phase 5: Meta-progression

### 5.1 Save/load worlds
- World state serialized to file
- DNA samples extracted and stored in collection

### 5.2 New world generation
- Parameter sliders: terrain mix, regen speed, anomaly density, impulse frequency
- Start with imported DNA or random population

---

## Phase 6: Social (network)

### 6.1 DNA exchange
- Export DNA as text string (18 comma-separated floats)
- Import from clipboard or via server

### 6.2 Catalog (optional server)
- Simple HTTP server or in-game browser for sharing DNA recipes
- Reputation: usage count per DNA line

---

## Phase 7: Polish

- Agent visuals: shape/color varies by DNA
- World generation variety
- Performance optimization for large populations
- Save/load whole world state
- Sound effects (optional)

---

## Build order (recommended)

| Step | What | Est. time |
|------|------|-----------|
| 1 | Grid + fragments + agents (movement & collection) | 3–5 hrs |
| 2 | DNA structure + decision cycle | 2–3 hrs |
| 3 | Reproduction + mutation + crossover | 2–3 hrs |
| 4 | Natural selection + death | 1 hr |
| 5 | Camera + basic HUD + agent inspection | 2–3 hrs |
| 6 | Terrain tools | 1–2 hrs |
| 7 | Anomalies, impulses, noise | 2–3 hrs |
| 8 | Resource cycles tuning | 1–2 hrs |
| 9 | Meta-progression (world save/load, new world gen) | 2–3 hrs |
| 10 | Social features (DNA export/import, catalog) | 2–3 hrs |
| 11 | Polish (visuals, performance, balancing) | 3–5 hrs |

Total: ~22–33 hours to a playable prototype.
