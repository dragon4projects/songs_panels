# Teea — Machine-to-machine REWORK delta after real Godot camera integration

**Batch under review:** \`TEEA_INT_20261122_002\`  
**Integrator:** ChatGPT (Godot 4.7.2)  
**Current disposition:** 12/12 PNGs and archive hashes PASS; real camera loads PASS **after integrator backwall visibility patch**; OWNER ART APPROVAL NOT GRANTED.  
**Important:** DO NOT overwrite the submitted art, DO NOT switch \`approved:false\` to \`true\` and DO NOT modify accepted gameplay/station data.

## A. Work already completed by integrator — no need to recreate artwork for this

1. The received archive SHA-256 is \`dcc4d0471a127c441a636d612f8aa8d8fceaa33e3c0a555b5c2f7d1008eb622c\`; every PNG checks out against the authored manifest and \`.sha256\`.
2. Rendered actual common/R3, library/R2, study/R1 and rest/R1 with the exact current Godot 4.7.2 runtime camera.
3. Isolated the backend occlusion fault: \`Stage_Backwall\` legacy procedural panels were in front of \`Art_backdrop\` Sprite3D. This is an **integrator renderer issue**, not a Teea task. The integrator hides temporary \`Stage_Backwall\` only when a loaded, accepted \`Art_backdrop\` exists, restores it for far-zoom, never reveals private interiors.
4. Avoid double sofas: current engine already suppresses procedural \`LocalFurniture\` meshes whenever an accepted complete \`furniture_back\` image is used. Invisible interaction nodes persist.
5. The production branch still has zero newly approved Teea image layers; a separate \`qa/teea-int-20261122-002\` branch contains review-only artifacts.

## B. Required next input from Teea: real authored X/Z anchors, not just screen X/Y

The current \`anchor_proposals\` contain \`local_x\`, \`local_y\`, \`source\` but no depth coordinate, seat count, seat width or walking approach. The \`local_x\` appears centered on the full R1/R2/R3 composition. The engine needs **module-indexed local X/Z**.

### Exact coordinate conversion

\`MODULE_W=4.8\` world units. For merged R3, module centers relative to the whole composite are \`[-4.8, 0, +4.8]\`. For R2, centers are \`[-2.4, +2.4]\`. For R1 center is \`0\`.

\`cell_local_x = group_local_x - group_module_center_x\`

Module local X must fit within \`[-1.90,+1.90]\` so characters do not pass through a physical wall. The \`group_local_x=-2.55\` common chair is +2.25 relative to the left R3 module: it is **in the near-wall/door clearance zone** and cannot be a legal adult station without explicitly changing geometry.

| Room | Teea source anchor | Group X | Proposed module index | Derived cell-local X | Status |
|---|---|---:|---:|---:|---|
| common/R3 | \`common_sofa_left\` | -5.25 | 0 (left) | -0.45 | requires actual seat slots and Z |
| common/R3 | \`common_chair_left\` | -2.55 | 0 | +2.25 | **OUTSIDE station bounds** |
| common/R3 | \`common_bench_right\` | +3.35 | 2 (right) | -1.45 | requires seat count/Z |
| common/R3 | \`common_chair_right\` | +5.35 | 2 (right) | +0.55 | requires Z |
| library/R2 | \`library_chair_left\` | -2.15 | 0 (left) | +0.25 | requires seated contact point/Z |
| library/R2 | \`library_chair_right\` | +2.15 | 1 (right) | -0.25 | requires seated contact point/Z |
| library/R2 | \`library_table\` | 0.00 | module boundary | ±2.40 | NOT a legal single-cell station |
| study/R1 | \`study_chair\` | -0.42 | 0 | -0.42 | close to old station X, Z unknown |
| rest/R1 | \`rest_sofa\` | +0.75 | 0 | +0.75 | old actual sofa stations use -0.85 and +0.27; mismatch |
| rest/R1 | \`rest_lounge\` | -1.35 | 0 | -1.35 | requires Z and chair sitting/contact |

**Common R3 critical mismatch:** \`common_sofa_left\` is painted in the LEFT module, whereas the old gameplay \`SOFA_COMMON_MIDDLE\` station belongs to the MIDDLE module. Do not equate these objects by name or shift the old station blindly. An actor would appear to sit in empty space.

### Required machine deliverable

File: \`dragon_house_clean/data/asset_proposals/TEEA_INT_20261122_002_furniture_anchors_candidate.json\`

Schema example for one group:

\`\`\`json
{
  "schema": 2,
  "batch_id": "TEEA_INT_20261122_002",
  "approved": false,
  "coordinate_space": "godot_group_modules",
  "unit": "world_meter",
  "module_width": 4.8,
  "room_variants": {
    "common/R3": {
      "stations": [
        {
          "id": "common_sofa_left_seat_a",
          "furniture_id": "common_sofa_left",
          "module_index": 0,
          "group_local_x": -5.6,
          "cell_local_x": -0.8,
          "cell_local_z": -0.48,
          "feet_contact_y": 0.0,
          "approach_local_z": 0.95,
          "kind": "seat",
          "pose_hint": "RELAXED_SIT",
          "occupancy_capacity": 1,
          "occlusion_role": "furniture_back",
          "source_visual_anchor": "common_sofa_left",
          "confidence": "AUTHOR_CONFIRMED_FROM_BLENDER_SCENE"
        }
      ]
    }
  }
}
\`\`\`

The numeric coordinates above are **schema illustrations, not accepted or inferred placement**. Replace each with actual values calculated from your original Blender scene and **visible sitting footprint**; no invented Z values. Give each individual person-sized seat its own unique ID. Tables that are not seating locations should have \`kind:work\` or no station; lamps and decorative shelf accents are **not** resident stations. Include a \`collision_footprint\` polygon in group-local X/Z for large benches, sofas, tables or where approach is constrained.

Do **not** submit a partial JSON that silently drops existing seats. Mark any unknown as \`BLOCKED_DEPTH_COORDINATE\` and describe the missing measurement.

## C. Actual depth, occlusion and image review

1. Images currently contain only \`backdrop\`, \`back_decor\`, \`furniture_back\`. This is valid **for pilot technical QA** but insufficient to occlude the actor correctly at all chairs and front-edge surfaces. Where a seated torso should appear behind a physical armrest/table, supply an additional transparent \`foreground\` PNG registered on the same full canvas.
2. Front trim and glow are optional; do **not** generate decorative filler solely to make six roles. No fake bloom, text, watermark or overpainting.
3. Current procedural ceiling and front beams may look oversized alongside these render plates. Integrator owns correction of the code-side beam thickness; do not repaint beams into a backdrop to hide the problem.
4. Preserve the 3D-rendered physically coherent camera, realistic stone/wood/fabric/metal response. **No cartoon, caricature, \`lubok\`, stylized fairytale, toy furniture, gloss-plastic or generic AI collage.** These models were rendered at 50% native resolution and Lanczos upscaled; for any softness/aliasing visible in owner-review close-up, rerender critical silhouette layers at the actual output resolution if feasible rather than over-sharpening.
5. Keep a full clear public aisle; no collision or sit action through a sofa backrest, tree of walls, film screen or bookshelf. No author-owned private room interior is disclosed.

## D. PASS gates for next handoff

**Machine PASS** requires the following:

- Same exact 4 variants and unmodified source 12 layers unless a requested revision is versioned.
- New 0-based \`module_index\`, \`cell_local_x\`, \`cell_local_z\`, \`approach_local_z\` for every actual seat/work station.
- All \`cell_local_x\` within ±1.90 or explicitly identified as a blocked geometry case.
- Seats have unique IDs and non-overlapping footprints; an R3 group must not imply 30 sofas when only specific seats are visually present.
- Depth and front-occlusion plates have alpha and exact canvas sizes; the art is aligned in the Godot 4.7.2 perspective camera (not just a Blender proof).
- No private-room layers, no copying Bethesda assets, explicit provenance for every changed asset.
- Status remains \`READY_FOR_REVIEW\` and \`approved:false\` pending owner art decision.

**Manual owner visual PASS** separately requires credible photographic realism, usable foreground/door/roof scale, depth consistency and recognizable intended function of each room.

**Do not open a production PR or toggle approved flags.** Place the new patch on \`art/teea-interiors-TEEA_INT_20261122_002\` or a clearly named follow-up Teea art branch, provide the commit and SHA checks. The integrator merges only after evidence and owner approval.

