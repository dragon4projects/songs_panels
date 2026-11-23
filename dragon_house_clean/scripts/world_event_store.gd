extends RefCounted
## Append-oriented local event store used by the v0.20 object-event strangler.
## The backend is deliberately JSON compatibility storage for this slice.
## Event grammar/revision semantics are designed to map to the proven old
## SQLite World Core without making external Python a runtime dependency.

const SCHEMA := 1
const MAX_EVENTS := 16384

var path: String = ""
var events: Array = []
var sequence: int = 0
var status: String = "UNINITIALIZED"
var last_error: String = ""

func backend_name() -> String:
	return "json_append_compat_v1"

func setup(base_save_path: String) -> bool:
	path = base_save_path + ".world_events_v1.json"
	events.clear()
	sequence = 0
	status = "EMPTY"
	last_error = ""
	if _load_path(path):
		status = "READY" if not events.is_empty() else "EMPTY"
		return true
	var primary_exists: bool = FileAccess.file_exists(path)
	var primary_error: String = last_error
	if _load_path(path + ".bak"):
		# Preserve the unreadable primary as evidence instead of rotating it over
		# the good backup on the next append.
		if primary_exists:
			var corrupt: String = path + ".corrupt"
			var corrupt_abs: String = ProjectSettings.globalize_path(corrupt)
			if FileAccess.file_exists(corrupt):
				DirAccess.remove_absolute(corrupt_abs)
			DirAccess.rename_absolute(
				ProjectSettings.globalize_path(path), corrupt_abs)
		status = "RECOVERED_FROM_BACKUP"
		last_error = primary_error
		return true
	if primary_exists or FileAccess.file_exists(path + ".bak"):
		status = "CORRUPT_NO_RECOVERY"
		if last_error == "":
			last_error = primary_error if primary_error != "" else "No readable event store"
		return false
	status = "EMPTY"
	last_error = ""
	return true

func _parse_document(raw: String, source: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(raw) != OK:
		last_error = "%s:%d: %s" % [
			source, parser.get_error_line(), parser.get_error_message()]
		return {}
	if typeof(parser.data) != TYPE_DICTIONARY:
		last_error = source + ": root is not an object"
		return {}
	var doc: Dictionary = parser.data
	if int(doc.get("schema",-1)) != SCHEMA:
		last_error = source + ": unsupported schema"
		return {}
	if typeof(doc.get("events",null)) != TYPE_ARRAY:
		last_error = source + ": events must be an array"
		return {}
	var seen: Dictionary = {}
	var max_seq: int = 0
	for raw_event in doc.get("events",[]):
		if typeof(raw_event) != TYPE_DICTIONARY:
			last_error = source + ": invalid event row"
			return {}
		var event: Dictionary = raw_event
		var event_id: String = str(event.get("event_id",""))
		var seq: int = int(event.get("seq",0))
		if event_id == "" or seq <= 0 or seen.has(event_id):
			last_error = source + ": duplicate/invalid event identity"
			return {}
		seen[event_id] = true
		max_seq = maxi(max_seq,seq)
	var declared: int = int(doc.get("sequence",max_seq))
	if declared < max_seq:
		last_error = source + ": sequence behind event stream"
		return {}
	return doc

func _load_path(source: String) -> bool:
	if not FileAccess.file_exists(source):
		return false
	var file := FileAccess.open(source,FileAccess.READ)
	if file == null:
		last_error = "Cannot open event store: " + source
		return false
	var doc: Dictionary = _parse_document(file.get_as_text(),source)
	file.close()
	if doc.is_empty():
		return false
	events = (doc.get("events",[]) as Array).duplicate(true)
	sequence = int(doc.get("sequence",0))
	return true

func _document(candidate_events: Array, candidate_sequence: int) -> Dictionary:
	return {
		"schema":SCHEMA,
		"sequence":candidate_sequence,
		"events":candidate_events
	}

func _persist(candidate_events: Array, candidate_sequence: int) -> bool:
	if candidate_events.size() > MAX_EVENTS:
		last_error = "Event store limit reached"
		status = "BACKPRESSURE"
		return false
	var scratch: String = path + ".tmp"
	var payload: String = JSON.stringify(
		_document(candidate_events,candidate_sequence),"	") + "
"
	var file := FileAccess.open(scratch,FileAccess.WRITE)
	if file == null:
		last_error = "Cannot open event-store temp file"
		status = "WRITE_FAILED"
		return false
	file.store_string(payload)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
		last_error = "Cannot flush event-store temp file"
		status = "WRITE_FAILED"
		return false
	var verify_file := FileAccess.open(scratch,FileAccess.READ)
	if verify_file == null:
		last_error = "Cannot verify event-store temp file"
		status = "WRITE_FAILED"
		return false
	var verified: Dictionary = _parse_document(verify_file.get_as_text(),scratch)
	verify_file.close()
	if verified.is_empty() or int(verified.get("sequence",-1)) != candidate_sequence:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
		status = "WRITE_FAILED"
		if last_error == "":
			last_error = "Event-store verification failed"
		return false

	var primary_abs: String = ProjectSettings.globalize_path(path)
	var scratch_abs: String = ProjectSettings.globalize_path(scratch)
	var backup: String = path + ".bak"
	var backup_abs: String = ProjectSettings.globalize_path(backup)
	# If primary exists and was readable at setup, rotate it. If setup recovered
	# from backup, primary was already quarantined as .corrupt.
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup):
			DirAccess.remove_absolute(backup_abs)
		if DirAccess.rename_absolute(primary_abs,backup_abs) != OK:
			DirAccess.remove_absolute(scratch_abs)
			last_error = "Cannot rotate event-store backup"
			status = "WRITE_FAILED"
			return false
	if DirAccess.rename_absolute(scratch_abs,primary_abs) != OK:
		if FileAccess.file_exists(backup) and not FileAccess.file_exists(path):
			DirAccess.rename_absolute(backup_abs,primary_abs)
		last_error = "Cannot commit event store"
		status = "WRITE_FAILED"
		return false
	return true

func has_event(event_id: String) -> bool:
	if event_id == "":
		return false
	for raw_event in events:
		var event: Dictionary = raw_event
		if str(event.get("event_id","")) == event_id:
			return true
	return false

func append(event: Dictionary) -> Dictionary:
	var rows: Array = [event]
	var committed: Array = append_many(rows)
	return committed[0] if committed.size() == 1 else {}

func append_many(input_events: Array) -> Array:
	if status == "CORRUPT_NO_RECOVERY" or status == "WRITE_FAILED" or status == "BACKPRESSURE":
		return []
	if input_events.is_empty():
		return []
	var candidate: Array = events.duplicate(true)
	var next_seq: int = sequence
	var committed: Array = []
	var ids: Dictionary = {}
	for existing in events:
		var existing_event: Dictionary = existing
		ids[str(existing_event.get("event_id",""))] = true
	for raw_event in input_events:
		if typeof(raw_event) != TYPE_DICTIONARY:
			last_error = "Cannot append non-object event"
			return []
		var event: Dictionary = (raw_event as Dictionary).duplicate(true)
		var event_id: String = str(event.get("event_id",""))
		if event_id == "" or ids.has(event_id):
			last_error = "duplicate/empty event_id: " + event_id
			return []
		next_seq += 1
		event["seq"] = next_seq
		ids[event_id] = true
		candidate.append(event)
		committed.append(event)
	if not _persist(candidate,next_seq):
		return []
	events = candidate
	sequence = next_seq
	status = "READY"
	last_error = ""
	return committed

func snapshot_events() -> Array:
	return events.duplicate(true)

func events_for_object(object_id: String, limit: int = 64) -> Array:
	if object_id == "" or limit <= 0:
		return []
	var matches: Array = []
	for raw_event in events:
		var event: Dictionary = raw_event
		var payload: Dictionary = event.get("payload",{})
		if str(event.get("object_id",payload.get("object_id",""))) != object_id:
			continue
		matches.append(event.duplicate(true))
	var start: int = maxi(0,matches.size()-limit)
	return matches.slice(start,matches.size())

func last_sequence() -> int:
	return sequence

func storage_path() -> String:
	return path
