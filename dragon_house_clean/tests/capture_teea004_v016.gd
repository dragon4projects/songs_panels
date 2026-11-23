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

func _add_group(scene,kind:String,width:int,start_x:int,level:int)->Array:
	var cells:Array=[]
	for i in range(width):
		cells.append(scene.world.make_room(start_x+i,level,kind))
	return cells

func _hide_all(scene)->void:
	for id in scene.actor_sprites:
		scene.actor_sprites[id].visible=false

func _stage_group(scene,cells:Array,kind:String)->void:
	_hide_all(scene)
	var ids=["RES_01","RES_02","RES_03","RES_04","RES_05","RES_06","RES_07","RES_08"]
	var actor_index:=0
	var width:=cells.size()
	for module_index in range(width):
		var cell:Dictionary=cells[module_index]
		var anchors:Array=scene.life.stations.furniture.for_room_variant(cell,width,module_index)
		for station in anchors:
			if actor_index>=ids.size():
				break
			var id:String=ids[actor_index]
			actor_index+=1
			var a:Dictionary=scene.world.residents[id]
			a["active"]=true
			a["room_id"]=cell["id"]
			a["x"]=float(cell["x"])*scene.W+float(station["x"])
			a["level"]=int(cell["level"])
			a["visual_y"]=float(cell["level"])*scene.H
			a["z"]=float(station["z"])
			a["phase"]="perform"
			a["until"]=scene.life.clock+10000.0
			a.erase("partner_id")
			a["station_room_id"]=cell["id"]
			a["station_kind"]=str(station["kind"])
			a["station_pose_hint"]=str(station.get("pose_hint","IDLE_S"))
			match kind:
				"music": a["intent"]="LISTEN_MUSIC"
				"cinema": a["intent"]="WATCH_FILM"
				"artifact": a["intent"]="VIEW_ART"
				"workshop": a["intent"]="WORK_CREATE"
			scene.actor_sprites[id].visible=true
	scene.update_residents(0.0)

func _room_view(scene,cells:Array,yaw_value:float,out_path:String)->void:
	scene.selected_room=str(cells[0]["id"])
	scene.set_mode("ROOM")
	scene.yaw=yaw_value
	scene.zoom_current=scene.zoom
	scene.smooth_focus=scene.desired_focus
	scene.apply_camera(1.0)
	scene.update_render_lod()
	await _settle(50)
	scene.apply_camera(1.0)
	await _settle(8)
	_save(out_path)

func capture()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://private_review/teea004"))
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.world.save_path="user://teea004_v016_capture.json"
	root.add_child(scene)
	current_scene=scene
	scene.world.seed_world()
	var groups={
		"music_r2":_add_group(scene,"music",2,8,2),
		"music_r3":_add_group(scene,"music",3,8,3),
		"cinema_r2":_add_group(scene,"cinema",2,12,2),
		"cinema_r3":_add_group(scene,"cinema",3,12,3),
		"artifact_r2":_add_group(scene,"artifact",2,8,-2),
		"artifact_r3":_add_group(scene,"artifact",3,8,-3),
		"workshop_r2":_add_group(scene,"workshop",2,12,-2),
		"workshop_r3":_add_group(scene,"workshop",3,12,-3)
	}
	scene.make_rooms()
	scene.qa_visual_preview=true
	scene.make_residents()

	for key in ["music_r2","music_r3","cinema_r2","cinema_r3"]:
		var kind:String=key.split("_")[0]
		_stage_group(scene,groups[key],kind)
		await _room_view(scene,groups[key],-0.18,"res://private_review/teea004/"+key+"_yaw_m018.png")
		await _room_view(scene,groups[key],0.0,"res://private_review/teea004/"+key+"_yaw_000.png")
		await _room_view(scene,groups[key],0.18,"res://private_review/teea004/"+key+"_yaw_p018.png")

	for key in ["artifact_r2","artifact_r3","workshop_r2","workshop_r3"]:
		var kind:String=key.split("_")[0]
		_stage_group(scene,groups[key],kind)
		await _room_view(scene,groups[key],0.0,"res://private_review/teea004/"+key+".png")

	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.world.save_path+suffix))
	print("TEEA004_V016_CAPTURE_PASS frames=16 measured_station_placement=true owner_approved=false")
	quit(0)
