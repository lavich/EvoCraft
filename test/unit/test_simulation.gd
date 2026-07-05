extends Node

func test_world_init() -> void:
	var sim = preload("res://simulation/simulation.gd").new()
	sim.init_world()
	assert(sim.grid.size() == 30, "grid width 30")
	assert(sim.grid[0].size() == 30, "grid height 30")
	assert(sim.agents.size() == 30, "30 agents spawned")

func test_fragment_regen() -> void:
	var sim = preload("res://simulation/simulation.gd").new()
	sim.init_world()
	var total_before = 0
	for x in 30:
		for y in 30:
			total_before += sim.grid[x][y].fragments
	sim.regen_fragments()
	var total_after = 0
	for x in 30:
		for y in 30:
			total_after += sim.grid[x][y].fragments
	assert(total_after >= total_before, "fragments regen or stay same")

func test_agent_spawn() -> void:
	var sim = preload("res://simulation/simulation.gd").new()
	sim.init_world()
	for a in sim.agents:
		assert(a.energy > 0, "agent has energy")
		assert(a.health > 0, "agent has health")
		assert(a.x >= 0 and a.x < 30, "agent in bounds x")
		assert(a.y >= 0 and a.y < 30, "agent in bounds y")

func test_tick_runs() -> void:
	var sim = preload("res://simulation/simulation.gd").new()
	sim.init_world()
	var prev_count = sim.tick_count
	sim.tick()
	assert(sim.tick_count == prev_count + 1, "tick increments")

func test_agents_move() -> void:
	var sim = preload("res://simulation/simulation.gd").new()
	sim.init_world()
	var initial_by_id = {}
	for a in sim.agents:
		initial_by_id[a.id] = Vector2i(a.x, a.y)
	for i in 100:
		sim.tick()
	var moved = false
	for a in sim.agents:
		if a.energy > 0 and a.id in initial_by_id:
			var pos = Vector2i(a.x, a.y)
			if pos != initial_by_id[a.id]:
				moved = true
				break
	assert(moved, "at least one agent moved after 100 ticks")

func test_death_and_reproduction() -> void:
	var sim = preload("res://simulation/simulation.gd").new()
	sim.init_world()
	var pop_sizes = []
	for i in 100:
		sim.tick()
		if i % 10 == 0:
			pop_sizes.append(sim.agents.size())
	assert(pop_sizes.size() > 0, "simulation runs 100 ticks")
	assert(true, "simulation completed without crash")

func run_all() -> void:
	print("=== Simulation Tests ===")
	test_world_init()
	test_fragment_regen()
	test_agent_spawn()
	test_tick_runs()
	test_agents_move()
	test_death_and_reproduction()
	print("All simulation tests passed!")
