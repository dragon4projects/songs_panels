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

func _sqlite_pragma(store, name: String) -> Variant:
	assert(store.db != null)
	assert(bool(store.db.call("query","PRAGMA "+name+";")))
	var rows = store.db.get("query_result")
	assert(rows is Array and not rows.is_empty())
	var row: Dictionary = rows[0]
	return row.values()[0]

func _assert_projection_equivalent(a: Dictionary, b: Dictionary) -> void:
	assert(a.size()==b.size())
	for id in a:
		assert(b.has(id))
		var left: Dictionary = a[id]
		var right: Dictionary = b[id]
		for field in [
			"id","display_name","canonical_owner_id","home_room_id",
			"current_holder_id","current_room_id","state","movable","recoverable",
			"ambient_pickup_allowed","ambient_hide_allowed","ambient_protected",
			"last_explicit_location","movement_reason","movement_authority",
			"updated_event_id"
		]:
			assert(left.get(field)==right.get(field),
				"projection mismatch "+str(id)+"."+field)

func run() -> void:
	var path := "user://object_event_sqlite_v021.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","sqlite")

	var world := World.new()
	world.save_path = path
	world.seed_world()
	var home: Dictionary = world.get_room(1,-1)
	var stash: Dictionary = world.get_room(-2,0)
	assert(not home.is_empty() and not stash.is_empty())

	assert(world.register_physical_object(
		"SQLITE_OBJECT","SQLite proof object","RES_01",home["id"],
		true,true,true,true,false,
		{"description":"v0.21 sqlite proof","asset_id":"QA_SQLITE"}))
	assert(str(world.runtime_state.get("object_event_backend",""))=="sqlite_v021_proof")
	assert(FileAccess.file_exists(path+".world_events_v1.sqlite"))
	assert(not FileAccess.file_exists(path+".world_events_v1.json"))
	assert(str(_sqlite_pragma(world.object_events.store,"journal_mode")).to_lower()=="wal")
	assert(int(_sqlite_pragma(world.object_events.store,"synchronous"))==2)

	var manjka: Dictionary = world.residents["MANJKA"]
	manjka["room_id"] = home["id"]
	manjka["x"] = float(home["x"])*World.MODULE_W
	manjka["level"] = int(home["level"])
	assert(world.pickup_physical_object("SQLITE_OBJECT","MANJKA"))
	manjka["room_id"] = stash["id"]
	assert(world.place_physical_object("SQLITE_OBJECT","MANJKA",stash["id"],"STASHED"))
	assert(world.object_event_revision()==3)
	assert(FileAccess.file_exists(path+".world_events_v1.sqlite.bak"))

	var sql_projection: Dictionary = world.object_events.store.derived_objects_snapshot()
	_assert_projection_equivalent(world.objects,sql_projection)

	var latest: Dictionary = world.object_events.store.events[
		world.object_events.store.events.size()-1].duplicate(true)
	var revision_before := world.object_event_revision()
	var duplicate := world.submit_object_event(latest)
	assert(not bool(duplicate.get("ok",false)))
	assert(bool(duplicate.get("duplicate",false)))
	assert(world.object_event_revision()==revision_before)
	_assert_projection_equivalent(world.objects,
		world.object_events.store.derived_objects_snapshot())

	# Simulate a renderer crash before the JSON compatibility checkpoint.
	assert(not FileAccess.file_exists(path))
	world.object_events.store.close()
	# Canonical backend choice survives without the QA env override.
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")

	var restarted := World.new()
	restarted.save_path = path
	restarted.load_or_seed()
	assert(str(restarted.runtime_state.get("object_event_backend",""))=="sqlite_v021_proof")
	assert(restarted.object_event_revision()==3)
	var restored: Dictionary = restarted.physical_object("SQLITE_OBJECT")
	assert(not restored.is_empty())
	assert(str(restored.get("state",""))=="STASHED")
	assert(str(restored.get("current_room_id",""))==str(stash["id"]))
	assert(str(restored.get("canonical_owner_id",""))=="RES_01")
	assert(str(restored.get("last_explicit_location",""))==str(home["id"]))
	_assert_projection_equivalent(restarted.objects,
		restarted.object_events.store.derived_objects_snapshot())

	restarted.object_events.store.close()
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	_cleanup(path)
	print("OBJECT_EVENT_SQLITE_V021_PASS backend=sqlite wal=yes sync=FULL transaction=event_plus_projection restart=sticky_sqlite duplicate=idempotent json_default=untouched")
	quit(0)
