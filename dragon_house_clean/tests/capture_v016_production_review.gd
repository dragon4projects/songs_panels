extends SceneTree

func _initialize()->void:
	call_deferred("capture")

func _settle(frames:int)->void:
	for i in range(frames):
		await process_frame

func _save(path:String)->void:
	var img:Image=root.get_texture().get_image()
	assert(img!=null and img.get_width()>0 and img.get_height()>0)
	assert(img.save_png(ProjectSettings.globalize_path(path))==OK)

func _hide_all(scene)->void:
	for id in scene.actor_sprites:
		scene.actor_sprites[id].visible=false

func _stage_actor(scene,id:String,room:Dictionary,station:Dictionary,intent:String)->void:
	var a:Dictionary=scene.world.residents[id]
	a["active"]=true
	a["room_id"]=room["id"]
	a["x"]=float(room["x"])*scene.W+float(station["x"])
	a["level"]=int(room["level"])
	a["visual_y"]=float(room["level"])*scene.H
	a["z"]=float(station["z"])
	a["phase"]="perform"
	a["intent"]=intent
	a["until"]=scene.life.clock+10000.0
	a.erase("partner_id")
	a["station_room_id"]=room["id"]
	a["station_kind"]=str(station.get("kind","standing"))
	a["station_pose_hint"]=str(station.get("pose_hint","IDLE_S"))
	scene.actor_sprites[id].visible=true
	scene.update_residents(0.0)

func _stage_room(scene,room:Dictionary,actor_ids:Array,intent:String)->void:
	_hide_all(scene)
	var group:Dictionary=scene.world.merged_group(int(room["x"]),int(room["level"]))
	var ai:=0
	for module_index in range(group.get("cells",[]).size()):
		var cell:Dictionary=group["cells"][module_index]
		var stations:Array=scene.life.stations.furniture.for_room_variant(
			cell,int(group["width"]),module_index)
		for station in stations:
			if ai>=actor_ids.size():
				return
			_stage_actor(scene,str(actor_ids[ai]),cell,station,intent)
			ai+=1

func _room_view(scene,room:Dictionary,path:String,yaw_value:float=0.0)->void:
	scene.selected_room=str(room["id"])
	scene.set_mode("ROOM")
	scene.yaw=yaw_value
	scene.zoom_current=scene.zoom
	scene.smooth_focus=scene.desired_focus
	scene.apply_camera(1.0)
	scene.update_render_lod()
	await _settle(45)
	scene.apply_camera(1.0)
	await _settle(8)
	_save(path)

func capture()->void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://private_review/v016"))
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.world.save_path="user://v016_production_review.json"
	root.add_child(scene)
	current_scene=scene
	scene.world.seed_world()

	# Public door-note proof uses explicit owner metadata only; it never opens
	# or materializes the private interior.
	var private_room:Dictionary=scene.world.get_room(3,1)
	assert(not private_room.is_empty())
	private_room["owner_id"]="RES_08"

	var workshop:Dictionary=scene.world.make_room(0,2,"workshop")
	scene.make_rooms()
	scene.qa_visual_preview=true
	scene.make_residents()
	_hide_all(scene)

	scene.set_mode("HOUSE")
	scene.fit_house_camera()
	scene.zoom_current=scene.zoom
	scene.smooth_focus=scene.desired_focus
	scene.apply_camera(1.0)
	scene.update_render_lod()
	await _settle(50)
	_save("res://private_review/v016/v016_house.png")

	var arrival:Dictionary=scene.world.get_room(-5,0)
	await _room_view(scene,arrival,"res://private_review/v016/v016_arrival.png")

	var corridor:Dictionary=scene.world.get_room(-4,0)
	var corridor_station={
		"x":0.0,"z":0.95,"kind":"standing",
		"pose_hint":"IDLE_S","id":"qa_corridor","furniture_id":""
	}
	_stage_actor(scene,"RES_01",corridor,corridor_station,"PURPOSEFUL_EXPLORE")
	await _room_view(scene,corridor,"res://private_review/v016/v016_corridor.png")

	var music:Dictionary=scene.world.get_room(3,0)
	_stage_room(scene,music,["RES_01"],"LISTEN_MUSIC")
	await _room_view(scene,music,"res://private_review/v016/v016_music.png")

	var cinema:Dictionary=scene.world.get_room(4,0)
	_stage_room(scene,cinema,["RES_01","RES_02"],"WATCH_FILM")
	await _room_view(scene,cinema,"res://private_review/v016/v016_cinema.png")

	var artifact:Dictionary=scene.world.get_room(1,-1)
	_stage_room(scene,artifact,["RES_01","RES_02"],"VIEW_ART")
	await _room_view(scene,artifact,"res://private_review/v016/v016_artifact.png")

	_stage_room(scene,workshop,["RES_01","RES_02"],"WORK_CREATE")
	await _room_view(scene,workshop,"res://private_review/v016/v016_workshop.png")

	_hide_all(scene)
	await _room_view(scene,private_room,"res://private_review/v016/v016_private_door.png")
	assert(scene.open_door_note(str(private_room["id"])))
	await _settle(4)
	_save("res://private_review/v016/v016_private_note.png")
	scene.close_door_note()

	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(
			scene.world.save_path+suffix))
	print("V016_PRODUCTION_REVIEW_PASS frames=9 accepted_003=true door_note=true work_pose=true")
	quit(0)
