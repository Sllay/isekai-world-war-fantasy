class_name PlayerPresentation
extends Node3D

# Visual adapters override apply_pose. Movement never references this contract.
# Rig adapters own body parts, bones/IK, accessory/equipment layers and attachment
# transforms. View-specific ordering belongs to the adapter, never physical state.
var direction := "front"
var mirrored := false
var attachment_points: Dictionary[StringName, Node3D] = {}

static func resolve_view(facing: Vector3, camera_yaw: float) -> Dictionary:
	var relative := facing.rotated(Vector3.UP, -camera_yaw)
	if absf(relative.x) > absf(relative.z):
		return {"direction": "side", "mirrored": relative.x < 0}
	return {"direction": "front" if relative.z > 0 else "back", "mirrored": false}

func present(state: PlayerState, camera_yaw: float) -> void:
	position = state.position
	var view := resolve_view(state.facing, camera_yaw)
	direction = view.direction
	mirrored = view.mirrored
	apply_pose(state, view)

func apply_pose(_state: PlayerState, _view: Dictionary) -> void:
	pass
