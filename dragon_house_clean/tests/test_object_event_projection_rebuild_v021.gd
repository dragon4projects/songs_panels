extends SceneTree
const World = preload("res://scripts/world_model.gd")

func _initialize() -> void:
	call_deferred("run")

func _cleanup(path: String) -> void:
	for suffix in [
		"",".bak",".tmp",
		".world_events_v1.sqlite",".world_events_v1.sqlite.bak",
		".world_events_v1.sqlite-wal",".world_events_v1.sqlite-shm",
		".world_events_v1.sqlite.corrupt"
	]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))

func run() -> void:
	var path := "user://object_event_projection_rebuild_v021.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","sqlite")

	var world := World.new()
	world.save_path = path
	world.seed_world()
	var home: Dictionary = world.get_room(1,-1)
	assert(world.register_physical_object(
		"REBUILD_OBJECT","Projection rebuild object","RES_01",home["id"],
		true,true,false,false,true))
	assert(world.set_object_ambient_protection("REBUILD_OBJECT",false))
	assert(world.object_event_revision()==2)
	assert(world.save_world())
	var event_identity: Array = []
	for raw in world.object_events.store.snapshot_events():
		var event: Dictionary = raw
		event_identity.append([int(event.get("seq",0)),str(event.get("event_id",""))])

	# Tamper only the disposable derived table; canonical events stay intact.
	assert(bool(world.object_events.store.db.call("query","DELETE FROM objects;")))
	assert(world.object_events.store.derived_objects_snapshot().is_empty())
	world.object_events.store.close()
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")

	var restarted := World.new()
	restarted.save_path = path
	restarted.load_or_seed()
	assert(str(restarted.runtime_state.get("object_event_status",""))=="REPLAYED")
	assert(bool(restarted.runtime_state.get("object_event_projection_rebuilt",false)))
	assert(restarted.object_event_revision()==2)
	var after_identity: Array = []
	for raw in restarted.object_events.store.snapshot_events():
		var event: Dictionary = raw
		after_identity.append([int(event.get("seq",0)),str(event.get("event_id",""))])
	assert(after_identity==event_identity,
		"projection rebuild must never rewrite canonical event identity/order")
	assert(restarted.object_events.store.derived_objects_snapshot()==restarted.objects)
	assert(str(restarted.physical_object("REBUILD_OBJECT").get("canonical_owner_id",""))=="RES_01")
	restarted.object_events.store.close()

	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	_cleanup(path)
	print("OBJECT_EVENT_PROJECTION_REBUILD_V021_PASS canonical_events=unchanged derived_objects=repaired restart=reducer_authoritative")
	quit(0)
