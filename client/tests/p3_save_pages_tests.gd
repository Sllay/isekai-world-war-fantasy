extends SceneTree

var checks := 0
var failures := 0
var slot := ""
var store := CoreSaveStore.new()
const MEMBERS := {"foundation.world_genesis": "chunks", "gameplay.living": "actors"}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func fixture() -> Dictionary:
	return {"format_version": 1, "game_version": "0.5.0", "world_id": "world.test_pages", "world_seed": 741,
		"modules": {"foundation.world_genesis": "1.0.0", "gameplay.living": "1.0.0", "foundation.player": "1.0.0"},
		"sections": {
			"foundation.world_genesis": {"version": 1, "state": {"identity": "world.test_pages", "chunks": {
				"chunk.a": {"id": "chunk.a", "height_mm": [0, 1000, 2000], "delta": {"removed": false}},
				"chunk.b": {"id": "chunk.b", "height_mm": [1000, 2000, 3000], "delta": {"removed": false}}}}},
			"gameplay.living": {"version": 1, "state": {"actors": {
				"actor.a": {"id": "actor.a", "health": 85, "position": [1.5, 0.000220715650357306, 2.0], "fraction": 0.123456789123456, "annotations": [{"_core_float64": "literal_data"}, {"_core_object": {"note": "literal_object"}}]},
				"actor.b": {"id": "actor.b", "health": 100, "position": [4.5, 0.25, 2.0]}}}},
			"foundation.player": {"version": 1, "state": {"health": 42, "position": [1.5, 0.25, 2.0], "clock_fraction": 1.38777878078145e-17}}}}

func same(a: Dictionary, b: Dictionary) -> bool:
	return WorldGenIds.digest(a) == WorldGenIds.digest(b)

func physical() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(slot))

func overwrite(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()

func run() -> void:
	slot = "user://tests/p3-pages-%s.json" % CoreIds.generate()
	store.page_members = MEMBERS.duplicate()
	var initial := fixture()
	check(store.write_snapshot(slot, initial) == OK, "existing CoreSaveStore writes one logical snapshot with paged records")
	check(store.pages.metrics.pages_written == 4 and store.pages.metrics.pages_reused == 0, "initial write creates only four bounded immutable pages")
	var manifest := physical()
	check(manifest.format_version == CoreSaveStore.FORMAT_VERSION and manifest._core_pages.schema == 1 and manifest._core_pages.members == MEMBERS, "physical paging preserves existing Core format and module ownership")
	check(same(CoreSavePages._decode(manifest.sections["foundation.player"]), initial.sections["foundation.player"]), "ordinary unpaged section remains in the same manifest with the lossless codec")
	var old_chunk_hash: String = manifest.sections["foundation.world_genesis"].state.chunks["chunk.a"]
	check(CoreSavePages._hash(old_chunk_hash) and FileAccess.file_exists((slot + ".pages").path_join(old_chunk_hash + ".json")), "manifest references safe content hash, not arbitrary external path")
	check(same(store.read_snapshot(slot), initial) and not store.read_snapshot(slot).has("_core_pages"), "read hydrates exact canonical logical snapshot without physical adapter header")
	var decoded_actor: Dictionary = store.read_snapshot(slot).sections["gameplay.living"].state.actors["actor.a"]
	var original_actor: Dictionary = initial.sections["gameplay.living"].state.actors["actor.a"]
	check(decoded_actor.position[1] == original_actor.position[1] and decoded_actor.fraction == original_actor.fraction, "fractional transform and clock-like value preserve exact IEEE bits")
	check(decoded_actor.annotations == original_actor.annotations, "literal reserved codec tag objects remain ordinary data")
	check(store.read_snapshot(slot).sections["foundation.player"].state.clock_fraction == initial.sections["foundation.player"].state.clock_fraction, "unpaged tiny clock fractions retain exact IEEE precision too")
	check(store.read_snapshot(slot).sections["foundation.player"].state.position == initial.sections["foundation.player"].state.position, "integral float coordinates preserve their canonical numeric types")
	check(store.write_snapshot(slot, initial) == OK and store.pages.metrics.pages_written == 4 and store.pages.metrics.pages_reused == 4, "unchanged records reuse pages without rewriting immutable world data")
	var after_read := store.read_snapshot(slot)
	var written: int = store.pages.metrics.pages_written
	check(store.write_snapshot(slot, after_read) == OK and store.pages.metrics.pages_written == written, "freshly parsed unchanged state reuses identical page bytes")
	var changed := initial.duplicate(true)
	changed.sections["foundation.world_genesis"].state.chunks["chunk.a"].delta.removed = true
	written = store.pages.metrics.pages_written
	check(store.write_snapshot(slot, changed) == OK and store.pages.metrics.pages_written == written + 1, "one dirty chunk writes one new immutable page")
	check(same(store.read_snapshot(slot), changed), "modified chunk hydrates while unchanged actor/chunk data remains coherent")
	check(not FileAccess.file_exists((slot + ".pages").path_join(old_chunk_hash + ".json")), "unreachable prior chunk page retired only after successful manifest commit")
	manifest = physical()
	var kept_hash: String = manifest.sections["foundation.world_genesis"].state.chunks["chunk.a"]
	var kept_path := (slot + ".pages").path_join(kept_hash + ".json")
	var committed_bytes := FileAccess.get_file_as_bytes(slot)
	var rejected := changed.duplicate(true)
	rejected.sections["gameplay.living"].state.actors["actor.a"].health = 1
	var before_failure: PackedStringArray = DirAccess.get_files_at(slot + ".pages")
	var failed: Error = store.pages.write(slot, rejected, MEMBERS, func(_path: String, _value: Dictionary) -> Error: return ERR_CANT_CREATE)
	var orphan_path := ""
	for name in DirAccess.get_files_at(slot + ".pages"):
		if name not in before_failure: orphan_path = (slot + ".pages").path_join(name)
	check(failed == ERR_CANT_CREATE and FileAccess.get_file_as_bytes(slot) == committed_bytes, "manifest failure preserves committed bytes and does not publish staged actor mutation")
	check(same(store.read_snapshot(slot), changed) and FileAccess.file_exists(kept_path), "after failed commit old referenced pages remain readable")
	check(FileAccess.file_exists(orphan_path), "failed new page remains unreachable, not visible as gameplay state")
	var unrelated := (slot + ".pages").path_join("keep.notes")
	overwrite(unrelated, "unrelated".to_utf8_buffer())
	check(store.write_snapshot(slot, changed) == OK and not FileAccess.file_exists(orphan_path), "next successful checkpoint cleans unreachable failed-transaction page")
	check(FileAccess.get_file_as_string(unrelated) == "unrelated", "page cleanup does not touch unrelated files")
	var valid_page := FileAccess.get_file_as_bytes(kept_path)
	overwrite(kept_path, "corrupt".to_utf8_buffer())
	check(store.read_snapshot(slot).is_empty(), "corrupted persisted page rejects instead of loading partial canonical state")
	committed_bytes = FileAccess.get_file_as_bytes(slot)
	check(store.write_snapshot(slot, changed) == ERR_FILE_CORRUPT and FileAccess.get_file_as_bytes(slot) == committed_bytes, "corrupt named cache cannot be silently reused or publish a manifest")
	overwrite(kept_path, valid_page)
	check(same(store.read_snapshot(slot), changed), "restoring known valid page recovers exact canonical state")
	DirAccess.remove_absolute(kept_path)
	check(store.read_snapshot(slot).is_empty(), "missing persisted page rejects, never generates replacement world data")
	overwrite(kept_path, valid_page)
	var forged := physical()
	forged.sections["foundation.world_genesis"].state.chunks["chunk.a"] = "../../other-save"
	check(store.pages.hydrate(slot, forged).is_empty(), "malicious page path cannot escape hash-only page directory")
	forged = physical()
	forged.sections["foundation.world_genesis"].state.chunks["chunk.a"] = kept_hash.to_upper()
	check(store.pages.hydrate(slot, forged).is_empty(), "noncanonical uppercase hash rejected")
	forged = physical()
	forged._core_pages.members["foundation.missing"] = "actors"
	check(store.pages.hydrate(slot, forged).is_empty(), "unknown paged section rejected before hydrate")
	forged = physical()
	forged._core_pages.schema = 2
	check(store.pages.hydrate(slot, forged).is_empty(), "incompatible page schema rejected visibly")
	for name in DirAccess.get_files_at(slot + ".pages"): DirAccess.remove_absolute((slot + ".pages").path_join(name))
	DirAccess.remove_absolute(slot + ".pages")
	DirAccess.remove_absolute(slot)
	DirAccess.remove_absolute(slot + ".tmp")
	check(not FileAccess.file_exists(slot) and not DirAccess.dir_exists_absolute(slot + ".pages"), "isolated page fixture and slot cleaned")
	await process_frame
	print("P3 save pages tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
