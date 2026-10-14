class_name CoreEvent
extends RefCounted

var event_id: String = CoreIds.generate()
var schema_version: int = 1
var tick: int = 0
var source_module: String = ""
var correlation_id: String = ""
