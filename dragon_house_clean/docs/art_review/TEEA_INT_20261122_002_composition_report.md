# Dragon House — TEEA_INT_20261122_002 composition report

## Status

- Batch method: deterministic CC0 3D assets + CC0 PBR materials rendered in portable Blender 4.5.16 LTS inside the Higgsfield sandbox.
- No image generator was used for the production plates in this batch.
- Camera: orthographic shallow side-view. Camera center height 1.50 m. Visible vertical span is 3.2 m. Horizontal span is exactly 4.8 m (R1), 9.6 m (R2), or 14.4 m (R3).
- Production source renders were made at 50% of target pixel size with the exact same aspect ratio, then enlarged once with Lanczos 2x to the required target canvas. No generative redraw or per-layer repositioning occurred.
- backdrop is opaque; back_decor and furniture_back use real RGBA transparency.
- No approved:true flag is written anywhere.

## Machine QA

- Exact target dimensions: PASS for all 12 PNG files.
- Non-background alpha: PASS, extrema 0..255 for all back_decor and furniture_back plates.
- Godot 4.7.2 decode: PASS for all 12 PNG files.
- ImageTexture creation: PASS for all 12 PNG files.
- Sprite3D texture assignment in a standalone Godot 4.7.2 QA script: PASS.
- Current dragon_house_clean integration camera: NOT TESTED in this sandbox because the private integration checkout is not available inside Higgsfield.
- Therefore this batch does not claim full TECH_PASS. It is READY_FOR_REVIEW / INTEGRATION TEST REQUIRED.

## Rights / provenance

- Poly Haven source models: CC0.
- ambientCG Rock035 and Wood051 materials: CC0 1.0.
- Procedural geometry created for this batch: cave structural blocks, Common hearth architecture, Study heavy desk, and simple wall-globe fixtures.
- No Bethesda/Fallout visual assets were used.

## Room notes

### common/R3

- Continuous 14.4 m composition, not a stretched R1.
- The fireplace is structural backdrop; no static flame is baked into the plate.
- Center remains intentionally sparse for movement/readability and later Dragon/actor composition.
- Seating and tables painted into furniture_back are visual anchor proposals only. Integration owner must map actual station/collision semantics before acceptance.
- Current visual direction is deliberately restrained and should be reviewed in the real camera before additional clutter is added.

### library/R2

- Three asymmetric shelf groupings with CC0 book volumes baked into back_decor.
- No mugs or drink props were added.
- Reading furniture is sparse and the aisle remains readable.
- Books are baked art here rather than repeated high-poly runtime geometry.

### study/R1

- Heavy desk is low-cost procedural geometry.
- Shelf and drawer storage are behind the resident plane.
- Desk/chair/lamp are anchor proposals and must not silently become interaction geometry.
- The room remains practical rather than dark-academia set dressing.

### rest/R1

- Quiet sofa + lounge chair + small side table.
- One modest shelf mass.
- No bed and no romantic/bedroom staging.
- Negative space is intentional.

## Source/render strategy

Repeated low-cost furniture uses 1K Poly Haven packages. Heavy book geometry is rendered once into the 2D layer instead of being repeated in runtime. This is specifically intended to reduce texture/geometry pressure on the Dell Latitude 5300 target.

## Review gates still open

1. Owner photorealism/aesthetic review in the actual Dragon House camera.
2. Current-project Sprite3D compositing check at exact runtime Z roles.
3. Collision/station mapping from anchor proposals.
4. Check that the existing 3D shell/furniture does not visually double with these candidate layers.
5. Only after these checks may the integration owner merge the proposal and set approved:true where appropriate.


