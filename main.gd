extends Node2D

enum Tool { POINTER, TERRAIN, IMPULSE, BREED, RELOCATE }

@onready var sim = $Simulation
@onready var stats_label = $HUD/StatsLabel
@onready var inspect_popup = $HUD/InspectPopup
@onready var inspect_label = $HUD/InspectPopup/InspectLabel

var zoom := 1.0
var offset := Vector2.ZERO
var dragging := false
var drag_start := Vector2.ZERO
var current_tool := Tool.POINTER
var relocate_target = null

const TILE_PX := 32
const AGENT_RADIUS := 4
func _ready() -> void:
	sim.init_world()
	$HUD/ToolPalette/PointerBtn.pressed.connect(func(): current_tool = Tool.POINTER; hide_popup())
	$HUD/ToolPalette/TerrainBtn.pressed.connect(func(): current_tool = Tool.TERRAIN; hide_popup())
	$HUD/ToolPalette/ImpulseBtn.pressed.connect(func(): current_tool = Tool.IMPULSE; hide_popup())
	$HUD/ToolPalette/BreedBtn.pressed.connect(func(): current_tool = Tool.BREED; hide_popup())
	$HUD/ToolPalette/RelocateBtn.pressed.connect(func(): current_tool = Tool.RELOCATE; hide_popup(); relocate_target = null)

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
			var color = sim.TILE_COLORS[cell.type]
			if cell.regen_boost > 0.0:
				color = color.blend(Color(0, 1, 1, cell.regen_boost * 0.3))
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
		if a.breeding_boost > 2.0:
			color = color.blend(Color(1, 0, 1, 0.4))
		draw_circle(pos, AGENT_RADIUS * zoom, color)
	if relocate_target:
		var tp = world_to_screen(relocate_target.x, relocate_target.y) + Vector2(TILE_PX/2, TILE_PX/2)
		draw_circle(tp, AGENT_RADIUS * zoom + 4, Color(1, 1, 0, 0.6), false, 2.0)

func world_to_screen(gx: int, gy: int) -> Vector2:
	return Vector2(gx * TILE_PX, gy * TILE_PX) * zoom + offset

func grid_from_screen(sx: float, sy: float) -> Vector2i:
	var g = (Vector2(sx, sy) - offset) / zoom
	return Vector2i(int(g.x / TILE_PX), int(g.y / TILE_PX))

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			sim.running = not sim.running
		if event.keycode == KEY_1 and event.pressed: current_tool = Tool.POINTER; hide_popup()
		if event.keycode == KEY_2 and event.pressed: current_tool = Tool.TERRAIN; hide_popup()
		if event.keycode == KEY_3 and event.pressed: current_tool = Tool.IMPULSE; hide_popup()
		if event.keycode == KEY_4 and event.pressed: current_tool = Tool.BREED; hide_popup()
		if event.keycode == KEY_5 and event.pressed: current_tool = Tool.RELOCATE; hide_popup(); relocate_target = null
		if event.keycode == KEY_ESCAPE and event.pressed: hide_popup()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom * 1.1, 0.5, 3.0)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom / 1.1, 0.5, 3.0)
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			drag_start = event.position / zoom - offset / zoom if event.pressed else drag_start
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var g = grid_from_screen(event.position.x, event.position.y)
			var gx = g.x; var gy = g.y
			if gx < 0 or gx >= sim.grid_size or gy < 0 or gy >= sim.grid_size: return
			handle_tool_click(gx, gy)
	if event is InputEventMouseMotion and dragging:
		offset = event.position / zoom - drag_start

func handle_tool_click(gx: int, gy: int) -> void:
	match current_tool:
		Tool.POINTER:
			var a = agent_at(gx, gy)
			if a: show_inspect(a)
			else: hide_popup()
		Tool.TERRAIN:
			sim.grid[gx][gy].type = (sim.grid[gx][gy].type + 1) % 4
		Tool.IMPULSE:
			sim.trigger_impulse(gx, gy, 3)
		Tool.BREED:
			var a = agent_at(gx, gy)
			if a: sim.boost_breeding(a)
		Tool.RELOCATE:
			if relocate_target == null:
				relocate_target = agent_at(gx, gy)
			else:
				sim.relocate_agent(relocate_target, gx, gy)
				relocate_target = null

func agent_at(gx: int, gy: int):
	for a in sim.agents:
		if a.x == gx and a.y == gy and a.energy > 0:
			return a
	return null

func show_inspect(a) -> void:
	var dna = a.dna
	var txt = "[b]Agent %d[/b]\n" % a.id
	txt += "Energy: %d/%d\n" % [a.energy, a.max_energy]
	txt += "Health: %d/%d\n" % [a.health, a.max_health]
	txt += "Age: %d\n" % a.age
	txt += "\n[b]DNA:[/b]\n"
	txt += "Sensor W: [%.2f, %.2f, %.2f, %.2f, %.2f]\n" % [dna.sensor_weights[0], dna.sensor_weights[1], dna.sensor_weights[2], dna.sensor_weights[3], dna.sensor_weights[4]]
	txt += "Thresholds: [%.2f, %.2f, %.2f]\n" % [dna.thresholds[0], dna.thresholds[1], dna.thresholds[2]]
	txt += "Priorities: [%.2f, %.2f, %.2f, %.2f, %.2f, %.2f]\n" % [dna.action_priorities[0], dna.action_priorities[1], dna.action_priorities[2], dna.action_priorities[3], dna.action_priorities[4], dna.action_priorities[5]]
	txt += "Params: [%.2f, %.2f, %.2f, %.2f]" % [dna.params[0], dna.params[1], dna.params[2], dna.params[3]]
	inspect_label.text = txt
	inspect_popup.visible = true

func hide_popup() -> void:
	inspect_popup.visible = false

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
