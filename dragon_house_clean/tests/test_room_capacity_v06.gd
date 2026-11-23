extends SceneTree
## A 49-cell future house must not instantiate furniture in every cell at once.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.world.save_path="user://test_49_room_lod_v06.json"
	root.add_child(scene)
	current_scene=scene
	var world=scene.world
	var added:=0
	for level in [-2,2]:
		for x in range(-7,7):
			if world.get_room(x,level).is_empty():
				var choices:=["corridor","library","rest","music","study","cinema","workshop"]
				world.make_room(x,level,choices[posmod(x+7,choices.size())])
				added+=1
	assert(world.rooms.size()==49,"Synthetic 49-cell world")
	scene.make_rooms()
	await process_frame
	await process_frame
	scene.zoom_current=100.0
	scene.zoom=100.0
	scene.smooth_focus=Vector3.ZERO
	scene.update_render_lod()
	await process_frame
	await process_frame
	assert(scene.detailed_room_groups.size()==0,"Never build all furniture at overview")
	var group_count:int=scene.room_root.get_child_count()
	assert(group_count>=30,"No room shell lost when growing house")
	# v0.19 semantic hierarchy: HOUSE is intentionally shell-only even if a
	# legacy caller forces a close zoom. Detail materialization belongs to
	# ROOM/FOLLOW, so enter a real public room before testing the near bound.
	var detail_room:Dictionary=world.get_room(0,0)
	assert(not detail_room.is_empty())
	scene.selected_room=str(detail_room["id"])
	scene.set_mode("ROOM")
	scene.zoom_current=10.0
	scene.zoom=10.0
	scene.smooth_focus=Vector3.ZERO
	scene.update_render_lod()
	var instanced:int=scene.detailed_room_groups.size()
	assert(instanced>0 and instanced<17,
		"Near camera materialization bounded independent of total house size")
	scene.zoom_current=100.0
	scene.zoom=100.0
	scene.update_render_lod()
	assert(scene.detailed_room_groups.size()==0)
	for ext in ["",".bak",".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.world.save_path+ext))
	print("ROOM_CAPACITY_V06_PASS rooms=%d visual_groups=%d near_instanced=%d far_instanced=0" %
		[world.rooms.size(),group_count,instanced])
	quit(0)

