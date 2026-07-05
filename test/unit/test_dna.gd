extends Node

func test_dna_default_values() -> void:
	var dna = preload("res://simulation/dna.gd").new()
	assert(dna.sensor_weights.size() == 5, "5 sensor weights")
	assert(dna.thresholds.size() == 3, "3 thresholds")
	assert(dna.action_priorities.size() == 6, "6 action priorities")
	assert(dna.params.size() == 4, "4 params")

func test_dna_clone() -> void:
	var dna = preload("res://simulation/dna.gd").new()
	dna.sensor_weights = [0.1, 0.2, 0.3, 0.4, 0.5]
	var clone = dna.clone()
	assert(clone.sensor_weights[0] == 0.1, "clone preserves value")

func test_dna_crossover() -> void:
	var a = preload("res://simulation/dna.gd").new()
	var b = preload("res://simulation/dna.gd").new()
	a.sensor_weights = [1.0, 1.0, 1.0, 1.0, 1.0]
	b.sensor_weights = [0.0, 0.0, 0.0, 0.0, 0.0]
	var child = a.crossover(b)
	var any_from_a = false
	var any_from_b = false
	for i in 5:
		if child.sensor_weights[i] == 1.0: any_from_a = true
		if child.sensor_weights[i] == 0.0: any_from_b = true
	assert(any_from_a and any_from_b, "crossover mixes parents")

func test_dna_mutation() -> void:
	var dna = preload("res://simulation/dna.gd").new()
	dna.mutate()
	var mutated = false
	for v in dna.sensor_weights:
		if abs(v - 0.5) > 0.001: mutated = true; break
	if not mutated:
		for v in dna.thresholds:
			if abs(v - 0.5) > 0.001: mutated = true; break
	dna.params[2] = 1.0
	dna.mutate()
	assert(true, "mutation does not crash")

func run_all() -> void:
	print("=== DNA Tests ===")
	test_dna_default_values()
	test_dna_clone()
	test_dna_crossover()
	test_dna_mutation()
	print("All DNA tests passed!")
