# ZNA_CHAR_NPC_20261123_003 — Independent QA Handoff

Date: 2026-11-23
Reviewer: Znaechka
Target branch: `art/znaechka-characters-ZNA_CHAR_NPC_20261123_001`
Integrated asset commit observed: `8bd076a8cdf3b8b06fccd5c6071876b3feb5e3f6`

## Verdict

**TECHNICAL PASS / INTEGRATOR READY**

Owner art approval and final permanent IDs remain separate gates.

## Package validated before GitHub ingest

Source ZIP:
- `ZNA_CHAR_NPC_20261123_003.zip`
- SHA-256: `1e549b2ae355a3735a948329ce63466bc90cea3df883a280fb17e457857a8331`

Validated totals:
- 21 banks
- 237 states
- 479 PNG

Resident banks:
- `NPC_VAMPIRE_GIRL`: SHORT / HOME / CITY, 22 states each, 47 frames per wardrobe
- `NPC_CENTAUR`: SHORT / HOME / CITY, 22 states each, 47 frames per wardrobe

Creature banks:
- `npc_ai_magic_sphere`
- `npc_hedgehog_01`
- `npc_hedgehog_02`
- `npc_hedgehog_03`
- `npc_cat_black_hero`
- `npc_cat_calico`
- `npc_cat_ginger`
- `npc_cat_sphynx`
- `npc_cat_tabby`
- `npc_cat_white`
- `npc_rat_agouti`
- `npc_rat_hero`
- `npc_rat_hooded`
- `npc_rat_juvenile_gray`
- `npc_rat_white`

## Technical checks

PASS:
- exact resident state coverage
- exact resident frame counts
- creature bank minimum coverage
- zero-padded numbering
- resident final frames: 512x512
- creature final frames: 1024x640
- RGBA final PNGs
- non-empty alpha masks
- transparent border retained
- no exact duplicate frames inside any multiframe state
- preview sheet exists for all 21 banks

Expected duplicate pairs only:
- vampire identity/front is identical to SHORT/IDLE_S/0001
- centaur identity/front is identical to SHORT/IDLE_S/0001

These are not animation-state duplicates and are acceptable.

## Visual sanity review

Reviewed all 21 preview sheets.

PASS for integrator staging:
- centaur fits resident canvas and remains readable
- vampire girl identity/wardrobes remain coherent at preview level
- AI sphere reads as active/magical and movement variants are readable
- cats, rats, hedgehogs retain clear species silhouettes
- no obvious crop/blank/background failure detected in preview sheets

## GitHub verification

Full recursive tree check on commit `8bd076a8cdf3b8b06fccd5c6071876b3feb5e3f6` confirmed:
- exactly 479 task PNG paths present
- both resident NPC directories present
- all 15 creature directories present
- `npc_20261123_003_provenance.json` present
- `asset_index.jsonl` present
- `bank_coverage.json` present
- `SHA256SUMS.txt` present
- `asset_registry_nov2026.json` present

## Integration note

Use the GitHub branch as source of truth. Do not use any old Znaechka `/mnt/data` path.

Production/runtime binding flags should remain subject to integrator/owner approval.
