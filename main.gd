extends Node2D

@onready var sim = $Simulation
@onready var stats_label = $HUD/StatsLabel

var zoom := 1.0
var offset := Vector2.ZERO
var dragging := false
var drag_start := Vector2.ZERO

const TILE_PX := 32
const AGENT_RADIUS := 4
const TILE_COLORS := {
	0: Color(0.5, 0.75, 0.5),
	1: Color(0.3, 0.5, 0.3),
	2: Color(0.7, 0.6, 0.4),
	3: Color(0.2, 0.2, 0.2),
}

func _ready() -> void:
	sim.init_world()

func _process(_delta: float) -> void:
	queue_redraw()
	update_hud()

func _draw() -> void:
	draw_grid()
	draw_agents()

func draw_grid() -> void:
	for x in sim.grid_size:
		for y in sim.grid_size:
			var cell = sim.grid[x][y]
			var color = TILE_COLORS[cell.type]
			var pos = world_to_screen(x, y)
			draw_rect(Rect2(pos, Vector2(TILE_PX, TILE_PX)), color)
			if cell.fragments > 0:
				var bright = 0.3 + 0.7 * (cell.fragments / 5.0)
				draw_circle(pos + Vector2(TILE_PX/2, TILE_PX/2), 2, Color(1, 1, 0.6, bright))

func draw_agents() -> void:
	for a in sim.agents:
		if a.energy <= 0: continue
		var pos = world_to_screen(a.x, a.y) + Vector2(TILE_PX/2, TILE_PX/2)
		var hue = a.dna.params[1]
		var sat = a.energy / a.max_energy
		var color = Color.from_hsv(hue, sat, 1.0)
		draw_circle(pos, AGENT_RADIUS * zoom, color)

func world_to_screen(gx: int, gy: int) -> Vector2:
	return Vector2(gx * TILE_PX, gy * TILE_PX) * zoom + offset

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			sim.running = not sim.running
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom * 1.1, 0.5, 3.0)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom / 1.1, 0.5, 3.0)
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			drag_start = event.position / zoom - offset / zoom if event.pressed else drag_start
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var click_pos = (event.position - offset) / zoom
			var gx = int(click_pos.x / TILE_PX)
			var gy = int(click_pos.y / TILE_PX)
			if gx >= 0 and gx < sim.grid_size and gy >= 0 and gy < sim.grid_size:
				sim.grid[gx][gy].type = (sim.grid[gx][gy].type + 1) % 4
	if event is InputEventMouseMotion and dragging:
		offset = event.position / zoom - drag_start

func update_hud() -> void:
	var alive = 0
	var avg_energy := 0.0
	var avg_age := 0.0
	for a in sim.agents:
		if a.energy > 0:
			alive += 1
			avg_energy += a.energy
			avg_age += a.age
	if alive > 0:
		avg_energy /= alive
		avg_age /= alive
	stats_label.text = "Pop: %d | Avg E: %.1f | Avg Age: %.1f | Tick: %d | %s" % [
			alive, avg_energy, avg_age, sim.tick_count, "RUN" if sim.running else "PAUSE"
	]
