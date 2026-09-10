class_name MonsterProgress
extends RefCounted
## Only permanent monster IDs are stored here. No currencies or run data.
const SAVE_PATH: String = "user://meta_progress.json"
const VERSION: int = 1

static func load_ids(path: String = SAVE_PATH) -> Array[StringName]:
	var ids: Array[StringName] = []
	if not FileAccess.file_exists(path):
		return ids
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Cannot read monster progress at %s: %s. Starting with no unlocks." % [path, error_string(FileAccess.get_open_error())])
		return ids
	var text: String = file.get_as_text()
	var read_error: Error = file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		push_warning("Cannot read monster progress at %s: %s. Starting with no unlocks." % [path, error_string(read_error)])
		return ids
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("Invalid monster progress JSON at %s, line %d: %s. File left untouched; starting with no unlocks." % [path, json.get_error_line(), json.get_error_message()])
		return ids
	var data: Variant = json.data
	if not data is Dictionary or data.get("version") != VERSION:
		push_warning("Unsupported monster progress format/version at %s. File left untouched; starting with no unlocks." % path)
		return ids
	var saved: Variant = data.get("unlocked_monsters", [])
	if not saved is Array:
		push_warning("Invalid unlocked_monsters list at %s. File left untouched; starting with no unlocks." % path)
		return ids
	for entry: Variant in saved:
		if entry is String:
			var id := StringName(entry)
			if CardCatalog.MONSTER_CARDS.has(id) and not ids.has(id):
				ids.append(id)
	return ids

static func save_ids(ids: Array[StringName], path: String = SAVE_PATH) -> bool:
	var recognized: Array[String] = []
	for id: StringName in ids:
		if CardCatalog.MONSTER_CARDS.has(id) and not recognized.has(String(id)):
			recognized.append(String(id))
	recognized.sort()
	# Replace only after a complete write, so interrupted writes retain the old save.
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _write_failed(path, FileAccess.get_open_error())
	file.store_string(JSON.stringify({"version": VERSION, "unlocked_monsters": recognized}, "\t") + "\n")
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return _write_failed(path, write_error)
	var rename_error: Error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if rename_error != OK:
		return _write_failed(path, rename_error)
	return true

static func _write_failed(path: String, error: Error) -> bool:
	push_warning("Could not save monster progress at %s: %s. Unlocks remain available this session but may not survive closing the game." % [path, error_string(error)])
	return false
