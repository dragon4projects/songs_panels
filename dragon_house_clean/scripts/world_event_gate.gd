extends RefCounted
## Truth/permission gate for the first event-sourced mutation family: objects.
## Semantics follow 13_WORLD_TRUTH_AND_CONSENT_MODEL + old World Core, while
## enforcing current v0.18 object/creature privacy invariants centrally.

const TRUTH_CLASSES := [
	"EXPLICIT_WORLD_FACT","AMBIENT_SIMULATION","PRESENTATION_ONLY"
]
const SOURCE_TYPES := [
	"dragon","resident_owner","cloud_session","admin_manual","system",
	"ambient_simulation","renderer","migration_import"
]
const AUTHORITIES := [
	"OWNER_DECLARED","DRAGON_DECLARED","AUTHORIZED_SESSION","SYSTEM_RULE",
	"AMBIENT","PRESENTATION","HISTORICAL_IMPORT"
]
const REVERSIBILITY := [
	"PERSISTENT_UNTIL_CHANGED","TEMPORARY_UNTIL_TIME",
	"TEMPORARY_UNTIL_EVENT_END","AMBIENT_REVERTIBLE","CLEANUP_ELIGIBLE",
	"HISTORICAL_RECORD_ONLY","OWNER_CONTROLLED"
]
const OBJECT_EVENTS := [
	"OBJECT_REGISTERED","OBJECT_MOVED","OBJECT_POLICY_SET","OBJECT_OWNER_CHANGED",
	"OBJECT_HOME_ASSIGNED"
]
const MOVEMENT_KINDS := [
	"PICKED_UP","PLACED","STASHED","RECOVERED_TO_LOST_FOUND","RESTORED_HOME"
]
const OBJECT_STATES := ["PLACED","HELD","STASHED","LOST_FOUND"]

var last_error: String = ""

func reject(reason: String) -> bool:
	last_error = reason
	return false

func _required(event: Dictionary, key: String) -> bool:
	return event.has(key) and event.get(key) != null and str(event.get(key,"")) != ""

func _actor(world, actor_id: String) -> Dictionary:
	if world.residents.has(actor_id):
		return world.residents[actor_id]
	return world.creatures.get(actor_id,{})

func _ambient_actor(world, actor_id: String) -> bool:
	return actor_id == "MANJKA" or world.creatures.has(actor_id)

func _valid_location_invariant(holder: String, location: String, state: String) -> bool:
	if state == "HELD":
		return holder != "" and location == ""
	if state in ["PLACED","STASHED","LOST_FOUND"]:
		return holder == "" and location != ""
	return false

func _valid_anchor(world, room_id: String, raw) -> bool:
	if typeof(raw) != TYPE_ARRAY:
		return false
	var anchor:Array=raw
	if anchor.size()!=2 or typeof(anchor[0]) not in [TYPE_INT,TYPE_FLOAT] or (
			typeof(anchor[1]) not in [TYPE_INT,TYPE_FLOAT]):
		return false
	var room:Dictionary=world.room_by_id(room_id)
	if room.is_empty():
		return false
	return world.room_contains_local(
		room,Vector2(float(anchor[0]),float(anchor[1])),0.08)

func _validate_source_authority(event: Dictionary) -> bool:
	var source_type: String = str(event.get("source_type",""))
	var authority: String = str(event.get("authority",""))
	var truth: String = str(event.get("truth_class",""))
	match source_type:
		"renderer":
			if authority != "PRESENTATION" or truth != "PRESENTATION_ONLY":
				return reject("renderer cannot elevate truth/authority")
		"ambient_simulation":
			if authority != "AMBIENT" or truth != "AMBIENT_SIMULATION":
				return reject("ambient source cannot elevate truth/authority")
		"migration_import":
			if authority != "HISTORICAL_IMPORT" or truth != "EXPLICIT_WORLD_FACT":
				return reject("migration source must remain historical import")
		"system":
			if authority != "SYSTEM_RULE" or truth == "PRESENTATION_ONLY":
				return reject("system source requires SYSTEM_RULE durable authority")
		"dragon":
			if authority != "DRAGON_DECLARED" or truth != "EXPLICIT_WORLD_FACT":
				return reject("dragon source requires explicit Dragon authority")
		"resident_owner":
			if authority != "OWNER_DECLARED" or truth != "EXPLICIT_WORLD_FACT":
				return reject("resident owner source requires owner authority")
		"cloud_session":
			if authority != "AUTHORIZED_SESSION" or truth != "EXPLICIT_WORLD_FACT":
				return reject("cloud session requires authorized explicit authority")
		"admin_manual":
			if authority not in ["SYSTEM_RULE","DRAGON_DECLARED"] or truth != "EXPLICIT_WORLD_FACT":
				return reject("admin manual source has invalid authority")
		_:
			return reject("unhandled source_type")
	return true

func _validate_envelope(event: Dictionary) -> bool:
	for key in [
		"event_id","created_at","source_type","source_id","authority","truth_class",
		"visibility","event_type","reversibility","provenance","payload"
	]:
		if not event.has(key):
			return reject("missing field: "+key)
	if str(event.get("event_id","")).strip_edges() == "":
		return reject("event_id must not be empty")
	if typeof(event.get("created_at")) not in [TYPE_INT,TYPE_FLOAT]:
		return reject("created_at must be numeric")
	if not SOURCE_TYPES.has(str(event.get("source_type",""))):
		return reject("invalid source_type")
	if str(event.get("source_id","")).strip_edges() == "":
		return reject("source_id must not be empty")
	if not AUTHORITIES.has(str(event.get("authority",""))):
		return reject("invalid authority")
	if not TRUTH_CLASSES.has(str(event.get("truth_class",""))):
		return reject("invalid truth_class")
	if str(event.get("visibility","")).strip_edges() == "":
		return reject("visibility must not be empty")
	if not REVERSIBILITY.has(str(event.get("reversibility",""))):
		return reject("invalid reversibility")
	if str(event.get("provenance","")).strip_edges() == "":
		return reject("provenance must not be empty")
	if typeof(event.get("payload")) != TYPE_DICTIONARY:
		return reject("payload must be an object")
	if not _validate_source_authority(event):
		return false
	if not OBJECT_EVENTS.has(str(event.get("event_type",""))):
		return reject("unsupported object event_type")
	if str(event.get("truth_class","")) == "PRESENTATION_ONLY":
		return reject("PRESENTATION_ONLY cannot mutate object truth")
	return true

func validate(world, projection: Dictionary, event: Dictionary) -> bool:
	last_error = ""
	if not _validate_envelope(event):
		return false
	var event_type: String = str(event["event_type"])
	var payload: Dictionary = event["payload"]
	var truth: String = str(event["truth_class"])

	if event_type == "OBJECT_REGISTERED":
		if truth == "AMBIENT_SIMULATION":
			return reject("ambient simulation cannot register canonical objects")
		var object_id: String = str(payload.get("object_id",""))
		var home_room_id: String = str(payload.get("home_room_id",
			payload.get("current_location","")))
		if object_id == "" or projection.has(object_id):
			return reject("invalid/duplicate object registration")
		if str(payload.get("display_name","")) == "":
			return reject("registered object requires display_name")
		if world.room_by_id(home_room_id).is_empty():
			return reject("registered object requires existing home room")
		if not _valid_anchor(world,home_room_id,payload.get("home_anchor",[])):
			return reject("registered object requires valid home anchor")
		var object_class:String=str(payload.get("object_class","display_object"))
		if object_class not in ["display_object","small_artifact"]:
			return reject("registered object has invalid object_class")
		var holder: String = str(payload.get("current_holder",""))
		var location: String = str(payload.get("current_location",home_room_id))
		var state: String = str(payload.get("state","PLACED"))
		if not _valid_location_invariant(holder,location,state):
			return reject("invalid initial holder/location invariant")
		if location!="" and not _valid_anchor(
				world,location,payload.get("current_anchor",payload.get("home_anchor",[]))):
			return reject("registered object requires valid current anchor")
		return true

	var object_id: String = str(payload.get("object_id",""))
	if object_id == "" or not projection.has(object_id):
		return reject("unknown object")
	var object: Dictionary = projection[object_id]

	if event_type == "OBJECT_OWNER_CHANGED":
		if truth == "AMBIENT_SIMULATION":
			return reject("ambient simulation cannot change canonical ownership")
		if str(payload.get("canonical_owner","")) == "":
			return reject("owner change requires canonical_owner")
		return true

	if event_type == "OBJECT_POLICY_SET":
		if truth == "AMBIENT_SIMULATION":
			return reject("ambient simulation cannot change object policy")
		for field in ["ambient_pickup_allowed","ambient_hide_allowed","ambient_protected","reset_eligible"]:
			if payload.has(field) and typeof(payload[field]) != TYPE_BOOL:
				return reject("object policy field must be boolean: "+field)
		return true

	if event_type == "OBJECT_HOME_ASSIGNED":
		if truth == "AMBIENT_SIMULATION":
			return reject("ambient simulation cannot assign object home")
		var previous_home:String=str(payload.get("previous_home_room_id",""))
		if previous_home!=str(object.get("home_room_id","")):
			return reject("object home changed before assignment commit")
		var target_home:String=str(payload.get("home_room_id",""))
		if world.room_by_id(target_home).is_empty():
			return reject("assigned home room does not exist")
		if not _valid_anchor(world,target_home,payload.get("home_anchor",[])):
			return reject("assigned home anchor is outside room")
		if typeof(payload.get("move_now",true))!=TYPE_BOOL:
			return reject("home assignment move_now must be boolean")
		if bool(payload.get("move_now",true)) and str(object.get("current_holder_id",""))!="":
			return reject("cannot re-home object while held")
		return true

	# OBJECT_MOVED
	var movement_kind: String = str(payload.get("movement_kind",""))
	if not MOVEMENT_KINDS.has(movement_kind):
		return reject("invalid movement_kind")
	var previous_holder: String = str(payload.get("previous_holder",""))
	var previous_location: String = str(payload.get("previous_location",""))
	if previous_holder != str(object.get("current_holder_id","")) or (
			previous_location != str(object.get("current_room_id",""))):
		return reject("object precondition changed before event commit")
	if payload.has("canonical_owner") and str(payload["canonical_owner"]) != str(
			object.get("canonical_owner_id","")):
		return reject("movement cannot rewrite canonical ownership")
	var holder: String = str(payload.get("current_holder",""))
	var location: String = str(payload.get("current_location",""))
	var state: String = str(payload.get("state",""))
	if not OBJECT_STATES.has(state) or not _valid_location_invariant(holder,location,state):
		return reject("invalid movement holder/location/state invariant")
	var actor_id: String = str(payload.get("actor_id",event.get("subject_id","")))
	var ambient: bool = truth == "AMBIENT_SIMULATION" or _ambient_actor(world,actor_id)

	if movement_kind == "PICKED_UP":
		var actor: Dictionary = _actor(world,actor_id)
		if actor.is_empty() or not bool(actor.get("active",false)):
			return reject("pickup actor is unavailable")
		if not bool(object.get("movable",false)):
			return reject("object is not movable")
		if str(object.get("object_class","display_object"))!="small_artifact":
			return reject("only small_artifact may be picked up/carried")
		if previous_holder != "" or previous_location == "":
			return reject("pickup requires placed object")
		if previous_location != str(actor.get("room_id","")):
			return reject("pickup actor is not in object room")
		var room: Dictionary = world.room_by_id(previous_location)
		if room.is_empty() or not world.is_accessible(room,actor_id):
			return reject("pickup room is inaccessible")
		if holder != actor_id or location != "" or state != "HELD":
			return reject("pickup projection is invalid")
		if ambient:
			if not bool(object.get("ambient_pickup_allowed",false)) or (
				bool(object.get("ambient_protected",false))):
				return reject("ambient pickup not allowed for object")
			if world.creatures.has(actor_id):
				var creature: Dictionary = world.creatures[actor_id]
				if not bool(creature.get("can_pickup_objects",false)):
					return reject("creature cannot pick up objects")
		return true

	if movement_kind in ["PLACED","STASHED"]:
		if str(object.get("object_class","display_object"))!="small_artifact":
			return reject("only small_artifact may be carried/placed from a holder")
		if actor_id == "":
			return reject("placement requires actor")
		var actor: Dictionary = _actor(world,actor_id)
		if actor.is_empty() or not bool(actor.get("active",false)):
			return reject("placement actor is unavailable")
		if previous_holder != actor_id or previous_location != "":
			return reject("placement requires actor-held object")
		var target: Dictionary = world.room_by_id(location)
		if target.is_empty() or not world.is_accessible(target,actor_id):
			return reject("placement target is inaccessible")
		if holder != "" or state != movement_kind:
			return reject("placement projection is invalid")
		if not _valid_anchor(world,location,payload.get("current_anchor",[])):
			return reject("placement anchor is outside target room")
		if ambient and bool(object.get("ambient_protected",false)):
			return reject("ambient actor cannot place protected object")
		if movement_kind == "STASHED" and ambient:
			if not bool(object.get("ambient_hide_allowed",false)):
				return reject("ambient hide not allowed for object")
			if world.creatures.has(actor_id):
				var creature: Dictionary = world.creatures[actor_id]
				if not bool(creature.get("can_hide_objects",false)):
					return reject("creature cannot hide objects")
		return true

	if movement_kind == "RECOVERED_TO_LOST_FOUND":
		if actor_id != "HOUSE_SPIRIT":
			return reject("lost/found recovery belongs to house spirit")
		if not bool(object.get("recoverable",false)):
			return reject("object is not recoverable")
		if bool(object.get("ambient_protected",false)):
			return reject("house spirit cannot move protected object")
		if previous_holder != "":
			return reject("house spirit cannot take an object from a holder")
		var target: Dictionary = world.room_by_id(location)
		if target.is_empty() or str(target.get("privacy","public")) != "public":
			return reject("lost/found target must be public")
		if holder != "" or state != "LOST_FOUND":
			return reject("lost/found projection is invalid")
		if not _valid_anchor(world,location,payload.get("current_anchor",[])):
			return reject("lost/found anchor is outside target room")
		return true

	if movement_kind == "RESTORED_HOME":
		if truth == "AMBIENT_SIMULATION":
			return reject("explicit restore cannot be ambient simulation")
		var home_room_id: String = str(object.get("home_room_id",""))
		if location != home_room_id or world.room_by_id(home_room_id).is_empty():
			return reject("restore target must be canonical home")
		if holder != "" or state != "PLACED":
			return reject("restore projection is invalid")
		if not _valid_anchor(world,home_room_id,payload.get("current_anchor",[])):
			return reject("restore anchor must be valid canonical home anchor")
		var home_anchor:Array=object.get("home_anchor",[])
		if payload.get("current_anchor",[]) != home_anchor:
			return reject("restore anchor must equal canonical home anchor")
		return true

	return reject("unhandled object movement")
