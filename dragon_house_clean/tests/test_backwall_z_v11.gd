extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var path="res://assets/rooms/common/R3/__QA_VALID_REAR_V11.png"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var img:=Image.create(128,96,false,Image.FORMAT_RGBA8)
	img.fill(Color("#31281e"))
	assert(img.save_png(path)==OK)
	var scene=load("res://scenes/main.tscn").instantiate()
	# Test the original fail-safe implementation, not the QA viewer's
	# intentionally pre-enabled Teea artwork.
	scene.teea_qa_enabled=false
	scene.world.save_path="user://test_backwall_z_v11.json"
	root.add_child(scene)
	current_scene=scene
	var group=scene.world.merged_group(-1,0)
	var node=scene.room_root.get_node(group["primary_id"])
	var back=node.get_node("Layer_Background/Stage_Backwall")
	assert(back.visible)
	scene.interior_skin.config={"schema":1,"room_types":{"common":{"R3":{"layers":[
		{"role":"backdrop","path":path.trim_prefix("res://"),"approved":true}
	]}}}}
	scene.visual_room_groups[node.name]["has_art"]=true
	scene.zoom_current=10.0
	scene.smooth_focus=Vector3(-scene.W,1.4,0)
	scene.update_render_lod()
	assert(node.get_node("Layer_ApprovedArt/Art_backdrop")!=null)
	assert(not back.visible,"Stage backwall must not occlude verified approved rear image")
	assert(node.get_node("Layer_Structure/Stage_CutawayDepth")!=null)
	scene.zoom_current=95
	scene.update_render_lod()
	assert(back.visible,"Overview must restore procedural rear panel")
	await process_frame
	await process_frame
	assert(node.get_node("Layer_ApprovedArt").get_child_count()==0)
	# A broken/missing PNG must not cause the procedural wall to vanish.
	scene.interior_skin.config={"schema":1,"room_types":{"common":{"R3":{"layers":[{
		"role":"backdrop","path":"assets/rooms/common/R3/does_not_exist.png",
		"approved":true
	}]}}}}
	scene.visual_room_groups[node.name]["has_art"]=false
	scene.zoom_current=10
	scene.update_render_lod()
	assert(back.visible)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	for ext in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.world.save_path+ext))
	print("BACKWALL_Z_V11_PASS no_duplicate_rear near=art_visible far=procedural_visible missing=fail_safe")
	quit(0)

