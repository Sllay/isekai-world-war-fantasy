class_name TelegraphDefinition
extends Resource

enum Shape { CIRCLE, LINE, SECTOR, WORLD_POINT }
@export var definition_id := "combat.telegraph.melee_range"
@export var shape: Shape = Shape.CIRCLE
@export var color := Color(1.0, 0.32, 0.05)
@export var band_width := 0.14
