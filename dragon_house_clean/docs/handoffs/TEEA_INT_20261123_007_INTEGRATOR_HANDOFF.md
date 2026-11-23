# TEEA_INT_20261123_007 — CORRECTED INTEGRATOR HANDOFF

Date: 2026-11-23
Owner approval: false
Production mutated by TEEA007: no
Current integration target revalidated: dragon-house-fallout-fresh@917d2d02cbc5ac6b0d8b69539a6ec266a37ebbdc (v0.19)
TEEA007 branch: art/teea-interiors-TEEA_INT_20261123_007
Overlapping TEEA006 remains separate: art/teea-interiors-TEEA_INT_20261123_006@ac44724c39275d365c185af0435b6dea676d24ae.

This handoff supersedes the earlier 007 drop/pointer after camera, guest-access and evidence corrections.

## 2026-11-23 current-production revalidation

TEEA007 was rechecked after production advanced from `7710734af88483bbdc6f828d623b82561319f7e8` to `917d2d02cbc5ac6b0d8b69539a6ec266a37ebbdc`.

The nine-commit delta changes only `scripts/main.gd` and three detail/furniture tests. The production code now explicitly exposes `HOUSE / LEVEL / ROOM / FOLLOW`; detail modes are semantic, not numeric-zoom aliases. The final merge adds semantic furniture fallback proxies for data-owned `furniture_id` anchors when approved room art is unavailable. It does not change the ROOM camera/yaw/zoom values used by this handoff.

Therefore the existing TEEA007 camera, HOUSE/LEVEL/ROOM scale, guest-room geometry, Common R2, mug and holder evidence remains valid against current production. PASS-A remains blocked only because the available ZNA handoff proves 512×512 RGBA/non-empty alpha but does not publish exact alpha bounding boxes; PASS-B remains blocked by unfinished TEEA006 Cinema/Music/Artifact geometry.

## Exact machine gate table

| Gate | Status | Evidence |
|---|---|---|
| PASS-A | BLOCKED | 3/3 guest room candidates exist and geometry/access tests pass. Canonical room type is current production guest; proposed cells (6,0)/(6,1)/(6,-1) each pass adjacency to the existing lift spine. Doors are 2.10×2.45 m; Centaur turning diameter is 2.50 m. Exact canonical sprite alpha/body footprint cannot be claimed because the guest PNGs are Git LFS and sandbox LFS download returns HTTP 401. Conservative full runtime Sprite3D plane bound 1.9×1.9 m passes. |
| PASS-B | BLOCKED | Neutral holders and 32 media-hook records exist for books/films/tracks/artifacts; Library exact placement and separate Cinema TV/console/gamepad contract are ready. Exact Cinema/Music/Artifact physical placement waits for unfinished TEEA006 geometry. |
| PASS-C | PASS | Project-original polygon mugs: LOD0 empty/filled + LOD1, source BLEND + GLB, GLB round-trip weld-aware boundary/nonmanifold = 0, tabletop hand-envelope proof, Godot GLTF parse PASS. |
| PASS-D | BLOCKED | Payload/provenance/SHA/contact sheets/Godot/HOUSE-LEVEL-ROOM/current-camera yaw/geometry/approach tests exist, but exact canonical guest-sprite proof and final TEEA006 media-room placement proof remain externally blocked. |
| PASS-E | PASS | owner_approved=false; no production mutation; isolated 007 art branch and Library drop/pointer are used. Final branch head and new binary URL/SHA are reported in the Library pointer and final chat handoff. |

## Guest rooms

Art profile keys, not room types:
- guest_centaur -> NPC_CENTAUR / Кентавр
- guest_vampire -> NPC_VAMPIRE_GIRL / Вампирша
- guest_miu -> NPC_GINGER_CAT_GUEST / Миу

Canonical production room type is guest.

Proposed room IDs/cells:
- guest_centaur_01 -> (6,0) adjacent to lift (5,0)
- guest_vampire_01 -> (6,1) adjacent to lift (5,1)
- guest_miu_01 -> (6,-1) adjacent to lift (5,-1)

All three proposed builds pass the seed-world adjacency contract.

Runtime access contract is current production:
- configure_guest_room(room_id, guest_id, display_name)
- set_guest_room_open(room_id, open)
- open guest -> public cutaway allowed
- closed guest -> public cutaway denied

Миу remains physiology-neutral: 0 forced runtime stations, 4 form/scale-conditional physical hooks.

## Current camera proof

v0.19 current ROOM camera:
- R1 zoom 10.8
- R2 zoom 13.9
- automatic close-bias +0.075
- manual Q/E yaw -0.18 / 0 / +0.18
- effective yaw -0.105 / +0.075 / +0.255

Guest rooms were re-rendered at those effective current-camera values.

HOUSE/LEVEL/ROOM:
- proposed guest cells all pass build adjacency
- HOUSE zoom with proposed cells: 71.7542
- LEVEL 0 zoom: 69.1915
- LEVEL ±1 zoom: 36.3084
- ROOM R1 zoom: 10.8
- rich room art is correctly unloaded at HOUSE/LEVEL and loaded only near ROOM/FOLLOW.

## Common R2 addendum

Base: accepted TEEA005 Common R2.

Adds:
- one measured Sofa_01 rest station
- one project-original floor fur-rest station
- two sparse runtime mug slots

Geometry QA:
- foreign furniture overlaps: 0
- blocked existing approaches: 0
- minimum station separation: 1.179237 m
- sofa measured front edge: z≈+0.15, aligned to the accepted Common foreground plane
- current-camera R2 yaw proof PASS at the same manual/effective yaw values above.

## Library / media hooks

Library exact hook placement is bound to measured TEEA005 shelf anchors.

Current runtime API:
register_content_hotspot(anchor, category, item_id, display_name)

Runtime category mapping:
- book -> books
- film -> films
- audio -> tracks
- artifact -> artifacts

No specific content is baked into neutral holder textures.

TEEA006 dependency:
- current observed TEEA006 head is docs-only
- final Cinema/Music/Artifact holder transforms must bind after TEEA006 final geometry lands
- no 007 regeneration of those rooms is authorized or required.

## Mugs

Delivered project-original:
- dragon_mug_lod0_empty
- dragon_mug_lod0_filled
- dragon_mug_lod1_empty

Anchors visible in Godot:
- PLACEMENT_ANCHOR
- PICKUP_ANCHOR
- RIM_CENTER

## Media holder GLBs

- media_holder_book
- media_holder_film_poster
- media_holder_film_screen
- media_holder_audio
- media_holder_artifact

Godot-visible holder nodes:
- MEDIA_SURFACE
- LABEL_ANCHOR
- HOVER_HIT
- FULLSCREEN_TRIGGER_ANCHOR
- PLACEMENT_ANCHOR

## QA summary

- production-candidate room PNG: 13/13 exact 1536×1024 RGBA8 PASS
- GLB Godot parse: 9/9 PASS
- prop topology round-trip: PASS
- guest geometry: PASS against conservative current runtime visual plane
- H/L/R scale report: PASS
- current-camera yaw proof: PASS
- exact canonical guest alpha/body footprint: BLOCKED by Git LFS authorization
- final Cinema/Music/Artifact physical binding: BLOCKED by unfinished TEEA006
- owner approval: false
- production mutation: none
