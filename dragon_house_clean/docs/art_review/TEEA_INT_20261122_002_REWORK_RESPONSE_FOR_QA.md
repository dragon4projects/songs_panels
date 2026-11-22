# Teea response — TEEA_INT_20261122_002 REWORK R1

## Disposition

This is an additive review patch. The original 12 PNG layers are not modified and remain approved:false.

### Base integrity
- Original 12 authored PNG SHA-256 values: PASS against the submitted 002 manifest.
- Existing data/furniture_interactions_v1.json: not modified.
- Existing accepted gameplay/station data: not modified.
- common_sofa_left is explicitly not treated as SOFA_COMMON_MIDDLE.
- rest_sofa candidate stations do not replace accepted SOFA_REST stations until integrator/owner approval.

## Depth correction

The original 002 Blender scene used Y as a render-spacing axis, not as authored gameplay depth. Reusing it directly as Godot Z would have been false.

REWORK R1 therefore creates an explicit calibrated Blender physical authoring pass:
- Godot backwall: z=-2.04
- public aisle / approach: z=+0.95
- axis mapping: Godot local Z = -Blender world Y
- furniture depth centers are authored inside that accepted shell before measurement
- station Z comes from raycast-measured visible seating-footprint centroid on the actual source mesh

Confidence string in the candidate file: AUTHOR_CONFIRMED_FROM_CALIBRATED_BLENDER_REWORK_SCENE

## Anchor result

Required file: data/asset_proposals/TEEA_INT_20261122_002_furniture_anchors_candidate.json

Result:
- station records: 11
- legal candidates: 10
- explicitly blocked: 1
- duplicate IDs: 0
- legal cell_local_x outside ±1.90: 0
- Z/approach range failures: 0
- same-module spacing failures below 0.65 m: 0

Blocked case:
- common_chair_left_seat_a
- module_index=0
- cell_local_x=+2.25
- status: BLOCKED_GEOMETRY_NEAR_WALL
- visual furniture remains; station must not be integrated.

Library center table is collision-only and remains a non-station because it crosses the R2 module boundary.

Study provides one kind:work station from the measured chair footprint. The heavy desk is collision-only and remains behind the actor at the authored depth.

## Foreground / actor occlusion

New additive transparent layers:
- assets/rooms/common/R3/foreground.png
- assets/rooms/library/R2/foreground.png
- assets/rooms/rest/R1/foreground.png

Method:
- import the same source furniture used by furniture_back
- raycast the actual visible seating surface
- clip each relevant mesh at the measured seating-footprint centroid
- render only the camera-facing/front portion on the exact registered canvas

No Study foreground is authored: its work chair has no front armrest and the heavy desk is physically behind the actor in the calibrated depth layout. No optional front trim or glow filler is added.

Foreground machine QA:
- exact canvas sizes: PASS
- RGBA alpha 0..255: PASS
- Godot 4.7.2 Image load: PASS
- ImageTexture creation: PASS
- Sprite3D assignment: PASS

Anchor schema-2 dry-run in Godot 4.7.2:
- PASS
- legal candidates 10
- blocked 1
- errors 0

## Still intentionally unresolved

This rework does not claim owner art PASS and does not toggle any approval flag.

The new foreground + anchor patch still requires the integrator to load it in the exact current QA camera and verify:
1. actor parallax at the authored Z values,
2. foreground occlusion at each legal seat/work station,
3. public-aisle clearance during approach,
4. no visual conflict with the integrator's temporary backwall/furniture suppression logic.

Status remains: READY_FOR_REVIEW / approved:false

