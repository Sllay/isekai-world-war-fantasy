class_name LoopbackAuthorityGateway
extends AuthorityGateway

var _host: LocalAuthorityHost
var _session := ""
var _sequence := 0
var connected := true

func _init(host: LocalAuthorityHost, session: String) -> void:
	_host = host
	_session = session

func request(kind: String, payload: Dictionary = {}) -> Dictionary:
	if not connected:
		return super.request(kind, payload)
	_sequence += 1
	return _host.submit(_session, {"version": 1, "sequence": _sequence, "tick": _host.combat.clock.tick, "kind": kind, "payload": payload.duplicate(true)})

func snapshot() -> Dictionary:
	return _host.snapshot() if connected else {}
