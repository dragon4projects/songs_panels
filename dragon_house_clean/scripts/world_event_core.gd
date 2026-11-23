extends RefCounted
## v0.20 local event/provenance strangler.
## Historical guarantees reused from Mora RC1.5 Core outbox:
## stable event IDs, durable pending history, atomic replace, idempotent duplicate IDs.
## This first slice owns physical-object projection only. No HTTP service and no SQLite yet.

const STORE_SCHEMA := 1
const EVENT_SCHEMA := 1
const ALLOWED_TRUTH_CLASSES := [
	"EXPLICIT_WORLD_FACT",
	"AMBIENT_SIMULATION",
	"PRESENTATION_ONLY"
]
const ALLOWED_OBJECT_STATES := ["PLACED","HELD","STASHED","LOST_FOUND"]

var store_path := ""
var events: Array = []
var sequence := 0
var subject_revisions: Dictionary = {}
var event_ids: Dictionary = {}
var store_ready := false
var last_error := ""

func configure(path: String) -> bool:
	if path == "":
		last_error = "event store path is empty"
		store_ready = false
		return false
	store_path = path
	return load_store()

func _read_store(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parser.data
	if int(data.get("schema",0)) != STORE_SCHEMA or typeof(data.get("events",null)) != TYPE_ARRAY:
		return {}
	return data

func load_store() -> bool:
	events.clear()
	subject_revisions.clear()
	event_ids.clear()
	sequence = 0
	last_error = ""
	var had_primary := FileAccess.file_exists(store_path)
	var had_backup := FileAccess.file_exists(store_path + ".bak")
	var parsed: Dictionary = _read_store(store_path)
	if parsed.is_empty() and had_backup:
		parsed = _read_store(store_path + ".bak")
	if parsed.is_empty():
		if had_primary or had_backup:
			last_error = "event store unreadable; preserved for recovery: " + store_path
			store_ready = false
			return false
		store_ready = true
		return true
	sequence = maxi(0,int(parsed.get("sequence",0)))
	for raw in parsed.get("events",[]):
		if typeof(raw) != TYPE_DICTIONARY:
			last_error = "event store contains non-dictionary row"
			store_ready = false
			return false
		var event: Dictionary = raw
		if not _valid_envelope(event):
			last_error = "invalid event envelope in durable store"
			store_ready = false
			return false
		var event_id := str(event.get("event_id",""))
		if event_ids.has(event_id):
			last_error = "duplicate event_id in durable store: " + event_id
			store_ready = false
			return false
		var subject_id := str(event.get("subject_id",""))
		var revision := int(event.get("revision",0))
		var expected := int(subject_revisions.get(subject_id,0)) + 1
		if revision != expected:
			last_error = "non-contiguous subject revision for " + subject_id
			store_ready = false
			return false
		var invariant_error := _validate_candidate_object_event(event)
		if invariant_error != "":
			last_error = "invalid durable object event: " + invariant_error
			store_ready = false
			return false
		events.append(event.duplicate(true))
		event_ids[event_id] = event.duplicate(true)
		subject_revisions[subject_id] = revision
	store_ready = true
	return true

func reset_store() -> bool:
	events.clear()
	subject_revisions.clear()
	event_ids.clear()
	sequence = 0
	last_error = ""
	store_ready = true
	for suffix in ["",".bak",".tmp"]:
		var path := store_path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return _persist_store()

func _next_event_id() -> String:
	sequence += 1
	return "local-%012d" % sequence

func object_revision(subject_id: String) -> int:
	return int(subject_revisions.get(subject_id,0))

func has_object_history(subject_id: String) -> bool:
	return object_revision(subject_id) > 0

func subject_ids() -> Array:
	var ids: Array = subject_revisions.keys()
	ids.sort()
	return ids

func _valid_envelope(event: Dictionary) -> bool:
	if int(event.get("schema",0)) != EVENT_SCHEMA:
		return false
	if str(event.get("event_id","")) == "" or str(event.get("event_type","")) == "":
		return false
	if str(event.get("subject_id","")) == "":
		return false
	if str(event.get("source_type","")) == "" or str(event.get("source_id","")) == "":
		return false
	if str(event.get("authority","")) == "":
		return false
	if not ALLOWED_TRUTH_CLASSES.has(str(event.get("truth_class",""))):
		return false
	if int(event.get("revision",0)) <= 0:
		return false
	if typeof(event.get("payload",null)) != TYPE_DICTIONARY:
		return false
	return true

func _events_equal(a: Dictionary,b: Dictionary) -> bool:
	# JSON canonicalization is enough here because envelopes contain JSON-safe values.
	return JSON.stringify(a) == JSON.stringify(b)

func _valid_object_snapshot(object: Dictionary, subject_id: String) -> bool:
	if object.is_empty() or str(object.get("id","")) != subject_id:
		return false
	if str(object.get("home_room_id","")) == "":
		return false
	if not ALLOWED_OBJECT_STATES.has(str(object.get("state",""))):
		return false
	if str(object.get("state","")) == "HELD":
		return str(object.get("current_holder_id","")) != "" and str(object.get("current_room_id","")) == ""
	return str(object.get("current_holder_id","")) == "" and str(object.get("current_room_id","")) != ""

func _validate_candidate_object_event(event: Dictionary) -> String:
	var event_type := str(event.get("event_type",""))
	var subject_id := str(event.get("subject_id",""))
	var actor_id := str(event.get("actor_id",""))
	var payload: Dictionary = event.get("payload",{})
	if event_type in ["OBJECT_REGISTERED","OBJECT_BASELINE_IMPORTED"]:
		if int(event.get("revision",0)) != 1:
			return "registration/baseline must be subject revision 1"
		if typeof(payload.get("object",null)) != TYPE_DICTIONARY:
			return "registration/baseline requires object snapshot"
		var initial: Dictionary = payload["object"]
		if not _valid_object_snapshot(initial,subject_id):
			return "invalid object snapshot for "+subject_id
		return ""
	var current: Dictionary = project_object(subject_id,{})
	if current.is_empty():
		return "object transition has no event-sourced baseline"
	match event_type:
		"OBJECT_AMBIENT_PROTECTION_CHANGED":
			if not payload.has("protected"):
				return "ambient protection event requires protected field"
		"OBJECT_PICKED_UP":
			if actor_id == "":
				return "pickup requires actor_id"
			if str(current.get("current_holder_id","")) != "":
				return "pickup requires unheld object"
			if str(current.get("current_room_id","")) == "":
				return "pickup requires placed object"
			if str(payload.get("from","")) != str(current.get("current_room_id","")):
				return "pickup from does not match current room"
			if str(payload.get("to","")) != actor_id:
				return "pickup to must equal actor_id"
		"OBJECT_PLACED","OBJECT_STASHED":
			if actor_id == "" or str(current.get("current_holder_id","")) != actor_id:
				return "place/stash requires current holder actor"
			if str(current.get("current_room_id","")) != "":
				return "place/stash requires held object"
			var target := str(payload.get("to",""))
			if target == "":
				return "place/stash requires destination"
			var state := str(payload.get("state",""))
			var expected_state := "STASHED" if event_type == "OBJECT_STASHED" else "PLACED"
			if state != expected_state:
				return "place/stash state does not match event type"
		"OBJECT_RECOVERED_TO_LOST_FOUND":
			if str(payload.get("to","")) == "":
				return "lost-found recovery requires destination"
		"OBJECT_RESTORED_HOME":
			var home := str(current.get("home_room_id",""))
			if home == "" or str(payload.get("to","")) != home:
				return "restore-home destination must equal canonical home_room_id"
		_:
			return "unsupported object event type: "+event_type
	return ""

func append_object_event(event_type: String, subject_id: String, actor_id: String,
		payload: Dictionary, sim_clock: float, authority: String,
		truth_class: String, expected_revision: int = -1,
		requested_event_id: String = "") -> Dictionary:
	if not store_ready:
		return {"ok":false,"error":last_error}
	if subject_id == "" or event_type == "" or authority == "":
		return {"ok":false,"error":"missing event identity/authority"}
	if not event_type.begins_with("OBJECT_"):
		return {"ok":false,"error":"v0.20 strangler accepts OBJECT_* only"}
	if not ALLOWED_TRUTH_CLASSES.has(truth_class):
		return {"ok":false,"error":"invalid truth_class"}
	var current_revision := object_revision(subject_id)
	var expected := current_revision if expected_revision < 0 else expected_revision
	var event_id := requested_event_id if requested_event_id != "" else _next_event_id()
	var event := {
		"schema":EVENT_SCHEMA,
		"event_id":event_id,
		"event_type":event_type,
		"subject_id":subject_id,
		"actor_id":actor_id,
		"source_type":"godot_local",
		"source_id":"world_model",
		"authority":authority,
		"truth_class":truth_class,
		"sim_clock":sim_clock,
		"expected_revision":expected,
		"revision":expected+1,
		"payload":payload.duplicate(true)
	}
	if event_ids.has(event_id):
		var existing: Dictionary = event_ids[event_id]
		if _events_equal(existing,event):
			return {"ok":true,"duplicate":true,"event":existing.duplicate(true)}
		return {"ok":false,"error":"event_id collision with different envelope: "+event_id}
	if expected != current_revision:
		return {"ok":false,"error":"revision conflict for %s expected=%d current=%d" %
			[subject_id,expected,current_revision]}
	if not _valid_envelope(event):
		return {"ok":false,"error":"invalid event envelope"}
	var invariant_error := _validate_candidate_object_event(event)
	if invariant_error != "":
		return {"ok":false,"error":invariant_error}
	events.append(event.duplicate(true))
	event_ids[event_id] = event.duplicate(true)
	subject_revisions[subject_id] = expected + 1
	if not _persist_store():
		events.pop_back()
		event_ids.erase(event_id)
		if current_revision == 0:
			subject_revisions.erase(subject_id)
		else:
			subject_revisions[subject_id] = current_revision
		return {"ok":false,"error":last_error}
	return {"ok":true,"duplicate":false,"event":event}

func _append_history(object: Dictionary,event: Dictionary) -> void:
	var history: Array = object.get("history",[])
	var payload: Dictionary = event.get("payload",{})
	history.append({
		"event":str(event.get("event_type","")).trim_prefix("OBJECT_"),
		"actor_id":str(event.get("actor_id","")),
		"from":str(payload.get("from","")),
		"to":str(payload.get("to","")),
		"sim_clock":float(event.get("sim_clock",0.0)),
		"event_id":str(event.get("event_id",""))
	})
	while history.size() > 64:
		history.pop_front()
	object["history"] = history

func project_object(subject_id: String, fallback: Dictionary = {}) -> Dictionary:
	var object: Dictionary = fallback.duplicate(true)
	for raw in events:
		var event: Dictionary = raw
		if str(event.get("subject_id","")) != subject_id:
			continue
		var event_type := str(event.get("event_type",""))
		var payload: Dictionary = event.get("payload",{})
		match event_type:
			"OBJECT_REGISTERED","OBJECT_BASELINE_IMPORTED":
				if typeof(payload.get("object",null)) != TYPE_DICTIONARY:
					return {}
				object = payload["object"].duplicate(true)
			"OBJECT_AMBIENT_PROTECTION_CHANGED":
				if object.is_empty():
					return {}
				object["ambient_protected"] = bool(payload.get("protected",false))
			"OBJECT_PICKED_UP":
				if object.is_empty():
					return {}
				object["current_holder_id"] = str(event.get("actor_id",""))
				object["current_room_id"] = ""
				object["state"] = "HELD"
				_append_history(object,event)
			"OBJECT_PLACED","OBJECT_STASHED":
				if object.is_empty():
					return {}
				var state := str(payload.get("state","PLACED"))
				if not ALLOWED_OBJECT_STATES.has(state) or state == "HELD":
					return {}
				object["current_holder_id"] = ""
				object["current_room_id"] = str(payload.get("to",""))
				object["state"] = state
				_append_history(object,event)
			"OBJECT_RECOVERED_TO_LOST_FOUND":
				if object.is_empty():
					return {}
				object["current_holder_id"] = ""
				object["current_room_id"] = str(payload.get("to",""))
				object["state"] = "LOST_FOUND"
				_append_history(object,event)
			"OBJECT_RESTORED_HOME":
				if object.is_empty():
					return {}
				object["current_holder_id"] = ""
				object["current_room_id"] = str(object.get("home_room_id",""))
				object["state"] = "PLACED"
				_append_history(object,event)
	return object

func event_rows_for_subject(subject_id: String) -> Array:
	var out: Array = []
	for raw in events:
		if str(raw.get("subject_id","")) == subject_id:
			out.append(raw.duplicate(true))
	return out

func metrics() -> Dictionary:
	return {
		"backend":"json_event_strangler_v020",
		"schema":STORE_SCHEMA,
		"events":events.size(),
		"subjects":subject_revisions.size(),
		"sequence":sequence,
		"store_ready":store_ready,
		"last_error":last_error
	}

func _persist_store() -> bool:
	if store_path == "":
		last_error = "event store path is empty"
		store_ready = false
		return false
	var payload := JSON.stringify({
		"schema":STORE_SCHEMA,
		"sequence":sequence,
		"events":events
	},"	") + "
"
	var temp_path := store_path + ".tmp"
	var backup_path := store_path + ".bak"
	var file := FileAccess.open(temp_path,FileAccess.WRITE)
	if file == null:
		last_error = "cannot open event-store temp file: " + temp_path
		return false
	file.store_string(payload)
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_error = "cannot flush event-store temp file: " + temp_path
		return false
	if _read_store(temp_path).is_empty() and not events.is_empty():
		last_error = "event-store temp verification failed"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
		return false
	var abs_temp := ProjectSettings.globalize_path(temp_path)
	var abs_store := ProjectSettings.globalize_path(store_path)
	var abs_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(abs_backup)
	if FileAccess.file_exists(store_path):
		if DirAccess.rename_absolute(abs_store,abs_backup) != OK:
			last_error = "cannot rotate event-store backup"
			return false
	if DirAccess.rename_absolute(abs_temp,abs_store) != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(abs_backup,abs_store)
		last_error = "cannot atomically replace event store"
		return false
	last_error = ""
	store_ready = true
	return true
