# Dragon House — Teea pilot batch 002 integration QA

**Batch:** TEEA_INT_20261122_002  
**Source commit:** eee270f5e47e60e4ad412a25c20cef664ae72527 on \`art/teea-interiors-TEEA_INT_20261122_002\`  
**QA branch:** \`qa/teea-int-20261122-002\`, isolated from the accepted runtime branch.  
**Status:** MACHINE INTAKE PASS / CAMERA QA PASS WITH REWORK / OWNER APPROVAL **NOT GRANTED**.

## Actual evidence inspected

- Read the exact candidate manifest, technical delivery JSON, authoring report, source provenance, archive pointer and the complete ZIP payload. The PNG binaries were NOT in Teea's GitHub commit; the private repository file \`..._BINARY_PAYLOAD.txt\` points to a separate archive.
- ZIP SHA256: \`dcc4d0471a127c441a636d612f8aa8d8fceaa33e3c0a555b5c2f7d1008eb622c\` — verified.
- All **12 actual PNG SHA256 values** match the ZIP's inventory and candidate manifest; all images decode; exact sizes common R3 4608x1024, library R2 3072x1024, study/rest R1 1536x1024. All four packs contain \`backdrop\`, \`back_decor\`, \`furniture_back\`, each respectively opaque and correctly alpha-masked.
- Per Teea's provenance, rendered in Blender from CC0 Poly Haven assets and ambientCG materials. Do not call these images AI-generated or native photorealistic photos: they are authored 3D-rendered plates, 50% native resolution + 2x Lanczos. Their artistic acceptability is **still awaiting the owner's decision**.
- Successfully ran **actual current Godot 4.7.2 scene camera** with all four pilot packs. To test library R2, the script **temporarily converts** the adjacent Music room into a second Library cell; this does not change the actual game or its save. The standard seeded Library is R1.
- Isolated script temporarily sets \`approved:true\` **in memory only**. Original JSON remains \`approved:false\`. No owner identity or room art was promoted.

## Confirmed visual problem and renderer remedy

**REWORK issue #1 — old backwall obscures the real backdrop.** In the original camera, old \`Stage_Backwall\` rectangles sit in FRONT of the room's \`backdrop\` Sprite3D and hide the majority of the new stone material. Confirmed by comparing original runtime screenshot with a screen capture after hiding those temporary panels. The remedy on this QA branch hides \`Layer_Background/Stage_Backwall\` only while an actual valid \`Art_backdrop\` node is loaded at ROOM zoom; on HOUSE overview or missing art it restores procedural background. This retains the floor shell, real cutaway Z depths, private facade and far-view proxies. Guarded with \`tests/test_backwall_z_v11.gd\`.

**REWORK issue #2 — oversized temporary structure framing.** Current upper ceiling and some front returns still visually dominate the image. They should be reviewed against the new cutaway camera and remain a separate structural adjustment; do not bake another fake ceiling into the art to compensate. Distinguish attractive deeper room art from the unfixed frame scale.

**REWORK issue #3 — actor/seat mismatch.** Teea's \`anchor_proposals\` are visual X/Y coordinates in the **whole rendered R1/R2/R3 group**, NOT engine-authored, collidable local (x,z) room-cell stations. Their \`local_y\` does not provide walkable depth Z. Do NOT directly import these proposals as \`data/furniture_interactions_v1.json\`; placement of actual sitting bodies could be badly wrong. Common proposal \`local_x=-5.25\` lies in the LEFT cell of common R3, whereas the old procedural sofa station \`SOFA_COMMON_MIDDLE\` is in its MIDDLE cell. Equating their IDs would move actors onto empty floor.

**REWORK issue #4 — only three roles.** No \`foreground\` / \`front_trim\` / \`light_overlay\` layers in this batch. That is not an automatic failure for a pilot, but objects intended to occlude seated bodies need separately composed alpha layers. The current \`furniture_back\` layer places furniture behind actors and cannot correctly hide lower limbs for front-seat perspectives.

**REWORK issue #5 — photoreal aesthetic.** The materials look significantly better than placeholder geometry, but the final scene still combines them with large procedural beams, temporary faceless resident sprites and differently shaded shell. This **cannot** be certified photorealistic on behalf of the owner. Record \`READY_FOR_REVIEW\`, not \`APPROVED\`.

## Safety and delivery

- All 12 binaries from verified original ZIP are staged on a **QA branch only**, using the repository's Git LFS rules. The integration workflow must verify correct LFS binaries; the original authoring branch remains unmodified.
- Owner-facing production branch \`dragon-house-fallout-fresh\` remains on **v0.10 without this unapproved batch**.
- QA proof images are produced in an isolated Godot scene using that camera, then uploaded privately as GitHub Actions artifacts rather than promoted to release art.
- Pipeline must not change canonical resident identities, toggle active residents, modify private rooms or update \`data/interior_layers_v1.json\` with new approvals.
- Future art revisions should supply group-level visual anchors plus explicit **cell-relative X, Z, object ID, seat count, approach location, and intended posture**; original room reference must be preserved and the user must approve any visible final art.

## Review disposition

\`INTEGRATION_GODOT_CAMERA: PASS AFTER RENDERER FIX\`  
\`PACKAGING_AND_HASHES: PASS\`  
\`PREVIEW_ONLY: TRUE\`  
\`OWNER_ART_APPROVAL: FALSE\`  
\`PRODUCTION_MERGE: BLOCKED\`  
\`AGENT_REWORK: NEEDED FOR SEAT ANCHORS / VISUAL FRONT LAYERS / BEAM SCALE\`

