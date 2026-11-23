# Dragon House — TEEA_INT_20261123_004 composition report

Status: READY_FOR_INTEGRATOR_QA
Owner approved: false
Parent art batch: TEEA_INT_20261122_003
Branch: art/teea-interiors-TEEA_INT_20261123_004

## Scope

Eight width-aware variants were authored. No 003 R1 file was modified.

- music/R2
- music/R3
- cinema/R2
- cinema/R3
- artifact/R2
- artifact/R3
- workshop/R2
- workshop/R3

Arrival and Corridor are intentionally absent because they are non-mergeable and complete at R1.

## Width-aware image authoring

Every production image is exactly 1536 x 1024 RGBA8.

Physical room widths:
- R2 = 9.6 m
- R3 = 14.4 m

The Blender orthographic camera uses `ortho_scale = physical_width`.
At the fixed 3:2 texture aspect this gives a physical vertical field of:
- R2: 6.4 m
- R3: 9.6 m

Only the real 0.0..3.1 m room band contains authored room geometry. The remaining vertical texture area is transparent. This allows the current Dragon House runtime to scale the 1536-wide sprite by physical room width without stretching the room itself or painting over adjacent floors.

A draft camera-authoring error using `physical_width / 1.5` was detected before handoff. All affected draft/production images were discarded and the final 28 PNG were rerendered with the correct width. Final SHA records therefore refer only to the corrected files.

## Visual continuity

The accepted 003 R1 visual family is retained:
- rough natural cave stone;
- restrained dark timber;
- leather / metal / paper / glass with physically readable material response;
- warm practical light;
- no neon theme rooms;
- no tavern / pseudo-medieval ornament;
- no painted fake interaction furniture.

R2/R3 are continuous compositions, not repeated R1 panels.

## Music

### music/R2
- two-module shared listening room;
- asymmetric media storage and wall instruments;
- two physically measured listening seats, one in each module;
- one shared table;
- foreground required.

Measured stations: 2.

### music/R3
- three-module shared listening room;
- media storage at opposite ends with central instrument area;
- three physically measured listening seats, one per module;
- side tables keep the central and public aisle readable;
- foreground required.

Measured stations: 3.

## Cinema

### cinema/R2
- one shared wide screen, not two duplicated R1 screens;
- two-seat sofa in module 0;
- one separate lounge chair in module 1;
- projector/table kept behind the public approach.

Measured seats: 3.

### cinema/R3
- one continuous wide screen;
- two-seat sofa in module 0;
- one armchair in module 1;
- one lounge chair in module 2;
- side projector furniture remains outside the viewing approach paths.

Measured seats: 4.

## Artifact

### artifact/R2
- multiple distinct display zones rather than duplicated cabinets;
- one wall display, one pedestal display and one cabinet display;
- viewing residents remain outside display collision volumes.

Measured standing view stations: 3.

### artifact/R3
- four distinct standing-view targets across three modules;
- irregular shelf / cabinet / pedestal rhythm;
- no labels, invented inscriptions or shrine staging.

Measured standing view stations: 4.

## Workshop

### workshop/R2
- two physically separate workbench zones;
- one stool work position;
- tool cart and chest remain collision-only;
- public approach remains open.

Measured work stations: 3.

### workshop/R3
- three-module shared practical workshop;
- three standing workbench positions plus one stool position;
- storage/tool furniture does not cross station approaches.

Measured work stations: 4.

## Width-aware station contract

Total artist-authored stations: 26.

Counts:
- music/R2: 2
- music/R3: 3
- cinema/R2: 3
- cinema/R3: 4
- artifact/R2: 3
- artifact/R3: 4
- workshop/R2: 3
- workshop/R3: 4

Every station records:
- stable ID;
- furniture ID;
- module_index;
- group_local_x;
- module-local cell_local_x;
- module-local cell_local_z;
- approach_local_z;
- kind / pose hint;
- occupancy_capacity = 1;
- source collision footprint in module-local and group-local coordinates.

Machine geometry checks:
- duplicate station IDs: 0
- abs(cell_local_x) > 1.90: 0
- Z / approach range failures: 0
- spacing below 0.65 m: 0
- aisle-to-station approach intersections with unrelated collision furniture: 0

An integrator-friendly `runtime_variant_cell_overrides_preview` is included in the anchor candidate for keys such as `music:R2:0`, `cinema:R3:2`, etc. It is review metadata only and does not overwrite production interaction data.

## Foreground contract

Foreground exists only for:
- music/R2
- music/R3
- cinema/R2
- cinema/R3

All foreground furniture in each variant was authored to a shared camera-facing front plane:

`physical_z = -0.10`

Measured imported mesh fronts differ from the authored target only by floating-point import noise (approximately 1e-7 m).

The delivered metadata explicitly separates:
- runtime physical plane: furniture front edge, `physical_z = -0.10`;
- geometry clipping plane: per-source measured seat-centroid cut used to retain only the true camera-facing occluder fragment.

This prevents the 003 ambiguity where the runtime physical registration plane and geometry clipping plane could be confused.

No foreground is authored for Artifact or Workshop because residents stand in front of the relevant display/work furniture and no camera-facing furniture part physically crosses the body.

## Machine image QA

Production PNG count: 28 / 28 PASS.

All production files:
- exact 1536 x 1024;
- RGBA;
- non-empty;
- per-file SHA-256 recorded.

Godot 4.7.2 staged handoff QA:
- Image load: 28 / 28 PASS
- FORMAT_RGBA8: 28 / 28 PASS
- ImageTexture creation: 28 / 28 PASS
- Sprite3D assignment: 28 / 28 PASS
- foreground physical_z records: 4 / 4 PASS
- width-aware station records: 26 PASS
- errors: 0

## Source policy

No physically broken source asset was scaled by eye.

The two sources rejected in batch 003:
- steel_frame_shelves_01
- bench_vice_01

were not reused.

All external model/material provenance is recorded in TEEA_INT_20261123_004_source_provenance.json.

No Bethesda/Fallout visual assets were used.

## Pending integrator checks

This batch does not claim owner approval.

Integrator must still test in the exact live Dragon House camera/runtime:
1. HOUSE / ROOM registration of R2 and R3 textures;
2. perspective foreground registration using physical_z = -0.10;
3. live resident sprites at all width-aware stations;
4. aisle-to-station paths against runtime collision;
5. no procedural furniture doubling;
6. no overlap into adjacent floors from transparent wide-room texture margins.

No production branch was modified.
No production PR was opened.
No approved:true flag is present.

