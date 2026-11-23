extends RefCounted
## SQLite backend proof for the v0.20 object-event strangler.
## Mirrors the accepted JSON store API while restoring the old Iteration-2
## transaction boundary: canonical event append + derived object projection
## commit atomically in one SQLite transaction.
##
## The SQLite GDExtension is discovered dynamically. This file parses and the
## normal production JSON backend remains usable when the addon is absent.

var path: String = ""
var events: Array = []
var sequence: int = 0
var status: String = "UNINITIALIZED"
var last_error: String = ""
var db: Object = null

func backend_name() -> String:
	return "sqlite_v021_proof"

func storage_path() -> String:
	return path

func last_sequence() -> int:
	return sequence

func _db_error(prefix: String) -> bool:
	last_error = prefix
	if db != null:
		var detail: String = str(db.get("error_message"))
		if detail != "":
			last_error += ": " + detail
	return false

func _query(sql: String, bindings: Array = []) -> bool:
	if db == null:
		last_error = "SQLite connection is unavailable"
		return false
	var ok: bool
	if bindings.is_empty():
		ok = bool(db.call("query",sql))
	else:
		ok = bool(db.call("query_with_bindings",sql,bindings))
	if not ok:
		return _db_error("SQLite query failed")
	return true

func _rows() -> Array:
	if db == null:
		return []
	var value = db.get("query_result")
	return value.duplicate(true) if value is Array else []

func _copy_file(source: String, target: String) -> bool:
	if not FileAccess.file_exists(source):
		return false
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(source)
	if bytes.is_empty() and FileAccess.get_file_as_string(source) != "":
		return false
	var file := FileAccess.open(target,FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	file.flush()
	var err: Error = file.get_error()
	file.close()
	return err == OK

func _open_current() -> bool:
	if not ClassDB.class_exists("SQLite"):
		status = "SQLITE_UNAVAILABLE"
		last_error = "SQLite GDExtension is not loaded"
		return false
	db = ClassDB.instantiate("SQLite")
	if db == null:
		status = "SQLITE_UNAVAILABLE"
		last_error = "Cannot instantiate SQLite GDExtension"
		return false
	db.set("path",path)
	db.set("verbosity_level",0)
	db.set("foreign_keys",true)
	if not bool(db.call("open_db")):
		status = "CORRUPT_NO_RECOVERY"
		return _db_error("Cannot open SQLite event store")
	return true

func _close() -> void:
	if db != null:
		db.call("close_db")
		db = null

func _initialize_schema() -> bool:
	var statements := [
		"PRAGMA foreign_keys=ON;",
		"PRAGMA journal_mode=WAL;",
		"PRAGMA synchronous=FULL;",
		"CREATE TABLE IF NOT EXISTS schema_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);",
		"""CREATE TABLE IF NOT EXISTS events (
			seq INTEGER PRIMARY KEY AUTOINCREMENT,
			event_id TEXT NOT NULL UNIQUE,
			created_at REAL NOT NULL,
			source_type TEXT NOT NULL,
			source_id TEXT NOT NULL,
			authority TEXT NOT NULL,
			truth_class TEXT NOT NULL,
			visibility TEXT NOT NULL,
			event_type TEXT NOT NULL,
			subject_id TEXT,
			object_id TEXT,
			room_id TEXT,
			from_value TEXT,
			to_value TEXT,
			expires_at REAL,
			reversibility TEXT NOT NULL,
			provenance TEXT NOT NULL,
			notes TEXT,
			payload_json TEXT NOT NULL
		);""",
		"CREATE INDEX IF NOT EXISTS idx_events_object ON events(object_id,seq);",
		"CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type,seq);",
		"""CREATE TABLE IF NOT EXISTS objects (
			object_id TEXT PRIMARY KEY,
			canonical_owner TEXT,
			current_holder TEXT,
			current_location TEXT,
			state TEXT NOT NULL,
			last_explicit_location TEXT,
			movement_reason TEXT,
			movement_authority TEXT,
			ambient_move_allowed INTEGER NOT NULL DEFAULT 0,
			ambient_hide_allowed INTEGER NOT NULL DEFAULT 0,
			ambient_protected INTEGER NOT NULL DEFAULT 0,
			updated_event_id TEXT,
			projection_json TEXT NOT NULL
		);""",
		"INSERT OR REPLACE INTO schema_meta(key,value) VALUES('schema_version','21');"
	]
	for sql in statements:
		if not _query(str(sql)):
			return false
	return true

func _decode_event(row: Dictionary) -> Dictionary:
	var payload = JSON.parse_string(str(row.get("payload_json","{}")))
	if typeof(payload) != TYPE_DICTIONARY:
		payload = {}
	return {
		"seq":int(row.get("seq",0)),
		"event_id":str(row.get("event_id","")),
		"created_at":float(row.get("created_at",0.0)),
		"timestamp":float(row.get("created_at",0.0)),
		"source_type":str(row.get("source_type","")),
		"source_id":str(row.get("source_id","")),
		"authority":str(row.get("authority","")),
		"truth_class":str(row.get("truth_class","")),
		"visibility":str(row.get("visibility","")),
		"event_type":str(row.get("event_type","")),
		"subject_id":str(row.get("subject_id","")),
		"object_id":str(row.get("object_id","")),
		"room_id":str(row.get("room_id","")),
		"from":str(row.get("from_value","")),
		"to":str(row.get("to_value","")),
		"expires_at":row.get("expires_at"),
		"reversibility":str(row.get("reversibility","")),
		"provenance":str(row.get("provenance","")),
		"notes":str(row.get("notes","")),
		"payload":payload
	}

func _load_events() -> bool:
	if not _query("""SELECT seq,event_id,created_at,source_type,source_id,authority,
		truth_class,visibility,event_type,subject_id,object_id,room_id,
		from_value,to_value,expires_at,reversibility,provenance,notes,payload_json
		FROM events ORDER BY seq;"""):
		return false
	events.clear()
	sequence = 0
	var seen: Dictionary = {}
	for raw_row in _rows():
		if typeof(raw_row) != TYPE_DICTIONARY:
			last_error = "SQLite event row is not a dictionary"
			return false
		var event: Dictionary = _decode_event(raw_row)
		var event_id: String = str(event.get("event_id",""))
		var seq: int = int(event.get("seq",0))
		if event_id == "" or seq <= sequence or seen.has(event_id):
			last_error = "SQLite event order/identity is invalid"
			return false
		seen[event_id] = true
		sequence = seq
		events.append(event)
	return true

func _open_initialize_load() -> bool:
	if not _open_current():
		return false
	if not _initialize_schema():
		_close()
		return false
	if not _load_events():
		_close()
		return false
	return true

func _quarantine_primary() -> void:
	if not FileAccess.file_exists(path):
		return
	var corrupt := path + ".corrupt"
	var corrupt_abs := ProjectSettings.globalize_path(corrupt)
	if FileAccess.file_exists(corrupt):
		DirAccess.remove_absolute(corrupt_abs)
	DirAccess.rename_absolute(ProjectSettings.globalize_path(path),corrupt_abs)
	for suffix in ["-wal","-shm"]:
		var sidecar: String = path+str(suffix)
		if FileAccess.file_exists(sidecar):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(sidecar))

func setup(base_save_path: String) -> bool:
	path = base_save_path + ".world_events_v1.sqlite"
	events.clear()
	sequence = 0
	status = "INITIALIZING"
	last_error = ""
	var primary_exists := FileAccess.file_exists(path)
	var backup := path + ".bak"

	if _open_initialize_load():
		status = "READY" if not events.is_empty() else "EMPTY"
		return true

	var primary_error := last_error
	_close()
	if primary_exists and FileAccess.file_exists(backup):
		_quarantine_primary()
		if not _copy_file(backup,path):
			status = "CORRUPT_NO_RECOVERY"
			last_error = "Cannot restore SQLite event-store backup after: "+primary_error
			return false
		events.clear()
		sequence = 0
		last_error = ""
		if _open_initialize_load():
			status = "RECOVERED_FROM_BACKUP"
			return true
		var backup_error := last_error
		_close()
		status = "CORRUPT_NO_RECOVERY"
		last_error = "Primary unreadable (%s); backup unreadable (%s)" % [
			primary_error,backup_error]
		return false

	status = "CORRUPT_NO_RECOVERY"
	if primary_exists:
		last_error = primary_error if primary_error != "" else "Unreadable SQLite event store"
	else:
		last_error = last_error if last_error != "" else "Cannot initialize SQLite event store"
	return false

func has_event(event_id: String) -> bool:
	if event_id == "":
		return false
	for raw_event in events:
		if str((raw_event as Dictionary).get("event_id","")) == event_id:
			return true
	return false

func _insert_event(event: Dictionary, preserve_seq: bool = false) -> bool:
	var payload_json := JSON.stringify(event.get("payload",{}))
	if preserve_seq:
		var source_seq: int = int(event.get("seq",0))
		if source_seq <= 0:
			last_error = "Imported canonical event is missing seq"
			return false
		return _query("""INSERT INTO events(
			seq,event_id,created_at,source_type,source_id,authority,truth_class,visibility,
			event_type,subject_id,object_id,room_id,from_value,to_value,expires_at,
			reversibility,provenance,notes,payload_json
		) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);""",[
			source_seq,
			str(event.get("event_id","")),
			float(event.get("created_at",0.0)),
			str(event.get("source_type","")),
			str(event.get("source_id","")),
			str(event.get("authority","")),
			str(event.get("truth_class","")),
			str(event.get("visibility","")),
			str(event.get("event_type","")),
			str(event.get("subject_id","")),
			str(event.get("object_id","")),
			str(event.get("room_id","")),
			str(event.get("from","")),
			str(event.get("to","")),
			event.get("expires_at"),
			str(event.get("reversibility","")),
			str(event.get("provenance","")),
			str(event.get("notes","")),
			payload_json
		])
	return _query("""INSERT INTO events(
		event_id,created_at,source_type,source_id,authority,truth_class,visibility,
		event_type,subject_id,object_id,room_id,from_value,to_value,expires_at,
		reversibility,provenance,notes,payload_json
	) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);""",[
		str(event.get("event_id","")),
		float(event.get("created_at",0.0)),
		str(event.get("source_type","")),
		str(event.get("source_id","")),
		str(event.get("authority","")),
		str(event.get("truth_class","")),
		str(event.get("visibility","")),
		str(event.get("event_type","")),
		str(event.get("subject_id","")),
		str(event.get("object_id","")),
		str(event.get("room_id","")),
		str(event.get("from","")),
		str(event.get("to","")),
		event.get("expires_at"),
		str(event.get("reversibility","")),
		str(event.get("provenance","")),
		str(event.get("notes","")),
		payload_json
	])

func _sync_projection(projection: Dictionary) -> bool:
	if not _query("DELETE FROM objects;"):
		return false
	var ids: Array = projection.keys()
	ids.sort()
	for raw_id in ids:
		var object: Dictionary = projection[raw_id]
		if not _query("""INSERT INTO objects(
			object_id,canonical_owner,current_holder,current_location,state,
			last_explicit_location,movement_reason,movement_authority,
			ambient_move_allowed,ambient_hide_allowed,ambient_protected,
			updated_event_id,projection_json
		) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?);""",[
			str(object.get("id",raw_id)),
			str(object.get("canonical_owner_id","")),
			str(object.get("current_holder_id","")),
			str(object.get("current_room_id","")),
			str(object.get("state","PLACED")),
			str(object.get("last_explicit_location","")),
			str(object.get("movement_reason","")),
			str(object.get("movement_authority","")),
			1 if bool(object.get("ambient_pickup_allowed",false)) else 0,
			1 if bool(object.get("ambient_hide_allowed",false)) else 0,
			1 if bool(object.get("ambient_protected",false)) else 0,
			str(object.get("updated_event_id","")),
			JSON.stringify(object)
		]):
			return false
	return true

func _backup() -> bool:
	if db == null:
		return false
	var ok := bool(db.call("backup_to",path+".bak"))
	if not ok:
		return _db_error("SQLite backup failed")
	return true

func import_canonical_events(input_events: Array, projection: Dictionary) -> Array:
	# One-time non-destructive migration from the accepted v0.20 JSON stream.
	# Canonical event identity includes event_id AND seq, so both are preserved.
	if db == null or not events.is_empty():
		last_error = "SQLite canonical import requires an empty open store"
		return []
	if input_events.is_empty():
		return []
	var previous_seq := 0
	var seen: Dictionary = {}
	for raw_event in input_events:
		if typeof(raw_event) != TYPE_DICTIONARY:
			last_error = "Canonical import contains non-object event"
			return []
		var event: Dictionary = raw_event
		var event_id := str(event.get("event_id",""))
		var source_seq := int(event.get("seq",0))
		if event_id == "" or seen.has(event_id) or source_seq <= previous_seq:
			last_error = "Canonical import identity/order is invalid"
			return []
		seen[event_id] = true
		previous_seq = source_seq
	if not _query("BEGIN IMMEDIATE;"):
		status = "WRITE_FAILED"
		return []
	for raw_event in input_events:
		if not _insert_event(raw_event,true):
			_query("ROLLBACK;")
			status = "WRITE_FAILED"
			return []
	if not _sync_projection(projection):
		_query("ROLLBACK;")
		status = "WRITE_FAILED"
		return []
	if not _query("COMMIT;"):
		_query("ROLLBACK;")
		status = "WRITE_FAILED"
		return []
	if not _load_events():
		status = "WRITE_FAILED"
		return []
	if events.size() != input_events.size():
		last_error = "SQLite canonical import count mismatch"
		status = "WRITE_FAILED"
		return []
	for i in range(input_events.size()):
		var source: Dictionary = input_events[i]
		var imported: Dictionary = events[i]
		if str(source.get("event_id","")) != str(imported.get("event_id","")) or 				int(source.get("seq",0)) != int(imported.get("seq",0)):
			last_error = "SQLite canonical import changed event identity/order"
			status = "WRITE_FAILED"
			return []
	if not _backup():
		status = "WRITE_FAILED"
		return []
	status = "READY"
	last_error = ""
	return snapshot_events()

func rebuild_projection(projection: Dictionary) -> bool:
	# Derived tables are disposable. Canonical events are not.
	if db == null:
		last_error = "SQLite connection is unavailable"
		return false
	if not _query("BEGIN IMMEDIATE;"):
		status = "WRITE_FAILED"
		return false
	if not _sync_projection(projection):
		_query("ROLLBACK;")
		status = "WRITE_FAILED"
		return false
	if not _query("COMMIT;"):
		_query("ROLLBACK;")
		status = "WRITE_FAILED"
		return false
	if not _backup():
		status = "WRITE_FAILED"
		return false
	status = "READY"
	last_error = ""
	return true

func append_with_projection(event: Dictionary, projection: Dictionary) -> Dictionary:
	var rows: Array = append_many_with_projection([event],projection)
	return rows[0] if rows.size() == 1 else {}

func append_many_with_projection(input_events: Array, projection: Dictionary) -> Array:
	if db == null or status == "CORRUPT_NO_RECOVERY" or status == "WRITE_FAILED":
		return []
	if input_events.is_empty():
		return []
	var ids: Dictionary = {}
	for existing in events:
		ids[str((existing as Dictionary).get("event_id",""))] = true
	for raw_event in input_events:
		if typeof(raw_event) != TYPE_DICTIONARY:
			last_error = "Cannot append non-object event"
			return []
		var id := str((raw_event as Dictionary).get("event_id",""))
		if id == "" or ids.has(id):
			last_error = "duplicate/empty event_id: " + id
			return []
		ids[id] = true
	if not _query("BEGIN IMMEDIATE;"):
		status = "WRITE_FAILED"
		return []
	for raw_event in input_events:
		if not _insert_event(raw_event):
			_query("ROLLBACK;")
			status = "WRITE_FAILED"
			return []
	if not _sync_projection(projection):
		_query("ROLLBACK;")
		status = "WRITE_FAILED"
		return []
	if not _query("COMMIT;"):
		_query("ROLLBACK;")
		status = "WRITE_FAILED"
		return []
	if not _load_events():
		status = "WRITE_FAILED"
		return []
	if not _backup():
		status = "WRITE_FAILED"
		return []
	status = "READY"
	last_error = ""
	var committed: Array = []
	var wanted: Dictionary = {}
	for raw_event in input_events:
		wanted[str((raw_event as Dictionary).get("event_id",""))] = true
	for raw_event in events:
		var event: Dictionary = raw_event
		if wanted.has(str(event.get("event_id",""))):
			committed.append(event.duplicate(true))
	return committed

func append(event: Dictionary) -> Dictionary:
	last_error = "SQLite backend requires append_with_projection() transaction"
	return {}

func append_many(input_events: Array) -> Array:
	last_error = "SQLite backend requires append_many_with_projection() transaction"
	return []

func snapshot_events() -> Array:
	return events.duplicate(true)

func events_for_object(object_id: String, limit: int = 64) -> Array:
	if object_id == "" or limit <= 0:
		return []
	var matches: Array = []
	for raw_event in events:
		var event: Dictionary = raw_event
		if str(event.get("object_id","")) == object_id:
			matches.append(event.duplicate(true))
	var start: int = maxi(0,matches.size()-limit)
	return matches.slice(start,matches.size())

func derived_objects_snapshot() -> Dictionary:
	if db == null or not _query(
			"SELECT object_id,projection_json FROM objects ORDER BY object_id;"):
		return {}
	var result: Dictionary = {}
	for raw_row in _rows():
		var row: Dictionary = raw_row
		var parsed = JSON.parse_string(str(row.get("projection_json","{}")))
		if typeof(parsed) == TYPE_DICTIONARY:
			result[str(row.get("object_id",""))] = parsed
	return result

func close() -> void:
	_close()
