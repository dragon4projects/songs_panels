# TEEA_INT_20261122_003 — INTEGRATOR FEEDBACK R1

Status: METADATA_REWORK_ONLY  
Art redraw required: NO  
Owner approval: NOT REQUESTED YET  
Integrator: Dragon House v0.11

## Independent intake PASS

The external binary ZIP was independently downloaded and verified.

ZIP SHA-256:
`2233854a91684acec90ad687961cc1c3b1316f921643a5941e9ed6846778b093`

Independent binary QA:
- delivery assets checked: 20 / 20
- per-file SHA-256: 20 / 20 exact
- dimensions: 20 / 20 exact 1536 x 1024
- mode: 20 / 20 RGBA
- errors: 0

No art redraw is requested from this check.

## Required metadata correction: foreground physical_z

Current Dragon House runtime does not place a foreground occlusion sprite at an arbitrary visual Z. It re-registers the image against the current camera using an explicit measured `physical_z` stored with the foreground layer.

Batch 003 currently provides foreground for:
- music/R1
- cinema/R1

But `TEEA_INT_20261122_003_foreground_layers_candidate.json` does not include an explicit `physical_z` for either layer.

The composition report says each foreground was cut from the same furniture at the measured seating centroid. The station proposal currently reports:
- music_listen_chair_seat_a: `cell_local_z = -0.4742`
- cinema_sofa_seat_a / b: `cell_local_z = -0.3424`

These values look like the intended cut planes, but the integrator will NOT silently infer that equivalence.

### Teea action

Update the foreground candidate metadata to state the exact authored Godot-local physical cut Z explicitly, e.g.:
```json
{
  "role": "foreground",
  "path": ".../foreground.png",
  "physical_z": <exact authored value>,
  "approved": false
}
```

Do this for both Music and Cinema. Keep `approved:false`.

If the intended physical cut plane is exactly the seat-centroid Z already reported above, explicitly confirm those exact numbers in the JSON. If not, provide the actual cut plane used in Blender/Godot calibration.

## Gameplay vocabulary is integrator-owned

Schema-2 uses richer artist semantics such as:
- `kind: "view"`
- `pose_hint: "LISTEN"`
- `pose_hint: "WATCH"`
- `pose_hint: "INSPECT"`

Do not redraw or reposition furniture because of this.

The current gameplay contract uses a narrower runtime vocabulary. The integrator will map the artist semantics to runtime station kinds / pose fallbacks without changing the measured x/z/approach geometry. No artist-side canon approval is implied.

## What remains after metadata fix

Integrator will:
1. ingest binaries through the real Git LFS path;
2. mount 003 only in QA/current-camera integration;
3. verify HOUSE and ROOM registration;
4. verify Music/Cinema foreground parallax around live actors;
5. verify approach routes against collision footprints;
6. verify no procedural-furniture doubling;
7. present the resulting live-camera build for owner visual review.

Do not set `approved:true`.
Do not open a production PR.
Do not modify the accepted 002 baseline.
