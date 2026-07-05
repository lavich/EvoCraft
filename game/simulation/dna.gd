extends Resource

var sensor_weights: Array = [0.5, 0.5, 0.5, 0.5, 0.5]
var thresholds: Array = [0.3, 0.7, 0.4]
var action_priorities: Array = [0.5, 0.5, 0.2, 0.3, 0.2, 0.2]
var params: Array = [0.5, 0.5, 0.3, 0.8]

func clone():
	var d = get_script().new()
	for i in 5: d.sensor_weights[i] = sensor_weights[i]
	for i in 3: d.thresholds[i] = thresholds[i]
	for i in 6: d.action_priorities[i] = action_priorities[i]
	for i in 4: d.params[i] = params[i]
	return d

func crossover(other):
	var d = get_script().new()
	for i in 5: d.sensor_weights[i] = sensor_weights[i] if randf() < 0.5 else other.sensor_weights[i]
	for i in 3: d.thresholds[i] = thresholds[i] if randf() < 0.5 else other.thresholds[i]
	for i in 6: d.action_priorities[i] = action_priorities[i] if randf() < 0.5 else other.action_priorities[i]
	for i in 4: d.params[i] = params[i] if randf() < 0.5 else other.params[i]
	d.mutate()
	return d

func mutate() -> void:
	var rate = params[2]
	for i in 5:
		if randf() < rate: sensor_weights[i] = clamp(sensor_weights[i] + randf_range(-0.05, 0.05), 0.0, 1.0)
	for i in 3:
		if randf() < rate: thresholds[i] = clamp(thresholds[i] + randf_range(-0.05, 0.05), 0.0, 1.0)
	for i in 6:
		if randf() < rate: action_priorities[i] = clamp(action_priorities[i] + randf_range(-0.05, 0.05), 0.0, 1.0)
	for i in 4:
		if randf() < rate: params[i] = clamp(params[i] + randf_range(-0.05, 0.05), 0.0, 1.0)
