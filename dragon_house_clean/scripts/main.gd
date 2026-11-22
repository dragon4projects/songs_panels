extends Node3D
## Fresh Godot 4.7.2 cutaway world. Geometry and presentation only;
## room truth + autonomous life are independent of the camera.
const WorldScript = preload("res://scripts/world_model.gd")
const LifeScript = preload("res://scripts/life.gd")
const MediaPanelScript = preload("res://scripts/media_station_ui.gd")
const AssetBankResolverScript = preload("res://scripts/asset_bank_resolver.gd")
const InteriorSkinScript = preload("res://scripts/interior_skin.gd")
const BankGalleryScript = preload("res://scripts/asset_gallery_ui.gd")
const W := 4.8
const H := 4.6
var world = WorldScript.new()
var life = LifeScript.new()
var asset_banks = AssetBankResolverScript.new()
var interior_skin = InteriorSkinScript.new()
var art_layer_count := 0
var detailed_room_groups: Dictionary = {}
var art_loaded_groups: Dictionary = {}
var visual_room_groups: Dictionary = {}
var detail_materialization_count := 0
var detail_eviction_count := 0
var validated_visual_banks := 0
var qa_visual_preview := false
# QA-BRANCH ONLY. Never merge to production; does NOT approve artist assets.
const TEEA_QA_BATCH := "TEEA_INT_20261122_002"
const TEEA_QA_CANDIDATE := "res://data/asset_proposals/TEEA_INT_20261122_002_interiors.json"
var teea_qa_enabled := true
var teea_qa_show_new := true
var teea_qa_error := ""
var teea_qa_note: Label
var teea_qa_toolbar: PanelContainer
var preview_visual_banks := 0
var actor_animations: Dictionary = {}
var camera: Camera3D
var room_root: Node3D
var actor_root: Node3D
var actor_sprites: Dictionary = {}
var actor_labels: Dictionary = {}
var material_cache: Dictionary = {}
var mesh_cache: Dictionary = {}
var desired_focus := Vector3.ZERO
var smooth_focus := Vector3.ZERO
var zoom := 47.0
var zoom_current := 47.0
var yaw := 0.0
var current_mode := "HOUSE"
var follow_id := ""
var selected_room := ""
var selected_outline: Node3D
var journal_panel: PanelContainer
var journal_text: Label
var journal_open := false
var follow_deadzone_ratio := 0.12
var build_mode := false
var build_type := "corridor"
var build_marker: MeshInstance3D
var build_cell := Vector2i(99, 99)
var moving_view := false
var save_timer := 0.0
var hud_title: Label
var hud_status: Label
var hud_help: Label
var hud_main_body: VBoxContainer
var hud_toggle_button: Button
var hud_brief: Label
var hud_expanded := false
var media_label: Label
var notice: Label
var menu: OptionButton
var catalog_picker: FileDialog
var media_panel: PanelContainer
var bank_gallery: PanelContainer
var catalog_metadata_added := 0
var palette := {
	"rock": Color("#665a5b"), "border": Color("#675957"),
	"rock_light": Color("#83706a"), "wood": Color("#98755d"),
	"bronze": Color("#ae8860"), "copper": Color("#bd8058"),
	"couch": Color("#6e253a"), "rug": Color("#5c2d39"),
	"light": Color("#f0bb78"), "screen": Color("#32516f"),
	"book": Color("#9a7966"), "floor": Color("#8d7569"),
	"black": Color("#171418")
}
var room_names := {
	"arrival": "Вход", "corridor": "Переход",
	"common": "Гостиная", "study": "Кабинет",
	"rest": "Комната отдыха", "library": "Библиотека",
	"cinema": "Фильмотека", "music": "Аудиотека",
	"workshop": "Мастерская", "private": "Личная дверь",
	"lift": "Подъёмник", "artifact": "Артефакты"
}

func _ready() -> void:
	Engine.max_fps = 30 # Low-end hardware baseline; detail modes can unlock 60.
	if teea_qa_enabled:
		# Isolated seeded demo. Original Dragon House save and the live world
		# are never read or overwritten by an unapproved art review app.
		world.save_path = "user://teea002_qa_disposable_world.json"
		world.seed_world()
		# Only preview: the submitted Library has R2; base world has R1.
		# One adjacent Music cell is borrowed IN MEMORY. No source save changes.
		world.get_room(3,0)["type"] = "library"
	else:
		world.load_or_seed()
	asset_banks.initialize()
	# Metadata is not a physical book or a movie/audio file.
	if not asset_banks.manifest.is_empty():
		catalog_metadata_added = world.merge_reference_book_metadata(
			asset_banks.manifest.get("media_previews",{}).get("books",[]))
	life.setup(world)
	interior_skin.initialize()
	if teea_qa_enabled:
		teea_qa_load_layers()
	validated_visual_banks = asset_banks.accepted_count(world.read_resident_profiles())
	preview_visual_banks = asset_banks.preview_count(world.read_resident_profiles())
	camera = Camera3D.new()
	camera.name = "ShelterPerspectiveCamera"
	camera.current = true
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 35.0
	camera.near = 0.1
	camera.far = 300.0
	add_child(camera)
	var ambient := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#111018")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c8b6a6")
	env.ambient_light_energy = 1.04
	ambient.environment = env
	add_child(ambient)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, -23, 0)
	sun.light_energy = 0.78
	sun.shadow_enabled = false
	add_child(sun)
	make_mountain()
	room_root = Node3D.new()
	room_root.name = "Rooms"
	add_child(room_root)
	selected_outline = Node3D.new()
	selected_outline.name = "RoomSelectionOutline"
	selected_outline.visible = false
	add_child(selected_outline)
	actor_root = Node3D.new()
	actor_root.name = "Residents"
	add_child(actor_root)
	make_rooms()
	make_residents()
	build_interface()
	fit_house_camera()
	if teea_qa_enabled:
		teea_qa_make_toolbar()
		teea_qa_focus(-1,0)
	smooth_focus = desired_focus
	zoom_current = zoom
	apply_camera(0.1)
	update_render_lod()
	notice.text = ("TEEA 002 · НЕ УТВЕРЖДЕНО · только визуальный просмотр"
		if teea_qa_enabled else
		"Независимый прототип: камера, постройка, автономная жизнь")

func teea_qa_load_layers() -> void:
	teea_qa_error = ""
	if not teea_qa_show_new:
		interior_skin.config={"schema":1,"room_types":{}}
		return
	var raw:String=FileAccess.get_file_as_string(TEEA_QA_CANDIDATE)
	var doc=JSON.parse_string(raw)
	if typeof(doc)!=TYPE_DICTIONARY or str(doc.get("batch_id",""))!=TEEA_QA_BATCH:
		teea_qa_error="Партия Теи отсутствует или неверная"
		interior_skin.config={"schema":1,"room_types":{}}
		return
	var proposed:Dictionary=doc.get("room_types",{})
	if proposed.is_empty():
		teea_qa_error="В партии нет слоёв"
		interior_skin.config={"schema":1,"room_types":{}}
		return
	var copy:Dictionary=proposed.duplicate(true)
	var total:int=0
	for typ in copy:
		for variant in copy[typ]:
			for layer in copy[typ][variant]["layers"]:
				if bool(layer.get("approved",true)):
					teea_qa_error="Исходный манифест уже содержит approved:true"
					interior_skin.config={"schema":1,"room_types":{}}
					return
				# Only an in-memory temporary preview allowance. Does not
				# update the original artist JSON or live manifest.
				layer["approved"]=true
				total+=1
	if total!=12:
		teea_qa_error="Количество слоёв не равно 12"
		interior_skin.config={"schema":1,"room_types":{}}
		return
	interior_skin.config={"schema":1,"room_types":copy}

func teea_qa_focus(x:int, level:int=0) -> void:
	var room:Dictionary=world.get_room(x,level)
	if room.is_empty():
		return
	selected_room=str(room["id"])
	set_mode("ROOM")
	var group:Dictionary=world.merged_group(x,level)
	zoom=13.3 if int(group["width"])==3 else 11.4 if int(group["width"])==2 else 8.8
	desired_focus=Vector3((float(group["x_start"])+float(group["x_end"]))*0.5*W,
		float(level)*H+1.4,0)
	smooth_focus=desired_focus
	zoom_current=zoom
	apply_camera(0.05)
	update_render_lod()

func teea_qa_toggle() -> void:
	if not teea_qa_enabled:
		return
	teea_qa_show_new = not teea_qa_show_new
	teea_qa_load_layers()
	# Rebuild camera-proximal rooms without pending nodes with duplicate IDs.
	# Only scene renderer is regenerated; logical residents and routes live on.
	for node in room_root.get_children():
		room_root.remove_child(node)
		node.free()
	make_rooms()
	update_render_lod()
	update_selection_outline()
	teea_qa_refresh_label()

func teea_qa_refresh_label() -> void:
	if teea_qa_note != null:
		teea_qa_note.text=("ТЕЯ 002 · %s · НЕ УТВЕРЖДЕНО" %
			("НОВЫЕ ИНТЕРЬЕРЫ" if teea_qa_show_new else "СТАРЫЕ ИНТЕРЬЕРЫ"))
	if notice!=null and teea_qa_enabled:
		notice.text=("Тея 002 · %s · QA, не утверждено" %
			("НОВЫЕ" if teea_qa_show_new else "СТАРЫЕ"))

func teea_qa_make_toolbar() -> void:
	# Actual clickable QA selector, not shortcuts only; functional on Mac M1.
	teea_qa_toolbar=PanelContainer.new()
	teea_qa_toolbar.name="TEEA_002_ReviewControls"
	teea_qa_toolbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	teea_qa_toolbar.position=Vector2(-470,14)
	teea_qa_toolbar.size=Vector2(460,97)
	get_tree().root.add_child(teea_qa_toolbar)
	var box:=VBoxContainer.new()
	teea_qa_toolbar.add_child(box)
	teea_qa_note=Label.new()
	box.add_child(teea_qa_note)
	var row:=HBoxContainer.new()
	box.add_child(row)
	for pair in [
		["Гостиная","C",-1],["Библиотека","L",2],
		["Кабинет","S",-3],["Отдых","R",1]
	]:
		var btn:=Button.new()
		btn.text=str(pair[0])+" ["+str(pair[1])+"]"
		btn.pressed.connect(teea_qa_focus.bind(int(pair[2]),0))
		row.add_child(btn)
	var toggle:=Button.new()
	toggle.text="Сравнить: новые / старые [T]"
	toggle.pressed.connect(teea_qa_toggle)
	box.add_child(toggle)
	teea_qa_refresh_label()

func surface_texture(color: Color) -> Texture2D:
	# Poly Haven materials are CC0 per imported asset provenance registry.
	# Reuse across modules. Geometry remains original and separately authored.
	var preference := ""
	if color == palette["rock"]:
		preference = "res://assets/materials/texture_albedo/dark_rock_diff_2k.jpg"
	elif color == palette["rock_light"]:
		preference = "res://assets/materials/texture_albedo/tiger_rock_diff_2k.jpg"
	elif color == palette["floor"]:
		preference = "res://assets/materials/texture_albedo/stone_pathway_diff_2k.jpg"
	elif color == palette["wood"]:
		preference = "res://assets/materials/texture_albedo/weathered_brown_planks_diff_1k.jpg"
	if preference != "" and ResourceLoader.exists(preference):
		return load(preference)
	return null

func mat(color: Color, emissive: bool = false) -> StandardMaterial3D:
	var key: String = str(color.to_html()) + ("_e" if emissive else "_n")
	if material_cache.has(key):
		return material_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.88
	var texture_path := ""
	if color == palette["rock"] or color == palette["rock_light"]:
		texture_path = "res://assets/textures/basalt.jpg"
	elif color == palette["wood"]:
		texture_path = "res://assets/textures/wood.jpg"
	elif color == palette["floor"]:
		texture_path = "res://assets/textures/floor.jpg"
	var licensed: Texture2D = surface_texture(color)
	if licensed != null:
		m.albedo_texture = licensed
		m.uv1_scale = Vector3(2.3, 1.35, 1.0)
	elif texture_path != "" and ResourceLoader.exists(texture_path):
		m.albedo_texture = load(texture_path)
		m.uv1_scale = Vector3(2.0, 2.0, 1.0)
	if emissive:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.65
	material_cache[key] = m
	return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	# Reuse geometry resources for repeated furniture elements / rock modules.
	var geometry_key := "%.4f:%.4f:%.4f" % [size.x,size.y,size.z]
	var mesh: BoxMesh
	if mesh_cache.has(geometry_key):
		mesh = mesh_cache[geometry_key]
	else:
		mesh = BoxMesh.new()
		mesh.size = size
		mesh_cache[geometry_key] = mesh
	node.mesh = mesh
	node.position = pos
	node.material_override = mat(color, emissive)
	parent.add_child(node)
	if not emissive and size.x < 0.57 and size.y < 0.69 and size.z < 0.62:
		node.add_to_group("low_end_micro_detail")
	return node

func make_mountain() -> void:
	# Tiled original basalt atlas behind the cutaway, not rectangular checkerboard.
	var shell := Node3D.new()
	shell.name = "MountainMassBehindRooms"
	add_child(shell)
	var rock := box(shell, Vector3(-0.5, -1.0, -5.6), Vector3(83, 26, 0.8), Color("#6f696a"))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#655d5e")
	material.albedo_texture = load("res://assets/textures/basalt.jpg")
	material.roughness = 1.0
	material.uv1_scale = Vector3(19.0, 6.0, 1.0)
	rock.material_override = material
	# Only a few irregular framing buttresses, no regular brick mosaic.
	for idx in range(10):
		var x := float(idx - 4) * 8.5
		var y := -7.0 + float(idx % 4) * 4.2
		var support := box(shell, Vector3(x, y, -4.9),
			Vector3(2.5 + float(idx % 3), 3.4, 0.28), Color("#4b4549"))
		support.rotation.z = 0.07 * float((idx % 3) - 1)

func label3(parent: Node3D, content: String, pos: Vector3, size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.text = content
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.0037
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = color
	l.outline_size = 4
	l.fixed_size = false
	parent.add_child(l)
	return l

func add_shelf(parent: Node3D, at: Vector3, width: float = 1.6) -> void:
	box(parent, at + Vector3(0.0, 0.55, 0.0), Vector3(width, 0.10, 0.36), palette["wood"])
	box(parent, at + Vector3(0.0, 1.2, 0.0), Vector3(width, 0.10, 0.36), palette["wood"])
	box(parent, at + Vector3(-width * 0.48, 0.65, 0.0), Vector3(0.11, 1.4, 0.38), palette["wood"])
	box(parent, at + Vector3(width * 0.48, 0.65, 0.0), Vector3(0.11, 1.4, 0.38), palette["wood"])
	for i in range(8):
		var c: Color = [Color("#704b43"), Color("#92715a"), Color("#554454"), Color("#57645e")][i % 4]
		var px := -width * 0.39 + float(i) * width * 0.105
		box(parent, at + Vector3(px, 0.94, -0.025), Vector3(width * 0.07, 0.53, 0.26), c)

func add_sofa(parent: Node3D, at: Vector3, width: float = 2.5, color: Color = Color("#6e253a")) -> void:
	box(parent, at + Vector3(0, 0.47, 0), Vector3(width, 0.46, 0.9), color)
	box(parent, at + Vector3(0, 0.86, -0.34), Vector3(width, 0.67, 0.23), color.darkened(0.15))
	box(parent, at + Vector3(-width * 0.47, 0.65, 0.0), Vector3(0.2, 0.65, 0.87), color.darkened(0.10))
	box(parent, at + Vector3(width * 0.47, 0.65, 0.0), Vector3(0.2, 0.65, 0.87), color.darkened(0.10))

func add_canonical_prop(parent: Node3D, prop_id: String, position: Vector3,
		world_height: float = 0.8) -> bool:
	var tex: Texture2D = asset_banks.prop_display_texture(prop_id)
	if tex == null:
		return false
	var pic := Sprite3D.new()
	pic.name = "Canon_" + prop_id
	pic.texture = tex
	pic.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	pic.pixel_size = world_height/maxf(1.0,float(tex.get_height()))
	pic.position = position
	pic.no_depth_test = false
	parent.add_child(pic)
	return true

func add_tv(parent: Node3D, at: Vector3) -> void:
	box(parent, at + Vector3(0, 0.65, -0.04), Vector3(2.2, 1.25, 0.16), palette["black"])
	box(parent, at + Vector3(0, 0.65, 0.065), Vector3(1.98, 1.04, 0.035), palette["screen"], true)
	box(parent, at + Vector3(0, -0.12, 0), Vector3(1.15, 0.18, 0.46), palette["wood"])

func furniture_object(parent: Node3D, object_id: String) -> Node3D:
	# Stable scene names mirror data/furniture_interactions_v1.json.
	# The node exists only while the camera materializes this room's detail,
	# but the simulation's data-owned station IDs persist independently.
	var object := Node3D.new()
	object.name = object_id
	parent.add_child(object)
	return object

func furnish(parent: Node3D, kind: String, x: int, level: int) -> void:
	var offset := int(abs(x) + abs(level)) % 2
	match kind:
		"common":
			box(parent, Vector3(0, 0.05, 0.45), Vector3(3.8, 0.04, 2.15), palette["rug"])
			if x == -2:
				var skins := furniture_object(parent, "FIREPLACE_SKINS")
				for side in [-1.0,1.0]:
					box(skins,Vector3(side*1.29,0.022,-0.32),
						Vector3(0.84,0.025,0.70),palette["rug"])
				box(parent, Vector3(-1.35, 1.38, -1.73), Vector3(1.25, 1.48, 0.25), palette["rock_light"])
				box(parent, Vector3(-1.35, 0.92, -1.45), Vector3(0.80, 0.58, 0.17), palette["black"])
				box(parent, Vector3(-1.32, 0.88, -1.30), Vector3(0.53, 0.45, 0.08), Color("#f4943c"), true)
				var fire_light := OmniLight3D.new()
				fire_light.name = "WarmHearthLight"
				fire_light.position = Vector3(-1.32,1.22,-1.12)
				fire_light.light_color = Color("#efaa68")
				fire_light.light_energy = 0.68
				fire_light.omni_range = 6.5
				fire_light.shadow_enabled = false
				parent.add_child(fire_light)
			elif x == -1:
				add_sofa(furniture_object(parent,"SOFA_COMMON_MIDDLE"), Vector3(0, 0, -1.06), 2.6)
				box(parent, Vector3(0, 0.44, 0.86), Vector3(1.4, 0.30, 0.7), palette["wood"])
				# Canonical historical mugs belong in the Common, not the Library.
				add_canonical_prop(parent,"MUG_RED_A",Vector3(-0.37,0.91,0.90),0.45)
				add_canonical_prop(parent,"MUG_BLUE_A",Vector3(0.34,0.91,0.90),0.45)
			else:
				add_sofa(furniture_object(parent,"SOFA_COMMON_GENERIC"), Vector3(0.0, 0, -0.88), 2.35, Color("#76513e"))
				add_shelf(parent, Vector3(1.38, 0.25, -1.70), 1.25)
		"library":
			add_shelf(parent, Vector3(-1.24, 0.15, -1.64), 1.75)
			add_shelf(parent, Vector3(1.12, 0.15, -1.64), 1.55)
			box(furniture_object(parent,"TABLE_LIBRARY"), Vector3(0.0, 0.48, 0.82), Vector3(0.9, 0.35, 0.65), palette["wood"])
		"rest":
			add_sofa(furniture_object(parent,"SOFA_REST"), Vector3(-0.30, 0.0, -0.83), 2.4, Color("#766049"))
			add_shelf(parent, Vector3(1.42, 0.23, -1.58), 1.1)
			box(parent, Vector3(0.72, 0.30, 0.70), Vector3(0.80, 0.35, 0.62), palette["wood"])
		"study":
			var desk := furniture_object(parent,"DESK_STUDY")
			box(desk, Vector3(0.0, 0.7, -1.05), Vector3(2.5, 0.18, 0.89), palette["wood"])
			box(desk, Vector3(-0.9, 0.38, -1.0), Vector3(0.15, 0.65, 0.50), palette["wood"])
			box(desk, Vector3(0.9, 0.38, -1.0), Vector3(0.15, 0.65, 0.50), palette["wood"])
			box(parent, Vector3(-0.1, 0.96, -1.0), Vector3(0.75, 0.52, 0.045), palette["screen"])
			add_shelf(parent, Vector3(1.50, 0.10, -1.7), 0.9)
		"music":
			box(parent, Vector3(-1.3, 0.7, -1.5), Vector3(1.2, 1.2, 0.58), palette["black"])
			box(parent, Vector3(1.3, 0.7, -1.5), Vector3(1.2, 1.2, 0.58), palette["black"])
			for side in [-1, 1]:
				box(parent, Vector3(side * 1.3, 0.89, -1.16), Vector3(0.7, 0.58, 0.10), palette["screen"])
			box(furniture_object(parent,"DESK_MUSIC"), Vector3(0, 0.68, -1.2), Vector3(1.25, 0.17, 0.75), palette["wood"])
		"cinema":
			add_tv(parent, Vector3(0.0, 0.70, -1.68))
			add_sofa(furniture_object(parent,"SOFA_CINEMA"), Vector3(0, 0, 0.84), 2.9, Color("#71423b"))
		"arrival":
			# Coat rack and shoe storage; deliberately no bench.
			box(parent, Vector3(-1.30, 1.28, -1.65), Vector3(0.1, 2.4, 0.1), palette["bronze"])
			box(parent, Vector3(-1.30, 2.24, -1.65), Vector3(0.85, 0.11, 0.13), palette["bronze"])
			box(parent, Vector3(1.08, 0.25, -1.5), Vector3(1.70, 0.50, 0.40), palette["wood"])
		"workshop":
			box(furniture_object(parent,"BENCH_WORKSHOP"), Vector3(0, 0.85, -1.30), Vector3(2.95, 0.20, 0.8), palette["wood"])
			add_shelf(parent, Vector3(1.2, 0.15, -1.72), 1.2)
		"artifact":
			add_shelf(parent, Vector3(0, 0.1, -1.62), 3.1)
			var canvas_ids := ["CUBE_LETTERS","POSTER_SHURSHUN","PHOTO_MOON","PORTRAIT_SHURS"]
			var art_shown := 0
			for i in range(canvas_ids.size()):
				var world_x: float = -1.65 + float(i) * 1.1
				if add_canonical_prop(parent,canvas_ids[i],Vector3(world_x,1.45,-1.52),0.95):
					art_shown += 1
			if art_shown == 0:
				# Temporary placeholder only. Never present cubes as the real masters.
				for side in [-1, 0, 1]:
					var cube := box(parent, Vector3(float(side) * 0.65, 1.0, -1.26), Vector3(0.36, 0.36, 0.36), Color("#7b8a83"))
					cube.transparency = 0.12
		"lift":
			box(parent, Vector3(-1.5, 1.0, -1.5), Vector3(0.14, 2.0, 0.30), palette["bronze"])
			box(parent, Vector3(1.5, 1.0, -1.5), Vector3(0.14, 2.0, 0.30), palette["bronze"])
			box(parent, Vector3(0, 0.04, 0.10), Vector3(3.3, 0.08, 3.4), palette["copper"])
		"corridor":
			if offset == 0:
				box(parent, Vector3(0, 0.5, -1.70), Vector3(1.0, 1.05, 0.16), palette["wood"])

func add_backwall_stage(parent: Node3D, group: Dictionary) -> void:
	# Cutaway has actual depth: the rear alcove is inset and all details remain
	# behind the mid-depth actor walkway. Shared R2/R3 rooms have continuous
	# floors plus repeated architectural bays, never full mid-room partitions.
	# No private room interiors are ever instantiated.
	var kind: String = str(group["type"])
	if kind == "private" or kind == "lift":
		return
	var base_color := Color("#4a4143")
	match kind:
		"common": base_color = Color("#514046")
		"library", "artifact": base_color = Color("#433739")
		"cinema": base_color = Color("#26242b")
		"study", "workshop": base_color = Color("#554843")
		"music": base_color = Color("#403842")
		"rest": base_color = Color("#51473f")
	var center: float = (float(group["x_start"])+float(group["x_end"]))*0.5
	for cell in group["cells"]:
		var module := Node3D.new()
		module.name = "RearBay_"+str(cell["id"])
		module.position.x = (float(cell["x"])-center)*W
		parent.add_child(module)
		# Dark matte recess, crown moulding, vertical stone returns and wainscot.
		box(module,Vector3(0,1.49,-1.78),Vector3(3.84,2.67,0.08),base_color)
		box(module,Vector3(-1.89,1.47,-1.59),Vector3(0.12,2.76,0.24),palette["rock_light"])
		box(module,Vector3(1.89,1.47,-1.59),Vector3(0.12,2.76,0.24),palette["rock_light"])
		box(module,Vector3(0,2.83,-1.58),Vector3(3.87,0.15,0.25),palette["border"])
		box(module,Vector3(0,0.19,-1.55),Vector3(3.72,0.31,0.27),palette["border"])
		# Minimal practical wall sconces: emissive material instead of eight real
		# omni lights per room (target Dell 5300 Compatibility renderer).
		if ["common","rest","study","library","arrival"].has(kind):
			for side in [-1.0,1.0]:
				box(module,Vector3(side*1.43,2.22,-1.41),
					Vector3(0.09,0.34,0.10),palette["bronze"])
				box(module,Vector3(side*1.43,2.43,-1.33),
					Vector3(0.15,0.14,0.09),Color("#b17c55"),true)

func add_cutaway_depth(parent: Node3D, group: Dictionary) -> void:
	# Shallow 3D, not a newly baked fake perspective image. These thin
	# structural features preserve the exact contracted Z positions of the
	# forthcoming photorealistic room sprites from Teea.
	# Recesses, floor depth marks, and a *low* front edge produce an observable
	# interior volume rather than a single wall/furniture cardboard plane.
	var kind: String = str(group["type"])
	if kind in ["private","lift"]:
		return
	var middle: float=(float(group["x_start"])+float(group["x_end"]))*0.5
	for cell in group["cells"]:
		var module:=Node3D.new()
		module.name="Depth_"+str(cell["id"])
		module.position.x=(float(cell["x"])-middle)*W
		parent.add_child(module)
		# Underlit walk path is recessed relative to both front and back.
		# Low thin lines suggest real floor plane perspective without painting
		# stripes across the actors' feet.
		for z in [-1.19,0.24,1.25]:
			box(module,Vector3(0,-0.004,float(z)),
				Vector3(3.82,0.018,0.023),Color("#3f3637"))
		# Front floor reveal with continuous floor lip and two small stone
		# returns that stop below knee level.
		box(module,Vector3(0,-0.25,1.63),
			Vector3(4.42,0.13,0.28),palette["rock_light"])
		for side in [-1.0,1.0]:
			box(module,Vector3(side*2.02,0.24,1.59),
				Vector3(0.16,0.49,0.35),palette["rock_light"])
		# Lower panel in a shadowed rear alcove, physically behind furniture.
		box(module,Vector3(0,1.47,-1.87),
			Vector3(3.45,2.24,0.09),Color("#393234"))
		box(module,Vector3(0,0.34,-1.74),
			Vector3(3.49,0.18,0.18),palette["wood"])

func add_room_overview_cues(parent: Node3D, group: Dictionary) -> void:
	# Cheap silhouettes carry room identity when rich furniture is not instantiated.
	# Never show the contents of private rooms; those only have a public facade.
	var kind: String = str(group["type"])
	if kind == "private":
		return
	var start_x: int = int(group["x_start"])
	var end_x: int = int(group["x_end"])
	var center_x: float = (float(start_x)+float(end_x))*0.5
	for cell in group["cells"]:
		var x: float = (float(cell["x"])-center_x)*W
		match kind:
			"common", "rest":
				box(parent, Vector3(x,0.39,-1.24), Vector3(1.9,0.70,0.48),palette["rug"])
			"library", "artifact":
				box(parent, Vector3(x,1.16,-1.70), Vector3(2.8,1.80,0.22),palette["wood"])
				box(parent, Vector3(x,1.74,-1.54), Vector3(2.48,0.055,0.20),palette["rock_light"])
			"cinema":
				box(parent, Vector3(x,1.65,-1.74), Vector3(2.5,1.42,0.15),palette["black"])
				box(parent, Vector3(x,1.65,-1.63), Vector3(2.16,1.10,0.07),palette["screen"],true)
			"music":
				for side in [-1.0,1.0]:
					box(parent, Vector3(x+side*1.0,1.09,-1.67), Vector3(0.54,1.40,0.24),palette["black"])
			"study", "workshop":
				box(parent, Vector3(x,0.66,-1.26), Vector3(2.72,0.18,0.66),palette["wood"])
			"arrival":
				box(parent, Vector3(x,1.20,-1.67), Vector3(0.10,2.15,0.12),palette["bronze"])
			"lift":
				box(parent, Vector3(x,0.06,-0.35), Vector3(3.5,0.08,3.1),palette["copper"])
			_:
				pass

func _is_near_detail(group_node: Node3D) -> bool:
	# Detail follows the camera position but never drives simulation.
	# R1/R2/R3 shells stay drawn; rich furniture is mounted only near focus.
	if zoom_current >= 44.0:
		return false
	var half_width: float = float(visual_room_groups.get(group_node.name,{}).get("width",1))*W*0.5
	var radius_x: float = maxf(7.0,zoom_current*0.63)+half_width
	var radius_y: float = maxf(H*1.15,zoom_current*0.30)
	return absf(group_node.position.x-smooth_focus.x) <= radius_x and absf(group_node.position.y-smooth_focus.y) <= radius_y

func _load_room_art(group_node: Node3D) -> void:
	if art_loaded_groups.has(group_node.name):
		return
	var group: Dictionary=visual_room_groups.get(group_node.name,{})
	if not bool(group.get("has_art",false)):
		return
	var layer: Node3D=group_node.get_node_or_null("Layer_ApprovedArt")
	if layer==null:
		return
	var count: int=interior_skin.add_layers(layer,str(group["type"]),
		int(group["width"]),float(group["width"])*W)
	if count>0:
		art_loaded_groups[group_node.name]=count
		art_layer_count+=count
		# A complete approved rear image and the procedural backwall occupy
		# competing Z planes. The 3D panels were physically occluding the
		# actual image in Godot 4.7.2. Hide only the old REAR PANELS and only
		# while a valid uploaded backdrop is genuinely mounted. Keep the
		# structural floor, side frames and privacy doors intact.
		var stage:Node3D=group_node.get_node_or_null("Layer_Background/Stage_Backwall")
		if stage!=null and layer.get_node_or_null("Art_backdrop")!=null:
			stage.visible=false

func _release_room_art(group_node: Node3D) -> void:
	if not art_loaded_groups.has(group_node.name):
		return
	var count: int=int(art_loaded_groups[group_node.name])
	art_loaded_groups.erase(group_node.name)
	art_layer_count=maxi(0,art_layer_count-count)
	var layer: Node3D=group_node.get_node_or_null("Layer_ApprovedArt")
	if layer:
		for child in layer.get_children():
			# Detach now rather than waiting for the frame end: rapidly
			# switching preview rooms must not render two art copies.
			layer.remove_child(child)
			child.queue_free()
	var stage:Node3D=group_node.get_node_or_null("Layer_Background/Stage_Backwall")
	if stage!=null:
		stage.visible=true

func _populate_furniture(group_node: Node3D) -> void:
	var group: Dictionary = visual_room_groups.get(group_node.name,{})
	if group.is_empty() or str(group.get("type","")) == "private":
		return
	var decoration_layer: Node3D = group_node.get_node_or_null("LocalFurniture")
	if decoration_layer == null or detailed_room_groups.has(group_node.name):
		return
	var center_cell: float = (float(group["x_start"])+float(group["x_end"]))*0.5
	for cell in group["cells"]:
		var module := Node3D.new()
		module.name = str(cell["id"])+"_furniture"
		module.position.x = (float(cell["x"])-center_cell)*W
		decoration_layer.add_child(module)
		if bool(group.get("replaces_furniture",false)):
			# Teea's approved furniture art replaces interim geometry.
			# Keep named invisible anchors for existing room interaction
			# contracts but do NOT draw a second 3D sofa on top of the art.
			var seen: Dictionary={}
			for station in life.stations.furniture.for_room(cell):
				var name: String=str(station.get("furniture_id",""))
				if name!="" and not seen.has(name):
					furniture_object(module,name)
					seen[name]=true
		else:
			furnish(module,str(group["type"]),int(cell["x"]),int(group["level"]))
	detailed_room_groups[group_node.name] = true
	detail_materialization_count += 1

func _release_furniture(group_node: Node3D) -> void:
	if not detailed_room_groups.has(group_node.name):
		return
	var decoration_layer: Node3D = group_node.get_node_or_null("LocalFurniture")
	if decoration_layer:
		for child in decoration_layer.get_children():
			decoration_layer.remove_child(child)
			child.queue_free()
	detailed_room_groups.erase(group_node.name)
	detail_eviction_count += 1

func make_room(group: Dictionary) -> void:
	# One shell per logical R1/R2/R3 merge group, not N adjacent full-walled rooms.
	# Individual module IDs remain in the World Core so residents keep legal routes.
	var n := Node3D.new()
	n.name = group["primary_id"]
	var level: int = int(group["level"])
	var x_start: int = int(group["x_start"])
	var x_end: int = int(group["x_end"])
	var center_cell: float = (float(x_start)+float(x_end))*0.5
	var span: float = float(group["width"])*W
	n.position = Vector3(center_cell*W,float(level)*H,0.0)
	room_root.add_child(n)
	visual_room_groups[n.name] = group
	var t: String = group["type"]
	var accepted: Array=interior_skin.validated_layers(t,int(group["width"]))
	visual_room_groups[n.name]["has_art"] = not accepted.is_empty()
	visual_room_groups[n.name]["replaces_furniture"] = accepted.any(
		func(item): return str(item.get("role","")) == "furniture_back")
	var side_left: Dictionary = world.get_room(x_start-1,level)
	var side_right: Dictionary = world.get_room(x_end+1,level)
	# Render hierarchy is spatial, not a single baked background image.
	var background := Node3D.new()
	background.name = "Layer_Background"
	n.add_child(background)
	var structure := Node3D.new()
	structure.name = "Layer_Structure"
	n.add_child(structure)
	var overlay := Node3D.new()
	overlay.name = "Layer_Foreground"
	n.add_child(overlay)
	var artwork := Node3D.new()
	artwork.name = "Layer_ApprovedArt"
	n.add_child(artwork)
	# Back wall at -Z, gameplay and furniture in the middle, low foreground at +Z.
	box(structure,Vector3(0,-0.12,-0.07),Vector3(span*1.01,0.25,4.05),palette["floor"])
	if t != "private":
		var cutaway_depth:=Node3D.new()
		cutaway_depth.name="Stage_CutawayDepth"
		structure.add_child(cutaway_depth)
		add_cutaway_depth(cutaway_depth,group)
	box(background,Vector3(0,1.45,-2.04),Vector3(span*1.01,3.25,0.35),palette["rock"])
	if t != "private":
		var rear_stage := Node3D.new()
		rear_stage.name = "Stage_Backwall"
		background.add_child(rear_stage)
		add_backwall_stage(rear_stage,group)
	box(structure,Vector3(0,3.12,-0.35),Vector3(span*1.01,0.22,3.55),palette["border"])
	box(overlay,Vector3(0,-0.20,1.80),Vector3(span*1.01,0.22,0.18),palette["border"])
	# Expensive full-resolution artwork is loaded on demand by
	# update_render_lod(), not permanently allocated for all 49+ rooms.
	for side in [-1,1]:
		var neighbour: Dictionary = side_left if side == -1 else side_right
		var edge: float = float(side)*(span*0.5-0.10)
		if neighbour.is_empty():
			box(structure,Vector3(edge,1.39,-0.22),Vector3(0.35,2.90,3.82),palette["rock_light"])
			# Partial foreground pier emphasizes depth without hiding the entire actor.
			box(overlay,Vector3(edge,0.36,1.73),Vector3(0.40,0.70,0.28),palette["rock_light"])
		else:
			# Doorway frame: two pillars BEHIND the public front walking aisle.
			box(structure,Vector3(edge,2.67,-0.3),Vector3(0.26,0.74,3.18),palette["rock_light"])
			box(structure,Vector3(edge,0.56,-1.75),Vector3(0.26,1.2,0.28),palette["rock_light"])
	# Merged runs: narrow arch ribs only, no full partitions or duplicate room names.
	if int(group["width"]) > 1:
		for i in range(int(group["width"])-1):
			var seam_x: float = (float(x_start)+float(i)+0.5-center_cell)*W
			box(structure,Vector3(seam_x,2.93,-0.50),
				Vector3(0.12,0.37,3.15),palette["rock_light"])
	if t != "private":
		var overview := Node3D.new()
		overview.name = "Layer_OverviewCues"
		n.add_child(overview)
		add_room_overview_cues(overview,group)
	if t == "private":
		# Never materialize someone else's private interior: facade only.
		box(n,Vector3(0,1.4,1.05),Vector3(2.08,2.8,0.22),palette["wood"])
		box(n,Vector3(0.82,1.33,1.2),Vector3(0.12,0.12,0.07),palette["bronze"])
		var door_label := label3(n,"ЛИЧНОЕ",Vector3(0,3.34,1.0),24,Color("#d4bdb0"))
		door_label.name = "RoomRoofLabel"
	else:
		var decoration_layer := Node3D.new()
		decoration_layer.name = "LocalFurniture"
		n.add_child(decoration_layer)
		var title: String = room_names.get(t,t)
		if int(group["width"]) > 1:
			title += " · %d" % int(group["width"])
		var roof_label := label3(n,title,Vector3(0,3.35,0.40),24,Color("#f4d9b9"))
		roof_label.name = "RoomRoofLabel"

func make_rooms() -> void:
	art_layer_count = 0
	detailed_room_groups.clear()
	art_loaded_groups.clear()
	visual_room_groups.clear()
	for child in room_root.get_children():
		child.queue_free()
	for group in world.visual_groups():
		make_room(group)

func make_sprite_texture(is_manka: bool) -> Texture2D:
	var img := Image.create(96, 144, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for py in range(144):
		for px in range(96):
			var xx := float(px - 48) / 48.0
			var yy := float(py)
			var inside := false
			if is_manka:
				inside = (pow(xx * 1.22, 2.0) + pow((yy - 82.0) / 39.0, 2.0) < 1.0)
				inside = inside or (pow((px - 44.0) / 23.0, 2.0) + pow((yy - 48.0) / 22.0, 2.0) < 1.0)
			else:
				inside = (pow(xx * 1.03, 2.0) + pow((yy - 95.0) / 46.0, 2.0) < 1.0)
				inside = inside or (pow((px - 48.0) / 20.0, 2.0) + pow((yy - 39.0) / 23.0, 2.0) < 1.0)
			if inside:
				var color := Color("#151318") if is_manka else Color("#e6dad3")
				if is_manka and yy < 58 and abs(xx) < 0.40:
					color = Color("#241b27")
				if is_manka and yy > 44 and yy < 49 and abs(xx) > 0.16 and abs(xx) < 0.43:
					color = Color("#9b121e")
				if not is_manka and yy > 58:
					color = Color("#713a4e")
				img.set_pixel(px, py, color)
	return ImageTexture.create_from_image(img)

func make_residents() -> void:
	var resident_tex := make_sprite_texture(false)
	var manka_tex := make_sprite_texture(true)
	for child in actor_root.get_children():
		child.queue_free()
	actor_sprites.clear()
	actor_labels.clear()
	actor_animations.clear()
	var n := 0
	for id in world.residents:
		var actor: Dictionary = world.residents[id]
		if not actor.get("active", false) or actor.get("name", "") == "":
			continue
		var anchor := Node3D.new()
		anchor.name = id
		actor_root.add_child(anchor)
		var sprite := Sprite3D.new()
		sprite.name = "Body"
		sprite.texture = manka_tex if id == "MANJKA" else resident_tex
		sprite.pixel_size = 0.009 if id == "MANJKA" else 0.012
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		actor["runtime_visual_bound"] = false
		if id == "MANJKA" and qa_visual_preview:
			var sprite_manka: Texture2D = asset_banks.manka_texture("IDLE_RIGHT",0)
			if sprite_manka != null:
				sprite.texture = sprite_manka
				sprite.pixel_size = 1.55/maxf(1.0,float(sprite_manka.get_height()))
				sprite.position.y = 0.77
				actor["runtime_visual_bound"] = true
				actor["visual_preview_only"] = true
				actor_animations[id] = {"state":"IDLE_RIGHT","frame":0,"elapsed":0.0}
		if id != "MANJKA":
			var profile_id: String = str(actor.get("appearance_profile",""))
			var chosen_wardrobe: String = asset_banks.preferred_wardrobe(id,profile_id,qa_visual_preview)
			if chosen_wardrobe != "":
				var approved_idle: Texture2D = asset_banks.texture_for(id,chosen_wardrobe,"IDLE_S",0)
				if approved_idle != null:
					sprite.texture = approved_idle
					sprite.pixel_size = 1.9 / maxf(1.0,float(approved_idle.get_height()))
					sprite.position.y = maxf(0.15,
						(asset_banks.feet_anchor(id,chosen_wardrobe,approved_idle.get_height())
						 - float(approved_idle.get_height())*0.5)*sprite.pixel_size)
					actor["runtime_visual_bound"] = true
					actor["visual_wardrobe"] = chosen_wardrobe
					actor["visual_preview_only"] = not asset_banks.verified_bank(id,profile_id,chosen_wardrobe)
					actor_animations[id] = {"state":"IDLE_S","frame":0,"elapsed":0.0}

		if not actor["runtime_visual_bound"]:
			sprite.position = Vector3(0, 0.83 if id == "MANJKA" else 1.05, 0)
		if id != "MANJKA" and not actor["runtime_visual_bound"]:
			var colors = [Color("#bfa4c1"), Color("#dca39e"), Color("#a3aeb3"), Color("#d4b78a"),
				Color("#c6c0c4"), Color("#9b9fbf"), Color("#bc9e97"), Color("#9ab4a9")]
			sprite.modulate = colors[n % colors.size()]
		anchor.add_child(sprite)
		actor_sprites[id] = anchor
		var lbl := label3(anchor, actor["name"], Vector3(0, 2.0, 0.2), 27, Color("#f1ddd0"))
		actor_labels[id] = lbl
		n += 1
	update_residents()

func update_residents(delta: float = 0.0) -> void:
	for id in actor_sprites:
		var actor: Dictionary = world.residents[id]
		var y: float = float(actor.get("visual_y", float(actor.get("level", 0)) * H))
		actor_sprites[id].position = Vector3(float(actor.get("x", 0.0)), y, float(actor.get("z", 0.3)))
		if actor.get("runtime_visual_bound",false):
			if id == "MANJKA":
				animate_manka(actor,delta)
			else:
				animate_verified_actor(id,actor,delta)
		# Names live in the status panel, never stacked over actors or furniture.
		actor_labels[id].visible = false
		if id == follow_id:
			actor_labels[id].text = actor["name"] + " • " + life.status(actor)

func animate_manka(actor: Dictionary, delta: float) -> void:
	var state := "IDLE_LEFT" if str(actor.get("moving_axis","")) == "left" else "IDLE_RIGHT"
	if actor.get("phase","idle") == "travel":
		state = "WALK_LEFT" if str(actor.get("moving_axis","")) == "left" else "WALK_RIGHT"
	elif actor.get("intent","") == "REST" and actor.get("phase","") == "perform":
		state = "REST"
	if asset_banks.manka_frame_count(state) <= 0:
		state = "IDLE_RIGHT"
	var animation: Dictionary = actor_animations.get("MANJKA",{"state":"","frame":0,"elapsed":0.0})
	if animation.get("state","") != state:
		animation = {"state":state,"frame":0,"elapsed":0.0}
	else:
		animation["elapsed"] = float(animation["elapsed"])+minf(delta,0.1)
		var period: float = 1.0/maxf(1.0,asset_banks.manka_fps(state))
		if float(animation["elapsed"]) >= period:
			animation["frame"] = (int(animation["frame"])+int(float(animation["elapsed"])/period)) % maxi(1,asset_banks.manka_frame_count(state))
			animation["elapsed"] = fmod(float(animation["elapsed"]),period)
	actor_animations["MANJKA"] = animation
	var texture: Texture2D = asset_banks.manka_texture(state,int(animation["frame"]))
	var sprite: Sprite3D = actor_sprites["MANJKA"].get_node("Body")
	if texture != null and texture != sprite.texture:
		sprite.texture = texture
		sprite.pixel_size = 1.55/maxf(1.0,float(texture.get_height()))
		sprite.position.y = 0.77

func desired_actor_animation(actor: Dictionary) -> String:
	# Pure pose selection. A sofa station is an actual authored seat, not
	# simply two actors standing at the same arbitrary position in a room.
	var requested := "IDLE_S"
	if zoom_current < 55.0 and actor.get("phase","idle") == "travel":
		var direction: String = str(actor.get("moving_axis",""))
		if direction == "left":
			requested = "WALK_LEFT"
		elif direction == "right":
			requested = "WALK_RIGHT"
	elif zoom_current < 55.0 and actor.get("phase","idle") == "perform":
		var intent: String = str(actor.get("intent",""))
		match intent:
			"READ_BOOK": requested = "READ"
			"REST":
				if str(actor.get("station_kind","")) == "seat":
					requested = str(actor.get("station_pose_hint","RELAXED_SIT"))
			"SLEEP":
				if str(actor.get("station_kind","")) == "seat":
					requested = "SLEEP"
			"TALK_PAIR": requested = "TALK"
			"GET_COFFEE": requested = "DRINK"
			"WATCH_FIRE", "VIEW_ART", "BROWSE_BOOK_CATALOG", "BROWSE_FILMS", "BROWSE_AUDIO":
				requested = "VIEW"
	return requested

func animate_verified_actor(id: String, actor: Dictionary, delta: float) -> void:
	# Visual state does not change life and cannot assume a real chair exists.
	var requested: String = desired_actor_animation(actor)
	var wardrobe: String = str(actor.get("visual_wardrobe","HOME"))
	if asset_banks.frame_count(id,wardrobe,requested) < 1:
		requested = "IDLE_S"
	var state: Dictionary = actor_animations.get(id,{"state":"","frame":0,"elapsed":0.0})
	if state["state"] != requested:
		state["state"] = requested
		state["elapsed"] = 0.0
		state["frame"] = 0
	else:
		state["elapsed"] = float(state["elapsed"])+minf(delta,0.1)
		var period: float = 1.0 / float(asset_banks.fps(id,wardrobe,requested))
		if float(state["elapsed"]) >= period:
			state["frame"] = (int(state["frame"])+int(float(state["elapsed"])/period)) % maxi(1,asset_banks.frame_count(id,wardrobe,requested))
			state["elapsed"] = fmod(float(state["elapsed"]),period)
	actor_animations[id] = state
	var sprite: Sprite3D = actor_sprites[id].get_node("Body")
	var texture: Texture2D = asset_banks.texture_for(id,wardrobe,requested,int(state["frame"]))
	if texture != null and sprite.texture != texture:
		sprite.texture = texture
		sprite.pixel_size = 1.9 / maxf(1.0,float(texture.get_height()))
		sprite.position.y = maxf(0.15,
			(asset_banks.feet_anchor(id,wardrobe,texture.get_height())
			 - float(texture.get_height())*0.5)*sprite.pixel_size)

func build_interface() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	var top := PanelContainer.new()
	top.position = Vector2(12, 12)
	top.custom_minimum_size = Vector2(292, 0)
	root.add_child(top)
	var col := VBoxContainer.new()
	top.add_child(col)
	var header := HBoxContainer.new()
	col.add_child(header)
	hud_title = Label.new()
	hud_title.text = "ДОМ ДРАКОНА"
	header.add_child(hud_title)
	hud_toggle_button = Button.new()
	hud_toggle_button.text = "☰ Меню"
	hud_toggle_button.pressed.connect(toggle_hud)
	header.add_child(hud_toggle_button)
	hud_brief = Label.new()
	hud_brief.text = "Обзор"
	col.add_child(hud_brief)
	hud_main_body = VBoxContainer.new()
	hud_main_body.visible = hud_expanded
	col.add_child(hud_main_body)
	hud_status = Label.new()
	hud_main_body.add_child(hud_status)
	media_label = Label.new()
	hud_main_body.add_child(media_label)
	var controls := HBoxContainer.new()
	hud_main_body.add_child(controls)
	for item in ["Дом", "Комната", "Манька", "Строить"]:
		var button := Button.new()
		button.text = item
		controls.add_child(button)
		match item:
			"Дом": button.pressed.connect(func(): set_mode("HOUSE"))
			"Комната": button.pressed.connect(func(): set_mode("ROOM"))
			"Манька": button.pressed.connect(func(): follow_actor("MANJKA"))
			"Строить": button.pressed.connect(toggle_build)
	menu = OptionButton.new()
	for t in WorldScript.ROOM_TYPES:
		menu.add_item(room_names.get(t, t))
		menu.set_item_metadata(menu.item_count - 1, t)
	menu.select(1)
	menu.item_selected.connect(func(i): build_type = str(menu.get_item_metadata(i)))
	hud_main_body.add_child(menu)
	var media_button := Button.new()
	media_button.text = "Открыть библиотеку / медиа [M]"
	media_button.pressed.connect(toggle_media_panel)
	hud_main_body.add_child(media_button)
	media_panel = MediaPanelScript.new()
	root.add_child(media_panel)
	media_panel.bind(world,life.media_runtime)
	bank_gallery = BankGalleryScript.new()
	root.add_child(bank_gallery)
	bank_gallery.bind(asset_banks,world.read_resident_profiles())
	var gallery_button := Button.new()
	gallery_button.text = "Галерея 24 банков [K]"
	gallery_button.pressed.connect(toggle_bank_gallery)
	hud_main_body.add_child(gallery_button)
	var qa_button := Button.new()
	qa_button.text = "QA-спрайты [V]"
	qa_button.pressed.connect(toggle_qa_art_preview)
	hud_main_body.add_child(qa_button)
	var journal_button := Button.new()
	journal_button.text = "Журнал дома [J]"
	journal_button.pressed.connect(toggle_journal)
	hud_main_body.add_child(journal_button)
	journal_panel = PanelContainer.new()
	journal_panel.position = Vector2(925, 15)
	journal_panel.custom_minimum_size = Vector2(335, 240)
	journal_panel.visible = false
	root.add_child(journal_panel)
	journal_text = Label.new()
	journal_text.custom_minimum_size = Vector2(310, 220)
	journal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_panel.add_child(journal_text)
	var import_button := Button.new()
	import_button.text = "Импорт книг / фильмов / музыки (JSON)"
	import_button.pressed.connect(func(): catalog_picker.popup_centered_ratio(0.65))
	hud_main_body.add_child(import_button)
	hud_help = Label.new()
	hud_help.text = "Колесо: масштаб | ПКМ: перемещение\nЛКМ: выбрать | Q/E: поворот\nF: следить | B: строить | Esc: весь дом\nV: QA-спрайты | M: медиа | J: журнал"
	hud_main_body.add_child(hud_help)
	hud_help.visible = false
	var help_button := Button.new()
	help_button.text = "Управление [?]"
	help_button.pressed.connect(func(): hud_help.visible = not hud_help.visible)
	hud_main_body.add_child(help_button)
	notice = Label.new()
	notice.position = Vector2(18, 690)
	notice.add_theme_color_override("font_color", Color("#eac59d"))
	root.add_child(notice)
	catalog_picker = FileDialog.new()
	catalog_picker.access = FileDialog.ACCESS_FILESYSTEM
	catalog_picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	catalog_picker.add_filter("*.json", "Media catalog JSON")
	catalog_picker.file_selected.connect(_import_media)
	root.add_child(catalog_picker)
	update_hud()

func _import_media(path: String) -> void:
	if world.import_catalog(path):
		life.media_runtime.setup(world)
		media_panel.refresh()
		notice.text = "Медиатека импортирована: " + path.get_file()
	else:
		notice.text = "Ошибка каталога: нужен JSON с books/films/tracks (id, title)"
	update_hud()

func toggle_hud() -> void:
	hud_expanded = not hud_expanded
	if hud_main_body != null:
		hud_main_body.visible = hud_expanded
	if hud_toggle_button != null:
		hud_toggle_button.text = "Скрыть ▲" if hud_expanded else "☰ Меню"

func toggle_bank_gallery() -> void:
	if bank_gallery == null:
		return
	bank_gallery.visible = not bank_gallery.visible
	if bank_gallery.visible:
		bank_gallery.refresh()

func toggle_qa_art_preview() -> void:
	qa_visual_preview = not qa_visual_preview
	make_residents()
	update_hud()
	if notice != null:
		notice.text = "Визуальные банки: QA-ПРОСМОТР" if qa_visual_preview else "Визуальные банки: только утверждённые"

func toggle_media_panel() -> void:
	if media_panel.visible:
		media_panel.close_panel()
	else:
		media_panel.open_panel()

func toggle_journal() -> void:
	journal_open = not journal_open
	journal_panel.visible = journal_open
	if journal_open:
		update_journal()

func update_journal() -> void:
	if journal_text == null:
		return
	var last: Array = life.log.slice(maxi(0, life.log.size() - 11))
	journal_text.text = "ЖУРНАЛ ДОМА\n\n" + "\n".join(last)

func camera_world_bounds() -> Rect2:
	var lo := Vector2(99999,99999)
	var hi := Vector2(-99999,-99999)
	for room in world.rooms:
		var pos := Vector2(float(room["x"]) * W, float(room["level"]) * H)
		lo.x = minf(lo.x,pos.x - W * 0.5)
		lo.y = minf(lo.y,pos.y - H * 0.5)
		hi.x = maxf(hi.x,pos.x + W * 0.5)
		hi.y = maxf(hi.y,pos.y + H * 0.5)
	return Rect2(lo,hi-lo)

func fit_house_camera() -> void:
	var bounds: Rect2 = camera_world_bounds()
	var size: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = maxf(1.0, size.x / maxf(1.0,size.y))
	var angle: float = deg_to_rad(camera.fov * 0.5)
	var vertical_dist: float = (bounds.size.y + 2.0) / maxf(0.1, 2.0 * tan(angle))
	var horizontal_dist: float = (bounds.size.x + 3.0) / maxf(0.1, 2.0 * aspect * tan(angle))
	zoom = clampf(maxf(horizontal_dist,vertical_dist)*1.12, 12.0, 110.0)
	desired_focus = Vector3(bounds.get_center().x,bounds.get_center().y,0.0)

func update_selection_outline() -> void:
	if selected_outline == null:
		return
	for child in selected_outline.get_children():
		child.queue_free()
	selected_outline.visible = false
	if selected_room == "" or current_mode != "ROOM":
		return
	var room: Dictionary = world.room_by_id(selected_room)
	if room.is_empty():
		return
	var group: Dictionary = world.merged_group(int(room["x"]),int(room["level"]))
	if group.is_empty():
		return
	var cx: float = (float(group["x_start"])+float(group["x_end"]))*0.5*W
	var length: float = float(group["width"])*W
	selected_outline.position = Vector3(cx,float(room["level"])*H,0.0)
	var tone := Color("#e8b875")
	box(selected_outline,Vector3(0,-0.08,1.92),
		Vector3(length,0.065,0.08),tone,true)
	box(selected_outline,Vector3(0,3.03,1.92),
		Vector3(length,0.065,0.08),tone,true)
	for side in [-1,1]:
		box(selected_outline,Vector3(float(side)*length*0.5,1.48,1.92),
			Vector3(0.075,3.15,0.08),tone,true)
	selected_outline.visible = true

func set_mode(mode: String) -> void:
	Engine.max_fps = 30 if mode == "HOUSE" else 60
	build_mode = false
	if build_marker:
		build_marker.visible = false
	current_mode = mode
	match mode:
		"HOUSE":
			fit_house_camera()
			follow_id = ""
		"ROOM":
			zoom = 10.5
			follow_id = ""
			if selected_room != "":
				var r: Dictionary = world.room_by_id(selected_room)
				if not r.is_empty():
					var group: Dictionary = world.merged_group(int(r["x"]),int(r["level"]))
					var cx: float = (float(group["x_start"])+float(group["x_end"]))*0.5*W
					desired_focus = Vector3(cx,float(r["level"])*H+1.1,0.0)
					zoom = 10.5 + maxf(0.0,float(group["width"]-1))*3.4
		"FOLLOW":
			zoom = 16.0
	update_selection_outline()
	update_hud()
	update_render_lod()

func follow_actor(id: String) -> void:
	if not actor_sprites.has(id):
		return
	follow_id = id
	current_mode = "FOLLOW"
	Engine.max_fps = 60
	build_mode = false
	update_selection_outline()
	zoom = minf(zoom, 20.0)
	update_hud()

func toggle_build() -> void:
	build_mode = not build_mode
	if build_mode:
		follow_id = ""
		current_mode = "BUILD"
		Engine.max_fps = 60
		update_selection_outline()
		if zoom < 16.0:
			zoom = 22.0
		if build_marker == null:
			build_marker = MeshInstance3D.new()
			var cube := BoxMesh.new()
			cube.size = Vector3(W * 0.9, 2.9, 3.9)
			build_marker.mesh = cube
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.22, 0.9, 0.55, 0.27)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			build_marker.material_override = material
			add_child(build_marker)
		build_marker.visible = true
	elif build_marker:
		build_marker.visible = false
	update_hud()

func update_hud() -> void:
	if hud_status == null:
		return
	var tracked: Dictionary = world.residents.get(follow_id, {})
	hud_status.text = "Режим: %s | комнат: %d | видимых: %d / 24" % [
		current_mode, world.rooms.size(), actor_sprites.size()-1]
	if hud_brief != null:
		hud_brief.text = "%s · %d комнат · %d/24" % [
			current_mode,world.rooms.size(),maxi(0,actor_sprites.size()-1)]
	hud_status.text += "\nУтверждено: %d / 24 | технически: %d" % [validated_visual_banks,preview_visual_banks]
	if qa_visual_preview:
		hud_status.text += "\nВИД: QA-ПРОСМОТР (не утверждено)"
	if not tracked.is_empty():
		hud_status.text += "\nСлежение: %s — %s" % [tracked.get("name", "?"), life.status(tracked)]
	if current_mode == "ROOM" and selected_room != "":
		var r: Dictionary = world.room_by_id(selected_room)
		if not r.is_empty():
			var merged: int = world.merged_run_length(int(r["x"]),int(r["level"]))
			hud_status.text += "\n%s  R%d  |  уровень %d" % [
				room_names.get(r["type"],r["type"]),merged,int(r["level"])]
			var group: Dictionary = world.merged_group(int(r["x"]),int(r["level"]))
			if r.get("privacy","public") == "public":
				var occupied := 0
				var capacity := 0
				for cell in group.get("cells",[]):
					occupied += life.stations.used_slots(world,str(cell["id"])).size()
					capacity += life.stations.capacity(cell)
				hud_status.text += "\nМеста действий: %d / %d" % [occupied,capacity]
	media_label.text = "Книги: %d  •  Фильмы: %d  •  Музыка: %d" % [
		world.media.get("books", []).size(), world.media.get("films", []).size(),
		world.media.get("tracks", []).size()]

func ray_to_front_plane(mouse: Vector2) -> Variant:
	var start: Vector3 = camera.project_ray_origin(mouse)
	var direction: Vector3 = camera.project_ray_normal(mouse)
	if absf(direction.z) < 0.0001:
		return null
	var distance: float = (0.25 - start.z) / direction.z
	if distance < 0:
		return null
	return start + direction * distance

func zoom_around_pointer(mouse: Vector2, multiplier: float) -> void:
	# Shelter-style anchoring: keep the world point under the cursor stable
	# while zooming the camera. Following a resident takes precedence.
	var old_zoom: float = zoom
	var new_zoom: float = clampf(old_zoom*multiplier,4.5,110.0)
	if is_equal_approx(new_zoom,old_zoom):
		return
	if follow_id == "":
		var target = ray_to_front_plane(mouse)
		if target != null:
			var ratio: float = new_zoom / old_zoom
			desired_focus.x = float(target.x) - (float(target.x)-desired_focus.x)*ratio
			desired_focus.y = float(target.y) - (float(target.y)-desired_focus.y)*ratio
	zoom = new_zoom

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			zoom_around_pointer(e.position,0.87)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			zoom_around_pointer(e.position,1.15)
		elif e.button_index == MOUSE_BUTTON_RIGHT:
			moving_view = e.pressed
	if event is InputEventMouseMotion:
		var e: InputEventMouseMotion = event
		if moving_view and not build_mode:
			follow_id = "" # moving away manually cancels Follow
			current_mode = "FREE"
			Engine.max_fps = 60
			var scale: float = zoom_current * 0.0019
			desired_focus.x -= e.relative.x * scale
			desired_focus.y += e.relative.y * scale
		elif build_mode:
			var hit = ray_to_front_plane(e.position)
			if hit != null:
				build_cell = Vector2i(roundi(hit.x / W), roundi(hit.y / H))
				build_marker.position = world.world_pos(build_cell.x, build_cell.y) + Vector3(0, 1.4, 0)
				var permitted := world.can_build(build_cell.x, build_cell.y, build_type)
				var preview_mat: StandardMaterial3D = build_marker.material_override
				preview_mat.albedo_color = Color(0.22,0.90,0.55,0.28) if permitted else Color(0.82,0.23,0.26,0.28)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_T:
				if teea_qa_enabled:
					teea_qa_toggle()
			KEY_C:
				if teea_qa_enabled:
					teea_qa_focus(-1)
			KEY_L:
				if teea_qa_enabled:
					teea_qa_focus(2)
			KEY_S:
				if teea_qa_enabled:
					teea_qa_focus(-3)
			KEY_R:
				if teea_qa_enabled:
					teea_qa_focus(1)
			KEY_ESCAPE: set_mode("HOUSE")
			KEY_F: follow_actor("MANJKA")
			KEY_B: toggle_build()
			KEY_Q: yaw = clampf(yaw - 0.10, -0.34, 0.34)
			KEY_E: yaw = clampf(yaw + 0.10, -0.34, 0.34)
			KEY_J: toggle_journal()
			KEY_M: toggle_media_panel()
			KEY_V: toggle_qa_art_preview()
			KEY_K: toggle_bank_gallery()
			KEY_TAB: toggle_hud()
			KEY_1: set_mode("HOUSE")
			KEY_2: set_mode("ROOM")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.button_index != MOUSE_BUTTON_LEFT or not e.pressed:
			return
		if build_mode:
			if build_cell == Vector2i(99,99):
				return
			if world.build(build_cell.x, build_cell.y, build_type):
				make_rooms()
				update_render_lod()
				notice.text = "Построено: %s (%d, %d)" % [
					room_names.get(build_type, build_type), build_cell.x, build_cell.y]
			else:
				notice.text = "Нет связного свободного участка"
			update_hud()
			return
		# Selection is by projected actor positions, independent of camera tracking.
		var nearest := ""
		var best := 39.0
		for id in actor_sprites:
			var anchor: Node3D = actor_sprites[id]
			if camera.is_position_behind(anchor.global_position + Vector3.UP):
				continue
			var screen: Vector2 = camera.unproject_position(anchor.global_position + Vector3.UP)
			var d: float = screen.distance_to(e.position)
			if d < best:
				best = d
				nearest = id
		if nearest != "":
			follow_actor(nearest)
			return
		var hit = ray_to_front_plane(e.position)
		if hit != null:
			var room: Dictionary = world.get_room(roundi(hit.x / W), roundi(hit.y / H))
			if not room.is_empty():
				selected_room = room["id"]
				if room["privacy"] == "door_only":
					notice.text = "Личная территория: камера остаётся у двери"
				else:
					notice.text = room_names.get(room["type"], room["type"])
				set_mode("ROOM")

func effective_camera_yaw() -> float:
	# A gentle Shelter-like oblique cutaway shows the rear and side depth
	# of the 3D room at close zoom, then fades back to a readable flat
	# overview. Q/E remains an additive *manual* adjustment.
	var close_bias: float=clampf((48.0-zoom_current)/34.0,0.0,1.0)*0.115
	return clampf(yaw+close_bias,-0.38,0.38)

func apply_camera(delta: float) -> void:
	if follow_id != "" and world.residents.has(follow_id):
		var actor: Dictionary = world.residents[follow_id]
		var target_room: Dictionary = world.room_by_id(actor.get("room_id", ""))
		if not target_room.is_empty() and world.allows_transit(target_room):
			var target := Vector3(float(actor.get("x", 0)),
				float(actor.get("visual_y", float(actor.get("level", 0))*H)) + 1.05,
				float(actor.get("z", 0)))
			var half_height: float = tan(deg_to_rad(camera.fov*0.5))*zoom_current
			var aspect: float = get_viewport().get_visible_rect().size.aspect()
			var deadzone_x: float = half_height * aspect * follow_deadzone_ratio
			var deadzone_y: float = half_height * follow_deadzone_ratio
			if absf(target.x - desired_focus.x) > deadzone_x:
				desired_focus.x = target.x - signf(target.x - desired_focus.x)*deadzone_x
			if absf(target.y - desired_focus.y) > deadzone_y:
				desired_focus.y = target.y - signf(target.y - desired_focus.y)*deadzone_y
		# The follow target may reach a private room, but camera will not cross its threshold.
	var bounds: Rect2 = camera_world_bounds()
	var edge_padding := Vector2(W*1.2,H*1.0)
	desired_focus.x = clampf(desired_focus.x,bounds.position.x-edge_padding.x,
		bounds.end.x+edge_padding.x)
	desired_focus.y = clampf(desired_focus.y,bounds.position.y-edge_padding.y,
		bounds.end.y+edge_padding.y)
	var k: float = 1.0 - exp(-4.0 * minf(delta,0.25))
	smooth_focus = smooth_focus.lerp(desired_focus,k)
	zoom_current = lerpf(zoom_current,zoom,1.0-exp(-4.6*minf(delta,0.25)))
	var view_yaw: float=effective_camera_yaw()
	var x_shift := sin(view_yaw) * zoom_current
	var z_shift := cos(view_yaw) * zoom_current
	camera.global_position = smooth_focus + Vector3(x_shift,zoom_current*0.19,z_shift)
	camera.look_at(smooth_focus,Vector3.UP)

func update_render_lod() -> void:
	# Keep cutaway shell/cues visible, materialize nearby details on demand.
	# The camera never activates an owner-private interior.
	for group_node in room_root.get_children():
		var furniture: Node3D = group_node.get_node_or_null("LocalFurniture")
		var cues: Node3D = group_node.get_node_or_null("Layer_OverviewCues")
		if furniture != null:
			var near: bool = _is_near_detail(group_node)
			if near:
				_load_room_art(group_node)
				_populate_furniture(group_node)
			else:
				_release_room_art(group_node)
				_release_furniture(group_node)
			furniture.visible = near
			if cues != null:
				cues.visible = not near
		var roof_label: Label3D = group_node.get_node_or_null("RoomRoofLabel")
		if roof_label != null:
			roof_label.visible = zoom_current >= 35.0 and current_mode != "FOLLOW"
	var micro_detail_visible: bool = zoom_current < 31.0
	for node in get_tree().get_nodes_in_group("low_end_micro_detail"):
		if node is Node3D:
			node.visible = micro_detail_visible

func _process(delta: float) -> void:
	# The camera never chooses activities. Life is a separate simulation clock.
	life.tick(delta)
	update_residents(delta)
	apply_camera(delta)
	save_timer += delta
	if save_timer > 20.0:
		world.save_world()
		save_timer = 0.0
	if Engine.get_process_frames() % 40 == 0:
		update_hud()
		update_render_lod()
		if journal_open:
			update_journal()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		world.save_world()
		get_tree().quit()

