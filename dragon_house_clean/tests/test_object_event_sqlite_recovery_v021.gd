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

func _overwrite(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	assert(file!=null)
	file.store_string(text)
	file.flush()
	file.close()

func run() -> void:
	var path := "user://object_event_sqlite_recovery_v021.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","sqlite")

	var world := World.new()
	world.save_path = path
	world.seed_world()
	var home: Dictionary = world.get_room(1,-1)
	assert(world.register_physical_object(
		"RECOVERY_OBJECT","Recovery object","RES_01",home["id"],
		true,true,true,true,false))
	assert(world.set_object_ambient_protection("RECOVERY_OBJECT",true))
	assert(world.object_event_revision()==2)
	assert(world.save_world())
	var sqlite_path := path+".world_events_v1.sqlite"
	var backup_path := sqlite_path+".bak"
	assert(FileAccess.file_exists(sqlite_path))
	assert(FileAccess.file_exists(backup_path))
	var expected: Dictionary = world.objects.duplicate(true)
	world.object_events.store.close()

	# Corrupt primary only. Startup must quarantine it and fully validate backup
	# before accepting it as canonical.
	_overwrite(sqlite_path,"not a sqlite database")
	var recovered := World.new()
	recovered.save_path = path
	recovered.load_or_seed()
	assert(str(recovered.runtime_state.get("object_event_status",""))=="REPLAYED_FROM_BACKUP")
	assert(str(recovered.runtime_state.get("object_event_backend",""))=="sqlite_v021_proof")
	assert(recovered.object_event_revision()==2)
	assert(recovered.objects==expected)
	assert(FileAccess.file_exists(sqlite_path+".corrupt"))
	assert(bool(recovered.physical_object("RECOVERY_OBJECT")["ambient_protected"]))
	recovered.object_events.store.close()

	# Corrupt both canonical copies. Compatibility snapshot stays inspectable,
	# but durable object mutations fail closed and no fresh event stream appears.
	_overwrite(sqlite_path,"bad primary again")
	_overwrite(backup_path,"bad backup")
	var fail_closed := World.new()
	fail_closed.save_path = path
	fail_closed.load_or_seed()
	assert(str(fail_closed.runtime_state.get("object_event_status",""))=="CORRUPT_NO_RECOVERY")
	assert(fail_closed.physical_object("RECOVERY_OBJECT").size()>0)
	assert(bool(fail_closed.physical_object("RECOVERY_OBJECT")["ambient_protected"]))
	var revision_before := fail_closed.object_event_revision()
	assert(not fail_closed.set_object_ambient_protection("RECOVERY_OBJECT",false))
	assert(fail_closed.object_event_revision()==revision_before)

	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	_cleanup(path)
	print("OBJECT_EVENT_SQLITE_RECOVERY_V021_PASS primary=quarantined backup=validated replay=yes double_corrupt=fail_closed snapshot=inspectable")
	quit(0)
