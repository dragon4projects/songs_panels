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
		".world_events_v1.sqlite.corrupt",
		".world_events_v1.sqlite.canonical.json",
		".world_events_v1.sqlite.canonical.json.tmp"
	]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))

func _semantic_object(object: Dictionary) -> Dictionary:
	return {
		"id":str(object.get("id","")),
		"display_name":str(object.get("display_name","")),
		"canonical_owner_id":str(object.get("canonical_owner_id","")),
		"home_room_id":str(object.get("home_room_id","")),
		"current_holder_id":str(object.get("current_holder_id","")),
		"current_room_id":str(object.get("current_room_id","")),
		"state":str(object.get("state","")),
		"movable":bool(object.get("movable",false)),
		"recoverable":bool(object.get("recoverable",false)),
		"ambient_pickup_allowed":bool(object.get("ambient_pickup_allowed",false)),
		"ambient_hide_allowed":bool(object.get("ambient_hide_allowed",false)),
		"ambient_protected":bool(object.get("ambient_protected",false)),
		"description":str(object.get("description","")),
		"preview_path":str(object.get("preview_path","")),
		"asset_id":str(object.get("asset_id","")),
		"viewer_category":str(object.get("viewer_category","")),
		"history":(object.get("history",[]) as Array).duplicate(true)
	}

func run() -> void:
	var path := "user://full_world_migration_equivalence_v021.json"
	_cleanup(path)
	# Build a true pre-v0.20 snapshot: JSON world state exists, canonical
	# object-event files do not.
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","json")
	var legacy := World.new()
	legacy.save_path = path
	legacy.seed_world()

	# Make each non-object family observably non-default so a broken migration
	# cannot pass merely because seed_world() happens to recreate similar data.
	var public_room: Dictionary = legacy.get_room(-2,0)
	assert(not public_room.is_empty())
	public_room["display_name"] = "QA preserved room label"
	legacy.residents["RES_01"]["needs"]["curiosity"] = 0.73125
	legacy.residents["RES_01"]["habits"]["QA_PERSIST"] = 0.42
	legacy.media = {
		"books":[{
			"id":"QA_BOOK","title":"QA preserved book","author":"QA",
			"physical":false,"preview":""
		}],
		"films":[{
			"id":"QA_FILM","title":"QA preserved film",
			"file_path":"user://qa_missing.ogv"
		}],
		"tracks":[{
			"id":"QA_TRACK","title":"QA preserved track",
			"file_path":"user://qa_missing.wav"
		}]
	}
	var home: Dictionary = legacy.get_room(1,-1)
	var legacy_object := {
		"id":"QA_LEGACY_OBJECT",
		"display_name":"QA legacy object",
		"canonical_owner_id":"RES_01",
		"home_room_id":str(home["id"]),
		"current_holder_id":"",
		"current_room_id":str(home["id"]),
		"state":"PLACED",
		"movable":true,
		"recoverable":true,
		"ambient_pickup_allowed":true,
		"ambient_hide_allowed":false,
		"ambient_protected":true,
		"description":"QA migration evidence",
		"preview_path":"qa-preview.png",
		"asset_id":"QA_ASSET",
		"viewer_category":"artifacts",
		"history":[{
			"event":"REGISTERED","actor_id":"","from":"",
			"to":str(home["id"]),"sim_clock":0.0
		}]
	}
	legacy.objects["QA_LEGACY_OBJECT"] = legacy_object.duplicate(true)
	assert(legacy.save_world())
	assert(not FileAccess.file_exists(path+".world_events_v1.json"))
	assert(not FileAccess.file_exists(path+".world_events_v1.sqlite"))
	var snapshot_sha := FileAccess.get_sha256(path)

	var expected_rooms: Array = legacy.rooms.duplicate(true)
	var expected_residents: Dictionary = legacy.residents.duplicate(true)
	var expected_media: Dictionary = legacy.media.duplicate(true)
	var expected_object: Dictionary = _semantic_object(legacy_object)

	# Normal production launch: no override. Vendored SQLite must migrate only
	# object truth and leave rooms/residents/media byte-semantically unchanged.
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	var migrated := World.new()
	migrated.save_path = path
	migrated.load_or_seed()
	assert(str(migrated.runtime_state.get("object_event_backend",""))=="sqlite_v021_proof")
	assert(str(migrated.runtime_state.get("object_event_status",""))=="MIGRATED_JSON_SNAPSHOT")
	assert(FileAccess.get_sha256(path)==snapshot_sha,
		"legacy source snapshot must remain byte-identical")
	assert(migrated.rooms==expected_rooms,
		"room registry changed during object persistence migration")
	assert(migrated.residents==expected_residents,
		"resident state changed during object persistence migration")
	assert(migrated.media==expected_media,
		"media registry changed during object persistence migration")
	assert(_semantic_object(migrated.physical_object("QA_LEGACY_OBJECT"))==expected_object,
		"object semantic state changed during migration")
	assert(migrated.object_events.store.derived_objects_snapshot()==migrated.objects)
	migrated.object_events.store.close()

	# A second startup must replay canonical SQLite object truth while still
	# reading the unchanged compatibility snapshot for the other families.
	var restarted := World.new()
	restarted.save_path = path
	restarted.load_or_seed()
	assert(restarted.rooms==expected_rooms)
	assert(restarted.residents==expected_residents)
	assert(restarted.media==expected_media)
	assert(_semantic_object(restarted.physical_object("QA_LEGACY_OBJECT"))==expected_object)
	assert(FileAccess.get_sha256(path)==snapshot_sha)
	restarted.object_events.store.close()

	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	_cleanup(path)
	print("FULL_WORLD_MIGRATION_EQUIVALENCE_V021_PASS rooms=equivalent residents=equivalent media=equivalent objects=semantic_equivalent source_snapshot=unchanged restart=equivalent")
	quit(0)
