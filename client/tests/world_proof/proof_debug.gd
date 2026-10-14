extends Label

@export var player: ProofPlayer
var elapsed := 0.0
var frame_sum := 0.0
var frame_count := 0
var build_info := ""

func _ready() -> void:
	build_info = "Godot %s | %s | %s | %s | M1.2 Gate D" % [Engine.get_version_info().string,
		RenderingServer.get_current_rendering_method(), OS.get_name(), "debug" if OS.is_debug_build() else "release"]
	_update_text(0.0)

func _process(delta: float) -> void:
	elapsed += delta
	frame_sum += delta
	frame_count += 1
	if elapsed >= 0.25:
		_update_text(frame_sum * 1000.0 / frame_count)
		elapsed = 0.0
		frame_sum = 0.0
		frame_count = 0

func _update_text(frame_ms: float) -> void:
	text = "%s\nFPS %d | frame %.2f ms | pos (%.2f, %.2f, %.2f) | grounded %s\nWASD / arrows: move | Space: jump | Q/E: orbit\nTouch: left drag move | right upper drag orbit | right bottom tap jump" % [
		build_info, Engine.get_frames_per_second(), frame_ms, player.position.x, player.position.y,
		player.position.z, player.is_on_floor()]
