# Sketchfab owner-supplied originals — 2026-11-25

Six exact original GLBs, SHA-256 verified by download from confirmed external storage. Three coffee machines, three fireplaces including one animated model. No normalization, production change, ownership approval or Godot import claimed. Existing .gitattributes require GLB to be committed via LFS. The connector cannot upload LFS bytes, so this commit contains metadata and hydration script, NOT the actual GLBs or orphan LFS pointers.

From a locally authenticated checkout of this branch, run:

```sh
python3 dragon_house_clean/assets_external/sketchfab/harvest_20261125/fetch_originals.py
git lfs install --local
git add -- dragon_house_clean/assets_external/sketchfab/harvest_20261125/raw/
git commit -m "assets: add six original Sketchfab GLBs"
git push origin assets/cgtrader-coffee-mugs-20261124
```

Retain CREDITS.md with assets. One model is CC BY-NC 4.0; non-commercial use only. The rest are CC BY 4.0. Do not activate or replace existing decor until separately normalized and reviewed. Animation preserved in original.
