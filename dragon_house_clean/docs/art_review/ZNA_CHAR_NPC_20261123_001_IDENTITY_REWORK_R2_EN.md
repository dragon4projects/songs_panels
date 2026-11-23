# ZNA_CHAR_NPC_20261123_001 — RES_22/23/24 IDENTITY REWORK R2

**From:** Dragon House Integrator  
**To:** Znaechka / local character-generation agent  
**Date:** 2026-11-23  
**Scope:** CHARACTERS / NPC ONLY  
**Status:** CORRECTION REQUIRED — CURRENT 423-FRAME DROP IS TECH PASS / VISUAL IDENTITY FAIL  
**Owner approval:** false

## 0. HARD DECISION

The delivered RES_22–RES_24 package is technically usable as a **pose / state / crop / folder-structure reference**, but it is **NOT approved for runtime ingestion** because the generated character identity does not consistently match the canonical identity masters.

Do not discard the work. Preserve the current 423-frame package as `R1_TECH_REFERENCE`.
Do not promote it to production.
Do not set `visual_bank_ready=true`.

## 1. CURRENT TECHNICAL RESULT — KEEP

The current package successfully proves:
- RES_22 / RES_23 / RES_24 folder grammar;
- HOME / CITY / SHORT wardrobes;
- 22 states per wardrobe;
- 47 frames per wardrobe;
- 141 frames per resident;
- 423 PNG total;
- 512x512 RGBA;
- transparent non-empty alpha;
- zero-padded frame naming;
- manifest / SHA / registry-delta structure.

This technical structure may be reused unchanged.

## 2. CURRENT VISUAL FAILURE — IDENTITY LOCK

Integrator comparison used the exact source pack:
- `identities/RES_22_LISA_03.png`
- `identities/RES_23_VALENTA_03.png`
- `identities/RES_24_LISA_01.png`

and current accepted-family baselines:
- RES_01 / RES_02 / RES_04 / RES_11 / RES_18 / RES_21 sample frames.

Observed failures:

### RES_22 / Вея / LISA_03 — FAIL
Canonical identity:
- short dark auburn/brown asymmetrical bob;
- specific LISA_03 face / eye / brow / jaw / mouth proportions.

Current delivered bank:
- reads as a different light/blonde woman in multiple wardrobes;
- hair color, hair silhouette and face identity do not preserve LISA_03.

### RES_23 / Хитрушка / VALENTA_03 — HOLD / REWORK
Canonical identity:
- distinct curly auburn/red-brown hair and VALENTA_03 face.

Current bank is closer than RES_22/24 but still must pass the same identity-lock gate.
Do not accept it merely because color family is closer.

### RES_24 / Язвочка / LISA_01 — FAIL
Canonical identity:
- long dark brunette hair;
- specific LISA_01 face / brow / eye / jaw / mouth proportions.

Current delivered bank:
- reads as a different blonde/light-haired woman across wardrobes;
- canonical hair silhouette and face identity are lost.

## 3. PROHIBITED SHORTCUTS

Do NOT solve this by:
- recoloring a generic blonde/light base;
- using one common female face for multiple residents;
- swapping wardrobe while allowing identity drift;
- mirroring a frame if asymmetric face/hair/accessory details become wrong;
- changing canonical hairstyle to fit the pose generator;
- accepting a full-body image because the face is small at HOUSE zoom;
- claiming identity PASS from technical PNG QA.

Identity must survive ROOM zoom and close review.

## 4. SOURCE PRIORITY

For each resident, priority order is:

1. canonical identity master for face/hair/identity;
2. accepted RES_01..RES_21 visual family for render language, body scale and sprite presentation;
3. current R1 423-frame package for pose/crop/state geometry only;
4. wardrobe prompts/details.

Never let item 3 override item 1.

## 5. R2 GATE — DO NOT REBUILD 423 FRAMES YET

First deliver an **18-image identity gate**, exactly 6 images per resident.

For each of RES_22, RES_23, RES_24 produce:

1. `HOME/IDLE_S/0001.png`
2. `CITY/IDLE_S/0001.png`
3. `SHORT/IDLE_S/0001.png`
4. `HOME/IDLE_E/0001.png`
5. `HOME/IDLE_W/0001.png`
6. one representative `HOME/WALK_RIGHT` mid-stride frame

Technical:
- 512x512 RGBA;
- transparent background;
- same feet-anchor/body scale family as existing accepted banks;
- no background/text;
- full silhouette inside canvas.

Visual:
- same person across all six frames;
- canonical face readable in front and side views;
- canonical hair color, length, volume, parting and silhouette preserved;
- wardrobe change does not change face or hair identity;
- no face/neck seams, scalp-cap, geometry spikes or detached hair artifacts.

## 6. IDENTITY GATE CONTACT SHEET — REQUIRED

Create one contact sheet per resident with:
- canonical identity master enlarged;
- the six R2 gate frames;
- 2 accepted-family baseline residents at comparable sprite scale;
- face crops from HOME/CITY/SHORT IDLE_S;
- hair silhouette crops from front/side;
- label each image with exact path.

No beauty score.
No self-assigned 9.5/10.
Return factual PASS/FAIL fields only.

## 7. R2 PASS CRITERIA

A resident passes the identity gate only if all are true:

- canonical hair family preserved;
- canonical face shape preserved;
- eye/brow placement materially consistent with master;
- nose/mouth/jaw proportions materially consistent with master;
- front/side views read as the same person;
- all three wardrobes read as the same person;
- no generic-face substitution;
- no hair/scalp artifacts;
- no neck/chin geometry artifacts;
- body scale and feet anchor compatible with accepted banks;
- visual family matches RES_01..RES_21 at gameplay scale.

Integrator may mark:
- `IDENTITY_PASS`
- `IDENTITY_REWORK`

Only `IDENTITY_PASS` residents may proceed to full-bank rebuild.

## 8. FULL BANK REBUILD AFTER GATE PASS

After all three identity gates pass:
- rebuild/re-identity the complete 423-frame package;
- current R1 frames may be reused as pose/crop guides;
- exact R1 pixels may only be kept where identity already matches the canonical master;
- preserve current folder/state/frame-count contract;
- rerun SHA/manifest/PNG QA;
- regenerate all 9 wardrobe preview sheets;
- add `identity_consistency_report.json`.

Required identity report per frame/state:
- resident_id
- wardrobe
- state
- source identity master
- generation/reprojection method
- manual/automatic identity check status
- warnings

## 9. DELIVERY CONTRACT

Do not return local `/mnt/data` paths as the only handoff.

PASS delivery must use:
- GitHub LFS + branch/head, or
- GitHub Actions artifact + digest, or
- Dragon House shared Library.

Current shared handoff folder is valid:
`/Dragon cave/DRAGON_HOUSE_ARCHITECT_2026-09-29/INTEGRATOR_DROP_RES22_24_20261123/`

For R2 use a new clearly versioned folder/artifact; do not overwrite R1 silently.

## 10. HOLD OTHER NPC WORK

Do **not** start:
- centaur;
- vampire girl;
- magical AI sphere;
- hedgehogs;
- any new humanoid NPC bank

until RES_22/23/24 identity R2 is accepted.

The local file `ZNA_CHAR_NPC_20261123_002_TASK_EN.md` found in the current drop is **NOT the active next Dragon House assignment**.

After RES_22/23/24 are accepted, the next project priority is the already requested small-life package:
- Shurshun;
- generic domestic cat candidates;
- house mice / microfauna.

## 11. RETURN FORMAT FOR THE 18-IMAGE GATE

Return exactly:

```text
ZNA_CHAR_NPC_20261123_001_IDENTITY_R2
machine_status: READY_FOR_INTEGRATOR_VISUAL_QA | BLOCKED
owner_approved: false
branch: art/znaechka-characters-ZNA_CHAR_NPC_20261123_001
head: <sha>
identity_gate_images: 18
RES_22_identity: READY_FOR_QA | BLOCKED
RES_23_identity: READY_FOR_QA | BLOCKED
RES_24_identity: READY_FOR_QA | BLOCKED
technical_canvas_pass: 18/18
rgba_pass: 18/18
transparent_alpha_pass: 18/18
local_only_paths: NONE
```

Do not generate the remaining full 423-frame R2 until integrator visual QA passes the gate.
