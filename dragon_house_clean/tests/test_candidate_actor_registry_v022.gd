extends SceneTree
const CandidateBanks = preload("res://scripts/candidate_actor_bank_resolver.gd")

func _initialize() -> void:
	call_deferred("run")

func _guest_frame_total(entry: Dictionary) -> int:
	var total := (entry.get("identity",[]) as Array).size()
	for wardrobe in entry.get("wardrobes",{}).values():
		for frames in (wardrobe as Dictionary).get("states",{}).values():
			total += (frames as Array).size()
	return total

func run() -> void:
	var banks := CandidateBanks.new()
	assert(banks.initialize(),banks.last_error)
	var guests := banks.guest_ids()
	assert(guests == [
		"NPC_CENTAUR","NPC_GINGER_CAT_GUEST","NPC_VAMPIRE_GIRL"])
	assert(str(banks.guest_entry("NPC_CENTAUR").get("display_name",""))=="Кентавр")
	assert(str(banks.guest_entry("NPC_VAMPIRE_GIRL").get("display_name",""))=="Вампирша")
	assert(str(banks.guest_entry("NPC_GINGER_CAT_GUEST").get("display_name",""))=="Миу")
	assert(_guest_frame_total(banks.guest_entry("NPC_CENTAUR"))==142)
	assert(_guest_frame_total(banks.guest_entry("NPC_VAMPIRE_GIRL"))==142)
	assert(_guest_frame_total(banks.guest_entry("NPC_GINGER_CAT_GUEST"))==48)
	assert(banks.guest_wardrobes("NPC_GINGER_CAT_GUEST")==["SHORT"])
	assert(banks.guest_bank_metadata_ready("NPC_CENTAUR","HOME"))
	assert(banks.guest_bank_metadata_ready("NPC_VAMPIRE_GIRL","HOME"))
	assert(banks.guest_bank_metadata_ready("NPC_GINGER_CAT_GUEST","SHORT"))
	assert(is_equal_approx(banks.guest_turning_diameter_m("NPC_CENTAUR"),2.5))

	var creatures := banks.creature_ids()
	assert(creatures.size()==18)
	assert(not creatures.has("manjka"))
	assert(not creatures.has("SHURSHUN"))
	assert(not creatures.has("shurshun"))
	for id in creatures:
		assert(banks.creature_bank_metadata_ready(str(id)),str(id))
		assert(banks.owner_claim(str(id))=="",
			"candidate ownership must remain unknown without evidence")
		assert(banks.creature_frame_count(str(id),"identity")==1)
		assert(banks.creature_frame_count(str(id),"idle")==2)
		assert(banks.creature_frame_count(str(id),"rest")==2)
		assert(banks.creature_frame_count(str(id),"walk_left")==4)
		assert(banks.creature_frame_count(str(id),"walk_right")==4)

	var raw: Dictionary = banks.manifest
	assert(str(raw.get("status",""))=="CANDIDATE_NOT_ACTIVATED")
	assert(not bool(raw.get("owner_approved",true)))
	assert(bool(raw.get("policy",{}).get(
		"asset_presence_does_not_create_world_entity",false)))
	assert(str(raw.get("policy",{}).get("shurshun",""))=="BLOCKED_MASTER_REQUIRED")
	print("CANDIDATE_ACTOR_REGISTRY_V022_PASS guests=3 guest_frames=332 creatures=18 creature_frames=234 miu=unique ownership=evidence_only shurshun=blocked")
	quit(0)
