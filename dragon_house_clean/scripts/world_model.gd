extends RefCounted
## One authoritative local simulation state. No chat/LLM interfaces.
const SAVE_PATH := "user://dragon_house_world_v01.json"
const ObjectEventRuntime = preload("res://scripts/object_event_runtime.gd")
const RoomSpaceV2 = preload("res://scripts/room_space_v2.gd")
const CanonicalHouseSeed = preload("res://scripts/canonical_house_seed.gd")
var canonical_house_seed := false
var room_space = RoomSpaceV2.new()
var save_path: String = SAVE_PATH
var sim_clock: float = 0.0
const MODULE_W := RoomSpaceV2.MODULE_W
const FLOOR_H := RoomSpaceV2.FLOOR_H
const GAME_DAY_SECONDS := 86400.0
const DRINK_VESSEL_IDLE_SECONDS := 86400.0
var vessel_reset_scan_at:float=-1.0
const ROOM_TYPES := ["arrival", "corridor", "common", "study", "rest", "library", "cinema", "music", "workshop", "private", "guest", "lift", "artifact", "kitchen"]
const MERGEABLE_TYPES := ["common", "study", "rest", "library", "cinema", "music", "workshop", "artifact"]
const MAX_MERGE := 3
const SHARED_TYPES := ["arrival", "corridor", "common", "study", "rest", "library", "cinema", "music", "workshop", "lift", "artifact", "kitchen"]
const INITIAL_SEED_CELLS := {
	"-5:0":"arrival","-4:0":"corridor","-3:0":"study",
	"-2:0":"common","-1:0":"common","0:0":"common",
	"1:0":"rest","2:0":"library","3:0":"music","4:0":"cinema","5:0":"lift",
	"5:1":"lift","4:1":"corridor","3:1":"private","2:1":"private","1:1":"rest",
	"5:-1":"lift","4:-1":"corridor","3:-1":"private","2:-1":"private","1:-1":"artifact"
}

var rooms: Array = []
var residents: Dictionary = {}
# Non-humanoid ambient actors are persisted separately from resident/guest life.
var creatures: Dictionary = {}
# Bounded causal House journal. This is world evidence, not UI presentation text.
var journal: Array = []
# Runtime compatibility state for scheduler/event strangler. Presentation never owns this.
var runtime_state: Dictionary = {}
var media: Dictionary = {"books": [], "films": [], "tracks": []}
# Persistent physical-object identities. Registration is explicit; seed_world does not
# invent owner artifacts merely because the lifecycle exists.
var objects: Dictionary = {}
var object_events = ObjectEventRuntime.new()
var object_events_initialized := false
var object_events_save_path := ""
var next_room_id := 1

func _ensure_object_events() -> bool:
	if object_events_initialized and object_events_save_path == save_path:
		return bool(object_events.ready)
	object_events_initialized = true
	object_events_save_path = save_path
	return object_events.setup(self)

func submit_object_event(event: Dictionary) -> Dictionary:
	if not _ensure_object_events():
		return {"ok":false,"error":str(object_events.last_error)}
	return object_events.submit(event)

func object_event_storage_paths() -> Array:
	if not object_events_initialized or object_events_save_path != save_path:
		object_events_save_path = save_path
	return [
		save_path+".world_events_v1.json",
		save_path+".world_events_v1.json.bak",
		save_path+".world_events_v1.json.tmp",
		save_path+".world_events_v1.json.corrupt"
	]

func object_event_revision() -> int:
	return int(runtime_state.get("object_event_revision",0))

func object_event_history(object_id: String, limit: int = 64) -> Array:
	if not _ensure_object_events():
		return []
	return object_events.events_for_object(object_id,limit)

func explain_physical_object(object_id: String) -> Dictionary:
	if not _ensure_object_events():
		return {}
	return object_events.explain_object(object_id)

func cell_key(x: int, level: int) -> String:
	return "%d:%d" % [x, level]

func get_room(x: int, level: int) -> Dictionary:
	for room in rooms:
		if room_space.covers_cell(room,x,level):
			return room
	return {}

func room_by_id(room_id: String) -> Dictionary:
	for room in rooms:
		if str(room["id"]) == room_id:
			return room
	return {}

func world_pos(x: int, level: int) -> Vector3:
	return Vector3(float(x) * MODULE_W, float(level) * FLOOR_H, 0.0)

func room_center_pos(room: Dictionary) -> Vector3:
	return room_space.center_world(room)

func room_local_to_world(room: Dictionary, local: Vector2) -> Vector3:
	return room_space.local_to_world(room,local)

func room_world_to_local(room: Dictionary, position: Vector3) -> Vector2:
	return room_space.world_to_local(room,position)

func room_contains_local(room: Dictionary, local: Vector2, margin: float = 0.0) -> bool:
	return room_space.local_contains(room,local,margin)

func room_size_modules(room: Dictionary) -> int:
	return room_space.size_modules(room)

func connection_between(a: Dictionary, b: Dictionary) -> Dictionary:
	return room_space.connection_between(a,b)

func make_room(x: int, level: int, room_type: String,
		size_modules: int = 1, immutable_topology: bool = false) -> Dictionary:
	var modules: int = int(room_space.normalize_size(size_modules))
	if room_type=="lift":
		modules=1
	var room: Dictionary = {
		"id": "ROOM_%04d" % next_room_id,
		"x": x,
		"level": level,
		"type": room_type,
		"size_modules":modules,
		"size_id":room_space.size_id(modules),
		"topology_version":2,
		"immutable_topology":immutable_topology,
		"topology_origin":"seed" if immutable_topology else "runtime_add",
		"privacy": "door_only" if room_type == "private" else "public",
		"owner_id": "",
		"public_frontage": room_type in ["private","guest"],
		"guest_access_state": "open" if room_type == "guest" else "",
		"display_name": "Гостевая" if room_type == "guest" else "",
	}
	room["connectors"]=room_space.default_connectors(room_type,modules)
	next_room_id += 1
	rooms.append(room)
	return room

func can_build_room(x: int, level: int, room_type: String, size_modules: int = 1) -> bool:
	if not ROOM_TYPES.has(room_type):
		return false
	var modules:=room_space.normalize_size(size_modules)
	if room_type=="lift" and modules!=1:
		return false
	if abs(x) > 28 or abs(level) > 5 or abs(x+modules-1)>28:
		return false
	for occupied_x in range(x,x+modules):
		if not get_room(occupied_x,level).is_empty():
			return false
	var candidate:Dictionary={
		"id":"__CANDIDATE__","x":x,"level":level,"type":room_type,
		"size_modules":modules,"privacy":"public",
		"public_frontage":room_type in ["private","guest"]
	}
	candidate["connectors"]=room_space.default_connectors(room_type,modules)
	if rooms.is_empty():
		return true
	for existing in rooms:
		if not connection_between(candidate,existing).is_empty() and allows_transit(existing):
			return true
	return false

func can_build(x: int, level: int, room_type: String) -> bool:
	return can_build_room(x,level,room_type,1)

func build_room(x: int, level: int, room_type: String, size_modules: int = 1) -> bool:
	if not can_build_room(x,level,room_type,size_modules):
		return false
	make_room(x,level,room_type,size_modules,false)
	save_world()
	return true

func build(x: int, level: int, room_type: String) -> bool:
	return build_room(x,level,room_type,1)

func can_reconfigure_room(room_id: String) -> bool:
	var room: Dictionary = room_by_id(room_id)
	return not room.is_empty() and not bool(room.get("immutable_topology",false))

func can_remove_room(room_id: String) -> bool:
	return can_reconfigure_room(room_id)

func is_accessible(room: Dictionary, actor_id: String = "") -> bool:
	if room.is_empty():
		return false
	if str(room.get("type","")) == "guest" and str(room.get("guest_access_state","open")) == "closed":
		return actor_id != "" and str(room.get("owner_id","")) == actor_id
	if room.get("privacy", "public") != "public":
		return actor_id != "" and room.get("owner_id", "") == actor_id
	return true

func public_cutaway_allowed(room: Dictionary) -> bool:
	if room.is_empty() or str(room.get("privacy","public")) != "public":
		return false
	if str(room.get("type","")) == "guest" and str(room.get("guest_access_state","open")) == "closed":
		return false
	return true

func configure_guest_room(room_id: String, guest_id: String,
		display_name: String = "") -> bool:
	var room: Dictionary = room_by_id(room_id)
	var guest: Dictionary = residents.get(guest_id,{})
	if room.is_empty() or str(room.get("type","")) != "guest":
		return false
	if guest.is_empty() or str(guest.get("entity_type","")) != "guest":
		return false
	room["owner_id"] = guest_id
	room["guest_access_state"] = "open"
	room["display_name"] = display_name if display_name != "" else (
		"Гостевая · " + str(guest.get("name",guest_id)))
	guest["home_room_id"] = room_id
	_append_journal("GUEST_ROOM_ASSIGNED",guest_id,room_id,"",room_id,
		{"display_name":str(room["display_name"])})
	return true

func set_guest_room_open(room_id: String, open: bool) -> bool:
	var room: Dictionary = room_by_id(room_id)
	if room.is_empty() or str(room.get("type","")) != "guest" or str(room.get("owner_id","")) == "":
		return false
	var previous := str(room.get("guest_access_state","open"))
	var next := "open" if open else "closed"
	if previous == next:
		return true
	room["guest_access_state"] = next
	_append_journal("GUEST_ROOM_ACCESS_CHANGED",str(room.get("owner_id","")),room_id,
		previous,next,{"public_cutaway":open})
	return true

func guest_room_for(guest_id: String) -> Dictionary:
	for room in rooms:
		if str(room.get("type","")) == "guest" and str(room.get("owner_id","")) == guest_id:
			return room
	return {}

func allows_transit(room: Dictionary) -> bool:
	# The publicly visible walking aisle is IN FRONT of a private door.
	# Walking past a room is not permission to enter its interior.
	if room.is_empty():
		return false
	return room.get("privacy", "public") == "public" or bool(room.get("public_frontage", false))

func neighbors(room: Dictionary, actor_id: String = "") -> Array:
	var out: Array = []
	for candidate in rooms:
		if str(candidate.get("id",""))==str(room.get("id","")):
			continue
		if connection_between(room,candidate).is_empty():
			continue
		if allows_transit(candidate) or is_accessible(candidate,actor_id):
			out.append(candidate)
	return out

# A short-lived geometry index keeps direct room mutation and save/reload safe.
# No privacy or ownership is cached. Ordering matches the original rooms array.
func route_geometry_index()->Dictionary:
	var cells:Dictionary={}
	var by_id:Dictionary={}
	var order:Dictionary={}
	for i in range(rooms.size()):
		var room:Dictionary=rooms[i]
		var rid:String=str(room["id"])
		by_id[rid]=room
		order[rid]=i
		for x in range(int(room["x"]),room_space.x_end(room)+1):
			cells[Vector2i(x,int(room["level"]))]=room
	return {"cells":cells,"by_id":by_id,"order":order}

func indexed_geometry_neighbors(room:Dictionary,index:Dictionary)->Array:
	var x:int=int(room["x"])
	var level:int=int(room["level"])
	var probes:Array=[Vector2i(x-1,level),Vector2i(room_space.x_end(room)+1,level)]
	if str(room["type"])=="lift":
		probes.append(Vector2i(x,level-1))
		probes.append(Vector2i(x,level+1))
	var result:Array=[]
	var ids:Dictionary={}
	var cells:Dictionary=index["cells"]
	var order:Dictionary=index["order"]
	for cell in probes:
		var candidate:Dictionary=cells.get(cell,{})
		if candidate.is_empty():continue
		var rid:String=str(candidate["id"])
		if ids.has(rid) or connection_between(room,candidate).is_empty():continue
		ids[rid]=true
		result.append(candidate)
	result.sort_custom(func(a,b):return int(order[str(a["id"])])<int(order[str(b["id"])]))
	return result

func find_route(start_id: String, destination_id: String, actor_id: String = "") -> Array:
	var index:Dictionary=route_geometry_index() if canonical_house_seed else {}
	var start: Dictionary = index["by_id"].get(start_id,{}) if canonical_house_seed else room_by_id(start_id)
	var target: Dictionary = index["by_id"].get(destination_id,{}) if canonical_house_seed else room_by_id(destination_id)
	if start.is_empty() or target.is_empty() or not is_accessible(target, actor_id):
		return []
	if start_id == destination_id:
		return [start_id]
	var seen: Dictionary = {start_id: true}
	var previous: Dictionary = {}
	var queue: Array = [start]
	var q_index := 0
	while q_index < queue.size():
		var current: Dictionary = queue[q_index]
		q_index += 1
		var adjacent:Array=indexed_geometry_neighbors(current,index) if canonical_house_seed else neighbors(current,actor_id)
		for next_room in adjacent:
			if canonical_house_seed and not allows_transit(next_room) and not is_accessible(next_room,actor_id):continue
			var key: String = next_room["id"]
			if seen.has(key):
				continue
			seen[key] = true
			previous[key] = current["id"]
			if key == destination_id:
				var path: Array = [destination_id]
				var cursor: String = destination_id
				while cursor != start_id:
					cursor = previous[cursor]
					path.push_front(cursor)
				return path
			queue.append(next_room)
	return []

func matching_rooms(types: Array, actor_id: String = "") -> Array:
	var out: Array = []
	for room in rooms:
		if types.has(room["type"]) and is_accessible(room, actor_id):
			out.append(room)
	return out

func merged_run_length(x: int, level: int) -> int:
	var room:=get_room(x,level)
	return 0 if room.is_empty() else room_size_modules(room)

func merged_group(x: int, level: int) -> Dictionary:
	var room:Dictionary=get_room(x,level)
	if room.is_empty():
		return {}
	var first:=int(room["x"])
	var width:=room_size_modules(room)
	return {
		"type":str(room["type"]),"level":int(room["level"]),
		"x_start":first,"x_end":first+width-1,"width":width,
		"cells":room_space.virtual_modules(room),
		"primary_id":str(room["id"]),"room_id":str(room["id"]),
		"immutable_topology":bool(room.get("immutable_topology",false)),
		"connectors":room.get("connectors",[])
	}

func visual_groups() -> Array:
	var groups:Array=[]
	var sorted_rooms:Array=rooms.duplicate()
	sorted_rooms.sort_custom(func(a,b):
		if int(a["level"])!=int(b["level"]):
			return int(a["level"])<int(b["level"])
		return int(a["x"])<int(b["x"]))
	for room in sorted_rooms:
		groups.append(merged_group(int(room["x"]),int(room["level"])))
	return groups

func _append_journal(event_name: String, actor_id: String = "", subject_id: String = "",
		from_value: String = "", to_value: String = "", details: Dictionary = {}) -> void:
	journal.append({
		"event": event_name,
		"actor_id": actor_id,
		"subject_id": subject_id,
		"from": from_value,
		"to": to_value,
		"details": details.duplicate(true),
		"sim_clock": sim_clock
	})
	while journal.size() > 256:
		journal.pop_front()

func journal_entries(limit: int = 64) -> Array:
	if limit <= 0:
		return []
	var start: int = maxi(0, journal.size() - limit)
	return journal.slice(start, journal.size())

func register_physical_object(object_id: String, display_name: String,
		canonical_owner_id: String, home_room_id: String,
		movable: bool = true, recoverable: bool = true,
		ambient_pickup_allowed: bool = false, ambient_hide_allowed: bool = false,
		ambient_protected: bool = false, metadata: Dictionary = {}) -> bool:
	if not _ensure_object_events():
		return false
	return object_events.register_object(
		object_id,display_name,canonical_owner_id,home_room_id,movable,recoverable,
		ambient_pickup_allowed,ambient_hide_allowed,ambient_protected,metadata)

func physical_object(object_id: String) -> Dictionary:
	return objects.get(object_id, {})

func _physical_actor(actor_id: String) -> Dictionary:
	if residents.has(actor_id):
		return residents[actor_id]
	return creatures.get(actor_id, {})

func can_ambient_pickup_object(object_id: String) -> bool:
	var object: Dictionary = physical_object(object_id)
	if object.is_empty():
		return false
	return (str(object.get("object_class","display_object"))=="small_artifact"
		and bool(object.get("movable",false))
		and bool(object.get("ambient_pickup_allowed",false))
		and not bool(object.get("ambient_protected",false))
		and str(object.get("current_holder_id","")) == ""
		and str(object.get("current_room_id","")) != "")

func set_object_ambient_protection(object_id: String, protected: bool) -> bool:
	if not _ensure_object_events():
		return false
	return object_events.set_ambient_protection(object_id,protected)

func pickup_physical_object(object_id: String, actor_id: String) -> bool:
	if not _ensure_object_events():
		return false
	return object_events.pickup(object_id,actor_id)

func place_physical_object(object_id: String, actor_id: String,
		target_room_id: String, state: String = "PLACED",
		target_anchor: Variant = null) -> bool:
	if not _ensure_object_events():
		return false
	return object_events.place(object_id,actor_id,target_room_id,state,target_anchor)

func recover_physical_object_to_lost_found(object_id: String,
		lost_found_room_id: String) -> bool:
	if not _ensure_object_events():
		return false
	return object_events.recover_to_lost_found(object_id,lost_found_room_id)

func restore_physical_object_home(object_id: String, reset_day: int = -1) -> bool:
	if not _ensure_object_events():
		return false
	return object_events.restore_home(object_id,reset_day)

func assign_physical_object_home(object_id: String, target_room_id: String,
		home_anchor: Vector2, move_now: bool = true, support_id:String="") -> bool:
	if not _ensure_object_events():
		return false
	return object_events.assign_home(
		object_id,target_room_id,home_anchor,move_now,"LOCAL_DRAGON",support_id)

func game_day_index() -> int:
	return maxi(0,int(floor(sim_clock/GAME_DAY_SECONDS)))

func _anchors_equal(a, b) -> bool:
	if typeof(a)!=TYPE_ARRAY or typeof(b)!=TYPE_ARRAY:
		return false
	var aa:Array=a
	var bb:Array=b
	if aa.size()!=2 or bb.size()!=2:
		return false
	return absf(float(aa[0])-float(bb[0]))<0.001 and (
		absf(float(aa[1])-float(bb[1]))<0.001)

func object_is_displaced(object: Dictionary) -> bool:
	if object.is_empty() or not bool(object.get("movable",false)) or not bool(object.get("reset_eligible",true)):
		return false
	var home_room:String=str(object.get("home_room_id",""))
	if home_room=="" or room_by_id(home_room).is_empty():
		return false
	if str(object.get("current_holder_id",""))!="":
		return true
	if str(object.get("current_room_id",""))!=home_room:
		return true
	if str(object.get("state","PLACED"))!="PLACED":
		return true
	if str(object.get("current_support_id",""))!=str(object.get("home_support_id","")):
		return true
	return not _anchors_equal(
		object.get("current_anchor",[]),object.get("home_anchor",[]))

func _clear_carrier_reference(object_id: String, previous_holder: String) -> void:
	if previous_holder=="":
		return
	if creatures.has(previous_holder):
		var creature:Dictionary=creatures[previous_holder]
		if str(creature.get("carried_object_id",""))==object_id:
			creature["carried_object_id"]=""
	if residents.has(previous_holder):
		var actor:Dictionary=residents[previous_holder]
		if str(actor.get("carried_object_id",""))==object_id:
			actor["carried_object_id"]=""

func tick_object_home_reset() -> int:
	var vessel_restored:int=tick_abandoned_vessel_reset() if canonical_house_seed else 0
	var day:int=game_day_index()
	if not runtime_state.has("object_home_reset_day"):
		runtime_state["object_home_reset_day"]=day
		runtime_state["object_game_day_seconds"]=GAME_DAY_SECONDS
		return vessel_restored
	var previous_day:int=int(runtime_state.get("object_home_reset_day",day))
	if day<=previous_day:
		return vessel_restored
	var restored:=0
	var failed:=0
	var ids:Array=objects.keys()
	ids.sort()
	for raw_id in ids:
		var object_id:String=str(raw_id)
		var object:Dictionary=objects[object_id]
		if canonical_house_seed and is_drink_vessel(object):
			continue # Rolling inactivity, never the midnight sweep.
		if not object_is_displaced(object):
			continue
		var previous_holder:String=str(object.get("current_holder_id",""))
		if restore_physical_object_home(object_id,day):
			_clear_carrier_reference(object_id,previous_holder)
			restored+=1
		else:
			failed+=1
	runtime_state["object_home_reset_day"]=day
	runtime_state["object_home_reset_last_count"]=restored
	runtime_state["object_home_reset_last_failed"]=failed
	runtime_state["object_home_reset_last_clock"]=sim_clock
	runtime_state["object_game_day_seconds"]=GAME_DAY_SECONDS
	if restored>0 or failed>0:
		_append_journal("OBJECT_HOME_DAILY_SWEEP","HOUSE_SPIRIT","",
			str(previous_day),str(day),{"restored":restored,"failed":failed})
	return restored+vessel_restored

func register_creature(creature_id: String, display_name: String,
		room_id: String, bank_id: String = "", owner_id: String = "",
		can_pickup: bool = false, can_hide: bool = false, guest: bool = false) -> bool:
	if creature_id == "" or display_name == "" or creatures.has(creature_id) or residents.has(creature_id):
		return false
	var room: Dictionary = room_by_id(room_id)
	if room.is_empty() or str(room.get("privacy","public")) != "public":
		return false
	creatures[creature_id] = {
		"id":creature_id, "name":display_name, "active":true,
		"entity_type":"creature", "guest":guest, "owner_id":owner_id,
		"bank_id":bank_id, "room_id":room_id,
		"x":room_center_pos(room).x, "level":int(room["level"]), "z":0.25,
		"can_pickup_objects":can_pickup, "can_hide_objects":can_hide,
		"carried_object_id":"", "next_decision_at":sim_clock
	}
	_append_journal("CREATURE_REGISTERED", creature_id, creature_id, "", room_id,
		{"display_name":display_name,"owner_id":owner_id,"guest":guest})
	return true

func creature_display_label(creature_id: String) -> String:
	var creature: Dictionary = creatures.get(creature_id,{})
	if creature.is_empty():
		return ""
	var label := str(creature.get("name",creature_id))
	var owner_id := str(creature.get("owner_id",""))
	if owner_id == "" or not residents.has(owner_id):
		return label
	var owner_name := str(residents[owner_id].get("name",""))
	if owner_name == "":
		return label
	return "%s · хозяйка %s" % [label,owner_name]

func register_guest_actor(actor_id: String, display_name: String,
		room_id: String, species: String = "", bank_id: String = "") -> bool:
	if actor_id == "" or display_name == "" or residents.has(actor_id) or creatures.has(actor_id):
		return false
	var room: Dictionary = room_by_id(room_id)
	if room.is_empty() or str(room.get("privacy","public")) != "public":
		return false
	residents[actor_id] = {
		"id":actor_id, "name":display_name, "active":true,
		"entity_type":"guest", "guest":true, "species":species, "bank_id":bank_id,
		"room_id":room_id, "home_room_id":room_id,
		"x":room_center_pos(room).x, "level":int(room["level"]), "z":0.15,
		"intent":"REST", "phase":"idle", "until":0.0,
		"needs":{"rest":0.4,"social":0.35,"curiosity":0.55},
		"traits":{"reading":0.35,"music":0.35},
		"habits":{}, "last_location":"", "route":[], "path_index":0,
		"production_visual_ready":false, "visual_status":"CANDIDATE"
	}
	_append_journal("GUEST_REGISTERED", actor_id, actor_id, "", room_id,
		{"display_name":display_name,"species":species,"bank_id":bank_id})
	if str(room.get("type","")) == "guest":
		configure_guest_room(room_id,actor_id)
	return true

func merge_reference_book_metadata(items: Array) -> int:
	# The documented cloud catalog is NOT a shelf inventory. No copy may be borrowed.
	var existing: Dictionary = {}
	for entry in media.get("books", []):
		existing[str(entry.get("id", ""))] = true
	var added := 0
	for item in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var id: String = str(item.get("id", ""))
		var title: String = str(item.get("title", ""))
		if id == "" or title == "" or existing.has(id) or str(item.get("status", "")) != "METADATA_ONLY":
			continue
		var byline = item.get("author", "")
		media["books"].append({
			"id": id, "title": title, "author": "" if byline == null else str(byline),
			"catalog_only": true, "physical": false,
			"provenance": str(item.get("source", "")),
			"preview": "", "holder_id": "", "location_room_id": "",
			"idle_since": 0, "progress_by_actor": {}
		})
		existing[id] = true
		added += 1
	if added > 0:
		save_world()
	return added

func read_resident_profiles() -> Array:
	var f := FileAccess.open("res://data/resident_profiles.json", FileAccess.READ)
	if f == null:
		return []
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var roster = parsed.get("residents", [])
	return roster if typeof(roster) == TYPE_ARRAY else []

func sync_resident_profiles() -> void:
	for profile in read_resident_profiles():
		var id: String = str(profile.get("id", ""))
		if residents.has(id):
			var actor: Dictionary = residents[id]
			actor["name"] = str(profile.get("display_name", actor.get("name", "")))
			actor["appearance_profile"] = str(profile.get("appearance_profile", ""))
			if not actor.has("production_visual_ready"):
				actor["production_visual_ready"] = false # asset validation is separate

func seed_world() -> void:
	rooms.clear()
	residents.clear()
	creatures.clear()
	journal.clear()
	runtime_state.clear()
	object_events_initialized = false
	object_events_save_path = ""
	next_room_id = 1
	sim_clock = 0.0
	# Physical seed topology. These rooms are immutable after creation:
	# runtime may add rooms, but it must never merge, resize, move or rebuild seed rooms.
	if canonical_house_seed:
		CanonicalHouseSeed.build(self)
		CanonicalHouseSeed.apply_social_purposes(self)
	else:
		for record in [
			[-5,0,"arrival",1],[-4,0,"corridor",1],[-3,0,"study",1],
			[-2,0,"common",3],
			[1,0,"rest",1],[2,0,"library",1],[3,0,"music",1],
			[4,0,"cinema",1],[5,0,"lift",1],
			[5,1,"lift",1],[4,1,"corridor",1],[3,1,"private",1],
			[2,1,"private",1],[1,1,"rest",1],
			[5,-1,"lift",1],[4,-1,"corridor",1],[3,-1,"private",1],
			[2,-1,"private",1],[1,-1,"artifact",1]
		]:
			make_room(record[0],record[1],record[2],record[3],true)
	# All 24 canonical names/profile IDs come from 2026-11-12 approved map.
	# Only the original eight QA silhouettes are active pending actual sprite banks.
	var profiles: Array = read_resident_profiles()
	var public_start_rooms: Array = matching_rooms(["common","rest","library","study","music","cinema","workshop","artifact"]) if canonical_house_seed else []
	for i in range(profiles.size()):
		var profile: Dictionary = profiles[i]
		var id: String = profile["id"]
		if i < 8:
			var r: Dictionary = public_start_rooms[i % public_start_rooms.size()] if canonical_house_seed else get_room(-3 + i, 0)
			if r.is_empty() or not is_accessible(r):
				r = get_room(1, 0)
			residents[id] = {
				"id": id, "name": profile["display_name"], "active": true,
				"room_id": r["id"], "x": room_center_pos(r).x,
				"level": int(r["level"]), "z": 0.15,
				"intent": "REST", "phase": "idle", "until": 0.0,
				"needs": {"rest": 0.5, "social": 0.4, "curiosity": 0.5},
				"traits": {"reading": 0.45 + float(i % 3) * 0.15,
					"music": 0.2 + float(i % 4) * 0.12},
				"habits": {}, "last_location": "", "route": [], "path_index": 0,
				"appearance_profile": profile["appearance_profile"],
				"production_visual_ready": false, "visual_status": "QA_ONLY"
			}
		else:
			residents[id] = {
				"id": id, "name": profile["display_name"], "active": false,
				"room_id": "", "appearance_profile": profile["appearance_profile"],
				"production_visual_ready": false,
				"visual_status": "ASSET_GATED"
			}
	if canonical_house_seed:
		CanonicalHouseSeed.assign_homes(self,profiles)
	# Manka is not a generic human resident.
	var manka_room:Dictionary=get_room(-3,1) if canonical_house_seed else get_room(0,0)
	residents["MANJKA"] = {"id": "MANJKA", "name": "Манька", "active": true,
		"room_id": manka_room["id"], "x": room_center_pos(manka_room).x if canonical_house_seed else 0.0, "level": int(manka_room["level"]), "z": 0.7,
		"intent": "EXPLORE", "phase": "idle", "until": 0.0,
		"needs": {"rest": 0.4, "social": 0.15, "curiosity": 0.9},
		"traits": {"reading": 0.0, "music": 0.0}, "habits": {}, "last_location": "",
		"route": [], "path_index": 0}
	media = {"books": [], "films": [], "tracks": []}
	objects = {}
	creatures = {}
	journal = []
	runtime_state = {"architecture_revision":CanonicalHouseSeed.REVISION} if canonical_house_seed else {}

func _initial_seed_cell(room: Dictionary) -> bool:
	var key: String = cell_key(int(room.get("x",0)),int(room.get("level",0)))
	return INITIAL_SEED_CELLS.get(key,"")==str(room.get("type",""))

func _remap_room_references(mapping: Dictionary) -> void:
	for collection in [residents,creatures]:
		for id in collection:
			var entity:Dictionary=collection[id]
			for key in ["room_id","home_room_id","station_room_id","route_target_room_id","route_origin_room_id"]:
				var old_id: String = str(entity.get(key,""))
				if mapping.has(old_id):
					entity[key]=mapping[old_id]
			var route:Array=entity.get("route",[])
			var remapped:Array=[]
			for old_id in route:
				var next_id: String = str(mapping.get(str(old_id),str(old_id)))
				if remapped.is_empty() or str(remapped[-1])!=next_id:
					remapped.append(next_id)
			if not route.is_empty():
				entity["route"]=remapped
			for point in entity.get("waypoints",[]):
				if typeof(point)==TYPE_DICTIONARY:
					var point_room: String = str(point.get("room_id",""))
					if mapping.has(point_room):
						point["room_id"]=mapping[point_room]
	for object_id in objects:
		var object:Dictionary=objects[object_id]
		for key in ["current_room_id","home_room_id","canonical_home_room_id","location_room_id"]:
			var old_id: String = str(object.get(key,""))
			if mapping.has(old_id):
				object[key]=mapping[old_id]
	for category in media:
		for item in media.get(category,[]):
			if typeof(item)==TYPE_DICTIONARY:
				var old_id: String = str(item.get("location_room_id",""))
				if mapping.has(old_id):
					item["location_room_id"]=mapping[old_id]

func _migrate_legacy_topology() -> bool:
	var needs_migration: bool = false
	for room in rooms:
		if int(room.get("topology_version",0))<2:
			needs_migration=true
			break
	if not needs_migration:
		for room in rooms:
			room_space.ensure_room_shape(room)
		return false
	var source:Array=rooms.duplicate(true)
	source.sort_custom(func(a,b):
		if int(a["level"])!=int(b["level"]):
			return int(a["level"])<int(b["level"])
		return int(a["x"])<int(b["x"]))
	var visited:Dictionary={}
	var mapping:Dictionary={}
	var migrated:Array=[]
	for legacy in source:
		var legacy_id: String = str(legacy.get("id",""))
		if visited.has(legacy_id):
			continue
		var run:Array=[legacy]
		visited[legacy_id]=true
		if MERGEABLE_TYPES.has(str(legacy.get("type",""))):
			var next_x: int = int(legacy.get("x",0))+1
			var legacy_is_seed: bool = _initial_seed_cell(legacy)
			while run.size()<3:
				var found:Dictionary={}
				for candidate in source:
					if visited.has(str(candidate.get("id",""))):
						continue
					if int(candidate.get("level",0))==int(legacy.get("level",0)) and (
							int(candidate.get("x",0))==next_x) and (
							str(candidate.get("type",""))==str(legacy.get("type",""))) and (
							_initial_seed_cell(candidate)==legacy_is_seed):
						found=candidate
						break
				if found.is_empty():
					break
				run.append(found)
				visited[str(found["id"])]=true
				next_x+=1
		var physical:Dictionary=run[0].duplicate(true)
		var immutable: bool = true
		for member in run:
			if not _initial_seed_cell(member):
				immutable=false
				break
		physical["size_modules"]=run.size()
		physical["size_id"]=room_space.size_id(run.size())
		physical["topology_version"]=2
		physical["immutable_topology"]=immutable
		physical["topology_origin"]="seed_migration" if immutable else "legacy_migration"
		physical["connectors"]=room_space.default_connectors(str(physical.get("type","")),run.size())
		for member in run:
			mapping[str(member.get("id",""))]=str(physical.get("id",""))
		migrated.append(physical)
	rooms=migrated
	_remap_room_references(mapping)
	return true

func _read_snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var parsed = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	if int(parsed.get("schema",0)) not in [1,2] or typeof(parsed.get("rooms",null)) != TYPE_ARRAY:
		return {}
	if typeof(parsed.get("residents",null)) != TYPE_DICTIONARY:
		return {}
	return parsed

func load_or_seed() -> void:
	var parsed: Dictionary = _read_snapshot(save_path)
	if parsed.is_empty():
		parsed = _read_snapshot(save_path + ".bak")
	if parsed.is_empty():
		seed_world()
		_ensure_object_events()
		save_world()
		return
	rooms.assign(parsed["rooms"])
	var social_changed:bool=CanonicalHouseSeed.apply_social_purposes(self) if canonical_house_seed else false
	residents = parsed["residents"]
	media = parsed.get("media", {"books": [], "films": [], "tracks": []})
	objects = parsed.get("objects", {})
	creatures = parsed.get("creatures", {})
	journal = parsed.get("journal", [])
	runtime_state = parsed.get("runtime_state", {})
	next_room_id = int(parsed.get("next_room_id", rooms.size() + 1))
	sim_clock = float(parsed.get("sim_clock", 0.0))
	for saved_room in rooms:
		if saved_room.get("type", "") == "private" and not saved_room.has("public_frontage"):
			saved_room["public_frontage"] = true
		if saved_room.get("type","") == "guest":
			if not saved_room.has("public_frontage"):
				saved_room["public_frontage"] = true
			if not saved_room.has("guest_access_state"):
				saved_room["guest_access_state"] = "open"
			if not saved_room.has("display_name"):
				saved_room["display_name"] = "Гостевая"
	var migrated: bool = _migrate_legacy_topology()
	sync_resident_profiles()
	object_events_initialized = false
	object_events_save_path = ""
	_ensure_object_events()
	if migrated or social_changed:
		save_world()

func save_world() -> bool:
	var scratch: String = save_path + ".tmp"
	var backup: String = save_path + ".bak"
	var data: Dictionary = {"schema": 2,"rooms": rooms,"residents": residents,
		"creatures":creatures,"journal":journal,"runtime_state":runtime_state,"media": media,"objects": objects,
		"next_room_id": next_room_id,"sim_clock": sim_clock}
	var file := FileAccess.open(scratch,FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data,"\t"))
	file.flush()
	file.close()
	# Verify before touching the last readable snapshot.
	if _read_snapshot(scratch).is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch))
		return false
	var absolute_save := ProjectSettings.globalize_path(save_path)
	var absolute_tmp := ProjectSettings.globalize_path(scratch)
	var absolute_backup := ProjectSettings.globalize_path(backup)
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(absolute_backup)
	if FileAccess.file_exists(save_path):
		if DirAccess.rename_absolute(absolute_save,absolute_backup) != OK:
			return false
	if DirAccess.rename_absolute(absolute_tmp,absolute_save) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(absolute_backup,absolute_save)
		return false
	return true

func import_catalog(path: String) -> bool:
	# Explicit import of verified manifest, preserving physical book truth.
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		return false
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return false
	var parsed: Dictionary = parser.data
	var imported: Dictionary = {}
	for category in ["books","films","tracks"]:
		var items = parsed.get(category,parsed.get("audio",[]) if category == "tracks" else [])
		if typeof(items) != TYPE_ARRAY:
			return false
		var unique: Dictionary = {}
		for item in items:
			if typeof(item) != TYPE_DICTIONARY or not item.has("id") or not item.has("title"):
				return false
			var id: String = str(item["id"])
			if id == "" or unique.has(id):
				return false
			unique[id] = true
		imported[category] = items
	# Import is additive. An unrelated category or omitted item must not erase a
	# physical volume, its holder, reading progress, or the existing catalogue.
	var merged:Dictionary=media.duplicate(true)
	for category in ["books","films","tracks"]:
		var records:Array=merged.get(category,[])
		var indices:Dictionary={}
		for idx in range(records.size()):
			indices[str(records[idx].get("id",""))]=idx
		for incoming in imported[category]:
			var id:String=str(incoming["id"])
			if not indices.has(id):
				records.append(incoming.duplicate(true))
				indices[id]=records.size()-1
				continue
			var index:int=int(indices[id])
			var old:Dictionary=records[index]
			var updated:Dictionary=old.duplicate(true)
			updated.merge(incoming,true)
			if category=="books":
				for field in ["holder_id","location_room_id","idle_since","progress_by_actor","owner_id","borrowed_at","home_room_id"]:
					if old.has(field):
						updated[field]=old[field]
				if bool(old.get("physical",true)):
					updated["physical"]=true
					updated["catalog_only"]=false
			records[index]=updated
		merged[category]=records
	var previous:Dictionary=media
	media=merged
	if save_world():
		return true
	media=previous
	return false

# All portable drinkware retains the existing cups viewer category, so old
# mug identities and pickup rules survive. Bar display sets are not vessels.
func is_drink_vessel(object:Dictionary)->bool:
	return str(object.get("viewer_category",""))=="cups"

func _vessel_last_activity(object:Dictionary)->float:
	var last:float=-1.0
	for entry in object.get("history",[]):
		if str(entry.get("event","")) in ["REGISTERED","PICKED_UP","PLACED","STASHED","RESTORED_HOME","HOME_ASSIGNED","RECOVERED_TO_LOST_FOUND"]:
			last=maxf(last,float(entry.get("sim_clock",0.0)))
	var observed:Dictionary=runtime_state.get("drink_vessel_last_use",{})
	last=maxf(last,float(observed.get(str(object.get("id","")),-1.0)))
	# A migrated object with no valid activity timestamp is not immediately
	# treated as ancient; its observed clock starts in this save.
	if last<0.0:
		observed[str(object["id"])]=sim_clock
		runtime_state["drink_vessel_last_use"]=observed
		return sim_clock
	return minf(last,sim_clock)

# Hook for successful sip/use events. Ownership and position are untouched.
# Current pickup/place events already supply replayable activity timestamps.
func note_drink_vessel_use(object_id:String,actor_id:String)->bool:
	var object:Dictionary=physical_object(object_id)
	if not is_drink_vessel(object) or str(object.get("current_holder_id",""))!=actor_id or actor_id=="":return false
	var actor:Dictionary=_physical_actor(actor_id)
	if actor.is_empty() or not bool(actor.get("active",false)):return false
	var observed:Dictionary=runtime_state.get("drink_vessel_last_use",{})
	observed[object_id]=sim_clock
	runtime_state["drink_vessel_last_use"]=observed
	return true

func tick_abandoned_vessel_reset()->int:
	# One scan per simulated second, not one per frame. No wall clock or
	# midnight reset; an unattended placement gets its own full day.
	if vessel_reset_scan_at>=0.0 and sim_clock>=vessel_reset_scan_at and sim_clock-vessel_reset_scan_at<1.0:return 0
	vessel_reset_scan_at=sim_clock
	var reserved:Dictionary={}
	for actor in residents.values():
		if bool(actor.get("active",false)) and bool(actor.get("autonomy_enabled",true)) and str(actor.get("phase","")) in ["travel","perform"] and str(actor.get("cup_task_stage",""))=="fetch":
			reserved[str(actor.get("cup_task_id",""))]=true
	var count:=0
	var ids:Array=objects.keys()
	ids.sort()
	for raw_id in ids:
		var id:String=str(raw_id)
		var object:Dictionary=objects[id]
		if not is_drink_vessel(object) or not object_is_displaced(object):continue
		if str(object.get("current_holder_id",""))!="":continue
		if reserved.has(id):continue
		var last:float=_vessel_last_activity(object)
		if sim_clock-last<DRINK_VESSEL_IDLE_SECONDS:continue
		if restore_physical_object_home(id):
			_append_journal("DRINK_VESSEL_IDLE_RETURN","HOUSE_SPIRIT",id,"",str(object.get("home_room_id","")),{"idle_seconds":sim_clock-last})
			count+=1
	return count
