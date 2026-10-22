class_name CoreSavePages
extends RefCounted

# Physical adapter for the SAME logical Core snapshot. Immutable record pages are
# written first; the ordinary atomic manifest rename is the only commit point.
const SCHEMA := 1
const MAX_PAGES := 1024
const MAX_PAGE_BYTES := 2097152
var metrics := {"pages_written": 0, "pages_reused": 0, "bytes_written": 0, "pages_loaded": 0, "load_us": 0}

func write(path: String, snapshot: Dictionary, members: Dictionary, atomic_write: Callable) -> Error:
	var manifest := snapshot.duplicate(true)
	var locations := {}
	var hashes := {}
	var started := Time.get_ticks_usec()
	var directory := path + ".pages"
	var error := DirAccess.make_dir_recursive_absolute(directory)
	if error != OK: return error
	for section: String in members:
		if not manifest.sections.has(section): continue
		var member: String = members[section]
		var state: Dictionary = manifest.sections[section].state
		if not state.get(member) is Dictionary: return ERR_INVALID_DATA
		var refs := {}
		for key: String in state[member]:
			var bytes := JSON.stringify(_encode(state[member][key]), "", true, true).to_utf8_buffer()
			if bytes.size() > MAX_PAGE_BYTES: return ERR_OUT_OF_MEMORY
			var hash_value := bytes.hex_encode().sha256_text()
			var page_path := directory.path_join(hash_value + ".json")
			if not FileAccess.file_exists(page_path):
				var file := FileAccess.open(page_path + ".tmp", FileAccess.WRITE)
				if file == null: return FileAccess.get_open_error()
				file.store_buffer(bytes)
				file.flush()
				error = file.get_error()
				file.close()
				if error != OK: return error
				error = DirAccess.rename_absolute(page_path + ".tmp", page_path)
				if error != OK: return error
				metrics.pages_written += 1
				metrics.bytes_written += bytes.size()
			else:
				# Never trust a stale/corrupt cache merely because its name matches.
				if FileAccess.get_file_as_bytes(page_path) != bytes: return ERR_FILE_CORRUPT
				metrics.pages_reused += 1
			refs[key] = hash_value
			hashes[hash_value] = true
			if hashes.size() > MAX_PAGES: return ERR_OUT_OF_MEMORY
		state[member] = refs
		locations[section] = member
	manifest["_core_pages"] = {"schema": SCHEMA, "members": locations}
	# The same lossless codec protects unpaged state too (notably the Core
	# clock's fractional remainder). Paging must not change simulation precision.
	error = atomic_write.call(path, _encode(manifest))
	if error == OK:
		# One writer per slot, as before. Only unreachable immutable pages are
		# retired AFTER the new manifest commits. Never touch unrelated files.
		for file_name in DirAccess.get_files_at(directory):
			var hash_value := file_name.trim_suffix(".json")
			if file_name.ends_with(".json") and _hash(hash_value) and not hashes.has(hash_value): DirAccess.remove_absolute(directory.path_join(file_name))
	metrics["last_write_us"] = Time.get_ticks_usec() - started
	return error

func hydrate(path: String, manifest: Dictionary) -> Dictionary:
	var started := Time.get_ticks_usec()
	var decoded_manifest: Variant = _decode(manifest)
	if not decoded_manifest is Dictionary: return {}
	manifest = decoded_manifest
	var header: Variant = manifest.get("_core_pages")
	if not header is Dictionary or header.size() != 2 or header.get("schema") != SCHEMA or not header.get("members") is Dictionary or header.members.size() > 32 or not manifest.get("sections") is Dictionary: return {}
	var result := manifest.duplicate(true)
	var count := 0
	for section: Variant in header.members:
		var member: Variant = header.members[section]
		if not section is String or not member is String or not result.sections.get(section) is Dictionary or not result.sections[section].get("state") is Dictionary: return {}
		var state: Dictionary = result.sections[section].state
		if not state.get(member) is Dictionary: return {}
		var records := {}
		for key: Variant in state[member]:
			var hash_value: Variant = state[member][key]
			if not key is String or not hash_value is String or not _hash(hash_value): return {}
			count += 1
			if count > MAX_PAGES: return {}
			var bytes := FileAccess.get_file_as_bytes((path + ".pages").path_join(hash_value + ".json"))
			if bytes.is_empty() or bytes.size() > MAX_PAGE_BYTES or bytes.hex_encode().sha256_text() != hash_value: return {}
			var value: Variant = JSON.parse_string(bytes.get_string_from_utf8())
			if not value is Dictionary: return {}
			var decoded: Variant = _decode(value)
			if not decoded is Dictionary: return {}
			records[key] = decoded
			metrics.pages_loaded += 1
		state[member] = records
	result.erase("_core_pages")
	metrics.load_us = Time.get_ticks_usec() - started
	return result

static func _hash(value: String) -> bool:
	return value.length() == 64 and value == value.to_lower() and value.is_valid_hex_number(false)

# Lossless record codec: JSON's parser can alter the final bits of fractional
# doubles. Integer-valued numbers normalize; other doubles keep their IEEE bytes.
# Clock fractions and domain precision must never be rounded to obtain cache hits.
static func _encode(value: Variant) -> Variant:
	if value is float:
		if is_finite(value) and absf(value) <= 9007199254740991.0 and value == int(value): return int(value)
		return {"_core_float64": PackedFloat64Array([value]).to_byte_array().hex_encode()}
	if value is Array:
		var result: Array = []
		for entry: Variant in value: result.append(_encode(entry))
		return result
	if value is Dictionary:
		var result := {}
		for key: String in value: result[key] = _encode(value[key])
		return {"_core_object": result} if value.has("_core_float64") or value.has("_core_object") else result
	return value

static func _decode(value: Variant) -> Variant:
	if value is Array:
		var result: Array = []
		for entry: Variant in value: result.append(_decode(entry))
		return result
	if value is Dictionary:
		if value.size() == 1 and value.has("_core_float64"):
			var hex_value: Variant = value._core_float64
			if not hex_value is String or hex_value.length() != 16 or not hex_value.is_valid_hex_number(false): return null
			var bytes: PackedByteArray = hex_value.hex_decode()
			var number := bytes.to_float64_array()[0]
			if not is_finite(number): return null
			return number
		var content: Dictionary = value
		if value.size() == 1 and value.get("_core_object") is Dictionary: content = value._core_object
		var result := {}
		for key: String in content: result[key] = _decode(content[key])
		return result
	return int(value) if value is float and value == int(value) and absf(value) <= 9007199254740991.0 else value
