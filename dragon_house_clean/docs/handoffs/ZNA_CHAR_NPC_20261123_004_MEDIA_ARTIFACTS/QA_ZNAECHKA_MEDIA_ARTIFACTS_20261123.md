# ZNA_CHAR_NPC_20261123_004 — Media / Artifact Source Integration QA

Status: **TECHNICAL PASS / owner_approved=false**

## Git

- repository: `dragon4projects/songs_panels`
- branch: `art/znaechka-characters-ZNA_CHAR_NPC_20261123_001`
- asset integration commit: `3cef9bec0441724d71b738e949bdd3c10b76b8b6`
- verification workflow commit: `1fdbc5ca460b58165c53e4c92e3c1ca4fa9e0382`
- verification workflow run: `45198277472`
- verification conclusion: **success**

## Part B — YouTube previews

Source:
- `Понравившиеся - YouTube.pdf`
- Library file id: `file_00000000b80c821087056a640cf64627`
- source SHA-256: `038efbd6e84c653ba67bc61569e05932eba9eebfa7883ea46cc59114da724cbf`
- pages: 88
- playlist visible count recorded in source: 932

Physically extracted from the PDF:
- real source-derived preview cards: **698**
- audio: **203**
- film: **0**
- unclassified: **495**
- source gap: **234** playlist positions not physically present/extractable in the supplied PDF

Repository result:
- old text-only YouTube placeholder PNGs for these entries were removed
- real PDF-derived previews are committed as WebP
- preview paths are registered in `media_preview_manifest_zna003.json` and `media_preview_index.json`
- source page/card provenance is retained
- no remote cover/poster/thumbnail artwork was fetched

## Part C — artifact masters

Canonical register:
- `/Артефакты/ДОМ_ДРАКОНА_АРТЕФАКТЫ_MASTER.md`

Recovered Library archive:
- `assets confirmed.zip`
- Library file id: `file_00000000039882109c1af818a29ded41`

Recovered and verified source/master evidence: **10**

1. `ARTEFACT_002_CUBE_DISCARDED_EQUIPMENT`
2. `ARTEFACT_003_CUBE_ICONOCHKA_DUST`
3. `ARTEFACT_004_CUBE_RED_STONE_RING`
4. `ARTEFACT_006_CUBE_LETTERS_BEFORE_SLEEP`
5. `ARTEFACT_008_CUBE_HITRUSHKA_GENERATOR_BREAKER`
6. `ARTEFACT_009_CUBE_FREE_SISTER_CHAIR`
7. `ARTEFACT_010_CUBE_SILVER_DRAGON`
8. `ARTEFACT_011_CUBE_STOLEN_ADAPTER_KUNICA`
9. `ARTEFACT_013_CUBE_MORA_ORIGINAL_THREE_GRAPHITE_SWEATERS`
10. `ARTEFACT_015_CUBE_BLACK_LACE`

Repository source evidence:
`dragon_house_clean/assets/props/artifacts/cubes/sources/library_confirmed/`

Generated normalized previews:
`dragon_house_clean/assets/media/previews/artifacts/`

Machine manifest:
`dragon_house_clean/assets/manifests/artifact_master_sources_zna004.json`

Important continuity rule:
- these recovered legacy images are preserved as **source/master evidence**
- where the existing migration plan says `MIGRATION_REQUIRED`, this task did not silently promote them to final LOCK
- no artifact was redesigned in this pass

Still not found in `assets confirmed.zip` or as separately indexed Library files during this pass:
- `ARTEFACT_001_CUBE_EVMOCHKA_BOW`
- `ARTEFACT_005_CUBE_VERA_I_SHORT_PENCIL`
- `ARTEFACT_019_CUBE_SHELEST_LINGERIE`

A larger Library archive `assets.7z` also exists, but this execution environment does not contain a 7z decoder; it was therefore not falsely reported as searched internally.

## Machine QA

Integration run:
- payload SHA-256 verified
- 203 audio WebP previews decoded
- 495 unclassified WebP previews decoded
- 10 artifact source images decoded
- 10 artifact previews decoded
- artifact source SHA-256 checks passed
- artifact preview SHA-256 checks passed
- media manifest counts passed
- old YouTube placeholder PNG absence check passed

Independent verification run:
- targeted Git LFS pull for the newly delivered preview/artifact paths: PASS
- all 698 source-derived YouTube previews were real binary images, not LFS pointer text
- all 10 artifact source images were real binary images
- all 10 artifact previews were real binary images
- source and preview hashes matched the manifest
- run conclusion: **success**

## Scope

This pass did not touch:
- NPC generation
- engine/runtime logic
- interiors
- RES_22 / RES_23 / RES_24 identity or frame banks
- owner approval state

`owner_approved` remains false.
