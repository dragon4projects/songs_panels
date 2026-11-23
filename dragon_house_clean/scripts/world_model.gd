extends RefCounted
## One authoritative local simulation state. No chat/LLM interfaces.
const SAVE_PATH := "user://dragon_house_world_v01.json"
const ObjectEventRuntime = preload("res://scripts/object_event_runtime.gd")
var save_path: String = SAVE_PATH
var sim_clock: float = 0.0
const MODULE_W := 4.8
const FLOOR_H := 4.6
const ROOM_TYPES := ["arrival", "corridor", "common", "study", "rest", "library", "cinema", "music", "workshop", "private", "guest", "lift", "artifact"]
const MERGEABLE_TYPES := ["common", "study", "rest", "library", "cinema", "music", "workshop", "artifact"]
const MAX_MERGE := 3
const SHARED_TYPES := ["arrival", "corridor", "common", "study", "rest", "library", "cinema", "music", "workshop", "lift", "artifact"]

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
		if int(room["x"]) == x and int(room["level"]) == level:
			return room
	return {}

func room_by_id(room_id: String) -> Dictionary:
	for room in rooms:
		if str(room["id"]) == room_id:
			return room
	return {}

func world_pos(x: int, level: int) -> Vector3:
	return Vector3(float(x) * MODULE_W, float(level) * FLOOR_H, 0.0)

func _new_room_record(room_id: String, x: int, level: int,
		room_type: String) -> Dictionary:
	return {
		"id": room_id,
		"x": x,
		"level": level,
		"type": room_type,
		"privacy": "door_only" if room_type == "private" else "public",
		"owner_id": "",
		"public_frontage": room_type in ["private","guest"],
		"guest_access_state": "open" if room_type == "guest" else "",
		"display_name": "Гостевая" if room_type == "guest" else "",
	}

func make_room(x: int, level: int, room_type: String) -> Dictionary:
	var room_id := "ROOM_%04d" % next_room_id
	next_room_id += 1
	var room := _new_room_record(room_id,x,level,room_type)
	rooms.append(room)
	return room

func make_room_with_id(room_id: String, x: int, level: int,
		room_type: String) -> Dictionary:
	# Named IDs are required for imported/canonical room contracts. This API
	# never replaces an existing room and never silently aliases a coordinate.
	if room_id.strip_edges() == "" or not ROOM_TYPES.has(room_type):
		return {}
	if not room_by_id(room_id).is_empty() or not get_room(x,level).is_empty():
		return {}
	var room := _new_room_record(room_id,x,level,room_type)
	rooms.append(room)
	# Keep generated ROOM_#### IDs collision-safe if a migration ever asks for
	# an explicit legacy-style ROOM_ ID.
	if room_id.begins_with("ROOM_"):
		var suffix := room_id.trim_prefix("ROOM_")
		if suffix.is_valid_int():
			next_room_id = maxi(next_room_id,int(suffix)+1)
	return room

func build_named(room_id: String, x: int, level: int,
		room_type: String) -> bool:
	if not room_by_id(room_id).is_empty() or not can_build(x,level,room_type):
		return false
	if make_room_with_id(room_id,x,level,room_type).is_empty():
		return false
	save_world()
	return true

func _left_right_run(x: int, level: int, room_type: String) -> int:
	var count := 1
	var xx := x - 1
	while get_room(xx, level).get("type", "") == room_type:
		count += 1
		xx -= 1
	xx = x + 1
	while get_room(xx, level).get("type", "") == room_type:
		count += 1
		xx += 1
	return count

func can_build(x: int, level: int, room_type: String) -> bool:
	if not ROOM_TYPES.has(room_type) or not get_room(x, level).is_empty():
		return false
	if abs(x) > 28 or abs(level) > 5:
		return false
	if MERGEABLE_TYPES.has(room_type) and _left_right_run(x, level, room_type) > MAX_MERGE:
		return false
	if rooms.is_empty():
		return true
	for dx in [-1, 1]:
		var adjacent: Dictionary = get_room(x + dx, level)
		if allows_transit(adjacent):
			return true
	# Shaft can grow vertically, without opening a hole in an unrelated ceiling.
	if room_type == "lift":
		return get_room(x, level - 1).get("type", "") == "lift" or get_room(x, level + 1).get("type", "") == "lift"
	return false

func build(x: int, level: int, room_type: String) -> bool:
	if not can_build(x, level, room_type):
		return false
	make_room(x, level, room_type)
	save_world()
	return true

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
	var x: int = int(room["x"])
	var level: int = int(room["level"])
	for dx in [-1, 1]:
		var candidate: Dictionary = get_room(x + dx, level)
		if allows_transit(candidate) or is_accessible(candidate, actor_id):
			out.append(candidate)
	if room["type"] == "lift":
		for dy in [-1, 1]:
			var candidate: Dictionary = get_room(x, level + dy)
			if candidate.get("type", "") == "lift":
				out.append(candidate)
	return out

func find_route(start_id: String, destination_id: String, actor_id: String = "") -> Array:
	var start: Dictionary = room_by_id(start_id)
	var target: Dictionary = room_by_id(destination_id)
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
		for next_room in neighbors(current, actor_id):
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
	var original: Dictionary = get_room(x, level)
	if original.is_empty():
		return 0
	if not MERGEABLE_TYPES.has(original["type"]):
		return 1
	return _left_right_run(x, level, original["type"])

func merged_group(x: int, level: int) -> Dictionary:
	var anchor: Dictionary = get_room(x, level)
	if anchor.is_empty():
		return {}
	var t: String = anchor["type"]
	var first := x
	if MERGEABLE_TYPES.has(t):
		while get_room(first - 1, level).get("type", "none") == t:
			first -= 1
	var cells: Array = []
	var ix := first
	while get_room(ix, level).get("type", "none") == t:
		cells.append(get_room(ix, level))
		ix += 1
		if not MERGEABLE_TYPES.has(t):
			break
	return {"type": t, "level": level, "x_start": first,
		"x_end": ix - 1, "width": cells.size(), "cells": cells,
		"primary_id": cells[0]["id"]}

func visual_groups() -> Array:
	# Authored width variants R1/R2/R3 have ONE shared cutaway shell,
	# while all logical cell IDs remain stable for paths and persistence.
	var groups: Array = []
	var sorted_rooms: Array = rooms.duplicate()
	sorted_rooms.sort_custom(func(a, b):
		if int(a["level"]) != int(b["level"]):
			return int(a["level"]) < int(b["level"])
		return int(a["x"]) < int(b["x"]))
	var visited: Dictionary = {}
	for room in sorted_rooms:
		if visited.has(room["id"]):
			continue
		var group: Dictionary = merged_group(int(room["x"]), int(room["level"]))
		if group.is_empty():
			continue
		for cell in group["cells"]:
			visited[cell["id"]] = true
		groups.append(group)
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
	return (bool(object.get("movable",false))
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
		target_room_id: String, state: String = "PLACED") -> bool:
	if not _ensure_object_events():
		return false
	return object_events.place(object_id,actor_id,target_room_id,state)

func recover_physical_object_to_lost_found(object_id: String,
		lost_found_room_id: String) -> bool:
	if not _ensure_object_events():
		return false
	return object_events.recover_to_lost_found(object_id,lost_found_room_id)

func restore_physical_object_home(object_id: String) -> bool:
	if not _ensure_object_events():
		return false
	return object_events.restore_home(object_id)

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
		"x":float(room["x"]) * MODULE_W, "level":int(room["level"]), "z":0.25,
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
		"x":float(room["x"]) * MODULE_W, "level":int(room["level"]), "z":0.15,
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
	# CORE, a working lift shaft, two residential terraces, genuine cutaway depth.
	for record in [
		[-5, 0, "arrival"], [-4, 0, "corridor"], [-3, 0, "study"],
		[-2, 0, "common"], [-1, 0, "common"], [0, 0, "common"],
		[1, 0, "rest"], [2, 0, "library"], [3, 0, "music"],
		[4, 0, "cinema"], [5, 0, "lift"],
		[5, 1, "lift"], [4, 1, "corridor"], [3, 1, "private"],
		[2, 1, "private"], [1, 1, "rest"],
		[5, -1, "lift"], [4, -1, "corridor"], [3, -1, "private"],
		[2, -1, "private"], [1, -1, "artifact"]
	]:
		make_room(record[0], record[1], record[2])
	# All 24 canonical names/profile IDs come from 2026-11-12 approved map.
	# Only the original eight QA silhouettes are active pending actual sprite banks.
	var profiles: Array = read_resident_profiles()
	for i in range(profiles.size()):
		var profile: Dictionary = profiles[i]
		var id: String = profile["id"]
		if i < 8:
			var r: Dictionary = get_room(-3 + i, 0)
			if r.is_empty() or not is_accessible(r):
				r = get_room(1, 0)
			residents[id] = {
				"id": id, "name": profile["display_name"], "active": true,
				"room_id": r["id"], "x": float(r["x"]) * MODULE_W,
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
	# Manka is not a generic human resident.
	residents["MANJKA"] = {"id": "MANJKA", "name": "Манька", "active": true,
		"room_id": get_room(0, 0)["id"], "x": 0.0, "level": 0, "z": 0.7,
		"intent": "EXPLORE", "phase": "idle", "until": 0.0,
		"needs": {"rest": 0.4, "social": 0.15, "curiosity": 0.9},
		"traits": {"reading": 0.0, "music": 0.0}, "habits": {}, "last_location": "",
		"route": [], "path_index": 0}
	media = {"books": [], "films": [], "tracks": []}
	objects = {}
	creatures = {}
	journal = []
	runtime_state = {}

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
	if int(parsed.get("schema",0)) != 1 or typeof(parsed.get("rooms",null)) != TYPE_ARRAY:
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
	residents = parsed["residents"]
	sync_resident_profiles()
	media = parsed.get("media", {"books": [], "films": [], "tracks": []})
	objects = parsed.get("objects", {})
	creatures = parsed.get("creatures", {})
	journal = parsed.get("journal", [])
	runtime_state = parsed.get("runtime_state", {})
	next_room_id = int(parsed.get("next_room_id", rooms.size() + 1))
	sim_clock = float(parsed.get("sim_clock", 0.0))
	object_events_initialized = false
	object_events_save_path = ""
	_ensure_object_events()

func save_world() -> bool:
	var scratch: String = save_path + ".tmp"
	var backup: String = save_path + ".bak"
	var data: Dictionary = {"schema": 1,"rooms": rooms,"residents": residents,
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
	var previous_books: Dictionary = {}
	for book in media.get("books",[]):
		previous_books[str(book["id"])] = book
	for item in imported["books"]:
		var old: Dictionary = previous_books.get(str(item["id"]),{})
		if not old.is_empty():
			for field in ["holder_id","location_room_id","idle_since","progress_by_actor",
				"owner_id","borrowed_at"]:
				if old.has(field):
					item[field] = old[field]
	media = imported
	return save_world()
