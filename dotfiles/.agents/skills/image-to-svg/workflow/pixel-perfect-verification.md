# Pixel-Perfect Verification

The strictest verification gate. The rendered SVG must match the original image pixel-for-pixel.

**Principle:** SVG → PNG (via `rsvg-convert`) → compare with original. If the rendered bitmap doesn't match the original, the SVG is wrong.

**When to use:** After composite iterations converge (Phase 4) and before delivery (Phase 5).

## Prerequisites

```bash
command -v magick || echo "Install: brew install imagemagick (macOS) or apt install imagemagick (Linux)"
command -v rsvg-convert || echo "Install: brew install librsvg (macOS) or apt install librsvg2-bin (Linux)"
```

## Verification Steps

### Step 1: Get original image dimensions

```bash
ORIG_W=$(magick identify -format "%w" original.png)
ORIG_H=$(magick identify -format "%h" original.png)
```

### Step 2: Render SVG at original dimensions

```bash
rsvg-convert -w "$ORIG_W" -h "$ORIG_H" final.svg -o /tmp/final-pixel-perfect.png
```

**Why original dimensions, not canvas size?**
- Canvas size (e.g., 512x512) is an intermediate working resolution
- The final output must match the source image dimensions
- Rendering at different dimensions introduces scaling artifacts
- Pixel-perfect comparison requires identical dimensions

### Step 3: Compare pixel-by-pixel

```bash
magick compare -metric AE original.png /tmp/final-pixel-perfect.png null: 2>&1
```

This returns the Absolute Error (AE) — the count of pixels that differ.

- **AE = 0**: Perfect match, proceed to delivery
- **AE > 0**: Differences found, must fix

### Step 4: If AE > 0, diagnose and fix

1. **Generate diff image:**
   ```bash
   magick compare original.png /tmp/final-pixel-perfect.png /tmp/pixel-diff.png
   ```

2. **Read the diff image:** Red/bright areas show where pixels differ.
   - Red along edges → shape/position error
   - Red in interior → color fill error
   - Red in details → stroke/gradient error

3. **Identify root cause:** Which feature SVG is responsible for the differing area?

4. **Fix the feature:** Go back to `parts/{feature}.svg`, correct the issue, re-render the feature.

5. **Re-composite:** Rebuild `final.svg` with the fixed feature.

6. **Re-verify:** Repeat Steps 1-4 until AE = 0.

## Hard Gate

**AE must be 0 before delivery.** This is non-negotiable.

If after multiple fix cycles AE still > 0, investigate:
- Is the rendering tool (`rsvg-convert`) introducing artifacts?
- Are there SVG features that don't render deterministically?
- Is the original image itself inconsistent (e.g., JPEG compression artifacts)?

**Note:** This verification validates the SVG against the toolchain you control. Different renderers (Chrome, Safari, Inkscape) may produce different results. The goal is consistency with `rsvg-convert`, which is the skill's standard rendering tool.
