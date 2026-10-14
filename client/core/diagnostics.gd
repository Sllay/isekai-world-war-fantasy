class_name CoreDiagnostics
extends RefCounted

var capacity: int = 128
var records: Array[Dictionary] = []

func record(level: String, module_id: String, code: String, context: Dictionary = {}) -> void:
	var entry := {"level": level, "module": module_id, "code": code, "context": context.duplicate(true)}
	records.append(entry)
	while records.size() > maxi(0, capacity):
		records.pop_front()
	print(JSON.stringify(entry))
