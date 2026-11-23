# ZNA_CHAR_NPC_20261123_003 — Creature / Media Previews QA

Status: **TECHNICAL PASS WITH EXPLICIT CONTENT GAPS / owner_approved=false**

## Git evidence

- audited task-start branch head: `b3f81349840707b6c0b95ec025b7a8e827175752`
- workflow staging head: `b3d2cbd49206a8bfc0a03455017fbb35fef0c3e2`
- asset commit: `413c77b2b8625b4871527dea61f1945528ee0b79`
- fresh-clone audited head: `413c77b2b8625b4871527dea61f1945528ee0b79`
- final handoff commit before this correction: `e1943f898176c3f77b5d8e6b2ee301f8b43586b7`
- branch: `art/znaechka-characters-ZNA_CHAR_NPC_20261123_001`

## Existing guest / creature inventory

- Кентавр: COMPLETE base guest bank, existing art reused.
- Вампирша: COMPLETE base guest bank, existing art reused.
- Миу / `NPC_GINGER_CAT_GUEST`: COMPLETE starting SHORT bank, no duplicate created.
- Magical AI sphere: COMPLETE minimum creature bank; remains sphere/device, no guest-room implication added.
- Hedgehogs: 3 COMPLETE minimum creature banks.
- Cats: 6 COMPLETE minimum creature banks; owner labels remain UNKNOWN because no verified owner IDs exist.
- Rats: 5 COMPLETE minimum creature banks; not relabeled as mice.
- Manjka: COMPLETE minimum creature bank.
- Shurshun: **MISSING creature bank**; only artifact/poster imagery is present, so no identity was fabricated.
- Mice: **MISSING**; no approved mouse identity master found.

## RES_22–RES_24 hard stop

- Exactly **423** prior R1 technical frames were restored from the prior accepted delivery.
- Source RES_22–24 ZIP SHA-256: `5d05c5fe0397bf0c7fa50cb03193f1540c2401ee66480c84c364f0123b47ab49`.
- All 423 destination frame SHA-256 values match their source bytes.
- Identity files were hash-checked before/after and were **not modified**.
- No repaint, regeneration or identity-gate work was performed.
- Identity drift remains a documented known limitation, not a silent PASS.

## Media preview processing

Canonical book registry:
- 76/76 metadata entries retained.
- No confirmed cover art was established in repo for this pass.
- 76 neutral typography placeholders were generated; they are explicitly **not official cover art**.

YouTube liked-list source:
- source: `Понравившиеся - YouTube.pdf`
- source file id: `file_00000000b80c821087056a640cf64627`
- source SHA-256: `038efbd6e84c653ba67bc61569e05932eba9eebfa7883ea46cc59114da724cbf`
- pages: 88
- playlist visible count in source: 932
- physically visible/extracted cards: 698
- source gap: 234 cards not present in PDF and **not reconstructed from the web**
- conservative source classification: audio 203 / film 0 / unclassified 495
- YouTube thumbnail bytes were **not committed** because repository-use rights were not confirmed
- neutral title/metadata placeholders were generated instead

Source-derived crop package for review only:
`/Dragon cave/DRAGON_HOUSE_ARCHITECT_2026-09-29/ZNA_CHAR_NPC_20261123_003_CREATURE_MEDIA_PREVIEWS/ZNA_CHAR_NPC_20261123_003_CREATURE_MEDIA_TRANSFER.zip`

Transfer package SHA-256:
`401ced83f2f99db74a72e1a58017935717019da581a62697ba1837c9b91487a8`

Artifacts:
- canonical artifact registry audited
- preview generated only when the registered source master already exists as a project asset in this repo
- missing masters remain `MISSING_SOURCE_MASTER_NO_FABRICATION`; no fake artifact art was created

## Runtime / scope

- No engine/runtime/interior files were edited.
- No ownership labels were invented.
- No runtime binding or owner approval was asserted.
- Media preview manifest is art/data only; integrator owns hover/full-screen/runtime hookup.

## Machine QA

- pre-commit QA: PASS
- scope guard: PASS
- Git LFS push: PASS
- fresh clone + `git lfs pull`: PASS
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
