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
	var art:Node3D=node.get_node("Layer_ApprovedArt")
	var fg:Sprite3D=art.get_node_or_null("Art_foreground")
	assert(fg!=null)
	assert(fg.has_meta("physical_z"))
	assert(absf(float(fg.get_meta("physical_z"))+0.10)<0.00001)
	scene.yaw=-0.18
	scene.apply_camera(1.0)
	var lx:float=fg.position.x
	var ls:float=fg.scale.x
	scene.yaw=0.18
	scene.apply_camera(1.0)
	var rx:float=fg.position.x
	var rs:float=fg.scale.x
	assert(not is_equal_approx(lx,rx))
	assert(absf(ls-rs)<0.08)
	scene.yaw=0.0

func run()->void:
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.world.save_path="user://teea004_v016_test.json"
	root.add_child(scene)
	current_scene=scene
	scene.world.seed_world()

	var groups={
		"music/R2":_add_group(scene,"music",2,8,2),
		"music/R3":_add_group(scene,"music",3,8,3),
		"cinema/R2":_add_group(scene,"cinema",2,12,2),
		"cinema/R3":_add_group(scene,"cinema",3,12,3),
		"artifact/R2":_add_group(scene,"artifact",2,8,-2),
		"artifact/R3":_add_group(scene,"artifact",3,8,-3),
		"workshop/R2":_add_group(scene,"workshop",2,12,-2),
		"workshop/R3":_add_group(scene,"workshop",3,12,-3)
	}
	scene.make_rooms()
	scene.qa_visual_preview=true
	scene.make_residents()
	await process_frame
	await process_frame

	var expected_layers={
		"music/R2":4,"music/R3":4,
		"cinema/R2":4,"cinema/R3":4,
		"artifact/R2":3,"artifact/R3":3,
		"workshop/R2":3,"workshop/R3":3
	}
	var expected_counts={
		"music/R2":[1,1],"music/R3":[1,1,1],
		"cinema/R2":[2,1],"cinema/R3":[2,1,1],
		"artifact/R2":[2,1],"artifact/R3":[1,2,1],
		"workshop/R2":[2,1],"workshop/R3":[1,2,1]
	}
	var station_total:=0
	for key in groups:
		var parts:PackedStringArray=key.split("/")
		var kind:String=parts[0]
		var width:int=int(parts[1].substr(1))
		var cells:Array=groups[key]
		var layers:Array=scene.interior_skin.validated_layers(kind,width)
		assert(layers.size()==int(expected_layers[key]),"layers "+key)
		var node:Node3D=_mount(scene,cells[0])
		assert(node!=null)
		var rendered:Dictionary=scene.visual_room_groups[node.name]
		assert(bool(rendered["has_art"]))
		assert(bool(rendered["replaces_furniture"]))
		for i in range(width):
			var anchors:Array=scene.life.stations.furniture.for_room_variant(cells[i],width,i)
			assert(anchors.size()==int(expected_counts[key][i]),"stations "+key+" module "+str(i))
			for a in anchors:
				assert(str(a.get("pose_hint","")) in ["RELAXED_SIT","VIEW","USE"])
			station_total+=anchors.size()
	assert(station_total==26)

	_assert_fg(scene,groups["music/R2"][0])
	_assert_fg(scene,groups["music/R3"][0])
	_assert_fg(scene,groups["cinema/R2"][0])
	_assert_fg(scene,groups["cinema/R3"][0])

	for key in ["artifact/R2","artifact/R3","workshop/R2","workshop/R3"]:
		var node:Node3D=_mount(scene,groups[key][0])
		assert(node.get_node("Layer_ApprovedArt").get_node_or_null("Art_foreground")==null)

	for suffix in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.world.save_path+suffix))
	print("TEEA004_INTEGRATION_V016_PASS variants=8 layers=28 stations=26 foreground=4 semantics=adapted")
	quit(0)
