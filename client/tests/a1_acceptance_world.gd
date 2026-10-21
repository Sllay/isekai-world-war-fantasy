extends "res://runtime/game_runtime.gd"

var scenario: A1ScenarioDriver
var tick_samples_us: Array[float] = []
var active_tick_samples_us: Array[float] = []
var active_frame_samples_us: Array[float] = []

func _ready() -> void:
	# Fresh isolated scenario slot, never the developer's ordinary session save.
	save_slot = LocalSaveSlot.new("test.a1", "user://tests/a1-%s.json" % CoreIds.generate())
	super._ready()
	persistence.suppress_autosave = true
	scenario = A1ScenarioDriver.new()
	scenario.runtime = self
	add_child(scenario)

func _process(delta: float) -> void:
	var previous := core.clock.tick
	var started := Time.get_ticks_usec()
	super._process(delta)
	var steps := core.clock.tick - previous
	if steps > 0:
		var elapsed := float(Time.get_ticks_usec() - started) / steps
		tick_samples_us.append(elapsed)
		if tick_samples_us.size() > 128: tick_samples_us.pop_front()
		if scenario != null and scenario.result.is_empty() and active_tick_samples_us.size() < 2400:
			active_tick_samples_us.append(elapsed)
	if scenario != null and scenario.result.is_empty() and active_frame_samples_us.size() < 10000:
		active_frame_samples_us.append(delta * 1000000.0)

func active_timing_summary() -> Dictionary:
	var ticks := active_tick_samples_us.duplicate()
	var frames := active_frame_samples_us.duplicate()
	ticks.sort()
	frames.sort()
	return {"application_tick_samples": ticks.size(), "application_tick_p95_us": ticks[mini(ticks.size() - 1, int(ticks.size() * 0.95))] if not ticks.is_empty() else 0.0, "application_tick_max_us": ticks.back() if not ticks.is_empty() else 0.0, "frame_samples": frames.size(), "frame_p95_us": frames[mini(frames.size() - 1, int(frames.size() * 0.95))] if not frames.is_empty() else 0.0, "frame_max_us": frames.back() if not frames.is_empty() else 0.0}

func timing_summary() -> Dictionary:
	var sorted := tick_samples_us.duplicate()
	sorted.sort()
	return {"samples": sorted.size(), "application_tick_p95_us": sorted[mini(sorted.size() - 1, int(sorted.size() * 0.95))] if not sorted.is_empty() else 0.0, "application_tick_max_us": sorted.back() if not sorted.is_empty() else 0.0}
