extends Node3D
## Fresh Godot 4.7.2 cutaway world. Geometry and presentation only;
## room truth + autonomous life are independent of the camera.
const WorldScript = preload("res://scripts/world_model.gd")
const LifeScript = preload("res://scripts/life.gd")
const MediaPanelScript = preload("res://scripts/media_station_ui.gd")
const ContentViewerScript = preload("res://scripts/content_viewer.gd")
const AssetBankResolverScript = preload("res://scripts/asset_bank_resolver.gd")
const InteriorSkinScript = preload("res://scripts/interior_skin.gd")
const RoomVisualLayoutScript = preload("res://scripts/room_visual_layout_v2.gd")
const BankGalleryScript = preload("res://scripts/asset_gallery_ui.gd")
const PrivateDoorRegistryScript = preload("res://scripts/private_door_registry.gd")
const SemanticViewScript = preload("res://scripts/semantic_view_v019.gd")
const CandidateContentRuntimeScript = preload("res://scripts/candidate_content_runtime.gd")
const ITER1_REVIEW_MARKER := "res://data/integration_candidates/ITER1_OWNER_REVIEW.enabled"
const W := 4.8
const H := 4.6
var world = WorldScript.new()
var life = LifeScript.new()
var asset_banks = AssetBankResolverScript.new()
var interior_skin = InteriorSkinScript.new()
var room_visual_layout = RoomVisualLayoutScript.new()
var door_registry = PrivateDoorRegistryScript.new()
var semantic_view = SemanticViewScript.new()
var candidate_content = CandidateContentRuntimeScript.new()
var iter1_owner_review := false
var art_layer_count := 0
var detailed_room_groups: Dictionary = {}
var art_loaded_groups: Dictionary = {}
var visual_room_groups: Dictionary = {}
var detail_materialization_count := 0
var detail_eviction_count := 0
var validated_visual_banks := 0
var qa_visual_preview := false
var preview_visual_banks := 0
var actor_animations: Dictionary = {}
var camera: Camera3D
var room_root: Node3D
var actor_root: Node3D
var creature_root: Node3D
var creature_nodes: Dictionary = {}
var creature_labels: Dictionary = {}
var creature_animations: Dictionary = {}
var object_root: Node3D
var object_nodes: Dictionary = {}
var actor_sprites: Dictionary = {}
var actor_labels: Dictionary = {}
var door_note_anchors: Dictionary = {}
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
var build_size := 1
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
var content_viewer: PanelContainer
var content_hover_label: Label
var content_hotspots: Array = []
var bank_gallery: PanelContainer
var door_note_panel: PanelContainer
var door_note_title: Label
var door_note_text: RichTextLabel
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
	"workshop": "Мастерская", "private": "Личная дверь", "guest": "Гостевая",
	"lift": "Подъёмник", "artifact": "Артефакты"
}

func _ready() -> void:
	Engine.max_fps = 30 # Low-end hardware baseline; detail modes can unlock 60.
	iter1_owner_review = FileAccess.file_exists(ITER1_REVIEW_MARKER)
	if iter1_owner_review:
		world.save_path = "user://dragon_house_iter1_owner_review.json"
	world.load_or_seed()
	if iter1_owner_review:
		if candidate_content.initialize():
			var guest_review_result: Dictionary = candidate_content.apply_guest_candidate(world)
			if not bool(guest_review_result.get("ok",false)):
				push_warning("Iteration-1 guest candidate activation failed: "+str(guest_review_result))
		else:
			push_warning("Iteration-1 candidate contract could not be initialized: "+candidate_content.last_error)
	semantic_view.install(world,"HOUSE")
	asset_banks.initialize()
	if iter1_owner_review:
		_register_iter1_review_creatures()
	# Metadata is not a physical book or a movie/audio file.
	if not asset_banks.manifest.is_empty():
		catalog_metadata_added = world.merge_reference_book_metadata(
			asset_banks.manifest.get("media_previews",{}).get("books",[]))
	life.setup(world)
	interior_skin.initialize()
	if not room_visual_layout.initialize():
		push_warning("Physical room visual layout unavailable: "+room_visual_layout.error)
	door_registry.initialize()
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
	creature_root = Node3D.new()
	creature_root.name = "AmbientCreatures"
	add_child(creature_root)
	object_root = Node3D.new()
	object_root.name = "PhysicalObjects"
	add_child(object_root)
	make_rooms()
	make_residents()
	build_interface()
	make_creatures()
	make_physical_objects()
	fit_house_camera()
	smooth_focus = desired_focus
	zoom_current = zoom
	apply_camera(0.1)
	update_render_lod()
	notice.text = ("ITER1 OWNER REVIEW · candidate art/guests/fauna · approved=false"
		if iter1_owner_review else
		"Независимый прототип: камера, постройка, автономная жизнь")

func _first_public_room_id(room_type: String) -> String:
	for room in world.rooms:
		if str(room.get("type","")) == room_type and str(room.get("privacy","public")) == "public":
			return str(room.get("id",""))
	return ""

func _register_iter1_review_creatures() -> void:
	var specs := [
		{"id":"CREATURE_SHURSHUN","name":"Шуршун","bank":"npc_cat_black_hero","owner":"RES_03","room":"common"},
		{"id":"CREATURE_CAT_CALICO_REVIEW","name":"Кошка","bank":"npc_cat_calico","owner":"","room":"rest"},
		{"id":"CREATURE_MOUSE_GRAY_REVIEW","name":"Мышь","bank":"npc_mouse_gray","owner":"","room":"library"},
		{"id":"CREATURE_RAT_HERO_REVIEW","name":"Крыса","bank":"npc_rat_hero","owner":"","room":"study"},
		{"id":"CREATURE_HEDGEHOG_REVIEW","name":"Ёж","bank":"npc_hedgehog_01","owner":"","room":"arrival"},
		{"id":"CREATURE_AI_SPHERE_REVIEW","name":"Сфера","bank":"npc_ai_magic_sphere","owner":"","room":"artifact"}
	]
	var changed := false
	for spec in specs:
		var creature_id := str(spec["id"])
		if world.creatures.has(creature_id):
			continue
		var bank_id := str(spec["bank"])
		if not asset_banks.candidate_creature_bank(bank_id):
			push_warning("Iteration-1 creature bank failed validation: "+bank_id)
			continue
		var room_id := _first_public_room_id(str(spec["room"]))
		if room_id == "":
			continue
		if world.register_creature(creature_id,str(spec["name"]),room_id,bank_id,
				str(spec["owner"]),false,false,false):
			changed = true
	if changed:
		world.save_world()

func _review_room_art_type(group: Dictionary) -> String:
	var room_type := str(group.get("type",""))
	if not iter1_owner_review or room_type != "guest":
		return room_type
	var cells: Array = group.get("cells",[])
	if cells.size() != 1:
		return room_type
	match str(cells[0].get("candidate_room_id","")):
		"guest_centaur_01":
			return "guest_centaur"
		"guest_vampire_01":
			return "guest_vampire"
		"guest_miu_01":
			return "guest_miu"
	return room_type

func _creature_canvas_width(bank_id: String) -> float:
	if bank_id.contains("mouse"):
		return 0.65
	if bank_id.contains("rat"):
		return 0.85
	if bank_id.contains("hedgehog"):
		return 0.85
	if bank_id.contains("cat"):
		return 1.20
	if bank_id.contains("sphere"):
		return 0.95
	return 1.0

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

func _texture_from_source(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var loaded = load(path)
		if loaded is Texture2D:
			return loaded
	if FileAccess.file_exists(path):
		var image := Image.new()
		if image.load(path) == OK:
			return ImageTexture.create_from_image(image)
	return null

func make_mountain() -> void:
	# Tiled original basalt atlas behind the cutaway, not rectangular checkerboard.
	var shell := Node3D.new()
	shell.name = "MountainMassBehindRooms"
	add_child(shell)
	var rock := box(shell, Vector3(-0.5, -1.0, -5.6), Vector3(83, 26, 0.8), Color("#6f696a"))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#655d5e")
	material.albedo_texture = _texture_from_source("res://assets/textures/basalt.jpg")
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
	# One continuous rear wall per physical room. R2/R3 are not three
	# architectural bays stitched together; only outer returns frame the volume.
	var kind:String=str(group["type"])
	if kind in ["private","lift"]:
		return
	var span:float=float(group["width"])*W
	var base_color:=Color("#4a4143")
	match kind:
		"common": base_color=Color("#514046")
		"library","artifact": base_color=Color("#433739")
		"cinema": base_color=Color("#26242b")
		"study","workshop": base_color=Color("#554843")
		"music": base_color=Color("#403842")
		"rest": base_color=Color("#51473f")
	var rear:=Node3D.new()
	rear.name="PhysicalRearWall"
	parent.add_child(rear)
	box(rear,Vector3(0,1.49,-1.78),Vector3(span-0.42,2.67,0.08),base_color)
	box(rear,Vector3(-span*0.5+0.16,1.47,-1.59),
		Vector3(0.18,2.76,0.24),palette["rock_light"])
	box(rear,Vector3(span*0.5-0.16,1.47,-1.59),
		Vector3(0.18,2.76,0.24),palette["rock_light"])
	box(rear,Vector3(0,2.83,-1.58),Vector3(span-0.36,0.15,0.25),palette["border"])
	box(rear,Vector3(0,0.19,-1.55),Vector3(span-0.48,0.31,0.27),palette["border"])
	if ["common","rest","study","library","arrival"].has(kind):
		var lamp_count:int=1 if int(group["width"])==1 else int(group["width"])
		for i in range(lamp_count):
			var px:float=0.0 if lamp_count==1 else lerpf(
				-span*0.5+1.45,span*0.5-1.45,float(i)/float(lamp_count-1))
			box(rear,Vector3(px,2.22,-1.41),
				Vector3(0.09,0.34,0.10),palette["bronze"])
			box(rear,Vector3(px,2.43,-1.33),
				Vector3(0.15,0.14,0.09),Color("#b17c55"),true)

func add_cutaway_depth(parent: Node3D, group: Dictionary) -> void:
	# One continuous X/Z floor volume. Depth markers span the entire physical
	# room and therefore cannot read as per-module separators.
	var kind:String=str(group["type"])
	if kind in ["private","lift"]:
		return
	var span:float=float(group["width"])*W
	var volume:=Node3D.new()
	volume.name="PhysicalDepthVolume"
	parent.add_child(volume)
	for z in [-1.19,0.18,1.10]:
		box(volume,Vector3(0,-0.004,float(z)),
			Vector3(maxf(0.5,span-0.52),0.014,0.018),Color("#3f3637"))
	box(volume,Vector3(0,-0.09,1.31),
		Vector3(maxf(0.5,span-0.34),0.055,0.11),palette["rock_light"])
	for side in [-1.0,1.0]:
		box(volume,Vector3(side*(span*0.5-0.18),0.14,1.28),
			Vector3(0.10,0.26,0.14),palette["rock_light"])
	box(volume,Vector3(0,1.47,-1.87),
		Vector3(maxf(0.5,span-0.86),2.24,0.09),Color("#393234"))
	box(volume,Vector3(0,0.34,-1.74),
		Vector3(maxf(0.5,span-0.82),0.18,0.18),palette["wood"])

func add_room_overview_cues(parent: Node3D, group: Dictionary) -> void:
	# Cheap room identity at distant zoom, but still one physical composition.
	var kind:String=str(group["type"])
	if kind=="private":
		return
	var span:float=float(group["width"])*W
	var width:int=int(group["width"])
	var root:=Node3D.new()
	root.name="OverviewPhysicalRoom"
	parent.add_child(root)
	match kind:
		"common","rest":
			box(root,Vector3(0,0.10,-0.35),
				Vector3(maxf(1.8,span*0.62),0.035,2.18),palette["rug"])
			box(root,Vector3(-span*0.18,0.48,-0.86),
				Vector3(maxf(1.4,span*0.34),0.58,0.64),palette["couch"])
		"library","artifact":
			box(root,Vector3(0,1.16,-1.70),
				Vector3(maxf(2.8,span*0.72),1.80,0.22),palette["wood"])
			box(root,Vector3(0,0.48,0.28),
				Vector3(maxf(1.0,span*0.28),0.35,0.72),palette["wood"])
		"cinema":
			box(root,Vector3(0,1.65,-1.74),
				Vector3(maxf(2.5,span*0.62),1.42,0.15),palette["black"])
			box(root,Vector3(0,1.65,-1.63),
				Vector3(maxf(2.16,span*0.56),1.10,0.07),palette["screen"],true)
			box(root,Vector3(0,0.45,0.78),
				Vector3(maxf(2.4,span*0.50),0.58,0.66),palette["couch"])
		"music":
			for side in [-1.0,1.0]:
				box(root,Vector3(side*span*0.25,1.09,-1.67),
					Vector3(0.62,1.40,0.24),palette["black"])
			box(root,Vector3(0,0.68,-1.05),
				Vector3(maxf(1.25,span*0.24),0.17,0.75),palette["wood"])
		"study","workshop":
			box(root,Vector3(0,0.66,-1.26),
				Vector3(maxf(2.72,span*0.62),0.18,0.66),palette["wood"])
		"arrival":
			box(root,Vector3(-span*0.22,1.20,-1.67),
				Vector3(0.10,2.15,0.12),palette["bronze"])
			box(root,Vector3(span*0.18,0.25,-1.50),
				Vector3(maxf(1.2,span*0.30),0.50,0.40),palette["wood"])
		"lift":
			box(root,Vector3(0,0.06,-0.35),
				Vector3(maxf(3.5,span-0.6),0.08,3.1),palette["copper"])
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

func register_art_foreground(group_node: Node3D) -> void:
	var layer:Node3D=group_node.get_node_or_null("Layer_ApprovedArt")
	if layer==null or camera==null:
		return
	var fg:Sprite3D=layer.get_node_or_null("Art_foreground")
	var reference:Sprite3D=layer.get_node_or_null("Art_furniture_back")
	if fg==null or reference==null or not fg.has_meta("physical_z"):
		return
	var target_z:float=float(fg.get_meta("physical_z"))
	var camera_local:Vector3=group_node.to_local(camera.global_position)
	var denominator:float=reference.position.z-camera_local.z
	if absf(denominator)<0.001:
		return
	var k:float=(target_z-camera_local.z)/denominator
	if k<=0.0 or k>2.0:
		return
	fg.position=Vector3(
		camera_local.x+(reference.position.x-camera_local.x)*k,
		camera_local.y+(reference.position.y-camera_local.y)*k,
		target_z)
	fg.scale=Vector3(k,k,1.0)

func register_loaded_foregrounds() -> void:
	if room_root==null:
		return
	for group_node in room_root.get_children():
		if art_loaded_groups.has(group_node.name):
			register_art_foreground(group_node)

func _load_room_art(group_node: Node3D) -> void:
	if art_loaded_groups.has(group_node.name):
		return
	var group: Dictionary=visual_room_groups.get(group_node.name,{})
	if not bool(group.get("has_art",false)):
		return
	var layer: Node3D=group_node.get_node_or_null("Layer_ApprovedArt")
	if layer==null:
		return
	var art_type := str(group.get("art_type",group["type"]))
	var count: int=interior_skin.add_layers(layer,art_type,
		int(group["width"]),float(group["width"])*W)
	if count>0:
		art_loaded_groups[group_node.name]=count
		art_layer_count+=count
		register_art_foreground(group_node)
		# Hide only the old rear panels when a real accepted backdrop is mounted.
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
			child.queue_free()
	var stage:Node3D=group_node.get_node_or_null("Layer_Background/Stage_Backwall")
	if stage!=null:
		stage.visible=true

func _group_facade_only(group: Dictionary) -> bool:
	var cells: Array = group.get("cells",[])
	if cells.is_empty():
		return false
	return not world.public_cutaway_allowed(cells[0])

func _ensure_fallback_anchor_furniture(module: Node3D, anchors: Array) -> void:
	# Approved furniture_back art carries the visible furniture itself and uses
	# invisible named anchors. When that art is unavailable/rejected (including
	# an LFS pointer instead of real image bytes), procedural fallback must still
	# keep the data-owned interaction contract truthful: every advertised
	# furniture_id has one visible proxy object in this room module.
	var created: Dictionary = {}
	for raw in anchors:
		if typeof(raw)!=TYPE_DICTIONARY:
			continue
		var anchor: Dictionary=raw
		var object_id:String=str(anchor.get("furniture_id",""))
		if object_id=="" or module.get_node_or_null(object_id)!=null or created.has(object_id):
			continue
		var object:=furniture_object(module,object_id)
		var x:float=float(anchor.get("x",0.0))
		var z:float=float(anchor.get("z",0.0))
		match str(anchor.get("kind","standing")):
			"seat","floor_rest":
				# Low seat + back. Anchor is the pelvis/interaction position.
				box(object,Vector3(x,0.28,z),Vector3(0.64,0.42,0.58),palette["wood"])
				box(object,Vector3(x,0.70,z-0.24),Vector3(0.64,0.72,0.12),palette["wood"])
			"work":
				# Work anchor is in front of the work surface; keep the proxy
				# behind the resident's approach aisle.
				box(object,Vector3(x,0.72,z-0.38),Vector3(1.15,0.16,0.66),palette["wood"])
				box(object,Vector3(x-0.47,0.37,z-0.38),Vector3(0.12,0.70,0.48),palette["wood"])
				box(object,Vector3(x+0.47,0.37,z-0.38),Vector3(0.12,0.70,0.48),palette["wood"])
			_:
				# Standing/view anchors point at an object rather than a seat.
				box(object,Vector3(x,0.66,z-0.48),Vector3(0.62,1.20,0.34),palette["wood"])
		created[object_id]=true

func _proxy_authored_object(parent: Node3D, item: Dictionary) -> void:
	var id:String=str(item.get("id","visual_object"))
	var node:=furniture_object(parent,id)
	var x:float=float(item.get("x",0.0))
	var z:float=float(item.get("z",-1.0))
	node.position=Vector3(x,0.0,z)
	var scale_value:float=maxf(0.25,float(item.get("scale",0.7)))
	var asset:String=str(item.get("asset",item.get("type",""))).to_lower()
	if asset.contains("chair") or asset.contains("lounge"):
		box(node,Vector3(0,0.27,0),Vector3(0.62*scale_value,0.42,0.58),palette["wood"])
		box(node,Vector3(0,0.70,-0.24),Vector3(0.62*scale_value,0.70,0.12),palette["wood"])
	elif asset.contains("shelf") or asset.contains("bookshelf"):
		add_shelf(node,Vector3(0,0.12,0),maxf(0.9,1.9*scale_value))
	elif asset.contains("day_bed") or asset.contains("sofa"):
		add_sofa(node,Vector3.ZERO,maxf(1.2,2.8*scale_value),palette["couch"])
	elif asset.contains("lamp"):
		box(node,Vector3(0,0.58,0),Vector3(0.08,1.10,0.08),palette["bronze"])
		box(node,Vector3(0,1.15,0),Vector3(0.32,0.18,0.28),Color("#b17c55"),true)
	else:
		box(node,Vector3(0,0.42,0),
			Vector3(maxf(0.48,1.05*scale_value),0.78,maxf(0.30,0.62*scale_value)),
			palette["wood"])

func _proxy_authored_procedural(parent: Node3D, item: Dictionary) -> void:
	var id:String=str(item.get("id","visual_procedural"))
	var node:=furniture_object(parent,id)
	var width:float=maxf(0.35,float(item.get("width",1.0)))
	var depth:float=maxf(0.25,float(item.get("depth",0.6)))
	var height:float=maxf(0.06,float(item.get("height",0.72)))
	var x:float=float(item.get("x",0.0))
	var z:float=float(item.get("z",-1.0))
	node.position=Vector3(x,0.0,z)
	var kind:String=str(item.get("type",""))
	if kind.contains("rest_pad"):
		box(node,Vector3(0,height*0.5,0),Vector3(width,height,depth),palette["rug"])
	else:
		box(node,Vector3(0,height*0.5,0),Vector3(width,height,depth),palette["wood"])

func _populate_physical_fallback(parent: Node3D, group: Dictionary) -> bool:
	var kind:String=str(group["type"])
	var width:int=int(group["width"])
	if not room_visual_layout.has_variant(kind,width):
		return false
	for raw in room_visual_layout.objects(kind,width):
		if typeof(raw)!=TYPE_DICTIONARY:
			continue
		var item:Dictionary=raw
		# Back-decor without collision belongs to the rear visual plane; the
		# fallback geometry is reserved for tangible mid/front-depth objects.
		if bool(item.get("collision",false)):
			_proxy_authored_object(parent,item)
	for raw in room_visual_layout.procedural(kind,width):
		if typeof(raw)==TYPE_DICTIONARY:
			_proxy_authored_procedural(parent,raw)
	return true

func _populate_furniture(group_node: Node3D) -> void:
	var group:Dictionary=visual_room_groups.get(group_node.name,{})
	if group.is_empty() or _group_facade_only(group):
		return
	var decoration_layer:Node3D=group_node.get_node_or_null("LocalFurniture")
	if decoration_layer==null or detailed_room_groups.has(group_node.name):
		return
	var physical_room:Dictionary=world.room_by_id(str(group.get("primary_id","")))
	if physical_room.is_empty():
		return
	var root:=Node3D.new()
	root.name="PhysicalFurniture"
	decoration_layer.add_child(root)
	if bool(group.get("replaces_furniture",false)):
		# The visual furniture lives in the authored image layer. Keep only
		# stable, invisible data anchors in one physical room root.
		var seen:Dictionary={}
		for spot in life.stations.layout_for_world(world,physical_room):
			var name:String=str(spot.get("furniture_id",""))
			if name=="" or seen.has(name):
				continue
			var anchor:=furniture_object(root,name)
			var offset:Vector2=spot.get("offset",Vector2.ZERO)
			anchor.position=Vector3(offset.x,0.0,offset.y)
			seen[name]=true
	else:
		var used_authored:bool=_populate_physical_fallback(root,group)
		if not used_authored:
			# R1 legacy rooms without a pinned wide layout remain one coherent
			# furniture composition, never one composition per virtual module.
			furnish(root,str(group["type"]),int(group["x_start"]),int(group["level"]))
			_ensure_fallback_anchor_furniture(
				root,life.stations.layout_for_world(world,physical_room))
	detailed_room_groups[group_node.name]=true
	detail_materialization_count+=1

func _release_furniture(group_node: Node3D) -> void:
	if not detailed_room_groups.has(group_node.name):
		return
	var decoration_layer: Node3D = group_node.get_node_or_null("LocalFurniture")
	if decoration_layer:
		for child in decoration_layer.get_children():
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
	var facade_only := _group_facade_only(group)
	var art_type := _review_room_art_type(group)
	visual_room_groups[n.name]["art_type"] = art_type
	var accepted: Array=interior_skin.validated_layers(art_type,int(group["width"]))
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
	# Structural slabs are deliberately thin: they frame the cutaway instead of
	# competing with the room artwork at close zoom.
	var floor_slab:=box(structure,Vector3(0,-0.055,-0.15),
		Vector3(span*1.01,0.10,3.60),palette["floor"])
	floor_slab.name="CutawayFloorSlab"
	if not facade_only:
		var cutaway_depth:=Node3D.new()
		cutaway_depth.name="Stage_CutawayDepth"
		structure.add_child(cutaway_depth)
		add_cutaway_depth(cutaway_depth,group)
	box(background,Vector3(0,1.45,-2.04),Vector3(span*1.01,3.25,0.35),palette["rock"])
	if not facade_only:
		var rear_stage := Node3D.new()
		rear_stage.name = "Stage_Backwall"
		background.add_child(rear_stage)
		add_backwall_stage(rear_stage,group)
	var ceiling_slab:=box(structure,Vector3(0,3.055,-0.62),
		Vector3(span*1.01,0.09,2.72),palette["border"])
	ceiling_slab.name="CutawayCeilingSlab"
	var front_lip:=box(overlay,Vector3(0,-0.095,1.39),
		Vector3(span*1.01,0.07,0.09),palette["border"])
	front_lip.name="CutawayFrontLip"
	# Expensive full-resolution artwork is loaded on demand by
	# update_render_lod(), not permanently allocated for all 49+ rooms.
	var physical_room:Dictionary=world.room_by_id(str(group.get("primary_id","")))
	for side in [-1,1]:
		var neighbour:Dictionary=side_left if side==-1 else side_right
		var edge:float=float(side)*(span*0.5-0.10)
		var connected:bool=not physical_room.is_empty() and not neighbour.is_empty() and (
			not world.connection_between(physical_room,neighbour).is_empty())
		if not connected:
			box(structure,Vector3(edge,1.42,-0.42),
				Vector3(0.22,2.75,3.08),palette["rock_light"])
			box(overlay,Vector3(edge,0.18,1.31),
				Vector3(0.22,0.34,0.14),palette["rock_light"])
		else:
			# Only an explicit connector opens the wall.
			box(structure,Vector3(edge,2.84,-0.61),
				Vector3(0.16,0.34,2.52),palette["rock_light"])
			box(structure,Vector3(edge,0.48,-1.82),
				Vector3(0.18,0.96,0.16),palette["rock_light"])
	# Physical R2/R3 rooms deliberately have no internal module ribs.
	if not facade_only:
		var overview := Node3D.new()
		overview.name = "Layer_OverviewCues"
		n.add_child(overview)
		add_room_overview_cues(overview,group)
	if facade_only:
		# Private/closed-guest interiors are facade-only; no hidden room is materialized.
		box(n,Vector3(0,1.4,1.05),Vector3(2.08,2.8,0.22),palette["wood"])
		box(n,Vector3(0.82,1.33,1.2),Vector3(0.12,0.12,0.07),palette["bronze"])
		var private_room:Dictionary=group["cells"][0]
		var owner_id:String=str(private_room.get("owner_id",""))
		var sign:String=str(private_room.get("display_name","Гостевая")) if t=="guest" else \
			door_registry.sign_text(owner_id,world.read_resident_profiles())
		var door_label := label3(n,sign,Vector3(0,3.34,1.0),24,Color("#d4bdb0"))
		door_label.name = "RoomRoofLabel"
		if t=="private" and door_registry.has_public_note(owner_id):
			# Public framed note is a clickable threshold object, never interior access.
			box(n,Vector3(-0.58,1.67,1.19),Vector3(0.52,0.70,0.055),palette["bronze"])
			box(n,Vector3(-0.58,1.67,1.225),Vector3(0.39,0.55,0.020),Color("#eadfc8"),true)
			var note_anchor:=Node3D.new()
			note_anchor.name="DoorPublicNoteAnchor"
			note_anchor.position=Vector3(-0.58,1.67,1.27)
			n.add_child(note_anchor)
			door_note_anchors[str(private_room["id"])]=note_anchor
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
	door_note_anchors.clear()
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

func depth_visual_scale(z: float) -> float:
	return world.room_space.perspective_scale(z)

func make_creatures() -> void:
	if creature_root == null:
		return
	for child in creature_root.get_children():
		child.queue_free()
	creature_nodes.clear()
	creature_labels.clear()
	var placeholder := make_sprite_texture(true)
	creature_animations.clear()
	for creature_id in world.creatures:
		var creature: Dictionary = world.creatures[creature_id]
		if not bool(creature.get("active",false)):
			continue
		var anchor := Node3D.new()
		anchor.name = str(creature_id)
		creature_root.add_child(anchor)
		var sprite := Sprite3D.new()
		sprite.name = "Body"
		var bank_id := str(creature.get("bank_id",""))
		var bank_texture: Texture2D = null
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		if bank_id != "" and asset_banks.candidate_creature_bank(bank_id):
			bank_texture = asset_banks.creature_texture(bank_id,"IDLE_RIGHT",0)
		sprite.texture = bank_texture if bank_texture != null else placeholder
		if bank_texture != null:
			sprite.pixel_size = _creature_canvas_width(bank_id) / maxf(1.0,float(bank_texture.get_width()))
			sprite.position.y = float(bank_texture.get_height()) * 0.43 * sprite.pixel_size
			sprite.set_meta("candidate_bank",bank_id)
			creature_animations[str(creature_id)] = {"state":"IDLE_RIGHT","frame":0,"elapsed":0.0}
		else:
			sprite.pixel_size = 0.0055
			sprite.position.y = 0.38
		anchor.add_child(sprite)
		var label := label3(anchor,world.creature_display_label(str(creature_id)),
			Vector3(0,0.92,0.15),21,Color("#ead8bf"))
		label.visible = false
		creature_nodes[str(creature_id)] = anchor
		creature_labels[str(creature_id)] = label
	update_creatures()

func update_creatures(delta: float = 0.0) -> void:
	var active_count := 0
	for creature_id in world.creatures:
		if bool(world.creatures[creature_id].get("active",false)):
			active_count += 1
	if active_count != creature_nodes.size():
		make_creatures()
		return
	for creature_id in creature_nodes:
		var creature: Dictionary = world.creatures.get(creature_id,{})
		var anchor: Node3D = creature_nodes[creature_id]
		if creature.is_empty() or not bool(creature.get("active",false)):
			anchor.visible = false
			continue
		anchor.visible = semantic_view.actor_visible(creature)
		if not anchor.visible:
			continue
		var y := float(creature.get("visual_y",
			float(creature.get("level",0))*H))
		var creature_z: float = float(creature.get("z",0.25))
		anchor.position = Vector3(float(creature.get("x",0.0)),y,creature_z)
		var creature_scale:=depth_visual_scale(creature_z)
		anchor.scale=Vector3.ONE*creature_scale
		var body: Sprite3D = anchor.get_node_or_null("Body")
		var bank_id := str(creature.get("bank_id",""))
		if body != null and bank_id != "" and body.has_meta("candidate_bank"):
			var moving_left := str(creature.get("moving_axis","right")) == "left"
			var state := ("WALK_LEFT" if moving_left else "WALK_RIGHT") if (
				str(creature.get("phase","idle")) == "travel") else (
				"IDLE_LEFT" if moving_left else "IDLE_RIGHT")
			var anim: Dictionary = creature_animations.get(creature_id,
				{"state":state,"frame":0,"elapsed":0.0})
			if str(anim.get("state","")) != state:
				anim = {"state":state,"frame":0,"elapsed":0.0}
			else:
				anim["elapsed"] = float(anim.get("elapsed",0.0)) + delta
			var frame_count := asset_banks.creature_frame_count(bank_id,state)
			var frame_time := 1.0 / asset_banks.creature_fps(bank_id,state)
			if frame_count > 0 and float(anim["elapsed"]) >= frame_time:
				anim["frame"] = (int(anim.get("frame",0)) + 1) % frame_count
				anim["elapsed"] = 0.0
			var tex := asset_banks.creature_texture(bank_id,state,int(anim.get("frame",0)))
			if tex != null:
				body.texture = tex
			creature_animations[creature_id] = anim
		var label: Label3D = creature_labels.get(creature_id)
		if label != null:
			label.text = world.creature_display_label(creature_id)
			var owner_id := str(creature.get("owner_id",""))
			# Owner labels are evidence-driven and shown only close enough to read.
			label.visible = owner_id != "" and zoom_current < 26.0

func _object_offset(object_id: String) -> Vector3:
	var code := 0
	for i in range(object_id.length()):
		code = (code * 33 + object_id.unicode_at(i)) & 0x7fffffff
	var ox := (float(code % 7) - 3.0) * 0.16
	var oz := (float(int(code / 7) % 5) - 2.0) * 0.12
	return Vector3(ox,0.0,oz)

func make_physical_objects() -> void:
	if object_root == null:
		return
	for child in object_root.get_children():
		child.queue_free()
	object_nodes.clear()
	clear_content_hotspots()
	for object_id in world.objects:
		var object: Dictionary = world.objects[object_id]
		var anchor := Node3D.new()
		anchor.name = "Object_" + str(object_id)
		object_root.add_child(anchor)
		var asset_id := str(object.get("asset_id",""))
		var texture: Texture2D = asset_banks.prop_display_texture(asset_id) if asset_id != "" else null
		if texture != null:
			var sprite := Sprite3D.new()
			sprite.name = "Visual"
			sprite.texture = texture
			sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
			sprite.pixel_size = 0.48 / maxf(1.0,float(texture.get_height()))
			sprite.position.y = 0.28
			anchor.add_child(sprite)
		else:
			var marker := box(anchor,Vector3(0,0.12,0),Vector3(0.22,0.22,0.22),palette["bronze"])
			marker.name = "VisualFallback"
		object_nodes[str(object_id)] = anchor
		register_content_hotspot(anchor,
			str(object.get("viewer_category","artifacts")),str(object_id),
			str(object.get("display_name",object_id)))
	update_physical_objects()

func update_physical_objects() -> void:
	for object_id in object_nodes:
		var anchor: Node3D = object_nodes[object_id]
		var object: Dictionary = world.physical_object(str(object_id))
		if object.is_empty():
			anchor.visible = false
			continue
		var holder_id := str(object.get("current_holder_id",""))
		if holder_id != "":
			var holder: Dictionary = world._physical_actor(holder_id)
			if holder.is_empty():
				anchor.visible = false
				continue
			anchor.visible = semantic_view.actor_visible(holder)
			if not anchor.visible:
				continue
			anchor.position = Vector3(
				float(holder.get("x",0.0)),
				float(holder.get("visual_y",float(holder.get("level",0))*H))+0.78,
				float(holder.get("z",0.25))+0.18) + _object_offset(str(object_id))*0.25
			var held_scale: float = depth_visual_scale(float(holder.get("z",0.25)))
			anchor.scale=Vector3.ONE*held_scale
			continue
		if str(object.get("state","")) == "STASHED":
			# Hidden means hidden: the canonical location remains in world state,
			# but the normal renderer and hover hit-test expose no visible copy.
			anchor.visible = false
			continue
		var room_id := str(object.get("current_room_id",""))
		var room: Dictionary = world.room_by_id(room_id)
		if room.is_empty() or str(room.get("privacy","public")) != "public":
			anchor.visible = false
			continue
		anchor.visible = current_mode == "HOUSE" or int(room.get("level",0)) == semantic_view.level
		if not anchor.visible:
			continue
		var raw_anchor=object.get("current_anchor",[])
		var local_anchor:Vector2
		if typeof(raw_anchor)==TYPE_ARRAY and (raw_anchor as Array).size()==2:
			local_anchor=Vector2(float(raw_anchor[0]),float(raw_anchor[1]))
		else:
			var fallback:Vector3=_object_offset(str(object_id))
			local_anchor=Vector2(fallback.x,0.72+fallback.z)
		var room_world:Vector3=world.room_local_to_world(room,local_anchor)
		anchor.position=Vector3(room_world.x,room_world.y+0.22,room_world.z)
		anchor.scale=Vector3.ONE*depth_visual_scale(local_anchor.y)

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
			var candidate_guest: bool = str(actor.get("entity_type","")) == "guest" and \
				str(actor.get("visual_status","")) == "CANDIDATE" and \
				str(actor.get("bank_id","")) == id
			var chosen_wardrobe: String = asset_banks.preferred_wardrobe(
				id,profile_id,qa_visual_preview or candidate_guest)
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
		var actor_z: float = float(actor.get("z",0.3))
		actor_sprites[id].position = Vector3(float(actor.get("x",0.0)),y,actor_z)
		var actor_scale:=depth_visual_scale(actor_z)
		actor_sprites[id].scale=Vector3.ONE*actor_scale
		actor_sprites[id].visible = semantic_view.actor_visible(actor)
		if not actor_sprites[id].visible:
			continue
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
			"WORK_CREATE":
				if str(actor.get("station_kind","")) == "work":
					requested = str(actor.get("station_pose_hint","USE"))
			"REST":
				if str(actor.get("station_kind","")) in ["seat","floor_rest"]:
					requested = str(actor.get("station_pose_hint","RELAXED_SIT"))
			"SLEEP":
				if str(actor.get("station_kind","")) in ["seat","floor_rest"]:
					requested = str(actor.get("station_pose_hint","SLEEP"))
			"TALK_PAIR":
				requested = "RELAXED_SIT" if str(actor.get("station_kind","")) == "seat" else "TALK"
			"GET_COFFEE": requested = "DRINK"
			"WATCH_FILM", "LISTEN_MUSIC":
				requested = str(actor.get("station_pose_hint","VIEW")) if (
					str(actor.get("station_kind",""))=="seat") else "VIEW"
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
	for item in ["Дом", "Этаж", "Комната", "Манька", "Строить"]:
		var button := Button.new()
		button.text = item
		controls.add_child(button)
		match item:
			"Дом": button.pressed.connect(func(): set_mode("HOUSE"))
			"Этаж": button.pressed.connect(func(): set_mode("LEVEL"))
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
	var size_menu := OptionButton.new()
	for size_id in [1,2,3]:
		size_menu.add_item("R%d · %d мод." % [size_id,size_id])
		size_menu.set_item_metadata(size_menu.item_count-1,size_id)
	size_menu.select(0)
	size_menu.item_selected.connect(func(i):
		build_size=int(size_menu.get_item_metadata(i))
		if build_marker!=null:
			var cube:BoxMesh=build_marker.mesh
			cube.size.x=W*float(build_size)*0.94)
	hud_main_body.add_child(size_menu)
	var media_button := Button.new()
	media_button.text = "Открыть библиотеку / медиа [M]"
	media_button.pressed.connect(toggle_media_panel)
	hud_main_body.add_child(media_button)
	content_viewer = ContentViewerScript.new()
	root.add_child(content_viewer)
	content_viewer.bind(life.media_runtime)
	media_panel = MediaPanelScript.new()
	root.add_child(media_panel)
	media_panel.bind(world,life.media_runtime,content_viewer)
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
	hud_help.text = "Колесо: масштаб | ПКМ: перемещение\nЛКМ: выбрать | Q/E: поворот\nPgUp/PgDn: этаж | F: следить | B: строить\nEsc: Follow→Room→Level→House | 1/2/3: House/Level/Room\nV: QA-спрайты | M: медиа | J: журнал"
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
	content_hover_label = Label.new()
	content_hover_label.visible = false
	content_hover_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_hover_label.add_theme_color_override("font_color",Color("#f4ddc4"))
	root.add_child(content_hover_label)
	catalog_picker = FileDialog.new()
	catalog_picker.access = FileDialog.ACCESS_FILESYSTEM
	catalog_picker.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	catalog_picker.add_filter("*.json", "Media catalog JSON")
	catalog_picker.file_selected.connect(_import_media)
	root.add_child(catalog_picker)

	# Full-screen owner-public door note. This panel never grants room access.
	door_note_panel = PanelContainer.new()
	door_note_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	door_note_panel.offset_left = 42
	door_note_panel.offset_top = 32
	door_note_panel.offset_right = -42
	door_note_panel.offset_bottom = -32
	door_note_panel.visible = false
	door_note_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(door_note_panel)
	var door_col:=VBoxContainer.new()
	door_note_panel.add_child(door_col)
	var door_header:=HBoxContainer.new()
	door_col.add_child(door_header)
	door_note_title=Label.new()
	door_note_title.text="ДВЕРЬ"
	door_note_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	door_header.add_child(door_note_title)
	var door_close:=Button.new()
	door_close.text="Закрыть [Esc]"
	door_close.pressed.connect(close_door_note)
	door_header.add_child(door_close)
	door_note_text=RichTextLabel.new()
	door_note_text.bbcode_enabled=false
	door_note_text.fit_content=false
	door_note_text.scroll_active=true
	door_note_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	door_note_text.size_flags_vertical=Control.SIZE_EXPAND_FILL
	door_note_text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	door_note_text.custom_minimum_size=Vector2(640,520)
	door_col.add_child(door_note_text)
	update_hud()

func register_content_hotspot(anchor: Node3D, category: String,
		item_id: String, display_name: String) -> void:
	if anchor == null or category == "" or item_id == "":
		return
	for entry in content_hotspots:
		if entry.get("anchor") == anchor:
			entry["category"] = category
			entry["item_id"] = item_id
			entry["display_name"] = display_name
			return
	content_hotspots.append({
		"anchor":anchor, "category":category,
		"item_id":item_id, "display_name":display_name
	})

func clear_content_hotspots() -> void:
	content_hotspots.clear()
	if content_hover_label != null:
		content_hover_label.visible = false

func content_hotspot_at_screen(point: Vector2) -> Dictionary:
	if camera == null:
		return {}
	var best := 42.0
	var found: Dictionary = {}
	for entry in content_hotspots:
		var anchor = entry.get("anchor")
		if not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
			continue
		if camera.is_position_behind(anchor.global_position):
			continue
		var screen := camera.unproject_position(anchor.global_position)
		var distance := screen.distance_to(point)
		if distance < best:
			best = distance
			found = entry
	return found

func open_content_hotspot(entry: Dictionary) -> bool:
	if entry.is_empty() or content_viewer == null:
		return false
	var category := str(entry.get("category",""))
	var item_id := str(entry.get("item_id",""))
	var record: Dictionary = {}
	if category in ["books","films","tracks"]:
		record = life.media_runtime._lookup(category,item_id)
	elif category == "artifacts":
		record = world.physical_object(item_id)
	if record.is_empty():
		return false
	return content_viewer.open_record(category,record)

func update_content_hover(point: Vector2) -> void:
	if content_hover_label == null or content_viewer == null or content_viewer.visible:
		return
	var entry := content_hotspot_at_screen(point)
	content_hover_label.visible = not entry.is_empty()
	if entry.is_empty():
		return
	content_hover_label.text = str(entry.get("display_name",entry.get("item_id","")))
	content_hover_label.position = point + Vector2(14,12)

func close_door_note()->void:
	if door_note_panel!=null:
		door_note_panel.visible=false

func open_door_note(room_id:String)->bool:
	var room:Dictionary=world.room_by_id(room_id)
	if room.is_empty() or str(room.get("privacy","public"))!="door_only":
		return false
	var owner_id:String=str(room.get("owner_id",""))
	var body:String=door_registry.note_text(owner_id)
	if body=="":
		return false
	door_note_title.text=door_registry.sign_text(owner_id,world.read_resident_profiles())
	door_note_text.text=body
	door_note_text.scroll_to_line(0)
	door_note_panel.visible=true
	return true

func door_note_at_screen(point:Vector2)->String:
	if camera==null:
		return ""
	var best:=44.0
	var found:=""
	for room_id in door_note_anchors:
		var anchor:Node3D=door_note_anchors[room_id]
		if not is_instance_valid(anchor) or not anchor.is_visible_in_tree():
			continue
		if camera.is_position_behind(anchor.global_position):
			continue
		var screen:Vector2=camera.unproject_position(anchor.global_position)
		var distance:float=screen.distance_to(point)
		if distance<best:
			best=distance
			found=str(room_id)
	return found

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

func _world_journal_line(entry: Dictionary) -> String:
	var event_name: String = str(entry.get("event",""))
	var actor_id: String = str(entry.get("actor_id",""))
	var subject_id: String = str(entry.get("subject_id",""))
	var actor_name: String = actor_id
	if world.residents.has(actor_id):
		actor_name = str(world.residents[actor_id].get("name",actor_id))
	elif world.creatures.has(actor_id):
		actor_name = str(world.creatures[actor_id].get("name",actor_id))
	var subject_name: String = subject_id
	var object: Dictionary = world.physical_object(subject_id)
	if not object.is_empty():
		subject_name = str(object.get("display_name",subject_id))
	match event_name:
		"CREATURE_ROAMED":
			return "%s — перемещение: %s → %s" % [
				actor_name,str(entry.get("from","")),str(entry.get("to",""))]
		"CREATURE_ACCESS_REJECTED":
			return "%s — доступ отклонён: %s" % [
				actor_name,str(entry.get("to",""))]
		"OBJECT_PICKED_UP":
			return "%s — переносит: %s" % [actor_name,subject_name]
		"OBJECT_STASHED":
			return "%s — прячет: %s" % [actor_name,subject_name]
		"OBJECT_LOST_FOUND":
			return "Дом нашёл: %s" % subject_name
		"OBJECT_RESTORED_HOME":
			return "На место возвращено: %s" % subject_name
		"GUEST_REGISTERED":
			return "Гостья в Доме: %s" % actor_name
		"CREATURE_REGISTERED":
			return "В Доме появилась живность: %s" % actor_name
		_:
			if event_name.begins_with("OBJECT_"):
				return "%s · %s" % [subject_name,event_name.trim_prefix("OBJECT_").to_lower()]
			return "%s · %s" % [actor_name,event_name]

func update_journal() -> void:
	if journal_text == null:
		return
	var lines: Array[String] = []
	for message in life.log.slice(maxi(0, life.log.size() - 6)):
		lines.append(str(message))
	for entry in world.journal_entries(8):
		if typeof(entry) == TYPE_DICTIONARY:
			lines.append(_world_journal_line(entry))
	if lines.size() > 14:
		lines = lines.slice(lines.size()-14,lines.size())
	journal_text.text = "ЖУРНАЛ ДОМА\n\n" + "\n".join(lines)

func camera_world_bounds() -> Rect2:
	var lo := Vector2(99999,99999)
	var hi := Vector2(-99999,-99999)
	for room in world.rooms:
		var start_x: float = float(room["x"])*W
		var end_x: float = float(world.room_space.x_end(room))*W
		var center_x: float = (start_x+end_x)*0.5
		var span: float = float(world.room_size_modules(room))*W
		var pos := Vector2(center_x, float(room["level"]) * H)
		lo.x = minf(lo.x,pos.x - span * 0.5)
		lo.y = minf(lo.y,pos.y - H * 0.5)
		hi.x = maxf(hi.x,pos.x + span * 0.5)
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
	box(selected_outline,Vector3(0,-0.04,1.51),
		Vector3(length,0.045,0.055),tone,true)
	box(selected_outline,Vector3(0,3.08,1.51),
		Vector3(length,0.045,0.055),tone,true)
	for side in [-1,1]:
		box(selected_outline,Vector3(float(side)*length*0.5,1.52,1.51),
			Vector3(0.050,3.12,0.055),tone,true)
	selected_outline.visible = true

func level_world_bounds(level: int) -> Rect2:
	var lo_x := INF
	var hi_x := -INF
	var found := false
	for room in world.rooms:
		if int(room.get("level",0)) != level:
			continue
		var start_x:=float(room["x"])*W
		var end_x:=float(world.room_space.x_end(room))*W
		lo_x = minf(lo_x,start_x-W*0.5)
		hi_x = maxf(hi_x,end_x+W*0.5)
		found = true
	if not found:
		return Rect2()
	var center_y := float(level)*H+1.45
	return Rect2(Vector2(lo_x,center_y-1.75),Vector2(hi_x-lo_x,3.5))

func fit_level_camera(level: int) -> bool:
	var bounds := level_world_bounds(level)
	if not bounds.has_area():
		return false
	var viewport := get_viewport().get_visible_rect().size
	var aspect := maxf(1.0,viewport.x/maxf(1.0,viewport.y))
	var angle := deg_to_rad(camera.fov*0.5)
	var vertical_dist := (bounds.size.y+1.4)/maxf(0.1,2.0*tan(angle))
	var horizontal_dist := (bounds.size.x+3.0)/maxf(0.1,2.0*aspect*tan(angle))
	zoom = clampf(maxf(vertical_dist,horizontal_dist)*1.08,12.0,82.0)
	desired_focus = Vector3(bounds.get_center().x,bounds.get_center().y,0.0)
	return true

func select_level(level: int) -> void:
	follow_id = ""
	build_mode = false
	if build_marker:
		build_marker.visible = false
	var selected := semantic_view.select_level(world,level)
	semantic_view.set_view(world,"LEVEL","",selected)
	current_mode = "LEVEL"
	Engine.max_fps = 60
	fit_level_camera(selected)
	update_selection_outline()
	update_hud()
	update_render_lod()

func step_level(delta: int) -> void:
	var next_level := semantic_view.step_level(world,delta)
	select_level(next_level)

func set_mode(mode: String) -> void:
	if not mode in ["HOUSE","LEVEL","ROOM","FOLLOW"]:
		return
	Engine.max_fps = 30 if mode == "HOUSE" else 60
	build_mode = false
	if build_marker:
		build_marker.visible = false
	current_mode = mode
	match mode:
		"HOUSE":
			follow_id = ""
			semantic_view.set_view(world,"HOUSE")
			fit_house_camera()
		"LEVEL":
			follow_id = ""
			var requested_level: int = int(semantic_view.level)
			if selected_room != "":
				var selected: Dictionary = world.room_by_id(selected_room)
				if not selected.is_empty():
					requested_level = int(selected.get("level",requested_level))
			semantic_view.select_level(world,requested_level)
			semantic_view.set_view(world,"LEVEL","",semantic_view.level)
			fit_level_camera(semantic_view.level)
		"ROOM":
			follow_id = ""
			zoom = 10.5
			if selected_room != "":
				var r: Dictionary = world.room_by_id(selected_room)
				if not r.is_empty():
					semantic_view.set_view(world,"ROOM",selected_room,int(r["level"]))
					var group: Dictionary = world.merged_group(int(r["x"]),int(r["level"]))
					var cx: float = (float(group["x_start"])+float(group["x_end"]))*0.5*W
					desired_focus = Vector3(cx,float(r["level"])*H+1.45,0.0)
					zoom = 10.8+maxf(0.0,float(group["width"]-1))*3.1
			else:
				semantic_view.set_view(world,"ROOM","",semantic_view.level)
		"FOLLOW":
			semantic_view.set_view(world,"FOLLOW",selected_room,semantic_view.level)
			zoom = 16.0
	update_selection_outline()
	update_hud()
	update_render_lod()

func follow_actor(id: String) -> void:
	if not actor_sprites.has(id) or not world.residents.has(id):
		return
	var actor: Dictionary = world.residents[id]
	follow_id = id
	selected_room = str(actor.get("room_id",selected_room))
	current_mode = "FOLLOW"
	semantic_view.set_view(world,"FOLLOW",selected_room,int(actor.get("level",0)))
	Engine.max_fps = 60
	build_mode = false
	update_selection_outline()
	zoom = minf(zoom,20.0)
	update_hud()
	update_render_lod()

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
			cube.size = Vector3(W * float(build_size) * 0.94, 2.9, 3.9)
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

func room_activity_lines(group: Dictionary) -> Array:
	# ROOM mode should expose what the visible residents are actually doing,
	# without putting floating labels over faces/furniture.
	var room_ids:Dictionary={}
	for cell in group.get("cells",[]):
		room_ids[str(cell.get("id",""))]=true
	var entries:Array=[]
	for id in world.residents:
		var actor:Dictionary=world.residents[id]
		if not bool(actor.get("active",false)) or str(actor.get("phase",""))!="perform":
			continue
		var activity_room:String=str(actor.get("station_room_id",
			actor.get("room_id","")))
		if not room_ids.has(activity_room):
			continue
		entries.append("%s — %s" % [
			str(actor.get("name",id)),life.status(actor)])
	entries.sort()
	return entries

func update_hud() -> void:
	if hud_status == null:
		return
	var tracked: Dictionary = world.residents.get(follow_id, {})
	hud_status.text = "Режим: %s | уровень: %d | комнат: %d | видимых: %d / 24" % [
		current_mode, semantic_view.level, world.rooms.size(), actor_sprites.size()-1]
	if hud_brief != null:
		hud_brief.text = "%s · L%d · %d комнат · %d/24" % [
			current_mode,semantic_view.level,world.rooms.size(),maxi(0,actor_sprites.size()-1)]
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
			if world.public_cutaway_allowed(r):
				var occupied := 0
				var capacity := 0
				for cell in group.get("cells",[]):
					occupied += life.stations.used_slots(world,str(cell["id"])).size()
					capacity += life.stations.capacity(cell)
				hud_status.text += "\nМеста действий: %d / %d" % [occupied,capacity]
				var activities:Array=room_activity_lines(group)
				for i in range(mini(3,activities.size())):
					hud_status.text += "\n" + str(activities[i])
				if activities.size()>3:
					hud_status.text += "\n…ещё %d" % (activities.size()-3)
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
		if not moving_view and not build_mode:
			update_content_hover(e.position)
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
				var center_x:float=(float(build_cell.x)+(float(build_size)-1.0)*0.5)*W
				build_marker.position = Vector3(center_x,float(build_cell.y)*H+1.4,0.0)
				var cube:BoxMesh=build_marker.mesh
				cube.size.x=W*float(build_size)*0.94
				var permitted: bool = bool(world.can_build_room(
					build_cell.x, build_cell.y, build_type, build_size))
				var preview_mat: StandardMaterial3D = build_marker.material_override
				preview_mat.albedo_color = Color(0.22,0.90,0.55,0.28) if permitted else Color(0.82,0.23,0.26,0.28)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE and content_viewer!=null and content_viewer.visible:
			content_viewer.close_viewer()
			return
		if event.keycode==KEY_ESCAPE and door_note_panel!=null and door_note_panel.visible:
			close_door_note()
			return
		match event.keycode:
			KEY_ESCAPE:
				if current_mode == "FOLLOW":
					var tracked: Dictionary = world.residents.get(follow_id,{})
					if not tracked.is_empty():
						selected_room = str(tracked.get("room_id",selected_room))
					follow_id = ""
					set_mode("ROOM")
				elif current_mode == "ROOM":
					set_mode("LEVEL")
				elif current_mode == "LEVEL":
					set_mode("HOUSE")
				else:
					set_mode("HOUSE")
			KEY_F: follow_actor("MANJKA")
			KEY_B: toggle_build()
			KEY_Q: yaw = clampf(yaw - 0.10, -0.34, 0.34)
			KEY_E: yaw = clampf(yaw + 0.10, -0.34, 0.34)
			KEY_J: toggle_journal()
			KEY_M: toggle_media_panel()
			KEY_V: toggle_qa_art_preview()
			KEY_K: toggle_bank_gallery()
			KEY_TAB: toggle_hud()
			KEY_PAGEUP: step_level(1)
			KEY_PAGEDOWN: step_level(-1)
			KEY_1: set_mode("HOUSE")
			KEY_2: set_mode("LEVEL")
			KEY_3: set_mode("ROOM")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var e: InputEventMouseButton = event
		if e.button_index != MOUSE_BUTTON_LEFT or not e.pressed:
			return
		if door_note_panel!=null and door_note_panel.visible:
			return
		if content_viewer!=null and content_viewer.visible:
			return
		var content_entry:Dictionary=content_hotspot_at_screen(e.position)
		if not content_entry.is_empty() and open_content_hotspot(content_entry):
			return
		var note_room_id:String=door_note_at_screen(e.position)
		if note_room_id!="":
			if open_door_note(note_room_id):
				return
		if build_mode:
			if build_cell == Vector2i(99,99):
				return
			if world.build_room(build_cell.x, build_cell.y, build_type, build_size):
				make_rooms()
				update_render_lod()
				notice.text = "Построено: %s R%d (%d, %d)" % [
					room_names.get(build_type, build_type), build_size,
					build_cell.x, build_cell.y]
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
				if not world.public_cutaway_allowed(room):
					notice.text = "Закрытая территория: камера остаётся у двери"
				else:
					notice.text = room_names.get(room["type"], room["type"])
				set_mode("ROOM")

func effective_camera_yaw() -> float:
	# A gentle Shelter-like oblique cutaway shows the rear and side depth
	# of the 3D room at close zoom, then fades back to a readable flat
	# overview. Q/E remains an additive *manual* adjustment.
	var close_bias: float=clampf((48.0-zoom_current)/34.0,0.0,1.0)*0.075
	return clampf(yaw+close_bias,-0.38,0.38)

func apply_camera(delta: float) -> void:
	if follow_id != "" and world.residents.has(follow_id):
		var actor: Dictionary = world.residents[follow_id]
		var actor_level := int(actor.get("level",0))
		var actor_room := str(actor.get("room_id",""))
		if current_mode == "FOLLOW" and (semantic_view.level != actor_level or semantic_view.active_room != actor_room):
			semantic_view.set_view(world,"FOLLOW",actor_room,actor_level)
			selected_room = actor_room
			update_render_lod()
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
	var height_ratio:float=lerpf(0.055,0.16,
		clampf((zoom_current-12.0)/36.0,0.0,1.0))
	camera.global_position = smooth_focus + Vector3(x_shift,zoom_current*height_ratio,z_shift)
	camera.look_at(smooth_focus,Vector3.UP)
	register_loaded_foregrounds()

func update_render_lod() -> void:
	# Keep the inexpensive shell/cues visible at HOUSE scale. Detailed 3D depth,
	# rear alcoves, rich furniture and accepted full-resolution art are useful
	# only near the camera; rendering them across the whole house wastes draw
	# calls on geometry that is smaller than a few screen pixels.
	# The camera never activates an owner-private interior.
	for group_node in room_root.get_children():
		var group: Dictionary = visual_room_groups.get(group_node.name,{})
		var semantic_visible := not group.is_empty() and semantic_view.group_visible(group)
		group_node.visible = semantic_visible
		if not semantic_visible:
			_release_room_art(group_node)
			_release_furniture(group_node)
			continue
		var furniture: Node3D = group_node.get_node_or_null("LocalFurniture")
		var cues: Node3D = group_node.get_node_or_null("Layer_OverviewCues")
		# Real room art is part of the Fallout-Shelter cutaway at every zoom.
		# Camera proximity controls only heavier 3D/furniture detail. Manual FREE
		# navigation is equivalent to ROOM for detail materialization.
		if bool(group.get("has_art",false)):
			_load_room_art(group_node)
		else:
			_release_room_art(group_node)
		var near: bool = _is_near_detail(group_node) if furniture != null else false
		if furniture != null:
			if near:
				_populate_furniture(group_node)
			else:
				_release_furniture(group_node)
			furniture.visible = near
			if cues != null:
				cues.visible = not near and not art_loaded_groups.has(group_node.name)
		var cutaway_depth: Node3D = group_node.get_node_or_null(
			"Layer_Structure/Stage_CutawayDepth")
		if cutaway_depth != null:
			cutaway_depth.visible = near
		var rear_stage: Node3D = group_node.get_node_or_null(
			"Layer_Background/Stage_Backwall")
		if rear_stage != null:
			var art_layer: Node3D = group_node.get_node_or_null("Layer_ApprovedArt")
			var backdrop_loaded: bool = art_layer != null and (
				art_layer.get_node_or_null("Art_backdrop") != null)
			rear_stage.visible = near and not backdrop_loaded
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
	update_creatures(delta)
	update_physical_objects()
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

