# ZNA_CHAR_NPC_20261123 — RES_22..RES_24 INTEGRATOR DROP FEEDBACK R2

**From:** Dragon House Integrator  
**To:** Znaechka / local character-generation agent  
**Date:** 2026-11-23  
**Role scope:** CHARACTERS / NPC / CREATURE ART ONLY  
**Source package:** `Dragon_House_RES22_24_integrator_drop.zip`  
**Owner approval:** false

## 0. MACHINE VERDICT

```text
package_access: PASS
package_structure: PASS
frame_count: PASS (423 PNG)
canvas_rgba_alpha: PASS
sha_manifest_for_drop_payload: PASS
walk_frame_uniqueness: PASS
 drink_frame_uniqueness: PASS
registry_state_coverage: PASS
visual_identity_RES_22: FAIL
visual_identity_RES_23: PROVISIONAL_PASS_ONLY
visual_identity_RES_24: FAIL
production_ingest: BLOCKED
owner_approved: false
```

Do **not** regenerate the entire package blindly. The packaging / state coverage work is useful and should be preserved. The blocker is identity fidelity, not the bank grammar.

---

## 1. EXACT PACKAGE CHECKED BY INTEGRATOR

Cloud delivery inspected:

`/Dragon cave/DRAGON_HOUSE_ARCHITECT_2026-09-29/INTEGRATOR_DROP_RES22_24_20261123/Dragon_House_RES22_24_integrator_drop.zip`

Exact package contains:
- `RES_22` — Veya / `LISA_03`
- `RES_23` — Khitrushka / `VALENTA_03`
- `RES_24` — Yazvochka / `LISA_01`
- `SHORT`, `HOME`, `CITY` for each resident
- 22 states per wardrobe
- 47 frames per wardrobe
- 141 frames per resident
- 423 PNG total

Independent integrator checks:
- every delivered frame = PNG
- every delivered frame = RGBA
- every delivered frame = exactly 512x512
- visible alpha silhouette present
- transparent pixels present
- all required directories / zero-padded filenames present
- SHA-256 entries corresponding to the drop payload match exact bytes
- WALK_LEFT = 12/12 unique frames for every wardrobe
- WALK_RIGHT = 12/12 unique frames for every wardrobe
- DRINK = 4/4 unique frames for every wardrobe
- `visual_bank_ready` remains false

These are PASS and must not be destroyed by corrective work.

---

# 2. RES_22 / VEYA / LISA_03 — VISUAL FAIL

## Authoritative identity input

`RES_22 / LISA_03`

Identity master inspected by integrator:
- dark auburn / brown asymmetric short bob;
- warm copper/red strands;
- strong green eyes;
- dark burgundy lips;
- angular jaw / cheekbone structure;
- recognizable mature face.

## Current delivered bank problem

The delivered Veya bank repeatedly resolves the character as a pale ash-blonde / silver-blonde woman.

The face retains some broad structural similarity, but the hair identity is materially wrong and the total read is no longer the same canonical character.

This is visible in at least:
- `VEYA_HOME.jpg`
- `VEYA_CITY.jpg`
- `VEYA_SHORT.jpg`
- `RES_22/wardrobes/HOME/IDLE_S/0001.png`

### FAIL reasons

- hair hue is wrong: canonical dark auburn/brown -> delivered pale ash/silver-blonde;
- hairstyle texture / volume drifts away from LISA_03;
- several generated states read as a different woman rather than the same identity in a different wardrobe;
- the earlier pilot identity warning was therefore not actually solved for the full bank.

## Required correction

Preserve all technically valid source frames that already match identity. Replace only frames that fail the identity gate.

For corrected generation:
- lock LISA_03 identity master as the primary identity reference;
- preserve dark auburn/brown hair with copper/red warmth;
- preserve source bob length and asymmetric volume;
- do not allow blonde, ash-blonde, gray-blonde or silver-blonde drift;
- preserve facial proportions before wardrobe styling;
- wardrobe may change; identity must not.

### RES_22 PASS gate

PASS only if a new contact sheet shows HOME/CITY/SHORT side by side and all three read immediately as the same LISA_03 person.

Integrator requires before full replacement:
- HOME: `IDLE_S`, `TALK`, `RELAXED_SIT`, `SLEEP`, `WALK_LEFT[0/6/11]`, `DRINK[0/3]`
- CITY: same selection
- SHORT: same selection

Do not bulk replace remaining frames until this subset is visually accepted.

---

# 3. RES_23 / KHITRUSHKA / VALENTA_03 — PROVISIONAL VISUAL PASS ONLY

## Authoritative identity input

`RES_23 / VALENTA_03`

The delivered bank is materially closer to the identity master than RES_22 / RES_24:
- curly auburn/brown hair family is preserved;
- face shape / eye placement broadly remain recognizable;
- wardrobe changes do not completely replace the identity;
- HOME/CITY/SHORT remain broadly coherent with one another.

Therefore:

```text
RES_23 integrator_identity_direction: PROVISIONAL_PASS
owner_approved: false
production_ready: false
```

This is not permission to set `visual_bank_ready=true`.

Before production ingest, provide a focused identity sheet containing:
- identity master;
- HOME/CITY/SHORT `IDLE_S` at larger scale;
- HOME/CITY/SHORT `TALK`;
- HOME/CITY/SHORT one side walk frame;
- HOME/CITY/SHORT `RELAXED_SIT`.

PASS requires no face swap / hair-color jump / body-scale jump across wardrobes.

---

# 4. RES_24 / YAZVOCHKA / LISA_01 — VISUAL FAIL

## Authoritative identity input

`RES_24 / LISA_01`

Identity master inspected by integrator:
- long dark auburn / near-black wavy hair;
- strong warm copper/red highlights;
- hair length well below shoulders;
- strong green eyes;
- dark burgundy lips;
- recognizable sharp face structure.

## Current delivered bank problem

The delivered Yazvochka is consistently a long-haired golden / light blonde woman.

This is not a small color-grade error. It changes the primary identity silhouette and makes the bank read as a different character.

Visible in:
- `YAZVOCHKA_HOME.jpg`
- `YAZVOCHKA_CITY.jpg`
- `YAZVOCHKA_SHORT.jpg`
- `RES_24/wardrobes/HOME/IDLE_S/0001.png`

### FAIL reasons

- canonical long dark auburn/black hair is replaced by golden blonde;
- copper highlights are not equivalent to changing the entire base hair color;
- the overall head silhouette / color mass no longer matches LISA_01;
- wardrobe consistency cannot compensate for identity replacement.

## Required correction

Preserve technically valid bank structure and regenerate identity-failing frames with LISA_01 locked.

Hard constraints:
- base hair must remain dark auburn / near-black;
- copper/red highlights may remain visible;
- preserve long wavy silhouette below shoulders;
- do not allow blonde base hair;
- preserve face proportions and eye/lip identity before wardrobe styling.

Use the same limited subset gate as RES_22 before regenerating the entire bank.

---

# 5. PROVENANCE / MIXED-SOURCE RULE

Integrator inspected `resident_banks_res22_res24_sources.json`.

The package correctly records a mixture of:
- `archived_original_frame`;
- `archived_sheet_recrop`;
- `imagegen`;
- `mirrored_walk`.

This is acceptable as provenance, but PASS is determined by final visual continuity, not by method name.

Do not assume an `archived_original_frame` is automatically canonical if its visual identity conflicts with the current authoritative identity master.

Do not hide source mixing. Keep provenance explicit.

For mirrored walk frames:
- only mirror when clothing/accessories are mirror-safe;
- if an asymmetric visible feature exists, generate/recover the actual opposite direction instead.

---

# 6. MANIFEST / INGEST RULE

Do not ask the integrator to replace current production manifests wholesale.

The current production branch has moved beyond the base used to build this package (TEEA003 production art, privacy/door runtime, pose fixes, physical-object lifecycle).

Next delivery must provide **delta-oriented metadata** for RES_22..RES_24, or an explicit merge map.

PASS:
- existing RES_01..RES_21 hashes unchanged;
- current production metadata unrelated to RES_22..RES_24 remains untouched;
- only RES_22..RES_24 registry/state/index/SHA additions or corrections are proposed.

---

# 7. DOWNSTREAM NPC TASKS

`ZNA_CHAR_NPC_20261123_002_TASK_EN.md` and `ZNA_CHAR_NPC_20261123_003_TASK_EN.md` currently describe RES_22..RES_24 as an **accepted** delivery.

That wording is incorrect.

Correct status:

```text
RES_22..RES_24 structural packaging contract: ACCEPTABLE REFERENCE
RES_22..RES_24 visual identity family: NOT ACCEPTED AS A WHOLE
RES_22: VISUAL FAIL
RES_23: PROVISIONAL VISUAL PASS ONLY
RES_24: VISUAL FAIL
owner_approved: false
```

You may reuse the folder grammar / frame-count / manifest discipline.

You must **not** use the failed RES_22 / RES_24 appearance as the visual identity template for new humanoid NPCs.

Creature NPC work may continue only from its own explicit approved visual masters / references.

---

# 8. REQUIRED NEXT HANDOFF

Return a small correction gate first, not another 423-frame dump.

Required files:

```text
ZNA_RES22_RES24_IDENTITY_CORRECTION_R1/
  RES_22_identity_master.png
  RES_22_HOME_gate.jpg
  RES_22_CITY_gate.jpg
  RES_22_SHORT_gate.jpg
  RES_24_identity_master.png
  RES_24_HOME_gate.jpg
  RES_24_CITY_gate.jpg
  RES_24_SHORT_gate.jpg
  RES_23_identity_check.jpg
  CORRECTION_REPORT.md
```

The gate sheets must include the exact selected frames listed above at readable size.

## PASS

- RES_22 reads as LISA_03 in all three wardrobes;
- RES_24 reads as LISA_01 in all three wardrobes;
- RES_23 identity continuity remains stable;
- no changes to RES_01..RES_21;
- no owner approval claimed;
- no full-bank regeneration until the identity correction gate passes.

## Final machine status until corrected

```text
machine_status: CORRECTION_REQUIRED
technical_structure: PASS
visual_identity: FAIL_PARTIAL
production_ingest: BLOCKED
owner_approved: false
```
