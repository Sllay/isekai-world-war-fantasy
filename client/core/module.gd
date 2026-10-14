class_name CoreModule
extends RefCounted

var id: String
var version: String = "1.0.0"
var requires: Array[String] = []
var optional: Array[String] = []
var provides: Array[String] = []
var published_events: Array[String] = []
var consumed_events: Array[String] = []
var data_ids: Array[String] = []
var state_version: int = 1
var persistent: bool = false
var feature_flag: String = ""

func register(_services: CoreServices) -> Error:
	return OK

func initialize(_services: CoreServices) -> Error:
	return OK

func start() -> Error:
	return OK

func stop() -> void:
	pass

func dispose() -> void:
	pass

func capture_state() -> Dictionary:
	return {}

# Validation must be side-effect free. Restore is infallible after validation.
func validate_state(_state: Dictionary) -> Error:
	return OK

func restore_state(_state: Dictionary) -> void:
	pass

# Override to migrate exactly one version forward; null means unsupported.
func migrate_state(_from_version: int, _state: Dictionary) -> Variant:
	return null
