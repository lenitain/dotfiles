---
name: wrfm
description: Use when creating, inspecting, editing, verifying, or iterating on .wrfm 3D wireframe models, or when working with wireforge wireframe assets. Use when asked to build, fix, rotate, or review a 3D wireframe shape. Requires a multimodal model that can see images.
---

# wrfm — 3D wireframe modeling (image-first)

## Overview

`.wrfm` is a plain-text format for 3D wireframe models (a `v x y z` vertex
list, an `e i j` edge list, optional `group` sections). This skill is the
operating guide for the `wrfm` CLI: generating, **seeing**, editing, and
verifying `.wrfm` models.

**Core principle: SEE the model as an image, never as terminal art.** You are
a multimodal model. The CLI renders a model to terminal text, and this skill
converts that render to a PNG image with ImageMagick — then you LOOK at the
PNG with the read tool. A real picture gives you occlusion, silhouette,
proportion, and perspective that no character art can. The wireframe is a
shape to see, not a string to parse.

The user may be watching the model live in the wireforge TUI (it hot-reloads
the file): write your edits to the watched file so they see them in real time.

## Requirements (check once when the skill loads)

| Check | Command | Failure means |
| :--- | :--- | :--- |
| wrfm CLI | `wrfm format > /dev/null` | not installed, or a stale binary (build the wrfm-cli crate from the wireforge repo) |
| ImageMagick | `magick -version` | install imagemagick |
| multimodal vision | open a PNG with the read tool and describe it | do NOT drive the main loop — use "Fallback when the image channel degrades" below |

Everything else comes from the CLI itself: `wrfm <sub> --help` per command,
and `wrfm format` for the complete file-format spec.

## See a model (the image channel)

Script: `scripts/wrfm-shot.sh` in this skill's directory (wraps
`wrfm render` + `magick`):

```bash
wrfm-shot.sh <model.wrfm> shot.png                  # all 6 standard views, one 2x3 montage
wrfm-shot.sh <model.wrfm> front.png --views front   # one view, large canvas
wrfm-shot.sh <model.wrfm> head.png --group head     # one group only (auto-fits the part)
wrfm-shot.sh <model.wrfm> zoom.png --views front --region 0.2,0.2,0.8,0.8  # magnify
wrfm-shot.sh <model.wrfm> iso.png --views "" --yaw 30 --pitch 20           # any camera
```

**After every shot, READ the produced PNG with the read tool.** If the image
is empty-looking or tiny, zoom (a single view, or a region). Re-shoot after
every edit — that is the feedback loop of this skill.

### Camera quick reference

| Want | Do |
| :--- | :--- |
| Default 6-view montage | `wrfm-shot.sh m.wrfm shot.png` — `auto_dist` on; framing follows the model's geometric-mean extent, so a thin axis fills only ~15–25% of the canvas width (a long axis can reach ~50–65%). Fine for orientation, not for detail. |
| Fill the canvas | add `--fit content` — the CLI auto-frames each view from the silhouette (padded 2%, clamped). Passes straight through `wrfm-shot.sh`. |
| Magnify a detail | shoot one view large, then `magick shot.png -trim` — **do not guess `--region`** (normalized coordinates have no reliable source; an explicit `--region` also overrides `--fit`). |
| Any camera | `--yaw 30 --pitch 20` (plus `--views ""` for a single frame); `--dist` is extremely sensitive — prefer `--fit` over hand-tuning it. |
| Angle signs / view names | One convention everywhere (CLI = wireforge TUI HUD: same signed angle = same picture). `--yaw` positive = the object turns to its **own left** (right-hand turn about +Y); `--pitch` positive = seen from above (top toward the camera). Named views promise the **object side facing the camera** (drafting): `left` = its own left side, `top` = its own top (+Y). |
| Text-mode preview | `--format grid --grid-w 32 --grid-h 16` (density numbers) or `--format ascii --width 40 --height 16` (fine text) — **text mode only**, never a PNG-shot preset |

## Image-channel integrity

The image channel's most expensive failure is *stale* output: `read` returns
a PNG, but it is an OLDER render than the file you just wrote — you then
judge the model from a picture that no longer describes it. Three rules make
that failure detectable instead of invisible:

1. **Every shot gets a NEW filename.** `wrfm-shot.py` (the implementation
   behind `wrfm-shot.sh`) refuses to overwrite an existing PNG, so a fresh
   file can never be confused with a cached one. Never reuse a shot name;
   never re-read an old file after an edit.
2. **Verify identity after every read.** Each shot stamps `# shot=<id>`
   INSIDE the image and prints the same id plus the model identity on
   stdout:

   ```text
     shot=<id>  name=<model>  vertices=<n>  edges=<m>
     VERIFY: read shot.png — its header must show name=... vertices=... shot=...
   ```

   After reading the PNG, compare three things: the `# shot=` line inside
   the image, the `name=`/`vertices=` header inside the image, and this
   stdout line. All three must agree (and agree with `wrfm info`).
3. **Mismatch = stale image.** Do not trust it, do not reason from it. Take a
   NEW filename and re-shoot; read the new file. If the mismatch persists,
   the image channel is degraded — escalate through the stackable fallback
   below ("Fallback when the image channel degrades").

## The iterate loop (do this, in this order)

1. **Facts first.** `wrfm info m.wrfm` and `wrfm geometry m.wrfm` — scale,
   topology, symmetry, orientation as JSON numbers. Never skip this.
2. **See it.** `wrfm-shot.sh m.wrfm shot.png`, then read shot.png.
3. **Zoom.** One view at a large canvas, or a region, until you understand the
   shape; `wrfm group m.wrfm` names the parts (head / feet / ...).
4. **Edit.** `wrfm transform` / `wrfm edit` via shell pipes (§Edit a model).
   Never hand-edit coordinates.
5. **Health gate.** `wrfm check` after EVERY edit (then re-shoot and look).
   `ok` = deliverable as-is. `broken` = fix before delivering. `warn` = judge
   the listed problems first — see "Judging a warn verdict" below.
6. **Intent gate.** `wrfm verify m.wrfm --expect-size ... --expect-center ...`
   against the intent you declared before editing.
7. **Diff.** `wrfm diff m.wrfm m_v2.wrfm --format json` to see exactly what
   changed between versions.

### Judging a `warn` verdict

`wrfm check` prints every problem by index (e.g. `edge [24, 25] ... touches
degree-1 vertex 24`). Indices alone say nothing about intent — map them:

1. **Coordinates** — `wrfm query m.wrfm vertices --range 24,29`.
2. **Where that is on the object** — `wrfm-shot.sh m.wrfm shot.png` and look
   at the render.
3. **What that part is** — if the model has a generator script
   (`references/wrfm_generator/`), its source names the parts (e.g.
   `side flush lever (24-29)`).

Then decide:

- **Deliberate detail** (a lever, handle, hanging piece, opening drawn as an
  open line, a plain ring) → **keep it**. Real objects are full of parts that
  are open by nature; closing them makes the model look worse, not better.
- **Accidental gap** (a line that should connect but does not) → **fix it**.
- **Near-duplicate vertices** (the `near_duplicate_vertices` list: two
  points closer than 1e-6) → **always fix** with
  `wrfm edit m.wrfm --weld 1e-6`. Two points that close are one point, and
  `--dedupe` is bit-exact, so it cannot see them.

## Edit a model (CLI, never by hand)

The CLI never writes files — it streams the result to stdout, so edits are
shell pipes. The output is verified by the CLI before printing; you redirect
it to a NEW file and re-verify:

```bash
wrfm transform m.wrfm --rotate-y 45 --scale 1.5 > m_v2.wrfm   # affine ops
wrfm edit m.wrfm --delete-vertices 0,3 > m_v2.wrfm            # topology ops
wrfm edit m.wrfm --extract-group head > head.wrfm             # extract a part
wrfm transform m.wrfm --to-origin --normalize 2 > m_norm.wrfm # recentre + rescale
```

Compose with pipes: `wrfm edit m.wrfm --extract-group body | wrfm transform - --scale 2`.

Rules:
- **Small edits (rotate/scale/translate/mirror) → `wrfm transform`** (reliable
  math, keeps groups).
- **Structure changes (vertex/edge counts) → `wrfm edit`** (delete vertices,
  delete edges, extract a group, clean, dedupe). Exactly ONE operation per call.
- **Never edit vertex coordinates by hand.** If you think you need to, you
  need a transform — or the model needs regenerating.
- `wrfm check` the output file before you use it.

## Reference library (references/) — copy, never invent

The repo ships finished sample models and the Python scripts that generated
them. For any real object (appliance, vehicle, furniture, ...), consult the
library BEFORE writing anything:

| Object | Sample asset | Generator script |
| :--- | :--- | :--- |
| anvil | `references/wrfm_assets/anvil.wrfm` | `references/wrfm_generator/gen_anvil.py` |
| bicycle | `references/wrfm_assets/bicycle.wrfm` | `references/wrfm_generator/gen_bicycle.py` |
| microwave | `references/wrfm_assets/microwave.wrfm` | `references/wrfm_generator/gen_microwave.py` |
| toilet | `references/wrfm_assets/toilet.wrfm` | `references/wrfm_generator/gen_toilet.py` |
| vintage TV | `references/wrfm_assets/vintage_tv.wrfm` | `references/wrfm_generator/gen_vintage_tv.py` |
| washing machine | `references/wrfm_assets/washing_machine.wrfm` | `references/wrfm_generator/gen_washing_machine.py` |

Rules:

- **Sample matches your object, or shares parts with it? READ both the asset
  and its generator, and COPY the structure** — named groups per part
  (`base`/`body`/`face`/`horn`/`holes`, `wheels`/`frame`/`saddle`, ...),
  Y-up, ground at y=0, front facing +Z, ring/hub/spoke and box/connect-ring
  topology patterns. Pattern-match the samples instead of free-inventing
  topology.
- **Complex models are scripted, not hand-written.** Anything with more than
  ~50 vertices or several parts belongs in a generator script like the
  `gen_*.py` samples — a `WrfmModel` helper (`add` / `edge` / `cycle` /
  `ring` / `box8` / `connect_ring` / `begin_group` / `end_group` / `write`).
  Run the script, then `wrfm check` the output. Hand-writing `.wrfm` is only
  for small models (the archetypes below).
- If you adapt a generator, keep its output healthy: `wrfm check` after
  every run, before you deliver the asset.

## Generate a model (from scratch)

Get the exact spec from the CLI: `wrfm format`. Minimal example (unit box):

```
wrfm 1
vertices 8   edges 12
v 0 0 0    v 1 0 0    v 1 0 1    v 0 0 1
v 0 1 0    v 1 1 0    v 1 1 1    v 0 1 1
e 0 1   e 1 2   e 2 3   e 3 0
e 4 5   e 5 6   e 6 7   e 7 4
e 0 4   e 1 5   e 2 6   e 3 7
```

Archetypes — copy these structures, never free-invent topology (`.wrfm` has
almost no training data; pattern-match these instead):

- **BOX** — 8 vertices / 12 edges: two 4-vertex rings (base + top) + 4
  vertical edges; every vertex degree 3 (as above).
- **PRISM (n-gon cylinder)** — 2n vertices / 3n edges: two n-gon rings (cap +
  cap) + n side edges; every vertex degree 3. n=6 → 12 vertices / 18 edges.
- **RING (torus approx, k segments)** — 2k vertices / 3k edges: k edges per
  circle + k connectors; every vertex degree 3. k=8 → 16 vertices / 24 edges.

**Health standard**: the archetypes are closed surfaces — every vertex
degree >= 3, every edge in at least one cycle, no open chains, no dangling
ends. If your shape is not one of these, still build it from closed rings +
connectors. This is the standard for SOLID primitives; real objects with
deliberate open detail (handles, levers, hanging pieces, openings) legitimately
fall to `warn` — judge it, don't blindly "fix" it (see "Judging a `warn`
verdict"). Only accidental gaps must be repaired before finishing.

**Generation chain**: consult the reference library first (§Reference
library) — a matching sample or generator is copied/adapted, not reinvented
→ write the file or run a generator script → **`--clean | --dedupe`
(mandatory for generated output)** → `wrfm check` → `wrfm geometry`
→ `wrfm-shot.sh` + read the PNG → iterate. Always build standing on Y
with the semantic front on +Z (Conventions below).

Fixed recipe for the clean/dedupe step:

```bash
wrfm edit gen.wrfm --clean | wrfm edit - --dedupe > final.wrfm
wrfm check final.wrfm
```

**Always `--clean | --dedupe` before `check`.** Anything generated —
especially data sampled onto a surface — carries degree-1 sampling stubs
(vertices left at parameterization folds, e.g. 23 of them on the Utah
teapot), which are sampling residue, not model geometry. If you skip this
step, a good part of the dangling vertices `check` reports are stubs your own
script created, and you will chase them (or hand-write pruning loops with
index remapping) for nothing. `wrfm edit --clean` exists precisely for this;
`--dedupe` removes the coincident points the sampling also produces.

## Model from real data (external datasets)

When the target comes from real data (OBJ meshes, Bezier patch files like
`.bpt`, point dumps) instead of the reference library, there is **no
`wrfm import`** — parsing and sampling stay in a skill-side Python script.
What the CLI *does* provide is the hard part: welding sampled coordinates
together. Pipeline:

1. **Parse the source format in Python** (one-off script; Bernstein-basis
   evaluation for Bezier patches, plain reader for OBJ/points).
2. **Sample into wireframe vertices + edges** (grid lines on curves/surfaces).
   Emit one `.wrfm` with everything in a group.
3. **Weld the seams**: adjacent patches share boundaries mathematically, but
   independently sampled coordinates differ (~1e-15). Exact `--dedupe` cannot
   see those:

   ```bash
   wrfm edit raw.wrfm --weld 1e-6 > welded.wrfm
   ```

   `--weld <tol>` merges vertices strictly closer than `tol` (first-touch
   group assignment — a vertex lives in exactly one group) and runs the same
   duplicate/zero-length cleanup as `--dedupe`. `--weld 1e-6` is the repair
   for what `wrfm check` reports as near-duplicate vertices (same 1e-6
   threshold as the CLI's point identity).
4. **Clean sampling residue**: `wrfm edit welded.wrfm --clean | wrfm edit - --dedupe`
   (degree-1 stubs at parameterization folds; see the generation chain above).
5. **Normalize for the consumer**: ground at y=0 or bbox-centered via
   `wrfm transform`, then `wrfm check` and declare intent +
   `wrfm verify`.

Degenerate points that are *inherent to the data* (e.g. whole control rows
collapsing to a pinch point on Bezier tips) will surface as `warn` — judge
them with "Judging a `warn` verdict"; do not "fix" correct geometry.

## Conventions

- **Y-UP**: +Y is vertical (height); X and Z form the ground. Build standing
  models. If the geometry report shows a lying-down model, REWRITE it — never
  rotate it afterwards.
- **FRONT = +Z**: the object's semantic face — appliance door, TV screen,
  nose, spout, horn, front wheel — must face +Z, so the `front` view shows
  that face and the left–right extent lives on X (every
  `references/wrfm_assets/` sample follows this). A front built on ±X or −Z
  is fixed with `wrfm transform --rotate-y` — Y-up and the ground are
  preserved.
- Ground at y=0 unless the intent says otherwise.
- **Declare intent before editing** (size, center, symmetry, closedness), then
  `wrfm verify` against it.

## Quick reference

| Task | Command |
| :--- | :--- |
| Facts (scale/topology/symmetry) | `wrfm info m.wrfm` · `wrfm geometry m.wrfm` |
| Parts (groups) | `wrfm group m.wrfm` |
| See the shape | `wrfm-shot.sh m.wrfm shot.png` + read the PNG |
| Fill the canvas / frame | `wrfm-shot.sh m.wrfm shot.png --fit content` (see "Camera quick reference") |
| Reference library | `references/wrfm_assets/` (sample assets) · `references/wrfm_generator/` (their generators) — copy, never invent |
| Exact occlusion/outline numbers | `wrfm view m.wrfm --pitch 30 --yaw 45` |
| Health | `wrfm check m.wrfm` (add `--strict` for zero tolerance) |
| Intent | `wrfm verify m.wrfm --expect-size 2,2,2` |
| Transform / topology edit | `wrfm transform ...` · `wrfm edit ...` (their `--help`) |
| Weld near-duplicate vertices | `wrfm edit m.wrfm --weld 1e-6` (tolerance merge, then dedupe cleanup) |
| Diff | `wrfm diff a.wrfm b.wrfm --format json` |
| Safe queries | `wrfm query m.wrfm profile` (also cross_section, vertices, distance, connectivity) · summaries: `wrfm geometry m.wrfm` (.bounds / .topology / .edge_lengths) |
| Format spec | `wrfm format` |

## Fallback when the image channel degrades (stackable)

Degradation is not only "I cannot see images" — the common and expensive
form is **half-working**: `read` returns a picture, but it is an older one
(see "Image-channel integrity"). Escalate through three steps; they stack
(stop as soon as one works):

1. **Re-shoot under a NEW filename** and check the `shot=` identity inside
   the image against the stdout line. A single mismatch is not yet a verdict
   — a fresh name usually clears it.
2. **Still mismatched → run text mode IN PARALLEL with the image**:
   `wrfm render m.wrfm --format grid` (digit density — numbers are the LLM's
   native language) and `--format ascii` for small canvases, plus facts from
   `wrfm view` / `wrfm query` instead of render text. Keep shooting and
   reading images if they help, but DECIDE from the text: text output is not
   stale. Where image and text disagree, the text conclusion wins.
3. **Tell the user explicitly that the image channel is abnormal** — which
   shots mismatched, what you fell back to, and that this skill's image-first
   loop is currently degraded for you.

If you cannot see images at all (no multimodal vision), start at step 2 and
say so. This is a degraded mode: the image loop is strictly better.

## Common mistakes

- **Hand-editing vertex coordinates** → use `wrfm transform` / `wrfm edit`.
- **Editing without `wrfm check`** → run it after every edit, before delivery.
- **Rendering but never reading the PNG** → a render you don't look at is a
  test you don't read.
- **Building lying-down models** → Y-UP: rewrite, don't rotate.
- **Front on the wrong axis** (door/screen/nose built on ±X or −Z) → the
  `front` view must show the object's face: rebuild facing +Z or fix with
  `wrfm transform --rotate-y`.
- **Parsing render text instead of looking at the image** → you are
  multimodal; the image IS the render.
- **Guessing flags** → `wrfm render --help` (or any `wrfm <sub> --help`)
  before guessing; the CLI self-describes.
