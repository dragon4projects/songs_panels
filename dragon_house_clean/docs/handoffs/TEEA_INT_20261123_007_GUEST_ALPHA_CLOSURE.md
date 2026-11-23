# TEEA_INT_20261123_007 — GUEST ALPHA CLOSURE ADDENDUM

Date: 2026-11-23
Role: TEEA / interiors-only QA
Status: READY_FOR_INTEGRATOR_QA
Owner approved: false
Approved: false
Production mutated: no

## External blocker resolved

The final TEEA007 handoff was blocked only because exact canonical guest PNG bytes were behind Git LFS. TEEA did not substitute guessed silhouettes.

A TEEA007-only GitHub Actions QA workflow checked out the existing ZNA branch with LFS enabled and verified the three materialized files against their exact LFS SHA-256 values before uploading the QA artifact.

Successful run: 45207278966
Artifact: 14833608303
Workflow commit: aa38bffddf3299ea47f756d705d3e8e6c0186f17

Exact source SHAs:
- NPC_CENTAUR: 2abcd9620fb249b37079235745516224bc39b46be6c4abec35fd69cd22fea47f
- NPC_VAMPIRE_GIRL: 501284e9724441533d9cc34648c6956c564a1a097008f4e2b15bea6238f65fee
- NPC_GINGER_CAT_GUEST / Миу: 5f3eb9dc8efef0c14a96de47887a099e9dec90d9cb0f14cb65162b5e66e05804

## Actual alpha footprint under current runtime scale

Current resident scale: pixel_size = 1.9 / texture_height = 0.003710937 m/px.

Using alpha >= 1:
- Centaur: 0.378516 m × 1.232031 m visible billboard alpha.
- Vampire Girl: 0.371094 m × 1.276563 m.
- Miu: 0.523242 m × 1.276563 m.

All are comfortably inside the 2.10 m × 2.45 m guest-door visual clearance.

This does NOT shrink Centaur physical room requirements. Centaur keeps the separate 2.50 m turning envelope, whose room-geometry QA remains PASS.

## Actual-sprite camera proof

The exact canonical PNGs were rendered in the existing TEEA007 guest-room layers using the current production ROOM camera contract:
- Perspective Camera3D equivalent
- FOV 35°
- R1 zoom 10.8
- close-bias formula unchanged
- manual yaw -0.18 / 0 / +0.18
- fixed-Y sprite facing
- runtime full-texture plane 1.9 × 1.9 m with feet visually aligned from the exact alpha lower bound.

Result: 9/9 render proofs PASS.
Machine projected exact alpha corners remain fully inside frame: 9/9 PASS.
No unrelated furniture hides essential body regions in the reviewed contact sheet.
All guest sprites sit in front of baked furniture_back z=-1.37 at the selected QA positions.
Guest rooms use no separate foreground layer.

Miu low-pad placement is visual-clearance proof only. It does not invent a species/body interaction binding.

## Gate closure

PASS-A: PASS
PASS-B: PASS
PASS-C: PASS
PASS-D: PASS
PASS-E: PASS

Final TEEA007 machine status: READY_FOR_INTEGRATOR_QA.

This is not owner approval and does not authorize production promotion. Guest room IDs remain proposed until Integrator binds them; Dragon approval remains required.


## Evidence hygiene note

Probe run 45206934849 is NOT used as guest-alpha evidence. Its upload step flattened three identical source basenames and retained only the final Miu file. This was detected by artifact SHA inspection before any measurement. The corrected run 45207278966 renamed outputs to centaur.png / vampire.png / miu.png and verified all three exact LFS SHA-256 values before upload.
