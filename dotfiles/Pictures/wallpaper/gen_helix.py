#!/usr/bin/env python3
"""Generate helix.svg - vector reconstruction of /home/lenitain/Pictures/helix.png.

The image is a generative-art spiral of 37 annular sectors (15 deg each) around a center.
Each blade: fill = wedge/annular sector from the center point out to r_out (colors reach as
far inward as possible, converging at the center); stroke = only the outer arc plus the
two radial side edges, which run all the way into the center point. The 5px strokes
overlap into the only dark region (r < ~19) - the minimal hub; blade fills sit right
behind it, so no disk is needed and nothing is covered up.

Usage:
  python3 gen_svg.py                       # background = original gray
  python3 gen_svg.py --bg "#1e1e2e"        # any CSS color (theme background)
  python3 gen_svg.py --bg none             # transparent background (alpha)
  python3 gen_svg.py --bg "#1e1e2e" -o out.svg
"""
import argparse
import math
import os

W, H = 2560, 1600
CX, CY = 1398.788, 683.064
RO0, DRO = 159.7, 20.0207     # outer radius centerline: R_out(m) = RO0 + DRO*m
RIN_CLAMP = 24.0                # inner radius clamp
LEN = 478.5                     # max radial length
TH0, STEP, HALFA = 112.5, 15.0, 7.5
STROKE = 5.0
M_MIN, M_MAX = -6, 30
DEFAULT_OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "helix.svg")

def pt(r, deg):
    a = math.radians(deg)
    return (CX + r * math.cos(a), CY + r * math.sin(a))

def color(m):
    return f"rgb({99 + 2*m},{101 + 2*m},{96 + 2*m})"

def build(bg_color, out_path):
    parts = []
    parts.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">')
    if bg_color is not None:
        parts.append(f'<rect width="{W}" height="{H}" fill="{bg_color}"/>')
    shapes = []
    # draw longer blades first so the shorter (earlier-revolution) blade of each slot owns
    # the centre: its fill wedge reaches the center point; the pair joins at r_out(m).
    for m in range(M_MAX, M_MIN - 1, -1):
        th = TH0 + STEP * m
        r_out = RO0 + DRO * m
        r_in = max(0.0, r_out - LEN)
        a1, a2 = th - HALFA, th + HALFA
        x3, y3 = pt(r_out, a2)
        x4, y4 = pt(r_out, a1)
        if r_in <= 0.5:
            # fill: wedge converging at the center point
            fill_d = (f"M {CX:.2f} {CY:.2f} L {x3:.2f} {y3:.2f} "
                      f"A {r_out:.2f} {r_out:.2f} 0 0 0 {x4:.2f} {y4:.2f} Z")
        else:
            x1, y1 = pt(r_in, a1)
            x2, y2 = pt(r_in, a2)
            fill_d = (f"M {x1:.2f} {y1:.2f} A {r_in:.2f} {r_in:.2f} 0 0 1 {x2:.2f} {y2:.2f} "
                      f"L {x3:.2f} {y3:.2f} A {r_out:.2f} {r_out:.2f} 0 0 0 {x4:.2f} {y4:.2f} Z")
        shapes.append(f'<path d="{fill_d}" fill="{color(m)}"/>')
        # stroke: wedge from the center out to the outer arc (both side edges + outer arc)
        stroke_d = (f"M {CX:.2f} {CY:.2f} L {x4:.2f} {y4:.2f} "
                    f"A {r_out:.2f} {r_out:.2f} 0 0 1 {x3:.2f} {y3:.2f} L {CX:.2f} {CY:.2f}")
        shapes.append(f'<path d="{stroke_d}" fill="none" stroke="rgb(47,51,54)" stroke-width="{STROKE}"/>')
    parts.append("\n".join(shapes))
    parts.append('</svg>')
    with open(out_path, "w") as f:
        f.write("\n".join(parts))
    bg_desc = bg_color if bg_color is not None else "transparent"
    print(f"wrote {out_path} (background: {bg_desc})")

def main():
    ap = argparse.ArgumentParser(description="Generate helix.svg")
    ap.add_argument("--bg", nargs="?", const="none", default="rgb(85,87,82)",
                    help='background color (any CSS color, e.g. "#1e1e2e"; "none" = transparent)')
    ap.add_argument("-o", "--output", default=DEFAULT_OUT, help=f"output path (default: {DEFAULT_OUT})")
    args = ap.parse_args()
    bg = None if args.bg.strip().lower() in ("none", "transparent", "") else args.bg
    build(bg, args.output)

if __name__ == "__main__":
    main()
