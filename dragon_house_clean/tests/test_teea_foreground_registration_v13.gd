extends SceneTree

func _corner_screens(scene, group:Node3D, sprite:Sprite3D) -> Array:
	var tex:Texture2D=sprite.texture
	var half_w:float=float(tex.get_width())*sprite.pixel_size*sprite.scale.x*0.5
	var half_h:float=float(tex.get_height())*sprite.pixel_size*sprite.scale.y*0.5
	var out:Array=[]
	for sy in [-1.0,1.0]:
		for sx in [-1.0,1.0]:
			var local:=sprite.position+Vector3(sx*half_w,sy*half_h,0.0)
			out.append(scene.camera.unproject_position(group.to_global(local)))
	return out

func _assert_registration(scene, room_x:int, yaw_value:float) -> void:
	scene.teea_qa_focus(room_x,0)
	scene.yaw=yaw_value
	scene.apply_camera(0.05)
	scene.update_render_lod()
	scene.teea_qa_register_foregrounds()
	var group_data:Dictionary=scene.world.merged_group(room_x,0)
	var group:Node3D=scene.room_root.get_node(group_data["primary_id"])
	var art:Node3D=group.get_node("Layer_ApprovedArt")
	var fg:Sprite3D=art.get_node_or_null("Art_foreground")
	if fg==null:
		return
	var reference:Sprite3D=art.get_node("Art_furniture_back")
	var a:Array=_corner_screens(scene,group,fg)
	var b:Array=_corner_screens(scene,group,reference)
	for i in range(4):
		assert(a[i].distance_to(b[i])<0.75,
			"Foreground full-canvas registration drifted at yaw "+str(yaw_value))

func _variant_stations(doc:Dictionary,key:String)->Array:
	var out:Array=[]
	for s in doc["room_variants"][key]["stations"]:
		if str(s.get("reservation_status",""))=="CANDIDATE":
			out.append(s)
	return out

func run() -> void:
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	assert(scene.teea_qa_anchor_report.get("valid",false))
	var candidate=JSON.parse_string(FileAccess.get_file_as_string(scene.TEEA_QA_ANCHORS))
	var depths:Dictionary=scene.teea_qa_anchor_report["foreground_z"]
	for key in ["common/R3","library/R2","rest/R1"]:
		var fg_z:float=float(depths[key])
		for station in _variant_stations(candidate,key):
			var seat_z:float=float(station["cell_local_z"])
			var aisle_z:float=float(station["approach_local_z"])
			assert(seat_z<fg_z and fg_z<aisle_z,
				key+" foreground must sort between seated actor and public aisle")
	assert(not depths.has("study/R1") or scene.interior_skin.validated_layers("study",1).all(
		func(x):return x["role"]!="foreground"))

	for x in [-1,2,1]:
		for yaw in [-0.265,-0.115,0.035]:
			_assert_registration(scene,x,float(yaw))

	print("TEEA_FOREGROUND_REGISTRATION_V13_PASS screen_drift_lt_0.75px yaw=-0.15..+0.15 seat<foreground<aisle")
	quit(0)

func _initialize() -> void:
	call_deferred("run")

