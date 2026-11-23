extends Node

func _ready() -> void:
	if not ClassDB.class_exists("SQLite"):
		push_error("SQLITE_SPIKE_EXPORT_RUNTIME_FAIL class_missing")
		get_tree().quit(2)
		return
	var db: Object=ClassDB.instantiate("SQLite")
	db.set("path","user://sqlite_export_smoke.db")
	db.set("verbosity_level",0)
	if not bool(db.call("open_db")):
		push_error("SQLITE_SPIKE_EXPORT_RUNTIME_FAIL open")
		get_tree().quit(3)
		return
	if not bool(db.call("query","SELECT sqlite_version() AS version;")):
		push_error("SQLITE_SPIKE_EXPORT_RUNTIME_FAIL query")
		get_tree().quit(4)
		return
	var rows:Array=db.get("query_result")
	var version:String=str((rows[0] as Dictionary).get("version","")) if not rows.is_empty() else ""
	db.call("close_db")
	print("SQLITE_SPIKE_EXPORT_RUNTIME_PASS version="+version)
	get_tree().quit(0)
