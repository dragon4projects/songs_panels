# ZNA_CHAR_NPC_20261123_003 — Integrator QA

Date: 2026-11-23  
Reviewer: Znaechka  
Status: **TECHNICAL PASS / OWNER ART APPROVAL STILL PENDING**

## Source reviewed

Exact uploaded package:

`ZNA_CHAR_NPC_20261123_003.zip`

SHA-256:

`1e549b2ae355a3735a948329ce63466bc90cea3df883a280fb17e457857a8331`

## Package totals

- 21 banks
- 237 states
- 479 PNG
- 2 resident-style NPCs:
  - `NPC_VAMPIRE_GIRL`
  - `NPC_CENTAUR`
- 15 creature-style banks:
  - magical AI sphere
  - 3 hedgehogs
  - 6 cats
  - 5 rats

## Machine QA

PASS:

- 479/479 project PNG found
- resident assets: 512×512 RGBA
- creature assets: 1024×640 RGBA
- non-empty alpha on every checked final PNG
- no canvas-touch/crop warnings
- no duplicate frame hashes inside multi-frame states
- zero-padded numbering valid
- resident coverage exact:
  - SHORT / HOME / CITY
  - 22 states per wardrobe
  - 47 frames per wardrobe
- creature coverage exact:
  - identity: 1
  - idle: 2
  - rest: 2
  - walk_left: 4
  - walk_right: 4
- SHA256 delta: 480 entries checked, 0 mismatches, 0 missing targets
- asset_index delta: 479 entries, 0 missing destinations

## Safety of repository merge

The integration workflow merged only:

- `NPC_VAMPIRE_GIRL`
- `NPC_CENTAUR`
- the 15 new creature slugs
- NPC003 provenance
- registry / coverage / index / SHA deltas
- preview and handoff documentation

`RES_01..RES_21` asset directories were not copied or rewritten.

Post-merge QA explicitly confirmed legacy registry keys `RES_01..RES_21` remain present.

## Visual sanity review

Reviewed all 21 preview sheets.

No blocking sheet-level defects observed:

- vampire girl remains consistent across the HOME bank preview;
- centaur remains readable in 512×512 and is not visibly cropped;
- magical AI sphere reads as an active hovering magical object rather than a dead prop;
- cat, rat, and hedgehog variants remain distinct and readable.

Important non-blocking follow-up:

- centaur furniture interaction, doorways and narrow-room traversal should be checked in-scene by the integrator;
- final artistic canon / permanent IDs remain owner decisions.

## GitHub delivery

Branch:

`art/znaechka-characters-ZNA_CHAR_NPC_20261123_001`

Asset integration commit:

`8bd076a8cdf3b8b06fccd5c6071876b3feb5e3f6`

Temporary integration workflow was removed after successful delivery.

The PNG/JPG assets are committed through Git LFS and representative LFS objects were verified on the branch.

## Runtime status

Do **not** infer owner approval from this QA.

Current intended state remains:

- technical bank: PASS
- runtime binding: pending integrator / owner decision
- owner art approval: pending
