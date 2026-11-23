# TEEA_INT_20261123_006 — DEPTH / FUNCTIONAL DRESSING REWORK FOR MEDIA + WORK FAMILIES

**From:** Dragon House Integrator  
**To:** Teea / local interior-authoring agent  
**Date:** 2026-11-23  
**Scope:** INTERIORS ONLY  
**Status:** PREPARED FOR AUTHORING AFTER TEEA005 INTEGRATOR VISUAL CLOSE  
**Owner approval:** false

## 0. ROLE LOCK

TEEA = INTERIORS ONLY.

Do not create or edit:
- resident character banks;
- cats / pets / microfauna;
- Godot life logic;
- door UI / private-room logic;
- owner approval flags.

Znaechka owns character/NPC/creature art. Integrator owns runtime/camera/collision/doors/builds.

## 1. WHY THIS BATCH EXISTS

TEEA004 is functionally sound in current Godot runtime:
- exact payload verified;
- width-aware stations verified;
- foreground registration verified;
- live residents fit the measured furniture at yaw -0.18 / 0 / +0.18.

However, integrator visual review shows that the following families still read too often as a long decorated stage rather than a deep lived cutaway room:
- Music
- Cinema
- Artifact
- Workshop

This batch is a **visual depth and functional-dressing refinement**, not a new room-system design.

Reference principle: study Fallout Shelter only for **depth readability / sectional staging / foreground-mid-rear separation / asymmetrical lived dressing**. Do NOT copy Bethesda art, props, textures, branding or layouts.

## 2. VARIANTS IN SCOPE

Create candidate replacement art for all 12 variants:

- Music R1
- Music R2
- Music R3
- Cinema R1
- Cinema R2
- Cinema R3
- Artifact R1
- Artifact R2
- Artifact R3
- Workshop R1
- Workshop R2
- Workshop R3

Important status seam:
- R1 Music/Cinema/Artifact/Workshop from TEEA003 are already owner-approved production art.
- R2/R3 from TEEA004 are integrator-QA candidates, not owner-approved.

Therefore TEEA006 must remain a **replacement candidate** with `approved:false` / `owner_approved:false` and must not silently overwrite production state.

## 3. PRIMARY VISUAL GOAL — THREE READABLE DEPTH BANDS

At ROOM scale, every variant must clearly read as a shallow 3D volume with:

1. `rear_architecture`
   - back wall / recess / shelves / screen wall / tool wall / display wall;
   - expected major visual Z approximately -1.35 to -1.95 where physically appropriate.

2. `mid_functional`
   - usable furniture / tables / work surfaces / display approach / equipment;
   - stations should not all collapse onto one Z line.

3. `front_functional_or_occluder`
   - one or more meaningful near-depth objects where appropriate;
   - may contain a measured resident station OR only a physically justified occluder;
   - must never become a decorative curtain across the whole room.

The front/mid/rear relationship must be visible at yaw 0 and remain coherent under current Dragon House perspective yaw.

### Machine target
For variants with both front and mid functional stations:
- target cross-band station Z separation: >= 0.45 m;
- absolute minimum: 0.35 m only with explicit geometry justification.

For variants where front functional seating/work is inappropriate, demonstrate depth through furniture faces, recesses, display volumes and occlusion instead of inventing fake stations.

## 4. DO NOT FLATTEN WIDE ROOMS

R2/R3 must not look like R1 duplicated horizontally.

Required:
- one continuous room shell;
- repeated architectural rhythm is allowed;
- furnishing must be asymmetric enough to read as one lived space;
- at least one depth event must cross or visually relate adjacent modules;
- avoid evenly spaced “objects on a shelf” composition across the entire width.

R3 especially must have a visual hierarchy: primary zone, secondary zone, negative space / circulation.

## 5. ROOM-SPECIFIC FUNCTIONAL DRESSING

### MUSIC
The room must visibly read as an audio/listening room, not a generic lounge.

Useful visual vocabulary:
- speakers at physically different depths;
- listening chair(s) / lounge seating;
- turntable / playback console / neutral audio hardware;
- album/audio storage or media shelving;
- cable/equipment logic kept readable, not clutter soup;
- optional instrument stand only if it does not redefine the room as a rehearsal studio.

Do not bake a specific copyrighted album cover into room art.
Actual track/album catalog data remains runtime-owned.

Preferred depth idea:
- rear audio/media wall;
- mid equipment / secondary listening element;
- front listening chair or low foreground edge with measured occlusion.

### CINEMA
The room must visibly read as a film-viewing / film-library space.

Required visual language:
- clear screen / TV / projection surface at rear;
- real viewing seat geometry at mid/front depth;
- film/media storage or neutral poster/display zone;
- lighting that supports screen focus while retaining room-volume cues.

Do not bake copyrighted film posters.
Use neutral/generated placeholders or empty runtime-ready frames.

Avoid:
- sofa pasted directly against screen wall;
- every viewer on one baseline;
- huge foreground sofa fragment that hides lower half of room.

### ARTIFACT
The room must read as spatial display/exhibition, not a flat cabinet wall.

Required:
- at least two visibly different display depths;
- plinth / pedestal / cabinet volumes that cast/receive spatial overlap;
- standing viewing stations outside collision footprints;
- clear path through displays;
- empty negative space around important artifacts.

Actual artifact identity/ownership remains runtime/data-owned. Do not invent canonical artifacts.

Avoid a “library with glass boxes” look.

### WORKSHOP
The room must read as active making/repair space with real work depth.

Required:
- workbench(s) / work surfaces at usable depth;
- tool/storage wall or rear storage;
- one foreground or mid-depth work element where safe;
- believable approach path to every work station;
- practical clutter, but not a solid wall of small props.

Do not create impossible work stations inside a bench footprint.
Do not use decorative objects to hide missing spatial depth.

## 6. OBJECT DISTRIBUTION / LIVED-IN RULE

The current House needs furniture and functional objects distributed by room purpose.

Do not use Library as generic storage for unrelated systems.

Examples of correct destination logic:
- audio hardware / album shelving -> Music;
- TV/screen / film storage -> Cinema;
- tools / parts / bench storage -> Workshop;
- display stands/cabinets -> Artifact;
- drinks / cups may appear only as sparse lived-in dressing in appropriate social/rest contexts, not as required room identity.

The art may show neutral physical holders/shelves/screens. Actual media content stays runtime-driven.

## 7. EXISTING FUNCTIONAL CONTRACT MUST NOT REGRESS

Use TEEA003 R1 and TEEA004 R2/R3 station sets as the starting functional contract.

You may move furniture/stations only when the depth rework physically requires it.
If any station moves:
- remeasure from source geometry;
- publish new `group_local_x`, `cell_local_x`, `cell_local_z`;
- preserve module_index semantics;
- preserve kind / intended activity semantics;
- publish updated collision footprint;
- rerun approach and spacing QA.

Do not move a station just to make a contact sheet prettier.

Do not reduce practical room function without explicit reason.

## 8. FOREGROUND CONTRACT

Foreground is allowed only when generated from the same physical furniture geometry represented in `furniture_back` / authored scene.

For every foreground layer provide:
- source furniture ID(s);
- exact measured front plane(s);
- selected `physical_z`;
- measurement provenance;
- explanation of what body/object region the fragment is supposed to occlude.

PASS requires:
- no detached foreground at yaw -0.18 / 0 / +0.18;
- no visible scale jump;
- no foreground covering an unrelated station;
- no foreground whose only purpose is “more depth”.

If no physically useful foreground is needed, omit it.

## 9. CURRENT CAMERA PROOF — REQUIRED

Do not validate only in Blender orthographic view.

Provide proof using current Dragon House perspective assumptions and current registration math.

For **every 12 variant** provide yaw proof at:
- -0.18
- 0.00
- +0.18

At minimum use resident-sized placeholders at measured stations.
Integrator will later repeat this with actual Godot resident sprites.

PASS checks:
- rear/mid/front remains readable;
- no furniture-plane detachment;
- no foreground detachment;
- no obviously floating station;
- no actor placeholder hidden by unrelated object;
- no neighboring-room/floor content baked into production PNG.

## 10. ART / FILE CONTRACT

Per variant:
- exact 1536 x 1024 PNG;
- RGBA8;
- transparent alpha where layer role requires it;
- roles limited to existing runtime roles:
  - `backdrop`
  - `back_decor`
  - `furniture_back`
  - `foreground` only if physically justified;
- SHA-256 for every production PNG;
- no `.import` files in handoff;
- no approval promotion.

Keep output compatible with Godot 4.7.2 ImageTexture/Sprite3D.

## 11. STATION / COLLISION PASS

For every station:
- stable ID;
- furniture ID;
- module_index;
- group_local_x;
- cell_local_x;
- cell_local_z;
- kind;
- pose_hint from runtime-supported set;
- approach_local_z;
- occupancy_capacity = 1;
- source collision footprint.

Required:
- station bounds errors = 0;
- foreign collision / approach intersections = 0;
- spacing errors = 0;
- station inside unrelated furniture = 0;
- module index errors = 0.

If two seats on the same physical sofa are <0.65 m apart, document the exact seat-centre geometry and prove no sprite-body overlap in the yaw proof.

## 12. DEPTH READABILITY REPORT

For every variant publish:
- major furniture IDs and front/back Z extents;
- station Z and declared depth band;
- foreground physical_z if present;
- minimum cross-band functional separation;
- one sentence explaining the intended visual hierarchy.

Required machine result:
`depth_readability_machine_pass = true` for 12/12.

Machine pass does NOT equal owner visual approval.

## 13. PERFORMANCE DISCIPLINE

Target remains low-end Dragon House hardware.

Do not solve depth by adding runtime 3D clutter.
The authored layered PNG approach remains primary.

Keep:
- limited layer count;
- no unnecessary alpha-fullscreen layer;
- no baked animated effects;
- no excessive tiny detail that disappears at ROOM/HOUSE scale.

## 14. STOP CONDITIONS

Stop and report instead of improvising if:
- a source furniture asset has physically wrong bbox/scale;
- correct depth requires changing cutaway calibration (`backwall_z`, aisle, module width);
- a station cannot be reached without foreign collision;
- a foreground cannot be tied to a measured physical plane;
- the only way to “improve” a room is to replace its functional identity.

Do not scale broken source furniture by eye.

## 15. REQUIRED HANDOFF

Deliver:
- proposal manifest;
- furniture-anchor candidate;
- foreground candidate;
- authoring layout;
- source provenance;
- image QA;
- collision/spacing report;
- depth-readability report;
- yaw-proof report + images;
- Godot 4.7.2 image load log;
- contact sheet;
- binary ZIP pointer;
- ZIP SHA-256.

Return exactly:

```text
TEEA_INT_20261123_006
machine_status: READY_FOR_INTEGRATOR_QA | BLOCKED
owner_approved: false
branch: art/teea-interiors-TEEA_INT_20261123_006
head: <sha>
production_pr: NONE
variants: 12
production_png: <count>
measured_stations: <count>
foreground_variants: <count>
depth_readability_pass: <n>/12
yaw_proof: 12/12 at -0.18 / 0 / +0.18
station_bounds_errors: 0
spacing_errors: 0
foreign_collision_approach_intersections: 0
```

No production merge. No `approved:true`. Integrator QA first, Dragon visual approval later.
