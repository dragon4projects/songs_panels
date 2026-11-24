# Blendkit harvest — 2026-11-24

Exact owner-selected Dragon House asset harvest.

State:
- requested: 78
- downloaded and SHA-pinned in authoring cache: 77 free assets
- unavailable without Full Plan: 1 (Vintage Wooden Bellows Camera)
- licenses: 77 Royalty Free, 1 CC0
- structural validation of downloaded source files: 77/77 PASS

Public-repository rule:
dragon_home_project is public. Raw Blendkit Royalty Free models are deliberately not committed here because they would be directly extractable as standalone 3D assets.

Instead:
- exact Blendkit asset/version/download UUIDs are pinned in BLENDKIT_HARVEST_20261124.json;
- fetch_blendkit_assets.py materializes the free files into a local ignored cache;
- downloaded SHA-256 values are pinned to detect source/version drift;
- Royalty Free assets are intended as BAKED_ART_SOURCE;
- only CC0 source assets may be committed raw.

No user credentials are stored in this package.

Raw CC0 source included:
Kitchen Set - Nuts and Accessories:
cc0/kitchen_set_nuts_and_accessories/source.glb

Missing item:
Vintage Wooden Bellows Camera is currently Full Plan. It is retained in the manifest but not fetched anonymously and no substitute asset was silently chosen.
