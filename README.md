# EvoCraft

Evolution simulation game in Godot 4.3. Autonomous creatures with behavioral DNA navigate a dynamic world, collect resources, reproduce, and evolve.

**Play online:** https://lavich.github.io/EvoCraft/

## Features

- Behavioral DNA (18 genes: sensors, thresholds, action priorities, params)
- Natural selection — reproduction with crossover + mutation
- 4 terrain types affecting movement cost
- Fragment regrowth with delay on full depletion
- Player tools: Inspect, Terrain, Impulse, Breed, Relocate
- Spatial bucketing for O(n) agent queries at scale

## Tech

- Godot 4.3, GDScript
- Data-driven simulation (no TileMap, agents as data)
- Rendering separated from simulation logic

## Run locally

```bash
# Open in Godot Editor (F5)
godot --path .

# Headless tests
godot --headless --path . test/run_tests.tscn

# Web export
godot --headless --export-debug "Web" --path . build/web/index.html
```
