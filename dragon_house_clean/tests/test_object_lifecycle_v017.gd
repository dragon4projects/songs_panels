extends SceneTree
const World=preload("res://scripts/world_model.gd")

func _initialize()->void:
	call_deferred("run")

func _cleanup(path:String)->void:
	for suffix in [
		"",".bak",".tmp",
		".world_events_v1.json",
		".world_events_v1.json.bak",
		".world_events_v1.json.tmp",
		".world_events_v1.json.corrupt"
	]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))

func run()->void:
	var path="user://object_lifecycle_v017.json"
	_cleanup(path)

	var world=World.new()
	world.save_path=path
	world.seed_world()

	var home:Dictionary=world.get_room(1,-1) # public artifact room
	var lost_found:Dictionary=world.get_room(-2,0) # public common cell
	assert(not home.is_empty())
	assert(not lost_found.is_empty())

	assert(world.register_physical_object(
		"QA_ARTIFACT_001","QA single persistent artifact","RES_01",home["id"],
		true,true,true,true,false,{"object_class":"small_artifact","home_anchor":[0.25,-0.80]}))
	assert(not world.register_physical_object(
		"QA_ARTIFACT_001","duplicate","RES_02",home["id"]))

	var object:Dictionary=world.physical_object("QA_ARTIFACT_001")
	assert(str(object["canonical_owner_id"])=="RES_01")
	assert(str(object["current_room_id"])==str(home["id"]))
	assert(str(object["current_holder_id"])=="")
	assert(str(object["state"])=="PLACED")
	assert(bool(object["ambient_pickup_allowed"]))

	# Manka cannot teleport-pick an object from another room.
	assert(not world.pickup_physical_object("QA_ARTIFACT_001","MANJKA"))

	var manjka:Dictionary=world.residents["MANJKA"]
	manjka["room_id"]=home["id"]
	manjka["x"]=float(home["x"])*World.MODULE_W
	manjka["level"]=int(home["level"])
	assert(world.pickup_physical_object("QA_ARTIFACT_001","MANJKA"))
	assert(str(object["canonical_owner_id"])=="RES_01",
		"Holder change must never rewrite canonical ownership")
	assert(str(object["current_holder_id"])=="MANJKA")
	assert(str(object["current_room_id"])=="")
	assert(str(object["state"])=="HELD")

	# A held identity is unique; it cannot be picked up again.
	assert(not world.pickup_physical_object("QA_ARTIFACT_001","MANJKA"))

	# Move Manka to a public stash-like room and place the SAME object identity.
	manjka["room_id"]=lost_found["id"]
	assert(world.place_physical_object(
		"QA_ARTIFACT_001","MANJKA",lost_found["id"],"STASHED"))
	assert(str(object["current_holder_id"])=="")
	assert(str(object["current_room_id"])==str(lost_found["id"]))
	assert(str(object["state"])=="STASHED")
	assert(str(object["canonical_owner_id"])=="RES_01")

	# House spirit recovery moves the same object; it does not duplicate it.
	assert(world.recover_physical_object_to_lost_found(
		"QA_ARTIFACT_001",lost_found["id"]))
	assert(str(object["state"])=="LOST_FOUND")
	assert(str(object["canonical_owner_id"])=="RES_01")

	assert(world.save_world())
	var restored=World.new()
	restored.save_path=path
	restored.load_or_seed()
	assert(restored.objects.size()==1)
	var loaded:Dictionary=restored.physical_object("QA_ARTIFACT_001")
	assert(str(loaded["canonical_owner_id"])=="RES_01")
	assert(str(loaded["current_room_id"])==str(lost_found["id"]))
	assert(str(loaded["state"])=="LOST_FOUND")
	assert(loaded.get("history",[]).size()>=4)

	assert(restored.restore_physical_object_home("QA_ARTIFACT_001"))
	assert(str(loaded["current_holder_id"])=="")
	assert(str(loaded["current_room_id"])==str(home["id"]))
	assert(str(loaded["state"])=="PLACED")
	assert(str(loaded["canonical_owner_id"])=="RES_01")
	assert(restored.objects.size()==1)
	assert(restored.save_world())

	var check=World.new()
	check.save_path=path
	check.load_or_seed()
	var final_obj:Dictionary=check.physical_object("QA_ARTIFACT_001")
	assert(str(final_obj["current_room_id"])==str(home["id"]))
	assert(str(final_obj["canonical_owner_id"])=="RES_01")
	assert(final_obj.get("history",[]).size()>=5)

	_cleanup(path)
	print("OBJECT_LIFECYCLE_V017_PASS identity=unique owner=stable holder/location=persistent stash=explicit_opt_in lost_found=recoverable restore=home")
	quit(0)
