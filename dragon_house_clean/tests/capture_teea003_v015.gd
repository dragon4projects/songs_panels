extends SceneTree

func _initialize() -> void:
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

func _actor(scene,id:String,room:Dictionary,x:float,z:float,intent:String,
		kind:String="standing",pose:String="IDLE_S")->void:
	var a:Dictionary=scene.world.residents[id]
	a["active"]=true
	a["room_id"]=room["id"]
	a["x"]=float(room["x"])*scene.W+x
	a["level"]=int(room["level"])
	a["visual_y"]=float(room["level"])*scene.H
	a["z"]=z
	a["phase"]="perform"
	a["intent"]=intent
	a["station_room_id"]=room["id"]
	a["station_kind"]=kind
	a["station_pose_hint"]=pose
	scene.actor_sprites[id].visible=true
	scene.update_residents(0.0)

func _room_view(scene,room:Dictionary,yaw_value:float,out_path:String)->void:
	scene.selected_room=room["id"]
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
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://private_review/teea003"))
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.world.save_path="user://teea003_v015_capture.json"
	root.add_child(scene)
	current_scene=scene
	scene.world.seed_world()
	var workshop:Dictionary=scene.world.make_room(0,2,"workshop")
	scene.make_rooms()
	# Integrator review is explicitly allowed to use QA resident banks. This
	# does not change resident approval; it prevents fallback silhouette width
	# from corrupting the Music/Cinema occlusion verdict.
	scene.qa_visual_preview=true
	scene.make_residents()
	_hide_all(scene)

	var arrival:Dictionary=scene.world.get_room(-5,0)
	await _room_view(scene,arrival,0.0,
		"res://private_review/teea003/arrival_r1.png")

	var corridor:Dictionary=scene.world.get_room(-4,0)
	_actor(scene,"RES_01",corridor,0.0,0.95,"PURPOSEFUL_EXPLORE")
	await _room_view(scene,corridor,0.0,
		"res://private_review/teea003/corridor_r1.png")
	_hide_all(scene)

	var music:Dictionary=scene.world.get_room(3,0)
	_actor(scene,"RES_01",music,0.55,-0.4742,"LISTEN_MUSIC","seat","RELAXED_SIT")
	await _room_view(scene,music,-0.18,
		"res://private_review/teea003/music_yaw_m018.png")
	await _room_view(scene,music,0.0,
		"res://private_review/teea003/music_yaw_000.png")
	await _room_view(scene,music,0.18,
		"res://private_review/teea003/music_yaw_p018.png")
	_hide_all(scene)

	var cinema:Dictionary=scene.world.get_room(4,0)
	_actor(scene,"RES_01",cinema,-0.5896,-0.3424,
		"WATCH_FILM","seat","RELAXED_SIT")
	_actor(scene,"RES_02",cinema,0.0896,-0.3424,
		"WATCH_FILM","seat","RELAXED_SIT")
	await _room_view(scene,cinema,-0.18,
		"res://private_review/teea003/cinema_yaw_m018.png")
	await _room_view(scene,cinema,0.0,
		"res://private_review/teea003/cinema_yaw_000.png")
	await _room_view(scene,cinema,0.18,
		"res://private_review/teea003/cinema_yaw_p018.png")
	_hide_all(scene)

	var artifact:Dictionary=scene.world.get_room(1,-1)
	_actor(scene,"RES_01",artifact,1.2,-0.5524,
		"VIEW_ART","standing","VIEW")
	_actor(scene,"RES_02",artifact,-0.38,-0.13,
		"VIEW_ART","standing","VIEW")
	await _room_view(scene,artifact,0.0,
		"res://private_review/teea003/artifact_r1.png")
	_hide_all(scene)

	_actor(scene,"RES_01",workshop,-0.62,-0.2853,
		"WORK_CREATE","work","USE")
	_actor(scene,"RES_02",workshop,0.6,-0.31,
		"WORK_CREATE","work","USE")
	await _room_view(scene,workshop,0.0,
		"res://private_review/teea003/workshop_r1.png")

	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(
			scene.world.save_path+suffix))
	print("TEEA003_V015_CAPTURE_PASS frames=10 owner_approved=false")
	quit(0)
