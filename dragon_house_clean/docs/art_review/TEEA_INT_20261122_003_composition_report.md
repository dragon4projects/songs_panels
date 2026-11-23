# Dragon House — TEEA_INT_20261122_003 composition report

Status: READY_FOR_INTEGRATOR_QA
Owner approved: false
Predecessor visual baseline: TEEA_INT_20261122_002_REWORK_R1

## Physical calibration

- Godot backwall: z = -2.04
- public aisle / approach: z = +0.95
- feet contact: y = 0.0
- module width: 4.8 m
- Godot local Z = -Blender world Y
- R1 canvas: 1536 x 1024 RGBA
- source renders: 768 x 512 at identical aspect, one Lanczos 2x resize to final canvas
- all furniture depth was authored in the calibrated shell before station measurement

## Visual continuity

This batch inherits the owner-accepted 002 visual family:
- rough real cave stone;
- dark restrained timber;
- leather / metal / glass / paper with physically readable materials;
- warm practical light without fantasy fog;
- no cartoon, luba, tavern, neon-room or pseudo-medieval staging.

003 deliberately reduces structural duplication relative to 002:
- backdrop contains the rear wall and restrained rear supports;
- no heavy floor/front beam is baked into the room art;
- mid-depth furniture remains on furniture_back;
- foreground exists only for physical actor occlusion.

## Room results

### arrival/R1
Purpose: inhabited entry threshold.
- dark practical entrance opening;
- wall hooks/drop zone;
- storage cabinet;
- bench and suitcase as collision-only floor furniture;
- resident stations: 0.
No fake sitting interaction was authored.

### corridor/R1
Purpose: transit.
- two restrained directional recesses;
- practical wall lights and a shallow wall ledge;
- floor furniture: none;
- resident stations: 0.
The furniture_back file is intentionally fully transparent.

### music/R1
Purpose: listening / audio library.
- dark media shelf;
- boombox and cassette player;
- wall-hung small string instrument;
- one lounge listening chair and side table;
- measured resident stations: 1.
A foreground layer is derived from the same lounge-chair mesh at the measured seat centroid.

### cinema/R1
Purpose: film watching.
- fixed matte screen integrated at the rear plane;
- real two-seat sofa;
- small side projector table and vintage 8 mm projector;
- measured resident stations: 2.
The screen is not a commercial theater parody. The foreground layer is a physical front slice of the same sofa mesh.

### artifact/R1
Purpose: meaningful-object display / viewing.
- restrained wall/display storage;
- cabinet;
- pedestal with small brass object;
- old suitcase;
- measured standing view stations: 2.
No labels, readable lore text or temple staging.

### workshop/R1
Purpose: practical repair/making.
- wall shelf;
- procedural pegboard / tool hooks;
- real tool cart and tool chest;
- procedural heavy workbench;
- industrial stool;
- measured work stations: 2 (one stool work position, one standing workbench position).
No steampunk decoration and no dangerous prop occupies the public aisle.

## Station / collision QA

Generated:
data/asset_proposals/TEEA_INT_20261122_003_furniture_anchors_candidate.json

Station count:
- arrival/R1: 0
- corridor/R1: 0
- music/R1: 1
- cinema/R1: 2
- artifact/R1: 2
- workshop/R1: 2
- total: 7

Machine checks:
- duplicate IDs: 0
- abs(cell_local_x) > 1.90: 0
- Z / approach range failures: 0
- same-module station spacing below 0.65 m: 0
- unrelated collision paths intentionally avoided

Collision-only furniture is explicitly retained in non_station_furniture where it constrains movement.

## Foreground QA

Foreground authored only for:
- music/R1
- cinema/R1

Method:
1. import the identical 3D furniture used in furniture_back;
2. raycast the actual seat surface;
3. calculate the measured seating centroid;
4. bisect the mesh at that physical depth;
5. render only the camera-facing geometry.

No hand-painted masks.
No duplicate fake-depth furniture.

Foreground intentionally omitted for Arrival, Corridor, Artifact and Workshop because no camera-facing furniture geometry physically needs to occlude the actor.

## Source hygiene

Two CC0 candidates were rejected before final art:
- steel_frame_shelves_01 — imported composite bbox was grossly inconsistent with source metadata and produced scene-spanning geometry;
- bench_vice_01 — imported bbox was roughly 7–8x expected dimensions.

They are not present in final production layers.

## Machine image QA

Godot 4.7.2 standalone QA:
- 20 / 20 production PNG files loaded: PASS
- exact 1536 x 1024: PASS
- FORMAT_RGBA8: PASS
- ImageTexture creation: PASS
- Sprite3D assignment: PASS
- errors: 0

The contact sheet shows:
- complete room frame;
- furniture close framing;
- actor/station relation, including foreground occlusion.

## Still pending

The Higgsfield sandbox does not contain the integrator's exact live QA camera/runtime state.

Therefore this batch intentionally does not claim final integration PASS.

Integrator must verify:
1. current HOUSE / ROOM camera registration;
2. station parallax at authored Z;
3. approach path against actual collision geometry;
4. Music/Cinema foreground ordering around live resident sprites;
5. no doubling against current temporary shell geometry.

No production branch was modified.
No production PR is opened.
No approved:true flag is written anywhere.

