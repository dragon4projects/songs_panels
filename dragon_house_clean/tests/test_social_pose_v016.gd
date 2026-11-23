extends SceneTree

func _initialize()->void:
	call_deferred("run")

func run()->void:
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.zoom_current=10.0

	var seated={
		"phase":"perform","intent":"TALK_PAIR",
		"station_kind":"seat","station_pose_hint":"TALK"
	}
	assert(scene.desired_actor_animation(seated)=="RELAXED_SIT")

	var standing={
		"phase":"perform","intent":"TALK_PAIR",
		"station_kind":"standing","station_pose_hint":"TALK"
	}
	assert(scene.desired_actor_animation(standing)=="TALK")

	var work={
		"phase":"perform","intent":"WORK_CREATE",
		"station_kind":"work","station_pose_hint":"USE"
	}
	assert(scene.desired_actor_animation(work)=="USE")

	var floor_rest={
		"phase":"perform","intent":"REST",
		"station_kind":"floor_rest","station_pose_hint":"SLEEP"
	}
	assert(scene.desired_actor_animation(floor_rest)=="SLEEP")

	print("SOCIAL_POSE_V016_PASS seated=RELAXED_SIT standing=TALK work=USE floor_rest=SLEEP")
	quit(0)
