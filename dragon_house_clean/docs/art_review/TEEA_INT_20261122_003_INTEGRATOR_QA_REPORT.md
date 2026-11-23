# TEEA_INT_20261122_003 — Integrator QA Report

**Project:** Dragon House / Living Dragon Cave  
**Integrator base:** v0.14 fresh, full CI #25 PASS  
**Integration branch:** `dev/dragon-house-v015-teea003-integration`  
**Artist source head:** `27a57e95b0185d263ade43c491cb9c450a56912a`  
**Integrator candidate head:** `f01a169ba06543c4248b6dbe29b827bceebbc5a5`  
**Owner approval:** false  
**Production promotion:** NONE

## Evidence boundary

This report evaluates the TEEA 003 delivery as an integrator candidate. The source proposal remains `approved:false`; the 20 PNG are mounted only in an ephemeral QA working tree.

## Binary intake

- exact ZIP SHA-256: `2233854a91684acec90ad687961cc1c3b1316f921643a5941e9ed6846778b093`
- production PNG: 20
- rooms: Arrival R1, Corridor R1, Music R1, Cinema R1, Artifact R1, Workshop R1
- source station count: 7
- source foreground layers: Music R1, Cinema R1 only

GitHub v0.15 workflow independently re-downloads and verifies the exact ZIP before every integrator run.

## Collision / approach QA

Result: PASS

- stations checked: 7
- collision-only furniture checked: 7
- aisle-to-station approach paths intersecting foreign furniture: 0
- Arrival stations: 0
- Corridor stations: 0

## Runtime semantic adapter

Source semantics are not rewritten. QA runtime maps:
- `LISTEN -> RELAXED_SIT`
- `WATCH -> RELAXED_SIT`
- `INSPECT -> VIEW`
- `kind=view -> standing`

Station x/z and approach coordinates are unchanged.

## Foreground registration

Dragon House requires a physical cut-plane depth for perspective re-registration.

QA uses the source furniture measured front edge:
- Music chair: `-0.1276819109916687`
- Cinema sofa: `-0.1038343608379364`

These are derived directly from TEEA 003 anchor measurements and remain an integrator QA hypothesis until owner acceptance.

Local current-camera test:
- Music yaw -0.18 / 0 / +0.18: registration stable
- Cinema yaw -0.18 / 0 / +0.18: registration stable

## Runtime integration regression

Local Godot 4.7.2 exact-payload result:

`TEEA003_INTEGRATION_V015_PASS layers=20 stations=7 foreground=2 duplicate_furniture=blocked`

Current-life regressions also pass with the candidate mounted:
- furniture contract
- room LOD
- cutaway depth
- width-aware furniture
- corridor passing
- concrete media
- room activity HUD

## Live visual review

GitHub workflow: #4 / `45126314587`

Required evidence:
- Arrival R1
- Corridor R1
- Music yaw -0.18 / 0 / +0.18
- Cinema yaw -0.18 / 0 / +0.18
- Artifact R1
- Workshop R1

Capture is configured with `qa_visual_preview=true` so Music/Cinema are reviewed against actual available QA resident banks rather than the oversized procedural fallback silhouette.

**Final visual verdict: PENDING CURRENT WORKFLOW ARTIFACT INSPECTION.**

## Promotion gate

TEEA 003 remains outside production until all are true:

1. exact-payload CI completes PASS;
2. integrator inspects the real-QA-sprite live-camera artifact;
3. no foreground/body ordering defect remains in Music/Cinema;
4. owner/Dragon visually accepts the six-room batch.

Only then:
- commit the 20 production PNG through Git LFS;
- add approved TEEA 003 layers to `interior_layers_v1.json`;
- add validated R1 station contracts to production furniture data;
- set approval metadata explicitly from the owner decision.

No Teea redraw or repack is currently requested.
