extends SceneTree
func _initialize():
	call_deferred("run")
func collect(n:Node, inherited:Transform3D, info:Dictionary):
	var xf:Transform3D = inherited
	if n is Node3D:
		xf = inherited * n.transform
	if n is MeshInstance3D and n.mesh != null:
		info.meshes += 1
		for s in range(n.mesh.get_surface_count()):
			var arr = n.mesh.surface_get_arrays(s)
			var indices = arr[Mesh.ARRAY_INDEX]
			var verts = arr[Mesh.ARRAY_VERTEX]
			info.triangles += int((indices.size() if indices != null and indices.size() > 0 else verts.size())/3)
			for v in verts:
				var p:Vector3=xf*v
				if info.vertices==0:
					info.lo=p
					info.hi=p
				else:
					info.lo=info.lo.min(p)
					info.hi=info.hi.max(p)
				info.vertices+=1
		info.material_slots += n.mesh.get_surface_count()
	for c in n.get_children():
		collect(c,xf,info)
func run():
	var d = JSON.parse_string(FileAccess.get_file_as_string("res://data/asset_proposals/TEEA_INT_20261124_008/asset_index.json"))
	var report=[]
	for item in d.items:
		var p=ResourceLoader.load(item.runtime_path,"PackedScene") as PackedScene
		if p==null:
			report.append({"id":item.asset_id,"status":"LOAD_FAIL"})
			continue
		var n=p.instantiate()
		var info={"meshes":0,"lo":Vector3.ZERO,"hi":Vector3.ZERO,"vertices":0,"triangles":0,"material_slots":0}
		collect(n,Transform3D.IDENTITY,info)
		var lo:Vector3=info.lo
		var hi:Vector3=info.hi
		var e_lo:Vector3=Vector3(item.normalized_aabb_min_m[0],item.normalized_aabb_min_m[1],item.normalized_aabb_min_m[2])
		var e_hi:Vector3=Vector3(item.normalized_aabb_max_m[0],item.normalized_aabb_max_m[1],item.normalized_aabb_max_m[2])
		var err=max((lo-e_lo).abs().length(),(hi-e_hi).abs().length())
		var status="PASS" if info.meshes>0 and info.vertices>0 and info.triangles==int(item.triangles) and err<.003 else "CHECK_GEOMETRY"
		report.append({"id":item.asset_id,"status":status,"meshes":info.meshes,"vertices":info.vertices,"triangles":info.triangles,"material_slots":info.material_slots,"imported_aabb_min":[lo.x,lo.y,lo.z],"imported_aabb_max":[hi.x,hi.y,hi.z],"max_vertex_bounds_error_m":err})
		n.free()
	var f=FileAccess.open("user://teea008_phase4_qa.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	f.close()
	print("QA_COUNT ",report.size())
	quit()
