class_name LivingCatalog
extends Resource

@export var races: Array[RaceDefinition] = []
@export var visuals: Array[RaceVisualProfile] = []
@export var classes: Array[ClassDefinition] = []
@export var progressions: Array[ProgressionDefinition] = []
@export var factions: Array[FactionDefinition] = []

static func defaults() -> LivingCatalog:
	return (load("res://gameplay/living/content/defaults.tres") as LivingCatalog).duplicate(true) as LivingCatalog

func race(id: String) -> RaceDefinition:
	for entry in races:
		if entry != null and entry.race_id == id: return entry.duplicate(true) as RaceDefinition
	return null

func visual(id: String) -> RaceVisualProfile:
	for entry in visuals:
		if entry != null and entry.profile_id == id: return entry.duplicate(true) as RaceVisualProfile
	return null

func character_class(id: String) -> ClassDefinition:
	for entry in classes:
		if entry != null and entry.class_id == id: return entry.duplicate(true) as ClassDefinition
	return null

func progression(id: String) -> ProgressionDefinition:
	for entry in progressions:
		if entry != null and entry.progression_id == id: return entry.duplicate(true) as ProgressionDefinition
	return null

func faction(id: String) -> FactionDefinition:
	for entry in factions:
		if entry != null and entry.faction_id == id: return entry.duplicate(true) as FactionDefinition
	return null

func disposition(source: String, target: String) -> String:
	var definition := faction(source)
	if definition == null or faction(target) == null: return "invalid"
	if source == target: return "friendly"
	return definition.dispositions.get(target, "neutral")

func valid() -> bool:
	var ids := {}
	for family: Array in [races, visuals, classes, progressions, factions]:
		if family.is_empty() or family.size() > 32: return false
		for definition: Resource in family:
			if definition == null or not definition.valid(): return false
			var key := ""
			if definition is RaceDefinition: key = definition.race_id
			elif definition is RaceVisualProfile: key = definition.profile_id
			elif definition is ClassDefinition: key = definition.class_id
			elif definition is ProgressionDefinition: key = definition.progression_id
			elif definition is FactionDefinition: key = definition.faction_id
			if ids.has(key): return false
			ids[key] = true
	for definition in races:
		if visual(definition.visual_profile_id) == null or faction(definition.historical_faction_id) == null: return false
	for definition in classes:
		if progression(definition.progression_id) == null: return false
	for definition in factions:
		for target: String in definition.dispositions:
			if faction(target) == null: return false
	return true
