# Dragon House — TEEA_INT_20261123_005 composition report

Status: READY_FOR_INTEGRATOR_QA  
Owner approved: false  
Branch: art/teea-interiors-TEEA_INT_20261123_005  
Visual canon: TEEA_INT_20261122_002_REWORK_R1  
Previous interior batch: TEEA_INT_20261123_004

## Scope

Exactly eight previously missing public-room variants were authored:

- common/R1
- common/R2
- study/R2
- study/R3
- rest/R2
- rest/R3
- library/R1
- library/R3

Accepted visual-canon variants were not modified:
- common/R3
- study/R1
- rest/R1
- library/R2

No 003 or 004 production room file was modified.

## Width / camera contract

Physical widths:
- R1 = 4.8 m
- R2 = 9.6 m
- R3 = 14.4 m

Every production layer is exactly 1536 x 1024 RGBA8.

Authoring uses:
`ortho_scale = physical_width`

No `physical_width / 1.5` draft logic is present in this batch.

R2/R3 transparent vertical margins contain no neighboring-floor art.

## Visual family

The accepted 002 direction is preserved:
- rough natural cave stone;
- restrained dark worn timber;
- leather / metal / paper / glass with physically readable response;
- warm practical light;
- asymmetry and lived-in dressing;
- no tavern pseudo-medieval theme;
- no neon room;
- no oversized decorative filler;
- no Fallout/Bethesda visual assets.

The new variants deliberately strengthen shallow-3D readability through:
1. rear architecture / shelves / recesses;
2. separate rear-mid functional furniture and stations;
3. a distinct front functional seating band;
4. physically registered foreground seat fragments.

## Depth-readability machine evidence

All eight variants declare two functional station depth bands:
- `front_functional`
- `rear_mid_functional`

Minimum cross-band station separation:

- common/R1: 0.47826 m
- common/R2: 0.47826 m
- study/R2: 0.46479 m
- study/R3: 0.42850 m
- rest/R2: 0.96479 m
- rest/R3: 0.92850 m
- library/R1: 0.55370 m
- library/R3: 0.48850 m

Required minimum: 0.35 m.

Result: PASS 8/8.

The full report records:
- major furniture IDs;
- Godot-local front/back Z extents;
- every station Z;
- foreground physical Z;
- declared depth bands;
- minimum cross-band separation.

## Common

### common/R1
- separate front chair and rear neutral shared surface;
- clear aisle;
- no forced sofa cluster;
- structural unlit hearth recess retained as Common-family language.

Measured stations: 2.

### common/R2
- two independent front seats;
- one long shared rear/mid surface with two standing positions;
- continuous composition rather than duplicated R1 cells.

Measured stations: 4.

## Study

### study/R2
- rear heavy desk work zone;
- separate reading/work table zone;
- independent front reading chair;
- rear storage and practical task lighting.

Measured stations: 3.

### study/R3
- one continuous expanded study;
- heavy desk, center reading/work surface and two independent front reading seats;
- asymmetric rear storage;
- no repeated desk modules.

Measured stations: 4.

## Rest

### rest/R2
- two independent front sit/rest positions;
- low rear quiet-rest pad;
- rear daybed is background dressing rather than a fake extra interaction;
- no giant sofa-wall foreground.

Measured stations: 3.

### rest/R3
- two independent front seats at opposite ends;
- paired low quiet-rest pad in the rear/mid zone;
- restrained rear daybed/drawer dressing;
- strong functional depth split without blocking the aisle.

Measured stations: 4.

## Library

### library/R1
- accepted R2 shelf/material family reduced to a coherent single-width room;
- rear shelves;
- one front seated reading position;
- one rear/mid reading work surface.

Measured stations: 2.

### library/R3
- coherent long library, not three copied shelf cells;
- asymmetric rear shelving;
- two front reading seats;
- one central rear/mid shared reading table with two measured positions.

Measured stations: 4.

## Width-aware stations

Total measured artist-authored stations: 26.

Counts:
- common/R1: 2
- common/R2: 4
- study/R2: 3
- study/R3: 4
- rest/R2: 3
- rest/R3: 4
- library/R1: 2
- library/R3: 4

Every station includes:
- stable ID;
- furniture ID;
- module_index;
- group_local_x;
- cell_local_x;
- cell_local_z;
- feet_contact_y;
- approach_local_z;
- kind;
- pose_hint;
- occupancy_capacity = 1;
- module-local collision footprint;
- group-local collision footprint;
- confidence/provenance.

Collision-only furniture is listed separately.

Machine checks:
- station bounds errors: 0
- duplicate station IDs: 0
- spacing errors: 0
- foreign collision / approach intersections: 0

## Foreground contract

Foreground exists in all eight variants because each contains at least one real front-band seat whose camera-facing geometry physically crosses the resident body.

Runtime registration plane for every foreground:
`physical_z = +0.15`

This is the common measured furniture front edge.

Measured imported source-front values differ from +0.15 only by floating-point import noise.

The metadata explicitly separates:
- runtime registration plane: `physical_z = +0.15`, `front_edge`;
- geometry clipping plane: source-specific measured seat-centroid minus 0.012 Blender-Y.

No foreground was added merely for visual richness.

## Perspective / yaw proof

Production PNG planes were recomposited using:
- current Dragon House perspective-camera ROOM zoom rule;
- exact yaw values -0.15, 0.00, +0.15;
- the current `register_art_foreground` interpolation formula;
- actor-sized placeholders at the real measured station X/Z.

Proof variants:
- R1: common/R1
- R2: study/R2
- R3: library/R3

Nine individual yaw images plus a contact sheet are delivered.

Author visual checks:
- rear/mid/front relationship readable: PASS
- foreground fragment remains attached to physical source: PASS
- actor-sized placeholders remain readable: PASS
- no neighboring-floor content baked into transparent margins: PASS

The QA floor shell visible in these proof renders is review-only geometry and is not part of any production PNG.

## Production image QA

Production PNG count: 32.

PASS:
- 32/32 exact 1536 x 1024
- 32/32 RGBA8
- 32/32 non-empty
- alpha present/correct
- per-file SHA-256 recorded

## Godot 4.7.2 staged QA

PASS:
- Image load: 32/32
- FORMAT_RGBA8: 32/32
- ImageTexture creation: 32/32
- Sprite3D assignment: 32/32
- foreground metadata: 8/8
- explicit physical_z = +0.15: 8/8
- station schema checks: 26
- depth-readability machine pass: 8/8
- errors: 0

## Source / copyright policy

No Bethesda/Fallout visual assets, textures, props, branding or room art were used.

External models are verified Poly Haven CC0 assets already present in the project asset pipeline.
Rock035 and Wood051 are ambientCG CC0 1.0 materials.

No physically broken source was scaled by eye.

Previously rejected:
- steel_frame_shelves_01
- bench_vice_01

were not reused.

## Approval boundary

No `approved:true` flag is written.
Owner approval remains false.
No production manifest was changed.
No production branch was changed.
No production PR was created.

The integrator must still test:
1. exact current HOUSE/ROOM mounting;
2. live resident sprites and poses;
3. width-aware runtime station ingestion;
4. perspective foreground registration;
5. runtime collision/approach behavior;
6. absence of procedural furniture doubling;
7. owner visual review in the Mac build.

