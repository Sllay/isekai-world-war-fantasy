extends "res://runtime/game_runtime.gd"

# Same production runtime and controls, with a separate Android acceptance slot.
# No bot or direct gameplay writes; the ordinary player save stays untouched.
func _ready() -> void:
	save_slot = LocalSaveSlot.new("test.p2_manual", "user://tests/p2-android-manual.json")
	super._ready()
