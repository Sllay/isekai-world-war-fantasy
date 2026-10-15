class_name EnemyBody
extends CharacterBody3D

# Region-owned physical movement port and neutral presentation adapter. No AI,
# health mutation, save data or action timing lives in this Node.
var actor: EnemyActor
var marker := MeshInstance3D.new()

func _ready() -> void:
	position = actor.position
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.75
	add_child(shape)
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.5
	marker.mesh = mesh
	marker.position.y = 0.75
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.75, 0.22, 0.12)
	marker.material_override = material
	add_child(marker)
	floor_snap_length = 0.3
	floor_constant_speed = true

# Invoked once per Core tick, independent of render frequency. CharacterBody
# motion uses explicit displacement via move_and_collide; no render delta.
func approach(destination: Vector3, seconds: float) -> void:
	if actor.combatant.lifecycle != Combatant.Lifecycle.ALIVE:
		return
	position = actor.position
	var delta := destination - position
	delta.y = 0
	if delta.length() > 0.001:
		actor.facing = delta.normalized()
	var motion := delta.limit_length(actor.archetype.speed * seconds)
	var collision := move_and_collide(motion)
	if collision != null:
		move_and_collide(collision.get_remainder().slide(collision.get_normal()))
	move_and_collide(Vector3.DOWN * 0.2)
	actor.position = position

func _process(_delta: float) -> void:
	position = actor.position
	marker.scale.y = 0.25 if actor.combatant.lifecycle == Combatant.Lifecycle.DEFEATED else 1.0
