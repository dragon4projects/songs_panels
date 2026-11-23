extends SceneTree
const World = preload("res://scripts/world_model.gd")

func _initialize() -> void:
	call_deferred("run")

func _cleanup(path: String) -> void:
	for suffix in [
		"",".bak",".tmp",
		".world_events_v1.json",
		".world_events_v1.json.bak",
		".world_events_v1.json.tmp",
		".world_events_v1.json.corrupt",
		".world_events_v1.sqlite",".world_events_v1.sqlite.bak",
		".world_events_v1.sqlite-wal",".world_events_v1.sqlite-shm",
		".world_events_v1.sqlite.corrupt"
	]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))

func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	assert(file!=null)
	file.store_string(text)
	file.flush()
	file.close()

func _has_event(entries: Array, event_name: String) -> bool:
	for raw_entry in entries:
		var entry: Dictionary = raw_entry
		if str(entry.get("event","")) == event_name:
			return true
	return false

func run() -> void:
	var path := "user://object_event_migration_v020.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","json")

	# Create a true pre-v0.20 compatibility snapshot by writing objects directly.
	var legacy := World.new()
	legacy.save_path = path
	legacy.seed_world()
	var home: Dictionary = legacy.get_room(1,-1)
	var legacy_history := [{
		"event":"REGISTERED","actor_id":"","from":"","to":str(home["id"]),
		"sim_clock":0.0
	},{
		"event":"LEGACY_NOTE","actor_id":"","from":"","to":"","sim_clock":2.0
	}]
	legacy.objects["LEGACY_OBJECT"] = {
		"id":"LEGACY_OBJECT","display_name":"Legacy object",
		"canonical_owner_id":"RES_03","home_room_id":str(home["id"]),
		"current_holder_id":"","current_room_id":str(home["id"]),
		"state":"PLACED","movable":true,"recoverable":true,
		"ambient_pickup_allowed":true,"ambient_hide_allowed":false,
		"ambient_protected":false,"description":"legacy description",
		"preview_path":"legacy.png","asset_id":"LEGACY_ASSET",
		"viewer_category":"artifacts","history":legacy_history
	}
	assert(legacy.save_world())
	assert(not FileAccess.file_exists(path+".world_events_v1.json"))

	var migrated := World.new()
	migrated.save_path = path
	migrated.load_or_seed()
	var object: Dictionary = migrated.physical_object("LEGACY_OBJECT")
	assert(not object.is_empty())
	assert(str(object["canonical_owner_id"])=="RES_03")
	assert(str(object["current_room_id"])==str(home["id"]))
	assert(str(object["description"])=="legacy description")
	assert(str(object["asset_id"])=="LEGACY_ASSET")
	assert((object.get("history",[]) as Array).size()==2,
		"legacy object history must survive non-destructive migration")
	assert(migrated.object_event_revision()==1)
	assert(str(migrated.runtime_state.get("object_event_status",""))==
		"MIGRATED_JSON_SNAPSHOT")
	var first: Dictionary = migrated.object_events.store.events[0]
	assert(str(first["source_type"])=="migration_import")
	assert(str(first["authority"])=="HISTORICAL_IMPORT")
	assert(str(first["truth_class"])=="EXPLICIT_WORLD_FACT")
	assert(str(first["provenance"])=="MIGRATION_FROM_JSON_SNAPSHOT_V1")

	# Create a second committed event so a valid prior stream exists in .bak.
	assert(migrated.set_object_ambient_protection("LEGACY_OBJECT",true))
	assert(FileAccess.file_exists(path+".world_events_v1.json.bak"))
	assert(migrated.save_world())

	# Damage only the primary event log. Startup must quarantine it and replay
	# the last readable backup instead of trusting the newer JSON projection.
	_write_text(path+".world_events_v1.json","{ definitely not valid json")
	var recovered := World.new()
	recovered.save_path = path
	recovered.load_or_seed()
	var recovered_object: Dictionary = recovered.physical_object("LEGACY_OBJECT")
	assert(not recovered_object.is_empty())
	assert(not bool(recovered_object.get("ambient_protected",false)),
		"backup contains pre-policy projection and must win over corrupt primary")
	assert(str(recovered.runtime_state.get("object_event_status",""))==
		"REPLAYED_FROM_BACKUP")
	assert(FileAccess.file_exists(path+".world_events_v1.json.corrupt"))
	assert(recovered.object_event_revision()==1)
	assert(not _has_event(recovered.journal_entries(64),
		"OBJECT_AMBIENT_PROTECTION_CHANGED"),
		"journal must not retain an event lost with corrupt primary")

	# Corrupt both canonical copies. Snapshot remains readable for inspection,
	# but future object mutations must fail closed.
	_write_text(path+".world_events_v1.json","bad primary")
	_write_text(path+".world_events_v1.json.bak","bad backup")
	var fail_closed := World.new()
	fail_closed.save_path = path
	fail_closed.load_or_seed()
	assert(fail_closed.physical_object("LEGACY_OBJECT").size()>0,
		"compatibility snapshot must remain inspectable")
	assert(str(fail_closed.runtime_state.get("object_event_status",""))==
		"CORRUPT_NO_RECOVERY")
	var revision_before: int = fail_closed.object_event_revision()
	assert(not fail_closed.set_object_ambient_protection("LEGACY_OBJECT",false))
	assert(fail_closed.object_event_revision()==revision_before)

	_cleanup(path)
	print("OBJECT_EVENT_MIGRATION_V020_PASS json=migrated history=preserved backup=replayed journal=canonical corrupt=quarantined double_corrupt=fail_closed")
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	quit(0)
