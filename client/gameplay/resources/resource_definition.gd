class_name ResourceDefinition
extends Resource

@export var profile_id := ""
@export var display_name := ""
@export var kind := "tree"
@export var loot_profile_id := ""
@export var tool_tag := ""
@export_range(1, 100) var minimum_tool_power := 1
@export_range(1, 10000) var reserves := 3
@export_range(1, 1200) var work_ticks := 12
@export_range(0, 720000) var regeneration_ticks := 1200
@export_range(0.1, 20.0) var interaction_range := 3.0

func valid() -> bool:
	return CoreIds.valid(profile_id) and not display_name.is_empty() and kind in ["tree", "stone", "ore"] and CoreIds.valid(loot_profile_id) and CoreIds.valid(tool_tag) and minimum_tool_power >= 1 and minimum_tool_power <= 100 and reserves >= 1 and reserves <= 10000 and work_ticks >= 1 and work_ticks <= 1200 and regeneration_ticks >= 0 and regeneration_ticks <= 720000 and is_finite(interaction_range) and interaction_range >= 0.1 and interaction_range <= 20.0
