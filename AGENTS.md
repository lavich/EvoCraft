# Project Context

## Godot 4.3 GDScript Rules
- Use `@onready` for node references, `@export` for inspector vars
- Signals: `signal name` then `emit_signal("name")` or `name.emit()`
- `class_name` for autoloads and custom resources
- Use `preload()` for constants, `load()` for dynamic resources
- No comments in code

## Architecture
- `simulation/simulation.gd` — data/state (grid, agents, tick, DNA), no rendering
- `main.gd` — rendering, camera, HUD, tools, input
- `simulation/dna.gd` — Resource with 18 genes
- Agents are `AgentData` objects in `agents: Array[AgentData]`
- Grid is custom `Array` of dicts (not TileMap)
- HUD in `CanvasLayer`

## Conventions
- Snake_case for vars/funcs
- Constants in SCREAMING_SNAKE_CASE
- No comments in source
- Prefer explicit typing: `var x: int`, `func f() -> void:`
- One `class_name` per file at most
- Tests in `test/unit/`, run with `godot --headless --path . test/run_tests.tscn`
- Web export: `godot --headless --export-debug "Web" --path . build/web/index.html`
