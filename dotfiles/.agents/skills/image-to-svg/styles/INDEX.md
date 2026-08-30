# Styles Index

Style-specific SVG construction techniques. Read only the files relevant to your image's style.

## Style Identification

| File | Use When | Content |
|------|----------|---------|
| `styles-identification.md` | **Always first** — before building any feature | How to identify the art style (line work, shape language, color approach, detail level) |

## Construction Techniques by Style

| File | Use When | Content |
|------|----------|---------|
| `styles-line-and-brush.md` | Illustrated, cartoon, or hand-drawn styles | Brush stroke simulation, tapering lines, organic outlines |
| `styles-geometric.md` | Flat, minimal, or geometric styles | SVG primitives, clean edges, simple shapes |
| `styles-applying-to-lifelike.md` | Photographic, realistic, or semi-realistic styles | Realistic conversion strategies, detail preservation |

## Universal Techniques

| File | Use When | Content |
|------|----------|---------|
| `styles-curves-and-shapes.md` | **Always** — applies to all styles | Filled shapes vs strokes, cubic Bezier construction, organic curves |
| `styles-effects.md` | During composition (Phase 4) or when features need effects | `<clipPath>`, `<mask>`, `<filter>`, depth, atmosphere |

## Quick Reference

1. **Start with `styles-identification.md`** — determine the style first
2. **Always read `styles-curves-and-shapes.md`** — universal curve construction
3. **Read the matching style file:**
   - Cartoon/illustrated → `styles-line-and-brush.md`
   - Flat/geometric → `styles-geometric.md`
   - Realistic/photographic → `styles-applying-to-lifelike.md`
4. **Read `styles-effects.md`** during Phase 4 for composition effects
