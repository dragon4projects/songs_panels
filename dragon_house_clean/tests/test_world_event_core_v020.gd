extends SceneTree
const World = preload("res://scripts/world_model.gd")

func _initialize() -> void:
	call_deferred("run")

func _cleanup(path: String) -> void:
	for suffix in ["",".bak",".tmp",".events.json",".events.json.bak",".events.json.tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))

func run() -> void:
	var path := "user://world_event_core_v020.json"
	_cleanup(path)

	var world := World.new()
	world.save_path = path
	world.seed_world()
	var home: Dictionary = world.get_room(1,-1)
	var stash: Dictionary = world.get_room(-2,0)
	assert(not home.is_empty() and not stash.is_empty())

	assert(world.register_physical_object(
		"QA_EVENT_OBJECT_001","event-sourced QA artifact","RES_01",str(home["id"]),
		true,true,true,false,false))
	assert(world.event_core.events.size()==1)
	assert(world.event_core.object_revision("QA_EVENT_OBJECT_001")==1)
	var registration: Dictionary = world.event_core.events[0]
	assert(str(registration["truth_class"])=="EXPLICIT_WORLD_FACT")
	assert(str(registration["authority"])=="SYSTEM_INIT")
	var registration_id := str(registration["event_id"])
	assert(registration_id!="")

	# Exact duplicate ID + envelope is an idempotent acknowledgement.
	var duplicate: Dictionary = world.event_core.append_object_event(
		str(registration["event_type"]),str(registration["subject_id"]),
		str(registration["actor_id"]),registration["payload"],
		float(registration["sim_clock"]),str(registration["authority"]),
		str(registration["truth_class"]),0,registration_id)
	assert(bool(duplicate.get("ok",false)))
	assert(bool(duplicate.get("duplicate",false)))
	assert(world.event_core.events.size()==1)

	# Stale expected revision is rejected and must not enter durable history.
	var stale: Dictionary = world.event_core.append_object_event(
		"OBJECT_AMBIENT_PROTECTION_CHANGED","QA_EVENT_OBJECT_001","",
		{"protected":true,"from":"ELIGIBLE","to":"PROTECTED"},
		world.sim_clock,"HOUSE_SYSTEM","EXPLICIT_WORLD_FACT",0)
	assert(not bool(stale.get("ok",false)))
	assert(world.event_core.events.size()==1)

	# Structurally valid but semantically impossible transitions must be rejected
	# before they enter durable history.
	var invalid_transition: Dictionary = world.event_core.append_object_event(
		"OBJECT_STASHED","QA_EVENT_OBJECT_001","MANJKA",
		{"from":"MANJKA","to":str(stash["id"]),"state":"STASHED"},
		world.sim_clock,"SIMULATION","AMBIENT_SIMULATION",1)
	assert(not bool(invalid_transition.get("ok",false)))
	assert(world.event_core.events.size()==1)

	var presentation_mutation: Dictionary = world.event_core.append_object_event(
		"OBJECT_AMBIENT_PROTECTION_CHANGED","QA_EVENT_OBJECT_001","",
		{"protected":true,"from":"ELIGIBLE","to":"PROTECTED"},
		world.sim_clock,"PRESENTATION","PRESENTATION_ONLY",1)
	assert(not bool(presentation_mutation.get("ok",false)))
	assert(world.event_core.events.size()==1)

	var manjka: Dictionary = world.residents["MANJKA"]
	manjka["room_id"] = str(home["id"])
	manjka["x"] = float(home["x"]) * World.MODULE_W
	manjka["level"] = int(home["level"])
	assert(world.pickup_physical_object("QA_EVENT_OBJECT_001","MANJKA"))
	manjka["room_id"] = str(stash["id"])
	assert(world.place_physical_object(
		"QA_EVENT_OBJECT_001","MANJKA",str(stash["id"]),"STASHED"))
	assert(world.event_core.object_revision("QA_EVENT_OBJECT_001")==3)

	var live: Dictionary = world.physical_object("QA_EVENT_OBJECT_001")
	assert(str(live["canonical_owner_id"])=="RES_01")
	assert(str(live["state"])=="STASHED")
	assert(str(live["current_room_id"])==str(stash["id"]))
	assert(str(live["current_holder_id"])=="")

	# No compatibility snapshot exists yet. A new World must seed deterministic
	# topology and then rebuild the event-sourced object projection.
	var recovered := World.new()
	recovered.save_path = path
	recovered.load_or_seed()
	var rebuilt: Dictionary = recovered.physical_object("QA_EVENT_OBJECT_001")
	assert(not rebuilt.is_empty())
	assert(str(rebuilt["canonical_owner_id"])=="RES_01")
	assert(str(rebuilt["state"])=="STASHED")
	assert(str(rebuilt["current_room_id"])==str(stash["id"]))
	assert(recovered.event_core.object_revision("QA_EVENT_OBJECT_001")==3)
	assert(recovered.event_core.events.size()==3)

	# Reconciled causal journal must contain each durable event ID once.
	var seen: Dictionary = {}
	for row in recovered.journal:
		var event_id := str(row.get("details",{}).get("event_id",""))
		if event_id == "":
			continue
		assert(not seen.has(event_id))
		seen[event_id] = true
	assert(seen.has(registration_id))
	assert(seen.size()==3)

	assert(recovered.set_object_ambient_protection("QA_EVENT_OBJECT_001",true))
	assert(not recovered.can_ambient_pickup_object("QA_EVENT_OBJECT_001"))
	assert(recovered.recover_physical_object_to_lost_found(
		"QA_EVENT_OBJECT_001",str(stash["id"])))
	var after_recovery: Dictionary = recovered.physical_object("QA_EVENT_OBJECT_001")
	assert(str(after_recovery["canonical_owner_id"])=="RES_01")
	assert(str(after_recovery["state"])=="LOST_FOUND")
	assert(recovered.event_core.object_revision("QA_EVENT_OBJECT_001")==5)
	assert(recovered.save_world())

	var restarted := World.new()
	restarted.save_path = path
	restarted.load_or_seed()
	var final_object: Dictionary = restarted.physical_object("QA_EVENT_OBJECT_001")
	assert(str(final_object["canonical_owner_id"])=="RES_01")
	assert(str(final_object["state"])=="LOST_FOUND")
	assert(restarted.event_core.events.size()==5)
	assert(bool(restarted.runtime_state.get("world_event_core",{}).get("store_ready",false)))

	# If both compatibility snapshot and readable event history are unavailable,
	# the runtime may seed a diagnostic shell but must not persist a fake clean
	# recovery over the evidence gap.
	_cleanup(path)
	var corrupt := FileAccess.open(path+".events.json",FileAccess.WRITE)
	assert(corrupt != null)
	corrupt.store_string("{broken-event-store")
	corrupt.flush()
	corrupt.close()
	var blocked := World.new()
	blocked.save_path = path
	blocked.load_or_seed()
	assert(not blocked.event_core.store_ready)
	assert(FileAccess.file_exists(path+".events.json"))
	assert(not FileAccess.file_exists(path))
	assert(str(blocked.event_core.last_error).contains("unreadable"))

	_cleanup(path)
	print("WORLD_EVENT_CORE_V020_PASS durable=yes reducer=yes duplicate_idempotent=yes stale_revision_rejected=yes semantic_invalid_rejected=yes presentation_cannot_mutate=yes snapshotless_rebuild=yes owner_immutable=yes journal_reconciled=yes corrupt_history_fail_closed=yes")
	quit(0)
