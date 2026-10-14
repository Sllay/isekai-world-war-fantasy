class_name CoreEventBus
extends RefCounted

var diagnostics: CoreDiagnostics
var max_dispatch_depth: int = 32
var _types: Dictionary = {}
var _subscriptions: Dictionary = {}
var _next_token: int = 1
var _depth: int = 0

func define(event_type: Script) -> Error:
	if event_type == null or not event_type.can_instantiate() or _types.has(event_type):
		return ERR_INVALID_PARAMETER
	var instance: Variant = event_type.new()
	if not instance is CoreEvent:
		return ERR_INVALID_DATA
	_types[event_type] = true
	return OK

func subscribe(event_type: Script, callback: Callable) -> int:
	if not _types.has(event_type) or not callback.is_valid():
		return 0
	var token := _next_token
	_next_token += 1
	_subscriptions[token] = {"type": event_type, "callback": callback}
	return token

func unsubscribe(token: int) -> void:
	_subscriptions.erase(token)

# Delivery is synchronous, subscription ordered, exact script typed.
# New subscriptions begin on the next publish; removed callbacks are skipped.
func publish(event: CoreEvent) -> Error:
	if event == null or not _types.has(event.get_script()) or not CoreIds.valid(event.source_module):
		return ERR_INVALID_PARAMETER
	if _depth >= max_dispatch_depth:
		return ERR_BUSY
	_depth += 1
	for token in _subscriptions.keys():
		if not _subscriptions.has(token):
			continue
		var subscription: Dictionary = _subscriptions[token]
		if subscription.type == event.get_script() and subscription.callback.is_valid():
			subscription.callback.call(event)
	_depth -= 1
	if diagnostics != null:
		diagnostics.record("trace", event.source_module, "event_published", {"event_id": event.event_id, "tick": event.tick, "correlation_id": event.correlation_id})
	return OK

func clear() -> void:
	_subscriptions.clear()
	_types.clear()
