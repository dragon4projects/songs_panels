# ZNA_CHAR_NPC_20261123_001 — RES_22 PILOT CORRECTION / HOLD BULK GENERATION

**From:** Dragon House Integrator  
**To:** Znaechka / local character-generation agent  
**Date:** 2026-11-23  
**Scope:** CHARACTERS / NPC / CREATURE ART ONLY  
**Status:** CORRECTION REQUIRED BEFORE BULK BANK GENERATION  
**Owner approval:** false

## 0. HARD STOP

Do **not** start bulk generation for RES_22, RES_23 or RES_24 from the current pilot recipe.

The current RES_22 pilot is useful as a pipeline proof, but it is **NOT a visual PASS** and must not become the template for 66 wardrobe banks.

Existing RES_01..RES_21 production-candidate sprite banks remain the visual family baseline. Dragon explicitly likes their current appearance. Do not redraw them and do not replace their visual language.

## 1. INPUTS THAT MUST BE USED

Use the exact source pack produced by `Znaechka source pack extraction`.

Identity source for the pilot:
- `identities/RES_22_LISA_03.png`
- canonical profile: `RES_22 / Вея / LISA_03`

Visual-family baselines:
- `baseline/RES_01_CITY_IDLE_S_0001.png`
- `baseline/RES_02_CITY_IDLE_S_0001.png`
- `baseline/RES_04_HOME_IDLE_S_0001.png`
- `baseline/RES_11_CITY_IDLE_S_0001.png`
- `baseline/RES_18_CITY_IDLE_S_0001.png`
- `baseline/RES_21_SHORT_IDLE_S_0001.png`

Registry/runtime contracts remain authoritative:
- `meta/resident_profiles.json`
- `meta/asset_registry_nov2026.json`
- `meta/bank_coverage.json`
- `meta/asset_bank_resolver.gd`

## 2. CURRENT PILOT — INTEGRATOR VISUAL VERDICT

Review artifact inspected:
- `RES22_PILOT_REVIEW_BOARD.jpg`
- workflow: `Znaechka review roundtrip`

### FAIL — identity likeness
The generated pilot does not preserve LISA_03 closely enough to be read as the same person at close/ROOM scale.

Corrective target:
- preserve the source face shape;
- preserve cheekbone/jaw proportions;
- preserve eyebrow shape and spacing;
- preserve eye shape/placement;
- preserve nose proportions;
- preserve lip shape;
- preserve the short auburn/brown hairstyle and its asymmetric real-hair silhouette.

Do not merely transfer approximate skin/hair colors onto a generic 3D head.

### FAIL — hair / scalp
Current front/3Q/side views read as a hard scalp cap / helmet with visible hairline seams and long stray guide-like strands.

Required:
- natural volumetric hair silhouette;
- no bald/scalp-cap appearance;
- no hard mesh seam around forehead/temples/ears;
- no guide strands, whisker-like artifacts or detached locks;
- side profile must preserve believable hair volume behind and above the ear.

### FAIL — face/neck geometry
Current pilot shows visible chin/neck discontinuity and geometry-like protrusions.

Required:
- clean jaw-to-neck transition;
- no white triangular protrusions;
- no doubled chin/neck edges;
- no ear/neck clipping;
- no facial topology artifacts in front, 3Q or side.

### FAIL — tonal range / material
Current skin and white clothing are blown out near pure white and lose surface/form information.

Required:
- keep readable skin tone and facial modelling;
- white/light clothes must retain folds, seams, buttons/edges and volume;
- no large clipped-white body regions;
- contrast should sit in the same family as RES_01..RES_21 cutouts.

### FAIL — family/style match
Current pilot reads like a different 3D/avatar pipeline next to the six baseline sprites.

Required visual family:
- photorealistic full-body cutout;
- natural human proportions;
- clean but not plastic skin;
- believable clothing materials;
- feet fully present;
- stable frontal silhouette;
- same apparent human scale as existing banks;
- no game-avatar / mannequin / character-creator look.

## 3. NEXT PILOT — DO NOT GENERATE A FULL BANK YET

Generate **one corrected RES_22 pilot set only**:

1. `FRONT_IDENTITY_CLOSE` — head/upper torso, frontal.
2. `THREE_QUARTER_IDENTITY_CLOSE` — head/upper torso, 3/4.
3. `SIDE_IDENTITY_CLOSE` — head/upper torso, side.
4. `FULL_BODY_IDLE_S` — full body, neutral standing, feet visible.
5. `FULL_BODY_WALK_LEFT_KEY` — one representative walking key frame.
6. `FULL_BODY_RELAXED_SIT_KEY` — one representative seated key frame.

This is a **visual calibration set**, not a runtime bank.

No RES_23/RES_24 generation until this set passes.

## 4. WARDROBE / BODY RULE

Do not force the identity reference outfit to become the wardrobe template.

Identity source = face/body/hair identity reference.  
Wardrobe system = existing Dragon House HOME / CITY / SHORT contract.

For the corrected pilot use clothing that matches the existing bank family and does not conceal silhouette validation. Avoid:
- pure white top overexposure;
- oversized collars hiding neck errors;
- long coats hiding leg proportions;
- extreme heels/platforms during scale calibration.

## 5. BACKGROUND / ALPHA

Final runtime sprites must follow the existing bank alpha/background convention exactly.

For pilot review:
- transparent background preferred;
- no baked floor/background;
- no halo stronger than existing baseline cutouts;
- no cropped hair, hands, feet or clothing edges.

## 6. SCALE / ANCHOR CONTRACT

Before full-bank generation, compare the corrected `FULL_BODY_IDLE_S` against the six supplied baselines.

PASS requires:
- apparent adult human scale consistent with baseline;
- head/body ratio within the existing family;
- both feet visible and usable for feet-anchor derivation;
- no vertical crop;
- no pose-dependent scale jump.

Do not solve a scale mismatch later by arbitrary per-state resizing.

## 7. MACHINE QA GATES FOR THE CORRECTED PILOT

All gates below are required.

### IDENTITY_PASS
- same intended identity readable in FRONT / 3Q / SIDE;
- no generic-head substitution;
- hair color/cut/silhouette remains coherent across views.

### HAIR_PASS
- no scalp cap;
- no hard hairline seam;
- no detached guide strands;
- no ear/hair clipping.

### FACE_NECK_PASS
- no chin/neck split;
- no polygon/triangle protrusion;
- no ear/neck clipping;
- no visible mesh seam.

### MATERIAL_PASS
- skin not clipped to white;
- light clothes retain texture/folds;
- blacks retain internal detail;
- no plastic/mannequin shader look.

### BASELINE_STYLE_PASS
- corrected sprite can sit beside RES_01/02/04/11/18/21 without looking generated by a different visual system.

### SILHOUETTE_PASS
- full body readable at game zoom;
- hands/feet present;
- no body-part fusion;
- standing/walk/sit keys preserve body proportions.

### ALPHA_PASS
- clean cutout;
- no opaque background;
- no excessive fringe/halo.

## 8. REVIEW BOARD REQUIRED

Produce one board with:
- canonical `RES_22_LISA_03.png` at useful face size;
- corrected FRONT / 3Q / SIDE identity close views;
- corrected full-body IDLE_S / WALK_LEFT / RELAXED_SIT keys;
- the six existing baseline sprites at comparable displayed height;
- labels for every cell;
- no beauty filters or post effects that are absent from final sprite bytes.

Also include a JSON review manifest with:
- generation recipe/version;
- source identity SHA-256;
- output SHA-256 per pilot image;
- pixel dimensions/mode;
- transparent-alpha check;
- declared PASS/FAIL for each gate above.

## 9. ACCEPTANCE LOGIC

A machine self-report is not sufficient.

Required sequence:
1. local agent generates corrected RES_22 pilot set;
2. Znaechka runs machine QA;
3. Znaechka publishes review board + manifest;
4. Integrator visually compares against canonical identity and existing bank family;
5. only after integrator visual PASS may the same recipe be expanded to RES_22 bank states;
6. RES_23 and RES_24 start only after RES_22 recipe is stable.

`owner_approved` remains **false** until Dragon reviews the actual character art.

## 10. DO NOT TOUCH

Do not modify:
- room/interior art;
- Teea branches;
- camera/runtime depth;
- door/private-room UI;
- RES_01..RES_21 existing sprite bytes;
- Manjka existing bank;
- production approval flags.

## 11. HANDOFF FORMAT

Return exactly:

```text
ZNA_CHAR_NPC_20261123_001_RES22_PILOT_R2
machine_status: READY_FOR_INTEGRATOR_VISUAL_QA | BLOCKED
owner_approved: false
branch: art/znaechka-characters-ZNA_CHAR_NPC_20261123_001
head: <sha>
identity: RES_22 / LISA_03
pilot_outputs: 6
IDENTITY_PASS: PASS|FAIL
HAIR_PASS: PASS|FAIL
FACE_NECK_PASS: PASS|FAIL
MATERIAL_PASS: PASS|FAIL
BASELINE_STYLE_PASS: PASS|FAIL
SILHOUETTE_PASS: PASS|FAIL
ALPHA_PASS: PASS|FAIL
review_board: <path/url>
review_manifest: <path>
production_banks_generated: 0
```

**BULK GENERATION REMAINS BLOCKED UNTIL THIS PILOT PASSES.**
