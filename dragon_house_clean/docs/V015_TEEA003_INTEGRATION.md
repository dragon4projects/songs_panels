# Dragon House v0.15 — TEEA_INT_20261122_003 integrator QA

**Date:** 2026-11-23  
**Base:** `dragon-house-fallout-fresh` v0.14, full CI PASS (#25)  
**Integration branch:** `dev/dragon-house-v015-teea003-integration`  
**Artist source head:** `27a57e95b0185d263ade43c491cb9c450a56912a`  
**Owner approval:** **false**

## Boundary

This branch does **not** promote TEEA 003 into the production interior manifest.

The artist candidate remains `approved:false`. The 20 PNG payload is mounted only inside an integrator sandbox / CI dirty working tree so the existing renderer can exercise the exact current HOUSE/ROOM camera, LOD, station logic and foreground registration.

## Verified handoff

Payload:
- 6 room variants: Arrival R1, Corridor R1, Music R1, Cinema R1, Artifact R1, Workshop R1;
- 20 production PNG;
- 7 stations;
- foreground only for Music and Cinema;
- declared ZIP SHA-256:
  `2233854a91684acec90ad687961cc1c3b1316f921643a5941e9ed6846778b093`.

Independent binary intake already verified the ZIP checksum and all 20 per-file delivery hashes.

## Runtime semantic mapping

Artist semantics are preserved in source and mapped only at runtime QA:

- `LISTEN` -> `RELAXED_SIT`
- `WATCH` -> `RELAXED_SIT`
- `INSPECT` -> `VIEW`
- station kind `view` -> runtime `standing`

This mapping does not move any measured station.

## Foreground physical depth hypothesis

The artist foreground files are camera-facing fragments cut from the same authored furniture, but the source manifest does not explicitly store the runtime `physical_z` used by Dragon House's perspective re-registration.

For integration QA the cut plane is anchored to the measured **front physical edge** of the source furniture:

- Music / `music_listen_chair`: `physical_z = -0.1276819109916687`
- Cinema / `cinema_sofa`: `physical_z = -0.1038343608379364`

Basis: `TEEA_INT_20261122_003_anchor_measurements.json` `godot_z_front`.

Status: **INTEGRATOR_QA_HYPOTHESIS**, not owner-approved canon.

## Local live-camera result

Using the current v0.14 renderer and Godot 4.7.2:

- all 20 PNG imported without parse/script errors;
- all 6 room variants mounted into the current shell;
- Arrival/Corridor stay station-free;
- 7/7 aisle-to-station approach lines avoid every foreign collision footprint;
- Music foreground remained registered to the chair at yaw `-0.18 / 0 / +0.18`;
- Cinema foreground remained registered to the sofa at yaw `-0.18 / 0 / +0.18`;
- Artifact and Workshop required no foreground and showed no procedural-furniture double render;
- candidate backdrops suppress the procedural rear-stage only while candidate art is mounted.

### Important visual seam

The current fallback resident silhouette is wider than the measured Cinema seat spacing (0.6792 m), so two fallback bodies overlap visually at the centre view. This is **not** treated as evidence that the artist seat coordinates are wrong: 0.6792 m is the authored measured seat width. Final seating acceptance must be repeated with a real production/QA resident sprite bank.

## Reproducible CI contract

The branch contains:

- `data/asset_proposals/TEEA_INT_20261122_003_integration_overrides.json`
- `tools/prepare_teea003_qa.py`
- `tools/qa_teea003_geometry.py`
- `tests/test_teea003_integration_v015.gd`
- `tests/capture_teea003_v015.gd`

CI downloads the exact artist ZIP, verifies its SHA, mounts it ephemerally, runs geometry/runtime regressions, renders ten live-camera review frames and uploads them as a private workflow artifact.

## Promotion gate

Do **not** set any TEEA 003 layer to `approved:true` until:

1. the branch CI passes against the exact payload;
2. the ten live-camera frames are retained as evidence;
3. Music/Cinema foreground is checked with a real resident sprite rather than only the fallback silhouette;
4. Dragon gives visual approval for the 003 rooms.

Only after that gate should the 20 PNG be committed to production Git LFS and the approved manifest/station contract be updated.
