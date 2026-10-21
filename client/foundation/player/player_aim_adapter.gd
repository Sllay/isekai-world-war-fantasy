class_name PlayerAimAdapter
extends RefCounted

# View-only candidate generation. Neither a camera ray nor this plane is hit truth.
# Touch/third-person adapters can emit the same PlayerIntent world values.
static func project(camera: Camera3D, screen: Vector2, origin: Vector3) -> Variant:
	if camera == null or not screen.is_finite() or not origin.is_finite():
		return null
	var from := camera.project_ray_origin(screen)
	var ray := camera.project_ray_normal(screen)
	return Plane(Vector3.UP, origin.y).intersects_ray(from, ray)

static func apply(intent: PlayerIntent, point: Vector3, origin: Vector3) -> bool:
	if not point.is_finite() or not origin.is_finite():
		return false
	var toward := point - origin
	toward.y = 0
	if toward.length_squared() < 0.0001 or toward.length_squared() > 100000000:
		return false
	intent.aim_direction = toward.normalized()
	intent.aim_point = point
	return true
