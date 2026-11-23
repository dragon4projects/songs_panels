extends SceneTree

func _initialize()->void:
    call_deferred("run")

func _ids(items:Array)->Array:
    var out:Array=[]
    for item in items:
        out.append(str(item.get("id","")))
    return out

func _node_for_room(scene,room:Dictionary)->Node3D:
    var group:Dictionary=scene.world.merged_group(int(room["x"]),int(room["level"]))
    for key in scene.visual_room_groups:
        var rendered:Dictionary=scene.visual_room_groups[key]
        if str(rendered.get("primary_id",""))==str(group.get("primary_id","")):
            return scene.room_root.get_node(str(key))
    return null

func _mount_room(scene,room:Dictionary)->Node3D:
    scene.selected_room=str(room["id"])
    scene.set_mode("ROOM")
    scene.zoom_current=scene.zoom
    scene.smooth_focus=scene.desired_focus
    scene.apply_camera(1.0)
    scene.update_render_lod()
    return _node_for_room(scene,room)

func _assert_foreground(scene,room:Dictionary,expected_z:float)->void:
    var node:Node3D=_mount_room(scene,room)
    assert(node!=null)
    var art:Node3D=node.get_node("Layer_ApprovedArt")
    var fg:Sprite3D=art.get_node("Art_foreground")
    assert(fg.has_meta("physical_z"))
    assert(absf(float(fg.get_meta("physical_z"))-expected_z)<0.00001)
    scene.yaw=-0.18
    scene.apply_camera(1.0)
    var lx:float=fg.position.x
    scene.yaw=0.18
    scene.apply_camera(1.0)
    var rx:float=fg.position.x
    assert(not is_equal_approx(lx,rx))
    scene.yaw=0.0

func run()->void:
    var scene=load("res://scenes/main.tscn").instantiate()
    scene.world.save_path="user://teea003_owner_prod_v016.json"
    root.add_child(scene)
    current_scene=scene
    scene.world.seed_world()
    var workshop:Dictionary=scene.world.make_room(0,2,"workshop")
    scene.make_rooms()
    scene.qa_visual_preview=true
    scene.make_residents()
    await process_frame
    await process_frame

    var rooms={
        "arrival":scene.world.get_room(-5,0),
        "corridor":scene.world.get_room(-4,0),
        "music":scene.world.get_room(3,0),
        "cinema":scene.world.get_room(4,0),
        "artifact":scene.world.get_room(1,-1),
        "workshop":workshop
    }
    var expected={"arrival":3,"corridor":3,"music":4,"cinema":4,"artifact":3,"workshop":3}
    for kind in expected:
        var layers:Array=scene.interior_skin.validated_layers(kind,1)
        assert(layers.size()==int(expected[kind]))
        for item in layers:
            assert(bool(item.get("approved",false)))
            assert(str(item.get("source_batch","")).contains("TEEA_INT_20261122_003"))
        var node:Node3D=_node_for_room(scene,rooms[kind])
        assert(node!=null)
        assert(bool(scene.visual_room_groups[node.name]["has_art"]))

    var raw=scene.life.stations.furniture
    assert(raw.for_room_variant(rooms["arrival"],1,0).is_empty())
    assert(raw.for_room_variant(rooms["corridor"],1,0).is_empty())
    assert(_ids(raw.for_room_variant(rooms["music"],1,0))==["music_listen_chair_seat_a"])
    assert(_ids(raw.for_room_variant(rooms["cinema"],1,0))==["cinema_sofa_seat_a","cinema_sofa_seat_b"])
    assert(_ids(raw.for_room_variant(rooms["artifact"],1,0))==["artifact_cabinet_view","artifact_pedestal_view"])
    assert(_ids(raw.for_room_variant(rooms["workshop"],1,0))==["workshop_stool_work","workshop_bench_work"])

    _assert_foreground(scene,rooms["music"],-0.1276819109916687)
    _assert_foreground(scene,rooms["cinema"],-0.1038343608379364)

    for suffix in ["",".bak",".tmp"]:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(scene.world.save_path+suffix))
    print("TEEA003_OWNER_PRODUCTION_V016_PASS layers=20 stations=7 owner_approved=true")
    quit(0)
