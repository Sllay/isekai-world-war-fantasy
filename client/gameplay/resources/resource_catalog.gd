class_name ResourceCatalog
extends Resource

@export var node_profiles: Array[ResourceDefinition] = []
@export var nodes: Array[ResourceNodeDefinition] = []
@export var loot_profiles: Array[LootProfile] = []
@export var recipes: Array[RecipeDefinition] = []

static func defaults() -> ResourceCatalog:
	var content := load("res://gameplay/resources/content/defaults.tres") as ResourceCatalog
	return content.duplicate(true) as ResourceCatalog if content != null else ResourceCatalog.new()

func profile(id: String) -> ResourceDefinition:
	for value in node_profiles:
		if value != null and value.profile_id == id:
			return value.duplicate(true) as ResourceDefinition
	return null

func node(id: String) -> ResourceNodeDefinition:
	for value in nodes:
		if value != null and value.node_id == id:
			return value.duplicate(true) as ResourceNodeDefinition
	return null

func loot(id: String) -> LootProfile:
	for value in loot_profiles:
		if value != null and value.profile_id == id:
			return value.duplicate(true) as LootProfile
	return null

func recipe(id: String) -> RecipeDefinition:
	for value in recipes:
		if value != null and value.recipe_id == id:
			return value.duplicate(true) as RecipeDefinition
	return null

func valid(items: ItemCatalog) -> bool:
	if items == null or nodes.is_empty() or nodes.size() > 256 or node_profiles.size() > 64 or loot_profiles.size() > 64 or recipes.size() > 128:
		return false
	var ids: Dictionary = {}
	for profile_value in node_profiles:
		if profile_value == null or not profile_value.valid() or ids.has(profile_value.profile_id) or loot(profile_value.loot_profile_id) == null:
			return false
		ids[profile_value.profile_id] = true
	for node_value in nodes:
		if node_value == null or not node_value.valid() or ids.has(node_value.node_id) or profile(node_value.profile_id) == null:
			return false
		ids[node_value.node_id] = true
	for loot_value in loot_profiles:
		if loot_value == null or not loot_value.valid(items) or ids.has(loot_value.profile_id):
			return false
		ids[loot_value.profile_id] = true
	for recipe_value in recipes:
		if recipe_value == null or not recipe_value.valid(items) or ids.has(recipe_value.recipe_id):
			return false
		ids[recipe_value.recipe_id] = true
	return true
