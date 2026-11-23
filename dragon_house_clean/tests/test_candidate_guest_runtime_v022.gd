extends SceneTree
const World = preload("res://scripts/world_model.gd")
const CandidateContent = preload("res://scripts/candidate_content_runtime.gd")
const Stations = preload("res://scripts/room_stations.gd")

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

func run() -> void:
	var path := "user://candidate_guest_runtime_v022.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","json")

	var world := World.new()
	world.save_path = path
	world.seed_world()
	var content := CandidateContent.new()
	assert(content.initialize(),content.last_error)

	for id in ["NPC_CENTAUR","NPC_VAMPIRE_GIRL","NPC_GINGER_CAT_GUEST"]:
		assert(not world.residents.has(id),
			"candidate asset presence must not auto-register guests")
	for room_id in ["guest_centaur_01","guest_vampire_01","guest_miu_01"]:
		assert(world.room_by_id(room_id).is_empty(),
			"candidate room presence must require explicit integration call")

	assert(content.install_guest_rooms_for_qa(world)==3,content.last_error)
	assert(content.install_guest_rooms_for_qa(world)==0,
		"guest room installation must be idempotent")
	assert(content.register_all_guests_for_qa(world)==3,content.last_error)
	assert(content.register_all_guests_for_qa(world)==0,
		"guest registration must be idempotent")

	var centaur_room: Dictionary = world.room_by_id("guest_centaur_01")
	var vampire_room: Dictionary = world.room_by_id("guest_vampire_01")
	var miu_room: Dictionary = world.room_by_id("guest_miu_01")
	assert([centaur_room["x"],centaur_room["level"]]==[6,0])
	assert([vampire_room["x"],vampire_room["level"]]==[6,1])
	assert([miu_room["x"],miu_room["level"]]==[6,-1])
	for room in [centaur_room,vampire_room,miu_room]:
		assert(str(room.get("type",""))=="guest")
		assert(str(room.get("guest_access_state",""))=="open")
		assert(world.public_cutaway_allowed(room))

	assert(str(centaur_room.get("owner_id",""))=="NPC_CENTAUR")
	assert(str(vampire_room.get("owner_id",""))=="NPC_VAMPIRE_GIRL")
	assert(str(miu_room.get("owner_id",""))=="NPC_GINGER_CAT_GUEST")
	assert(str(world.residents["NPC_GINGER_CAT_GUEST"].get("name",""))=="Миу")
	assert(str(world.residents["NPC_CENTAUR"].get("station_profile",""))=="quadruped_large")
	assert(not bool(world.residents["NPC_CENTAUR"].get("human_seat_allowed",true)))
	assert(str(world.residents["NPC_GINGER_CAT_GUEST"].get("station_profile",""))=="small_quadruped")
	assert(not bool(world.residents["NPC_GINGER_CAT_GUEST"].get("human_seat_allowed",true)))

	var visitor_id := "RES_01"
	for room in [centaur_room,vampire_room,miu_room]:
		assert(not world.find_route(
			str(world.residents[visitor_id]["room_id"]),str(room["id"]),visitor_id).is_empty())

	var private_room: Dictionary = world.get_room(3,1)
	assert(str(private_room.get("type",""))=="private")
	assert(not world.is_accessible(private_room,visitor_id),
		"guest integration must not relax resident-private access")

	var stations := Stations.new()
	var centaur_layout := stations.layout_for_world(world,centaur_room)
	var vampire_layout := stations.layout_for_world(world,vampire_room)
	var miu_layout := stations.layout_for_world(world,miu_room)
	assert(centaur_layout.size()==3)
	assert(vampire_layout.size()==4)
	assert(miu_layout.size()==1)
	for spot in centaur_layout:
		assert(str(spot.get("kind",""))!="seat")
	assert(str(miu_layout[0].get("kind",""))=="floor_rest")
	assert(str(miu_layout[0].get("furniture_id",""))=="miu_low_pad")

	var centaur: Dictionary = world.residents["NPC_CENTAUR"]
	var vampire: Dictionary = world.residents["NPC_VAMPIRE_GIRL"]
	var miu: Dictionary = world.residents["NPC_GINGER_CAT_GUEST"]
	var centaur_rest := stations.single(world,centaur,centaur_room,"REST")
	assert(str(centaur_rest.get("kind",""))=="floor_rest")
	var centaur_read := stations.single(world,centaur,centaur_room,"READ_BOOK")
	assert(str(centaur_read.get("kind",""))=="work")
	var miu_rest := stations.single(world,miu,miu_room,"REST")
	assert(str(miu_rest.get("kind",""))=="floor_rest")
	var no_human_seat_fallback := stations.single(
		world,centaur,vampire_room,"REST")
	assert(no_human_seat_fallback.is_empty(),
		"centaur must not fall back to vampire human seating")
	var common: Dictionary = world.get_room(-2,0)
	var pair_claim := stations.pair(world,centaur,vampire,common)
	if not pair_claim.is_empty():
		assert(str(pair_claim["actor"].get("kind",""))!="seat",
			"centaur TALK pair must never claim a human seat")

	assert(world.save_world())
	var loaded := World.new()
	loaded.save_path = path
	loaded.load_or_seed()
	for id in ["NPC_CENTAUR","NPC_VAMPIRE_GIRL","NPC_GINGER_CAT_GUEST"]:
		assert(loaded.residents.has(id))
	assert(loaded.room_by_id("guest_centaur_01").get("owner_id","")=="NPC_CENTAUR")
	assert(loaded.room_by_id("guest_vampire_01").get("owner_id","")=="NPC_VAMPIRE_GIRL")
	assert(loaded.room_by_id("guest_miu_01").get("owner_id","")=="NPC_GINGER_CAT_GUEST")

	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	_cleanup(path)
	print("CANDIDATE_GUEST_RUNTIME_V022_PASS rooms=3 stable_ids=yes miu=one routes=open private=closed centaur=quadruped_no_human_seat miu=low_pad persistence=yes")
	quit(0)
