class_name ActionRuntime
extends RefCounted

# Actor owners bind/unbind this transient registry on residency changes.
var executors: Dictionary[String, ActionExecutor] = {}
var last_result := "NONE"
var _pending: Array[Dictionary] = []

func register(executor: ActionExecutor) -> void:
	executors[executor.owner_id] = executor
	executor.runtime = self

func unregister(id: String) -> void:
	if executors.has(id):
		executors[id].reset_transient()
		executors[id].runtime = null
	executors.erase(id)

func clear() -> void:
	for id in executors.keys():
		unregister(id)
	_pending.clear()
	last_result = "NONE"

func interrupt(id: String) -> CombatResult:
	var result := CombatResult.new()
	result.target_entity = id
	var executor: ActionExecutor = executors.get(id)
	result.code = executor.interrupt() if executor != null else "EXECUTOR_UNAVAILABLE"
	result.accepted = result.code == "CANCELLED"
	last_result = result.code
	return result

func defense_resolved(fact: DefenseResolved) -> void:
	if fact.outcome == "PARRIED" and fact.interrupt_relevant:
		# Events cannot recursively mutate combat/execution. Drain after the
		# committing executor leaves its busy boundary, correlated to that cast.
		_pending.append({"attacker": fact.source_entity, "execution": fact.transaction_id})

func flush() -> void:
	var pending := _pending
	_pending = []
	for request in pending:
		var executor: ActionExecutor = executors.get(request.attacker)
		if executor != null:
			last_result = executor.interrupt_committed(request.execution)
