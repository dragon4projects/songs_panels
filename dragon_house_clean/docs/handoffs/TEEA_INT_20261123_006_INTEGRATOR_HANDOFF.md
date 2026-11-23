# TEEA_INT_20261123_006 — INTEGRATOR HANDOFF

Role: TEEA / interiors only
Machine status: READY_FOR_INTEGRATOR_QA
Owner approved: false
Approved: false
Production PR: NONE
Authoring branch: art/teea-interiors-TEEA_INT_20261123_006
Task branch base: ac44724c39275d365c185af0435b6dea676d24ae
Exact production HEAD rechecked: 78f2ae904585ffe01bc11b39f2762ce90e85f00c

## Scope completed

Candidate replacement interiors were authored for all 12 requested variants:
Music R1/R2/R3; Cinema R1/R2/R3; Artifact R1/R2/R3; Workshop R1/R2/R3.

This batch does not promote any R1 production art and does not overwrite owner-approved state.

## Machine evidence

- production PNG: 40/40, exact 1536 x 1024, RGBA8
- Godot 4.7.2 Image -> ImageTexture -> Sprite3D: 40/40 PASS, clean final log
- measured stations: 31
- station/bounds/approach/collision errors: 0
- depth readability: 12/12 PASS
- manual current-camera contract: 36/36 proof renders at -0.18 / 0 / +0.18
- effective production-camera supplement: 36/36 proof renders
- foreground variants: 4 (music/R2, music/R3, cinema/R2, cinema/R3)
- harvested Poly Haven assets used: 41 unique, baked-art source class
- kitchen/private reserve leaks: 0
- runtime prop candidates created by TEEA006: 0

The one spacing record that is not a failure is Cinema R1's two measured seats on the same physical sofa: 0.6054 m centre-to-centre, explicitly retained as MEASURED_SAME_SOFA_SEAT_CENTRES.

## Foreground physical evidence

The foreground layers are cut from the same source furniture geometry as their furniture layer. Render-time raycast measurements:

| Variant | Source | physical_z | seat centroid z | clip plane z |
|---|---|---:|---:|---:|
| music/R2 | music_r2_chair_front | 0.515725 | 0.242181 | 0.254181 |
| music/R3 | music_r3_chair_front | 0.510694 | 0.242590 | 0.254590 |
| cinema/R2 | cinema_r2_chair_front | 0.572797 | 0.212474 | 0.224474 |
| cinema/R3 | cinema_r3_chair_front | 0.578528 | 0.211631 | 0.223631 |

Do not reuse the older TEEA004 physical_z=-0.10: TEEA006 moved the physical front chairs and remeasured from source GLTF.

## Camera seam

At final recheck, production 78f2ae904585ffe01bc11b39f2762ce90e85f00c still uses:
- perspective ROOM camera
- FOV 35.0
- R1/R2/R3 ROOM zoom 10.8 / 13.9 / 17.0
- effective_camera_yaw = clamp(manual_yaw + clamp((48-zoom)/34,0,1)*0.075, -0.38, 0.38)

Therefore the required manual proof is preserved and a second proof set records the actual close-bias view. The proof renderer uses resident-sized placeholders at measured station Z and runtime foreground plane registration math.

## Asset / source constraints

- Poly Haven harvested sources are CC0 and default to BAKED_ART_SOURCE.
- steel_frame_shelves_01 uses only the verified normalized x0.1 copy.
- stock artwork/canvas inside Poly Haven frame assets was stripped and replaced by neutral inserts.
- frame holders publish stable media_slot:<object_id> identifiers; actual catalog content stays runtime-owned.
- KITCHEN_RESERVE and PRIVATE_RESERVE items were not placed.

## Integrator action

1. Ingest this as a replacement candidate only; keep all approval flags false.
2. Rebase/overlay onto exact current production or a descendant and repeat live ROOM/HOUSE camera registration.
3. Put actual resident sprites and poses on the published measured stations.
4. Register foreground using the per-variant physical_z; compare against published render-time clip evidence.
5. Re-run current collision/approach and ensure procedural furniture is not double-rendered beneath baked furniture.
6. Only after integrator QA, send visual result to Dragon for owner approval.

## Evidence files

TEEA_INT_20261123_006_interiors.json
TEEA_INT_20261123_006_furniture_anchors_candidate.json
TEEA_INT_20261123_006_foreground_layers_candidate.json
TEEA_INT_20261123_006_authoring_layout.json
TEEA_INT_20261123_006_source_provenance.json
TEEA_INT_20261123_006_harvest_usage.json
TEEA_INT_20261123_006_reserve_candidates.json
TEEA_INT_20261123_006_runtime_prop_candidates.json
TEEA_INT_20261123_006_reserve_leak_report.json
TEEA_INT_20261123_006_image_qa.json
TEEA_INT_20261123_006_collision_spacing_report.json
TEEA_INT_20261123_006_depth_readability_report.json
TEEA_INT_20261123_006_depth_visual_review.json
TEEA_INT_20261123_006_yaw_proof_report.json
TEEA_INT_20261123_006_camera_proof_contract.json
TEEA_INT_20261123_006_godot_4_7_2_load.log
TEEA_INT_20261123_006.sha256
art/contact review sheets
manual/effective yaw contact sheets
raw manual + effective yaw proof renders

## Binary handoff

Permanent ZIP:
https://d2ol7oe51mr4n9.cloudfront.net/user_3JdI9kJ82xObF8Bi3EgU4P6DaoR/b50aa9af-cd2c-4101-b16a-553e561c9c55.zip

ZIP SHA-256:
5ae489046eefb6dc3718f2334945bb6fc7786dc59fc0758060e7f7e1d010e275

ZIP size: 61 MiB.

The ZIP is the immutable binary drop. This external handoff is authoritative for its URL/SHA.
