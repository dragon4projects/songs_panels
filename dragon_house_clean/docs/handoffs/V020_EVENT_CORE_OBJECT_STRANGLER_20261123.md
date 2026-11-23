# Dragon House v0.20 — object event/provenance strangler

Date: 2026-11-23
Integrator branch: `dev/dragon-house-v020-event-core-object-strangler`
Base: `dragon-house-fallout-fresh@e8f788655170f7a2f42edee909dd0e2c54f8968e`
Historical engineering evidence: `dragon4projects/dragon_cave_godot@a55ee0ec8c8cc2ff39c1015e672464b99ec1eba2`

This is an engineering handoff/provenance record. It is not owner visual approval and it does not promote old Mora content into the current House.

## Scope

v0.20 is intentionally a narrow strangler around **physical-object mutations only**.

It does not event-source residents, guests, rooms, media, scheduler state or creature life yet.
It does not introduce SQLite yet.
It does not reintroduce the historical localhost HTTP World Core.

The current compatibility JSON snapshot remains present while object mutations begin moving behind:

```text
permission/invariant checks
-> canonical object event envelope
-> durable append
-> reducer projection
-> compatibility snapshot
```

## Historical guarantees selectively reused

Inspected historical sources:

- `core_client.gd`
- `qa/core_outbox_replay_qa.gd`
- `content_system/content_store.gd`

Reused guarantees:

- stable event IDs inside one durable event store;
- explicit `source_type`, `source_id`, `authority`, `truth_class`;
- expected-revision / per-subject revision checks;
- duplicate event ID is idempotent only when the whole envelope is identical;
- same ID with a different envelope is rejected;
- semantically invalid events are rejected **before** durable commit;
- durable history is revalidated on load;
- temp write + flush + verification + atomic replace;
- prior durable store retained as `.bak`;
- unreadable/corrupt history fails closed instead of being silently replaced;
- event projection can reconstruct object state independently of the compatibility snapshot.

Explicitly not copied:

- HTTP transport;
- local token/config plumbing;
- old renderer/service topology;
- old resident/content IDs;
- old room coordinates;
- old production schema.

## Current implementation

### `scripts/world_event_core.gd`

Local JSON event backend for the first strangler slice.

Current truth classes accepted:

- `EXPLICIT_WORLD_FACT`
- `AMBIENT_SIMULATION`
- `PRESENTATION_ONLY`

Current object events:

- `OBJECT_REGISTERED`
- `OBJECT_BASELINE_IMPORTED`
- `OBJECT_AMBIENT_PROTECTION_CHANGED`
- `OBJECT_PICKED_UP`
- `OBJECT_PLACED`
- `OBJECT_STASHED`
- `OBJECT_RECOVERED_TO_LOST_FOUND`
- `OBJECT_RESTORED_HOME`

A pre-v0.20 object receives one `OBJECT_BASELINE_IMPORTED` event on its first post-v0.20 mutation. This is the strangler migration boundary: existing saves are not destroyed or mass-rewritten.

### `scripts/world_model.gd`

Existing permission checks remain in WorldModel.

After permission checks, the object state no longer mutates directly. The transition is appended to the local event store and the reducer projection becomes the new `objects[object_id]` state.

Protected semantics retained:

- canonical owner is independent of current holder/location;
- holder/location are mutually exclusive for a held object;
- private-room access checks still gate pickup/place;
- recoverability and ambient-protection checks remain explicit;
- no object duplication is introduced;
- the House journal receives the canonical event ID, authority and truth class.

The event backend path is derived from the compatibility save:

```text
<save_path>.events.json
```

This keeps tests and alternate save paths isolated.

## Recovery behavior

If the compatibility world snapshot is readable:

1. load it;
2. load the event store;
3. overlay event-sourced object projections;
4. reconcile causal journal rows.

If the compatibility snapshot is missing but the object event store is valid:

1. seed deterministic topology/resident baseline without clearing the event store;
2. rebuild event-sourced object projections;
3. reconstruct event-backed journal rows;
4. write a fresh compatibility snapshot.

This does **not** claim that all world state can yet be rebuilt from events. Only the v0.20 physical-object slice has that guarantee.

## Tests

New destructive test:

`tests/test_world_event_core_v020.gd`

It proves:

- registration creates a durable explicit-fact event;
- exact duplicate event ID/envelope is idempotent;
- stale expected revision is rejected;
- structurally valid but semantically impossible object transition is rejected before persistence;
- Manjka pickup/stash keeps canonical ownership unchanged;
- object state rebuilds from event history with no compatibility snapshot;
- reconciled journal contains each durable event ID once;
- ambient protection and lost-found recovery remain functional;
- durable history survives restart.

Existing `test_object_lifecycle_v017.gd` remains in the suite and is the backwards-compatibility guard for the public object API.

## Deliberate non-goals / next gates

Not closed by v0.20:

- event sourcing of resident/guest/media/room mutations;
- complete reducer-owned world state;
- SQLite backend;
- migration from JSON event backend to SQLite;
- hardware qualification;
- owner-facing UI for event history.

Next expansion is allowed only after object-event equivalence passes the full production acceptance suite. SQLite should come after event/reducer semantics are stable, not before.

## Acceptance rule

v0.20 may be proposed to production only if:

- full LFS audit remains green;
- Godot 4.7.2 import remains clean;
- all existing tests remain green;
- `WORLD_EVENT_CORE_V020_PASS` is present;
- current v0.19 production base CI is green;
- no object lifecycle regression is observed.

No production merge is implied by this document.
