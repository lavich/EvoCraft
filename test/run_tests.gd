extends Node

func _ready() -> void:
	print("=== Running All Tests ===")
	print("")

	var dna_test = preload("res://test/unit/test_dna.gd").new()
	add_child(dna_test)
	dna_test.run_all()
	remove_child(dna_test)

	var sim_test = preload("res://test/unit/test_simulation.gd").new()
	add_child(sim_test)
	sim_test.run_all()
	remove_child(sim_test)

	print("")
	print("=== All Tests Complete ===")
	get_tree().quit()
