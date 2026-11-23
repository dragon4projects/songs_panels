extends RefCounted
const CandidateBanksScript = preload("res://scripts/candidate_actor_bank_resolver.gd")
## Explicit QA/integration gate for staged guest and creature content.
## Nothing in this class runs automatically from main.gd.

var banks = CandidateBanksScript.new()
var last_error := ""

func initialize(path: String = CandidateBanksScript.REGISTRY_PATH) -> bool:
	last_error = ""
	if not banks.initialize(path):
		last_error = banks.last_error
		return false
	return true

func _guest_spec(guest_id: String) -> Dictionary:
	return banks.guest_entry(guest_id)

func _room_spec(guest_id: String) -> Dictionary:
	var guest := _guest_spec(guest_id)
	var cell = guest.get("room_cell",[])
	if typeof(cell) != TYPE_ARRAY or cell.size() != 2:
		return {}
	var room_id := str(guest.get("room_candidate",""))
	if room_id == "":
		return {}
	return {
		"id":room_id,
		"x":int(cell[0]),
		"level":int(cell[1]),
		"type":"guest",
		"guest_id":guest_id
	}

func guest_room_specs() -> Array:
	var out: Array = []
	for guest_id in banks.guest_ids():
		var spec := _room_spec(str(guest_id))
		if not spec.is_empty():
			out.append(spec)
	out.sort_custom(func(a,b): return str(a["id"]) < str(b["id"]))
	return out

func preflight_guest_rooms(world) -> bool:
	last_error = ""
	if world == null:
		last_error = "World is required"
		return false
	var seen_ids: Dictionary = {}
	var seen_cells: Dictionary = {}
	var specs := guest_room_specs()
	if specs.size() != 3:
		last_error = "Exactly three named guest-room specs are required"
		return false
	for spec in specs:
		var room_id := str(spec["id"])
		var cell_key := "%d:%d" % [int(spec["x"]),int(spec["level"])]
		if seen_ids.has(room_id) or seen_cells.has(cell_key):
			last_error = "Duplicate guest room id/cell in candidate registry"
			return false
		seen_ids[room_id] = true
		seen_cells[cell_key] = true
		var by_id: Dictionary = world.room_by_id(room_id)
		var by_cell: Dictionary = world.get_room(int(spec["x"]),int(spec["level"]))
		if not by_id.is_empty():
			if (int(by_id.get("x",9999)) != int(spec["x"])
					or int(by_id.get("level",9999)) != int(spec["level"])
					or str(by_id.get("type","")) != "guest"):
				last_error = "Existing named guest room conflicts with candidate spec: " + room_id
				return false
			if not by_cell.is_empty() and str(by_cell.get("id","")) != room_id:
				last_error = "Guest room coordinate is occupied by another room: " + cell_key
				return false
			continue
		if not by_cell.is_empty():
			last_error = "Guest room coordinate is occupied: " + cell_key
			return false
		if not world.can_build(int(spec["x"]),int(spec["level"]),"guest"):
			last_error = "Guest room is not connected/buildable: " + room_id
			return false
	return true

func install_guest_rooms_for_qa(world) -> int:
	if not preflight_guest_rooms(world):
		return -1
	var created := 0
	for spec in guest_room_specs():
		var room_id := str(spec["id"])
		if not world.room_by_id(room_id).is_empty():
			continue
		var room := world.make_room_with_id(
			room_id,int(spec["x"]),int(spec["level"]),"guest")
		if room.is_empty():
			last_error = "Failed to create guest room: " + room_id
			return -1
		created += 1
	if created > 0:
		world.save_world()
	return created

func register_guest_for_qa(world, guest_id: String) -> bool:
	last_error = ""
	if world == null:
		last_error = "World is required"
		return false
	var guest := _guest_spec(guest_id)
	if guest.is_empty():
		last_error = "Unknown guest candidate: " + guest_id
		return false
	var room_id := str(guest.get("room_candidate",""))
	var room: Dictionary = world.room_by_id(room_id)
	if room.is_empty() or str(room.get("type","")) != "guest":
		last_error = "Guest candidate room is not installed: " + room_id
		return false
	if world.residents.has(guest_id):
		var existing: Dictionary = world.residents[guest_id]
		return (str(existing.get("entity_type","")) == "guest"
			and str(existing.get("home_room_id","")) == room_id)
	if world.creatures.has(guest_id):
		last_error = "Guest ID collides with creature registry: " + guest_id
		return false
	if not world.register_guest_actor(
			guest_id,
			str(guest.get("display_name",guest_id)),
			room_id,
			str(guest.get("species","")),
			guest_id):
		last_error = "World rejected guest registration: " + guest_id
		return false
	var actor: Dictionary = world.residents[guest_id]
	actor["candidate_visual_ready"] = banks.guest_bank_metadata_ready(guest_id)
	actor["production_visual_ready"] = false
	actor["visual_status"] = "CANDIDATE"
	actor["footprint_turning_diameter_m"] = banks.guest_turning_diameter_m(guest_id)
	if guest_id == "NPC_CENTAUR":
		actor["station_profile"] = "quadruped_large"
		actor["human_seat_allowed"] = false
	elif guest_id == "NPC_GINGER_CAT_GUEST":
		actor["station_profile"] = "small_quadruped"
		actor["human_seat_allowed"] = false
	return true

func register_all_guests_for_qa(world) -> int:
	if install_guest_rooms_for_qa(world) < 0:
		return -1
	var registered := 0
	for guest_id in banks.guest_ids():
		var existed := world.residents.has(str(guest_id))
		if not register_guest_for_qa(world,str(guest_id)):
			return -1
		if not existed:
			registered += 1
	if registered > 0:
		world.save_world()
	return registered

func register_creature_for_qa(world, bank_id: String, display_name: String,
		room_id: String, can_pickup: bool = false,
		can_hide: bool = false) -> bool:
	last_error = ""
	if world == null or display_name.strip_edges() == "":
		last_error = "World and explicit display name are required"
		return false
	if not banks.has_creature(bank_id):
		last_error = "Unknown creature candidate: " + bank_id
		return false
	if world.creatures.has(bank_id) or world.residents.has(bank_id):
		last_error = "Creature candidate ID already exists: " + bank_id
		return false
	var room: Dictionary = world.room_by_id(room_id)
	if room.is_empty() or str(room.get("privacy","public")) != "public":
		last_error = "Creature QA registration requires a public room"
		return false
	var owner_id := banks.owner_claim(bank_id)
	if not world.register_creature(
			bank_id,display_name,room_id,bank_id,owner_id,
			can_pickup,can_hide,false):
		last_error = "World rejected creature registration: " + bank_id
		return false
	var creature: Dictionary = world.creatures[bank_id]
	creature["candidate_visual_ready"] = banks.creature_bank_metadata_ready(bank_id)
	creature["production_visual_ready"] = false
	creature["visual_status"] = "CANDIDATE"
	return true
