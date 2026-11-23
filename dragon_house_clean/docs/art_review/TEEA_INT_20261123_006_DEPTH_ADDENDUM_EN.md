# TEEA_INT_20261123_006 — DEPTH READABILITY ADDENDUM

Status: REQUIRED ADDENDUM TO 006 BRIEF
Scope owner: TEEA / INTERIORS ONLY
Owner approval: false

## REFERENCE PURPOSE

Use Fallout Shelter screenshots only as a **spatial readability reference** for sectional 2.5D depth.
Do NOT copy Bethesda room art, props, colors, silhouettes, UI, textures, or layouts.

The useful reference property is this:

> A near-frontal cutaway can still read as a room with real depth when shell geometry, furniture overlap, lighting and functional clusters all agree on front / mid / rear planes.

## OBSERVED DEPTH MECHANISMS TO REPRODUCE IN OUR OWN VISUAL LANGUAGE

### 1. Shell depth must be visible before furniture is considered

The room shell itself must expose depth through:
- left/right side-wall wedges or returns;
- ceiling thickness / soffit / beam recession;
- floor recession / edge thickness;
- doorway or niche recesses;
- non-flat junctions between wall, ceiling and floor.

PASS:
- with furniture layers hidden, a reviewer can still identify front vs rear boundary at game camera scale.

FAIL:
- room becomes a flat rectangular wallpaper when furniture is hidden.

### 2. Functional objects must occupy multiple real depth bands

Do not place all important furniture on one Z line.
For every R2/R3 variant, create at least:
- one readable front-functional cluster;
- one readable mid/rear-functional cluster.

Clusters must be physically plausible and must preserve the public aisle.

PASS:
- at least two functional Z bands are visible without relying on labels.
- residents placed at measured stations visibly belong to the furniture plane they use.

FAIL:
- long room reads as one horizontal row of objects against the back wall.

### 3. Overlap is required, not accidental

Depth must be reinforced by controlled occlusion:
- front furniture may overlap lower body portions where physically correct;
- mid furniture may overlap rear props;
- rear props must not incorrectly render in front of front actors/furniture.

PASS:
- at yaw -0.15 / 0 / +0.15, overlap ordering remains physically believable.

FAIL:
- objects appear pasted side-by-side with no depth interaction;
- foreground cuts through torsos;
- rear props jump visually in front of closer furniture.

### 4. Lighting must separate planes

Use our warm cave-house lighting language, but establish depth with local light pools and value separation.

Required:
- rear wall cannot have the same average value/readability as every front object;
- at least one local light or shadow transition must help separate front/mid/rear;
- do not solve depth by globally darkening the entire room.

PASS:
- grayscale thumbnail still shows depth separation.

### 5. R2/R3 must be composed as larger rooms, not stretched R1 strips

For merged variants:
- use 2–3 functional clusters with slight Z staggering;
- vary furniture silhouette and local lighting rhythm across modules;
- preserve one coherent room identity;
- avoid three copied R1 bays unless the architecture truly demands repetition.

PASS:
- R3 remains readable at overview zoom and becomes richer, not emptier, at ROOM zoom.

FAIL:
- R3 is mostly empty horizontal floor with small furniture pinned to one back line;
- repeated modules expose obvious copy/paste rhythm.

### 6. Front edge must participate in the composition

A strong front edge is one reason sectional rooms read as volumes.
Use physically justified front trim / furniture / floor lip where appropriate.

Do not add arbitrary foreground clutter.
Every foreground object still requires measured `physical_z`.

PASS:
- front edge contributes to room volume while leaving actors and aisle readable.

## 006 TARGETED REWORK PRIORITY

Apply this addendum especially to:
1. Music R1/R2/R3
2. Artifact R1/R2/R3
3. Cinema R1/R2/R3
4. Workshop R1/R2/R3

Current 004 integrator review found the largest residual flatness in Music and Artifact.
Cinema and Workshop are secondary but must use the same depth contract.

## REQUIRED MACHINE EVIDENCE

For every delivered variant provide:
- front / mid / rear authored depth-band declaration;
- measured furniture Z for every station-bearing object;
- measured `physical_z` for every foreground layer;
- yaw proof at -0.15 / 0 / +0.15;
- grayscale 25% thumbnail proof;
- no-furniture shell screenshot proving shell depth remains readable;
- live-resident contact sheet after integrator mount is NOT artist-owned and will be produced by integrator.

## MACHINE PASS

006 DEPTH PASS only if all are true:
- shell depth readable without furniture: PASS;
- >=2 functional depth bands per R2/R3 variant: PASS;
- controlled overlap ordering: PASS;
- grayscale depth separation: PASS;
- R2/R3 not stretched/copy-pasted R1: PASS;
- public aisle clear: PASS;
- station approach/collision: PASS;
- all foreground has measured physical_z: PASS;
- owner_approved remains false.
