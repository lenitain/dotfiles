# File Structure & WIP Organization

## Standard Project Layout

```
{project-dir}/
├── original.png              # Source image — NEVER modify
├── feature-locations.yml     # Bounding boxes for all features (source of truth for cropping)
├── crop-tool.py              # Crop utility (from skill's scripts/ directory)
├── extract-trace-metadata.py # Metadata extraction script (from workflow-trace-metadata.md)
├── gen_{name}.py             # Deliverable: geometry → SVG, stdlib only — see "Generation Script"
├── derive_{name}.py          # Process: raster → geometry (heavy deps allowed)
├── refs/                     # Cropped reference images (generated from feature-locations.yml)
│   ├── head-full.png         # Wide crop of entire head/subject
│   ├── left-eye.png          # Tight crop per feature
│   ├── right-eye.png
│   ├── nose.png
│   ├── mouth.png
│   ├── left-ear.png
│   ├── right-ear.png
│   ├── hat.png
│   └── ...
├── parts/                    # Standalone SVGs for each feature
│   ├── face.svg              # Face shape + contour strokes + shadow
│   ├── face.png              # Latest render for comparison
│   ├── left-eye.svg
│   ├── left-eye.png
│   ├── right-eye.svg
│   ├── right-eye.png
│   └── ...
├── wip.png                   # Latest render of the composite (overwritten each iteration)
└── final.svg                 # Final composite SVG
```

## Naming Conventions

- **Reference crops:** `refs/{feature-name}.png`
- **Standalone SVGs:** `parts/{feature-name}.svg`
- **Renders of parts:** `parts/{feature-name}.png` (same name, different extension)
- **Composite WIP render:** `wip.png` (single file, overwritten each time)
- **Final output:** `final.svg`
- **Deliverable script:** `gen_{image-name}.py` — geometry → SVG, no third-party deps
- **Process script:** `derive_{image-name}.py` — raster → geometry (see "Generation Script")

## Where to Put the Project

Create a project directory adjacent to the original image. Derive the name from the image filename:

```bash
# If the original is at ~/Downloads/goblin.png → project dir is ~/Downloads/goblin-svg/
PROJECT_DIR="$(dirname "$ORIGINAL")/$(basename "$ORIGINAL" | sed 's/\.[^.]*$//')-svg"
mkdir -p "$PROJECT_DIR"/{refs,parts}
cp "$ORIGINAL" "$PROJECT_DIR/original.png"
```

If the user specifies a different output location, use that instead.

## WIP Renders

Every time you modify an SVG, render it immediately and view it:

```bash
# Check rsvg-convert is available
command -v rsvg-convert || echo "Install with: brew install librsvg (macOS) or apt install librsvg2-bin (Linux)"

# Render a standalone part
rsvg-convert -w 200 -h 200 parts/left-eye.svg -o parts/left-eye.png

# Render the composite
rsvg-convert -w 512 -h 512 final.svg -o wip.png
```

If `rsvg-convert` is not available and cannot be installed, fall back to opening the SVG in a browser for visual verification.

**Always render after every change.** Don't make multiple changes before rendering — you won't know which change caused which effect.

## Troubleshooting Render Failures

If `rsvg-convert` fails, check for these common SVG errors:
- **Missing namespace:** The root `<svg>` must include `xmlns="http://www.w3.org/2000/svg"`
- **Unclosed tags:** Every `<g>`, `<path>`, `<circle>` etc. must be closed (`/>` or `</g>`)
- **Invalid `d` attribute:** Path data must start with `M` or `m`. Common mistake: missing a space between coordinates or using commas inconsistently
- **Malformed gradients:** `<linearGradient>` and `<radialGradient>` must be inside a `<defs>` block and referenced by `id`

If the SVG is valid but renders blank, check that elements have either a `fill` or `stroke` attribute — SVG defaults to black fill with no stroke, but transparent/white elements on a white background appear invisible.

## Cleanup

- Keep `refs/` and `parts/` even after delivering the final SVG
- The user may want to adjust a single feature later
- Don't accumulate numbered versions (`wip-v1.png`, `wip-v2.png`) — overwrite `wip.png`
- Part renders (`parts/left-eye.png`) are also overwritten each iteration

## Generation Script

The recovered geometry is the product. The raster trace was a means to find it —
run once, and kept only so it can be re-run when the source changes. So delivery
is **two scripts with two different contracts**, and confusing them is the most
common way to hand over something the user cannot run.

| script | contract | dependencies |
|---|---|---|
| `gen_{name}.py` | **deliverable** — geometry → SVG. One command, done. | Python 3 standard library only |
| `derive_{name}.py` | **process** — raster → geometry. Run to re-trace. | numpy/OpenCV/vtracer as needed |

### `gen_{name}.py` — the deliverable

The canonical entry point, and the one the user will type. It carries the finished
geometry and writes the SVG from it:

- Embeds the geometry (a `SHAPES`/`STROKES` table in the file, or a data file next
  to it) — it does **not** read `original.png` or any raster
- **Standard library only.** No numpy, no OpenCV, no ImageMagick, no venv. If the
  user's plain `python3` cannot run it, it is wrong
- Optional tools stay optional: `svgo` may compact the output when present, but the
  un-compacted output must render identically
- Deterministic: same input-free run, byte-identical SVG
- `--help` works and states what it writes

Verify before delivering — with the **system** interpreter, not the project venv:

```bash
python3 gen_{name}.py /tmp/regenerated.svg
cmp /tmp/regenerated.svg final.svg && echo "reproduces the artifact exactly"
```

### `derive_{name}.py` — the process script

Re-traces geometry out of the raster (the Phase 1-4 pipeline: crop, trace metadata,
detect, polish, composite, verify) and rewrites the geometry file. Heavy deps are
fine here. It reuses the deliverable's template — one source of truth for the SVG
markup, so the two paths can never drift:

```python
import gen_goblin                       # the emitter owns the template
gen_goblin.write(doc, "final.svg")
```

Run it only when the source image, resolution, or tracing algorithm changes.

### Naming

`{name}` is the original image filename without extension (`goblin.png` →
`gen_goblin.py`, `derive_goblin.py`). Place both in the project root, alongside
`original.png`.

### Intermediate Scripts

Helper scripts written along the way (crop utilities, trace extractors, measurement
and diff tools) may stay in the project, but they are neither of the two above. The
pipeline that reads the raster is `derive_{name}.py` — **never** ship it under the
`gen_` name, and never make the deliverable depend on the source image.

## Red Flags — STOP before delivering

- The script the user runs needs a venv, `pip install`, or the source PNG
- `gen_{name}.py` opens `original.png`
- One script does both raster→geometry and geometry→SVG
- "It's fine, they just have to activate the venv first"

**All of these mean: split the emitter out of the derivation and re-verify.**
