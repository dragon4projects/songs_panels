# MACHINE TASK — TEEA_INT_20261122_003 — NEXT DRAGON HOUSE INTERIORS

Status: READY
Owner direction: CONTINUE
Predecessor accepted baseline: TEEA_INT_20261122_002_REWORK_R1
Target repository: dragon4projects/songs_panels
Required art branch: art/teea-interiors-TEEA_INT_20261122_003
Do not modify production branch directly.

## 1. Objective

Extend the accepted photorealistic Dragon House cutaway interior system to the next six public room variants:

1. arrival/R1
2. corridor/R1
3. music/R1
4. cinema/R1
5. artifact/R1
6. workshop/R1

The visual language must clearly belong to the same House as accepted common/R3, library/R2, study/R1 and rest/R1.

This is NOT fantasy-cartoon art, painted concept art, a decorative illustration, a flat matte, or a stylized game icon set.
Target is photorealistic / cinematic / physically plausible 2.5D room art suitable for the existing Godot perspective camera.

## 2. Mandatory inherited calibration

Use the same accepted physical room coordinate system:

- Godot backwall: z = -2.04
- public aisle / approach: z = +0.95
- feet contact: y = 0.0
- module width: 4.8 world meters
- Godot local Z = -Blender world Y
- exact registered image canvas for R1: 1536 x 1024 RGBA

Do not infer station Z from screen-space composition.
Author furniture in the calibrated Blender room shell first, then measure from actual geometry.

## 3. Required image layers per room

Each room must provide, at minimum:

- backdrop.png
- back_decor.png
- furniture_back.png

Add:
- foreground.png ONLY when a physically camera-facing furniture part must occlude a seated/working actor.
- Do not create fake foreground filler.
- Do not bake the actor into any room layer.
- Do not bake labels, UI, room names, selection frames or lighting indicators into images.

Optional front_trim / light_overlay are forbidden in this batch unless explicitly justified in the manifest and shown necessary by physical geometry.

All layers:
- PNG
- RGBA
- exact 1536x1024 canvas
- transparent where appropriate
- identical registration
- no cropping mismatch between layers
- no AI text artifacts
- no visible watermarks
- no perspective inconsistency between layer files.

## 4. Art direction — common language

Match accepted R1 visual direction:

- real rough cave stone, not fantasy masonry;
- believable timber / dark wood structural elements;
- restrained warm practical light;
- leather, wood, metal, glass, cloth and paper should read as real materials;
- no ornamental pseudo-medieval clutter;
- no whimsical tavern aesthetic;
- no caricature proportions;
- no saturated game-toy palette;
- no painterly brushwork;
- no fake depth painted into objects that are meant to interact with residents.

Rooms may have personality but must look like parts of one inhabited private cave-house.

Increase spatial readability relative to batch 002:
- clearer back plane;
- meaningful mid-depth furniture;
- foreground only where physically justified;
- avoid lining every functional object against the backwall;
- preserve a navigable aisle around z=+0.95.

## 5. Room-specific requirements

### arrival/R1
Purpose: entry/transition into the House.
Must read as a practical inhabited threshold, not a hotel lobby.
Include:
- sturdy entry surface / bench or landing area;
- hooks / storage / practical drop zone;
- believable cave-house transition elements;
- one or more collision objects if appropriate.
Do NOT author a resident seat unless geometry genuinely supports it.

### corridor/R1
Purpose: transit.
Must prioritize clear passage and depth.
Include restrained environmental details only.
Do NOT create fake seating simply to fill space.
Keep public aisle visibly and physically unobstructed.

### music/R1
Purpose: audio library / listening / music interaction.
Must support visible use by residents.
Include:
- physically plausible playback/listening furniture;
- storage/display related to music media;
- at least one measured work/listen interaction if geometry supports it;
- avoid recording-studio cliché unless justified by House use.
No generic neon music-room aesthetic.

### cinema/R1
Purpose: film library / watching.
Include:
- real screen/TV placement;
- comfortable seating with measured seat surfaces;
- sightline from seats to screen;
- physically measured foreground if sofa/chair front occludes seated actor.
No cinema-theater parody and no rows of identical commercial seats unless strongly justified.

### artifact/R1
Purpose: House artifacts / meaningful objects.
Include:
- physically plausible display/storage furniture;
- safe walking space;
- no invented lore labels or readable fictional inscriptions;
- no sacred-temple staging.
Interaction can be viewing/standing unless a real seat/work surface exists.

### workshop/R1
Purpose: practical making/repair work.
Include:
- real workbench / tool storage;
- one or two measured work positions if geometry supports them;
- believable clutter but not visual noise;
- no steampunk decoration unless it is mechanically functional.
Keep dangerous or obstructive props away from the public approach path.

## 6. Furniture interaction authoring

Create:
data/asset_proposals/TEEA_INT_20261122_003_furniture_anchors_candidate.json

Schema: 2, same semantics as accepted batch 002 rework.

Every station record must contain:
- id
- furniture_id
- module_index
- group_local_x
- cell_local_x
- cell_local_z
- feet_contact_y
- approach_local_z
- kind
- pose_hint
- occupancy_capacity
- seat_width when relevant
- occlusion_role
- source_visual_anchor
- collision_footprint
- confidence
- reservation_status

Allowed status for legal records:
CANDIDATE

If geometry violates legal station bounds, do NOT nudge coordinates to fake a pass.
Mark it BLOCKED_* with an explicit reason.

Legal bounds:
- abs(cell_local_x) <= 1.90
- furniture/station must remain inside the calibrated physical shell
- public approach should normally originate at z=+0.95
- station must not require a path through unrelated collision furniture.

Minimum spacing between distinct usable resident positions: 0.65 m.

Non-interactive furniture still requires collision footprints in non_station_furniture where it constrains approach or movement.

## 7. Foreground authoring

For any room that needs foreground occlusion:
- use the SAME source 3D furniture as furniture_back;
- derive the camera-facing fragment from measured physical geometry;
- cut/render only the part that is actually in front of the actor;
- keep exact canvas registration;
- record source furniture IDs and physical Z derivation.

Do not hand-paint an occlusion mask.
Do not create a duplicate visual object at a fake depth.

## 8. Machine QA / PASS criteria

A room variant is PASS only if all apply:

IMAGE:
- PNG decodes in Godot 4.7.2;
- exact 1536x1024;
- RGBA where transparency is needed;
- alpha range valid;
- all room layers register exactly;
- SHA-256 recorded.

ART:
- photorealistic;
- same House visual family as accepted batch 002;
- no cartoon / luba / painted-concept look;
- furniture scale believable against a 1.65-1.90 m adult;
- room does not read as a flat wallpaper collage.

GEOMETRY:
- calibrated Blender shell used;
- backwall -2.04 and aisle +0.95 preserved;
- legal stations inside bounds;
- collision footprints provided;
- approach path does not cross unrelated furniture;
- no two usable stations overlap.

FOREGROUND:
- only where physically required;
- generated from source geometry;
- same canvas;
- supports seat/work occlusion without furniture duplication.

DATA:
- approved:false everywhere;
- no accepted production JSON overwritten;
- original predecessor assets untouched;
- provenance document included;
- no silent reuse of old procedural station coordinates.

## 9. Required deliverables

Branch:
art/teea-interiors-TEEA_INT_20261122_003

Paths:

dragon_house_clean/assets/rooms/arrival/R1/
dragon_house_clean/assets/rooms/corridor/R1/
dragon_house_clean/assets/rooms/music/R1/
dragon_house_clean/assets/rooms/cinema/R1/
dragon_house_clean/assets/rooms/artifact/R1/
dragon_house_clean/assets/rooms/workshop/R1/

Data:
dragon_house_clean/data/asset_proposals/TEEA_INT_20261122_003_interiors.json
dragon_house_clean/data/asset_proposals/TEEA_INT_20261122_003_furniture_anchors_candidate.json
dragon_house_clean/data/asset_proposals/TEEA_INT_20261122_003_foreground_layers_candidate.json

Review:
dragon_house_clean/docs/art_review/TEEA_INT_20261122_003_delivery.json
dragon_house_clean/docs/art_review/TEEA_INT_20261122_003_source_provenance.json
dragon_house_clean/docs/art_review/TEEA_INT_20261122_003_composition_report.md
dragon_house_clean/docs/art_review/TEEA_INT_20261122_003_GODOT_QA.log
dragon_house_clean/docs/art_review/TEEA_INT_20261122_003.sha256
dragon_house_clean/docs/art_review/TEEA_INT_20261122_003_contact_sheet.jpg

If binary payload cannot be pushed directly, provide a patch ZIP plus SHA-256 in:
dragon_house_clean/docs/art_review/TEEA_INT_20261122_003_BINARY_PAYLOAD.txt

## 10. Contact sheet

One contact sheet must show every completed room at:
- full room framing;
- closer furniture framing;
- any station / foreground relation that needs human approval.

Do not hide weak areas with dramatic crop or darkness.

## 11. Handoff status

Final machine status must be one of:
- READY_FOR_INTEGRATOR_QA
- REWORK_REQUIRED
- BLOCKED_SOURCE_ASSET
- BLOCKED_GEOMETRY

Never mark owner_approved:true.
Never open a production PR.
Integrator will test in the exact Dragon House camera before owner review.
