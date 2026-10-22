extends "res://runtime/game_runtime.gd"

# Ordinary production controls in an isolated Android acceptance slot.
func _ready() -> void:
	save_slot = LocalSaveSlot.new("test.p3_manual", "user://tests/p3-android-manual.json")
	super._ready()
