# Dragon House — TEEA interior pilot composition report

Batch: `TEEA_INT_20261122_001`  
Date: 2026-11-22  
Branch: `art/teea-interiors-TEEA_INT_20261122_001`  
Target branch: `dragon-house-fallout-fresh`  
Status: **BLOCKED DURING PILOT GENERATION — NO TECH_PASS CLAIM**

## Scope actually performed

The implementation contract was read from the target branch before generation:

- `docs/V06_CUTAWAY_LOD_CAMERA.md`
- `scripts/interior_skin.gd`
- `data/interior_layers_v1.json`
- `scripts/main.gd`
- `scripts/world_model.gd`

The September→November Dragon House canon was also reread from the cloud Library, including the active interior visual/aesthetic direction and current furniture/item rules.

Locked implementation facts used:
- R1/R2/R3 world widths = 4.8 / 9.6 / 14.4 Godot units.
- Accepted art is mounted by `interior_skin.gd` at local y=1.50 and scaled by physical group width / pixel width.
- Only `approved:true` records render.
- Private interiors remain door/facade only.
- Existing shallow 3D shell, actor lane, shell structure and runtime furniture remain engine-owned.
- Pilot order: common/R3 → library/R2 → study/R1 → rest/R1.

## Canon retained

Visual direction retained:
- real inhabited worked cave, not castle/hotel/tavern/museum;
- natural cave + accumulated domestic life + repairable furniture + selective warm light;
- restrained warm graphite/brown-grey rock, worn wood, blackened metal, matte leather/wool/linen/fur;
- no matching furniture showroom, no fantasy gold trim, no neon/magical edge glow;
- empty capacity/negative space is intentional;
- Common identity remains Dragon berth + hearth + social gathering;
- Library contains shelves/reading stations but no invented mugs;
- Rest is quiet reading/relaxation, not a bedroom;
- Study is practical accumulated work, not decorative “dark academia”.

## Generation attempts

### Attempt 1
Requested: isolated `common/R3/backdrop` plate.  
Observed: generator produced a multi-room Dragon House infographic / asset-pack board with labels and technical UI.  
Disposition: **REJECTED / not production art**.

### Attempt 2
A neutral 4.5:1 layout guide was created to constrain geometry.  
Requested again: isolated Common/R3 backdrop, no people/furniture/text/UI.  
Observed: one visually useful photoreal cave-room backdrop was produced, but its output aspect did not match the required 4608×1024 plate and it was not safely layer-aligned to the runtime shell.  
Disposition: **CONCEPT_ONLY / not TECH_PASS**.

### Attempt 3
Requested: transparent `back_decor` aligned to the preceding Common backdrop.  
Observed: generator again returned an unrelated multi-room infographic/contact-board rather than the requested transparent layer.  
Disposition: **REJECTED**.

At this point generation was stopped per the brief’s “one serious mismatch → REWORK” rule. Continuing to mass-produce would create false assets and destroy layer alignment.

## Exact blocker

The user explicitly requested the built-in/own image generator. In this long project context that generator currently does not reliably isolate the requested production plate or preserve the requested room/layer edit target. The failure is repeatable: room-layer prompts collapse back into a Dragon House overview/infographic.

This blocks:
- exact six-role decomposition;
- aligned transparent plates;
- exact actor-safe occlusion proof;
- 25% reduced-view proof;
- Godot composite test of the proposed layers;
- honest TECH_PASS.

The blocker is **generation control**, not the GitHub branch, Godot loader, file contract or visual specification.

## What was deliberately NOT done

- No mass production after pilot failure.
- No changes to gameplay scripts.
- No changes to `data/interior_layers_v1.json`.
- No `approved:true`.
- No private-room interiors.
- No lift art.
- No fabricated SHA-256 values.
- No claim that an infographic/collage is a production plate.
- No stretching of an R1 room into R2/R3.
- No invented resident/lore symbols.

## Anchor proposals

None delivered because no layer reached a stable composite. Interaction anchors must only be proposed against an accepted/aligned composite so that painted furniture does not conflict with engine-owned collision/stations.

## Required resume condition

Resume from `common/R3` only when the image generator can reliably produce/edit one isolated room plate while preserving:
1. a fixed 4.5:1 composition;
2. consistent camera/origin across edits;
3. real transparency for non-backdrop roles;
4. no text/UI/people;
5. stable floor/ceiling line.

Then complete exactly one pilot batch and stop for owner review before expansion.
