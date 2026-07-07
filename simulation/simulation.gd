extends Node
class_name Simulation

enum TileType { RAVNINA, TRYASINA, VOZVYSHENNOST, RAZLOM }

const DNA_SCRIPT = preload("res://simulation/dna.gd")

class AgentData:
	var id: int
	var x: int
	var y: int
	var energy: float
	var max_energy: float
	var health: float
	var max_health: float
	var age: int
	var dna: Resource
	var cooldown: int
	var breeding_boost: float
	var move_cooldown: int

var grid_size := 30
var grid: Array
var agents: Array[AgentData]
var tick_count := 0
var running := true
var next_id := 0
const TICKS_PER_SECOND := 60
var _regen_cooldown := 0

var _agent_buckets: Dictionary
const BUCKET_SIZE := 5
const SENSOR_RANGE := 8

const TILE_COLORS := {
	TileType.RAVNINA: Color(0.5, 0.75, 0.5),
	TileType.TRYASINA: Color(0.3, 0.5, 0.3),
	TileType.VOZVYSHENNOST: Color(0.7, 0.6, 0.4),
	TileType.RAZLOM: Color(0.2, 0.2, 0.2),
}

const FRAGMENT_REGEN_BASE := 0.03
const ENERGY_PER_FRAGMENT := 12.0
const MOVE_COST := 0.3
const ATTACK_COST := 2.0
const EVADE_COST := 1.0
const REPRODUCE_COST := 30.0
const IDLE_COST := 0.5
const COOLDOWN_TICKS := 5

func random_dna():
	var d = DNA_SCRIPT.new()
	for i in 5: d.sensor_weights[i] = randf()
	for i in 3: d.thresholds[i] = randf()
	for i in 6: d.action_priorities[i] = randf()
	d.action_priorities[0] = max(d.action_priorities[0], 0.3)
	for i in 4: d.params[i] = randf()
	return d

func _ready() -> void:
	randomize()
	init_world()

func init_world() -> void:
	grid = []
	for x in grid_size:
		grid.append([])
		for y in grid_size:
			var t = TileType.RAVNINA
			var r = randf()
			if r < 0.1: t = TileType.TRYASINA
			elif r < 0.15: t = TileType.VOZVYSHENNOST
			elif r < 0.18: t = TileType.RAZLOM
			grid[x].append({
				type = t,
				fragments = randi() % 4 + 1,
				regen_boost = 0.0,
				regen_delay = 0,
			})
	agents = []
	for i in 30:
		spawn_agent()

func spawn_agent() -> void:
	var a = AgentData.new()
	a.id = next_id; next_id += 1
	a.x = randi() % grid_size
	a.y = randi() % grid_size
	a.energy = 50.0
	a.max_energy = 100.0
	a.health = 100.0
	a.max_health = 100.0
	a.age = 0
	a.dna = random_dna()
	a.cooldown = 0
	a.breeding_boost = 1.0
	a.move_cooldown = randi() % 60
	agents.append(a)

func _process(_delta: float) -> void:
	if not running: return
	tick()

func tick() -> void:
	tick_count += 1
	if _regen_cooldown <= 0:
		regen_fragments()
		_regen_cooldown = TICKS_PER_SECOND / 3
	else:
		_regen_cooldown -= 1
	process_agents()
	cleanup_dead()

func regen_fragments() -> void:
	for x in grid_size:
		for y in grid_size:
			var cell = grid[x][y]
			if cell.type == TileType.RAZLOM: continue
			if cell.regen_delay > 0:
				cell.regen_delay -= 1
				continue
			var neighbors := 0
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0: continue
					var nx: int = x + dx
					var ny: int = y + dy
					if nx < 0 or nx >= grid_size or ny < 0 or ny >= grid_size: continue
					if grid[nx][ny].fragments > 0:
						neighbors += 1
			if neighbors < 1: continue
			var rate = FRAGMENT_REGEN_BASE + cell.regen_boost
			if cell.type == TileType.TRYASINA: rate *= 2
			if randf() < rate:
				cell.fragments = min(cell.fragments + 1, 5)
			if cell.regen_boost > 0.0:
				cell.regen_boost = max(0.0, cell.regen_boost - 0.05)

func process_agents() -> void:
	_rebuild_buckets()
	for a in agents:
		if a.energy <= 0 or a.health <= 0: continue
		a.age += 1
		if a.cooldown > 0: a.cooldown -= 1
		if a.move_cooldown > 0: a.move_cooldown -= 1
		a.breeding_boost = max(1.0, a.breeding_boost - 0.1)
		decide_action(a)

func decide_action(a: AgentData) -> void:
	var w = a.dna.sensor_weights
	var p = a.dna.action_priorities
	var t = a.dna.thresholds

	var nearest_fragment_dist = sense_nearest_fragment(a)
	var nearest_agent_dist = sense_nearest_agent(a)
	var energy_ratio = a.energy / a.max_energy

	# Each action uses sensor weights that are relevant to it:
	# w[0] = fragment dist  |  w[1] = agent dist  |  w[2] = energy level
	# w[3] = direction to cluster  |  w[4] = agent density
	var move_w = 0.0 if a.move_cooldown > 0 else p[0] * (w[0] + w[3]) * 0.5 + 0.15
	var collect_w = p[1] * w[0] * (1.0 if nearest_fragment_dist < 1.5 else 0.1)
	var idle_w = p[2] * (1.0 - w[2])
	var reproduce_w = p[3] * w[2] * (1.0 if energy_ratio > t[1] else 0.0)
	var attack_w = p[4] * w[1] * (1.0 if nearest_agent_dist < 1.5 and energy_ratio > 0.5 else 0.0)
	var evade_w = p[5] * w[1] * (1.0 if nearest_agent_dist < 2.0 and energy_ratio < t[2] else 0.0)

	var actions = [
		[move_w, 0], [collect_w, 1], [idle_w, 2],
		[reproduce_w, 3], [attack_w, 4], [evade_w, 5]
	]
	actions.sort_custom(func(a, b): return a[0] > b[0])
	var chosen = actions[0][1]
	if a.move_cooldown == 1:
		chosen = 0

	match chosen:
		0: do_move(a)
		1: do_collect(a)
		2: do_idle(a)
		3: do_reproduce(a)
		4: do_attack(a)
		5: do_evade(a)

func sense_nearest_fragment(a: AgentData) -> float:
	var best_dist_sq := 999.0
	for dx in range(-3, 4):
		for dy in range(-3, 4):
			var nx = a.x + dx; var ny = a.y + dy
			if nx < 0 or nx >= grid_size or ny < 0 or ny >= grid_size: continue
			if grid[nx][ny].fragments > 0:
				var d_sq = dx*dx + dy*dy
				if d_sq < best_dist_sq: best_dist_sq = d_sq
	return sqrt(best_dist_sq)

func sense_nearest_agent(a: AgentData) -> float:
	var best_sq := SENSOR_RANGE * SENSOR_RANGE
	for other in _nearby_agents(a.x, a.y, SENSOR_RANGE):
		if other.id == a.id: continue
		var dx = other.x - a.x; var dy = other.y - a.y
		var d_sq = dx*dx + dy*dy
		if d_sq < best_sq: best_sq = d_sq
	return sqrt(best_sq)

func do_move(a: AgentData) -> void:
	var best_dir = Vector2i(0, 0)
	var best_dist := 999.0
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0: continue
			var nx = a.x + dx; var ny = a.y + dy
			if nx < 0 or nx >= grid_size or ny < 0 or ny >= grid_size: continue
			if grid[nx][ny].type == TileType.RAZLOM: continue
			if grid[nx][ny].fragments > 0:
				var d = sqrt(dx*dx + dy*dy)
				if d < best_dist:
					best_dist = d
					best_dir = Vector2i(dx, dy)
	if best_dir == Vector2i.ZERO:
		var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1),
			Vector2i(1,1), Vector2i(-1,1), Vector2i(1,-1), Vector2i(-1,-1)]
		dirs.shuffle()
		for d in dirs:
			var nx = a.x + d.x; var ny = a.y + d.y
			if nx < 0 or nx >= grid_size or ny < 0 or ny >= grid_size: continue
			if grid[nx][ny].type == TileType.RAZLOM: continue
			best_dir = d; break
	if best_dir != Vector2i.ZERO:
		a.x += best_dir.x
		a.y += best_dir.y
		a.move_cooldown = 60
		var speed = a.dna.params[1]
		var terrain_cost = 1.0
		if grid[a.x][a.y].type == TileType.TRYASINA: terrain_cost = 2.0
		if grid[a.x][a.y].type == TileType.VOZVYSHENNOST: terrain_cost = 1.2
		a.energy -= MOVE_COST * terrain_cost / max(speed, 0.1)

func do_collect(a: AgentData) -> void:
	var cell = grid[a.x][a.y]
	if cell.fragments > 0:
		var eff = a.dna.params[0]
		var amount = ENERGY_PER_FRAGMENT * eff
		a.energy = min(a.energy + amount, a.max_energy)
		cell.fragments -= 1
		if cell.fragments == 0:
			cell.regen_delay = 300

func do_idle(a: AgentData) -> void:
	a.energy -= IDLE_COST

func do_reproduce(a: AgentData) -> void:
	if a.cooldown > 0: return
	var partner: AgentData = null
	var repro_threshold = REPRODUCE_COST / max(a.breeding_boost, 0.1)
	for other in _nearby_agents(a.x, a.y, 2):
		if other.id == a.id or other.energy <= 0: continue
		if other.energy > repro_threshold:
			partner = other; break
	if partner == null: return

	if agents.size() >= 150: return
	var child = AgentData.new()
	child.id = next_id; next_id += 1
	child.x = a.x + randi() % 3 - 1
	child.y = a.y + randi() % 3 - 1
	child.x = clampi(child.x, 0, grid_size - 1)
	child.y = clampi(child.y, 0, grid_size - 1)
	child.energy = 30.0
	child.max_energy = 100.0
	child.health = a.health * 0.7 + partner.health * 0.3
	child.max_health = 100.0
	child.age = 0
	child.dna = a.dna.crossover(partner.dna)
	child.cooldown = COOLDOWN_TICKS
	agents.append(child)

	a.energy -= REPRODUCE_COST * 0.5
	partner.energy -= REPRODUCE_COST * 0.5
	a.cooldown = COOLDOWN_TICKS
	partner.cooldown = COOLDOWN_TICKS

func do_attack(a: AgentData) -> void:
	for other in _nearby_agents(a.x, a.y, 2):
		if other.id == a.id or other.energy <= 0: continue
		var dx = other.x - a.x; var dy = other.y - a.y
		if dx*dx + dy*dy < 2.25:
			other.health -= 20.0
			a.energy -= ATTACK_COST
			return

func do_evade(a: AgentData) -> void:
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	dirs.shuffle()
	for d in dirs:
		var nx = a.x + d.x; var ny = a.y + d.y
		if nx < 0 or nx >= grid_size or ny < 0 or ny >= grid_size: continue
		if grid[nx][ny].type == TileType.RAZLOM: continue
		var danger := false
		for other in _nearby_agents(nx, ny, 1):
			if other.id == a.id or other.energy <= 0: continue
			danger = true; break
		if not danger:
			a.x = nx; a.y = ny
			a.energy -= EVADE_COST
			return

func _bucket_key(x: int, y: int) -> Vector2i:
	return Vector2i(x / BUCKET_SIZE, y / BUCKET_SIZE)

func _rebuild_buckets() -> void:
	_agent_buckets.clear()
	for a in agents:
		if a.energy <= 0: continue
		var bk = _bucket_key(a.x, a.y)
		if not _agent_buckets.has(bk):
			_agent_buckets[bk] = []
		_agent_buckets[bk].append(a)

func _nearby_agents(x: int, y: int, radius: int) -> Array[AgentData]:
	var result: Array[AgentData] = []
	var min_bx = max(0, x - radius) / BUCKET_SIZE
	var max_bx = min(grid_size - 1, x + radius) / BUCKET_SIZE
	var min_by = max(0, y - radius) / BUCKET_SIZE
	var max_by = min(grid_size - 1, y + radius) / BUCKET_SIZE
	for bx in range(min_bx, max_bx + 1):
		for by in range(min_by, max_by + 1):
			var bk = Vector2i(bx, by)
			var bucket = _agent_buckets.get(bk)
			if bucket == null: continue
			for a in bucket:
				var dx = a.x - x; var dy = a.y - y
				if dx*dx + dy*dy <= radius*radius:
					result.append(a)
	return result

func cleanup_dead() -> void:
	var alive: Array[AgentData] = []
	for a in agents:
		if a.energy > 0 and a.health > 0:
			alive.append(a)
	agents = alive

func trigger_impulse(cx: int, cy: int, radius: int = 3) -> void:
	for x in range(max(0, cx - radius), min(grid_size, cx + radius + 1)):
		for y in range(max(0, cy - radius), min(grid_size, cy + radius + 1)):
			var d = sqrt(pow(x - cx, 2) + pow(y - cy, 2))
			if d <= radius:
				grid[x][y].regen_boost = 0.5

func boost_breeding(a: AgentData) -> void:
	a.breeding_boost = 5.0

func relocate_agent(a: AgentData, nx: int, ny: int) -> void:
	nx = clampi(nx, 0, grid_size - 1)
	ny = clampi(ny, 0, grid_size - 1)
	if grid[nx][ny].type != TileType.RAZLOM:
		a.x = nx
		a.y = ny
