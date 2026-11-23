# ZNA_CHAR_NPC_20261123_002 — SMALL LIFE ART BANKS

**From:** Dragon House Integrator  
**To:** Znaechka / local character-generation agent  
**Date:** 2026-11-23  
**Scope:** CHARACTERS / NPC / CREATURE ART ONLY  
**Status:** QUEUED — START ONLY AFTER RES_22/23/24 IDENTITY R2 PASS  
**Owner approval:** false

## 0. GATE

Do not start this batch until `ZNA_CHAR_NPC_20261123_001_IDENTITY_R2` has passed integrator visual QA for all three residents.

When gate opens, this task supersedes the self-generated centaur/vampire/sphere/hedgehog proposal as the next Dragon House NPC-art priority.

## 1. REQUIRED ENTITIES

Create candidate art banks for:

1. `SHURSHUN` — canonical named cat.
2. `CAT_GENERIC_01` — unassigned domestic cat candidate.
3. `CAT_GENERIC_02` — second visibly distinct unassigned domestic cat candidate.
4. `MICRO_MOUSE_01` — house mouse / microfauna hunt target.

Optional third generic cat only if identity consistency remains strong.

Do not redraw Manka in this batch.
Do not invent additional resident-owned pets without explicit source evidence.

## 2. SHURSHUN CANON

Preserve:
- small adult charcoal/black domestic cat;
- amber/gold eyes;
- fluffy raised tail;
- intelligent/skeptical expression;
- brown leather collar;
- round brass/gold tag;
- tag text canon: `Шуршун. Хозяйка Шурша`;
- paw mark on tag.

Ownership fact:
- Shursha chose/adopted Shurshun herself;
- Dragon did not give her the cat;
- Dragon gifted the collar/tag.

If tag lettering is not readable at runtime sprite scale, preserve tag shape/material and keep exact text in identity/reference master; do not generate fake glyph noise in every animation frame.

## 3. CAT BANK STATES

For Shurshun and each generic cat candidate:
- `IDENTITY` — 1
- `IDLE_STAND` — 1
- `IDLE_SIT` — 1
- `LOOK` — 1
- `NAP` — 1
- `WALK_LEFT` — 8
- `WALK_RIGHT` — 8
- `RUN_LEFT` — 8
- `RUN_RIGHT` — 8
- `STALK_LEFT` — 4
- `STALK_RIGHT` — 4
- `POUNCE_LEFT` — 4
- `POUNCE_RIGHT` — 4
- `CARRY_SMALL_LEFT` — 1
- `CARRY_SMALL_RIGHT` — 1

Priority if generation quality falls:
`IDENTITY + IDLE + WALK + NAP + STALK + CARRY_SMALL` first.
Do not fake PASS with duplicate frames.

## 4. MOUSE BANK STATES

For `MICRO_MOUSE_01`:
- `IDLE` — 1
- `SNIFF` — 2–4
- `RUN_LEFT` — 6–8
- `RUN_RIGHT` — 6–8
- `HIDE` — 1
- `FLEE_LEFT` — 6–8
- `FLEE_RIGHT` — 6–8

Optional:
- `CARRY_CRUMB_LEFT`
- `CARRY_CRUMB_RIGHT`

No gore is required.
Mouse is microfauna, not a biography-bearing resident.

## 5. CARRY / OBJECT RULE

Cat carry states represent presentation only.

Do not bake a specific canonical Dragon House artifact permanently into the cat sprite bank.
Preferred:
- neutral small placeholder object for silhouette QA, or
- documented mouth/object overlay anchor for runtime compositing.

Runtime object identity/ownership/holder/location is integrator-owned and separate from creature art.

## 6. TECHNICAL CONTRACT

Transparent RGBA PNG.

Recommended canvas:
- cats: 512x512;
- mouse: 256x256 or 512x512, choose one consistently and document it.

For every bank record:
- entity_id;
- state;
- frame count;
- fps;
- paw/feet anchor;
- visual height relative to 512x512 human resident;
- direction;
- source/provenance;
- identity consistency warnings;
- `owner_approved:false`.

Path family:
- `dragon_house_clean/assets/creatures/cats/<CAT_ID>/...`
- `dragon_house_clean/assets/creatures/microfauna/MICRO_MOUSE_01/...`

Do not invent a different folder grammar if current creature manifests already define one; adapt to the current canonical project structure and document any delta.

## 7. RUNTIME SEMANTICS METADATA

Candidate manifest fields:
- `entity_type = creature | microfauna`
- `owner_entity_id`
- `hunt_eligible`
- `can_hunt`
- `can_pickup_objects`
- `can_stash_objects`
- `roam_scope_candidate`
- `behavior_profile_candidate`
- `activation_status = ART_ONLY`

Defaults:
- Shurshun: `owner_entity_id` = Shursha's canonical resident ID only if exact mapping is already authoritative in project data; otherwise leave unresolved and report.
- generic cats: `owner_entity_id = null`.
- mouse: `hunt_eligible = true`.

Do not activate creatures in world state.
Do not code behavior.

## 8. VISUAL PASS

PASS only if:
- Shurshun reads as the same cat across every state;
- two generic cats are clearly distinguishable from each other and Shurshun;
- mouse silhouette is readable at gameplay scale;
- walk/run/stalk/pounce frames are genuinely distinct;
- baseline/paw anchor is stable;
- no extra limbs/tails/ears;
- carry states keep object at a physically plausible mouth position;
- transparent alpha/canvas/naming QA passes;
- no resident ownership invented;
- Manka assets unchanged.

## 9. DELIVERY

Deliver:
- candidate banks;
- identity/contact sheet per cat;
- mouse contact sheet;
- creature manifest delta;
- SHA256 manifest;
- Godot image-load QA;
- provenance note;
- integrator-accessible GitHub LFS or Actions artifact / shared Library handoff.

Return:

```text
ZNA_CHAR_NPC_20261123_002
machine_status: READY_FOR_INTEGRATOR_QA | BLOCKED
owner_approved: false
entities: 4 minimum
shurshun: READY | BLOCKED
generic_cats: 2 minimum
mouse_banks: 1 minimum
runtime_activation: NONE
local_only_paths: NONE
```
