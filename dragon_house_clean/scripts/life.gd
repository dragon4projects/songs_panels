extends RefCounted
const MediaRuntime = preload("res://scripts/media_runtime.gd")
const RoomLocomotion = preload("res://scripts/room_locomotion.gd")
const RoomStations = preload("res://scripts/room_stations.gd")
const AmbientCreatureRuntime = preload("res://scripts/ambient_creature_runtime.gd")
const LifeScheduler = preload("res://scripts/life_scheduler_v2.gd")
## Autonomous utility/need scheduler. No external events or AI dependency.
var world
var media_runtime = MediaRuntime.new()
var locomotion = RoomLocomotion.new()
var stations = RoomStations.new()
var creature_runtime = AmbientCreatureRuntime.new()
var life_scheduler = LifeScheduler.new()
var rng := RandomNumberGenerator.new()
var clock := 0.0
var max_jobs_per_tick := 2
var idle_retry_seconds := 8.0
var moving_ids: Dictionary = {}
var planner_calls := 0
var planner_usec_total := 0
var planner_usec_max := 0
var log: Array = []
var steps := 0
var last_cleanup_wall_time := 0

const HUMAN_STATUS := {
	"REST": "отдыхает", "SLEEP": "спит",
	"WORK_CREATE": "занимается делами", "READ_BOOK": "читает книгу",
	"BROWSE_BOOK_CATALOG": "просматривает книжный каталог",
	"BROWSE_FILMS": "выбирает фильм", "BROWSE_AUDIO": "выбирает музыку",
	"GET_COFFEE": "готовит кофе", "WATCH_FIRE": "смотрит на огонь",
	"TALK_PAIR": "разговаривает", "LISTEN_MUSIC": "слушает музыку",
	"WATCH_FILM": "смотрит фильм", "VIEW_ART": "рассматривает артефакты",
	"PURPOSEFUL_EXPLORE": "исследует Дом"
}
const TRAVEL_STATUS := {
	"REST": "идёт отдыхать", "SLEEP": "идёт спать",
	"WORK_CREATE": "идёт работать", "READ_BOOK": "идёт читать",
	"BROWSE_BOOK_CATALOG": "идёт к книжному каталогу",
	"BROWSE_FILMS": "идёт выбирать фильм", "BROWSE_AUDIO": "идёт к аудиотеке",
	"GET_COFFEE": "идёт за кофе", "WATCH_FIRE": "идёт к очагу",
	"TALK_PAIR": "идёт на встречу", "LISTEN_MUSIC": "идёт слушать музыку",
	"WATCH_FILM": "идёт смотреть фильм", "VIEW_ART": "идёт к артефактам",
	"PURPOSEFUL_EXPLORE": "гуляет по Дому"
}

func _quoted_media_title(actor: Dictionary, category_key: String,
		id_key: String) -> String:
	var category:String=str(actor.get(category_key,""))
	var item_id:String=str(actor.get(id_key,""))
	if category=="" or item_id=="":
		return ""
	var item:Dictionary=media_runtime._lookup(category,item_id)
	var title:String=str(item.get("title","")) if not item.is_empty() else ""
	if title=="":
		title=str(actor.get("activity_media_title",""))
	return ("«"+title+"»") if title!="" else ""

func status(actor: Dictionary) -> String:
	var intent: String = str(actor.get("intent","REST"))
	if actor.get("phase","idle") == "travel":
		return str(TRAVEL_STATUS.get(intent, "идёт по делу"))
	var active_title:=_quoted_media_title(
		actor,"activity_media_category","activity_media_id")
	if active_title!="":
		match intent:
			"READ_BOOK": return "читает "+active_title
			"WATCH_FILM": return "смотрит "+active_title
			"LISTEN_MUSIC": return "слушает "+active_title
	var browse_title:=_quoted_media_title(
		actor,"browsing_category","browsing_item_id")
	if browse_title!="":
		match intent:
			"BROWSE_BOOK_CATALOG": return "смотрит в каталоге "+browse_title
			"BROWSE_FILMS": return "выбирает фильм "+browse_title
			"BROWSE_AUDIO": return "выбирает музыку "+browse_title
	return str(HUMAN_STATUS.get(intent,"отдыхает"))

const INTENTS := {
	"REST": ["rest", "private", "guest"], "SLEEP": ["rest", "private", "guest"],
	"WORK_CREATE": ["study", "workshop"], "READ_BOOK": ["library", "rest"],
	"BROWSE_BOOK_CATALOG": ["library"],
	"BROWSE_FILMS": ["cinema"], "BROWSE_AUDIO": ["music"],
	"GET_COFFEE": ["common"], "WATCH_FIRE": ["common"],
	"TALK_PAIR": ["common", "rest"], "LISTEN_MUSIC": ["music"],
	"WATCH_FILM": ["cinema"], "VIEW_ART": ["artifact"],
	"PURPOSEFUL_EXPLORE": ["arrival", "corridor", "study", "library", "artifact", "rest"]
}

func setup(p_world) -> void:
	world = p_world
	media_runtime.setup(world)
	creature_runtime.setup(world)
	rng.seed = 814223
	clock = world.sim_clock
	stations.reconcile(world)
	stations.migrate_legacy_positions(world)
	reconcile_concrete_media()
	var now: int = int(Time.get_unix_time_from_system())
	media_runtime.cleanup_abandoned(now)
	last_cleanup_wall_time = now
	moving_ids.clear()
	var active_ids: Array = []
	for id in world.residents:
		var actor: Dictionary = world.residents[id]
		if not bool(actor.get("active",false)) or not bool(actor.get("autonomy_enabled",true)):
			continue
		active_ids.append(str(id))
		if str(actor.get("phase","idle")) == "travel":
			moving_ids[str(id)] = true
	active_ids.sort()
	var saved_scheduler: Dictionary = world.runtime_state.get("life_scheduler",{})
	life_scheduler.restore(saved_scheduler,active_ids,clock,idle_retry_seconds,3.0)
	# Existing pre-scheduler saves retain their commitments. First wake only
	# reconciles/schedules them; it does not cancel an unexpired action.
	world.runtime_state["life_scheduler"] = life_scheduler.snapshot()

func daypart() -> String:
	var hour: int = Time.get_datetime_dict_from_system().get("hour", 12)
	if hour < 6:
		return "night"
	if hour < 11:
		return "morning"
	if hour < 18:
		return "day"
	return "evening"

func _advance_needs(actor: Dictionary, elapsed: float) -> void:
	if elapsed <= 0.0:
		return
	var needs: Dictionary = actor.get("needs",{})
	needs["rest"] = clampf(float(needs.get("rest",0.5)) + elapsed*0.00065,0,1)
	needs["curiosity"] = clampf(float(needs.get("curiosity",0.4)) + elapsed*0.0004,0,1)
	needs["social"] = clampf(float(needs.get("social",0.4)) + elapsed*0.00025,0,1)
	if str(actor.get("phase","idle")) == "perform":
		var intent := str(actor.get("intent",""))
		if intent in ["REST","SLEEP"]:
			needs["rest"] = maxf(0.0,float(needs["rest"]) - elapsed*0.004)
		elif intent in ["PURPOSEFUL_EXPLORE","BROWSE_BOOK_CATALOG","BROWSE_FILMS","BROWSE_AUDIO"]:
			needs["curiosity"] = maxf(0.0,float(needs["curiosity"]) - elapsed*0.002)
	actor["needs"] = needs

func _schedule_actor(actor: Dictionary, reason: String = "PERIODIC_LOW_CADENCE") -> void:
	var id := str(actor.get("id",""))
	if id == "" or not bool(actor.get("active",false)) or not bool(actor.get("autonomy_enabled",true)):
		life_scheduler.cancel(id)
		moving_ids.erase(id)
		return
	if str(actor.get("phase","idle")) == "travel":
		moving_ids[id] = true
		# Travel itself is frame-driven. This wake is only a bounded safety check.
		life_scheduler.schedule_in(id,clock,2.0,"TRAVEL_ACTIVE")
		return
	var until := float(actor.get("until",0.0))
	if until > clock:
		life_scheduler.schedule_at(id,until,reason)
	else:
		life_scheduler.schedule_in(id,clock,idle_retry_seconds,reason)

func wake_actor(id: String, reason: String) -> void:
	if world == null or not world.residents.has(id):
		return
	var actor: Dictionary = world.residents[id]
	if not bool(actor.get("active",false)) or not bool(actor.get("autonomy_enabled",true)):
		return
	life_scheduler.wake(id,clock,reason)

func scheduler_metrics() -> Dictionary:
	return {
		"planner_calls":planner_calls,
		"planner_usec_total":planner_usec_total,
		"planner_usec_max":planner_usec_max,
		"scheduled":life_scheduler.due_at.size(),
		"moving":moving_ids.size()
	}

func _utilities(actor: Dictionary) -> Dictionary:
	var need: Dictionary = actor.get("needs", {})
	var traits: Dictionary = actor.get("traits", {})
	var rest := float(need.get("rest", 0.4))
	var social := float(need.get("social", 0.4))
	var curiosity := float(need.get("curiosity", 0.4))
	var phase := daypart()
	var scores: Dictionary = {
		"REST": 0.3 + rest * 1.2, "SLEEP": 0.1 + rest * 1.5,
		"WORK_CREATE": 0.55 + curiosity * 0.5,
		"GET_COFFEE": 0.65,
		"WATCH_FIRE": 0.4 + (0.35 if phase == "evening" else 0.0),
		"TALK_PAIR": 0.2 + social * 1.0,
		"READ_BOOK": 0.3 + float(traits.get("reading", 0.3)) + curiosity * 0.3,
		"BROWSE_BOOK_CATALOG": 0.28 + float(traits.get("reading",0.3))*0.65 + curiosity*0.40,
		"BROWSE_FILMS": 0.25 + curiosity*0.35,
		"BROWSE_AUDIO": 0.23 + float(traits.get("music",0.3))*0.6 + curiosity*0.24,
		"LISTEN_MUSIC": 0.2 + float(traits.get("music", 0.3)),
		"WATCH_FILM": 0.3 + (0.35 if phase == "evening" else 0.0),
		"VIEW_ART": 0.2 + curiosity * 0.8,
		"PURPOSEFUL_EXPLORE": 0.2 + curiosity * 0.35
	}
	if phase == "night":
		scores["SLEEP"] += 1.0
		scores["TALK_PAIR"] -= 0.4
	if phase == "morning":
		scores["GET_COFFEE"] += 0.6
		scores["WORK_CREATE"] += 0.2
	if phase == "day":
		scores["WORK_CREATE"] += 0.45
	if actor["id"] == "MANJKA":
		return {"REST": 0.2 + rest, "PURPOSEFUL_EXPLORE": 1.0 + curiosity}
	if media_runtime.available_books().is_empty():
		scores.erase("READ_BOOK")
	if world.media.get("books",[]).is_empty():
		scores.erase("BROWSE_BOOK_CATALOG")
	if world.media.get("films",[]).is_empty():
		scores.erase("BROWSE_FILMS")
	if world.media.get("tracks",[]).is_empty():
		scores.erase("BROWSE_AUDIO")
	if media_runtime.playable("films").is_empty():
		scores.erase("WATCH_FILM")
	if media_runtime.playable("tracks").is_empty():
		scores.erase("LISTEN_MUSIC")
	return scores

func _destination_pressure(actor: Dictionary, room: Dictionary) -> Dictionary:
	var path:Array=world.find_route(actor["room_id"],room["id"],actor["id"])
	if path.is_empty():
		return {}
	var room_capacity:int=maxi(1,stations.capacity(room))
	var room_used:int=stations.used_slots(world,str(room["id"]),[str(actor["id"])]).size()
	var room_ratio:float=float(room_used)/float(room_capacity)

	var group:Dictionary=world.merged_group(int(room["x"]),int(room["level"]))
	var group_used:=0
	var group_capacity:=0
	for cell in group.get("cells",[]):
		group_used+=stations.used_slots(world,str(cell["id"]),[str(actor["id"])]).size()
		group_capacity+=stations.capacity(cell)
	var group_ratio:float=float(group_used)/float(maxi(1,group_capacity))

	# Cell pressure spreads residents across merged R2/R3 rooms; group pressure
	# prevents one visual room from becoming a crowd magnet when another room
	# of the same purpose is available. Route cost remains deliberately weak.
	var pressure:float=room_ratio*0.95+group_ratio*0.30+float(path.size()-1)*0.035
	return {"room":room,"path":path,"pressure":pressure}

func best_destination(actor: Dictionary, candidates: Array) -> Dictionary:
	var best:Dictionary={}
	var best_pressure:=INF
	for room in candidates:
		var option:Dictionary=_destination_pressure(actor,room)
		if option.is_empty():
			continue
		var pressure:float=float(option["pressure"])
		if pressure<best_pressure-0.0001:
			best=option
			best_pressure=pressure
		elif is_equal_approx(pressure,best_pressure) and not best.is_empty():
			# Stable tie-break: do not let RNG make all residents pile into one
			# cell simply because identical candidates happened to repeat.
			if str(room["id"])<str(best["room"]["id"]):
				best=option
	return best

func choose_intent(actor: Dictionary) -> Dictionary:
	var scored: Dictionary = _utilities(actor)
	var best := ""
	var best_score := -999.0
	var best_room: Dictionary = {}
	for intent in scored:
		var types: Array = INTENTS[intent]
		var candidates: Array = []
		for room in world.matching_rooms(types, actor["id"]):
			if (str(room.get("type","")) == "guest"
					and intent in ["REST","SLEEP"]
					and str(room.get("owner_id","")) != str(actor.get("id",""))):
				continue
			if stations.can_reserve(world,room,intent=="TALK_PAIR"):
				candidates.append(room)
		if candidates.is_empty():
			continue
		var selected:Dictionary=best_destination(actor,candidates)
		if selected.is_empty():
			continue
		var destination:Dictionary=selected["room"]
		var path:Array=selected["path"]
		var habits: Dictionary = actor.get("habits", {})
		var repeat_bonus := minf(float(habits.get(intent, 0.0)), 0.3)
		var path_cost: float = maxf(0.0, float(path.size() - 1) * 0.045)
		var score: float = float(scored[intent]) + repeat_bonus - path_cost + rng.randf_range(-0.2, 0.2)
		if intent == "TALK_PAIR" and rng.randf() > 0.15:
			# Reserve actual social sessions later; do not fake dialogue.
			continue
		if score > best_score:
			best_score = score
			best = intent
			best_room = destination
	if best == "":
		return {}
	return {"intent": best, "room": best_room}

func _choose_partner(actor: Dictionary, destination: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_cost := 99999
	for id in world.residents:
		var other: Dictionary = world.residents[id]
		if id == actor["id"] or id == "MANJKA" or not other.get("active", false) or \
				not bool(other.get("autonomy_enabled",true)):
			continue
		if other.get("partner_id", "") != "" or other.get("phase", "idle") == "travel":
			continue
		if other.get("held_book","") != "":
			continue
		if float(other.get("until", 0.0)) > clock:
			continue
		if float(other.get("needs", {}).get("social", 0.0)) < 0.15:
			continue
		var route: Array = world.find_route(other.get("room_id", ""), destination["id"], id)
		if route.is_empty():
			continue
		if route.size() < best_cost:
			best_cost = route.size()
			best = other
	return best

func _record(message: String) -> void:
	log.push_back(message)
	while log.size() > 60:
		log.pop_front()

func end_catalog_browse(actor: Dictionary) -> void:
	# Looking up a catalog entry is not borrowing, reading, watching or playing it.
	actor.erase("browsing_item_id")
	actor.erase("browsing_category")

func end_concrete_media(actor: Dictionary) -> void:
	# Concrete media state is evidence for the resident activity, not a global
	# playback command. UI playback remains explicit user action.
	actor.erase("activity_media_category")
	actor.erase("activity_media_id")
	actor.erase("activity_media_title")

func _set_concrete_media(actor: Dictionary, category: String,
		item: Dictionary) -> void:
	var item_id:String=str(item.get("id",""))
	if item_id=="":
		return
	actor["activity_media_category"]=category
	actor["activity_media_id"]=item_id
	actor["activity_media_title"]=str(item.get("title",""))

func _concrete_media_is_valid(actor: Dictionary) -> bool:
	var category:String=str(actor.get("activity_media_category",""))
	var item_id:String=str(actor.get("activity_media_id",""))
	if category=="" or item_id=="":
		return false
	var item:Dictionary=media_runtime._lookup(category,item_id)
	if item.is_empty():
		return false
	if category=="books":
		return bool(item.get("physical",true)) and (
			str(item.get("holder_id",""))==str(actor.get("id","")))
	var destination_id:String=str(actor.get("station_room_id",""))
	if category=="films":
		return media_runtime.can_watch(str(actor.get("id","")),item_id,destination_id)
	if category=="tracks":
		return media_runtime.can_listen(str(actor.get("id","")),item_id,destination_id)
	return false

func reconcile_concrete_media() -> int:
	# Saves from before v0.14 may contain a real borrowed book but no concrete
	# media metadata. That identity is recoverable from holder_id and is safe
	# to restore. Film/music identity is not recoverable and is never guessed.
	var fixed:=0
	for id in world.residents:
		var actor:Dictionary=world.residents[id]
		if not bool(actor.get("active",false)):
			continue
		var active_id:String=str(actor.get("activity_media_id",""))
		var held_book:String=str(actor.get("held_book",""))
		if active_id=="" and held_book!="":
			var book:Dictionary=media_runtime._lookup("books",held_book)
			if not book.is_empty() and str(book.get("holder_id",""))==str(id):
				_set_concrete_media(actor,"books",book)
				fixed+=1
				continue
		if active_id!="" and _concrete_media_is_valid(actor):
			continue
		var intent:String=str(actor.get("intent",""))
		var needs_concrete:bool=intent in ["READ_BOOK","WATCH_FILM","LISTEN_MUSIC"]
		if active_id=="" and not needs_concrete:
			continue
		end_concrete_media(actor)
		if held_book!="" and intent=="READ_BOOK":
			# Do not pretend an inconsistent book is still in the actor's hand.
			var book:Dictionary=media_runtime._lookup("books",held_book)
			if book.is_empty() or str(book.get("holder_id",""))!=str(id):
				actor.erase("held_book")
		if needs_concrete and str(actor.get("phase","idle")) in ["travel","perform"]:
			stations.release(actor)
			actor["phase"]="idle"
			actor["waypoints"]=[]
			actor["waypoint_index"]=0
			actor["until"]=clock
		fixed+=1
	return fixed

func _assign(actor: Dictionary, task: Dictionary) -> void:
	# Previous reservation ends before a new activity; actor state owns the
	# claim, making occupancy recoverable from JSON snapshots.
	stations.release(actor)
	end_catalog_browse(actor)
	end_concrete_media(actor)
	if task.is_empty():
		actor["until"] = clock + 15.0
		return
	var room: Dictionary = task["room"]
	var intent: String = str(task["intent"])
	var route: Array = world.find_route(actor["room_id"], room["id"], actor["id"])
	if route.is_empty():
		actor["until"] = clock + 15.0
		return

	var partner: Dictionary = {}
	var partner_route: Array = []
	var partner_claim: Dictionary = {}
	var actor_claim: Dictionary = {}
	var partner_waypoints: Array = []
	var end_time := 0.0
	if intent == "TALK_PAIR":
		partner = _choose_partner(actor,room)
		if partner.is_empty():
			actor["until"] = clock + 10.0
			return
		partner_route = world.find_route(partner["room_id"],room["id"],str(partner["id"]))
		var pair_claim: Dictionary = stations.pair(world,actor,partner,room)
		if pair_claim.is_empty() or partner_route.is_empty():
			actor["until"] = clock + 10.0
			return
		actor_claim = pair_claim["actor"]
		partner_claim = pair_claim["partner"]
		partner_waypoints = locomotion.build_waypoints(
			world,partner,partner_route,intent,partner_claim["offset"],
			float(partner_claim.get("approach_z",0.95)))
		if partner_waypoints.is_empty():
			actor["until"] = clock + 10.0
			return
		end_time = clock + maxf(float(route.size()),float(partner_route.size()))*3.2+34.0
	else:
		actor_claim = stations.single(world,actor,room,intent)
		if actor_claim.is_empty():
			actor["until"] = clock + 10.0
			return
	var actor_waypoints: Array = locomotion.build_waypoints(
		world,actor,route,intent,actor_claim["offset"],
		float(actor_claim.get("approach_z",0.95)))
	if actor_waypoints.is_empty():
		actor["until"] = clock + 10.0
		return
	# Catalog browsing is truthful even without playable audio/video or a
	# physical book. It holds only a reference ID, never an imaginary object.
	var browse_category := ""
	var browse_id := ""
	match intent:
		"BROWSE_BOOK_CATALOG": browse_category = "books"
		"BROWSE_FILMS": browse_category = "films"
		"BROWSE_AUDIO": browse_category = "tracks"
	if browse_category != "":
		var entries: Array = world.media.get(browse_category,[])
		if entries.is_empty():
			actor["until"] = clock + 12.0
			return
		var selected: Dictionary = entries[rng.randi_range(0,entries.size()-1)]
		browse_id = str(selected.get("id",""))
		if browse_id == "":
			actor["until"] = clock + 12.0
			return

	var concrete_category:=""
	var concrete_item:Dictionary={}
	# Watching/listening is allowed only after choosing one concrete playable
	# entry. A room visit alone is not evidence that a film or track was used.
	if intent=="WATCH_FILM":
		var playable_films:Array=media_runtime.playable("films")
		if playable_films.is_empty():
			actor["until"]=clock+12.0
			return
		concrete_item=playable_films[rng.randi_range(0,playable_films.size()-1)]
		if not media_runtime.can_watch(str(actor["id"]),
				str(concrete_item.get("id","")),str(room["id"])):
			actor["until"]=clock+12.0
			return
		concrete_category="films"
	elif intent=="LISTEN_MUSIC":
		var playable_tracks:Array=media_runtime.playable("tracks")
		if playable_tracks.is_empty():
			actor["until"]=clock+12.0
			return
		concrete_item=playable_tracks[rng.randi_range(0,playable_tracks.size()-1)]
		if not media_runtime.can_listen(str(actor["id"]),
				str(concrete_item.get("id","")),str(room["id"])):
			actor["until"]=clock+12.0
			return
		concrete_category="tracks"

	# Acquiring an object comes only after a destination and station are valid.
	if intent == "READ_BOOK":
		var books: Array = media_runtime.available_books()
		if books.is_empty():
			actor["until"] = clock + 12.0
			return
		concrete_item=books[rng.randi_range(0,books.size()-1)]
		var book_id: String = str(concrete_item.get("id",""))
		if not media_runtime.borrow(actor["id"],book_id,int(Time.get_unix_time_from_system())):
			actor["until"] = clock + 12.0
			return
		actor["held_book"] = book_id
		concrete_category="books"

	if intent == "TALK_PAIR":
		stations.release(partner)
		stations.commit_claim(partner,partner_claim)
		partner["intent"] = intent
		partner["waypoints"] = partner_waypoints
		partner["waypoint_index"] = 0
		partner["phase"] = "travel"
		partner["route"] = partner_route
		partner["path_index"] = 1
		partner["until"] = end_time
		partner["partner_id"] = actor["id"]
		actor["partner_id"] = partner["id"]
		_schedule_actor(partner,"PAIR_COMMITMENT")
		_record("%s и %s — договорились встретиться для разговора" %
			[actor.get("name",""),partner.get("name","")])
	stations.commit_claim(actor,actor_claim)
	if browse_category != "":
		actor["browsing_category"] = browse_category
		actor["browsing_item_id"] = browse_id
	if concrete_category!="" and not concrete_item.is_empty():
		_set_concrete_media(actor,concrete_category,concrete_item)
	actor["intent"] = intent
	actor["waypoints"] = actor_waypoints
	actor["waypoint_index"] = 0
	actor["phase"] = "travel"
	moving_ids[str(actor["id"])] = true
	actor["route"] = route
	actor["path_index"] = 1
	actor["until"] = end_time if intent == "TALK_PAIR" else (
		clock + rng.randf_range(20.0,40.0)+float(route.size())*2.0)
	var habits: Dictionary = actor.get("habits",{})
	habits[intent] = minf(0.3,float(habits.get(intent,0.0))+0.012)
	actor["habits"] = habits
	if intent != "TALK_PAIR":
		_record("%s — %s" % [actor.get("name",actor["id"]),status(actor)])
	steps += 1

const PASS_TRIGGER_X := 1.85
const PASS_LANE_OFFSET := 0.34
const FOLLOW_GAP := 0.58
const OPPOSING_YIELD_X := 0.54
const PASSING_WAYPOINT_KINDS := [
	"leave_station","local_aisle_entry","local_aisle",
	"connector_out","connector_in","lift_align","station_approach"
]

func _travel_adjustment(actor: Dictionary, at: Vector3, target: Vector3,
		point: Dictionary) -> Dictionary:
	# Cheap deterministic local avoidance for the public walking aisle.
	# It changes only the transient movement target; authored waypoints and
	# station coordinates remain untouched.
	if not PASSING_WAYPOINT_KINDS.has(str(point.get("kind",""))):
		return {"target":target,"wait":false,"passing":false}
	var dx:float=target.x-at.x
	if absf(dx)<0.05:
		return {"target":target,"wait":false,"passing":false}
	var direction:float=signf(dx)
	var actor_id:String=str(actor.get("id",""))
	var adjusted:=target
	for other_id in world.residents:
		if str(other_id)==actor_id:
			continue
		var other:Dictionary=world.residents[other_id]
		if not bool(other.get("active",false)) or str(other.get("phase",""))!="travel":
			continue
		var other_at:=Vector3(
			float(other.get("x",0.0)),
			float(other.get("visual_y",float(other.get("level",0))*world.FLOOR_H)),
			float(other.get("z",0.0)))
		if absf(other_at.y-at.y)>0.18 or absf(other_at.x-at.x)>PASS_TRIGGER_X:
			continue
		if absf(other_at.z-at.z)>0.50:
			continue
		var other_target:Vector3=locomotion.get_target(other)
		var other_dx:float=other_target.x-other_at.x
		if absf(other_dx)<0.05:
			continue
		var other_direction:float=signf(other_dx)
		var relative_x:float=other_at.x-at.x
		if is_equal_approx(direction,other_direction):
			# Same direction: the rear resident yields instead of walking
			# through the resident immediately ahead.
			if direction*relative_x>0.0 and absf(relative_x)<FOLLOW_GAP:
				return {"target":adjusted,"wait":true,"passing":false}
			continue
		if direction*other_direction<0.0 and direction*relative_x>0.0:
			# Opposing traffic gets two shallow depth lanes. Stable ID order
			# makes the choice deterministic across saves and machines.
			var lane_sign:float=-1.0 if actor_id<str(other_id) else 1.0
			adjusted.z=clampf(target.z+lane_sign*PASS_LANE_OFFSET,-1.45,1.64)
			# Close to the actual crossing one walker has deterministic
			# right-of-way. The other holds briefly instead of intersecting
			# the same screen-space body.
			if absf(relative_x)<OPPOSING_YIELD_X and actor_id>str(other_id):
				return {"target":adjusted,"wait":true}
			# A short transient X target makes the side-step happen before the
			# walkers meet. authored_target remains unchanged in _move().
			adjusted.x=at.x+direction*minf(0.38,absf(dx))
			return {"target":adjusted,"wait":false}
	return {"target":adjusted,"wait":false}

func _move(actor: Dictionary, delta: float) -> void:
	var waypoints: Array = actor.get("waypoints", [])
	var idx: int = int(actor.get("waypoint_index", 0))
	if idx >= waypoints.size():
		actor["phase"] = "perform"
		return
	var point: Dictionary = waypoints[idx]
	var authored_target: Vector3 = locomotion.get_target(actor)
	var target: Vector3 = authored_target
	var at := Vector3(float(actor.get("x",0.0)),
		float(actor.get("visual_y", float(actor.get("level",0)) * world.FLOOR_H)),
		float(actor.get("z",0.0)))
	var adjustment:Dictionary=_travel_adjustment(actor,at,target,point)
	if bool(adjustment.get("wait",false)):
		actor["moving_axis"]="wait"
		return
	target=adjustment.get("target",target)
	var speed := 2.25 if actor["id"] != "MANJKA" else 3.25
	if point["kind"] == "lift":
		speed = 1.65
	var next: Vector3 = at.move_toward(target, speed * minf(delta, 0.15))
	actor["x"] = next.x
	actor["visual_y"] = next.y
	actor["z"] = next.z
	actor["moving_axis"] = "up" if point["kind"] == "lift" else ("right" if next.x > at.x else "left" if next.x < at.x else "depth")
	if next.distance_to(authored_target) <= 0.025:
		actor["room_id"] = point["room_id"]
		var current_room: Dictionary = world.room_by_id(point["room_id"])
		if not current_room.is_empty():
			actor["level"] = current_room["level"]
		actor["waypoint_index"] = idx + 1
		if int(actor["waypoint_index"]) >= waypoints.size():
			# Consume only the travel interval before switching need semantics.
			var actor_id := str(actor.get("id",""))
			_advance_needs(actor,life_scheduler.consume_elapsed(actor_id,clock))
			actor["phase"] = "perform"
			actor["until"] = maxf(float(actor.get("until",0.0)),clock+12.0)
			moving_ids.erase(actor_id)
			life_scheduler.schedule_at(actor_id,float(actor["until"]),"ACTION_COMMITMENT")

func _process_due_actor(id: String, wake_reason: String) -> void:
	var actor: Dictionary = world.residents.get(id,{})
	if actor.is_empty() or not bool(actor.get("active",false)) or \
			not bool(actor.get("autonomy_enabled",true)):
		life_scheduler.cancel(id)
		moving_ids.erase(id)
		return
	var elapsed := life_scheduler.consume_elapsed(id,clock)
	_advance_needs(actor,elapsed)
	if str(actor.get("phase","idle")) == "travel":
		moving_ids[id] = true
		life_scheduler.schedule_in(id,clock,2.0,"TRAVEL_ACTIVE")
		return
	if float(actor.get("until",0.0)) > clock:
		life_scheduler.schedule_at(id,float(actor["until"]),"COMMITMENT_ACTIVE")
		return
	if actor.get("partner_id","") != "":
		var partner_id := str(actor["partner_id"])
		actor.erase("partner_id")
		var partner: Dictionary = world.residents.get(partner_id,{})
		if partner.get("partner_id","") == id:
			partner.erase("partner_id")
			wake_actor(partner_id,"PAIR_RELEASED")
	if actor.get("held_book","") != "":
		var book_id := str(actor["held_book"])
		media_runtime.read(id,book_id,25.0)
		media_runtime.return_book(id,book_id)
		actor.erase("held_book")
		_record("%s — вернула книгу" % actor.get("name",id))
	var started := Time.get_ticks_usec()
	var task := choose_intent(actor)
	_assign(actor,task)
	var spent := int(Time.get_ticks_usec()-started)
	planner_calls += 1
	planner_usec_total += spent
	planner_usec_max = maxi(planner_usec_max,spent)
	_schedule_actor(actor,"PLANNER_RESULT")
	world._append_journal("LIFE_PLANNER_RAN",id,id,wake_reason,str(actor.get("intent","")),
		{"planner_usec":spent,"next_due":life_scheduler.peek_due_at(id)})

func tick(delta: float) -> void:
	clock += delta
	world.sim_clock = clock
	var home_restored:int=world.tick_object_home_reset()
	if home_restored>0:
		_record("Дом вернул вещи на назначенные места: %d" % home_restored)
	creature_runtime.tick(delta)
	# Movement stays frame-driven, but only actors actually travelling are touched.
	for raw_id in moving_ids.keys().duplicate():
		var id := str(raw_id)
		var actor: Dictionary = world.residents.get(id,{})
		if actor.is_empty() or not bool(actor.get("active",false)) or \
				not bool(actor.get("autonomy_enabled",true)) or \
				str(actor.get("phase","idle")) != "travel":
			moving_ids.erase(id)
			continue
		_move(actor,delta)
	var wall_now := int(Time.get_unix_time_from_system())
	if wall_now-last_cleanup_wall_time >= 60:
		var recovered := media_runtime.cleanup_abandoned(wall_now)
		if recovered > 0:
			_record("Дом вернул забытые книги на полку: %d" % recovered)
		last_cleanup_wall_time = wall_now
	for due in life_scheduler.pop_due(clock,max_jobs_per_tick):
		_process_due_actor(str(due.get("id","")),str(due.get("reason","PERIODIC_LOW_CADENCE")))
	world.runtime_state["life_scheduler"] = life_scheduler.snapshot()
	world.runtime_state["life_scheduler_metrics"] = scheduler_metrics()
