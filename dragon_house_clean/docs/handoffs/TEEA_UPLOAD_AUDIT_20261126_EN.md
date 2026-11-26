# TEEA asset delivery audit — 2026-11-26
## Status: PUBLIC_PAYLOAD_VERIFIED / PRIVATE_PAYLOAD_PREPARED_NOT_COMMITTED

Public repository: dragon4projects/songs_panels, branch `assets/cgtrader-coffee-mugs-20261124`.
Binary intake commit: `b7abfd4e854f87554d69115c91f185eef2ec7d06`.
An independent remote download of every file in the intake manifest (including Git LFS media where the raw endpoint returned a pointer) matched byte count and SHA-256: **1119/1119 PASS**. This is remote byte verification, not live Godot integration. Actions run 45812084821 completed the commit/push step; the additional fresh-checkout step was still in progress at report preparation. The temporary workflow has been removed.

## Public payload
- 243 TEEA008 normalized model.gltf assets and relative dependencies, including 158/158 original Poly Haven source IDs, 10 PBR sets, 33 room proposal variants, 219 placement candidates, 32 legacy media IDs, 15 small-artifact candidates, 332 measured guest frames. Previous isolated Godot import 243/243 and layout geometry 33/33; no new runtime activation.
- Existing 11 models retained: six Sketchfab optimized coffee machines/fireplaces, two public decor models (industrial pipe lamp and sleeping dragon), three empty artifact glass cubes. Total public bank 254 model.gltf entries at binary intake commit.
- Six original Sketchfab GLB files (CC-BY / CC-BY-NC; preserve credit and noncommercial restriction).
- Three historical archives (TEEA006, TEEA007 final, TEEA007 guest alpha closure) stored outside runtime, not to be installed over current room geometry.
- Earlier TEEA001–005 are superseded proposal generations; not reintroduced or counted as new runtime assets.

Paths, relative to dragon_house_clean:
- assets/decor_bank/
- data/asset_proposals/TEEA_INT_20261124_008/
- docs/handoffs/TEEA_INT_20261124_008/HANDOFF_CONSOLIDATED_EN.md
- docs/handoffs/TEEA_INT_20261124_008/QA_REPORT_CONSOLIDATED_EN.md
- data/asset_proposals/TEEA_UPLOAD_AUDIT_20261126/manifest.json (1119 verified file records)
- assets_external/sketchfab/harvest_20261125/raw/
- assets_external/authoring/teea_historical/

## Private-only payload
Prepared 23 normalized models + one Blender authoring node group (21 models absent from public bank), and 97 original source records / 96 distinct files (77 old Blendkit downloads, 16 newer downloads, four owner-supplied files; one exact duplicate). 400 manifest records verified locally. The private repository branch contains the catalog and restoration script, **not the actual payload**. Three attempts (run 45812090566, run 45812837560 attempts 1–2) failed before runner assignment, with no steps/logs and no asset commit, including retries after owner settings change. No public redistribution of restricted source files. See the private handoff for exact recovery path. Original missing theatre .bin not reconstructed; Blender source was used for six modules. 26 prior CGTrader URLs were not downloaded; Vintage Wooden Bellows Camera was not free. Older raw Blendkit harvest is not an independently normalized or Godot-tested runtime library.

## Integrator instructions
1. Fetch the public asset branch (or cherry-pick the binary intake commit into a staging branch); use existing Git LFS rules. Verify manifest against hydrated files. Do not copy historical zip packages or original source cache into runtime.
2. Use consolidated proposal JSON as candidates only; preserve production topology, existing world/actor IDs, access rules, accepted assets and media identities. Do not auto-enable theft, new guest stations or replacement shells.
3. Integrate private normalized decor only into an authorized private/local checkout after restoration; never merge restricted source files into public main. Preserve all credits.
4. Review actual runtime visual depth, glass transparency, guest collisions and poses, media interactions, layout and performance on target hardware. No owner approval or full runtime QA asserted. Main branches untouched.
