extends SceneTree
const World = preload("res://scripts/world_model.gd")

func _initialize() -> void:
	call_deferred("run")

func _cleanup(path: String) -> void:
	for suffix in [
		"",".bak",".tmp",
		".world_events_v1.json",".world_events_v1.json.bak",
		".world_events_v1.json.tmp",".world_events_v1.json.corrupt",
		".world_events_v1.sqlite",".world_events_v1.sqlite.bak",
		".world_events_v1.sqlite-wal",".world_events_v1.sqlite-shm",
		".world_events_v1.sqlite.corrupt"
	]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))

func _event_identity(events: Array) -> Array:
	var out: Array = []
	for raw in events:
		var event: Dictionary = raw
		out.append([int(event.get("seq",0)),str(event.get("event_id",""))])
	return out

func run() -> void:
	var path := "user://object_event_json_to_sqlite_v021.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")

	# Build a genuine accepted v0.20 JSON canonical stream.
	var legacy := World.new()
	legacy.save_path = path
	legacy.seed_world()
	var home: Dictionary = legacy.get_room(1,-1)
	var stash: Dictionary = legacy.get_room(-2,0)
	assert(legacy.register_physical_object(
		"MIGRATE_OBJECT","Migration object","RES_01",home["id"],
		true,true,true,true,false))
	var manjka: Dictionary = legacy.residents["MANJKA"]
	manjka["room_id"] = home["id"]
	manjka["x"] = float(home["x"])*World.MODULE_W
	manjka["level"] = int(home["level"])
	assert(legacy.pickup_physical_object("MIGRATE_OBJECT","MANJKA"))
	manjka["room_id"] = stash["id"]
	assert(legacy.place_physical_object(
		"MIGRATE_OBJECT","MANJKA",stash["id"],"STASHED"))
	assert(legacy.object_event_revision()==3)
	assert(legacy.save_world())
	var json_path := path+".world_events_v1.json"
	assert(FileAccess.file_exists(json_path))
	var original_json := FileAccess.get_file_as_string(json_path)
	var original_sha := FileAccess.get_sha256(json_path)
	var source_identity := _event_identity(legacy.object_events.store.snapshot_events())
	var source_projection: Dictionary = legacy.objects.duplicate(true)

	# Opt in to SQLite on the same persisted House. Migration must preserve the
	# old stream byte-for-byte while importing canonical identity/order.
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","sqlite")
	var migrated := World.new()
	migrated.save_path = path
	migrated.load_or_seed()
	assert(str(migrated.runtime_state.get("object_event_backend",""))=="sqlite_v021_proof")
	assert(str(migrated.runtime_state.get("object_event_status",""))=="MIGRATED_JSON_EVENT_STORE")
	assert(int(migrated.runtime_state.get("object_event_migrated_event_count",0))==3)
	assert(FileAccess.file_exists(path+".world_events_v1.sqlite"))
	assert(FileAccess.get_file_as_string(json_path)==original_json)
	assert(FileAccess.get_sha256(json_path)==original_sha)
	assert(_event_identity(migrated.object_events.store.snapshot_events())==source_identity)
	assert(migrated.object_event_revision()==3)
	assert(migrated.objects==source_projection)
	assert(migrated.object_events.store.derived_objects_snapshot()==source_projection)

	# After cutover, SQLite advances independently; the historical JSON source
	# remains immutable evidence and is not rotated/rewritten.
	assert(migrated.set_object_ambient_protection("MIGRATE_OBJECT",true))
	assert(migrated.object_event_revision()==4)
	assert(bool(migrated.physical_object("MIGRATE_OBJECT")["ambient_protected"]))
	assert(FileAccess.get_sha256(json_path)==original_sha)
	assert(_event_identity(legacy.object_events.store.snapshot_events())==source_identity)
	migrated.object_events.store.close()
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","json")

	# Even an accidental legacy override cannot downgrade an existing SQLite canonical store.
	# Restart auto-detects the SQLite canonical stream, not the stale JSON checkpoint.
	var restarted := World.new()
	restarted.save_path = path
	restarted.load_or_seed()
	assert(str(restarted.runtime_state.get("object_event_backend",""))=="sqlite_v021_proof")
	assert(str(restarted.runtime_state.get("object_event_status",""))=="REPLAYED")
	assert(restarted.object_event_revision()==4)
	assert(bool(restarted.physical_object("MIGRATE_OBJECT")["ambient_protected"]))
	assert(restarted.object_events.store.snapshot_events().size()==4)
	assert(FileAccess.get_sha256(json_path)==original_sha)

	restarted.object_events.store.close()
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	_cleanup(path)
	print("OBJECT_EVENT_JSON_TO_SQLITE_V021_PASS source=json_v020 non_destructive=yes identity=event_id_seq projection=equivalent cutover=sticky_sqlite downgrade_env=blocked restart=sqlite_canonical")
	quit(0)
