# Building Features: Detailed Workflow

This file contains the detailed steps for building individual SVG features. Referenced from SKILL.md Phase 2.

## Building Each Feature

For each feature:

1. **Study the reference** — examine the cropped reference image in isolation **and** the full original image for proportion context.

2. **Ask observation questions** — use `analysis/analysis-asking-questions.md` to analyze shape, color, position.

3. **Consider what's hidden** — if this feature is partially obscured by another (head under hat, face under hair), extend the shape under the obscuring element. See "Handling Obscured Content" below.

4. **Build as standalone SVG** — write to `parts/{feature-name}.svg`.

5. **Apply art style techniques:**
   - Illustrated/cartoon: `styles/styles-line-and-brush.md`
   - Flat/geometric: `styles/styles-geometric.md`
   - Photographic/realistic: `styles/styles-applying-to-lifelike.md`
   
   Read only the style file matching the style identified in Phase 1.

6. **Always read `styles/styles-curves-and-shapes.md`** — covers curve construction, filled shapes vs strokes, organic curves. This is the bridge between "what should it look like" and "how do I build it in SVG."

7. **Render and compare** — see `workflow/workflow-verification.md` for the diff loop.

## Construction Principles

**Prefer complex construction over simple geometry** (except for geometric/flat style). A filled shape built from cubic Beziers with proper width variation, per-panel lighting, and structural detail produces a more valuable result than a circle with a stroke.

Only use SVG primitives (`<circle>`, `<rect>`, `<ellipse>`) when:
- The reference image genuinely shows a perfect geometric shape
- The style is explicitly flat/geometric

When in doubt, build the more complex version — the visual quality difference is substantial.

## File Organization Rules

### One feature = one SVG file

No exceptions. Even trivially simple features (a nose that's just two dots, a sparkle, a small badge) get their own file. This keeps parts decoupled for compositing and future editing.

### Paired features are ALWAYS separate files

Left eye and right eye are separate SVGs. Same for left/right ears, left/right boots, left/right arms. Consistency is enforced in Phase 3 (Class Alignment).

### Body parts are independent

Arms are separate from the torso. Each leg is separate. The head is separate from the neck. Think of each part as something that might animate independently later.

### Shared viewBox

All features must use the same `viewBox` as the composite canvas (e.g., `viewBox="0 0 512 512"`). Position each feature within full canvas coordinates using the bounding box from the feature map. This ensures parts align without rescaling during composition.

### Interacting features

Features that interact (e.g., face + ears, hair + hat) should be noted but built independently — interactions are resolved in Phase 4. For tightly coupled features, include the neighboring feature's bounding box so you know where the boundary sits.

## References to Keep at Hand

For each feature build, have these available:

- The reference crop for the feature
- The full original image (for proportion context)
- The subject brief from Phase 1 step 7
- The identified art style description
- The relevant feature reference sheet (from `features/`)
- The relevant style technique file (`styles/styles-line-and-brush.md`, `styles/styles-geometric.md`, or `styles/styles-applying-to-lifelike.md`)
- The curve construction reference (`styles/styles-curves-and-shapes.md`) — **always included**
- The verification pipeline (`workflow/workflow-verification.md`) — **always included**
- The feature map with measured coordinates, proportion anchors, and inter-feature relationships
- The trace metadata for this feature (if available)

## Describe Features Quantitatively

Text descriptions lose visual nuance. Use measurements, not adjectives:

- **Bad:** "wide grin", "thick brim"
- **Good:** "mouth width = 55% of face width", "brim height = 5% of hat height, follows dome curvature"

Ratios survive canvas remapping; adjectives don't.

## Expression-Critical Features

Some features are disproportionately important because they define character personality or object identity. These get extra comparison rigor:

- **Mouth/smile** — the single biggest driver of expression
- **Eye gaze** — pupil position and highlight placement
- **Overall proportions** — head-to-body ratio, stance width, limb length
- **Signature features** — whatever makes this subject recognizable

For these features, always run the programmatic diff loop and iterate until convergence, even if it means exceeding 3 passes.

## Render-Compare Loop Summary

After every SVG change:

1. **Validate XML:** `xmllint --noout parts/{feature}.svg`
2. **Render to PNG:** `rsvg-convert -w 512 -h 512 parts/{feature}.svg -o parts/{feature}.png`
3. **Programmatic diff** — see `workflow/workflow-verification.md` for ImageMagick commands
4. **Read the diff image** — use highlighted differences to direct corrections
5. **Visual sanity check** — read both rendered PNG and reference crop
6. **Iterate** — fix top issue, re-render, re-diff

**When to stop iterating:**
- Normal features: 3-5 refinement passes
- Expression-critical features: up to 10 passes

**Convergence targets (RMSE, normalized 0-1):**
- Expression-critical: < 0.15
- Standard: < 0.25
- Background/simple fills: < 0.30
- Stop when two consecutive iterations improve by < 0.02

Trust the diff image over the number.

## Handling Obscured Content

When a feature is partially hidden by another layer:

- **Imagine what's underneath.** A head wearing a hat still has a complete top — extend the shape under where the hat sits, even though it won't be visible.
- **Simplify but don't omit.** The hidden portion doesn't need full detail, but the shape should be continuous. This prevents hard edges or gaps if layers shift.
- **Think in complete shapes.** A face path should be a complete closed curve, not one that stops where the hat brim sits.
