extends SceneTree
const World=preload("res://scripts/world_model.gd")

func _initialize()->void:
	call_deferred("run")

func _cleanup(path:String)->void:
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

func _eq_anchor(raw, value:Vector2)->bool:
	if typeof(raw)!=TYPE_ARRAY or (raw as Array).size()!=2:
		return false
	return absf(float(raw[0])-value.x)<0.001 and absf(float(raw[1])-value.y)<0.001

func _has_event(world, name:String)->bool:
	for item in world.journal_entries(128):
		if str(item.get("event",""))==name:
			return true
	return false

func run()->void:
	var path="user://object_home_v022.json"
	_cleanup(path)
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","json")
	var world=World.new()
	world.save_path=path
	world.seed_world()
	var artifact_room:Dictionary=world.get_room(1,-1)
	var common:Dictionary=world.get_room(-2,0)
	var library:Dictionary=world.get_room(2,0)
	assert(not artifact_room.is_empty() and not common.is_empty() and not library.is_empty())

	var display_home:=Vector2(-0.7,-1.25)
	assert(world.register_physical_object(
		"DISPLAY_FRAME","Картина","RES_01",common["id"],
		true,true,true,true,false,{
			"object_class":"display_object",
			"home_anchor":[display_home.x,display_home.y]
		}))
	var display:Dictionary=world.physical_object("DISPLAY_FRAME")
	assert(str(display["object_class"])=="display_object")
	assert(_eq_anchor(display["home_anchor"],display_home))
	assert(_eq_anchor(display["current_anchor"],display_home))
	var manjka:Dictionary=world.residents["MANJKA"]
	manjka["room_id"]=common["id"]
	assert(not world.pickup_physical_object("DISPLAY_FRAME","MANJKA"),
		"Only small_artifact can ever become HELD")

	var new_display_home:=Vector2(1.05,-1.52)
	var rev_before:int=world.object_event_revision()
	assert(world.assign_physical_object_home(
		"DISPLAY_FRAME",library["id"],new_display_home,true))
	assert(world.object_event_revision()==rev_before+1)
	assert(str(display["home_room_id"])==str(library["id"]))
	assert(str(display["current_room_id"])==str(library["id"]))
	assert(_eq_anchor(display["home_anchor"],new_display_home))
	assert(_eq_anchor(display["current_anchor"],new_display_home))
	assert(_has_event(world,"OBJECT_HOME_ASSIGNED"))

	var ring_home:=Vector2(0.55,-1.10)
	assert(world.register_physical_object(
		"SMALL_RING","Кольцо","RES_01",artifact_room["id"],
		true,true,true,true,false,{
			"object_class":"small_artifact",
			"home_anchor":[ring_home.x,ring_home.y],
			"reset_eligible":true
		}))
	var ring:Dictionary=world.physical_object("SMALL_RING")
	assert(str(ring["object_class"])=="small_artifact")
	assert(world.tick_object_home_reset()==0)
	assert(int(world.runtime_state["object_home_reset_day"])==0)

	manjka["room_id"]=artifact_room["id"]
	assert(world.pickup_physical_object("SMALL_RING","MANJKA"))
	assert(str(ring["state"])=="HELD")
	world.sim_clock=World.GAME_DAY_SECONDS+1.0
	assert(world.tick_object_home_reset()==1,
		"First day boundary must restore displaced eligible object")
	assert(str(ring["current_holder_id"])=="")
	assert(str(ring["current_room_id"])==str(artifact_room["id"]))
	assert(str(ring["state"])=="PLACED")
	assert(_eq_anchor(ring["current_anchor"],ring_home))
	assert(int(ring.get("last_home_reset_day",-1))==1)

	# Same-day displacement stays displaced until the next game day.
	manjka["room_id"]=artifact_room["id"]
	assert(world.pickup_physical_object("SMALL_RING","MANJKA"))
	manjka["room_id"]=common["id"]
	var stash_anchor:=Vector2(-1.2,0.35)
	assert(world.place_physical_object(
		"SMALL_RING","MANJKA",common["id"],"STASHED",stash_anchor))
	assert(_eq_anchor(ring["current_anchor"],stash_anchor))
	assert(world.tick_object_home_reset()==0)
	assert(str(ring["state"])=="STASHED")
	world.sim_clock=World.GAME_DAY_SECONDS*2.0+1.0
	assert(world.tick_object_home_reset()==1)
	assert(str(ring["current_room_id"])==str(artifact_room["id"]))
	assert(_eq_anchor(ring["current_anchor"],ring_home))

	# A Dragon-assigned new home becomes canonical for future daily resets.
	var new_ring_home:=Vector2(2.0,-1.35)
	assert(world.assign_physical_object_home(
		"SMALL_RING",common["id"],new_ring_home,true))
	assert(str(ring["home_room_id"])==str(common["id"]))
	assert(_eq_anchor(ring["home_anchor"],new_ring_home))
	manjka["room_id"]=common["id"]
	assert(world.pickup_physical_object("SMALL_RING","MANJKA"))
	world.sim_clock=World.GAME_DAY_SECONDS*3.0+1.0
	assert(world.tick_object_home_reset()==1)
	assert(str(ring["current_room_id"])==str(common["id"]))
	assert(_eq_anchor(ring["current_anchor"],new_ring_home))
	assert(int(world.runtime_state["object_home_reset_last_count"])==1)
	assert(float(world.runtime_state["object_game_day_seconds"])==World.GAME_DAY_SECONDS)

	assert(world.save_world())
	var loaded=World.new()
	loaded.save_path=path
	loaded.load_or_seed()
	var loaded_ring:Dictionary=loaded.physical_object("SMALL_RING")
	assert(str(loaded_ring["home_room_id"])==str(common["id"]))
	assert(_eq_anchor(loaded_ring["home_anchor"],new_ring_home))
	assert(_eq_anchor(loaded_ring["current_anchor"],new_ring_home))
	assert(str(loaded.physical_object("DISPLAY_FRAME")["object_class"])=="display_object")
	assert(_has_event(loaded,"OBJECT_HOME_ASSIGNED"))
	assert(_has_event(loaded,"OBJECT_RESTORED_HOME"))

	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","")
	_cleanup(path)
	print("OBJECT_HOME_V022_PASS display_not_carryable=true small_artifact_only=true home_anchor=persistent daily_once=true reassigned_home=respected")
	quit(0)
