extends RefCounted
## QA-only adapter for Teea schema-2 furniture anchors.
## It never writes accepted gameplay data. It validates a candidate and
## installs temporary per-cell overrides into the already-loaded registry.

const PATH := "res://data/asset_proposals/TEEA_INT_20261122_002_furniture_anchors_candidate.json"
const EXPECTED_BATCH := "TEEA_INT_20261122_002"
const ALLOWED_KINDS := ["seat","work","floor_rest","standing"]
const ALLOWED_POSES := ["IDLE_S","RELAXED_SIT","READ","USE","VIEW","TALK","DRINK","SLEEP"]
const EXPECTED_VARIANTS := ["common/R3","library/R2","study/R1","rest/R1"]

var doc: Dictionary = {}
var last_error := ""
var report: Dictionary = {}
var footprints_by_variant: Dictionary = {}
var foreground_z_by_variant: Dictionary = {}

func initialize(path: String = PATH) -> bool:
	last_error = ""
	report = {}
	footprints_by_variant = {}
	foreground_z_by_variant = {}
	var raw := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "schema-2 candidate is not a JSON object"
		return false
	doc = parsed
	if int(doc.get("schema",0)) != 2:
		last_error = "schema must be 2"
		return false
	if str(doc.get("batch_id","")) != EXPECTED_BATCH:
		last_error = "wrong batch id"
		return false
	if bool(doc.get("approved",true)):
		last_error = "candidate unexpectedly approved"
		return false
	if absf(float(doc.get("module_width",0.0))-4.8)>0.0001:
		last_error = "module width mismatch"
		return false
	if str(doc.get("coordinate_space","")) != "godot_group_modules":
		last_error = "unsupported coordinate space"
		return false
	var calibration: Dictionary=doc.get("calibration",{})
	if absf(float(calibration.get("godot_backwall_z",0.0))+2.04)>0.001 or (
		absf(float(calibration.get("godot_public_aisle_z",0.0))-0.95)>0.001):
		last_error = "calibration does not match current room shell"
		return false
	var variants: Dictionary=doc.get("room_variants",{})
	for key in EXPECTED_VARIANTS:
		if not variants.has(key):
			last_error = "missing room variant "+key
			return false
	return true

func _find_group(world, room_type: String, width: int) -> Dictionary:
	var seen: Dictionary={}
	for room in world.rooms:
		if str(room.get("type","")) != room_type:
			continue
		var group: Dictionary=world.merged_group(int(room["x"]),int(room["level"]))
		if group.is_empty():
			continue
		var id: String=str(group.get("primary_id",""))
		if seen.has(id):
			continue
		seen[id]=true
		if int(group.get("width",0))==width:
			return group
	return {}

func _variant_parts(key: String) -> Array:
	var parts:=key.split("/")
	if parts.size()!=2 or not str(parts[1]).begins_with("R"):
		return []
	var width_str: String=str(parts[1]).trim_prefix("R")
	if not width_str.is_valid_int():
		return []
	return [str(parts[0]),int(width_str)]

func _polygon_bounds(raw: Variant) -> Dictionary:
	if typeof(raw)!=TYPE_ARRAY or raw.size()<3:
		return {}
	var min_x:=INF
	var max_x:=-INF
	var min_z:=INF
	var max_z:=-INF
	for pt in raw:
		if typeof(pt)!=TYPE_ARRAY or pt.size()!=2:
			return {}
		var x:=float(pt[0])
		var z:=float(pt[1])
		if is_nan(x) or is_inf(x) or is_nan(z) or is_inf(z):
			return {}
		min_x=minf(min_x,x); max_x=maxf(max_x,x)
		min_z=minf(min_z,z); max_z=maxf(max_z,z)
	return {"min_x":min_x,"max_x":max_x,"min_z":min_z,"max_z":max_z}

func _segment_hits_other_furniture(station: Dictionary, obstacles: Array) -> String:
	var x: float=float(station["group_local_x"])
	var z0: float=float(station["cell_local_z"])
	var z1: float=float(station["approach_local_z"])
	var low:=minf(z0,z1)
	var high:=maxf(z0,z1)
	var target: String=str(station.get("furniture_id",""))
	for obstacle in obstacles:
		if str(obstacle.get("furniture_id",""))==target:
			continue
		var b: Dictionary=obstacle.get("bounds",{})
		if b.is_empty():
			continue
		# 8 cm safety margin around furniture silhouettes.
		if x < float(b["min_x"])-0.08 or x > float(b["max_x"])+0.08:
			continue
		if high < float(b["min_z"])-0.08 or low > float(b["max_z"])+0.08:
			continue
		return str(obstacle.get("furniture_id","unknown"))
	return ""

func validate_and_apply(world, registry) -> Dictionary:
	if doc.is_empty() and not initialize():
		return {"valid":false,"error":last_error}
	var legal:=0
	var blocked:=0
	var errors: Array=[]
	var candidate_ids: Dictionary={}
	var overrides: Dictionary={}
	var station_records_by_variant: Dictionary={}
	var obstacle_records_by_variant: Dictionary={}
	var variants: Dictionary=doc["room_variants"]

	# First validate geometry and build all collision footprints.
	for key in EXPECTED_VARIANTS:
		var parts:=_variant_parts(key)
		var room_type: String=parts[0]
		var width: int=parts[1]
		var group: Dictionary=_find_group(world,room_type,width)
		if group.is_empty():
			errors.append("No current QA group for "+key)
			continue
		var cell_keys: Array=[]
		for x in range(int(group["x_start"]),int(group["x_end"])+1):
			var k:=room_type+":"+str(x)
			overrides[k]=[]
			cell_keys.append(k)
		var payload: Dictionary=variants[key]
		var obstacles: Array=[]
		var records: Array=[]
		for raw_station in payload.get("stations",[]):
			if typeof(raw_station)!=TYPE_DICTIONARY:
				errors.append(key+": non-dictionary station")
				continue
			var station: Dictionary=raw_station
			var id:=str(station.get("id",""))
			var status:=str(station.get("reservation_status",""))
			if id=="" or not id.is_valid_identifier() or candidate_ids.has(id):
				errors.append(key+": invalid/duplicate id "+id)
				continue
			candidate_ids[id]=true
			var footprint:=_polygon_bounds(station.get("collision_footprint",[]))
			if footprint.is_empty():
				errors.append(id+": invalid collision footprint")
				continue
			obstacles.append({"furniture_id":str(station.get("furniture_id","")),
				"bounds":footprint})
			if status.begins_with("BLOCKED_"):
				blocked+=1
				continue
			if status!="CANDIDATE":
				errors.append(id+": unsupported reservation status "+status)
				continue
			var module_index:=int(station.get("module_index",-1))
			var x:=float(station.get("cell_local_x",999.0))
			var z:=float(station.get("cell_local_z",999.0))
			var approach:=float(station.get("approach_local_z",999.0))
			var kind:=str(station.get("kind",""))
			var pose:=str(station.get("pose_hint",""))
			if module_index<0 or module_index>=width:
				errors.append(id+": module index out of group")
				continue
			if absf(x)>1.90:
				errors.append(id+": local x outside +/-1.90")
				continue
			if z < -2.04 or z > 0.95 or approach < z or approach > 1.35:
				errors.append(id+": z/approach outside calibrated shell")
				continue
			if not ALLOWED_KINDS.has(kind) or not ALLOWED_POSES.has(pose):
				errors.append(id+": kind/pose rejected")
				continue
			var expected_group_x: float=(float(module_index)-float(width-1)*0.5)*4.8+x
			if absf(expected_group_x-float(station.get("group_local_x",999.0)))>0.02:
				errors.append(id+": group/cell X conversion mismatch")
				continue
			records.append(station.duplicate(true))
		for raw_item in payload.get("non_station_furniture",[]):
			if typeof(raw_item)!=TYPE_DICTIONARY:
				errors.append(key+": invalid nonstation furniture")
				continue
			var item: Dictionary=raw_item
			var bounds:=_polygon_bounds(item.get("collision_footprint",[]))
			if bounds.is_empty():
				errors.append(key+": bad collision footprint "+str(item.get("furniture_id","")))
				continue
			obstacles.append({"furniture_id":str(item.get("furniture_id","")),
				"bounds":bounds})
		station_records_by_variant[key]={"group":group,"records":records}
		obstacle_records_by_variant[key]=obstacles
		footprints_by_variant[key]=obstacles
		# A full-canvas foreground plate may contain several furniture pieces.
		# Use the median CAMERA-FACING edge of unique legal furniture objects
		# as its physical sort depth; screen registration is handled separately.
		var front_by_furniture:Dictionary={}
		for station in records:
			var furniture_id:String=str(station.get("furniture_id",""))
			var bounds:Dictionary=_polygon_bounds(station.get("collision_footprint",[]))
			if furniture_id!="" and not bounds.is_empty():
				front_by_furniture[furniture_id]=float(bounds["max_z"])
		if not front_by_furniture.is_empty():
			var fronts:Array=front_by_furniture.values()
			fronts.sort()
			var n:int=fronts.size()
			var median:float=float(fronts[n/2]) if n%2==1 else (
				(float(fronts[n/2-1])+float(fronts[n/2]))*0.5)
			foreground_z_by_variant[key]=median

	# Then verify approach corridors and install only legal records.
	for key in EXPECTED_VARIANTS:
		if not station_records_by_variant.has(key):
			continue
		var info: Dictionary=station_records_by_variant[key]
		var group: Dictionary=info["group"]
		var room_type: String=str(group["type"])
		var obstacles: Array=obstacle_records_by_variant.get(key,[])
		for station in info["records"]:
			var obstruction:=_segment_hits_other_furniture(station,obstacles)
			if obstruction!="":
				errors.append(str(station["id"])+": approach collides with "+obstruction)
				continue
			var world_x:=int(group["x_start"])+int(station["module_index"])
			var override_key:=room_type+":"+str(world_x)
			var converted={
				"id":str(station["id"]),
				"x":float(station["cell_local_x"]),
				"z":float(station["cell_local_z"]),
				"kind":str(station["kind"]),
				"furniture_id":str(station["furniture_id"]),
				"pose_hint":str(station["pose_hint"]),
				"approach_z":float(station["approach_local_z"])
			}
			overrides[override_key].append(converted)
			legal+=1

	if not errors.is_empty():
		last_error="; ".join(errors)
		return {"valid":false,"error":last_error,"legal":legal,"blocked":blocked,
			"errors":errors}
	# Preserve every accepted room profile outside the four pilot groups.
	# Replace ONLY the in-memory per-cell overrides in QA.
	for key in overrides:
		registry.cell_overrides[key]=overrides[key].duplicate(true)
	report={"valid":true,"approved":false,"integrated":"QA_MEMORY_ONLY",
		"legal":legal,"blocked":blocked,"errors":[],"overrides":overrides.keys(),
		"foreground_z":foreground_z_by_variant.duplicate(true)}
	return report

func legal_station_ids() -> Array:
	var ids: Array=[]
	for key in doc.get("room_variants",{}):
		for s in doc["room_variants"][key].get("stations",[]):
			if str(s.get("reservation_status",""))=="CANDIDATE":
				ids.append(str(s["id"]))
	return ids

