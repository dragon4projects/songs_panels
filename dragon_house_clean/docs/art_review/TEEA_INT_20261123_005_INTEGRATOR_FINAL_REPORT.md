# TEEA_INT_20261123_005 — INTEGRATOR FINAL REPORT

**Date:** 2026-11-23  
**Source art branch:** `art/teea-interiors-TEEA_INT_20261123_005`  
**Source head:** `5500e9a9dd902a3fe573c556e51bc1c4814c88c7`  
**Owner approved:** false  
**Production promotion:** NONE

## Final verdict

```text
machine_status: INTEGRATOR_QA_PASS
exact_payload: PASS
runtime_integration: PASS
live_camera_visual: PASS
owner_approved: false
artist_rework_required: false
production_promotion: BLOCKED_PENDING_OWNER
```

## Exact payload

- 8 variants
- 32 production PNG
- 26 measured stations
- 8 foreground variants
- all foreground `physical_z = +0.15`
- 32/32 exact 1536x1024 RGBA8
- ZIP SHA-256 verified: `5cc946bcba991d0d357b02310a16109dda866e79b8e961d76766f4aa24641fbd`
- station bounds errors: 0
- spacing errors: 0
- foreign collision / approach intersections: 0
- depth-readability machine pass: 8/8

## Runtime issues found by integration — NOT art rework

Live integration exposed three runtime mapping bugs. All were fixed in production runtime rather than returned to Teea:

1. `floor_rest / SLEEP` was rendered as standing IDLE.
   - fixed: `floor_rest` may honor authored `SLEEP`.
2. `WORK_CREATE / kind=work / pose=USE` was rendered as IDLE.
   - fixed: real work stations honor authored `USE`.
3. `TALK_PAIR / kind=seat / pose=TALK` forced the standing TALK bank.
   - fixed: seated conversation uses `RELAXED_SIT`; standing conversation retains `TALK`.

These were integrator/runtime defects. Teea station semantics were valid.

## Authoritative evidence

Final QA branch:
`dev/dragon-house-v016-teea005-acceptance-final`

Final QA head:
`95cb712dcee52869fe71bccf3352894c66d6b4bc`

GitHub Actions:
- workflow: `Dragon House v0.16 TEEA005 integrator QA`
- run #7
- run id: `45165857931`
- conclusion: SUCCESS

Artifact:
- `dragon-house-teea005-integrator-qa`
- artifact id: `14815410382`
- digest: `sha256:47ff732a3ea4e1ad1c93ed9d54e340978bdfd573a369e603430add3750ece284`

Production runtime acceptance after pose fixes:
- fresh head at final candidate review: `3bd019771dec104ceec830150a8801b197eb02c5`
- full acceptance run #32: SUCCESS

## Live visual review

PASS:
- Common R1/R2 station semantics read correctly: measured seat remains seated; standing talk target remains standing.
- Study R2/R3 work/read station positions remain registered to authored furniture.
- Rest R2/R3 lounge seats and floor-rest positions use physically appropriate poses.
- Library R1/R3 measured anchors remain registered.
- foreground remains registered at yaw `-0.15 / 0 / +0.15` on proof variants.
- no procedural furniture doubling was observed.
- accepted TEEA002 variants outside batch005 remain preserved.

## Artist action

No correction required for TEEA005.

Proceed with `TEEA_INT_20261123_006` depth / functional-dressing rework scope already assigned.

Do not modify TEEA005 unless the owner explicitly requests a visual revision.

## Owner gate

`TEEA_INT_20261123_005` remains `owner_approved:false`.

Integrator PASS does not promote the assets to production by itself.
