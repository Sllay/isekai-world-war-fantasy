extends Node3D

# Debug-only acceptance fixture, not enemy/training-target production content.
# One transient Core entity + real Combatant. No AI, save state or second combat.
var combat: CombatService
var player: PlayerState
var target: Combatant
var target_position := Vector3.ZERO
var marker := MeshInstance3D.new()
var status := Label.new()

class HarnessPolicy extends CombatTargetPolicy:
	var target_id := ""
	var previous: CombatTargetPolicy
	func relationship(source: String, destination: String) -> Relationship:
		if source == target_id or destination == target_id:
			return Relationship.ENEMY
		return previous.relationship(source, destination)

var policy: HarnessPolicy

func _ready() -> void:
	target = combat.register(combat.entities.create(), "combat.profile.standard")
	target_position = player.position + Vector3(0, 0, -1.5)
	policy = HarnessPolicy.new()
	policy.target_id = target.entity_id
	policy.previous = combat.target_policy
	combat.target_policy = policy
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.35
	mesh.bottom_radius = 0.35
	mesh.height = 1.5
	marker.mesh = mesh
	marker.position = target_position + Vector3(0, 0.75, 0)
	add_child(marker)
	var layer := CanvasLayer.new()
	add_child(layer)
	status.position = Vector2(20, 145)
	layer.add_child(status)

func position_of(id: String) -> Variant:
	if id == player.entity_id:
		return player.position
	if target != null and id == target.entity_id:
		return target_position
	return null

func target_id() -> String:
	return target.entity_id

func _process(_delta: float) -> void:
	status.text = "Dev target HP %d/%d (fixed at session entry)" % [target.health, target.max_health()]

func development_state() -> Dictionary:
	return {"entity_id": target.entity_id, "health": target.health, "position": target_position}

func _exit_tree() -> void:
	if target != null:
		combat.unregister(target.entity_id)
		# Core's saved identity set must never contain this development fixture.
		var identities := combat.entities.capture()
		identities.ids.erase(target.entity_id)
		combat.entities.restore(identities)
	if combat.target_policy == policy:
		combat.target_policy = policy.previous
