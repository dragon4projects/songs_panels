# TEEA_INT_20261123_007 — INTEGRATOR HANDOFF

Date: 2026-11-23
Owner approval: false
Production mutated by TEEA007: no

## Routing

- Base production: `dragon-house-fallout-fresh@c280f62778bcc4a4ac0093db48a852f0469b6bf2`
- TEEA007 branch: `art/teea-interiors-TEEA_INT_20261123_007`
- Library pointer:
  `/Dragon cave/DRAGON_HOUSE_ARCHITECT_2026-09-29/INTEGRATOR_DROP_TEEA007_20261123/TEEA_INT_20261123_007_HANDOFF_POINTER.md`
- Full binary drop filename: `Dragon_House_TEEA007_integrator_drop.zip`
- Full binary drop SHA256:
  `3bcec6d95001cd3f240d2cb014634264fd9772638ef85ae548ff8f9c81b4c89c`
- Permanent binary-drop URL:
  `https://d2ol7oe51mr4n9.cloudfront.net/user_3JdI9kJ82xObF8Bi3EgU4P6DaoR/b635be89-3a5d-4c28-b48b-a00d1db81c5d.zip`
- Archive manifest: 85 entries, zero missing referenced files.
- Archive integrity: PASS (`unzip -t`).

Active overlapping TEEA006 remains separate:
`art/teea-interiors-TEEA_INT_20261123_006@ac44724c39275d365c185af0435b6dea676d24ae`.

## Machine gate table

| Gate | Status | Evidence |
|---|---|---|
| PASS-A | PASS | 3/3 named guest room art profiles; measured geometry/stations/approaches; v0.18 guest access contract; 2.10×2.45 m doors; Centaur 2.50 m turning envelope; yaw -0.18/0/+0.18. |
| PASS-B | BLOCKED | Library/Common pass. Exact Cinema/Music/Artifact placement intentionally waits for unfinished overlapping TEEA006. Holder geometry and metadata are already delivered. |
| PASS-C | PASS | Project-original polygon mugs LOD0 empty/filled + LOD1; GLB round-trip manifold; source BLEND included; tabletop-access proof; Godot parse PASS. |
| PASS-D | PASS | 13/13 RGBA8 room PNG 1536×1024; 9/9 GLB Godot 4.7.2 parse; source attribution, contact sheets, yaw proof, payload manifest and SHA256 included. |
| PASS-E | PASS | Production branch untouched; isolated 007 branch created from current production; Library pointer and GitHub handoff reported; owner_approved=false. |

## A — guest rooms

Three candidate R1 art profiles:
- `guest_centaur` → `NPC_CENTAUR` / Кентавр
- `guest_vampire` → `NPC_VAMPIRE_GIRL` / Вампирша
- `guest_miu` → `NPC_GINGER_CAT_GUEST` / Миу

Important: these are **art-profile keys, not new room types**.

Production v0.18 owns canonical room type `guest`.
Bind with:
- `configure_guest_room(room_id, guest_id, display_name)`
- `set_guest_room_open(room_id, open)`

Current verified non-Manjka actor visual contract in `main.gd` is
`sprite.pixel_size = 1.9 / texture_height`.
The guest banks are 512×512, therefore the full runtime visual plane is conservatively bounded by 1.9×1.9 m. TEEA007 room access was re-authored and re-tested against that complete plane, rather than pretending unavailable LFS alpha silhouettes had been inspected.

Миу remains physiology-neutral. Her perch/rest/feed locations are conditional integration hooks; no humanoid/quadruped form is silently canonized.

## B — public-room function work

PASS now:
- Library: measured reading stations retained; 5 runtime book-preview surfaces added.
- Common R2 candidate: sofa rest + floor-fur rest + 2 sparse mug object slots.
  - no furniture collision overlap
  - no existing approach-path blockage
  - measured minimum station separation 1.179 m

Ready for TEEA006 binding:
- Cinema: primary film screen holder, neutral poster holders, separate TV/console/gamepad corner contract.
- Music: neutral audio holders plus boombox/cassette equipment contract.
- Artifact: neutral artifact label/preview holders.

No Kitchen was introduced. Kitchen assets remain reserve-only.

## C — mugs

Project-original assets:
- `dragon_mug_lod0_empty.glb/.blend`
- `dragon_mug_lod0_filled.glb/.blend`
- `dragon_mug_lod1_empty.glb/.blend`

Round-trip QA after GLB import:
- ceramic boundary edges = 0
- ceramic non-manifold edges = 0

Godot 4.7.2 sees:
- `PLACEMENT_ANCHOR`
- `PICKUP_ANCHOR`
- `RIM_CENTER`

Tabletop hand-envelope authoring proof is included.

## D — media holders

Neutral physical holders:
- book
- film poster
- film screen
- audio
- artifact

Every holder contains:
- `MEDIA_SURFACE`
- `LABEL_ANCHOR`
- `HOVER_HIT`
- `FULLSCREEN_TRIGGER_ANCHOR`
- `PLACEMENT_ANCHOR`

Current production v0.18 API:
`register_content_hotspot(anchor, category, item_id, display_name)`

Runtime category mapping:
- `book -> books`
- `film -> films`
- `audio -> tracks`
- `artifact -> artifacts`

No specific book cover, film poster, audio cover/recording, or artifact image is baked into neutral holder textures.

## QA

- Guest room geometry: PASS
- Guest yaw proof: PASS
- Final room PNG decode/size/mode: PASS
- Prop GLB round-trip topology: PASS
- Godot 4.7.2 parse: 9/9 GLB PASS
- Common R2 addendum geometry: PASS
- Payload manifest references: 0 missing
- ZIP integrity: PASS
- Production mutation: NONE
- Owner approval: false
