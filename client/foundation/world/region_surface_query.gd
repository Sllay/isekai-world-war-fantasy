class_name RegionSurfaceQuery
extends RefCounted

# Transient port. Context selects an appropriate local surface, never global max Y.
# New terrain/layer adapters can override both methods without changing recovery.
func expected_height(_position: Vector3, _context: String) -> Variant:
	return null

func candidate_above(_position: Vector3, _context: String, _offset: float) -> RegionSurfaceCandidate:
	return null
