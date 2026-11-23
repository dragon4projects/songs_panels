# ZNA_CHAR_NPC_20261123_003 — Creature / Media Previews QA

Status: **TECHNICAL PASS WITH EXPLICIT CONTENT GAPS / owner_approved=false**

## Git evidence

- audited task-start branch head: 
- workflow staging head: 
- asset commit: 
- fresh-clone audited head: 
- branch: 

## Existing guest / creature inventory

- Кентавр: COMPLETE base guest bank, existing art reused.
- Вампирша: COMPLETE base guest bank, existing art reused.
- Миу / : COMPLETE starting SHORT bank, no duplicate created.
- Magical AI sphere: COMPLETE minimum creature bank; remains sphere/device, no guest-room implication added.
- Hedgehogs: 3 COMPLETE minimum creature banks.
- Cats: 6 COMPLETE minimum creature banks; owner labels remain UNKNOWN because no verified owner IDs exist.
- Rats: 5 COMPLETE minimum creature banks; not relabeled as mice.
- Manjka: COMPLETE minimum creature bank.
- Shurshun: **MISSING creature bank**; only artifact/poster imagery is present, so no identity was fabricated.
- Mice: **MISSING**; no approved mouse identity master found.

## RES_22–RES_24 hard stop

- Exactly **423** prior R1 technical frames restored from the prior accepted delivery.
- Source ZIP SHA-256: .
- All 423 destination frame SHA-256 values match their source bytes.
- Identity files were hash-checked before/after and were **not modified**.
- No repaint, regeneration or identity-gate work was performed.
- Identity drift remains a documented known limitation, not a silent PASS.

## Media preview processing

Canonical book registry:
- 76/76 metadata entries retained.
- No confirmed cover art was present in repo.
- 76 neutral typography placeholders generated; they are explicitly **not official cover art**.

YouTube liked-list source:
- source: 
- source file id: 
- source SHA-256: 
- pages: 88
- playlist visible count in source: 932
- physically visible/extracted cards: 698
- source gap: 234 cards not present in PDF and **not reconstructed from the web**
- conservative source classification: audio 203 / film 0 / unclassified 495
- YouTube thumbnail bytes were **not committed** because repository-use rights were not confirmed.
- Instead, neutral title/metadata placeholders were generated.
- Source-derived crop package remains in shared Library for review only:
  

Artifacts:
- canonical artifact registry audited.
- preview generated only when the registered source master already exists as a project asset in this repo.
- missing masters remain ; no fake artifact art was created.

## Runtime / scope

- No engine/runtime/interior files were edited.
- No ownership labels were invented.
- No runtime binding or owner approval was asserted.
- Media preview manifest is art/data only; integrator owns hover/full-screen/runtime hookup.

## Machine QA

- pre-commit QA: PASS
- scope guard: PASS
- Git LFS push: PASS
- fresh clone + : PASS
- 423 RES frame re-hash in fresh clone: PASS
- placeholder/media manifest counts in fresh clone: PASS
- preview image decode in fresh clone: PASS

## Explicit blockers

1. Shurshun needs an approved creature identity master before a creature bank can be generated.
2. Mice need an approved mouse identity master; existing rat banks are not substitutes.
3. 234 liked-list entries are absent from the supplied PDF.
4. YouTube source thumbnails require a separate rights decision before repository use.
5. Artifact registry entries whose master image is absent from this repo remain unresolved.
6. Owner art approval remains false.
