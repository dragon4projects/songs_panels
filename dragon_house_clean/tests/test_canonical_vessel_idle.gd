extends SceneTree
const W=preload("res://scripts/world_model.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	OS.set_environment("DRAGON_OBJECT_EVENT_BACKEND","json")
	var w=W.new()
	w.canonical_house_seed=true
	w.save_path="user://canonical_vessel_idle_qa.json"
	w.seed_world()
	var home:Dictionary=w.get_room(-3,1)
	var other:Dictionary=w.get_room(4,0)
	var actor:Dictionary=w.residents["RES_01"]
	actor["active"]=true
	actor["room_id"]=home["id"]
	var id:="QA_MUG"
	assert(w.register_physical_object(id,"QA cup","",home["id"],true,true,false,false,true,{"viewer_category":"cups","home_anchor":[0.3,0.4]}))
	w.sim_clock=86390.0
	assert(w.pickup_physical_object(id,"RES_01"))
	actor["room_id"]=other["id"]
	assert(w.place_physical_object(id,"RES_01",other["id"],"PLACED",[0.5,0.2]))
	assert(w.tick_object_home_reset()==0)
	w.sim_clock=86401.0
	assert(w.tick_object_home_reset()==0)
	assert(w.physical_object(id)["current_room_id"]==other["id"])
	w.sim_clock=90000.0
	assert(w.pickup_physical_object(id,"RES_01"))
	assert(w.note_drink_vessel_use(id,"RES_01"))
	w.sim_clock=90010.0
	assert(w.place_physical_object(id,"RES_01",other["id"],"PLACED",[0.7,0.2]))
	w.sim_clock=176409.0
	assert(w.tick_object_home_reset()==0)
	assert(w.save_world())
	var reloaded=W.new()
	reloaded.canonical_house_seed=true
	reloaded.save_path=w.save_path
	reloaded.load_or_seed()
	reloaded.sim_clock=176410.0
	assert(reloaded.tick_object_home_reset()==1)
	var obj:Dictionary=reloaded.physical_object(id)
	assert(obj["current_room_id"]==home["id"] and obj["current_anchor"]==obj["home_anchor"])
	assert(reloaded.tick_object_home_reset()==0)
	actor=reloaded.residents["RES_01"]
	actor["room_id"]=home["id"]
	assert(reloaded.pickup_physical_object(id,"RES_01"))
	reloaded.sim_clock+=W.DRINK_VESSEL_IDLE_SECONDS+2.0
	assert(reloaded.tick_object_home_reset()==0)
	assert(reloaded.physical_object(id)["current_holder_id"]=="RES_01")
	print("CANONICAL_VESSEL_IDLE_PASS midnight_ignored=true reuse_restarts=true reload=true held_exempt=true return_once=true")
	quit(0)
