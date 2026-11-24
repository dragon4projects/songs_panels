# Phase 2 QA — PARTIAL_READY

- 87/87 PackedScene load, vertex-derived bounds, actual triangle count. Max vertex-bound error 0.000007570 m. All relative model dependencies resolve.
- 18 models decimated, 221,899 triangles removed; original source retained. Largest observed pre-recenter bound difference 10.4 mm (gaming console), visual approval pending.
- 350 asset payload files, 92,925,862 bytes, per-file SHA-256 recorded.
- 30 room delta variants, 94 added candidate objects, 29 support slots, 0 omitted proposed placements after fit adjustments. Phase1 path-grid QA is not reasserted as new whole-runtime QA.
- 32/32 legacy media IDs preserved; no private media. Original holder surface geometry measured. Artifact labels need final shelf/cabinet reanchor; no pedestal.
- 35 actual Godot images (7 rooms, effective yaw 0 / +/-0.34 / +/-0.42 radians). Camera math copied from pinned game code. Raw physical X/Z preview, not runtime actor/depth correction, not final approved art. Common still visually sparse; cinema screen overly bright; not owner accepted. Audio driver dummy fallback in sandbox only.
- No GitHub Actions started intentionally. No production changes. No clean LFS checkout or full runtime verification.
