extends RefCounted
const DATA_PATH := "res://data/candidate_guest_stations_20261123.json"
var data: Dictionary = {}
var last_error := ""

func initialize(path: String = DATA_PATH) -> bool:
	data = {}
	last_error = ""
	if not FileAccess.file_exists(path):
		last_error = "Candidate guest station registry is absent"
		return false
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		last_error = "Candidate guest station registry is unreadable"
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("schema",0)) != 1:
		last_error = "Candidate guest station registry is malformed"
		return false
	if typeof(parsed.get("rooms",null)) != TYPE_DICTIONARY:
		last_error = "Candidate guest station registry lacks rooms"
		return false
	data = parsed
	return true

func room_entry(room_id: String) -> Dictionary:
	return data.get("rooms",{}).get(room_id,{})

func has_room(room_id: String) -> bool:
	return not room_entry(room_id).is_empty()

func guest_id_for(room_id: String) -> String:
	return str(room_entry(room_id).get("guest_id",""))

func capacity_for(room_id: String) -> int:
	var stations = room_entry(room_id).get("stations",[])
	return stations.size() if typeof(stations) == TYPE_ARRAY else 0

func stations_for(room_id: String) -> Array:
	var room := room_entry(room_id)
	var raw = room.get("stations",[])
	if typeof(raw) != TYPE_ARRAY:
		return []
	var out: Array = []
	var seen: Dictionary = {}
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var row: Dictionary = item
		var id := str(row.get("id",""))
		var kind := str(row.get("kind",""))
		if id == "" or seen.has(id) or not kind in [
			"standing","work","seat","floor_rest"]:
			continue
		seen[id] = true
		out.append({
			"id":id,
			"x":float(row.get("x",0.0)),
			"z":float(row.get("z",0.0)),
			"kind":kind,
			"furniture_id":str(row.get("furniture_id","")),
			"pose_hint":str(row.get("pose_hint","IDLE_S")),
			"approach_z":float(row.get("approach_z",0.95)),
			"activity":str(row.get("activity","")),
			"candidate_binding":true
		})
	return out

func human_seat_allowed(room_id: String) -> bool:
	return bool(room_entry(room_id).get("human_seat_allowed",true))

func station_profile(room_id: String) -> String:
	return str(room_entry(room_id).get("station_profile",""))

func turning_diameter_m(room_id: String) -> float:
	return float(room_entry(room_id).get("turning_diameter_m",0.0))
