extends SceneTree
const Locomotion = preload("res://scripts/room_locomotion.gd")

func _initialize() -> void:
	call_deferred("run")

func _find(points:Array,id:String) -> Dictionary:
	for p in points:
		if str(p.get("id",""))==id:
			return p
	return {}

func _assert_approach(scene, room:Dictionary, anchor:Dictionary, actor:Dictionary) -> void:
	var route:Array=scene.world.find_route(str(actor["room_id"]),str(room["id"]),str(actor["id"]))
	assert(not route.is_empty())
	var loco=Locomotion.new()
	var offset:Vector2=anchor["offset"]
	var waypoints:Array=loco.build_waypoints(scene.world,actor,route,"REST",offset,
		float(anchor["approach_z"]))
	assert(not waypoints.is_empty())
	var last:Dictionary=waypoints[-1]
	assert(last["kind"]=="station")
	assert(is_equal_approx(float(last["position"][0]),
		float(room["x"])*scene.W+offset.x))
	assert(is_equal_approx(float(last["position"][2]),offset.y))
	assert(waypoints.size()>=2)
	var previous:Dictionary=waypoints[-2]
	assert(previous["kind"]=="station_approach")
	assert(is_equal_approx(float(previous["position"][0]),float(last["position"][0])))
	assert(is_equal_approx(float(previous["position"][2]),float(anchor["approach_z"])))

func run() -> void:
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	assert(scene.teea_qa_enabled)
	assert(scene.teea_qa_error=="",scene.teea_qa_error)
	assert(scene.teea_qa_anchor_report.get("valid",false))
	assert(int(scene.teea_qa_anchor_report["legal"])==10)
	assert(int(scene.teea_qa_anchor_report["blocked"])==1)
	assert(scene.teea_qa_anchor_report.get("errors",[]).is_empty())

	# Original authored files remain candidates, never silently accepted.
	var anchors_raw=JSON.parse_string(FileAccess.get_file_as_string(scene.TEEA_QA_ANCHORS))
	assert(anchors_raw["approved"]==false)
	var fg_raw=JSON.parse_string(FileAccess.get_file_as_string(scene.TEEA_QA_FOREGROUND))
	assert(fg_raw["approved"]==false)
	for k in fg_raw["additive_layers"]:
		assert(fg_raw["additive_layers"][k]["approved"]==false)

	var expected_layers={
		"common":4,"library":4,"study":3,"rest":4
	}
	for kind in expected_layers:
		var width:int=3 if kind=="common" else 2 if kind=="library" else 1
		var layers:Array=scene.interior_skin.validated_layers(kind,width)
		assert(layers.size()==expected_layers[kind])
		var has_fg:=layers.any(func(x):return x["role"]=="foreground")
		assert(has_fg==(kind!="study"))

	# Candidate anchors appear only in the QA room cells.
	var common_left:Dictionary=scene.world.get_room(-2,0)
	var common_middle:Dictionary=scene.world.get_room(-1,0)
	var common_right:Dictionary=scene.world.get_room(0,0)
	var library_left:Dictionary=scene.world.get_room(2,0)
	var library_right:Dictionary=scene.world.get_room(3,0)
	var study:Dictionary=scene.world.get_room(-3,0)
	var rest:Dictionary=scene.world.get_room(1,0)
	var stations=scene.life.stations
	var checks=[
		[common_left,"common_sofa_left_seat_a"],
		[common_left,"common_sofa_left_seat_b"],
		[common_right,"common_bench_right_seat_a"],
		[common_right,"common_chair_right_seat_a"],
		[library_left,"library_chair_left_seat_a"],
		[library_right,"library_chair_right_seat_a"],
		[study,"study_chair_work"],
		[rest,"rest_sofa_seat_a"],
		[rest,"rest_sofa_seat_b"],
		[rest,"rest_lounge_seat_a"]
	]
	var actor:Dictionary=scene.world.residents["RES_01"]
	for pair in checks:
		var room:Dictionary=pair[0]
		var anchor:Dictionary=_find(stations.layout(room),str(pair[1]))
		assert(not anchor.is_empty(),"Missing QA anchor "+str(pair[1]))
		assert(absf(float(anchor["offset"].x))<=1.90)
		assert(float(anchor["offset"].y)>=-2.04 and float(anchor["offset"].y)<=0.95)
		_assert_approach(scene,room,anchor,actor)

	assert(_find(stations.layout(common_left),"common_chair_left_seat_a").is_empty(),
		"Blocked +2.25 station must not enter runtime")
	assert(_find(stations.layout(common_middle),"common_sofa_left_seat_a").is_empty())
	assert(_find(stations.layout(common_middle),"common_sofa_left_seat_b").is_empty())
	assert(_find(stations.layout(common_middle),"common_middle_left").is_empty(),
		"Old SOFA_COMMON_MIDDLE seat must not masquerade as new art")
	assert(_find(stations.layout(rest),"rest_left").is_empty(),
		"Old rest coordinates must not be active under Teea QA art")

	# Real render nodes load additive foreground in the exact QA camera.
	for spec in [
		["common",-1,4,true],["library",2,4,true],
		["study",-3,3,false],["rest",1,4,true]
	]:
		scene.teea_qa_focus(int(spec[1]),0)
		var group:Dictionary=scene.world.merged_group(int(spec[1]),0)
		var node:Node3D=scene.room_root.get_node(group["primary_id"])
		var art:Node3D=node.get_node("Layer_ApprovedArt")
		assert(art.get_child_count()==int(spec[2]))
		var fg:Node3D=art.get_node_or_null("Art_foreground")
		assert((fg!=null)==bool(spec[3]))
		if fg!=null:
			var key:String=str(group["type"])+"/R"+str(int(group["width"]))
			var expected_z:float=float(scene.teea_qa_anchor_report["foreground_z"][key])
			assert(is_equal_approx(fg.position.z,expected_z))
			assert(fg.scale.x>0.0 and fg.scale.x<2.0)
			assert(is_equal_approx(fg.scale.x,fg.scale.y))

	# No accepted source data changed.
	var prod=JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/interior_layers_v1.json"))
	assert(prod.get("room_types",{}).get("common",{}).get("R3",{}).get("layers",[]).is_empty())
	print("TEEA_REWORK_R1_INTEGRATION_PASS legal=10 blocked=1 foreground=3 approach_clear=10 approved=false")
	quit(0)

