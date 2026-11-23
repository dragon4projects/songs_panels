# Dragon House v0.21 — SQLite Object Truth Core Integration Handoff

Date: 2026-11-23  
Role: INTEGRATOR  
Status: integration candidate; NOT owner approval  
Production base used for clean integration: `1216e2f1a737008e3d9fea0f5d240d54a78a6ea2`

## Scope boundary

v0.21 migrates exactly one persistent mutation family to the SQLite target architecture:

- physical object registration;
- object pickup / holder transfer;
- placement / stash;
- ambient protection policy change;
- lost-found recovery;
- restore-home;
- object provenance / explanation.

It does **not** claim that the whole House is event-sourced.

Still compatibility/snapshot owned after v0.21:
- room topology/build mutations;
- resident/guest durable state as a whole;
- creature registry/state as a whole;
- media catalog/reading state;
- private door registry;
- scheduler runtime state;
- other House metadata.

Those families must migrate one at a time through the same strangler discipline.

## Reused engineering lineage

Historical source/evidence:
- Mora/RC1.5 repository `dragon4projects/dragon_cave_godot@a55ee0...`;
- Library Iteration 2 package `DRAGON_HOUSE_RUNTIME_REBASE_V2_ITER2_2026-11-20.zip`;
- Library Iteration 4 package `DRAGON_HOUSE_RUNTIME_REBASE_V2_ITER4_2026-11-20.zip`.

The old package was not trusted only by documentation:
- Iteration 2 bundled Python World Core tests were re-executed: 6/6 PASS;
- Iteration 4 bundled Python World Core/API tests were re-executed: 9/9 PASS.

Preserved old architecture properties:
- SQLite WAL;
- `synchronous=FULL`;
- append-only canonical event identity;
- transaction boundary around event append + derived projection;
- truth/permission gate before persistent mutation;
- reducer-owned current object projection;
- canonical event replay rebuilds derived state;
- renderer/presentation cannot elevate itself to world truth;
- migration inputs remain non-destructive.

## v0.20 -> v0.21 spine

Existing v0.20 spine remains:
`WorldModel API -> ObjectEventRuntime -> WorldEventGate -> EventStore -> ObjectEventReducer -> world.objects projection`.

v0.21 replaces the normal durable event-store backend for this family:
- old compatibility backend: `world_event_store.gd` JSON append log;
- normal backend: `world_event_store_sqlite.gd`.

The public WorldModel object APIs remain stable, so ambient-creature callers and UI callers do not write SQLite directly.

## SQLite layout

Current deliberately narrow tables:
- `schema_meta`;
- `events` — canonical append-only object event stream;
- `objects` — disposable derived object projection.

This is intentionally not the old full schema yet. Empty rooms/residents/permissions/media tables would be architecture theatre until their mutation families actually move behind the reducer.

## Default / compatibility selection

With the vendored SQLite GDExtension available:
- a clean world selects SQLite by default;
- an existing v0.20 JSON event stream is automatically migrated to SQLite;
- a pre-v0.20 JSON object snapshot is automatically migrated to typed import events;
- explicit env `DRAGON_OBJECT_EVENT_BACKEND=json` remains available only for legacy QA on a world that has not cut over;
- once a SQLite canonical store exists (or saved runtime state marks SQLite), SQLite is sticky and always wins;
- an env request for JSON cannot downgrade an already-cut-over world to stale JSON history;
- if a cut-over world cannot load SQLite, it fails closed rather than silently changing truth source.

## Canonical migration guarantees

### v0.20 JSON event stream -> SQLite
- source JSON remains byte-for-byte unchanged;
- every imported event keeps exact `event_id` and `seq`;
- event order is validated;
- reducer replay builds the candidate projection;
- events + derived projection commit in one SQLite transaction;
- persisted projection is compared against reducer projection;
- after cutover, new canonical events advance only SQLite;
- old JSON remains historical migration evidence.

### pre-v0.20 object snapshot -> SQLite
- source world snapshot remains non-destructive migration input;
- each existing object becomes a typed `migration_import` event;
- authority: `HISTORICAL_IMPORT`;
- truth class: `EXPLICIT_WORLD_FACT`;
- legacy per-object history is preserved in the projected object;
- restart is thereafter SQLite-canonical.

## Recovery / rebuild

SQLite primary readability is validated as a whole, not merely by successful file open.

If primary is unreadable:
1. primary and sidecars are quarantined;
2. backup is copied;
3. backup must pass open + schema + event-stream load before being accepted.

If primary and backup are both unusable:
- compatibility JSON snapshot may remain inspectable;
- durable object mutations fail closed;
- no new empty canonical stream is invented.

The `objects` table is explicitly disposable:
- canonical `events` replay is authoritative;
- if derived objects differ from reducer replay, the projection is rebuilt transactionally;
- canonical event `seq/event_id` are never rewritten by projection repair.

## Vendored dependency / source closure

Dependency:
- upstream `2shady4u/godot-sqlite`;
- release v4.9;
- upstream commit `9cbdb225823ee111342ce32fe451e066eb92cc6e`;
- upstream release `addons.zip` SHA-256:
  `95e91b72fe32984a84edaf6357a78753661f37a170cb362f5b948e0ede7c2cb0`;
- upstream compatibility minimum: Godot 4.7;
- Dragon House engine: Godot 4.7.2.

Vendored only:
- Linux x86_64 debug/release;
- Windows x86_64 debug/release;
- macOS universal debug/release frameworks;
- trimmed `gdsqlite.gdextension`;
- MIT plugin license;
- SQLite public-domain dedication;
- provenance note.

Android/iOS/Web binaries are deliberately absent.

Native binaries are stored in Git LFS under
`dragon_house_clean/addons/godot-sqlite/bin/**`,
separate from the Dragon House art manifests.

One-shot vendoring workflow was removed after successful source closure.

## Evidence

### Existing production baseline
- production `1216e2f1a737008e3d9fea0f5d240d54a78a6ea2`;
- full production acceptance #44 / `45203091451`: SUCCESS.

### v0.21 proof before vendoring
Final Linux backend proof:
- run #16 / `45206673425`: SUCCESS.

Final real-LFS Windows/macOS packaging proof:
- run #10 / `45206696566`: SUCCESS.
- all five final v0.21 migration/recovery/rebuild tests PASS;
- Windows export contains `libgdsqlite.windows.template_release.x86_64.dll`;
- macOS app contains `libgdsqlite.macos.template_release.framework`;
- macOS ZIP integrity PASS;
- real LFS bytes used.

### Source closure
One-shot vendoring:
- run #1 / `45208242538`: SUCCESS.

Vendored SQLite source-closure, external SQLite download forbidden:
- run #1 / `45208661619`: SUCCESS (pre-default-cutover proof).
- final default-cutover source-closure run #8 / `45210009719`: SUCCESS; default SQLite also proven through v0.17 object lifecycle and v0.18 ambient-creature integration.

Key v0.21 signals:
- `OBJECT_EVENT_SQLITE_V021_PASS`;
- `OBJECT_EVENT_JSON_TO_SQLITE_V021_PASS`;
- `OBJECT_EVENT_SQLITE_RECOVERY_V021_PASS`;
- `OBJECT_EVENT_SNAPSHOT_TO_SQLITE_V021_PASS`;
- `OBJECT_EVENT_PROJECTION_REBUILD_V021_PASS`;
- `SQLITE_SOURCE_CLOSURE_V021_PASS`;
- `SQLITE_EXPORT_V021_PASS`.

## Production acceptance changes

The main production LFS/Godot workflow in this integration branch now:
- fetches the vendored SQLite LFS bytes;
- verifies native binaries are real bytes, not pointers;
- runs all v0.21 tests in addition to v0.20 regressions;
- exports Windows/macOS with the vendored GDExtension;
- requires the Windows SQLite release DLL;
- adds that DLL to the private Windows ZIP;
- requires the macOS release framework inside the exported app/ZIP.

This closes a packaging seam found during integration: Godot correctly emitted the Windows DLL beside the EXE, but the older private ZIP command would have omitted it.

## Explicit non-claims

- Machine PASS is not Dragon visual approval.
- SQLite migration here does not authorize any new object owner, pet relation, private-room access, artifact placement, guest assignment or content truth.
- No TEEA/ZNA art/content branch is merged by this work.
- This is not yet a full-house SQLite World Core.
- Real Dell Latitude 5300 / Intel UHD 620 and owner M1 execution remain separate target-hardware qualification.

## Next Integrator block after v0.21 production acceptance

Return to INT-P0-002 completion, reusing old Iteration 4 commitment semantics:
- explicit `minimum_commit_until`;
- declared interrupt reasons;
- persist deterministic RNG/decision state;
- remove wall-clock daypart nondeterminism from decision layer;
- explicit wake sources from object/permission/station/media/social events;
- 24-active-resident proportional-planner proof;
- same seed + same event stream deterministic decision sequence;
- planner timing evidence.

Do not mix this scheduler completion into the v0.21 persistence merge.
