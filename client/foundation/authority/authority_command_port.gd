class_name AuthorityCommandPort
extends RefCounted

# Trusted application composition extends payload semantics, never authentication,
# sequence checks or the bounded host inbox. An unbound capability fails closed.
func validate(_kind: String, _payload: Dictionary) -> String:
	return "UNKNOWN_COMMAND"

func execute(_actor: String, _kind: String, _payload: Dictionary) -> String:
	return "CAPABILITY_UNAVAILABLE"

func dispose() -> void:
	pass
