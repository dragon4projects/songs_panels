# TEEA_INT_20261124_008 — partial asset-only QA
Status: PARTIAL_READY. Owner approval: false. Production untouched.

- Physical source geometry: 158/158 unique source IDs measured (137 harvest plus 21 earlier source assets).
- 45 candidate runtime models with actual files at model.gltf paths. Four 1K PBR material sets.
- Model triangle sum 162,529; normalized payload 46,686,437 bytes; 209 SHA-verified files.
- Godot 4.7.2: 45/45 PackedScene import, mesh-child, triangle and AABB validation: 33 non-cinema + 12 cinema separately in clean import. KHR_mesh_quantization was unsupported; converted vertex attributes to float32 and verified unchanged positions (<0.1 mm). Source intact.
- 30/30 public X/Z layout proposals passed conservative 0.65 m human route grid, bounds, overlap, support and station-cap checks. 109 proposed instances, 80 candidate stations. Not actual actor/runtime gameplay proof.
- 15 small-artifact candidates. All theft_enabled=false, no ownership assigned, masses provisional.
- 32 legacy media IDs preserved. Three screen-aperture deltas proposed, 29 remain unchanged pending rebind.
- Real game-camera yaw proofs, clean git LFS checkout, integration runtime, guest-fit proof and owner visual approval are NOT performed.
- See gap_inventory.json for exact remaining work; no production changes, no private media.
