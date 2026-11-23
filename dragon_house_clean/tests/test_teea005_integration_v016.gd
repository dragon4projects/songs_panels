extends SceneTree

func _initialize()->void:
	call_deferred("run")

func _add_group(scene,kind:String,width:int,start_x:int,level:int)->Array:
	var cells:Array=[]
	for i in range(width):
		cells.append(scene.world.make_room(start_x+i,level,kind))
	return cells

func _node_for_room(scene,room:Dictionary)->Node3D:
	var group:Dictionary=scene.world.merged_group(int(room["x"]),int(room["level"]))
	for key in scene.visual_room_groups:
		var rendered:Dictionary=scene.visual_room_groups[key]
		if str(rendered.get("primary_id",""))==str(group.get("primary_id","")):
			return scene.room_root.get_node(str(key))
	return null

func _mount(scene,room:Dictionary)->Node3D:
	scene.selected_room=str(room["id"])
	scene.set_mode("ROOM")
	scene.zoom_current=scene.zoom
	scene.smooth_focus=scene.desired_focus
	scene.apply_camera(1.0)
	scene.update_render_lod()
	return _node_for_room(scene,room)

func _assert_fg(scene,room:Dictionary)->void:
	var node:Node3D=_mount(scene,room)
	assert(node!=null)
	var fg:Sprite3D=node.get_node("Layer_ApprovedArt").get_node_or_null("Art_foreground")
	assert(fg!=null)
	assert(fg.has_meta("physical_z"))
	assert(absf(float(fg.get_meta("physical_z"))-0.15)<0.00001)
	scene.yaw=-0.15
	scene.apply_camera(1.0)
	var lx:float=fg.position.x
	var ly:float=fg.position.y
	scene.yaw=0.15
	scene.apply_camera(1.0)
	var rx:float=fg.position.x
	var ry:float=fg.position.y
	assert(not is_equal_approx(lx,rx))
	assert(absf(ly-ry)<0.03)
	scene.yaw=0.0

func run()->void:
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.world.save_path="user://teea005_v016_test.json"
	root.add_child(scene)
	current_scene=scene
	scene.world.seed_world()

	var groups={
		"common/R1":_add_group(scene,"common",1,18,2),
		"common/R2":_add_group(scene,"common",2,18,3),
		"study/R2":_add_group(scene,"study",2,22,2),
		"study/R3":_add_group(scene,"study",3,22,3),
		"rest/R2":_add_group(scene,"rest",2,18,-2),
		"rest/R3":_add_group(scene,"rest",3,18,-3),
		"library/R1":_add_group(scene,"library",1,26,2),
		"library/R3":_add_group(scene,"library",3,26,3)
	}
	scene.make_rooms()
	scene.qa_visual_preview=true
	scene.make_residents()
	await process_frame
	await process_frame

	var expected_counts={
		"common/R1":[2],
		"common/R2":[2,2],
		"study/R2":[1,2],
		"study/R3":[2,1,1],
		"rest/R2":[1,2],
		"rest/R3":[1,2,1],
		"library/R1":[2],
		"library/R3":[1,2,1]
	}
	var station_total:=0
	for key in groups:
		var parts:PackedStringArray=key.split("/")
		var kind:String=parts[0]
		var width:int=int(parts[1].substr(1))
		var cells:Array=groups[key]
		var layers:Array=scene.interior_skin.validated_layers(kind,width)
		assert(layers.size()==4,"layers "+key)
		var node:Node3D=_mount(scene,cells[0])
		assert(node!=null)
		var rendered:Dictionary=scene.visual_room_groups[node.name]
		assert(bool(rendered["has_art"]))
		assert(bool(rendered["replaces_furniture"]))
		for i in range(width):
			var anchors:Array=scene.life.stations.furniture.for_room_variant(cells[i],width,i)
			assert(anchors.size()==int(expected_counts[key][i]),"stations "+key+" module "+str(i))
			for a in anchors:
				assert(str(a.get("pose_hint","")) in ["TALK","USE","READ","RELAXED_SIT","SLEEP"])
			station_total+=anchors.size()
		_assert_fg(scene,cells[0])
	assert(station_total==26)

	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.world.save_path+suffix))
	print("TEEA005_INTEGRATION_V016_PASS variants=8 layers=32 stations=26 foreground=8 depth_bands=runtime")
	quit(0)
