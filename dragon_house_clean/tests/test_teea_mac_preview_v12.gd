extends SceneTree
const CANDIDATE="res://data/asset_proposals/TEEA_INT_20261122_002_interiors.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	assert(scene.teea_qa_enabled)
	assert(scene.teea_qa_show_new)
	assert(scene.world.save_path=="user://teea002_qa_disposable_world.json")
	assert(scene.world.get_room(3,0)["type"]=="library")
	assert(scene.world.get_room(4,0)["type"]=="cinema")
	assert(scene.teea_qa_toolbar!=null and scene.teea_qa_toolbar.is_inside_tree())
	assert(scene.teea_qa_note.text.contains("НЕ УТВЕРЖДЕНО"))
	assert(scene.teea_qa_error=="")
	var raw=JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE))
	assert(raw.get("batch_id")=="TEEA_INT_20261122_002")
	for room in ["common","library","study","rest"]:
		for variant in raw["room_types"][room]:
			for item in raw["room_types"][room][variant]["layers"]:
				assert(item["approved"]==false)
	assert(scene.interior_skin.validated_layers("common",3).size()==4)
	assert(scene.interior_skin.validated_layers("library",2).size()==4)
	assert(scene.interior_skin.validated_layers("study",1).size()==3)
	assert(scene.interior_skin.validated_layers("rest",1).size()==4)
	assert(scene.teea_qa_anchor_report.get("valid",false))
	assert(scene.teea_qa_anchor_report.get("legal",0)==10)
	assert(scene.teea_qa_anchor_report.get("blocked",0)==1)
	assert(scene.interior_skin.validated_layers("private",1).is_empty())
	for data in [
		{"x":-1,"type":"common","R":3},
		{"x":2,"type":"library","R":2},
		{"x":-3,"type":"study","R":1},
		{"x":1,"type":"rest","R":1}
	]:
		scene.teea_qa_focus(int(data["x"]))
		assert(scene.current_mode=="ROOM")
		var group=scene.world.merged_group(int(data["x"]),0)
		assert(str(group["type"])==data["type"])
		assert(int(group["width"])==int(data["R"]))
		var node=scene.room_root.get_node(group["primary_id"])
		print("ROOM_QA ",data["type"]," art=",node.get_node("Layer_ApprovedArt").get_child_count(),
			"has_art=",scene.visual_room_groups[node.name].get("has_art"),
			"z=",scene.zoom_current," layers=",scene.interior_skin.validated_layers(data["type"],int(data["R"])).size())
		var expected_count:int=3 if data["type"]=="study" else 4
		assert(node.get_node("Layer_ApprovedArt").get_child_count()==expected_count,
			"Base+foreground image layers must load in room view")
		assert(not node.get_node("Layer_Background/Stage_Backwall").visible,
			"Old temporary walls may not occlude Teea backdrop")
		assert(int(scene.art_loaded_groups.get(node.name,0))==expected_count)
	var p:Dictionary=scene.world.get_room(1,0)
	var keep_id:String=str(p["id"])
	var resident_count:int=scene.world.residents.size()
	scene.teea_qa_toggle()
	assert(not scene.teea_qa_show_new)
	assert(scene.interior_skin.validated_layers("rest",1).is_empty())
	assert(scene.teea_qa_note.text.contains("СТАРЫЕ"))
	scene.teea_qa_focus(1)
	var group_old=scene.world.merged_group(1,0)
	var old=scene.room_root.get_node(group_old["primary_id"])
	assert(old.get_node("Layer_ApprovedArt").get_child_count()==0)
	assert(old.get_node("Layer_Background/Stage_Backwall").visible)
	var furniture=old.get_node("LocalFurniture")
	assert(furniture.get_node_or_null(keep_id+"_furniture")!=null)
	assert(scene.world.residents.size()==resident_count)
	scene.teea_qa_toggle()
	assert(scene.teea_qa_show_new)
	assert(scene.teea_qa_note.text.contains("REWORK R1"))
	scene.teea_qa_focus(1)
	var new_node=scene.room_root.get_node(group_old["primary_id"])
	assert(new_node.get_node("Layer_ApprovedArt").get_child_count()==4)
	assert(not new_node.get_node("Layer_Background/Stage_Backwall").visible)
	assert(scene.world.residents.size()==resident_count)
	# Reviewer can freeze actors at the candidate schema-2 seats.
	scene.teea_qa_anchor_demo_toggle()
	assert(scene.teea_qa_anchor_demo)
	assert(scene.teea_qa_note.text.contains("ПОСАДКИ"))
	var visible:=0
	for id in scene.actor_sprites:
		if scene.actor_sprites[id].visible:
			visible+=1
	assert(visible==3,"Rest R1 has exactly three legal candidate stations")
	scene.teea_qa_anchor_demo_toggle()
	assert(not scene.teea_qa_anchor_demo)
	# This is a QA preview only: neither authored JSON nor production
	# room layer manifest shall contain art approval.
	var original=JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE))
	assert(not original["room_types"]["rest"]["R1"]["layers"][0]["approved"])
	var prod=JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/interior_layers_v1.json"))
	assert(prod.get("room_types",{}).get("rest",{}).get("R1",{}).get("layers",[]).is_empty())
	# Leave QA save in isolated namespace; regular Dragon House never reads it.
	print("TEEA002_MAC_PREVIEW_PASS rework_R1=15_layers anchors=10+1 compare_T=works seating_A=works save=isolated approved=false")
	quit(0)

