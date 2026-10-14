class_name CoreModuleRegistry
extends RefCounted

enum State { NEW, VALIDATED, RUNNING, STOPPED, FAILED }
var state: State = State.NEW
var modules: Dictionary = {}
var statuses: Dictionary = {}
var order: Array[CoreModule] = []
var services := CoreServices.new()
var diagnostics := CoreDiagnostics.new()
var flags := CoreFeatureFlags.new()
var _visited: Dictionary = {}
var _active: Dictionary = {}
var _prepared: Array[CoreModule] = []
var _started: Array[CoreModule] = []

func add(module: CoreModule) -> Error:
	if state != State.NEW or module == null or not CoreIds.valid(module.id) or modules.has(module.id):
		return ERR_INVALID_PARAMETER
	modules[module.id] = module
	statuses[module.id] = "discovered"
	return OK

func _fail(id: String, reason: String) -> Error:
	state = State.FAILED
	statuses[id] = reason
	diagnostics.record("error", id, "module_validation_failed", {"reason": reason})
	return ERR_INVALID_DATA

func validate() -> Error:
	if state != State.NEW:
		return ERR_ALREADY_IN_USE
	var contracts: Dictionary = {}
	for id in modules:
		var module: CoreModule = modules[id]
		if not module.feature_flag.is_empty() and not CoreIds.valid(module.feature_flag):
			return _fail(id, "invalid feature flag")
		if not module.feature_flag.is_empty() and not flags.enabled(module.feature_flag):
			statuses[id] = "disabled"
			continue
		if module.version.is_empty() or module.state_version < 1:
			return _fail(id, "invalid version")
		for contract in module.provides:
			if not CoreIds.valid(contract) or contracts.has(contract):
				return _fail(id, "invalid or duplicate contract: " + contract)
			contracts[contract] = id
		for declaration in [module.provides, module.published_events, module.consumed_events, module.data_ids]:
			var seen: Dictionary = {}
			for declared_id in declaration:
				if not CoreIds.valid(declared_id) or seen.has(declared_id):
					return _fail(id, "invalid or duplicate declaration: " + declared_id)
				seen[declared_id] = true
		var dependencies: Dictionary = {}
		for dependency in module.requires + module.optional:
			if dependencies.has(dependency):
				return _fail(id, "duplicate dependency: " + dependency)
			dependencies[dependency] = true
			var layer: String = id.get_slice(".", 0)
			var dependency_layer := dependency.get_slice(".", 0)
			if (layer == "core" and dependency_layer != "core") or (layer == "foundation" and dependency_layer not in ["core", "foundation"]):
				return _fail(id, "dependency violates layer direction: " + dependency)
			if not CoreIds.valid(dependency):
				return _fail(id, "invalid dependency: " + dependency)
	var ids := modules.keys()
	ids.sort()
	for id in ids:
		if statuses[id] != "disabled" and not _visit(id):
			return ERR_INVALID_DATA
	state = State.VALIDATED
	return OK

func _visit(id: String) -> bool:
	if _active.has(id):
		_fail(id, "dependency cycle")
		return false
	if _visited.has(id):
		return true
	_active[id] = true
	var module: CoreModule = modules[id]
	for dependency in module.requires:
		if not modules.has(dependency) or statuses[dependency] == "disabled":
			_fail(id, "missing required dependency: " + dependency)
			return false
	for dependency in module.requires + module.optional:
		if modules.has(dependency) and statuses[dependency] != "disabled" and not _visit(dependency):
			return false
	_active.erase(id)
	_visited[id] = true
	order.append(module)
	statuses[id] = "validated"
	return true

func boot() -> Error:
	if state == State.NEW and validate() != OK:
		return ERR_INVALID_DATA
	if state != State.VALIDATED:
		return ERR_ALREADY_IN_USE
	for module in order:
		_prepared.append(module)
		services.enter(module)
		var error := module.register(services)
		services.leave()
		if error != OK:
			return _abort(module, error)
	for module in order:
		for contract in module.provides:
			if contract not in services.inspect():
				return _abort(module, ERR_DOES_NOT_EXIST)
		services.enter(module)
		var error := module.initialize(services)
		services.leave()
		if error != OK:
			return _abort(module, error)
	for module in order:
		_started.append(module)
		var error := module.start()
		if error != OK:
			return _abort(module, error)
		statuses[module.id] = "running"
	state = State.RUNNING
	diagnostics.record("info", "core.lifecycle", "runtime_started", {"modules": order.size()})
	return OK

func _abort(module: CoreModule, error: Error) -> Error:
	shutdown()
	state = State.FAILED
	statuses[module.id] = "failed"
	diagnostics.record("error", module.id, "startup_failed", {"error": error})
	return error

func shutdown() -> void:
	for index in range(_started.size() - 1, -1, -1):
		_started[index].stop()
	for index in range(_prepared.size() - 1, -1, -1):
		_prepared[index].dispose()
		statuses[_prepared[index].id] = "disposed"
	_started.clear()
	_prepared.clear()
	services.clear()
	state = State.STOPPED
