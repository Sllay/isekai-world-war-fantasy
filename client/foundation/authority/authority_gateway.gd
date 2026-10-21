class_name AuthorityGateway
extends RefCounted

# Disconnected transport contract: there is deliberately no local fallback.
func request(_kind: String, _payload: Dictionary = {}) -> Dictionary:
	return {"accepted": false, "code": "DISCONNECTED"}

func snapshot() -> Dictionary:
	return {}
