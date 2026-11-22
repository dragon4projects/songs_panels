extends SceneTree
## QA-only scene. All approved booleans remain false on disk.
## Run with:
## xvfb-run -a Godot_v4.7.2-stable_linux.x86_64 \
##   --rendering-driver opengl3 --path . --script res://tests/qa_teea_batch_002.gd
const CANDIDATE = "res://data/asset_proposals/TEEA_INT_20261122_002_interiors.json"
const OUT = "res://private_review/teea_002"

func _initialize() -> void:
	call_deferred("run")

func capture(scene: Node3D, name: String, room: Dictionary, group: Dictionary) -> void:
	scene.zoom=12.8 if int(group["width"])==3 else 10.4 if int(group["width"])==2 else 7.8
	scene.zoom_current=scene.zoom
	scene.smooth_focus=Vector3((float(group["x_start"])+float(group["x_end"]))*0.5*scene.W,
		float(room["level"])*scene.H+1.40,0.0)
	scene.desired_focus=scene.smooth_focus
	scene.current_mode="ROOM"
	scene.apply_camera(0.1)
	scene.update_render_lod()
	await process_frame
	await process_frame
	var group_node:Node3D=scene.room_root.get_node(str(group["primary_id"]))
	var art:Node3D=group_node.get_node("Layer_ApprovedArt")
	assert(art.get_child_count()==3,"Each pilot pack must load its 3 PNG roles")
	assert(group_node.get_node("Layer_Background/Stage_Backwall").visible==false,
		"Old wall must not hide valid pilot backdrop")
	var details:Node3D=group_node.get_node("LocalFurniture")
	assert(details.get_child_count()>=1)
	var img:Image=root.get_texture().get_image()
	var destination=OUT+"/camera_"+name+".png"
	assert(img.save_png(destination)==OK)
	print("TEEA_002_CAMERA_PASS room=",name," R",group["width"],
		" art_count=",art.get_child_count()," old_backwall=hidden")

func run() -> void:
	assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))==OK)
	var raw=FileAccess.get_file_as_string(CANDIDATE)
	assert(raw!="")
	var proposal=JSON.parse_string(raw)
	assert(typeof(proposal)==TYPE_DICTIONARY)
	assert(proposal["batch_id"]=="TEEA_INT_20261122_002")
	# QA-only temporary staging. Original authoritative runtime manifest never
	# contains these layers with approved:true, nor is this dictionary saved.
	var qa_types:Dictionary=proposal["room_types"].duplicate(true)
	for typ in qa_types:
		for width in qa_types[typ]:
			for layer in qa_types[typ][width]["layers"]:
				assert(layer.get("approved",true)==false)
				layer["approved"]=true
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.world.save_path="user://qa_teea002_world.json"
	root.add_child(scene)
	current_scene=scene
	scene.set_process(false)
	# Base seed has Library R1. Simulate R2 in QA memory only by borrowing
	# one adjacent public Music room. No owner save is changed.
	scene.world.get_room(3,0)["type"]="library"
	scene.interior_skin.config={"schema":1,"room_types":qa_types}
	for old in scene.room_root.get_children():
		scene.room_root.remove_child(old)
		old.free()
	scene.make_rooms()
	await process_frame
	await process_frame
	for spec in [
		{"type":"common","x":-1,"level":0},
		{"type":"library","x":2,"level":0},
		{"type":"study","x":-3,"level":0},
		{"type":"rest","x":1,"level":0}
	]:
		var room:Dictionary=scene.world.get_room(int(spec["x"]),int(spec["level"]))
		var group:Dictionary=scene.world.merged_group(int(spec["x"]),int(spec["level"]))
		assert(str(room["type"])==str(spec["type"]))
		assert(scene.interior_skin.validated_layers(str(spec["type"]),int(group["width"])).size()==3)
		await capture(scene,str(spec["type"]),room,group)
	for ext in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.world.save_path+ext))
	print("TEEA_002_ALL_CAMERA_TESTS_PASS 4 groups / 12 layers / owner_approved=false")
	quit(0)

