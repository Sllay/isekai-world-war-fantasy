class_name TargetingModule
extends CoreModule

var service := TargetingService.new()

func _init() -> void:
	id = "foundation.targeting"
	requires.assign(["foundation.combat"])
	provides.assign(["foundation.targeting"])

func register(services: CoreServices) -> Error:
	return services.provide("foundation.targeting", service)

func initialize(services: CoreServices) -> Error:
	service.combat = services.resolve("foundation.combat") as CombatService
	if service.combat == null:
		return ERR_UNCONFIGURED
	service.combat.target_policy = service.disposition
	return OK

func dispose() -> void:
	service.clear()
	service.disposition.groups.clear()
	service.combat.target_policy = CombatTargetPolicy.new()
