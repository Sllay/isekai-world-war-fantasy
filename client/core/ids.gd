class_name CoreIds
extends RefCounted

static func valid(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[a-z][a-z0-9_]*(\\.[a-z][a-z0-9_]*)+$")
	return regex.search(value) != null

static func generate() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()
