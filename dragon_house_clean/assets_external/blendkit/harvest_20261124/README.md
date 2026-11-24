# Blendkit harvest — 2026-11-24

Exact owner-selected Dragon House asset harvest.

State:
- requested: 78
- downloaded and SHA-pinned in authoring cache: 77 free assets
- unavailable without Full Plan: 1 (Vintage Wooden Bellows Camera)
- licenses: 77 Royalty Free, 1 CC0
- structural validation of downloaded source files: 77/77 PASS

Public-repository rule:
dragon_home_project is public. Raw Blendkit Royalty Free models are deliberately not committed because they would be directly extractable as standalone 3D assets.

Instead:
- exact Blendkit asset/version/download UUIDs are pinned in BLENDKIT_HARVEST_20261124.json;
- fetch_blendkit_assets.py materializes the 77 free files into a local ignored cache;
- downloaded SHA-256 values are pinned to detect source/version drift;
- Royalty Free assets are treated as BAKED_ART_SOURCE;
- the sole CC0 asset is also materialized through the same pinned fetcher.

No user credentials are stored in this package.

The current ChatGPT GitHub connection can write to songs_panels but has read-only access to dragon_home_project. This branch is therefore a staging branch on the same Dragon House production base and is intended to be copied to dragon_home_project once repository write access is granted.

Missing item:
Vintage Wooden Bellows Camera is currently Full Plan. It is retained in the manifest but was not fetched anonymously and no substitute asset was silently chosen.

License references:
- https://www.blendkit.com/docs/licenses/
- https://www.blendkit.com/docs/licenses/licensing-faq/
- https://www.blendkit.com/terms-and-conditions-2026/
