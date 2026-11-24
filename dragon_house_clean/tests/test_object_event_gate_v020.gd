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
		".world_events_v1.json.corrupt"
	]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))

func _manual_event(event_id: String, event_type: String, truth_class: String,
		authority: String, object: Dictionary, room_id: String,
		payload: Dictionary) -> Dictionary:
	return {
		"event_id":event_id,
		"created_at":Time.get_unix_time_from_system(),
		"timestamp":Time.get_unix_time_from_system(),
		"source_type":"renderer" if truth_class=="PRESENTATION_ONLY" else "ambient_simulation",
		"source_id":"QA_DIRECT",
		"authority":authority,
		"truth_class":truth_class,
		"visibility":"house_public",
		"event_type":event_type,
		"subject_id":"MANJKA",
		"object_id":str(object.get("id","")),
		"room_id":room_id,
		"from":room_id,
		"to":room_id,
		"expires_at":null,
		"reversibility":"AMBIENT_REVERTIBLE",
		"provenance":"QA_GATE_BYPASS_ATTEMPT",
		"notes":"negative-path QA",
		"payload":payload
	}

func run() -> void:
	var path := "user://object_event_gate_v020.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","json")
	var world := World.new()
	world.save_path = path
	world.seed_world()
	var room: Dictionary = world.get_room(-2,0)
	assert(not room.is_empty())
	var manjka: Dictionary = world.residents["MANJKA"]
	manjka["room_id"] = room["id"]
	manjka["x"] = float(room["x"])*World.MODULE_W
	manjka["level"] = int(room["level"])

	# Direct WorldModel calls may no longer bypass ambient policy.
	assert(world.register_physical_object(
		"NO_AMBIENT","Not ambient","RES_01",room["id"],
		true,true,false,true,false,{"object_class":"small_artifact"}))
	var rev_no_ambient: int = world.object_event_revision()
	assert(not world.pickup_physical_object("NO_AMBIENT","MANJKA"))
	assert(world.object_event_revision()==rev_no_ambient)

	assert(world.register_physical_object(
		"PROTECTED","Protected","RES_01",room["id"],
		true,true,true,true,true,{"object_class":"small_artifact"}))
	var rev_protected: int = world.object_event_revision()
	assert(not world.pickup_physical_object("PROTECTED","MANJKA"))
	assert(world.object_event_revision()==rev_protected)

	assert(world.register_creature(
		"NO_PICK","No pick",room["id"],"", "",false,false,false))
	assert(world.register_physical_object(
		"CREATURE_DENIED","Creature denied","",room["id"],
		true,true,true,true,false,{"object_class":"small_artifact"}))
	var rev_creature: int = world.object_event_revision()
	assert(not world.pickup_physical_object("CREATURE_DENIED","NO_PICK"))
	assert(world.object_event_revision()==rev_creature)

	assert(world.register_creature(
		"PICK_NO_HIDE","Pick no hide",room["id"],"", "",true,false,false))
	assert(world.register_physical_object(
		"HIDE_BY_CREATURE","Hide candidate","",room["id"],
		true,true,true,true,false,{"object_class":"small_artifact"}))
	assert(world.pickup_physical_object("HIDE_BY_CREATURE","PICK_NO_HIDE"))
	var hide_obj: Dictionary = world.physical_object("HIDE_BY_CREATURE")
	var rev_hide_denied: int = world.object_event_revision()
	assert(not world.place_physical_object(
		"HIDE_BY_CREATURE","PICK_NO_HIDE",room["id"],"STASHED"))
	assert(world.object_event_revision()==rev_hide_denied)
	assert(str(hide_obj["state"])=="HELD")
	assert(world.place_physical_object(
		"HIDE_BY_CREATURE","PICK_NO_HIDE",room["id"],"PLACED"))

	assert(world.register_creature(
		"PICK_HIDE","Pick hide",room["id"],"", "",true,true,false))
	assert(world.register_physical_object(
		"HIDE_POLICY_DENIED","No hide policy","",room["id"],
		true,true,true,false,false,{"object_class":"small_artifact"}))
	assert(world.pickup_physical_object("HIDE_POLICY_DENIED","PICK_HIDE"))
	var rev_hide_policy: int = world.object_event_revision()
	assert(not world.place_physical_object(
		"HIDE_POLICY_DENIED","PICK_HIDE",room["id"],"STASHED"))
	assert(world.object_event_revision()==rev_hide_policy)
	assert(world.place_physical_object(
		"HIDE_POLICY_DENIED","PICK_HIDE",room["id"],"PLACED"))

	# Presentation and ambient ownership mutations are rejected before append,
	# projection and House Journal.
	var object: Dictionary = world.physical_object("NO_AMBIENT")
	var journal_before: int = world.journal.size()
	var revision_before: int = world.object_event_revision()
	var presentation_payload := {
		"object_id":"NO_AMBIENT","movement_kind":"PLACED","actor_id":"MANJKA",
		"previous_holder":str(object.get("current_holder_id","")),
		"previous_location":str(object.get("current_room_id","")),
		"current_holder":"","current_location":str(room["id"]),"state":"PLACED",
		"canonical_owner":str(object.get("canonical_owner_id",""))
	}
	var presentation_result: Dictionary = world.submit_object_event(_manual_event(
		"QA_PRESENTATION_MUTATION","OBJECT_MOVED","PRESENTATION_ONLY",
		"PRESENTATION",object,str(room["id"]),presentation_payload))
	assert(not bool(presentation_result.get("ok",false)))
	assert(world.object_event_revision()==revision_before)
	assert(world.journal.size()==journal_before)

	var elevated: Dictionary = _manual_event(
		"QA_RENDERER_ELEVATION","OBJECT_MOVED","EXPLICIT_WORLD_FACT",
		"DRAGON_DECLARED",object,str(room["id"]),presentation_payload)
	elevated["source_type"] = "renderer"
	var elevated_result: Dictionary = world.submit_object_event(elevated)
	assert(not bool(elevated_result.get("ok",false)))
	assert(str(elevated_result.get("error","")).contains("elevate"))
	assert(world.object_event_revision()==revision_before)
	assert(world.journal.size()==journal_before)

	var owner_result: Dictionary = world.submit_object_event(_manual_event(
		"QA_AMBIENT_OWNER_CHANGE","OBJECT_OWNER_CHANGED","AMBIENT_SIMULATION",
		"AMBIENT",object,str(room["id"]),
		{"object_id":"NO_AMBIENT","canonical_owner":"RES_02"}))
	assert(not bool(owner_result.get("ok",false)))
	assert(str(object["canonical_owner_id"])=="RES_01")
	assert(world.object_event_revision()==revision_before)
	assert(world.journal.size()==journal_before)

	# Duplicate identity is idempotent at the authoritative boundary.
	assert(world.set_object_ambient_protection("NO_AMBIENT",true))
	var accepted: Dictionary = world.object_events.store.events[
		world.object_events.store.events.size()-1].duplicate(true)
	var duplicate_revision: int = world.object_event_revision()
	var history_before: int = (object.get("history",[]) as Array).size()
	var duplicate_result: Dictionary = world.submit_object_event(accepted)
	assert(not bool(duplicate_result.get("ok",false)))
	assert(bool(duplicate_result.get("duplicate",false)))
	assert(world.object_event_revision()==duplicate_revision)
	assert((object.get("history",[]) as Array).size()==history_before)

	# Every accepted persistent event carries the canonical envelope.
	for raw_event in world.object_events.store.events:
		var event: Dictionary = raw_event
		for field in [
			"event_id","created_at","source_type","source_id","authority",
			"truth_class","visibility","event_type","reversibility",
			"provenance","payload","seq"
		]:
			assert(event.has(field),"accepted event missing "+field)

	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	_cleanup(path)
	print("OBJECT_EVENT_GATE_V020_PASS direct_bypass=blocked protected=blocked creature_caps=central hide_caps=central presentation=no_truth renderer_elevation=blocked owner=stable duplicate=idempotent envelope=typed")
	quit(0)
