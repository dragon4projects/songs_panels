extends RefCounted
const InteractionAnchors = preload("res://scripts/interaction_anchor_registry.gd")
const CandidateGuestStations = preload("res://scripts/candidate_guest_station_registry.gd")
## Explicit, deterministic local station reservations. No AI/external dependency.
## Reservations live on actor state so save/load can reconstruct occupancy.
## PRIVATE rooms are never public station pools.
const CAPACITY_BY_TYPE := {
	"common": 10, "library": 4, "rest": 5, "study": 4,
	"workshop": 4, "cinema": 8, "music": 6, "artifact": 6,
	"arrival": 4, "corridor": 2, "private": 1, "lift": 0
}
const FLOOR_X_LIMIT := 2.05
const BACK_Z := -0.70
const FRONT_Z := 0.51
var furniture = InteractionAnchors.new()
var candidate_guest_stations = CandidateGuestStations.new()

func _init() -> void:
	if not furniture.initialize():
		push_warning("Interaction anchor manifest unavailable: "+furniture.last_error)
	if not candidate_guest_stations.initialize():
		push_warning("Candidate guest station manifest unavailable: "
			+candidate_guest_stations.last_error)

func capacity(room: Dictionary) -> int:
	if room.is_empty():
		return 0
	if str(room.get("type","")) == "guest":
		var guest_capacity := candidate_guest_stations.capacity_for(
			str(room.get("id","")))
		if guest_capacity > 0:
			return guest_capacity
	return int(CAPACITY_BY_TYPE.get(str(room.get("type","")),2))

func _spot(x: float, z: float, kind: String = "standing", object_id: String = "") -> Dictionary:
	return {"offset":Vector2(x,z),"kind":kind,"furniture_id":object_id}

func _layout_from_anchors(room: Dictionary, anchors: Array) -> Array:
	# The physical furniture anchors are data, never inferred from a painted
	# backdrop. Art-agent proposals do not automatically change simulation.
	var count: int=capacity(room)
	var positions: Array=[]
	for item in anchors:
		positions.append({
			"id":str(item["id"]),
			"offset":Vector2(float(item["x"]),float(item["z"])),
			"kind":str(item["kind"]),
			"furniture_id":str(item.get("furniture_id","")),
			"pose_hint":str(item.get("pose_hint","IDLE_S")),
			"approach_z":float(item.get("approach_z",0.95))
		})
	if positions.size()>count:
		push_error("Furniture spots exceed room capacity, ignoring duplicates")
		positions.resize(count)
	# The remainder is physically present for standing and social gatherings.
	# These aren't furniture seats and cannot trigger a seated sprite.
	var candidates: Array=[]
	var idx:=0
	for z in [1.24,0.27,-1.30]:
		var shift := 0.0 if z == 1.24 else 0.30 if z == 0.27 else -0.18
		for x in [-1.75,-0.87,0.0,0.87,1.75]:
			var xx: float=clampf(float(x)+shift,-1.87,1.87)
			candidates.append({
				"id":"stand_%02d" % idx,
				"offset":Vector2(xx,float(z)),
				"kind":"standing",
				"furniture_id":"",
				"pose_hint":"IDLE_S",
				"approach_z":0.95
			})
			idx+=1
	for place in candidates:
		if positions.size()>=count:
			break
		var pos: Vector2=place["offset"]
		var conflict:=false
		for existing in positions:
			var old: Vector2=existing["offset"]
			if pos.distance_to(old)<0.73:
				conflict=true
				break
		if not conflict:
			positions.append(place)
	assert(positions.size()==count,"A room must have distinct physical stations")
	for place in positions:
		assert(absf(float(place["offset"].x))<FLOOR_X_LIMIT)
	return positions

func layout(room: Dictionary) -> Array:
	# Private/door-only rooms have no public interaction layout at all.
	# Do not let the generic fallback generator manufacture a standing slot.
	if room.is_empty() or str(room.get("privacy","public"))!="public":
		return []
	if str(room.get("type","")) == "guest" and candidate_guest_stations.has_room(
			str(room.get("id",""))):
		return _layout_from_anchors(room,candidate_guest_stations.stations_for(
			str(room.get("id",""))))
	# Context-free fallback used by legacy migration/tests. Width-specific art
	# requires layout_for_world(), because a room dictionary alone cannot know
	# whether its logical cell is currently part of R1, R2 or R3.
	return _layout_from_anchors(room,furniture.for_room(room))

func layout_for_world(world, room: Dictionary) -> Array:
	if room.is_empty() or str(room.get("privacy","public"))!="public":
		return []
	if str(room.get("type","")) == "guest" and candidate_guest_stations.has_room(
			str(room.get("id",""))):
		return _layout_from_anchors(room,candidate_guest_stations.stations_for(
			str(room.get("id",""))))
	var group:Dictionary=world.merged_group(int(room.get("x",0)),int(room.get("level",0)))
	if group.is_empty():
		return layout(room)
	var module_index:=-1
	for i in range(group.get("cells",[]).size()):
		if str(group["cells"][i].get("id",""))==str(room.get("id","")):
			module_index=i
			break
	var anchors:Array=furniture.for_room_variant(room,int(group.get("width",1)),module_index)
	return _layout_from_anchors(room,anchors)

func _intent_prefers_station(intent: String, kind: String) -> bool:
	match intent:
		"REST","SLEEP":
			return kind in ["seat","floor_rest"]
		"READ_BOOK":
			return kind in ["seat","work"]
		"WORK_CREATE","BROWSE_BOOK_CATALOG":
			return kind=="work"
		"WATCH_FILM":
			return kind=="seat"
		"TALK_PAIR":
			return kind=="seat"
		_:
			return kind=="standing"

func _spot_allowed_for_actor(actor: Dictionary, intent: String,
		spot: Dictionary) -> bool:
	if actor.is_empty():
		return true
	var kind := str(spot.get("kind","standing"))
	var human_seat_allowed := bool(actor.get("human_seat_allowed",true))
	if not human_seat_allowed and kind == "seat":
		return false
	if not human_seat_allowed and intent in ["REST","SLEEP"]:
		return kind == "floor_rest"
	if not human_seat_allowed and intent == "READ_BOOK":
		return kind in ["work","floor_rest"]
	return true

func used_slots(world, room_id: String, ignore_ids: Array = []) -> Dictionary:
	var used: Dictionary = {}
	for id in world.residents:
		if ignore_ids.has(id):
			continue
		var actor: Dictionary = world.residents[id]
		if not bool(actor.get("active",false)):
			continue
		if str(actor.get("station_room_id","")) == room_id:
			var slot := int(actor.get("station_slot",-1))
			if slot >= 0 and str(actor.get("phase","idle")) in ["travel","perform"]:
				used[slot] = id
	return used

func available_count(world, room: Dictionary) -> int:
	if room.is_empty() or room.get("privacy","public") != "public":
		return 0
	return maxi(0,capacity(room)-used_slots(world,str(room["id"])).size())

func _claim(room: Dictionary, index: int, spot: Dictionary) -> Dictionary:
	return {"room_id":str(room["id"]),"slot":index,
		"offset":spot["offset"],"kind":str(spot.get("kind","standing")),
		"furniture_id":str(spot.get("furniture_id","")),
		"anchor_id":str(spot.get("id","")),
		"pose_hint":str(spot.get("pose_hint","IDLE_S")),
		"approach_z":float(spot.get("approach_z",0.95))}

func single(world, actor: Dictionary, room: Dictionary, intent: String = "") -> Dictionary:
	var id: String = str(actor.get("id",""))
	if room.is_empty() or room.get("privacy","public") != "public" or not world.is_accessible(room,id) or capacity(room)==0:
		return {}
	var used: Dictionary = used_slots(world,str(room["id"]),[id])
	var points: Array = layout_for_world(world,room)
	# If the actor is continuing a reservation, keep its exact location.
	var prior := int(actor.get("station_slot",-1))
	if (str(actor.get("station_room_id","")) == room["id"]
			and prior >= 0 and prior < points.size() and not used.has(prior)
			and _spot_allowed_for_actor(actor,intent,points[prior])):
		return _claim(room,prior,points[prior])
	# Deterministic id rotation distributes arrivals across the room.
	var start: int = 0
	for ch in id:
		start = posmod(start*31+ch.unicode_at(0),997)
	# Prefer a real seat/work surface. When full, side-space is safer than
	# putting a standing person's sprite directly in front of two seated
	# people, even if its (x,z) coordinates are technically unique.
	var resting: bool=intent in ["REST","SLEEP","READ_BOOK","WATCH_FILM"]
	for pass_id in range(3):
		if pass_id==1 and not resting:
			continue
		var prefer_functional: bool=pass_id==0
		var prefer_side: bool=pass_id==1
		for step in range(points.size()):
			var idx: int=(start+step)%points.size()
			if used.has(idx):
				continue
			var spot: Dictionary=points[idx]
			if not _spot_allowed_for_actor(actor,intent,spot):
				continue
			var matches: bool=_intent_prefers_station(intent,str(spot.get("kind","standing")))
			if matches!=prefer_functional:
				continue
			if prefer_side and absf(float(spot["offset"].x))<1.45:
				continue
			return _claim(room,idx,spot)
	return {}

func _paired_spots(points: Array, used: Dictionary, seats_only: bool = false) -> Array:
	for left in range(points.size()-1):
		if used.has(left):
			continue
		for right in range(left+1,points.size()):
			if used.has(right):
				continue
			var a: Dictionary=points[left]
			var b: Dictionary=points[right]
			if seats_only and (a.get("kind","")!="seat" or b.get("kind","")!="seat"):
				continue
			var one: Vector2=a["offset"]
			var two: Vector2=b["offset"]
			if absf(one.y-two.y)>0.04:
				continue
			var dx:float=absf(one.x-two.x)
			if dx>=0.72 and dx<=1.35:
				return [left,right]
	return []

func _paired_spots_for_actors(points: Array, used: Dictionary,
		actor: Dictionary, partner: Dictionary, seats_only: bool = false) -> Array:
	for left in range(points.size()-1):
		if used.has(left):
			continue
		for right in range(left+1,points.size()):
			if used.has(right):
				continue
			var a: Dictionary = points[left]
			var b: Dictionary = points[right]
			if seats_only and (str(a.get("kind","")) != "seat"
					or str(b.get("kind","")) != "seat"):
				continue
			var one: Vector2 = a["offset"]
			var two: Vector2 = b["offset"]
			if absf(one.y-two.y) > 0.04:
				continue
			var dx := absf(one.x-two.x)
			if dx < 0.72 or dx > 1.35:
				continue
			if (_spot_allowed_for_actor(actor,"TALK_PAIR",a)
					and _spot_allowed_for_actor(partner,"TALK_PAIR",b)):
				return [left,right]
			if (_spot_allowed_for_actor(actor,"TALK_PAIR",b)
					and _spot_allowed_for_actor(partner,"TALK_PAIR",a)):
				return [right,left]
	return []

func pair(world, actor: Dictionary, partner: Dictionary, room: Dictionary) -> Dictionary:
	if room.is_empty() or room.get("privacy","public") != "public" or not world.is_accessible(room,str(actor.get("id",""))) or not world.is_accessible(room,str(partner.get("id",""))):
		return {}
	var used: Dictionary=used_slots(world,str(room["id"]),[str(actor["id"]),str(partner["id"])])
	var points: Array=layout_for_world(world,room)
	var indexes: Array=_paired_spots_for_actors(
		points,used,actor,partner,true)
	if indexes.is_empty():
		indexes=_paired_spots_for_actors(
			points,used,actor,partner,false)
	if indexes.size()!=2:
		return {}
	return {"actor":_claim(room,int(indexes[0]),points[int(indexes[0])]),
		"partner":_claim(room,int(indexes[1]),points[int(indexes[1])])}

func can_reserve(world, room: Dictionary, pair_needed: bool = false,
		actor: Dictionary = {}) -> bool:
	if available_count(world,room)<(2 if pair_needed else 1):
		return false
	var points := layout_for_world(world,room)
	var used := used_slots(world,str(room["id"]),[
		str(actor.get("id",""))] if not actor.is_empty() else [])
	var allowed_free := 0
	for idx in range(points.size()):
		if used.has(idx):
			continue
		if _spot_allowed_for_actor(actor,
				"TALK_PAIR" if pair_needed else "",points[idx]):
			allowed_free += 1
	if allowed_free < 1:
		return false
	if not pair_needed:
		return true
	# Partner is not selected yet. Require a physical pair and at least one side
	# that this actor may occupy; the final actor/partner orientation is checked
	# again by pair().
	for left in range(points.size()-1):
		if used.has(left):
			continue
		for right in range(left+1,points.size()):
			if used.has(right):
				continue
			var a: Dictionary = points[left]
			var b: Dictionary = points[right]
			var one: Vector2 = a["offset"]
			var two: Vector2 = b["offset"]
			var dx := absf(one.x-two.x)
			if absf(one.y-two.y) <= 0.04 and dx >= 0.72 and dx <= 1.35:
				if (_spot_allowed_for_actor(actor,"TALK_PAIR",a)
						or _spot_allowed_for_actor(actor,"TALK_PAIR",b)):
					return true
	return false

func commit_claim(actor: Dictionary, claim: Dictionary) -> void:
	if claim.is_empty():
		return
	actor["station_room_id"] = claim["room_id"]
	actor["station_slot"] = claim["slot"]
	var offset: Vector2 = claim["offset"]
	actor["station_point"] = [offset.x,offset.y]
	actor["station_kind"] = str(claim.get("kind","standing"))
	actor["station_furniture_id"] = str(claim.get("furniture_id",""))
	actor["station_anchor_id"] = str(claim.get("anchor_id",""))
	actor["station_pose_hint"] = str(claim.get("pose_hint","IDLE_S"))
	actor["station_approach_z"] = float(claim.get("approach_z",0.95))

func release(actor: Dictionary) -> void:
	actor.erase("station_room_id")
	actor.erase("station_slot")
	actor.erase("station_point")
	actor.erase("station_kind")
	actor.erase("station_furniture_id")
	actor.erase("station_anchor_id")
	actor.erase("station_pose_hint")
	actor.erase("station_approach_z")

func reconcile(world) -> int:
	# Restore station invariants after loading a snapshot, without new life.
	# Prefer the lexicographically first existing claim if an old save has
	# duplicates; later actors replan normally instead of overlapping.
	var claimed: Dictionary = {}
	var fixed := 0
	var ordered: Array = world.residents.keys()
	ordered.sort()
	for id in ordered:
		var actor: Dictionary = world.residents[id]
		var room_id: String = str(actor.get("station_room_id",""))
		var slot: int = int(actor.get("station_slot",-1))
		if room_id == "" and slot == -1:
			continue
		var room: Dictionary = world.room_by_id(room_id)
		var authored: Array = layout_for_world(world,room) if not room.is_empty() else []
		var stable_id: String=str(actor.get("station_anchor_id",""))
		if stable_id!="":
			slot = -1
			for index in range(authored.size()):
				if str(authored[index].get("id",""))==stable_id:
					slot=index
					break
			if slot>=0:
				actor["station_slot"]=slot
		var key: String = "%s:%d" % [room_id,slot]
		var invalid: bool = not bool(actor.get("active",false)) or room.is_empty() or (
			not world.is_accessible(room,str(id))) or slot < 0 or slot >= capacity(room) or (
			not ["travel","perform"].has(str(actor.get("phase","idle")))) or claimed.has(key)
		if (not invalid and slot < authored.size()
				and not _spot_allowed_for_actor(
					actor,str(actor.get("intent","")),authored[slot])):
			invalid = true
		if not invalid and str(actor.get("phase",""))=="travel":
			var route: Array=actor.get("waypoints",[])
			invalid = route.is_empty() or typeof(route[-1])!=TYPE_DICTIONARY or (
				str(route[-1].get("kind",""))!="station") or (
				str(route[-1].get("room_id",""))!=room_id)
		if invalid:
			release(actor)
			# Old/corrupt reservations cannot continue a phantom activity
			# while another resident legitimately claims their former seat.
			actor["phase"] = "idle"
			actor["waypoints"] = []
			actor["waypoint_index"] = 0
			actor["until"] = world.sim_clock
			fixed += 1
		else:
			claimed[key] = true
			# v0.7 stored generic coordinates and the SAME slot IDs. Rewrite
			# the actor's true body location/terminal waypoint, not just the
			# station metadata, or old saves still visually stack on furniture.
			var spot: Dictionary = authored[slot]
			actor["station_kind"] = str(spot.get("kind","standing"))
			actor["station_furniture_id"] = str(spot.get("furniture_id",""))
			actor["station_anchor_id"] = str(spot.get("id",""))
			actor["station_pose_hint"] = str(spot.get("pose_hint","IDLE_S"))
			actor["station_approach_z"] = float(spot.get("approach_z",0.95))
			var offset: Vector2 = spot["offset"]
			actor["station_point"] = [offset.x,offset.y]
			var new_x:float=float(room["x"])*world.MODULE_W+offset.x
			var new_y:float=float(room["level"])*world.FLOOR_H
			if str(actor.get("phase",""))=="perform":
				actor["x"]=new_x
				actor["visual_y"]=new_y
				actor["z"]=offset.y
			else:
				var route: Array=actor["waypoints"]
				var last: Dictionary=route[-1]
				last["position"]=[new_x,new_y,offset.y]
				route[route.size()-1]=last
				actor["waypoints"]=route
	return fixed

func migrate_legacy_positions(world) -> int:
	# v0.6 and older snapshots have positions and paths but no reserved seats.
	# Reconcile immediately at load, before the first render, rather than
	# waiting for the next autonomous task and showing stacked actors for 40s.
	var changed := 0
	var sorted_ids: Array = world.residents.keys()
	sorted_ids.sort()
	for id in sorted_ids:
		var actor: Dictionary=world.residents[id]
		if not bool(actor.get("active",false)) or actor.has("station_slot"):
			continue
		var phase: String=str(actor.get("phase","idle"))
		if not phase in ["travel","perform"]:
			continue
		var room: Dictionary={}
		var waypoint: Dictionary={}
		if phase=="travel":
			var route: Array=actor.get("waypoints",[])
			if route.is_empty() or typeof(route[-1])!=TYPE_DICTIONARY:
				continue
			waypoint = route[-1]
			if str(waypoint.get("kind",""))!="station":
				continue
			room=world.room_by_id(str(waypoint.get("room_id","")))
		else:
			room=world.room_by_id(str(actor.get("room_id","")))
		if room.is_empty() or room.get("privacy","public")!="public":
			continue
		var claim: Dictionary=single(world,actor,room,str(actor.get("intent","")))
		if claim.is_empty():
			# An overfilled legacy room has no vacant station. Pause/replan,
			# rather than leaving two people at the same destination.
			actor["phase"]="idle"
			actor["until"]=world.sim_clock
			actor["waypoints"]=[]
			actor["waypoint_index"]=0
			changed+=1
			continue
		commit_claim(actor,claim)
		var offset: Vector2=claim["offset"]
		if phase=="travel":
			var points: Array=actor["waypoints"]
			var last: Dictionary=points[-1]
			last["position"]=[float(room["x"])*world.MODULE_W+offset.x,
				float(room["level"])*world.FLOOR_H,offset.y]
			points[points.size()-1]=last
			actor["waypoints"]=points
		else:
			actor["x"]=float(room["x"])*world.MODULE_W+offset.x
			actor["z"]=offset.y
			actor["visual_y"]=float(room["level"])*world.FLOOR_H
		changed+=1
	return changed
