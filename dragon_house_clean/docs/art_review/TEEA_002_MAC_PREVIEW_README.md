# Dragon House — Teea 002 macOS visual review

QA-only preview. Source batch TEEA_INT_20261122_002. Not artistically approved. Mac build targets macOS 15 on Apple M1 (Godot 4.7.2 universal, unsigned). Not yet benchmarked on an actual Mac.

Launch: unzip and right-click .app > Open. If Gatekeeper blocks it, go to System Settings > Privacy & Security > Open Anyway.

Controls: C=Common R3; L=Library R2; S=Study R1; R=Rest R1; T=toggle Teea's new interior vs old procedural; mouse wheel=zoom; right click drag=pan; Q/E=shallow camera rotation; Esc=whole house; V=temporary nonapproved character bank preview. Clickable controls also appear top right. Starts in Teea Common R3.

Privacy and state: dedicated Godot app name, bundle ID and disposable QA save path. This viewer never reads the ordinary Dragon House saves. To show the submitted Library R2, it temporarily changes the adjacent Music module into Library IN MEMORY ONLY. Original project and its resident identities remain unchanged.

All 12 source PNGs and their SHA-256 verified from original Teea bundle. Source candidate data remains approved:false. QA mode temporarily allows candidate layers in memory only and does not modify data/interior_layers_v1.json.

Renderer QA: the original rear 3D stage was in front of the new Teea backdrop and obscured it. The QA renderer hides this stage only while an actual decoded Art_backdrop is mounted; HOUSE mode restores the old shell. Existing procedural furniture is suppressed when furniture_back image is loaded; unapproved physical seat mapping is still unresolved.

Tests: tests/test_teea_mac_preview_v12.gd checks all four room images, three layers each, original privacy and save isolation, T comparison without duplicate layers, missing approvals remain false. test_backwall_z_v11.gd checks near/far rear wall handling.

Review criteria for the owner: stone/wood fabric and metal photographic realism; spatial depth; relative scale of furniture and actors; oversized temporary ceiling/front beams; where seat positions should be; safe movement aisle. Send room and exact visual corrections. This is not final approval.
