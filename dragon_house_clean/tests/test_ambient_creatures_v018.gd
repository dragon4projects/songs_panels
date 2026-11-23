extends SceneTree
const World = preload("res://scripts/world_model.gd")
const Ambient = preload("res://scripts/ambient_creature_runtime.gd")

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

func _has_event(entries: Array, event_name: String) -> bool:
	for item in entries:
		if str(item.get("event","")) == event_name:
			return true
	return false

func run() -> void:
	var path := "user://ambient_creatures_v018.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	var world := World.new()
	world.save_path = path
	world.seed_world()
	assert(str(world.runtime_state.get("object_event_backend",""))=="sqlite_v021_proof")

	var common_a: Dictionary = world.get_room(-2,0)
	var common_b: Dictionary = world.get_room(-1,0)
	var private_room: Dictionary = world.get_room(2,1)
	assert(not common_a.is_empty() and not common_b.is_empty() and not private_room.is_empty())

	assert(world.register_creature(
		"npc_rat_hero","Крыса",common_a["id"],"npc_rat_hero","",
		true,true,false))
	assert(world.creature_display_label("npc_rat_hero")=="Крыса")
	assert(world.register_creature(
		"PET_CAT_QA","Кот",common_a["id"],"npc_cat_tabby","RES_01",
		false,false,false))
	assert(world.creature_display_label("PET_CAT_QA").contains(world.residents["RES_01"]["name"]))
	assert(not world.register_creature(
		"BAD_PRIVATE","Не должна войти",private_room["id"],"npc_rat_white"))
	assert(world.register_guest_actor(
		"NPC_VAMPIRE_GIRL","Вампирша",world.get_room(1,1)["id"],
		"humanoid","NPC_VAMPIRE_GIRL"))
	assert(world.residents["NPC_VAMPIRE_GIRL"]["entity_type"]=="guest")
	assert(bool(world.residents["NPC_VAMPIRE_GIRL"]["guest"]))

	assert(world.register_physical_object(
		"LOOSE_MUG","Кружка","",common_a["id"],true,true,true,true,false))
	assert(world.register_physical_object(
		"PROTECTED_ARTIFACT","Защищённый артефакт","RES_01",common_a["id"],
		true,true,true,true,true))
	assert(world.can_ambient_pickup_object("LOOSE_MUG"))
	assert(not world.can_ambient_pickup_object("PROTECTED_ARTIFACT"))

	var ambient := Ambient.new()
	ambient.setup(world)
	assert(not ambient.pickup_eligible_here("npc_rat_hero","PROTECTED_ARTIFACT"))
	assert(ambient.pickup_eligible_here("npc_rat_hero","LOOSE_MUG"))
	var mug: Dictionary = world.physical_object("LOOSE_MUG")
	assert(str(mug["current_holder_id"])=="npc_rat_hero")
	assert(str(mug["current_room_id"])=="")
	assert(str(mug["canonical_owner_id"])=="")

	# Closed/private rooms are not destinations even though their public frontage
	# may participate in resident transit.
	assert(not ambient.roam_one_step("npc_rat_hero",private_room["id"]))
	assert(_has_event(world.journal_entries(64),"CREATURE_ACCESS_REJECTED"))
	assert(ambient.roam_one_step("npc_rat_hero",common_b["id"]))
	assert(str(world.creatures["npc_rat_hero"]["phase"])=="travel")
	var travel_steps := 0
	while str(world.creatures["npc_rat_hero"].get("phase",""))=="travel" and travel_steps<500:
		ambient.advance_travel("npc_rat_hero",0.05)
		travel_steps += 1
	assert(travel_steps<500)
	assert(str(world.creatures["npc_rat_hero"]["room_id"])==str(common_b["id"]))
	assert(_has_event(world.journal_entries(64),"CREATURE_ROAMED"))
	assert(ambient.stash_carried("npc_rat_hero"))
	assert(str(mug["state"])=="STASHED")
	assert(str(mug["current_room_id"])==str(common_b["id"]))
	assert(str(mug["current_holder_id"])=="")
	assert(str(world.creatures["npc_rat_hero"]["carried_object_id"])=="")

	var events: Array = world.journal_entries(64)
	assert(_has_event(events,"CREATURE_REGISTERED"))
	assert(_has_event(events,"GUEST_REGISTERED"))
	assert(_has_event(events,"OBJECT_PICKED_UP"))
	assert(_has_event(events,"CREATURE_ROAMED"))
	assert(_has_event(events,"OBJECT_STASHED"))

	assert(world.save_world())
	var loaded := World.new()
	loaded.save_path = path
	loaded.load_or_seed()
	assert(loaded.creatures.has("npc_rat_hero"))
	assert(str(loaded.creatures["npc_rat_hero"]["room_id"])==str(common_b["id"]))
	assert(str(loaded.physical_object("LOOSE_MUG")["state"])=="STASHED")
	assert(_has_event(loaded.journal_entries(64),"OBJECT_STASHED"))

	_cleanup(path)
	print("AMBIENT_CREATURES_V018_PASS public_roam=yes private_bypass=no rejected_logged=yes waypoint_travel=yes owner_label=evidence_only opt_in_pickup=yes protected=no stash=persistent journal=causal guest=registered")
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	quit(0)
