# TEEA_INT_20261123_007 — FINAL ARTIST HANDOFF

Date: 2026-11-23
Role: TEEA / INTERIORS ONLY
Machine status: BLOCKED_EXTERNAL_GUEST_ALPHA_ONLY
Owner approved: false
Approved: false
Production mutated by TEEA007: no
Production PR: NONE

Branch:
`art/teea-interiors-TEEA_INT_20261123_007`

Branch head before final handoff publication:
`7322b7e9a76ad212e8b70f96119edb8be893f186`

Current production head rechecked:
`dragon-house-fallout-fresh@1216e2f1a737008e3d9fea0f5d240d54a78a6ea2`

## Immutable binary payload

URL:
https://d2ol7oe51mr4n9.cloudfront.net/user_3JdI9kJ82xObF8Bi3EgU4P6DaoR/13095c35-c1b0-4b5d-b0cf-9a0a7dbba489.zip

SHA-256:
05f734b2af745a062a4942653834e38149b10301c9bb035b4682ae7004a78cbb

Archive size: ~25 MiB  
ZIP integrity: PASS  
Internal root: dragon_house_teea007_drop_FINAL/

Final TEEA006 geometry source:
`art/teea-interiors-TEEA_INT_20261123_006@887e5f1c874c7fb0deb600c58c06ad4e5dafb90f`

The immutable binary URL/SHA and final post-publication branch head are reported by the Library handoff pointer. This document intentionally does not pretend a commit can contain its own resulting SHA.

## Machine gates

| Gate | Status | Evidence |
|---|---|---|
| PASS-A | **BLOCKED** | 3/3 named guest room candidates exist; build adjacency, access semantics, measured geometry, entry/stations/collision and conservative runtime-plane clearance pass. Exact canonical guest PNG alpha/body footprints cannot be measured because the canonical candidate PNG bytes are Git LFS on the divergent ZNA art branch and are absent from current production. No guessed alpha silhouette is claimed. |
| PASS-B | **PASS** | 32 neutral media surfaces total. Library 5 remain exact TEEA005 bindings. The 27 Music/Cinema/Artifact surfaces that previously waited on TEEA006 are now bound to final TEEA006 geometry with zero binding errors. Cinema retains a real screen/viewing area and a separate TV/console/gamepad nook. No actual media content is baked. |
| PASS-C | **PASS** | Project-original polygon mugs: LOD0 empty/filled + LOD1, source BLEND + GLB, valid open mouth/rim/handle, topology QA, tabletop hand-envelope proof and Godot GLTF parse pass. |
| PASS-D | **BLOCKED** | Payload/provenance/SHA/contact/Godot/HOUSE-LEVEL-ROOM/current-camera/geometry/approach evidence pass. Final TEEA006 media binding and 27/27 current-camera media-holder yaw proofs pass. Only exact canonical guest-sprite alpha/body-footprint and actual-sprite yaw/occlusion proof remains externally blocked. |
| PASS-E | **PASS** | `approved:false`, `owner_approved:false`, production untouched, isolated art branch, no production PR. |

## What changed after TEEA006 completed

The old blocker `BLOCK_TEEA006_MEDIA_ROOM_FINALS` is **RESOLVED**.

New exact evidence:
- `metadata/TEEA_INT_20261123_007_media_binding_006_final.json`
  - 27/27 formerly dependent surfaces bound;
  - validation errors: 0.
- `metadata/TEEA_INT_20261123_007_media_hooks.json`
  - old `TEEA006_INTEGRATION_REQUIRED` state removed for Music/Cinema/Artifact;
  - final state = `READY_EXACT_TEEA006_FINAL`.
- `metadata/TEEA_INT_20261123_007_media_yaw_proof_report.json`
  - 9 room variants × 3 manual yaws = 27/27 proof images;
  - machine errors: 0;
  - visual review: no obvious holder/station occlusion and no collapse of the separate Cinema game nook.
- wall-media runtime plane:
  - baked TEEA006 `back_decor` reference z = -1.63 m;
  - runtime holder/display plane z = -1.55 m;
  - deliberate front offset = +0.08 m so runtime media is not hidden behind baked art.

Current camera contract was rechecked at production `1216e2f1...`:
- Perspective camera;
- FOV = 35°;
- ROOM zoom R1/R2/R3 = 10.8 / 13.9 / 17.0;
- close bias = `clamp((48 - zoom)/34, 0, 1) * 0.075`;
- proof manual yaw = -0.18 / 0 / +0.18, with effective yaw recorded per frame.

## Guest rooms

Named guest profiles:
- `guest_centaur` -> `NPC_CENTAUR` / Кентавр
- `guest_vampire` -> `NPC_VAMPIRE_GIRL` / Вампирша
- `guest_miu` -> `NPC_GINGER_CAT_GUEST` / Миу

Proposed cells:
- `guest_centaur_01` -> (6,0), adjacent to lift (5,0)
- `guest_vampire_01` -> (6,1), adjacent to lift (5,1)
- `guest_miu_01` -> (6,-1), adjacent to lift (5,-1)

All three proposed builds pass adjacency to the circulation spine.

Access semantics reused from current production:
- guest rooms are not sibling-private rooms;
- open guest -> public cutaway allowed;
- closed guest -> public cutaway denied;
- later open/closed state remains integrator-configurable.

Geometry:
- doors: 2.10 × 2.45 m;
- Centaur turning diameter: 2.50 m;
- conservative complete runtime Sprite3D plane: 1.9 × 1.9 m;
- conservative geometry/access proof passes.

Миу remains physiology-neutral in TEEA art metadata: no invented humanoid chair/body assumptions.

## Remaining external blocker — exact guest alpha

Canonical candidate paths:
- `assets/residents/NPC_CENTAUR/identity/front_0001.png`
- `assets/residents/NPC_VAMPIRE_GIRL/identity/front_0001.png`
- `assets/residents/NPC_GINGER_CAT_GUEST/identity/front_0001.png`

Observed ZNA candidate branch:
`art/znaechka-characters-ZNA_CHAR_NPC_20261123_001@994eb3f66436b2985cb94b1fc98b82274d8141c6`

GitHub fetch returns LFS pointers:
- Centaur: `sha256:2abcd9620fb249b37079235745516224bc39b46be6c4abec35fd69cd22fea47f`
- Vampire: `sha256:501284e9724441533d9cc34648c6956c564a1a097008f4e2b15bea6238f65fee`
- Миу: `sha256:5f3eb9dc8efef0c14a96de47887a099e9dec90d9cb0f14cb65162b5e66e05804`

Independent production checks:
- current production tree `1216e2f1...`: **0** matching guest art paths;
- successful production CI run `45200296771` at `78f2ae...` was downloaded;
- artifact `14830708047`, `DragonHouse_v014.pck`, was opened through Godot 4.7.2;
- all three exact guest identity `res://` paths were absent.

Therefore TEEA cannot truthfully compute exact alpha bounds from current production and must not substitute a composite atlas or invented silhouette.

Required closure:
Integrator/ZNA materializes the exact canonical LFS PNG bytes, computes non-transparent alpha bounds/world footprint and reruns the actual-sprite guest yaw/occlusion proof. No interior redesign is required by the current evidence.

## Functional room / media state

Library:
- PASS;
- exact TEEA005 reading/shelf anchors;
- 5 exact book surfaces;
- no appliance warehouse.

Music:
- PASS;
- final TEEA006 listening/equipment geometry;
- 9 exact runtime audio surfaces;
- neutral holders only.

Cinema:
- PASS;
- final TEEA006 screen and depth-separated viewing seating;
- 9 exact film surfaces;
- separate TV + console + gamepad nook retained.

Artifact:
- PASS;
- final TEEA006 reachable display geometry;
- 9 exact artifact label/preview surfaces;
- station-bound labels reuse already-passing TEEA006 approach/collision paths.

Common R2 addendum:
- PASS;
- one measured Sofa_01 rest station;
- one project-original fur floor-rest station;
- two sparse runtime mug slots;
- foreign furniture overlaps: 0;
- blocked existing approaches: 0.

## Mugs / props

Project-original:
- `dragon_mug_lod0_empty`
- `dragon_mug_lod0_filled`
- `dragon_mug_lod1_empty`

Godot-visible mug anchors:
- `PLACEMENT_ANCHOR`
- `PICKUP_ANCHOR`
- `RIM_CENTER`

Neutral holder GLBs:
- `media_holder_book`
- `media_holder_film_poster`
- `media_holder_film_screen`
- `media_holder_audio`
- `media_holder_artifact`

Holder nodes:
- `MEDIA_SURFACE`
- `LABEL_ANCHOR`
- `HOVER_HIT`
- `FULLSCREEN_TRIGGER_ANCHOR`
- `PLACEMENT_ANCHOR`

## QA summary

- guest room production-candidate PNG: 13/13 exact 1536×1024 RGBA8 PASS
- GLB Godot parse: 9/9 PASS
- prop topology round-trip: PASS
- guest geometry/access: PASS against conservative runtime plane
- HOUSE/LEVEL/ROOM scale report: PASS
- guest conservative current-camera yaw proof: PASS
- final TEEA006 media surface binding: 27/27 PASS
- media current-camera yaw proof: 27/27 PASS
- media binding machine errors: 0
- exact canonical guest alpha/body footprint: **BLOCKED_EXTERNAL_ZNA_LFS_ART_NOT_IN_PRODUCTION**
- owner approval: false
- production mutation: none

Final machine status is intentionally **BLOCKED_EXTERNAL_GUEST_ALPHA_ONLY**, not READY_FOR_INTEGRATOR_QA, because PASS-A and PASS-D explicitly require the actual canonical guest-sprite footprint.
