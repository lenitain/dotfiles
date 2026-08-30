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
| multimodal vision | open a PNG with the read tool and describe it | do NOT drive the main loop — use the Text-mode fallback |

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
| anvil | `references/wrfm_assests/anvil.wrfm` | `references/wrfm_generator/gen_anvil.py` |
| bicycle | `references/wrfm_assests/bicycle.wrfm` | `references/wrfm_generator/gen_bicycle.py` |
| microwave | `references/wrfm_assests/microwave.wrfm` | `references/wrfm_generator/gen_microwave.py` |
| toilet | `references/wrfm_assests/toilet.wrfm` | `references/wrfm_generator/gen_toilet.py` |
| vintage TV | `references/wrfm_assests/vintage_tv.wrfm` | `references/wrfm_generator/gen_vintage_tv.py` |
| washing machine | `references/wrfm_assests/washing_machine.wrfm` | `references/wrfm_generator/gen_washing_machine.py` |

Rules:

- **Sample matches your object, or shares parts with it? READ both the asset
  and its generator, and COPY the structure** — named groups per part
  (`base`/`body`/`face`/`horn`/`holes`, `wheels`/`frame`/`saddle`, ...),
  Y-up, ground at y=0, ring/hub/spoke and box/connect-ring topology
  patterns. Pattern-match the samples instead of free-inventing topology.
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
→ write the file or run a generator script → `wrfm check` → `wrfm geometry`
→ `wrfm-shot.sh` + read the PNG → iterate. Always build standing on Y
(below).

## Conventions

- **Y-UP**: +Y is vertical (height); X and Z form the ground. Build standing
  models. If the geometry report shows a lying-down model, REWRITE it — never
  rotate it afterwards.
- Ground at y=0 unless the intent says otherwise.
- **Declare intent before editing** (size, center, symmetry, closedness), then
  `wrfm verify` against it.

## Quick reference

| Task | Command |
| :--- | :--- |
| Facts (scale/topology/symmetry) | `wrfm info m.wrfm` · `wrfm geometry m.wrfm` |
| Parts (groups) | `wrfm group m.wrfm` |
| See the shape | `wrfm-shot.sh m.wrfm shot.png` + read the PNG |
| Reference library | `references/wrfm_assests/` (sample assets) · `references/wrfm_generator/` (their generators) — copy, never invent |
| Exact occlusion/outline numbers | `wrfm view m.wrfm --pitch 30 --yaw 45` |
| Health | `wrfm check m.wrfm` (add `--strict` for zero tolerance) |
| Intent | `wrfm verify m.wrfm --expect-size 2,2,2` |
| Transform / topology edit | `wrfm transform ...` · `wrfm edit ...` (their `--help`) |
| Diff | `wrfm diff a.wrfm b.wrfm --format json` |
| Safe queries | `wrfm query m.wrfm extents` (also topology, edge_stats, profile, cross_section, vertices, distance, connectivity) |
| Format spec | `wrfm format` |

## Text-mode fallback (ONLY if you cannot see images)

If you cannot read images, the main loop is unavailable — say so to the user,
then use the cheapest text forms: `wrfm render m.wrfm --format grid` (digit
density grid — numbers are the LLM's native language) and `--format ascii`
for small canvases; reason from `wrfm view` / `wrfm query` facts instead of
render text. This is a degraded mode: the image loop is strictly better.

## Common mistakes

- **Hand-editing vertex coordinates** → use `wrfm transform` / `wrfm edit`.
- **Editing without `wrfm check`** → run it after every edit, before delivery.
- **Rendering but never reading the PNG** → a render you don't look at is a
  test you don't read.
- **Building lying-down models** → Y-UP: rewrite, don't rotate.
- **Parsing render text instead of looking at the image** → you are
  multimodal; the image IS the render.
- **Guessing flags** → `wrfm render --help` (or any `wrfm <sub> --help`)
  before guessing; the CLI self-describes.
