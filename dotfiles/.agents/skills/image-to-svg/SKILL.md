---
name: image-to-svg
description: 'Recreate a raster image as SVG by isolating features, building each as a standalone layer, then compositing. Use to vectorize photos, illustrations, or AI art, or to extract specific elements as scalable graphics.'
---

# Image to SVG

Recreate raster images as high-quality SVGs by decomposing, studying, and rebuilding each visual element independently.

## Core Principles

**Never try to reproduce the whole image at once.** The quality comes from isolating each feature, studying it closely against a cropped reference, and building it as a standalone SVG before compositing.

**Correctness over speed.** Every shortcut in this workflow compounds into visible quality loss in the final output. Batching crop verification, skipping programmatic checks, eyeballing coordinates instead of measuring, settling for "looks about right" instead of running the diff — each saves a minute but costs ten in rework or produces a visibly worse result. The value of this skill is in the output quality. Take the time to verify at every step.

## When to Use

- Converting an image (photo, illustration, AI art) to SVG
- Creating vector versions of logos, mascots, icons, or artwork
- Extracting specific elements from images as scalable graphics
- The user provides a reference image and wants an SVG recreation

## Instructions

You are converting a raster image into an SVG recreation. Follow the phases below in order.

### File Loading Guide

This skill uses **incremental discovery** — reference files live in subdirectories adjacent to this skill (`analysis/`, `features/`, `styles/`, `workflow/`). Read them only when a specific phase or condition calls for them. **Do not read all reference files upfront.**

| Phase | Files to Read |
|-------|---------------|
| Phase 0 | `workflow/workflow-dependencies.md` |
| Phase 1 | `styles/styles-identification.md`, `analysis/analysis-asking-questions.md`, `analysis/analysis-identifying-concepts.md`, `analysis/analysis-reference-crops.md`, `workflow/workflow-verification.md` (measurement section), `workflow/workflow-trace-metadata.md` (if vtracer available) |
| Phase 2 | `styles/INDEX.md` (to identify which style file), `styles/styles-curves-and-shapes.md` (always), `features/INDEX.md` (to identify which feature files), `workflow/building-features.md`, `workflow/workflow-verification.md` (diff loop) |
| Phase 3 | No new files — compare features built in Phase 2 |
| Phase 4 | `workflow/composition-bringing-layers-together.md`, `styles/styles-effects.md`, `workflow/pixel-perfect-verification.md` |
| Phase 5 | `workflow/workflow-file-structure.md` |

---

### Phase 0: Environment Setup

Read `workflow/workflow-dependencies.md` and run the dependency check script. Ensure required tools (`magick`, `rsvg-convert`, `xmllint`) are available. For optional tools (`vtracer`, `svgo`), check availability and note which enhancements are possible.

**Installation Policy: NEVER install tools globally.** All tools must be installed to the project directory or user-local paths. No `npm install -g`, no system-wide `pip install`, no `cargo install` to default global location. Project-local installs are self-contained and don't require elevated privileges.

If `vtracer` is not installed and Rust/Cargo is available, install it to the project directory: `cargo install vtracer --root "$PROJECT_DIR/.cargo"`.

### Phase 1: Analyze the Image

**Initial analysis:**

1. **Identify the art style.** Read `styles/styles-identification.md`, study the image, and determine the style classification and reasoning (line work, shape language, color approach, detail level). The identified style determines which techniques you'll use later.
2. **Build your observation framework.** Read `analysis/analysis-asking-questions.md`, study the image, and answer the key observation questions — especially the Construction and Structural questions for complex objects. This report informs the decomposition step.
3. **Handle transparency.** Check programmatically: `magick identify -format "%[channels]" original.png` — if it reports `srgba` or similar alpha channel, note whether the transparent background should be preserved in the final SVG (common for emoji/stickers) or filled with a solid color.

**Decompose** — depends on the observation framework above:

4. **Decompose into features.** Read `analysis/analysis-identifying-concepts.md`. Break the image into independent visual elements and establish a z-order (layer stack).

**Preparation** — these all depend on the feature list from step 4:

5. **Create and verify reference crops.** Read `analysis/analysis-reference-crops.md`. Write `feature-locations.yml` with bounding boxes for every feature, then crop all features from it in one pass. **Run the programmatic edge-margin check on every crop** — this is the most common failure point. Fix any failing crops by adjusting the YAML and re-cropping (don't re-estimate from the image). Then visually verify each crop individually (one per Read call, not batched). Do not proceed to the build phase with any clipped crops.

6. **Measure and map coordinates programmatically.** Read `workflow/workflow-verification.md` for the measurement pipeline. Do NOT eyeball feature coordinates — small estimation errors compound across features and ruin proportions.
   - Determine canvas size (512x512 standard for emoji/icons; use original aspect ratio for other subjects)
   - Use ImageMagick to measure the original image dimensions and compute the scale factor to canvas
   - Identify **proportion anchors**: 3-5 key measured points (e.g., "head center at 35% of character height, chin at 52%, feet at 95%"). Express as ratios, not absolute pixels — ratios survive the canvas remapping.
   - Compute each feature's bounding box by measuring from the original and scaling to canvas coordinates
   - Record **inter-feature relationships** — not just individual bounding boxes but how features relate: "mouth width = 55% of face width", "gap between boots = 15% of body width", "ears extend 20% past hat brim edge". These relative measurements are what make proportions look right when features are built independently.
   - Record the feature map with measured coordinates, proportion ratios, relationships, and z-ordering.

7. **Write a subject brief.** In 2-3 sentences, describe the personality, expression, and overall vibe of the subject ("a cheeky, confident goblin with a big happy grin and a proud crossed-arms stance"). This qualitative description guides the *feeling* of the subject, not just the geometry. Without it, features end up technically correct but lack the character's personality.

**After crops are verified** (step 5 must complete first):

8. **Extract trace metadata from crops.** If `vtracer` is available, read `workflow/workflow-trace-metadata.md`. Auto-trace each feature crop in polygon mode and extract structured metadata: color palettes, sub-element positions/sizes, area percentages, and topology hints. This provides precise numeric data (~130 tokens per feature) instead of eyeballing colors and positions from the raster image. Add the trace metadata to each feature's entry in the feature map.

   If `vtracer` is not available, fall back to ImageMagick color extraction:
   ```bash
   magick refs/{feature}.png -resize 200x200 -kmeans 10 -unique-colors txt: | tail -n +2 | tr -s ' ' | cut -d' ' -f3
   ```
   This gives accurate hex values but no spatial sub-element data.

### Phase 2: Build Each Feature

Once the style is identified, reference crops verified, and the feature map established, build each feature sequentially. Each feature is independent — work from its reference crop, study it, and construct the SVG.

#### Character/face images

For character or face images, read the relevant feature reference sheet from `features/` before building each element:

| Feature | Reference file |
|---|---|
| Eyes | `features/features-eyes.md` |
| Mouth | `features/features-mouth.md` |
| Nose | `features/features-nose.md` |
| Ears | `features/features-ears.md` |
| Face shape | `features/features-face-shape.md` |
| Hair | `features/features-hair.md` |
| Body | `features/features-body.md` |
| Accessories | `features/features-accessories.md` |
| Complex objects (held items, props) | `features/features-objects.md` |

Only read the reference sheets for features that exist in the image.

#### Non-character images (landscapes, logos, objects, abstract)

The `features/` reference sheets are character-specific. For other subjects, decompose by visual layer instead:

- **Logos/icons:** background shape, primary symbol, text (as traced paths — do not use `<text>` elements, since fonts won't match), secondary elements, border/frame
- **Landscapes/scenes:** sky/background, distant elements, midground, foreground, focal subject, atmospheric effects (fog, light rays)
- **Objects/products:** Read `features/features-objects.md` for detailed guidance on structural decomposition. Objects have internal structure, multiple visible surfaces, and perspective complexity that goes far beyond silhouette + fill. Decompose into structural parts (panels, ribs, joints, handles), not just color regions.
- **Vehicles/machines:** Read `features/features-vehicles.md`. Vehicles are panel assemblies — decompose by body panels, glass, wheels, lights, and trim. Panel lines and metallic gradients are critical.
- **Food/drinks:** Read `features/features-food.md`. Shape-building approach with glossy highlights, layered construction, and steam/aroma effects.
- **Plants/flowers:** Read `features/features-plants.md`. Radial petal symmetry with `<use>` + `rotate`, leaf construction with vein clipping.
- **Abstract/patterns:** base layer, repeating motifs (use `<pattern>` or `<use>` where possible), accent elements, overlay effects
- **Hybrid images:** For images that combine categories (character holding an object in a landscape), use the focal subject's decomposition as primary and treat secondary elements more simply.

The same principles apply: one crop per element, one standalone SVG per layer, same composite viewBox. Read `analysis/analysis-asking-questions.md` for each element — the shape, color, and position questions are universal.

#### Expression-critical features

Some features are disproportionately important because they define the character's personality or the object's identity. These get **extra comparison rigor** — more iteration passes, programmatic diff verification, and side-by-side checks before moving to composition:

- **Mouth/smile** — the single biggest driver of expression. Curvature, width, and upturn at corners must match closely.
- **Eye gaze** — pupil position and highlight placement determine where the character is looking and how it "feels."
- **Overall proportions** — head-to-body ratio, stance width, limb length. If these are off, no amount of detail fixes the result.
- **Signature features** — whatever makes this specific subject recognizable (a distinctive hat, a specific logo, a unique silhouette).

For these features, always run the programmatic diff (see "Render-Compare Loop" below) and iterate until the diff score converges, even if it means exceeding 3 passes.

#### Building each feature

Read `workflow/building-features.md` for the detailed build workflow, construction principles, file organization rules, and the render-compare loop.

**Key principles (summary):**
- One feature = one SVG file, no exceptions
- Paired features (left/right) are always separate files
- All features use the same `viewBox` as the composite canvas
- Prefer complex construction over simple geometry (except for geometric/flat style)
- Describe features quantitatively, not qualitatively
- Expression-critical features (mouth, eyes, proportions, signature features) get extra iteration

#### Handling Obscured Content

When a feature is partially hidden by another layer, extend the shape underneath (simplified but continuous). See `workflow/building-features.md` for details.

### Phase 3: Class Alignment

After all features are built individually, check paired and repeated features for consistency.

A "class" is a group of features that should share the same construction style:
- **Eyes class** — left eye + right eye
- **Ears class** — left ear + right ear
- **Boots/shoes class** — left boot + right boot
- **Arms class** — left arm + right arm (if pose shows both)
- **Any other repeated elements** — e.g., both wheels of a bike, multiple windows on a building

For images with multiple subjects, classes are per-subject: "character A eyes" and "character B eyes" are separate classes.

For each class, compare both SVGs, both reference crops, and the full original image, and check:

1. **Outline weight** — are paired features using the same stroke width or offset technique? (Most likely to drift between independent builds)
2. **Absolute size** — are they the same size, or intentionally different per the reference?
3. **Fill colors** — do both use exactly the same hex values?
4. **Construction technique** — did one use ellipses while the other used paths? This creates visual inconsistency even if dimensions match.
5. **Highlight count and position** — highlights are the most "creative" part and most likely to vary between builds.
6. **Proportional placement** — "both eyes should be equidistant from face center" type checks.

Normalize any unintentional inconsistencies — make paired features match while preserving intentional asymmetry from the reference (e.g., if the reference genuinely shows different-sized eyes, keep that).

### Phase 4: Composite and Iterate

Read `workflow/composition-bringing-layers-together.md`.

**This phase is not optional.** The first assembly is never the final output. Individual features built in isolation always have proportion and alignment issues that only become visible in context.

1. **Assemble** — combine standalone SVGs into the composite
2. **Apply effects** — read `styles/styles-effects.md` for `<clipPath>`, `<mask>`, and `<filter>` where needed
3. **Diff the composite against the original** — use the full-image programmatic diff from `workflow/workflow-verification.md`. This highlights exactly where the composite diverges from the original.
4. **Identify the top 3 discrepancies** from the diff — usually proportion errors (head too small, features shifted), expression mismatches (mouth curvature, gaze direction), or interaction issues (hat sitting wrong, limbs overlapping incorrectly).
5. **Fix each discrepancy** — fix directly in the feature SVG or the composite SVG. Re-render and re-diff after each fix.
6. **Repeat** until the composite diff stabilizes — at least 2 composite iterations, more if expression-critical features are off.
7. **Final small-size check:**
   ```bash
   rsvg-convert -w 64 -h 64 final.svg -o /tmp/small-check-64.png
   rsvg-convert -w 128 -h 128 final.svg -o /tmp/small-check-128.png
   ```
   Read both renders — does it still read clearly at icon size? Features that looked fine at 512px may merge or disappear.

8. **Pixel-perfect verification (final gate):** Read `workflow/pixel-perfect-verification.md`. The rendered SVG must match the original image pixel-for-pixel (AE = 0). This is a hard requirement before delivery.

### Phase 5: Deliver

Read `workflow/workflow-file-structure.md` for the expected project layout.

1. **Optimize the final SVG.** If `svgo` is available, run it with `cleanupIds` disabled to preserve named groups:
   ```bash
   svgo final.svg -o final.svg \
     --config='{"plugins":[{"name":"preset-default","params":{"overrides":{"cleanupIds":false,"collapseGroups":false,"convertShapeToPath":false}}}]}'
   ```
   This typically reduces file size by 25-40% (numeric precision, default attributes, path command optimization) without changing the visual output. If `svgo` is not available, skip this step — the SVG is still valid.
   Minification belongs to the emitter of step 5, not to a manual pass: if you compact by hand and the script does not, the script can no longer reproduce the artifact.

2. Keep the `parts/` directory with standalone SVGs for future edits
3. Provide the final composite SVG
4. Render a PNG at the target resolution for comparison
5. **Split delivery into two scripts.** The recovered geometry is the product; the raster trace was the means to find it.
   - `gen_{name}.py` — **the deliverable.** Geometry (embedded table or a data file beside it) → `final.svg`. Python standard library only, never opens the source raster, deterministic. The user's plain `python3 gen_{name}.py` must work — if it needs a venv or `pip install`, it is the wrong script.
   - `derive_{name}.py` — **the process script.** Raster → geometry (crop, trace metadata, build, composite, verify). Heavy deps allowed; it imports the deliverable's template so the two cannot drift.
   - Verify with the **system** interpreter: `python3 gen_{name}.py /tmp/r.svg && cmp /tmp/r.svg final.svg`
   - See `workflow/workflow-file-structure.md` for the full contract and red flags.
