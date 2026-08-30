#!/usr/bin/env python3
"""Build the clean star-field wallpaper that sits behind the dashboard.

Same palette as starry-night-dashboard.svg, but with no UI: a slate sky whose
base tone is held at SKY_BASE (#2b3339), a soft galactic dusting and a few hot
stars. Every background tint is mixed from SKY_BASE so the rendered backdrop
stays as close to that colour as possible.
"""

from __future__ import annotations

import random
from pathlib import Path

W, H = 1920, 1080
OUT = Path(__file__).with_name("starry-night-sky.svg")
SKY_BASE = (0x2B, 0x33, 0x39)
WHITE = (0xFF, 0xFF, 0xFF)
BLACK = (0x00, 0x00, 0x00)
COOL = (0x86, 0xA6, 0xA2)
random.seed(21101984)


def mix(color, toward, t):
    return tuple(round(a + (b - a) * t) for a, b in zip(color, toward))


def hexof(color):
    return "#%02x%02x%02x" % color


def tinted(toward, t):
    return hexof(mix(SKY_BASE, toward, t))


def shifted(step):
    return hexof(tuple(min(255, max(0, v + step)) for v in SKY_BASE))


def grain_channel(tag, value):
    """Grain channel centered on the sky base so the noise neither lifts nor drops it."""
    slope = 0.25
    intercept = value / 255 - slope * 0.5
    return f'<feFunc{tag} type="linear" slope="{slope}" intercept="{intercept:.4f}"/>'


def fmt(v):
    if isinstance(v, int):
        return str(v)
    if abs(v - round(v)) < 0.05:
        return str(int(round(v)))
    return f"{v:.1f}"


def starfield_uniform():
    out = []
    colors = ("#ffffff", "#e9efec", "#fff4e1", "#d7e0df")
    weights = (0.58, 0.25, 0.09, 0.08)
    for _ in range(2800):
        x = random.uniform(2, W - 2)
        y = random.uniform(2, H - 2)
        r = random.choices([0.45, 0.6, 0.8, 1.05, 1.35, 1.7], [28, 32, 22, 11, 5, 2])[0]
        op = random.uniform(0.14, 0.55) + (r - 0.45) * 0.12
        c = random.choices(colors, weights)[0]
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{c}" '
                   f'opacity="{min(op, 0.92):.2f}"/>')
    for _ in range(46):
        x = random.uniform(20, W - 20)
        y = random.uniform(10, H - 10)
        r = random.uniform(1.25, 2.0)
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r * 3.4:.1f}" fill="#d3dedd" '
                   f'opacity="0.06"/>'
                   f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="#ffffff" opacity="0.86"/>')
    return "\n".join(out)


def galactic_band():
    out = []
    # a faint dusting of stars along a diagonal; no visible haze
    stars = []
    for _ in range(700):
        x = random.gauss(960, 360)
        y = random.gauss(430, 85)
        if not (-40 <= x <= 1960 and -40 <= y <= 1120):
            continue
        r = random.choices([0.4, 0.55, 0.7, 0.9, 1.2], [30, 32, 22, 12, 4])[0]
        op = random.uniform(0.08, 0.4)
        stars.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="#e7edec" opacity="{op:.2f}"/>')
    out.append('<g transform="rotate(-18 960 430)">' + "".join(stars) + '</g>')
    return "\n".join(out)


def sparkle(cx, cy, r, opacity=0.8):
    q = r * 0.14
    d = (f"M{cx} {cy - r} Q{cx + q} {cy - q} {cx + r} {cy} "
         f"Q{cx + q} {cy + q} {cx} {cy + r} "
         f"Q{cx - q} {cy + q} {cx - r} {cy} "
         f"Q{cx - q} {cy - q} {cx} {cy - r} Z")
    return (f'<path d="{d}" fill="#f6f8f7" opacity="{opacity}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r * 2.2}" fill="#a9c4c4" opacity="0.055"/>')



def build():
    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1920 1080"
     preserveAspectRatio="xMidYMid meet" shape-rendering="geometricPrecision">
<title>Nightfall — pure starry sky wallpaper</title>
<desc>A slate vector night sky on a #2b3339 base with thousands of stars and a faint
galactic dusting. No UI, just the wallpaper.</desc>
<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="{shifted(3)}"/>
  <stop offset="0.5" stop-color="{hexof(SKY_BASE)}"/>
  <stop offset="1" stop-color="{shifted(-3)}"/>
</linearGradient>
<radialGradient id="hazeIndigo" cx="0.5" cy="0.5" r="0.55">
  <stop offset="0" stop-color="{tinted(WHITE, 0.16)}" stop-opacity="0.05"/>
  <stop offset="0.6" stop-color="{tinted(WHITE, 0.07)}" stop-opacity="0.03"/>
  <stop offset="1" stop-color="{tinted(WHITE, 0.07)}" stop-opacity="0"/>
</radialGradient>
<radialGradient id="hazeTeal" cx="0.5" cy="0.5" r="0.55">
  <stop offset="0" stop-color="{tinted(COOL, 0.14)}" stop-opacity="0.05"/>
  <stop offset="0.65" stop-color="{tinted(COOL, 0.06)}" stop-opacity="0.02"/>
  <stop offset="1" stop-color="{tinted(COOL, 0.06)}" stop-opacity="0"/>
</radialGradient>
<radialGradient id="hazeCool" cx="0.5" cy="0.5" r="0.55">
  <stop offset="0" stop-color="{tinted(WHITE, 0.13)}" stop-opacity="0.04"/>
  <stop offset="0.65" stop-color="{tinted(WHITE, 0.05)}" stop-opacity="0.02"/>
  <stop offset="1" stop-color="{tinted(WHITE, 0.05)}" stop-opacity="0"/>
</radialGradient>
<radialGradient id="vignette" cx="0.5" cy="0.46" r="0.75">
  <stop offset="0.45" stop-color="{tinted(BLACK, 0.45)}" stop-opacity="0"/>
  <stop offset="0.8" stop-color="{tinted(BLACK, 0.45)}" stop-opacity="0.03"/>
  <stop offset="1" stop-color="{tinted(BLACK, 0.45)}" stop-opacity="0.1"/>
</radialGradient>
<filter id="grain" x="0" y="0" width="100%" height="100%" color-interpolation-filters="sRGB">
  <feTurbulence type="fractalNoise" baseFrequency="0.78" numOctaves="3" stitchTiles="stitch"/>
  <feColorMatrix type="saturate" values="0"/>
  <feComponentTransfer>
    {grain_channel("R", SKY_BASE[0])}
    {grain_channel("G", SKY_BASE[1])}
    {grain_channel("B", SKY_BASE[2])}
    <feFuncA type="linear" slope="0.11"/>
  </feComponentTransfer>
</filter>
</defs>
<rect width="1920" height="1080" fill="url(#sky)"/>
<ellipse cx="250" cy="120" rx="820" ry="460" fill="url(#hazeIndigo)"/>
<ellipse cx="1710" cy="940" rx="680" ry="400" fill="url(#hazeTeal)"/>
<ellipse cx="1220" cy="20" rx="760" ry="250" fill="url(#hazeCool)"/>
<rect width="1920" height="1080" fill="url(#vignette)"/>
{galactic_band()}
<g>{starfield_uniform()}</g>
{sparkle(278, 176, 5.5, 0.72)}
{sparkle(1692, 744, 6.5, 0.62)}
{sparkle(862, 268, 3.6, 0.6)}
{sparkle(1430, 512, 3.2, 0.55)}
{sparkle(118, 836, 4.6, 0.52)}
{sparkle(1838, 126, 3.4, 0.6)}
<rect width="1920" height="1080" filter="url(#grain)" opacity="0.4"/>
</svg>'''
    OUT.write_text(svg, encoding="utf-8")
    print(f"wrote {OUT} ({OUT.stat().st_size / 1024:.1f} KiB)")


if __name__ == "__main__":
    build()
