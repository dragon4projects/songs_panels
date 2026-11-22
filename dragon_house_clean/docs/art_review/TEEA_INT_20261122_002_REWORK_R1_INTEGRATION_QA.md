# TEEA_INT_20261122_002 — REWORK R1 integrator QA

Date: 2026-11-22
Integrator target: actual Dragon House QA camera, Godot 4.7.2 Compatibility.
Source art branch: art/teea-interiors-TEEA_INT_20261122_002 @ 049ae29659405485120c80a28dc6d4496d8b921a
Patch ZIP SHA-256: 72872c33fa1ce41d7816f5d298c13b5f38ce255e931e626acaf73db9cf0923e9
Disposition: TECHNICAL INTEGRATION PASS / OWNER ART APPROVAL STILL FALSE.

## Source integrity

- Rework patch ZIP SHA-256 verified.
- All three additive foreground PNG SHA-256 values verified.
- Common foreground: 4608x1024 RGBA, alpha 0..255.
- Library foreground: 3072x1024 RGBA, alpha 0..255.
- Rest foreground: 1536x1024 RGBA, alpha 0..255.
- Original 12 PNGs were not replaced by the rework.
- Candidate anchor and foreground manifests both remain approved:false.
- data/furniture_interactions_v1.json and data/interior_layers_v1.json remain the accepted sources and are not rewritten.

## Schema-2 anchor result in the actual QA world

The integrator loads TEEA_INT_20261122_002_furniture_anchors_candidate.json through scripts/teea_qa_anchor_adapter.gd. The adapter installs only temporary per-cell overrides in memory for the four pilot rooms.

PASS:
- legal candidate stations: 10
- explicitly blocked: 1
- candidate validation errors: 0
- duplicate station IDs: 0
- legal local X outside +/-1.90: 0
- calibrated station Z/approach failures: 0
- approach path collision against other authored furniture footprints: 0 / 10
- common_chair_left_seat_a at cell_local_x=+2.25 remains BLOCKED_GEOMETRY_NEAR_WALL and never enters runtime.
- common_sofa_left seats map to left Common R3 module only and never alias SOFA_COMMON_MIDDLE.
- Library table remains collision-only.
- Study uses one kind:work station.
- Rest uses only the newly measured candidate seat positions while the candidate preview is active.

## Foreground / physical depth integration

A first raw integration exposed an integrator-side defect: the runtime's generic foreground role was at z=+1.63. The additive full-canvas furniture cutouts therefore projected as a second, enlarged/down-shifted chair/sofa in a perspective camera.

The artwork was not changed. The QA renderer now:
1. derives a physical foreground sort depth from the median camera-facing edge (max Z) of unique legal furniture footprints in that room variant;
2. places the full-canvas foreground at that physical Z;
3. dynamically rescales and recenters it against Art_furniture_back for the current camera transform, preserving exact full-canvas screen registration;
4. keeps ordinary depth sorting active.

Consequences:
- seated actor Z is behind foreground;
- public aisle / approach at z=+0.95 remains in front of foreground;
- the furniture does not duplicate or drift while the camera yaws;
- Study has no foreground and keeps its authored work depth.

Automated test test_teea_foreground_registration_v13.gd verifies screen-space corner drift below 0.75 pixels for Common, Library and Rest at effective yaw -0.15, 0 and +0.15 rad. It also verifies seat_z < foreground_z < aisle_z for every legal station in foreground-enabled variants.

## Real camera evidence

tests/qa_teea_rework_r1_camera.gd rendered 12 actual-camera frames:
- Common R3: front, yaw -0.15, yaw +0.15
- Library R2: front, yaw -0.15, yaw +0.15
- Study R1: front, yaw -0.15, yaw +0.15
- Rest R1: front, yaw -0.15, yaw +0.15

The corrected foreground remains registered through these views. Rest and Library visibly put the chair/sofa front in front of the seated placeholder lower body. Common no longer produces the previously observed duplicate displaced sofa-front fragment.

This does NOT prove final character pose fidelity: current QA bodies are temporary, and Znaechka's final identity-matched seated sprites are still needed.

## Mac reviewer mode

The isolated Mac QA viewer now includes:
- C: Common R3
- L: Library R2
- S: Study R1
- R: Rest R1
- T: Teea REWORK R1 vs old procedural room
- A: freeze the current room and place actually rendered active residents exactly on legal schema-2 candidate stations
- Q/E: camera rotation for parallax review
- wheel/right-drag: zoom/pan

The disposable QA app does not read the ordinary Dragon House save. Library R2 still borrows the adjacent Music module in RAM only.

## Remaining artistic / product questions

The integrator no longer considers anchors, approach, blocked geometry, foreground decode, or basic foreground parallax to be blockers.

Still open for owner visual judgement:
- overall realism and whether the 3D-rendered room plates feel like the intended Dragon House;
- depth of the ROOM camera and whether more object-separated parallax is desirable;
- scale and thickness of the temporary procedural ceiling/front beams;
- final body proportions and seated poses once character banks are ready;
- whether the existing room compositions should be accepted, revised, or expanded.

No production PR should be opened and no approved flag should change until the owner explicitly accepts the visual result.
