# Native SQLite spike dependency provenance

This directory is an isolated compatibility harness and is not the Dragon House production runtime.

Dependency candidate:
- project: godot-sqlite
- upstream: 2shady4u/godot-sqlite
- tag: v4.9
- pinned upstream commit: 9cbdb225823ee111342ce32fe451e066eb92cc6e
- release asset: addons.zip
- release asset SHA256: 95e91b72fe32984a84edaf6357a78753661f37a170cb362f5b948e0ede7c2cb0
- upstream Godot dependency: 4.7.1-stable
- SQLite dependency: 3.51.0
- gdextension compatibility_minimum: 4.7
- license: MIT
- copyright: 2019-2026 Piet Bronders & Jeroen De Geeter

Spike policy:
- addon binaries are downloaded only inside CI and are not committed to this branch;
- exact SHA256 is verified before use;
- the main project stays dependency-free until runtime/export compatibility is proven;
- passing Linux runtime + cross-export packaging is not physical Windows/macOS execution proof.
