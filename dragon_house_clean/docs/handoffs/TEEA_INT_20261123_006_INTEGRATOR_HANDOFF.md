# TEEA_INT_20261123_006 — INTEGRATOR HANDOFF

Date: 2026-11-23
Role: TEEA / interiors only
Machine status: READY_FOR_INTEGRATOR_QA
Owner approved: false
Production mutated by TEEA006: no
Current production target rechecked before handoff: dragon-house-fallout-fresh@1216e2f1a737008e3d9fea0f5d240d54a78a6ea2

## Scope delivered

Candidate replacement art for all 12 requested variants:
- Music R1 / R2 / R3
- Cinema R1 / R2 / R3
- Artifact R1 / R2 / R3
- Workshop R1 / R2 / R3

Existing owner-approved R1 art is not overwritten by this handoff.

## Production image contract

- 48 production PNG
- 4 roles per variant: backdrop, back_decor, furniture_back, foreground
- exact final size: 1536x1024
- RGBA8
- deterministic Blender physical scene rendered at 768x512 then non-generatively resampled with Pillow/Lanczos to the exact runtime size
- SHA-256 published for every final production PNG
- no .import files
- approved:false
- owner_approved:false

The half-resolution source render keeps software-EGL/llvmpipe authoring practical in the remote sandbox. Geometry, camera, depth, layers, alpha and object composition come from the same deterministic authored scene. No generative repainting is used during resampling.

## Physical authoring calibration

- module width: 4.8 m
- Godot back wall: z = -2.04 m
- public approach aisle: z = +0.95 m
- axis mapping: godot_z = -blender_y
- shallow physical shell includes floor recession, rear wall, ceiling thickness, side returns and a low front floor lip
- foreground is a measured physical shell/floor-edge contributor, not an arbitrary depth curtain

## Functional contract

The semantic station intent from TEEA003/004 is preserved:
- Music: LISTEN
- Cinema: WATCH
- Artifact: VIEW / INSPECT
- Workshop: USE

Measured stations delivered: 33.

Strict independent geometry validator:
- station bounds errors: 0
- module index errors: 0
- spacing errors: 0
- foreign collision / approach intersections: 0
- stations inside unrelated furniture: 0
- missing source collision footprints: 0

Two authoring defects were caught and corrected before handoff:
1. Workshop work points initially fell inside workbench depth footprints; benches/stations were physically separated and all Workshop variants re-rendered/revalidated.
2. Artifact R2/R3 pedestal view points initially overlapped the displayed statue footprint; view points were moved in front of the measured statue front plane and proofs were re-rendered/revalidated.

## Depth / yaw evidence

- depth_readability_machine_pass: 12/12
- strict R2/R3 functional cross-band separation >= 0.45 m: PASS
- shell-only proof: 12/12
- yaw proof: 12/12 at -0.18 / 0 / +0.18
- grayscale 25% proof: 12/12
- yaw frames are machine-distinct for all variants
- grayscale depth separation threshold passes for all variants

Visual pixels could not be returned through the current Higgsfield connector to the model for an independent human-eye verdict. This handoff therefore claims machine/geometry/render QA only, not owner visual approval. Contact sheets and yaw/shell/grayscale evidence are included for Integrator/Dragon review.

## Room-specific functional decisions

### Music
Rear audio/media storage and equipment; boombox and portable cassette player form accumulated listening-room dressing. Mismatched listening chairs occupy staggered Z. Wide variants are not repeated R1 bays.

### Cinema
The main cinema screen remains the primary film-viewing function. Television_01 plus gaming_console plus gamepad form a separate secondary game corner. Main screen and game corner are distinct physical/local clusters. Viewing seats occupy staggered depth.

### Artifact
Asymmetrical curiosity-cabinet layout. Only normalized steel_frame_shelves_01 is used; the broken x10 source is never used for placement. steel_frame_shelves_03, Chinese cabinet, chest, shell, bronze/gothic objects and katana stand create mixed non-museum staging. No canonical object biography is invented.

### Workshop
Rear worn storage, chemistry/Bunsen and practical clutter; workbenches and human work stations have clear physical approaches. metal_stool_01 is only a cat-perch candidate and is not promoted to a human station. TEEA authors no cat ownership or behavior.

## Poly Haven harvest

Harvest archive SHA-256:
db6a8f396e700c22a49f7ac75e06907f75c1691616176c491e8ef8acca726dbd

All used assets are tracked with transform, bbox, depth band, provenance and use class.

Hard checks:
- normalized steel shelf used: PASS
- READY_BUT_ODD clocks used without review: no
- Kitchen reserve leak: no
- Private reserve leak: no
- runtime 3D prop candidates: none; harvested props remain BAKED_ART_SOURCE

## Godot 4.7.2 gate

Exact engine: 4.7.2.stable.official.ed1daf0bf

Result:
TEEA006_GODOT_4_7_2_IMAGE_LOAD_PASS count=48 size=1536x1024 format=RGBA8 texture=ImageTexture

## Production compatibility recheck

Production advanced to 1216e2f1... while this batch was being authored. Changes since 917d2d0... include the v0.20 object event strangler/gate/store/reducer and QA changes. main.gd is not part of that delta, so the TEEA006 camera/semantic ROOM evidence remains compatible.

## Evidence included

Proposal manifest; furniture-anchor candidate with source collision footprints; foreground candidate; authoring layout; source provenance; image QA; collision/spacing/approach report; depth-readability report; yaw-proof report; Godot 4.7.2 image-load log; contact sheet; harvest-ID contact sheet; harvest usage/reserve/runtime-candidate files; final SHA256SUMS; validation summary.

No production PR. Integrator QA first. Dragon visual approval remains separate.


## Binary drop

URL:
https://d2ol7oe51mr4n9.cloudfront.net/user_3JdI9kJ82xObF8Bi3EgU4P6DaoR/1f7c0d7a-e63f-4860-8bfa-b653f7ac2e34.zip

ZIP SHA-256:
7ca98ad9039ba36ca76f1e29f6e82489c1098c35d5243f639724d092546694bc

Archive:
TEEA_INT_20261123_006_DEPTH_DRESSING.zip

