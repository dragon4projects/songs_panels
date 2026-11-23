# TEEA_INT_20261123_006 — POLY HAVEN HARVEST / LIVED-IN DRESSING ADDENDUM

**From:** Dragon House Integrator  
**To:** Teea / local interior-authoring agent  
**Date:** 2026-11-23  
**Scope:** INTERIORS ONLY  
**Status:** REQUIRED ADDENDUM TO TEEA_INT_20261123_006  
**Owner approval:** false

## 0. PURPOSE

Use the completed Poly Haven harvest as the source geometry / prop vocabulary for the current TEEA006 depth+dressing rework.

This does **not** create a new room batch. Continue `TEEA_INT_20261123_006` on the existing branch.

The goal is the Dragon House visual rule:

> accumulated cave-house / collected over years / mismatched objects with history, not a coordinated furniture catalogue.

Use clutter to strengthen depth, lived-in causality and room identity. Do not clutter merely to raise object count.

## 1. AUTHORITATIVE HARVEST INPUT

Library pointer:
`/Dragon cave/DRAGON_HOUSE_ARCHITECT_2026-09-29/POLYHAVEN_ASSET_HARVEST_20261123.md`

Archive:
`https://d2ol7oe51mr4n9.cloudfront.net/user_3JdI9kJ82xObF8Bi3EgU4P6DaoR/f53353a0-343e-46f4-aefe-43450a6404d3.zip`

SHA-256:
`db6a8f396e700c22a49f7ac75e06907f75c1691616176c491e8ef8acca726dbd`

Archive facts:
- 137 unique selected models;
- 137/137 source/provenance available;
- 134 `READY`;
- 2 `READY_BUT_ODD`: `alarm_clock_01`, `vintage_grandfather_clock_01`;
- 1 `READY_NORMALIZED`: `steel_frame_shelves_01`;
- source working packages use 1K textures.

## 2. CRITICAL SOURCE RULES

### steel_frame_shelves_01

The original source import is physically wrong by exactly x10.

Use **only the normalized x0.1 copy** for authoring/measurement.
Verified normalized dimensions:
- 1.097415 m × 0.502118 m × 2.140501 m.

Preserve the original source as provenance only.
Do not rescale by eye.

### decorative_book_set_01

Poly Haven currently provides no glTF package for this asset.
The harvested working glTF was converted from the original 1K FBX+textures in Blender 4.5.16.
Keep conversion provenance attached.

### READY_BUT_ODD models

`alarm_clock_01` and `vintage_grandfather_clock_01` require a visual scale/orientation check in the actual room before final placement.
Do not fail them automatically, and do not silently normalize them without measured evidence.

## 3. RUNTIME / PERFORMANCE SEAM

The 137 models are an **authoring source library**, not permission to instantiate 137 runtime 3D assets.

Default rule for TEEA006:
- use Poly Haven geometry to compose / render / author the existing layered room-art pipeline;
- final room layers remain the established 1536×1024 RGBA8 PNG roles;
- default classification for harvested props = `BAKED_ART_SOURCE`;
- a prop becomes a runtime-3D candidate only if a later interaction genuinely requires separate geometry.

If you believe a placed asset must remain runtime-separate, list it explicitly under `runtime_prop_candidates` with:
- asset_id;
- reason it cannot be baked;
- physical bbox;
- collision need;
- interaction/station need;
- expected runtime benefit.

Do not import the entire harvest into the live Godot scene tree.
Do not create a material/node explosion to solve room dressing.

## 4. FRAME ASSETS

Poly Haven picture-frame models are **frame geometry only**.

Stock frame artwork/images are not Dragon House content.
For every visible frame:
- remove/cover stock image content;
- use Dragon House poster / painting / memory / cover / photo / artifact artwork where an approved/public asset exists;
- otherwise leave a neutral blank insert or mark the insert as pending;
- never invent private-room content.

Required manifest field for each used frame:
`insert_content_id` or `PENDING_PUBLIC_INSERT`.

## 5. ROOM POOLS FOR TEEA006

TEEA006 scope remains:
- Music R1/R2/R3
- Cinema R1/R2/R3
- Artifact R1/R2/R3
- Workshop R1/R2/R3

Use the harvest primarily as follows.

### Music
Required candidates to evaluate:
- `portable_cassette_player`
- `boombox`
- compatible frame geometry for later album/poster inserts

Rules:
- these supplement existing music equipment; they do not replace the room's primary listening identity;
- use them to create front/mid/rear rhythm rather than lining every device on one wall;
- at least one variant should show a visibly personal/accumulated listening corner rather than a showroom rack.

### Cinema
Required candidates to evaluate:
- `Television_01`
- `gaming_console`
- `gamepad`
- `sofa_02` where useful

Rules:
- TV+console+gamepad form a **secondary game corner**;
- they do not replace the main cinema/screen function;
- game corner should occupy a different depth/local cluster from the main viewing focus;
- do not create duplicate TVs/screens without a readable functional reason.

### Workshop
Required candidates to evaluate:
- `industrial_storage_cart`
- `worn_metal_rack`
- `lubricant_spray`
- `chemistry_set`
- `bunsen_burner`
- industrial sconces/lights
- deliberately mismatched stools
- `metal_stool_01` as cat-perch candidate, NOT a human station by default

Rules:
- clutter must read as work history, not random obstacle spam;
- keep approach lanes to authored work stations clear;
- chemistry/Bunsen may cross-pollinate with Study in future, but TEEA006 itself edits only Workshop among these families;
- cat-perch candidates receive metadata only; Znaechka/runtime owns cats.

### Artifact
Required candidates to evaluate:
- normalized `steel_frame_shelves_01`
- `steel_frame_shelves_03`
- Chinese cabinets / commode
- `ClassicConsole_01`
- treasure chest
- compass / shell
- bronze/stone/gothic statues
- animal heads / bust
- vases / baskets
- katana stand
- odd lighting

Rules:
- this room is allowed to be the most eclectic / curiosity-cabinet-like;
- do NOT organize by civilization/era into clean museum zones;
- objects should feel collected, inherited, stolen, gifted or found, without inventing specific biography in metadata;
- keep every standing-view station's sight line and approach clear;
- use asymmetrical depth clusters and controlled partial occlusion.

## 6. CROSS-ROOM HARVEST RULES

These harvest families are documented but are **not TEEA006 scope** unless used as tiny compatible dressing props:
- Arrival pool;
- Corridor frames/clocks;
- Common pool;
- Study pool;
- Rest pool;
- Library pool.

Do not silently re-author accepted 002/003/005 families during 006.
If a harvested prop clearly improves one of those rooms, add it to `future_dressing_candidates` only.

## 7. KITCHEN / PRIVATE HARD STOPS

### KITCHEN_RESERVE

There is no current Kitchen room type in the live registry.
Keep these in reserve:
- `vintage_microwave`
- `electric_stove`
- `vintage_electric_kettle`
- `CoffeeCart_01`
- pots/pans/jugs and large kitchen-specific sets.

Small tea/wine/thermos/bowl/croissant/can props may appear in Common later, but TEEA006 does not reopen Common.

Do not build a fake kitchen inside Music/Cinema/Artifact/Workshop.

### PRIVATE_RESERVE

`GothicBed_01` and personal/private room dressing remain reserve.
Private interiors remain facade-only unless separately authorized by the room owner.

## 8. DRESSING MUST SUPPORT DEPTH

Every selected prop must have a purpose in at least one of these categories:
- shell-depth cue;
- rear silhouette;
- mid functional cluster;
- front functional/occlusion cue;
- lived-in micro-story without fabricated biography;
- interaction support;
- lighting/value separation.

Reject a prop placement if its only justification is "there was empty space".

For R2/R3:
- avoid repeating one decorated bay three times;
- create 2–3 different local clusters;
- stagger meaningful silhouettes across Z;
- preserve the public aisle;
- preserve resident readability at HOUSE and ROOM zoom.

## 9. PLACEMENT MANIFEST — REQUIRED

For every harvest model actually used in TEEA006, publish:

- `asset_id`
- source/provenance pointer
- room type
- R width
- module index
- authoring transform
- measured physical bbox after transform
- depth band = rear / mid / front
- `use_class` = `BAKED_ART_SOURCE` | `RUNTIME_PROP_CANDIDATE`
- collidable source geometry yes/no
- interaction station source yes/no
- if station source: station ID(s)
- if foreground contributor: measured physical front Z
- if frame: `insert_content_id`
- if reserve only: reserve class and no placement transform

No untracked prop may appear in final candidate art.

## 10. VISUAL / TECH PASS

PASS only if all are true:

- 12/12 TEEA006 variants still satisfy the existing depth addendum;
- harvested dressing reinforces front/mid/rear readability rather than flattening it;
- no station/approach/collision regression;
- no kitchen leakage into current 006 rooms;
- no private-room asset leakage;
- normalized steel shelf used instead of broken source scale;
- both READY_BUT_ODD clocks, if used, have explicit visual scale/orientation review record;
- stock Poly Haven frame images are absent from final Dragon House layers;
- no matching-suite showroom look;
- no obvious copy/paste clutter rhythm in R2/R3;
- no asset is present without placement-manifest provenance;
- final runtime art remains within existing layered PNG contract;
- `approved:false` / `owner_approved:false` remains unchanged.

## 11. REQUIRED HANDOFF ADDITIONS

Add to the normal TEEA006 handoff:
- `TEEA_INT_20261123_006_harvest_usage.json`
- `TEEA_INT_20261123_006_reserve_candidates.json`
- `TEEA_INT_20261123_006_runtime_prop_candidates.json`
- one contact sheet showing room candidates with harvest asset IDs overlaid for integrator review
- count of unique harvest assets actually used vs reserve-only.

No production PR.
No owner approval promotion.
