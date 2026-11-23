# NPC and creature sprite-bank QA — 2026-11-23

**Current status: PARTIAL PASS. Production and local binary verification complete. GitHub push and fresh remote checkout pending.**

## Continuation from the exact GitHub branch

- Branch: `art/znaechka-characters-ZNA_CHAR_NPC_20261123_001`.
- Starting checkout: `994eb3f66436b2985cb94b1fc98b82274d8141c6`. The operator's authenticated GitHub clone completed LFS filtering for 4,218 files. A copied working checkout ran a scoped `git lfs pull` for creatures and residents with exit 0. Existing PNGs were decoded and hashed before art generation.
- The tracked Git tree, registry, index, checksums, and creature folder inventory confirmed zero mouse banks before production. The tree has two Shurshun poster paths and no creature identity image. Recovered `docs/art_review/ZNA_CHAR_NPC_20261123_002_SMALL_LIFE_TASK_EN.md` specifies black-cat identity details and records a queued mouse behavior-art proposal. Neither that document nor the poster designates an approved Shurshun creature identity master.
- `NPC_GINGER_CAT_GUEST` remains the sole Miu bank. The centaur, vampire girl, Miu, AI sphere, three hedgehogs, six cats, five rats, and Manjka passed the binary audit and were reused.
- The active ZNA004 instruction takes the current seven-state 1024×640 creature bank grammar from the accepted branch manifests. The queued ZNA002 behavior-art proposal has no registered mouse bank or active run/flee/sniff contract in this checkout. The art delivery uses the registered seven-state grammar and leaves runtime binding disabled.

## Production

| New bank | States | PNGs |
| --- | --- | ---: |
| `npc_mouse_gray` | FRONT 1, IDLE_LEFT 1, IDLE_RIGHT 1, SIT 1, REST 1, WALK_LEFT 4, WALK_RIGHT 4 | 13 |
| `npc_mouse_brown` | FRONT 1, IDLE_LEFT 1, IDLE_RIGHT 1, SIT 1, REST 1, WALK_LEFT 4, WALK_RIGHT 4 | 13 |
| `npc_mouse_pale` | FRONT 1, IDLE_LEFT 1, IDLE_RIGHT 1, SIT 1, REST 1, WALK_LEFT 4, WALK_RIGHT 4 | 13 |
| Shurshun | BLOCKED_MASTER_REQUIRED | 0 |

Three separately generated visual variants share a realistic house-mouse pose plan. Right-facing sprites mirror the matching left-facing originals. Frames are aligned by the dense body silhouette and a common alpha floor. The pale sheet had translucent background spill corrected during alpha preparation. Ownership is unknown for each mouse. Existing states required no repair. Visual art approval is pending.

Canonical updates are limited to the creature entries in `data/asset_registry_nov2026.json`, `assets/manifests/bank_coverage.json`, the 39 appended asset index and checksum records, and `assets/manifests/npc_20261123_004_mouse_provenance.json`. Per-frame source references, cut cells, mirror flags, and alpha bounds are in provenance.

## Binary QA and no-touch verification

| Check | Evidence |
| --- | --- |
| Existing bank audit | 966 decoded PNGs across 22 banks, including three protected residents. SHA-256 matches tracked checksums for all 966. |
| New banks | 39 decoded PNGs, all 1024×640 RGBA. Every image has transparent canvas and a visible opaque or near-opaque subject. |
| Naming, state coverage and duplicates | Seven states per mouse, consecutive four-digit numbering, 39 distinct SHA-256 values. |
| Canvas and motion placement | Nonempty alpha strictly inside each canvas. Common floor at exclusive y=598. Walk-cycle height/width ratios under 1.25 and consecutive left alpha-bound changes (including wrap) below 70 px. Contact-sheet review found intact silhouettes and visibly distinct coats. |
| Protected residents | All three identities and 423 wardrobe images matched pre-work SHA-256 byte-for-byte after integration. The digest table below remains valid. No asset redraw or existing asset edits. |
| Git scope | Asset commit touches only the 39 mouse PNGs and five creature-related metadata files. This handoff update is the second commit. |
| LFS pointer integrity | All 39 staged pointers exactly match image SHA-256 and byte length. Each corresponding local LFS object is byte-identical to its checked-out image. |
| Fresh local checkout | A non-hardlinked Git clone at asset commit `436a16632c9cbeb71945dc6810384b91f8435143` started with smudge disabled, then fetched the resident/creature LFS objects from the local origin. The complete machine audit was byte-identical to the post-work audit. |
| Remote GitHub push and fresh remote checkout | Pending at report creation. The sandbox cannot resolve github.com. Use the authenticated native Git connection to publish and verify the enclosing report commit. |

## Historical manifest-only audit

The evidence below records the first pass, before the authenticated operator checkout made the LFS payloads available. Its initial blockers and Git status are historical.

**Overall: BLOCKED. Manifest audit completed. Binary checkout and asset delivery are pending.**

## Source state

- Repository `dragon4projects/songs_panels`, branch `art/znaechka-characters-ZNA_CHAR_NPC_20261123_001`.
- Starting asset HEAD: `957695e040c457c15ed5db4f3416143e57f9188f`, resolved directly from GitHub before the audit. All manifest reads were pinned to this SHA.
- HTTPS and SSH Git requests could not resolve `github.com` in the local environment. Git LFS 3.8.0 is installed. `git lfs pull` was blocked at the checkout prerequisite. The GitHub file API returned LFS pointer records for sampled PNGs. `dragon_house_clean/.gitattributes` tracks PNGs with LFS.
- Inputs: `assets/manifests/bank_coverage.json`, `data/asset_registry_nov2026.json`, `assets/manifests/asset_index.jsonl`, and `assets/manifests/SHA256SUMS.txt`, relative to `dragon_house_clean/`. The audit compared declared paths, sequence indices, hashes, dimensions, mode, and alpha flags. All statuses marked COMPLETE below refer to manifest coverage. Image decode, alpha bounds, crop, and animation review require the binary objects.
- The related Library packages `Dragon_House_RES22_24_integrator_drop.zip` and `ZNA_CHAR_NPC_20261123_003_CREATURE_MEDIA_TRANSFER.zip` were located. DNS blocked payload download from this environment. The old local checkout at `3a6b3b2` was used only to identify available historical sources.

## Coverage before work

### Resident-style NPCs

Each listed wardrobe has these 22 states. `IDLE_N`, `IDLE_NE`, `IDLE_E`, `IDLE_SE`, `IDLE_S`, `IDLE_SW`, `IDLE_W`, `IDLE_NW`, `SIT`, `TALK`, `VIEW`, `READ`, `CARRY_USE`, `RELAXED_SIT`, `SLEEP`, `LIE_SIDE_STRAIGHT`, `LIE_SIDE_CURLED`, `SIT_HUG_KNEES`, and `SIT_LEGS_TUCKED` have one frame apiece. `WALK_LEFT` and `WALK_RIGHT` have 12 frames apiece. `DRINK` has four. Identities and wardrobe frames are indexed as 512×512 RGBA with nonempty alpha. Required states absent from listed wardrobes: zero. Within-state duplicate hashes: zero. The registry has one entry for Миу, `NPC_GINGER_CAT_GUEST`, with the `SHORT` wardrobe.

| Entity | Identity | Identity bytes | Wardrobes, frames and frame size range | Manifest status |
| --- | --- | ---: | --- | --- |
| `NPC_CENTAUR` | `assets/residents/NPC_CENTAUR/identity/front_0001.png` | 61233 | SHORT 47 (57927–117209 B), HOME 47 (61886–105245 B), CITY 47 (60387–112413 B) | COMPLETE |
| `NPC_VAMPIRE_GIRL` | `assets/residents/NPC_VAMPIRE_GIRL/identity/front_0001.png` | 55080 | SHORT 47 (35315–61097 B), HOME 47 (36586–61243 B), CITY 47 (31732–69619 B) | COMPLETE |
| `NPC_GINGER_CAT_GUEST` | `assets/residents/NPC_GINGER_CAT_GUEST/identity/front_0001.png` | 69827 | SHORT 47 (38374–78570 B) | COMPLETE |

### Small creatures

Each row has this state profile: `FRONT=1`, `IDLE_LEFT=1`, `IDLE_RIGHT=1`, `SIT=1`, `REST=1`, `WALK_LEFT=4`, `WALK_RIGHT=4`. The paths use `identity/`, `idle/`, `rest/`, `walk_left/`, and `walk_right/` with four-digit numbering. All 208 indexed frames record 1024×640 RGBA and nonempty alpha. Required states absent: zero. Within-state duplicate hashes: zero. The tracked manifests do not prescribe additional small-creature states for these banks.

| Entity | Identity | Identity bytes | Frame size range (bytes) | Manifest status |
| --- | --- | ---: | ---: | --- |
| `manjka` | `assets/creatures/manjka/identity/front_0001.png` | 304850 | 296274–395497 | COMPLETE |
| `npc_ai_magic_sphere` | `assets/creatures/npc_ai_magic_sphere/identity/front_0001.png` | 233786 | 220889–277842 | COMPLETE |
| `npc_hedgehog_01` | `assets/creatures/npc_hedgehog_01/identity/front_0001.png` | 190297 | 156004–274047 | COMPLETE |
| `npc_hedgehog_02` | `assets/creatures/npc_hedgehog_02/identity/front_0001.png` | 189327 | 150964–258157 | COMPLETE |
| `npc_hedgehog_03` | `assets/creatures/npc_hedgehog_03/identity/front_0001.png` | 181745 | 140218–224462 | COMPLETE |
| `npc_cat_black_hero` | `assets/creatures/npc_cat_black_hero/identity/front_0001.png` | 151024 | 143245–306340 | COMPLETE |
| `npc_cat_tabby` | `assets/creatures/npc_cat_tabby/identity/front_0001.png` | 175132 | 175132–382201 | COMPLETE |
| `npc_cat_white` | `assets/creatures/npc_cat_white/identity/front_0001.png` | 145389 | 145389–311238 | COMPLETE |
| `npc_cat_ginger` | `assets/creatures/npc_cat_ginger/identity/front_0001.png` | 175198 | 175198–391646 | COMPLETE |
| `npc_rat_hero` | `assets/creatures/npc_rat_hero/identity/front_0001.png` | 139807 | 139807–250852 | COMPLETE |
| `npc_rat_agouti` | `assets/creatures/npc_rat_agouti/identity/front_0001.png` | 153118 | 153118–263449 | COMPLETE |
| `npc_rat_white` | `assets/creatures/npc_rat_white/identity/front_0001.png` | 138627 | 138627–233225 | COMPLETE |
| `npc_rat_hooded` | `assets/creatures/npc_rat_hooded/identity/front_0001.png` | 145884 | 143353–247256 | COMPLETE |
| `npc_cat_calico` | `assets/creatures/npc_cat_calico/identity/front_0001.png` | 176997 | 176997–378532 | COMPLETE |
| `npc_cat_sphynx` | `assets/creatures/npc_cat_sphynx/identity/front_0001.png` | 107401 | 107401–251927 | COMPLETE |
| `npc_rat_juvenile_gray` | `assets/creatures/npc_rat_juvenile_gray/identity/front_0001.png` | 124767 | 124767–222588 | COMPLETE |

- Mouse banks: `MISSING` in the registry, coverage manifest, asset index and checksum inventory. The expected `npc_mouse_gray`, `npc_mouse_brown`, and `npc_mouse_pale` each have 0 of 13 indexed frames. Earlier mouse assets under an unindexed path remain unverified because repository-tree checkout failed.
- Shurshun: `BLOCKED_MASTER_REQUIRED` on available evidence. No indexed creature frames. The scope of the master search and inaccessible sources is recorded below.
- `dragon` is recorded as an owner-approved technical proxy with final creature body absent. It is outside this sprite-bank production assignment.

### Resident inventory outside production scope

Identity filenames below are relative to `assets/residents/<ID>/identity/`. A zero indicates that all 22 baseline states in that wardrobe are missing. Positive baseline counts apply the same state vector described above. RES_07 has a distinct source bank grammar. Status is based on declared wardrobes and state coverage.

| Entity | Identity filename(s) | Wardrobe frame counts | Manifest status | State profile |
| --- | --- | --- | --- | --- |
| RES_01 | `helga_01.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_02 | `valenta_01.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_03 | `valenta_07.png` | SHORT 0, CITY 47, HOME 47 | PARTIAL | Baseline on each populated wardrobe |
| RES_04 | `lisa_02.png` | SHORT 0, CITY 0, HOME 47 | PARTIAL | Baseline on each populated wardrobe |
| RES_05 | `helga_08.png` | SHORT 47, CITY 47, HOME 0 | PARTIAL | Baseline on each populated wardrobe |
| RES_06 | `helga_02.png` | SHORT 0, CITY 47, HOME 47 | PARTIAL | Baseline on each populated wardrobe |
| RES_07 | — | SHORT 63, CITY 0, HOME 45, EXTRA/EVM_GREY_SHORTS_01 57, EXTRA/EVM_WHITE_SKIRT_01 57, EXTRA/EVM_DENIM_SKIRT_01 57 | PARTIAL | See exact exceptions below |
| RES_08 | `helga_07.png` | SHORT 0, CITY 47, HOME 0 | PARTIAL | Baseline on each populated wardrobe |
| RES_09 | `helga_03.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_10 | `helga_04.png` | SHORT 47, CITY 0, HOME 47 | PARTIAL | Baseline on each populated wardrobe |
| RES_11 | `valenta_02.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_12 | `helga_06.png` | SHORT 47, CITY 0, HOME 0 | PARTIAL | Baseline on each populated wardrobe |
| RES_13 | `helga_05.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_14 | `valenta_08.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_15 | `valenta_04.png` | SHORT 0, CITY 47, HOME 47 | PARTIAL | Baseline on each populated wardrobe |
| RES_16 | `lisa_07.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_17 | `lisa_04.png` | SHORT 47, CITY 0, HOME 47 | PARTIAL | Baseline on each populated wardrobe |
| RES_18 | `valenta_06.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_19 | `lisa_05.png` | SHORT 0, CITY 0, HOME 47 | PARTIAL | Baseline on each populated wardrobe |
| RES_20 | `lisa_08.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_21 | `valenta_05.png` | SHORT 47, CITY 0, HOME 0 | PARTIAL | Baseline on each populated wardrobe |
| RES_22 | `lisa_03.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_23 | `valenta_03.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |
| RES_24 | `lisa_01.png` | SHORT 47, CITY 47, HOME 47 | COMPLETE | Baseline on each populated wardrobe |

- `SHORT` — IDLE_N=1, IDLE_NE=1, IDLE_E=1, IDLE_SE=1, IDLE_S=1, IDLE_SW=1, IDLE_W=1, IDLE_NW=1, WALK_LEFT=12, WALK_RIGHT=12, SIT=1, RELAXED_SIT=1, TALK=1, VIEW=1, READ=1, DRINK=4, CARRY_USE=1, LIE_SIDE_STRAIGHT=1, LIE_SIDE_CURLED=1, SLEEP=1, SIT_HUG_KNEES=1, SIT_LEGS_TUCKED=1, DANCE=12, USE=1, CASUAL=1, LIE=1, RIDE=1
- `CITY` — IDLE_N=0, IDLE_NE=0, IDLE_E=0, IDLE_SE=0, IDLE_S=0, IDLE_SW=0, IDLE_W=0, IDLE_NW=0, WALK_LEFT=0, WALK_RIGHT=0, SIT=0, RELAXED_SIT=0, TALK=0, VIEW=0, READ=0, DRINK=0, CARRY_USE=0, LIE_SIDE_STRAIGHT=0, LIE_SIDE_CURLED=0, SLEEP=0, SIT_HUG_KNEES=0, SIT_LEGS_TUCKED=0
- `HOME` — IDLE_N=1, IDLE_NE=1, IDLE_E=1, IDLE_SE=1, IDLE_S=1, IDLE_SW=1, IDLE_W=1, IDLE_NW=1, WALK_LEFT=12, WALK_RIGHT=12, SIT=1, RELAXED_SIT=1, TALK=1, VIEW=1, READ=0, DRINK=0, CARRY_USE=0, LIE_SIDE_STRAIGHT=1, LIE_SIDE_CURLED=1, SLEEP=1, SIT_HUG_KNEES=1, SIT_LEGS_TUCKED=1, USE=1, CASUAL=1, RIDE=2
- `EXTRA/EVM_GREY_SHORTS_01` — IDLE_N=1, IDLE_NE=1, IDLE_E=1, IDLE_SE=1, IDLE_S=1, IDLE_SW=1, IDLE_W=1, IDLE_NW=1, WALK_LEFT=12, WALK_RIGHT=12, SIT=1, RELAXED_SIT=1, TALK=1, VIEW=1, READ=0, DRINK=0, CARRY_USE=0, LIE_SIDE_STRAIGHT=1, LIE_SIDE_CURLED=1, SLEEP=1, SIT_HUG_KNEES=1, SIT_LEGS_TUCKED=1, DANCE=12, USE=1, CASUAL=1, LIE=1, RIDE=1
- `EXTRA/EVM_WHITE_SKIRT_01` — IDLE_N=1, IDLE_NE=1, IDLE_E=1, IDLE_SE=1, IDLE_S=1, IDLE_SW=1, IDLE_W=1, IDLE_NW=1, WALK_LEFT=12, WALK_RIGHT=12, SIT=1, RELAXED_SIT=1, TALK=1, VIEW=1, READ=0, DRINK=0, CARRY_USE=0, LIE_SIDE_STRAIGHT=1, LIE_SIDE_CURLED=1, SLEEP=1, SIT_HUG_KNEES=1, SIT_LEGS_TUCKED=1, DANCE=12, USE=1, CASUAL=1, LIE=1, RIDE=1
- `EXTRA/EVM_DENIM_SKIRT_01` — IDLE_N=1, IDLE_NE=1, IDLE_E=1, IDLE_SE=1, IDLE_S=1, IDLE_SW=1, IDLE_W=1, IDLE_NW=1, WALK_LEFT=12, WALK_RIGHT=12, SIT=1, RELAXED_SIT=1, TALK=1, VIEW=1, READ=0, DRINK=0, CARRY_USE=0, LIE_SIDE_STRAIGHT=1, LIE_SIDE_CURLED=1, SLEEP=1, SIT_HUG_KNEES=1, SIT_LEGS_TUCKED=1, DANCE=12, USE=1, CASUAL=1, RIDE=1, LIE=1

## Shurshun source search

1. At the pinned GitHub commit, inspected the coverage and registry, and searched the asset index and checksums for `Shurshun` / `Шуршун`. The only image paths identified are `assets/props/artifacts/posters/poster_shurshun.png` and `assets/props/artifacts/posters/masters/poster_shurshun.png`. The index classifies them as a poster preview and a poster master. Direct identity-path lookups for `shurshun`, `npc_shurshun`, and `npc_cat_shurshun` returned 404. The generic black-cat bank has no Shurshun provenance.
2. Searched the project source paths under the Dragon's Home documentation, DragonHouse handoff and older checkout, and local Dragon House downloads. The available archive member-name checks covered `DragonHouse_v015_TEEA003_macOS15_M1.zip`, `DragonHouse_v015_TEEA003_macOS15_M1 (1).zip`, `dragon-house-teea003-integrator-qa-run6.zip`, `dragon_house_nav_camera_v0_2_unverified.zip`, `DRAGON_HOUSE_ARCHITECTURE_HANDOFF_00-18_PLUS_PRIVACY_V0_5_2026-09-30.zip`, `dragon_house_nav_camera_v0_3_unverified.zip`, `dragon_house_godot_smoke_v0_1.zip`, `dragon_house_nav_camera_v0_4_unverified.zip`, `DRAGON_HOUSE_LOCAL_AGENTS_INTERACTION_RIG_PACKAGE_2026-10-02.zip`, `dragon cave.zip`, `DRAGON_HOUSE_NEW_ARCHITECT_COMPLETE_HANDOFF_2026-10-02.zip`, `Dragon's Home (1).zip`, `Dragon's Home.zip`, `dragon_house_privacy_v0_5_nika_independent_mac_QA.zip`. No member name identified an approved Shurshun creature master. An archive member-name check cannot rule out a generically named source or one embedded in a packaged application.
3. Reviewed the project documents `Shursha backup dragon cave.md` and `ARTIFACT_MASTER_MIGRATION_PLAN.md`. The former identifies Shurshun as a small black cat and documents his collar. The latter classifies `ARTEFACT_017_POSTER_SHURSHUN_BOOKS_CAT.png` as poster artwork. Neither document designates a production creature identity image. The two current Library transfer ZIPs located above were unavailable as bytes.

## Work and protected-file checks

- No asset, ownership record or manifest was modified. No redraw, generation, or state repair occurred. The required pre-generation LFS gate could not run. The repository change for this handoff is this report.
- The three listed identity SHA-256 values were read from the actual Git LFS pointers. They match the asset index and `SHA256SUMS.txt`. All 423 wardrobe paths match between the index and checksum list. Wardrobe set digests cover sorted `SHA256␠␠repo-relative-asset-path\n` records, where the paths are relative to `dragon_house_clean/`. The digest is of the manifest records.

| Resident | Identity path | Identity SHA-256, before and after the docs-only change | Wardrobe frames | Wardrobe manifest-set digest |
| --- | --- | --- | ---: | --- |
| RES_22 | `assets/residents/RES_22/identity/lisa_03.png` | `7d6885f93a9012b6a41bbf9ca662bcbc96cbdb45e5e7754099712fe889e41b83` | 141 | `a923c50cb19b3ea269b835d1e4c1b9e8fbf29d535e951d74f30e8332a1b1a258` |
| RES_23 | `assets/residents/RES_23/identity/valenta_03.png` | `da7499cb212f557d8fc0d4cc30eca96eb50d0fda4308989c959cf3bb6992d808` | 141 | `b6bd5adbf8fa5f891641f0d9aa06d5efaec99f0f6b786f9e4566dd5d63671c8b` |
| RES_24 | `assets/residents/RES_24/identity/lisa_01.png` | `4f73de27440cfc407e8aecf95da944d3b62504ac80ce07c8414dc2e28af0cc23` | 141 | `bb40172b215e84977dfd5817cc096c077bcddc28b7c6f5ed9806f0357d0e636b` |

## Machine checks and Git evidence

| Check | Result |
| --- | --- |
| Manifest coverage and state numbering | PASS for the 3 resident-style NPCs and 16 small-creature banks listed above |
| Duplicate frames within a state | Zero duplicate hashes in the listed NPC and small-creature banks |
| Canvas, RGBA and nonempty alpha | Consistent in asset-index metadata for the listed NPC and small-creature banks |
| PNG decode, pixel alpha, crop, origin and movement | BLOCKED by missing LFS payload access |
| New PNGs | 0 |
| Scope guard | One report path in the handoff commit. No binary assets, runtime, interiors, media, or artifact files changed |
| Asset HEAD | `957695e040c457c15ed5db4f3416143e57f9188f` |
| Final Git reference | The enclosing documentation commit on `art/znaechka-characters-ZNA_CHAR_NPC_20261123_001` |
| LFS push | No new LFS objects |
| Fresh clone and LFS pull | BLOCKED by local DNS failure |

## Remaining blockers

An authenticated Git and LFS checkout is required to run the byte-level audit and establish exact tree coverage before mouse generation. The approved Shurshun creature identity master was not identified in the inspected sources. Existing RGB identity references for RES_22–24 are preserved as supplied.
