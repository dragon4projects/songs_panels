extends SceneTree

const DB_PATH := "user://dragon_house_sqlite_spike_v49.db"

func _initialize() -> void:
	call_deferred("run")

func _cleanup() -> void:
	for suffix in ["","-wal","-shm"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(DB_PATH+suffix))

func _q(db: Object, sql: String) -> bool:
	var ok: bool = bool(db.call("query",sql))
	if not ok:
		push_error("SQL failed: %s :: %s" % [sql,str(db.get("error_message"))])
	return ok

func _scalar(db: Object, sql: String, key: String) -> Variant:
	assert(_q(db,sql))
	var rows: Array = db.get("query_result")
	assert(rows.size()==1)
	return (rows[0] as Dictionary).get(key)

func run() -> void:
	_cleanup()
	assert(ClassDB.class_exists("SQLite"),"godot-sqlite GDExtension class must load")
	var db: Object = ClassDB.instantiate("SQLite")
	assert(db!=null)
	db.set("path",DB_PATH)
	db.set("verbosity_level",0)
	assert(bool(db.call("open_db")),"SQLite.open_db must succeed")

	assert(_q(db,"PRAGMA journal_mode=WAL;"))
	var wal_rows: Array = db.get("query_result")
	assert(not wal_rows.is_empty())
	assert(str((wal_rows[0] as Dictionary).get("journal_mode","")).to_lower()=="wal")
	assert(_q(db,"PRAGMA synchronous=FULL;"))
	assert(int(_scalar(db,"PRAGMA synchronous;","synchronous"))==2)

	# Compatibility subset of the old Runtime Rebase World Core schema.
	assert(_q(db,"""
CREATE TABLE events (
	seq INTEGER PRIMARY KEY AUTOINCREMENT,
	event_id TEXT NOT NULL UNIQUE,
	created_at REAL NOT NULL,
	source_type TEXT NOT NULL,
	source_id TEXT NOT NULL,
	authority TEXT NOT NULL,
	truth_class TEXT NOT NULL,
	visibility TEXT NOT NULL,
	event_type TEXT NOT NULL,
	subject_id TEXT,
	object_id TEXT,
	room_id TEXT,
	from_value TEXT,
	to_value TEXT,
	reversibility TEXT NOT NULL,
	provenance TEXT NOT NULL,
	payload_json TEXT NOT NULL
);
"""))
	assert(_q(db,"""
CREATE TABLE object_current (
	object_id TEXT PRIMARY KEY,
	canonical_owner_id TEXT,
	current_holder_id TEXT,
	current_room_id TEXT,
	state TEXT NOT NULL,
	last_explicit_location TEXT,
	movement_reason TEXT,
	movement_authority TEXT,
	updated_event_id TEXT NOT NULL UNIQUE
);
"""))

	# Event append + reducer/current-state projection must commit together.
	assert(_q(db,"BEGIN IMMEDIATE;"))
	assert(bool(db.call("query_with_bindings",
		"INSERT INTO events(event_id,created_at,source_type,source_id,authority,truth_class,visibility,event_type,subject_id,object_id,room_id,from_value,to_value,reversibility,provenance,payload_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);",
		["EVT_REGISTER",1.0,"migration_import","qa","HISTORICAL_IMPORT",
		 "EXPLICIT_WORLD_FACT","house_public","OBJECT_REGISTERED","RES_01",
		 "OBJ_SQL","ROOM_A","","ROOM_A","PERSISTENT_UNTIL_CHANGED",
		 "SQLITE_SPIKE",JSON.stringify({"object_id":"OBJ_SQL","state":"PLACED"})]
	)))
	assert(bool(db.call("query_with_bindings",
		"INSERT INTO object_current(object_id,canonical_owner_id,current_holder_id,current_room_id,state,last_explicit_location,movement_reason,movement_authority,updated_event_id) VALUES(?,?,?,?,?,?,?,?,?);",
		["OBJ_SQL","RES_01","","ROOM_A","PLACED","ROOM_A",
		 "REGISTERED","HISTORICAL_IMPORT","EVT_REGISTER"]
	)))
	assert(_q(db,"COMMIT;"))
	assert(int(_scalar(db,"SELECT COUNT(*) AS n FROM events;","n"))==1)
	assert(str(_scalar(db,
		"SELECT current_room_id AS room FROM object_current WHERE object_id='OBJ_SQL';",
		"room"))=="ROOM_A")

	# Duplicate event ID is rejected and must not alter current state.
	assert(_q(db,"BEGIN IMMEDIATE;"))
	var duplicate_ok: bool = bool(db.call("query_with_bindings",
		"INSERT INTO events(event_id,created_at,source_type,source_id,authority,truth_class,visibility,event_type,reversibility,provenance,payload_json) VALUES(?,?,?,?,?,?,?,?,?,?,?);",
		["EVT_REGISTER",2.0,"system","qa","SYSTEM_RULE","EXPLICIT_WORLD_FACT",
		 "house_public","OBJECT_MOVED","PERSISTENT_UNTIL_CHANGED",
		 "SQLITE_SPIKE","{}"]
	))
	assert(not duplicate_ok)
	assert(_q(db,"ROLLBACK;"))
	assert(int(_scalar(db,"SELECT COUNT(*) AS n FROM events;","n"))==1)
	assert(str(_scalar(db,
		"SELECT current_room_id AS room FROM object_current WHERE object_id='OBJ_SQL';",
		"room"))=="ROOM_A")

	# Rollback must remove both event and projection mutation.
	assert(_q(db,"BEGIN IMMEDIATE;"))
	assert(bool(db.call("query_with_bindings",
		"INSERT INTO events(event_id,created_at,source_type,source_id,authority,truth_class,visibility,event_type,subject_id,object_id,room_id,from_value,to_value,reversibility,provenance,payload_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);",
		["EVT_ROLLBACK",3.0,"system","qa","SYSTEM_RULE","EXPLICIT_WORLD_FACT",
		 "house_public","OBJECT_MOVED","RES_01","OBJ_SQL","ROOM_B","ROOM_A",
		 "ROOM_B","PERSISTENT_UNTIL_CHANGED","SQLITE_SPIKE","{}"]
	)))
	assert(bool(db.call("query_with_bindings",
		"UPDATE object_current SET current_room_id=?,movement_reason=?,updated_event_id=? WHERE object_id=?;",
		["ROOM_B","PLACED","EVT_ROLLBACK","OBJ_SQL"]
	)))
	assert(_q(db,"ROLLBACK;"))
	assert(int(_scalar(db,"SELECT COUNT(*) AS n FROM events;","n"))==1)
	assert(str(_scalar(db,
		"SELECT current_room_id AS room FROM object_current WHERE object_id='OBJ_SQL';",
		"room"))=="ROOM_A")

	# Real committed move establishes a second monotonic sequence.
	assert(_q(db,"BEGIN IMMEDIATE;"))
	assert(bool(db.call("query_with_bindings",
		"INSERT INTO events(event_id,created_at,source_type,source_id,authority,truth_class,visibility,event_type,subject_id,object_id,room_id,from_value,to_value,reversibility,provenance,payload_json) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);",
		["EVT_MOVE",4.0,"system","qa","SYSTEM_RULE","EXPLICIT_WORLD_FACT",
		 "house_public","OBJECT_MOVED","RES_01","OBJ_SQL","ROOM_B","ROOM_A",
		 "ROOM_B","PERSISTENT_UNTIL_CHANGED","SQLITE_SPIKE",
		 JSON.stringify({"movement_kind":"PLACED","state":"PLACED"})]
	)))
	assert(bool(db.call("query_with_bindings",
		"UPDATE object_current SET current_room_id=?,movement_reason=?,movement_authority=?,updated_event_id=? WHERE object_id=?;",
		["ROOM_B","PLACED","SYSTEM_RULE","EVT_MOVE","OBJ_SQL"]
	)))
	assert(_q(db,"COMMIT;"))
	assert(int(_scalar(db,"SELECT COUNT(*) AS n FROM events;","n"))==2)
	assert(int(_scalar(db,"SELECT MAX(seq) AS seq FROM events;","seq"))==2)

	assert(bool(db.call("close_db")))
	db = null

	# Close/reopen persistence and replay equivalence.
	var reopened: Object = ClassDB.instantiate("SQLite")
	reopened.set("path",DB_PATH)
	reopened.set("verbosity_level",0)
	assert(bool(reopened.call("open_db")))
	assert(str(_scalar(reopened,
		"SELECT current_room_id AS room FROM object_current WHERE object_id='OBJ_SQL';",
		"room"))=="ROOM_B")
	assert(int(_scalar(reopened,"SELECT COUNT(*) AS n FROM events;","n"))==2)
	assert(_q(reopened,"SELECT event_id,to_value FROM events ORDER BY seq;"))
	var ordered: Array = reopened.get("query_result")
	assert(str((ordered[0] as Dictionary)["event_id"])=="EVT_REGISTER")
	assert(str((ordered[1] as Dictionary)["event_id"])=="EVT_MOVE")
	assert(bool(reopened.call("close_db")))
	reopened = null

	_cleanup()
	print("NATIVE_SQLITE_V49_SPIKE_PASS gdextension=loaded godot=4.7.2 wal=yes synchronous=full transaction=atomic duplicate=idempotent rollback=yes reopen=yes seq=monotonic")
	quit(0)
