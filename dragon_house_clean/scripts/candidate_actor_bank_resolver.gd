extends RefCounted
## Read-only resolver for staged guest/creature candidate banks.
## Asset presence is NOT entity registration, activation, ownership evidence or
## Dragon owner approval. Callers may resolve visuals only for entities that
## already exist in WorldModel.
const REGISTRY_PATH := "res://data/candidate_actor_banks_20261123.json"
const ALLOWED_EXTENSIONS := ["png","webp"]
const MAX_GUEST_FRAMES := 24
const MAX_CREATURE_FRAMES := 8

var manifest: Dictionary = {}
var source_path := REGISTRY_PATH
var cache: Dictionary = {}
var cache_order: Array = []
var cache_capacity := 48
var last_error := ""

func initialize(path: String = REGISTRY_PATH) -> bool:
	source_path = path
	manifest = {}
	cache.clear()
	cache_order.clear()
	last_error = ""
	if not FileAccess.file_exists(source_path):
		last_error = "Candidate actor bank registry is absent"
		return false
	var file := FileAccess.open(source_path,FileAccess.READ)
	if file == null:
		last_error = "Candidate actor bank registry is unreadable"
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "Candidate actor bank registry is malformed"
		return false
	var data: Dictionary = parsed
	if int(data.get("schema",0)) != 1:
		last_error = "Candidate actor bank registry schema must be 1"
		return false
	if typeof(data.get("guests",null)) != TYPE_DICTIONARY:
		last_error = "Candidate actor bank registry lacks guests map"
		return false
	if typeof(data.get("creatures",null)) != TYPE_DICTIONARY:
		last_error = "Candidate actor bank registry lacks creatures map"
		return false
	manifest = data
	return true

func guest_ids() -> Array:
	var keys: Array = manifest.get("guests",{}).keys()
	keys.sort()
	return keys

func creature_ids() -> Array:
	var keys: Array = manifest.get("creatures",{}).keys()
	keys.sort()
	return keys

func guest_entry(actor_id: String) -> Dictionary:
	return manifest.get("guests",{}).get(actor_id,{})

func creature_entry(creature_id: String) -> Dictionary:
	return manifest.get("creatures",{}).get(creature_id,{})

func has_guest(actor_id: String) -> bool:
	return not guest_entry(actor_id).is_empty()

func has_creature(creature_id: String) -> bool:
	return not creature_entry(creature_id).is_empty()

func _safe_path(root: String, path: String) -> bool:
	var relative := path.trim_prefix("res://")
	if root == "" or relative == "":
		return false
	if relative.contains("..") or relative.contains("\\") or relative.begins_with("/"):
		return false
	if not relative.begins_with(root + "/"):
		return false
	return ALLOWED_EXTENSIONS.has(relative.get_extension().to_lower())

func _real_image_bytes(relative: String) -> bool:
	var path := "res://" + relative.trim_prefix("res://")
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path,FileAccess.READ)
		if file == null:
			return false
		var head: PackedByteArray = file.get_buffer(12)
		file.close()
		var ext := relative.get_extension().to_lower()
		if ext == "png":
			return head.size() >= 8 and head.slice(0,8) == PackedByteArray([
				137,80,78,71,13,10,26,10])
		if ext == "webp":
			return (head.size() >= 12
				and head.slice(0,4).get_string_from_ascii() == "RIFF"
				and head.slice(8,12).get_string_from_ascii() == "WEBP")
		return false
	if ResourceLoader.exists(path):
		return load(path) is Texture2D
	return false

func _load_texture(relative: String) -> Texture2D:
	var url := "res://" + relative.trim_prefix("res://")
	if cache.has(url):
		return cache[url]
	var texture: Texture2D = null
	if ResourceLoader.exists(url):
		var loaded = load(url)
		if loaded is Texture2D:
			texture = loaded
	if texture == null and FileAccess.file_exists(url):
		var image := Image.new()
		if image.load(url) == OK:
			texture = ImageTexture.create_from_image(image)
	if texture != null:
		cache[url] = texture
		cache_order.append(url)
		while cache_order.size() > cache_capacity:
			cache.erase(cache_order.pop_front())
	return texture

func guest_wardrobes(actor_id: String) -> Array:
	var entry := guest_entry(actor_id)
	var keys: Array = entry.get("wardrobes",{}).keys()
	keys.sort()
	return keys

func guest_default_wardrobe(actor_id: String) -> String:
	var entry := guest_entry(actor_id)
	var preferred := str(entry.get("default_wardrobe",""))
	if guest_wardrobes(actor_id).has(preferred):
		return preferred
	var options := guest_wardrobes(actor_id)
	return str(options[0]) if not options.is_empty() else ""

func _guest_frames(actor_id: String, wardrobe: String, state: String) -> Array:
	var entry := guest_entry(actor_id)
	var frames = entry.get("wardrobes",{}).get(wardrobe,{}).get(
		"states",{}).get(state,[])
	return frames if typeof(frames) == TYPE_ARRAY else []

func guest_frame_count(actor_id: String, wardrobe: String, state: String) -> int:
	var frames := _guest_frames(actor_id,wardrobe,state)
	if frames.is_empty() or frames.size() > MAX_GUEST_FRAMES:
		return 0
	var root := str(guest_entry(actor_id).get("bank_root",""))
	for raw in frames:
		if not _safe_path(root,str(raw)):
			return 0
	return frames.size()

func guest_bank_metadata_ready(actor_id: String, wardrobe: String = "") -> bool:
	var chosen := wardrobe if wardrobe != "" else guest_default_wardrobe(actor_id)
	return (guest_frame_count(actor_id,chosen,"IDLE_S") == 1
		and guest_frame_count(actor_id,chosen,"WALK_LEFT") >= 4
		and guest_frame_count(actor_id,chosen,"WALK_RIGHT") >= 4)

func guest_bank_bytes_ready(actor_id: String, wardrobe: String = "") -> bool:
	var chosen := wardrobe if wardrobe != "" else guest_default_wardrobe(actor_id)
	if not guest_bank_metadata_ready(actor_id,chosen):
		return false
	var root := str(guest_entry(actor_id).get("bank_root",""))
	for state in ["IDLE_S","WALK_LEFT","WALK_RIGHT"]:
		for raw in _guest_frames(actor_id,chosen,state):
			var path := str(raw)
			if not _safe_path(root,path) or not _real_image_bytes(path):
				return false
	return true

func guest_fps(state: String) -> float:
	# Presentation-only cadence; not simulation truth or source-art metadata.
	if state.begins_with("WALK"):
		return 12.0
	if state == "DRINK":
		return 4.0
	return 2.0

func guest_texture(actor_id: String, wardrobe: String, state: String,
		frame_index: int) -> Texture2D:
	var frames := _guest_frames(actor_id,wardrobe,state)
	if frames.is_empty() or frames.size() > MAX_GUEST_FRAMES:
		return null
	var chosen := str(frames[posmod(frame_index,frames.size())])
	var root := str(guest_entry(actor_id).get("bank_root",""))
	if not _safe_path(root,chosen) or not _real_image_bytes(chosen):
		return null
	return _load_texture(chosen)

func guest_feet_anchor(actor_id: String, wardrobe: String, height: int) -> float:
	# Candidate banks have common floor-baseline normalization but no canonical
	# per-frame feet anchor record. Keep this presentation-only and conservative.
	return float(height) - minf(12.0,float(height)*0.07)

func _creature_frames(creature_id: String, state: String) -> Array:
	var entry := creature_entry(creature_id)
	var frames = entry.get("states",{}).get(state,[])
	return frames if typeof(frames) == TYPE_ARRAY else []

func creature_frame_count(creature_id: String, state: String) -> int:
	var frames := _creature_frames(creature_id,state)
	if frames.is_empty() or frames.size() > MAX_CREATURE_FRAMES:
		return 0
	var root := str(creature_entry(creature_id).get("bank_root",""))
	for raw in frames:
		if not _safe_path(root,str(raw)):
			return 0
	return frames.size()

func creature_bank_metadata_ready(creature_id: String) -> bool:
	if creature_id == "manjka":
		return false
	return (creature_frame_count(creature_id,"identity") == 1
		and creature_frame_count(creature_id,"idle") == 2
		and creature_frame_count(creature_id,"rest") == 2
		and creature_frame_count(creature_id,"walk_left") == 4
		and creature_frame_count(creature_id,"walk_right") == 4)

func creature_bank_bytes_ready(creature_id: String) -> bool:
	if not creature_bank_metadata_ready(creature_id):
		return false
	var root := str(creature_entry(creature_id).get("bank_root",""))
	for state in ["identity","idle","rest","walk_left","walk_right"]:
		for raw in _creature_frames(creature_id,state):
			var path := str(raw)
			if not _safe_path(root,path) or not _real_image_bytes(path):
				return false
	return true

func creature_fps(state: String) -> float:
	# Presentation-only cadence; simulation movement remains authoritative.
	if state.begins_with("walk_"):
		return 8.0
	return 2.0

func creature_texture(creature_id: String, state: String,
		frame_index: int) -> Texture2D:
	var frames := _creature_frames(creature_id,state)
	if frames.is_empty() or frames.size() > MAX_CREATURE_FRAMES:
		return null
	var chosen := str(frames[posmod(frame_index,frames.size())])
	var root := str(creature_entry(creature_id).get("bank_root",""))
	if not _safe_path(root,chosen) or not _real_image_bytes(chosen):
		return null
	return _load_texture(chosen)

func creature_world_height(creature_id: String) -> float:
	# Renderer-only size hints. They do not affect navigation/collision policy.
	var kind := str(creature_entry(creature_id).get("creature_kind",""))
	match kind:
		"cat_candidate":
			return 0.62
		"microfauna":
			if creature_id.begins_with("npc_mouse_"):
				return 0.24
			if creature_id.begins_with("npc_hedgehog_"):
				return 0.28
			if creature_id.begins_with("npc_rat_"):
				return 0.31
			return 0.30
		"zoo":
			return 0.55
	return 0.42

func guest_turning_diameter_m(actor_id: String) -> float:
	return maxf(0.0,float(guest_entry(actor_id).get("turning_diameter_m",0.0)))

func owner_claim(creature_id: String) -> String:
	# Empty is meaningful: ownership must never be inferred from room/proximity.
	var entry := creature_entry(creature_id)
	var value = entry.get("owner_id",null)
	return "" if value == null else str(value)
