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

func run() -> void:
	var path := "user://object_event_snapshot_to_sqlite_v021.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","json")

	# Build a pre-event-strangler compatibility snapshot: object state exists,
	# but there is no canonical v0.20 event file yet.
	var legacy := World.new()
	legacy.save_path = path
	legacy.seed_world()
	var home: Dictionary = legacy.get_room(1,-1)
	legacy.objects["LEGACY_SNAPSHOT_OBJECT"] = {
		"id":"LEGACY_SNAPSHOT_OBJECT",
		"display_name":"Legacy snapshot object",
		"canonical_owner_id":"RES_01",
		"home_room_id":str(home["id"]),
		"current_holder_id":"",
		"current_room_id":str(home["id"]),
		"state":"PLACED",
		"movable":true,
		"recoverable":true,
		"ambient_pickup_allowed":false,
		"ambient_hide_allowed":false,
		"ambient_protected":true,
		"description":"pre-v0.20",
		"preview_path":"",
		"asset_id":"LEGACY_ASSET",
		"viewer_category":"artifacts",
		"history":[{
			"event":"REGISTERED","actor_id":"","from":"",
			"to":str(home["id"]),"sim_clock":0.0
		}]
	}
	assert(legacy.save_world())
	assert(not FileAccess.file_exists(path+".world_events_v1.json"))
	var snapshot_sha := FileAccess.get_sha256(path)

	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	var migrated := World.new()
	migrated.save_path = path
	migrated.load_or_seed()
	assert(str(migrated.runtime_state.get("object_event_status",""))=="MIGRATED_JSON_SNAPSHOT")
	assert(str(migrated.runtime_state.get("object_event_backend",""))=="sqlite_v021_proof")
	assert(migrated.object_event_revision()==1)
	assert(FileAccess.get_sha256(path)==snapshot_sha,
		"read-only compatibility snapshot must remain byte-identical")
	assert(not FileAccess.file_exists(path+".world_events_v1.json"))
	assert(FileAccess.file_exists(path+".world_events_v1.sqlite"))
	var object: Dictionary = migrated.physical_object("LEGACY_SNAPSHOT_OBJECT")
	assert(str(object.get("canonical_owner_id",""))=="RES_01")
	assert(str(object.get("current_room_id",""))==str(home["id"]))
	assert(bool(object.get("ambient_protected",false)))
	assert((object.get("history",[]) as Array).size()==1,
		"legacy history must be preserved during migration")
	var events: Array = migrated.object_events.store.snapshot_events()
	assert(events.size()==1)
	assert(str(events[0].get("source_type",""))=="migration_import")
	assert(str(events[0].get("authority",""))=="HISTORICAL_IMPORT")
	assert(str(events[0].get("truth_class",""))=="EXPLICIT_WORLD_FACT")
	assert(migrated.object_events.store.derived_objects_snapshot()==migrated.objects)
	migrated.object_events.store.close()

	# Sticky SQLite replay must work even though the old JSON snapshot still
	# contains the pre-event representation and was never rewritten.
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	var restarted := World.new()
	restarted.save_path = path
	restarted.load_or_seed()
	assert(str(restarted.runtime_state.get("object_event_backend",""))=="sqlite_v021_proof")
	assert(restarted.object_event_revision()==1)
	assert(str(restarted.physical_object("LEGACY_SNAPSHOT_OBJECT").get(
		"updated_event_id",""))==str(events[0].get("event_id","")))
	restarted.object_events.store.close()

	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	_cleanup(path)
	print("OBJECT_EVENT_SNAPSHOT_TO_SQLITE_V021_PASS source=pre_v020_snapshot automatic_cutover=yes non_destructive=yes migration_import=typed history=preserved restart=sticky_sqlite")
	quit(0)
