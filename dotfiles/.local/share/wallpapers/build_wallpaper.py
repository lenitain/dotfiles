#!/usr/bin/env python3
"""Build a starry-night, glass-dashboard vector wallpaper (SVG).

Inspired by a desktop screenshot: a dense star field behind translucent
dark panels, monospaced type, music/artist rails and small warm accents.
Everything is generated as pure SVG (no raster assets, no external links).
"""

from __future__ import annotations

import math
import random
from pathlib import Path

W, H = 1920, 1080
OUT = Path(__file__).with_name("starry-night-dashboard.svg")

MONO = ("'Maple Mono NL NF CN','JetBrains Mono','Cascadia Mono','Noto Sans Mono',"
        "Consolas,'DejaVu Sans Mono',monospace")
SANS = "'Adwaita Sans','Cantarell','DejaVu Sans',sans-serif"

INK = "#e2e6e4"
MUTED = "#98a2a2"
MINT = "#a9d6d0"
GOLD = "#d9b56b"

random.seed(20260422)


# ------------------------------------------------------------------ helpers

def fmt(value: float) -> str:
    if isinstance(value, int):
        return str(value)
    if abs(value - round(value)) < 0.05:
        return str(int(round(value)))
    return f"{value:.1f}"


def T(x, y, content, size=12, fill=INK, anchor="start", weight=400, ls=None,
      family=MONO, opacity=None, extra=""):
    attrs = [f'x="{fmt(x)}"', f'y="{fmt(y)}"', f'font-family="{family}"',
             f'font-size="{fmt(size)}"', f'fill="{fill}"']
    if anchor != "start":
        attrs.append(f'text-anchor="{anchor}"')
    if weight != 400:
        attrs.append(f'font-weight="{weight}"')
    if ls is not None:
        attrs.append(f'letter-spacing="{fmt(ls)}"')
    if opacity is not None:
        attrs.append(f'opacity="{fmt(opacity)}"')
    if extra:
        attrs.append(extra)
    safe = content.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    return f'<text {" ".join(attrs)}>{safe}</text>'


def leaf(x, y, s, rot, fill, opacity=0.85):
    return (f'<path d="M0 0 C{s*0.3} {-s*0.52} {s*0.78} {-s*0.54} {s} {-s*0.12} '
            f'C{s*0.72} {s*0.28} {s*0.24} {s*0.26} 0 0 Z" fill="{fill}" '
            f'opacity="{opacity}" transform="translate({x} {y}) rotate({rot})"/>')


def sparkle(cx, cy, r, opacity=0.8):
    q = r * 0.14
    d = (f'M{cx} {cy - r} Q{cx + q} {cy - q} {cx + r} {cy} '
         f'Q{cx + q} {cy + q} {cx} {cy + r} '
         f'Q{cx - q} {cy + q} {cx - r} {cy} '
         f'Q{cx - q} {cy - q} {cx} {cy - r} Z')
    return (f'<path d="{d}" fill="#f5f8f6" opacity="{opacity}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r * 1.9}" fill="#a9c4c4" opacity="0.06"/>')


# --------------------------------------------------------------- background

def starfield():
    chunks = []
    colors = ["#ffffff", "#e9efec", "#fff4e2", "#d7e0df"]
    weights = [0.56, 0.26, 0.1, 0.08]
    for _ in range(3400):
        x = random.uniform(2, W - 2)
        y = random.uniform(2, H - 2)
        band = 0.5 + 0.5 * math.exp(-((y - 110) / 250) ** 2)
        if random.random() > band:
            continue
        r = random.choices([0.45, 0.6, 0.8, 1.05, 1.35], [28, 32, 24, 12, 4])[0]
        op = random.uniform(0.12, 0.5) + (r - 0.45) * 0.18
        color = random.choices(colors, weights)[0]
        chunks.append(
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{color}" '
            f'opacity="{min(op, 0.9):.2f}"/>')
    for _ in range(44):
        x = random.uniform(20, W - 20)
        y = random.uniform(8, H - 8)
        r = random.uniform(1.2, 1.9)
        chunks.append(
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r * 3.2:.1f}" fill="#d3dedd" opacity="0.055"/>'
            f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r:.1f}" fill="#ffffff" opacity="0.82"/>')
    return "\n".join(chunks)


def background():
    return "\n".join([
        f'<rect width="{W}" height="{H}" fill="url(#bgSky)"/>',
        '<ellipse cx="270" cy="120" rx="760" ry="430" fill="url(#hazeIndigo)"/>',
        '<ellipse cx="1730" cy="940" rx="650" ry="380" fill="url(#hazeTeal)"/>',
        '<ellipse cx="1510" cy="38" rx="700" ry="240" fill="url(#hazeCool)" opacity="0.8"/>',
        '<ellipse cx="960" cy="116" rx="880" ry="170" fill="url(#hazeTop)" opacity="0.7"/>',
        f'<rect width="{W}" height="{H}" fill="url(#vignette)"/>',
        '<g>', starfield(), '</g>',
        sparkle(148, 48, 8, 0.9),
        sparkle(1836, 116, 6, 0.75),
        sparkle(1812, 62, 3.5, 0.7),
        sparkle(68, 1004, 5, 0.65),
        sparkle(1850, 978, 7, 0.6),
        sparkle(1005, 22, 4, 0.6),
        sparkle(52, 300, 3.5, 0.5),
    ])


# --------------------------------------------------------------------- defs

def defs():
    av_clips = "\n".join(
        f'<clipPath id="avClip{i}"><circle cx="0" cy="0" r="46"/></clipPath>'
        for i in range(15))
    return f'''<defs>
<linearGradient id="bgSky" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#111a20"/>
  <stop offset="0.55" stop-color="#0c1419"/>
  <stop offset="1" stop-color="#080e13"/>
</linearGradient>
<radialGradient id="hazeIndigo" cx="0.5" cy="0.5" r="0.55">
  <stop offset="0" stop-color="#5b6c7b" stop-opacity="0.34"/>
  <stop offset="0.6" stop-color="#35414c" stop-opacity="0.1"/>
  <stop offset="1" stop-color="#35414c" stop-opacity="0"/>
</radialGradient>
<radialGradient id="hazeTeal" cx="0.5" cy="0.5" r="0.55">
  <stop offset="0" stop-color="#426b66" stop-opacity="0.24"/>
  <stop offset="0.65" stop-color="#2a4441" stop-opacity="0.07"/>
  <stop offset="1" stop-color="#2a4441" stop-opacity="0"/>
</radialGradient>
<radialGradient id="hazeCool" cx="0.5" cy="0.5" r="0.55">
  <stop offset="0" stop-color="#66727f" stop-opacity="0.2"/>
  <stop offset="0.6" stop-color="#404a54" stop-opacity="0.06"/>
  <stop offset="1" stop-color="#404a54" stop-opacity="0"/>
</radialGradient>
<radialGradient id="hazeTop" cx="0.5" cy="0.5" r="0.55">
  <stop offset="0" stop-color="#8a969f" stop-opacity="0.12"/>
  <stop offset="0.65" stop-color="#4d5862" stop-opacity="0.04"/>
  <stop offset="1" stop-color="#4d5862" stop-opacity="0"/>
</radialGradient>
<radialGradient id="vignette" cx="0.5" cy="0.46" r="0.75">
  <stop offset="0.45" stop-color="#03080b" stop-opacity="0"/>
  <stop offset="0.8" stop-color="#03080b" stop-opacity="0.24"/>
  <stop offset="1" stop-color="#03080b" stop-opacity="0.62"/>
</radialGradient>
<linearGradient id="panelFill" x1="0" y1="0" x2="0.1" y2="1">
  <stop offset="0" stop-color="#242e35"/>
  <stop offset="1" stop-color="#161f26"/>
</linearGradient>
<linearGradient id="panelDeep" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#1f2930"/>
  <stop offset="1" stop-color="#0f171d"/>
</linearGradient>
<linearGradient id="cardFill" x1="0" y1="0" x2="0.15" y2="1">
  <stop offset="0" stop-color="#2b3339"/>
  <stop offset="1" stop-color="#1f2930"/>
</linearGradient>
<linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#ffffff" stop-opacity="0.055"/>
  <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
</linearGradient>
<radialGradient id="panelHot" cx="0.5" cy="0.5" r="0.5">
  <stop offset="0" stop-color="#7a8a95" stop-opacity="0.16"/>
  <stop offset="1" stop-color="#7a8a95" stop-opacity="0"/>
</radialGradient>
<linearGradient id="edgeLine" x1="0" y1="0" x2="1" y2="0">
  <stop offset="0" stop-color="#ffffff" stop-opacity="0"/>
  <stop offset="0.2" stop-color="#ffffff" stop-opacity="0.18"/>
  <stop offset="0.8" stop-color="#ffffff" stop-opacity="0.18"/>
  <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
</linearGradient>
<linearGradient id="avatarGrad" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="#6b8191"/>
  <stop offset="1" stop-color="#36424c"/>
</linearGradient>
<radialGradient id="whiteGlow" cx="0.5" cy="0.45" r="0.55">
  <stop offset="0" stop-color="#ffffff" stop-opacity="0.45"/>
  <stop offset="0.55" stop-color="#ffffff" stop-opacity="0.12"/>
  <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
</radialGradient>
<radialGradient id="avVignette" cx="0.5" cy="0.42" r="0.68">
  <stop offset="0.5" stop-color="#000000" stop-opacity="0"/>
  <stop offset="1" stop-color="#000000" stop-opacity="0.52"/>
</radialGradient>
<linearGradient id="cloudGrad" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#d2c8d6"/>
  <stop offset="1" stop-color="#948b9d"/>
</linearGradient>
<linearGradient id="coverBg" x1="0" y1="0" x2="1" y2="1">
  <stop offset="0" stop-color="#1b281b"/>
  <stop offset="1" stop-color="#090e0a"/>
</linearGradient>
<filter id="blur12" x="-80%" y="-150%" width="260%" height="400%" color-interpolation-filters="sRGB">
  <feGaussianBlur stdDeviation="12"/>
</filter>
<filter id="blur24" x="-60%" y="-120%" width="220%" height="340%" color-interpolation-filters="sRGB">
  <feGaussianBlur stdDeviation="24"/>
</filter>
<filter id="blur36" x="-45%" y="-90%" width="190%" height="280%" color-interpolation-filters="sRGB">
  <feGaussianBlur stdDeviation="36"/>
</filter>
<filter id="blur14" x="-60%" y="-60%" width="220%" height="220%">
  <feGaussianBlur stdDeviation="14"/>
</filter>
<filter id="glowLine" x="-30%" y="-400%" width="160%" height="900%">
  <feGaussianBlur stdDeviation="4"/>
</filter>
<filter id="grain" x="0" y="0" width="100%" height="100%" color-interpolation-filters="sRGB">
  <feTurbulence type="fractalNoise" baseFrequency="0.78" numOctaves="3" stitchTiles="stitch"/>
  <feColorMatrix type="saturate" values="0"/>
  <feComponentTransfer><feFuncA type="linear" slope="0.12"/></feComponentTransfer>
</filter>
<clipPath id="mainClip"><rect x="76" y="100" width="1080" height="620" rx="18"/></clipPath>
<clipPath id="artistsClip"><rect x="1010" y="282" width="770" height="518" rx="16"/></clipPath>
<clipPath id="dockClip"><rect x="208" y="852" width="1504" height="196" rx="16"/></clipPath>
<clipPath id="coverClip"><rect width="124" height="124" rx="11"/></clipPath>
{av_clips}
{office_defs()}
</defs>'''


# ---------------------------------------------------------------- UI pieces

def icon_plus(cx, cy, color, s=6, sw=1.6):
    return (f'<path d="M{cx - s} {cy} H{cx + s} M{cx} {cy - s} V{cy + s}" '
            f'stroke="{color}" stroke-width="{sw}" stroke-linecap="round"/>')


def icon_pencil(cx, cy, color, s=8, sw=1.5):
    return (f'<g stroke="{color}" stroke-width="{sw}" fill="none" stroke-linecap="round" '
            f'stroke-linejoin="round">'
            f'<path d="M{cx - s} {cy + s} l1.1 {-4.1} 6.5 -6.5 a1.7 1.7 0 0 1 2.4 0 '
            f'l0.5 0.5 a1.7 1.7 0 0 1 0 2.4 l-6.5 6.5 Z"/>'
            f'<path d="M{cx - s + 1.1} {cy + s - 1.1} l3.6 -1.2"/></g>')


def icon_gear(cx, cy, color, s=7.5, sw=1.5):
    teeth = []
    for k in range(8):
        a = k * math.pi / 4
        teeth.append(
            f'M{cx + math.cos(a) * (s - 2.8):.1f} {cy + math.sin(a) * (s - 2.8):.1f} '
            f'L{cx + math.cos(a) * s:.1f} {cy + math.sin(a) * s:.1f}')
    return (f'<g stroke="{color}" stroke-width="{sw}" fill="none" stroke-linecap="round">'
            f'<circle cx="{cx}" cy="{cy}" r="{s * 0.44:.1f}"/>'
            f'<path d="{" ".join(teeth)}"/></g>')


def action_button(x, icon):
    return (f'<g><rect x="{x}" y="142" width="44" height="44" rx="14" '
            f'fill="#ffffff07" stroke="#ffffff10"/>{icon}</g>')


# --------------------------------------------------------------- card icons

def netflix(cx, cy):
    return (f'<g transform="translate({cx} {cy})">'
            '<path d="M-22 -28 H-10 V28 H-22 Z" fill="#b83838"/>'
            '<path d="M-22 -28 H-10 L22 28 H10 Z" fill="#a93236"/>'
            '<path d="M10 -28 H22 V28 H10 Z" fill="#d14a45"/>'
            '<path d="M-18.5 -24 H-13.5 V24 H-18.5 Z" fill="#e36a61" opacity="0.28"/>'
            '</g>')


def hulu(cx, cy):
    return (f'<text x="{cx}" y="{cy + 12}" font-family="{SANS}" font-size="35" '
            f'font-weight="700" fill="#84bf8b" text-anchor="middle" '
            f'letter-spacing="-1.6">hulu</text>')


def office(cx, cy):
    colors = (("#eaa83c", "#f2c766"), ("#f3d27f", "#e8a13a"))
    out = [f'<g transform="translate({cx} {cy})">']
    for r in range(2):
        for c in range(2):
            out.append(f'<rect x="{-23 + c * 25}" y="{-23 + r * 25}" width="21" height="21" '
                       f'rx="2.5" fill="url(#offGrad{r}_{c})"/>')
    out.append('</g>')
    return "".join(out)


def office_defs():
    return ('<linearGradient id="offGrad0_0" x1="0" y1="0" x2="1" y2="1">'
            '<stop offset="0" stop-color="#f0b44c"/><stop offset="1" stop-color="#dd912e"/></linearGradient>'
            '<linearGradient id="offGrad0_1" x1="0" y1="0" x2="1" y2="1">'
            '<stop offset="0" stop-color="#f3cd78"/><stop offset="1" stop-color="#e6aa45"/></linearGradient>'
            '<linearGradient id="offGrad1_0" x1="0" y1="0" x2="1" y2="1">'
            '<stop offset="0" stop-color="#f6dc9c"/><stop offset="1" stop-color="#eec56b"/></linearGradient>'
            '<linearGradient id="offGrad1_1" x1="0" y1="0" x2="1" y2="1">'
            '<stop offset="0" stop-color="#edb54e"/><stop offset="1" stop-color="#d98e2e"/></linearGradient>')


def reddit(cx, cy):
    return (f'<g transform="translate({cx} {cy})">'
            '<circle r="27" fill="#dd7b52"/>'
            '<path d="M0 -9 C0 -16 5 -20 10 -20" stroke="#f7f1e6" stroke-width="2.2" '
            'fill="none" stroke-linecap="round"/>'
            '<circle cx="10.5" cy="-20" r="3.2" fill="#f7f1e6"/>'
            '<circle cx="-16" cy="3" r="4.5" fill="#f7f1e6"/>'
            '<circle cx="16" cy="3" r="4.5" fill="#f7f1e6"/>'
            '<ellipse cx="0" cy="3" rx="16.5" ry="13" fill="#f7f1e6"/>'
            '<circle cx="-6" cy="0.5" r="2.6" fill="#dd7b52"/>'
            '<circle cx="6" cy="0.5" r="2.6" fill="#dd7b52"/>'
            '<path d="M-6 7.5 Q0 12.5 6 7.5" fill="none" stroke="#dd7b52" stroke-width="2" '
            'stroke-linecap="round"/>'
            '</g>')


def youtube(cx, cy):
    return (f'<g transform="translate({cx} {cy})">'
            '<rect x="-30" y="-20" width="60" height="40" rx="12" fill="#cf5752"/>'
            '<path d="M-6 -9 L-6 9 L11 0 Z" fill="#f6f1ea"/>'
            '<path d="M-23 -14 C-12 -18 12 -18 24 -14" stroke="#ffffff" stroke-opacity="0.12" '
            'stroke-width="3" stroke-linecap="round" fill="none"/>'
            '</g>')


def blackboard(cx, cy):
    return (f'<g transform="translate({cx} {cy})" fill="none" stroke="#d8b46b" '
            'stroke-linecap="round" stroke-linejoin="round">'
            '<rect x="-27" y="-23" width="54" height="38" rx="5" stroke-width="2.2"/>'
            '<path d="M-8 15 V21 H8 V15" stroke-width="1.8"/>'
            '<path d="M-18 24 H18" stroke-width="1.8"/>'
            '<path d="M-17 -11 H8" stroke-width="1.5" opacity="0.85"/>'
            '<path d="M-17 -3 H-2" stroke-width="1.5" opacity="0.55"/>'
            '<path d="M13 2 L13 8 L17 5 Z" fill="#d8b46b" stroke="none"/>'
            '</g>')


CARD_ICONS = {
    "Netflix": netflix,
    "Hulu": hulu,
    "Office365": office,
    "Reddit": reddit,
    "YouTube": youtube,
    "Blackboard": blackboard,
}


def service_card(x, y, w, h, accent, label):
    cx = x + w / 2
    icon = CARD_ICONS[label](cx, y + 84)
    return (f'<g>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="14" fill="url(#cardFill)" '
            f'stroke="#ffffff0d"/>'
            f'<circle cx="{x + w - 38}" cy="{y + 22}" r="42" fill="{accent}" opacity="0.05" '
            f'filter="url(#blur14)"/>'
            f'<circle cx="{x + 34}" cy="{y + h - 26}" r="30" fill="{accent}" opacity="0.035" '
            f'filter="url(#blur14)"/>'
            f'<ellipse cx="{cx}" cy="{y + 84}" rx="66" ry="56" fill="{accent}" opacity="0.03" '
            f'filter="url(#blur14)"/>'
            f'{icon}'
            f'{T(cx, y + 166, label, 13.5, "#ccd3d1", anchor="middle", ls=0.4)}'
            f'<rect x="{x + 42}" y="{y + h - 4}" width="{w - 84}" height="2.5" rx="1.25" '
            f'fill="{accent}" opacity="0.8"/>'
            f'<rect x="{x + 62}" y="{y + h - 5}" width="{w - 124}" height="4.5" rx="2.25" '
            f'fill="{accent}" opacity="0.26" filter="url(#glowLine)"/>'
            f'</g>')


# ---------------------------------------------------------------- main panel

def main_panel():
    p = ['<rect x="76" y="100" width="1080" height="620" rx="18" fill="#03080b" '
         'opacity="0.5" transform="translate(0 28)" filter="url(#blur36)"/>',
         '<rect x="76" y="100" width="1080" height="620" rx="18" fill="#03080b" '
         'opacity="0.32" transform="translate(0 8)" filter="url(#blur12)"/>',
         '<rect x="76" y="100" width="1080" height="620" rx="18" fill="url(#panelFill)" '
         'fill-opacity="0.94" stroke="#ffffff12"/>',
         '<g clip-path="url(#mainClip)">'
         '<rect x="76" y="100" width="1080" height="120" fill="url(#sheen)"/>'
         '<ellipse cx="1080" cy="140" rx="300" ry="110" fill="url(#panelHot)"/>'
         '<path d="M94 100.5 H1138" stroke="url(#edgeLine)"/></g>']

    p.append('<circle cx="150" cy="137" r="2.6" fill="#a9d6d0"/>')
    p.append(T(160, 140, "FRI, 22 APRIL · 01:27 PM", 9.2, "#808b8d", ls=2.1))
    p.append(f'<text x="150" y="192" font-family="{MONO}" font-size="35" font-weight="300" '
             f'fill="#bdc6c5" letter-spacing="0.4">Good afternoon,'
             f'<tspan dx="0.6em" fill="#f0e9d9">Barbarossa</tspan></text>')

    p.append('<rect x="596" y="212" width="40" height="22" rx="11" fill="#ffffff07" '
             'stroke="#ffffff0e"/>'
             '<path d="M610 224 L616 218 L622 224" fill="none" stroke="#8e9899" '
             'stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>')

    p.append('<circle cx="800" cy="164" r="22" fill="url(#avatarGrad)" stroke="#ffffff1c"/>')
    p.append(T(800, 169, "B", 12, "#eef3f1", anchor="middle", weight=500))
    p.append(action_button(836, icon_plus(858, 164, "#a8b2b1")))
    p.append(action_button(892, icon_pencil(914, 164, "#a8b2b1")))
    p.append(action_button(948, icon_gear(970, 164, "#a8b2b1")))

    cards = [
        ("Netflix", "#d65a54"), ("Hulu", "#83b98a"), ("Office365", "#e2b75e"),
        ("Reddit", "#dd7b52"), ("YouTube", "#d15c57"), ("Blackboard", "#d8b46b"),
    ]
    for idx, (label, accent) in enumerate(cards):
        col, row = idx % 3, idx // 3
        p.append(service_card(150 + col * 316, 252 + row * 216, 300, 200, accent, label))
    return "\n".join(p)


# ------------------------------------------------------------------ avatars

def person(cx, base, h, fill, opacity=1.0):
    hr = h * 0.115
    head_y = base - h * 0.8
    return (f'<g opacity="{opacity}">'
            f'<circle cx="{cx}" cy="{head_y:.1f}" r="{hr:.1f}" fill="{fill}"/>'
            f'<path d="M{cx - h * 0.4:.1f} {base} C{cx - h * 0.34:.1f} {base - h * 0.4:.1f} '
            f'{cx - h * 0.2:.1f} {base - h * 0.52:.1f} {cx} {base - h * 0.52:.1f} '
            f'C{cx + h * 0.2:.1f} {base - h * 0.52:.1f} {cx + h * 0.34:.1f} {base - h * 0.4:.1f} '
            f'{cx + h * 0.4:.1f} {base} Z" fill="{fill}"/></g>')


def band(base, h, fill, xs=(-30, -15, 0, 15, 30), opacity=1.0):
    return "".join(person(x, base, h * (1.04 - 0.06 * abs(x) / 30), fill, opacity) for x in xs)


def avatar_art(i):
    """Return art for a 92x92 local circle (center 0,0)."""
    if i == 0:  # 3 Inches of Blood
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#0b0e13"/>'
            '<ellipse cx="0" cy="-4" rx="46" ry="40" fill="#c98752" opacity="0.24"/>'
            '<circle cx="0" cy="-17" r="22" fill="#f0c894" opacity="0.1"/>'
            '<path d="M-36 -46 L-20 -46 L-8 26 L-24 26 Z" fill="#f0c894" opacity="0.06"/>'
            '<path d="M16 -46 L32 -46 L38 26 L22 26 Z" fill="#f0c894" opacity="0.05"/>'
            f'{band(48, 58, "#150f0a", xs=(-26, 0, 26))}'
            '<ellipse cx="0" cy="43" rx="46" ry="10" fill="#71261f" opacity="0.26"/>'
            '<circle cx="-27" cy="-29" r="1.2" fill="#e9c9a0" opacity="0.55"/>'
            '<circle cx="30" cy="-35" r="0.9" fill="#e9c9a0" opacity="0.45"/>')
    if i == 1:  # The Acacia Strain
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#8b8a82"/>'
            '<ellipse cx="0" cy="-10" rx="44" ry="42" fill="url(#whiteGlow)"/>'
            '<circle cx="0" cy="-1" r="31" fill="none" stroke="#e7e3d8" stroke-opacity="0.22" stroke-width="1"/>'
            '<path d="M0 -46 L0 46 M-46 3 L46 3" stroke="#2e2e2a" stroke-opacity="0.1" stroke-width="1"/>'
            '<circle cx="0" cy="-5" r="16" fill="#d4d0c3"/>'
            '<path d="M-16 -2 C-12 6 -4 7 0 7 C4 7 12 6 16 -2 L16 10 C10 16 -10 16 -16 10 Z" fill="#c3beaf"/>'
            '<path d="M-24 46 C-22 24 -14 15 -7 12 L7 12 C15 15 22 24 24 46 Z" fill="#cbc6b7"/>'
            '<ellipse cx="-6" cy="-8" rx="3.4" ry="2" fill="#57554d" opacity="0.8"/>'
            '<ellipse cx="6" cy="-8" rx="3.4" ry="2" fill="#57554d" opacity="0.8"/>'
            '<path d="M0 -5 L0 2 M-5 4 L5 4" stroke="#57554d" stroke-width="0.9" opacity="0.6"/>'
            '<path d="M-11 -18 L-6 -10 L-12 -6" stroke="#68665e" stroke-width="0.8" fill="none" opacity="0.7"/>'
            '<path d="M9 4 L13 16 M-30 26 L-20 34" stroke="#e7e3d8" stroke-width="0.6" opacity="0.25"/>'
            '<rect x="-46" y="34" width="92" height="12" fill="#5b5a54" opacity="0.25"/>')
    if i == 2:  # Aesop Rock
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#d8ab4c"/>'
            '<circle cx="4" cy="0" r="33" fill="none" stroke="#37452b" stroke-width="7" opacity="0.55"/>'
            '<path d="M-46 -22 H46 M-46 25 H46" stroke="#1f2618" stroke-width="5" opacity="0.28"/>'
            f'{person(4, 51, 66, "#2f3b26")}'
            '<rect x="1" y="-1" width="7" height="2" fill="#e4cfa0" opacity="0.8"/>'
            '<path d="M-18 -46 L-8 -46 L-11 -30 L-20 -30 Z" fill="#f2e5c4" opacity="0.15"/>'
            '<circle cx="-29" cy="-24" r="1" fill="#f7ecd0" opacity="0.6"/>')
    if i == 3:  # Allegaeon
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#718399"/>'
            '<ellipse cx="0" cy="-18" rx="38" ry="30" fill="url(#whiteGlow)"/>'
            '<circle cx="2" cy="-14" r="13" fill="#eef1ee" opacity="0.7"/>'
            '<path d="M-46 18 L-24 -4 L-8 12 L6 0 L26 20 L46 6 V46 H-46 Z" fill="#8fa1af" opacity="0.65"/>'
            '<path d="M-46 30 L-28 12 L-14 26 L-2 14 L18 32 L34 22 L46 32 V46 H-46 Z" fill="#596b7d"/>'
            '<path d="M-46 40 L-22 26 L-6 38 L10 24 L30 40 L46 32 V46 H-46 Z" fill="#303d4b"/>'
            '<path d="M-24 -4 L-19 3 L-15 0 L-10 7" stroke="#e7edf2" stroke-width="1" fill="none" opacity="0.7"/>'
            '<path d="M25 24 L30 22 M33 27 L38 25" stroke="#dfe6ea" stroke-width="0.8" opacity="0.6"/>')
    if i == 4:  # Amon Amarth
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#7a5639"/>'
            '<ellipse cx="0" cy="-8" rx="45" ry="38" fill="#e3b782" opacity="0.28"/>'
            '<circle cx="0" cy="2" r="32" fill="none" stroke="#d8b58a" stroke-opacity="0.25" stroke-width="1"/>'
            '<path d="M-46 26 C-22 18 22 18 46 26 V46 H-46 Z" fill="#4a3220" opacity="0.45"/>'
            f'{band(48, 47, "#170e08", (-30, -15, 0, 15, 30))}'
            '<path d="M-3 -24 C-8 -31 -15 -34 -20 -32 M3 -24 C8 -31 15 -34 20 -32" '
            'stroke="#170e08" stroke-width="3" fill="none" stroke-linecap="round"/>'
            '<path d="M-24 -14 L-20 -20 M-25 -2 L-21 -8 M-25 10 L-21 4" stroke="#c9a97b" stroke-width="0.7" opacity="0.4"/>'
            '<ellipse cx="0" cy="41" rx="38" ry="6" fill="#2a1a10" opacity="0.5"/>')
    if i == 5:  # ASG
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#b9663d"/>'
            '<circle cx="0" cy="-8" r="24" fill="#e7b276" opacity="0.5"/>'
            '<circle cx="0" cy="-8" r="16" fill="#f0c690" opacity="0.5"/>'
            '<path d="M-46 4 H46 M-46 10 H46" stroke="#7e3a22" stroke-width="1" opacity="0.4"/>'
            '<path d="M-46 30 C-22 24 22 24 46 30 V46 H-46 Z" fill="#5e2b1b" opacity="0.55"/>'
            f'{person(-13, 48, 51, "#381a11")}'
            f'{person(13, 49, 54, "#2e150e")}'
            '<path d="M-30 -46 C-24 -24 -22 -8 -23 20" stroke="#f4d1a2" stroke-width="7" opacity="0.04"/>'
            '<circle cx="-27" cy="-24" r="1" fill="#ffdfb5" opacity="0.6"/>')
    if i == 6:  # Baroness
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#273b2f"/>'
            '<g fill="none" stroke="#7f9a78" stroke-linecap="round">'
            '<path d="M-38 2 C-24 -24 20 -30 38 -6" stroke-width="1.2" opacity="0.55"/>'
            '<path d="M-34 10 C-20 -12 18 -16 34 4" stroke-width="1.4" opacity="0.45"/>'
            '<path d="M-29 18 C-16 2 14 0 29 12" stroke-width="1.6" opacity="0.35"/>'
            '<path d="M-24 26 C-12 16 10 15 23 22" stroke-width="1.8" opacity="0.25"/></g>'
            '<path d="M0 -22 C12 -8 15 6 2 20 C-12 8 -13 -6 0 -22 Z" fill="#d8d0b4" opacity="0.82"/>'
            '<circle cx="0" cy="2" r="3" fill="#273b2f"/>'
            '<circle cx="0" cy="2" r="7" fill="none" stroke="#d8d0b4" stroke-opacity="0.4"/>'
            '<circle cx="-28" cy="-29" r="1" fill="#d8d0b4" opacity="0.5"/>'
            '<circle cx="31" cy="-22" r="0.8" fill="#d8d0b4" opacity="0.4"/>')
    if i == 7:  # Black Tusk
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#0a0a0b"/>'
            '<circle cx="0" cy="0" r="29" fill="none" stroke="#e9e6de" stroke-width="1.6" opacity="0.85"/>'
            '<path d="M-20 -24 C-34 -12 -36 8 -23 20 C-31 6 -30 -12 -20 -24 Z" fill="#e9e6de" opacity="0.95"/>'
            '<path d="M20 -24 C34 -12 36 8 23 20 C31 6 30 -12 20 -24 Z" fill="#e9e6de" opacity="0.95"/>'
            '<path d="M-38 30 L30 -38" stroke="#8e2f2a" stroke-width="4.2" opacity="0.65"/>'
            '<circle cx="0" cy="0" r="2" fill="#e9e6de"/>'
            '<path d="M-20 -13 H-10 M10 -13 H20" stroke="#e9e6de" stroke-width="1" opacity="0.4"/>')
    if i == 8:  # Borknagar
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#1d3f44"/>'
            '<ellipse cx="0" cy="-20" rx="40" ry="30" fill="url(#whiteGlow)"/>'
            '<circle cx="2" cy="-18" r="15" fill="#d8e9e4" opacity="0.75"/>'
            '<circle cx="0" cy="4" r="27" fill="none" stroke="#a9cfc9" stroke-width="1" opacity="0.35"/>'
            '<path d="M0 -23 V31 M-23 3 H23 M-16 -12 L16 18 M16 -12 L-16 18" stroke="#a9cfc9" stroke-width="0.8" opacity="0.35"/>'
            '<path d="M-46 26 L-27 6 L-14 22 L3 2 L18 20 L33 6 L46 22 V46 H-46 Z" fill="#7fa3a0" opacity="0.55"/>'
            '<path d="M-46 36 L-24 22 L-8 34 L10 20 L28 34 L46 26 V46 H-46 Z" fill="#355c60"/>'
            '<circle cx="-20" cy="-27" r="0.9" fill="#ffffff" opacity="0.7"/>'
            '<circle cx="26" cy="-12" r="0.8" fill="#ffffff" opacity="0.6"/>')
    if i == 9:  # Dio
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#392a51"/>'
            '<circle cx="12" cy="-17" r="17" fill="#d8c9a7" opacity="0.7"/>'
            '<ellipse cx="0" cy="-6" rx="42" ry="34" fill="url(#whiteGlow)" opacity="0.6"/>'
            '<path d="M-9 -22 C-20 -16 -24 -2 -21 12 L22 12 C24 -4 18 -18 7 -23 '
            'C4 -17 0 -14 -4 -18 Z" fill="#120c1a"/>'
            '<path d="M-21 12 L-32 46 H36 L22 12 Z" fill="#0d0913"/>'
            '<path d="M-9 -16 C-9 -6 -7 2 -5 8 M0 -18 C0 -6 1 3 2 8" stroke="#6a5584" stroke-width="0.8" opacity="0.7"/>'
            '<path d="M-4 -8 L-7 -3 L-4 1 M5 -8 L8 -3 L5 1" stroke="#cbbca0" stroke-width="1" fill="none" opacity="0.7"/>'
            '<path d="M22 -30 L26 46" stroke="#8e7143" stroke-width="2.4"/>'
            '<circle cx="22" cy="-33" r="4" fill="#e6c887" opacity="0.8"/>'
            '<circle cx="22" cy="-33" r="8" fill="#e6c887" opacity="0.12"/>')
    if i == 10:  # Disarmonia Mundi
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#561d22"/>'
            '<ellipse cx="0" cy="0" rx="36" ry="32" fill="#e08a7c" opacity="0.14"/>'
            '<path d="M-46 -12 L-12 -46 H8 L-26 4 Z" fill="#8d3738" opacity="0.55"/>'
            '<path d="M46 -6 L10 -46 H28 L46 -24 Z" fill="#7a2b2e" opacity="0.5"/>'
            '<path d="M-46 30 L-4 46 H-30 Z" fill="#9e4640" opacity="0.45"/>'
            '<path d="M46 16 L8 46 H38 Z" fill="#b75a50" opacity="0.32"/>'
            '<path d="M-36 -36 L33 35 M18 -40 L-30 30" stroke="#e7b1a6" stroke-width="0.7" opacity="0.28"/>'
            '<circle cx="0" cy="0" r="10" fill="none" stroke="#e7c6bb" stroke-width="1" opacity="0.25"/>'
            '<circle cx="0" cy="0" r="2" fill="#e7c6bb" opacity="0.5"/>')
    if i == 11:  # Disturbed
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#292c30"/>'
            '<ellipse cx="0" cy="-4" rx="20" ry="27" fill="#9ba1a6" opacity="0.85"/>'
            '<path d="M-20 -4 C-34 -2 -34 18 -22 22 L22 22 C34 18 34 -2 20 -4 Z" fill="#898f95" opacity="0.65"/>'
            '<path d="M-46 18 H46 M-46 30 H46 M-46 42 H46" stroke="#111316" stroke-width="3" opacity="0.55"/>'
            '<circle cx="-7" cy="-8" r="2.3" fill="#eff2f0"/>'
            '<circle cx="7" cy="-8" r="2.3" fill="#eff2f0"/>'
            '<path d="M-6 13 C-2 10 2 10 6 13" stroke="#4f5357" stroke-width="1" fill="none"/>'
            '<circle cx="-7" cy="-8" r="6" fill="#dfe5e4" opacity="0.08"/>'
            '<circle cx="7" cy="-8" r="6" fill="#dfe5e4" opacity="0.08"/>')
    if i == 12:  # Einherjer
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#0b0c0e"/>'
            '<path d="M0 -25 C-14 -25 -22 -14 -22 1 C-22 16 -15 26 -7 28 L7 28 '
            'C15 26 22 16 22 1 C22 -14 14 -25 0 -25 Z" fill="#ddd8cc"/>'
            '<path d="M-22 1 C-16 -6 -10 -8 -6 -7 L-6 16 C-13 16 -19 10 -22 1 Z" fill="#c9c3b6" opacity="0.7"/>'
            '<path d="M-13 -6 L-4 -2 M13 -6 L4 -2" stroke="#141416" stroke-width="2" stroke-linecap="round"/>'
            '<path d="M-10 -2 L-4 0 M10 -2 L4 0" stroke="#141416" stroke-width="1.4" stroke-linecap="round"/>'
            '<path d="M-2 3 V13 M-6 -1 L-2 12" stroke="#141416" stroke-width="1.1"/>'
            '<path d="M-8 20 H8" stroke="#a63e36" stroke-width="3" opacity="0.8"/>'
            '<path d="M-22 29 H22 M-17 34 H17" stroke="#e0dbcf" stroke-width="3" opacity="0.18"/>'
            '<path d="M30 -32 L38 -20 M34 -36 L40 -26" stroke="#8f2e2b" stroke-width="0.8" opacity="0.5"/>')
    if i == 13:  # Eliminator
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#3a4527"/>'
            '<path d="M-46 10 C-30 -4 -18 8 -4 0 C10 -8 22 4 36 -2 C42 -5 45 0 46 4 V46 H-46 Z" fill="#55683b" opacity="0.6"/>'
            '<path d="M-46 28 C-30 18 -16 30 -2 22 C12 14 28 26 46 16 V46 H-46 Z" fill="#1d2515" opacity="0.7"/>'
            '<circle cx="0" cy="-2" r="24" fill="none" stroke="#d6cba9" stroke-width="1" opacity="0.55"/>'
            '<path d="M-35 -2 H35 M0 -37 V33" stroke="#d6cba9" stroke-width="0.8" opacity="0.4"/>'
            '<circle cx="0" cy="-2" r="5" fill="none" stroke="#d6cba9" stroke-width="1" opacity="0.7"/>'
            '<circle cx="0" cy="-2" r="1.5" fill="#d6cba9" opacity="0.8"/>'
            '<path d="M-30 -30 C-18 -22 -10 -14 -8 -6" stroke="#0f140b" stroke-width="7" opacity="0.35"/>')
    if i == 14:  # Eluveitie
        return (
            '<rect x="-46" y="-46" width="92" height="92" fill="#2f4354"/>'
            '<ellipse cx="0" cy="-16" rx="40" ry="30" fill="url(#whiteGlow)"/>'
            '<circle cx="-6" cy="-20" r="14" fill="#d8d4c3" opacity="0.7"/>'
            '<path d="M-46 16 L-32 8 L-32 -8 L-26 -8 L-26 -16 L-18 -24 L-10 -16 L-10 14 '
            'L-2 14 L-2 -4 L6 -4 L6 14 L12 14 L12 -20 L18 -28 L26 -20 L26 12 L34 12 L34 4 '
            'L46 4 V46 H-46 Z" fill="#0f1a22" opacity="0.8"/>'
            '<path d="M-46 30 H46 M-46 38 H46 M-46 44 H46" stroke="#cfdbd8" stroke-width="4" opacity="0.06"/>'
            '<path d="M-14 20 L-14 30 M22 20 L22 30" stroke="#d8b46b" stroke-width="1.2" opacity="0.45"/>'
            '<circle cx="24" cy="-32" r="0.9" fill="#dfe8e5" opacity="0.6"/>')
    return '<rect x="-46" y="-46" width="92" height="92" fill="#222b38"/>'


ARTISTS = [
    "3 Inches of Blood", "The Acacia Strain", "Aesop Rock", "Allegaeon", "Amon Amarth",
    "ASG", "Baroness", "Black Tusk", "Borknagar", "Dio",
    "Disarmonia Mundi", "Disturbed", "Einherjer", "Eliminator", "Eluveitie",
]


def avatar(cx, cy, i):
    label = ARTISTS[i]
    return (f'<g transform="translate({cx} {cy})">'
            f'<circle r="46" fill="#10161f"/>'
            f'<g clip-path="url(#avClip{i})">{avatar_art(i)}'
            f'<circle r="46" fill="url(#avVignette)"/></g>'
            f'<circle r="46" fill="none" stroke="#ffffff1f" stroke-width="1"/>'
            f'<circle r="47.5" fill="none" stroke="#000000" stroke-opacity="0.25"/>'
            f'</g>'
            f'{T(cx, cy + 60, label, 8.9, "#9ba5a4", anchor="middle")}')


# ------------------------------------------------------------------- icons

def sidebar_icon(name, x, y):
    inner = {
        "suggestions": '<path d="M6 .8 L7.2 4.8 L11.2 6 L7.2 7.2 L6 11.2 L4.8 7.2 L.8 6 L4.8 4.8 Z"/>',
        "popular": '<path d="M6 1.1 L7.4 4.4 L10.9 4.8 L8.2 7.1 L8.9 10.7 L6 8.9 L3.1 10.7 L3.8 7.1 L1.1 4.8 L4.6 4.4 Z"/>',
        "random": '<path d="M1 3.3 H3.2 C5 3.3 6.2 4.4 7.2 6 L8.8 8.7 H11"/><path d="M9 6.8 L11 8.7 L9 10.6"/><path d="M1 8.7 H3.2 C4.2 8.7 4.8 8.4 5.5 7.5"/><path d="M5 4.4 C5.8 3.6 6.6 3.3 7.6 3.3 H11"/><path d="M9 1.4 L11 3.3 L9 5.2"/>',
        "recent": '<circle cx="6" cy="6" r="4.6"/><path d="M6 3.4 V6 L8 7.4"/>',
        "artists": '<circle cx="6" cy="4" r="2.2"/><path d="M2 10.8 C2.4 8.2 4 7.3 6 7.3 C8 7.3 9.6 8.2 10 10.8"/>',
        "genres": '<path d="M1.2 5.2 L5.2 1.2 H9.6 L10.8 2.4 V6.8 L6.8 10.8 Z"/><circle cx="8.3" cy="3.7" r=".9"/>',
        "playlists": '<path d="M4.6 9.4 V3.1 L9.8 2 V8.2"/><circle cx="3" cy="9.4" r="1.6"/><circle cx="8.2" cy="8.2" r="1.6"/>',
        "albums": '<circle cx="6" cy="6" r="4.7"/><circle cx="6" cy="6" r="1.2"/>',
        "search": '<circle cx="5.2" cy="5.2" r="3.4"/><path d="M7.7 7.7 L10.8 10.8"/>',
    }[name]
    return (f'<g transform="translate({x} {y})" fill="none" stroke="#8b9697" '
            f'stroke-width="1.15" stroke-linecap="round" stroke-linejoin="round">'
            f'{inner}</g>')


def header_icon(name, cx, cy, color=MUTED):
    if name == "shuffle":
        return (f'<g transform="translate({cx - 6} {cy - 6})" fill="none" stroke="{color}" '
                'stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round">'
                '<path d="M1 3.3 H3.2 C5 3.3 6.2 4.4 7.2 6 L8.8 8.7 H11"/>'
                '<path d="M9 6.8 L11 8.7 L9 10.6"/>'
                '<path d="M1 8.7 H3.2 C4.2 8.7 4.8 8.4 5.5 7.5"/>'
                '<path d="M5 4.4 C5.8 3.6 6.6 3.3 7.6 3.3 H11"/>'
                '<path d="M9 1.4 L11 3.3 L9 5.2"/></g>')
    if name == "play":
        return (f'<path d="M{cx - 3.5} {cy - 5.5} L{cx + 5} {cy} L{cx - 3.5} {cy + 5.5} Z" '
                f'fill="{color}"/>')
    if name == "more":
        return (f'<circle cx="{cx - 5}" cy="{cy}" r="1.3" fill="{color}"/>'
                f'<circle cx="{cx}" cy="{cy}" r="1.3" fill="{color}"/>'
                f'<circle cx="{cx + 5}" cy="{cy}" r="1.3" fill="{color}"/>')
    return ""


# ------------------------------------------------------------------ artists

def sidebar_item(y, icon, label, active=False):
    out = []
    if active:
        out.append(f'<rect x="1018" y="{y - 15}" width="169" height="26" rx="7" '
                   f'fill="#ffffff09"/>'
                   f'<rect x="1018" y="{y - 9}" width="2" height="14" rx="1" '
                   f'fill="#a9d6d0" opacity="0.7"/>')
    out.append(sidebar_icon(icon, 1027, y - 10))
    out.append(T(1046, y, label, 9.6, "#e6eae8" if active else "#97a1a1"))
    return "".join(out)


def artists_panel():
    p = ['<rect x="1010" y="282" width="770" height="518" rx="16" fill="#03080b" '
         'opacity="0.58" transform="translate(0 30)" filter="url(#blur36)"/>',
         '<rect x="1010" y="282" width="770" height="518" rx="16" fill="#03080b" '
         'opacity="0.4" transform="translate(0 8)" filter="url(#blur12)"/>',
         '<rect x="1010" y="282" width="770" height="518" rx="16" fill="url(#panelDeep)" '
         'fill-opacity="0.965" stroke="#ffffff12"/>',
         '<g clip-path="url(#artistsClip)">',
         '<path d="M1010 282 H1780 V336 H1010 Z" fill="#141d23"/>',
         '<rect x="1010" y="336" width="185" height="464" fill="#0f171d" opacity="0.55"/>',
         '<rect x="1010" y="336" width="770" height="80" fill="url(#sheen)" opacity="0.7"/>',
         '<line x1="1195" y1="336" x2="1195" y2="800" stroke="#ffffff09"/>',
         '<line x1="1010" y1="336.5" x2="1780" y2="336.5" stroke="#ffffff0d"/>']

    # mini player header
    p.append(asg_cover(1026, 294, 30))
    p.append(T(1066, 309, "Mourning Of The Earth", 10.2, "#cbd2d0"))
    p.append(T(1066, 322, "ASG · Low Country", 8.2, "#859092"))
    p.append('<rect x="1262" y="309" width="282" height="3" rx="1.5" fill="#ffffff12"/>')
    p.append('<rect x="1262" y="309" width="231" height="3" rx="1.5" fill="#a9d6d0" opacity="0.8"/>')
    p.append('<circle cx="1493" cy="310.5" r="3" fill="#d2e7e0"/>')
    p.append(T(1556, 314, "3:21 / 4:05", 8, "#838e8f"))
    for k, color in enumerate(("#d97a72", "#d9b56b", "#83b98a")):
        p.append(f'<circle cx="{1714 + k * 14}" cy="310" r="2.6" fill="{color}" opacity="0.5"/>')

    # sidebar
    items = [
        (362, "suggestions", "Suggestions", False),
        (390, "popular", "Popular albums", False),
        (418, "random", "Random albums", False),
        (446, "recent", "Recently added albums", False),
        (474, "artists", "Artists", True),
        (502, "genres", "Genres", False),
        (530, "playlists", "Playlists", False),
        (558, "albums", "Albums", False),
    ]
    for y, icon, label, active in items:
        p.append(sidebar_item(y, icon, label, active))

    p.append('<rect x="1016" y="610" width="170" height="30" rx="8" fill="#ffffff05" '
             'stroke="#ffffff0a"/>')
    p.append('<g transform="translate(1026 618)" fill="none" stroke="#838e8f" stroke-width="1.2" '
             'stroke-linecap="round"><circle cx="4" cy="4" r="3"/><path d="M6.4 6.4 L9 9"/></g>')
    p.append(T(1042, 629, "Search", 9, "#758183"))
    p.append('<line x1="1026" y1="694" x2="1170" y2="694" stroke="#ffffff08"/>')
    p.append(T(1026, 714, "ASG LIBRARY", 7.2, "#667172", ls=1.6))
    p.append(T(1026, 728, "128 albums · 3,214 tracks", 8, "#758183"))

    # main header
    p.append(T(1221, 370, "Artists", 21, "#e9ecea", weight=500))
    p.append('<circle cx="1692" cy="366" r="13" fill="#ffffff06" stroke="#ffffff0d"/>')
    p.append(header_icon("shuffle", 1692, 366, "#9aa5a5"))
    p.append('<circle cx="1724" cy="366" r="13" fill="#a9d6d0"/>')
    p.append(header_icon("play", 1724, 366, "#111a22"))
    p.append(header_icon("more", 1754, 366, "#8d9898"))

    # three rows of artist circles
    xs = (1265, 1376, 1487, 1598, 1709)
    ys = (430, 556, 682)
    for row, cy in enumerate(ys):
        for col, cx in enumerate(xs):
            p.append(avatar(cx, cy, row * 5 + col))
    p.append('</g>')
    p.append('<rect x="1010" y="282" width="770" height="518" rx="16" fill="none" '
             'stroke="#ffffff14"/>')
    return "\n".join(p)


def asg_cover(x, y, size):
    s = size / 124
    leaves = [
        (12, 26, 27, -35, "#3f5a37", 0.95), (34, 10, 22, 55, "#55724a", 0.8),
        (102, 20, 25, 140, "#506b45", 0.9), (110, 52, 28, 195, "#2f452c", 0.95),
        (98, 104, 26, 130, "#3c5535", 0.9), (22, 102, 30, -20, "#46603d", 0.9),
        (6, 64, 24, 255, "#334b30", 0.9), (64, 118, 20, 70, "#55724a", 0.65),
        (16, 52, 15, 10, "#6b8458", 0.7), (112, 82, 15, 170, "#738d60", 0.65),
    ]
    p = [f'<g transform="translate({x} {y}) scale({s:.4f})" clip-path="url(#coverClip)">',
         '<rect width="124" height="124" fill="url(#coverBg)"/>',
         '<ellipse cx="62" cy="62" rx="46" ry="44" fill="#6f855a" opacity="0.16"/>',
         '<circle cx="62" cy="58" r="40" fill="none" stroke="#9aab7a" stroke-opacity="0.14"/>']
    for lx, ly, ls, rot, fill, op in leaves:
        p.append(leaf(lx, ly, ls, rot, fill, op))
    # small pink blossoms
    for fx, fy, fr in ((22, 30, 5.4), (100, 38, 4.6), (26, 92, 5.2), (96, 96, 5.8)):
        for k in range(5):
            a = k * 2 * math.pi / 5 - math.pi / 2
            p.append(f'<circle cx="{fx + math.cos(a) * fr:.1f}" cy="{fy + math.sin(a) * fr:.1f}" '
                     f'r="{fr * 0.72:.1f}" fill="#c17c91" opacity="0.9"/>')
        p.append(f'<circle cx="{fx}" cy="{fy}" r="{fr * 0.6:.1f}" fill="#e3c08f" opacity="0.9"/>')
    # skull
    p.append('<path d="M62 30 C49 30 40 39 40 52 C40 60 44 65 48 68 L48 75 L57 75 L57 71 '
             'L67 71 L67 75 L76 75 L76 68 C80 65 84 60 84 52 C84 39 75 30 62 30 Z" '
             'fill="#e7dac2"/>')
    p.append('<path d="M40 52 C40 60 44 65 48 68 L48 75 L57 75 L57 71 L62 71 V30 '
             'C49 30 40 39 40 52 Z" fill="#d8c9ad" opacity="0.55"/>')
    p.append('<ellipse cx="53" cy="51" rx="5.2" ry="6.4" fill="#1b2118"/>')
    p.append('<ellipse cx="71" cy="51" rx="5.2" ry="6.4" fill="#1b2118"/>')
    p.append('<path d="M62 57 L58 65 L66 65 Z" fill="#1b2118"/>')
    p.append('<path d="M57 71 V75 M62 71 V75 M67 71 V75" stroke="#1b2118" stroke-width="1" opacity="0.8"/>')
    p.append('<path d="M59 35 C56 40 55 46 56 50 M67 35 L67 43" stroke="#c9b998" stroke-width="0.7" fill="none" opacity="0.7"/>')
    p.append('<circle cx="47" cy="61" r="2.4" fill="#5f7a51" opacity="0.8"/>')
    p.append('<circle cx="77" cy="64" r="3.2" fill="#4c6744" opacity="0.8"/>')
    p.append('<circle cx="79" cy="77" r="1.8" fill="#c17c91" opacity="0.75"/>')
    p.append(T(62, 114, "ASG", 11.5, "#efe7d6", anchor="middle", ls=3.2,
               family="'DejaVu Serif','Liberation Serif',serif", weight=700))
    p.append('<rect width="124" height="124" fill="none" stroke="#ffffff1c"/>')
    p.append('</g>')
    return "".join(p)


# --------------------------------------------------------------------- dock

def dock_icon(name, cx, cy, color="#8e9899"):
    shapes = {
        "globe": ('<circle cx="0" cy="0" r="10"/><ellipse cx="0" cy="0" rx="4.4" ry="10"/>'
                  '<path d="M-10 0 H10"/><path d="M-8.6 -5 H8.6"/><path d="M-8.6 5 H8.6"/>'),
        "mail": ('<rect x="-11" y="-8" width="22" height="16" rx="2.5"/>'
                 '<path d="M-10 -6 L0 2.5 L10 -6"/>'),
        "note": ('<path d="M2 -10 V7"/><path d="M2 -10 C7 -11 10 -8 10 -3"/>'
                 '<circle cx="-1.6" cy="8" r="3.8"/><circle cx="8.4" cy="5" r="3.4"/>'),
        "folder": ('<path d="M-11 -7 H-3.4 L-1.2 -3.8 H11 V8.6 H-11 Z"/>'),
        "code": ('<path d="M-6 -7 L-12 0 L-6 7"/><path d="M6 -7 L12 0 L6 7"/><path d="M2.5 -8 L-2.5 8"/>'),
        "calendar": ('<rect x="-10" y="-8" width="20" height="17" rx="2.5"/>'
                     '<path d="M-10 -3 H10"/><path d="M-5.5 -11 V-6"/><path d="M5.5 -11 V-6"/>'
                     '<circle cx="-4.5" cy="1.5" r="1" fill="currentColor" stroke="none"/>'
                     '<circle cx="1" cy="1.5" r="1" fill="currentColor" stroke="none"/>'
                     '<circle cx="6" cy="1.5" r="1" fill="currentColor" stroke="none"/>'),
        "compass": ('<circle cx="0" cy="0" r="10"/><path d="M3.8 -4.2 L1.2 1.2 L-3.8 4.2 L-1.2 -1.2 Z"/>'),
        "terminal": ('<rect x="-11" y="-8" width="22" height="16" rx="2.5"/>'
                     '<path d="M-6 -3 L-2 0.5 L-6 4"/><path d="M1.5 4.5 H6.5"/>'),
    }[name]
    return (f'<g transform="translate({cx} {cy})" fill="none" stroke="{color}" stroke-width="1.55" '
            f'stroke-linecap="round" stroke-linejoin="round">{shapes}</g>')


def ring(cx, cy, r, sw, pct, color):
    circ = 2 * math.pi * r
    return (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="#303a40" stroke-width="{sw}"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{color}" stroke-width="{sw}" '
            f'stroke-dasharray="{pct * circ:.1f} {circ:.1f}" stroke-linecap="round" '
            f'transform="rotate(-90 {cx} {cy})" opacity="0.9"/>'
            f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{color}" stroke-width="{sw + 4}" '
            f'stroke-dasharray="{pct * circ:.1f} {circ:.1f}" stroke-linecap="round" '
            f'transform="rotate(-90 {cx} {cy})" opacity="0.08"/>')


def cloud(cx, cy):
    return (f'<g transform="translate({cx} {cy})">'
            '<path d="M-38 14 C-47 14 -49 0 -40 -5 C-41 -21 -23 -28 -13 -17 '
            'C-5 -33 20 -32 24 -14 C39 -17 44 2 33 9 C29 13 24 14 19 14 Z" '
            'fill="#443e5b" opacity="0.35" transform="translate(2 6)"/>'
            '<path d="M-38 10 C-47 10 -49 -4 -40 -9 C-41 -25 -23 -32 -13 -21 '
            'C-5 -37 20 -36 24 -18 C39 -21 44 -2 33 5 C29 9 24 10 19 10 Z" '
            'fill="url(#cloudGrad)"/>'
            '<path d="M-28 -9 C-24 -20 -8 -23 -3 -14" stroke="#f2edf2" stroke-width="2" '
            'fill="none" opacity="0.35" stroke-linecap="round"/>'
            '</g>')


def dock():
    p = ['<rect x="208" y="852" width="1504" height="196" rx="16" fill="#03080b" '
         'opacity="0.55" transform="translate(0 20)" filter="url(#blur24)"/>',
         '<rect x="208" y="852" width="1504" height="196" rx="16" fill="#03080b" '
         'opacity="0.35" transform="translate(0 5)" filter="url(#blur12)"/>',
         '<rect x="208" y="852" width="1504" height="196" rx="16" fill="url(#panelDeep)" '
         'fill-opacity="0.95" stroke="#ffffff12"/>',
         '<g clip-path="url(#dockClip)">',
         '<rect x="208" y="852" width="1504" height="90" fill="url(#sheen)" opacity="0.6"/>',
         '<path d="M226 852.5 H1694" stroke="url(#edgeLine)"/>']
    for x in (596, 1044, 1408):
        p.append(f'<line x1="{x}" y1="878" x2="{x}" y2="1022" stroke="#ffffff0a"/>')

    # now playing
    p.append('<rect x="230" y="891" width="118" height="118" rx="11" fill="#a9d6d0" opacity="0.06" filter="url(#blur14)"/>')
    p.append(asg_cover(230, 891, 118))
    p.append(T(372, 902, "NOW PLAYING", 7.4, "#788485", ls=1.7))
    p.append(T(372, 926, "Mourning Of The", 15.2, "#e9ecea"))
    p.append(T(372, 944, "Earth", 15.2, "#e9ecea"))
    p.append(T(372, 963, "ASG · Low Country", 9.2, "#98a2a2"))
    p.append('<rect x="372" y="984" width="198" height="3.5" rx="1.75" fill="#ffffff14"/>')
    p.append('<rect x="372" y="984" width="121" height="3.5" rx="1.75" fill="#a9d6d0" opacity="0.85"/>')
    p.append('<circle cx="493" cy="985.8" r="3.2" fill="#dbe8e3"/>')
    p.append(T(372, 1004, "1:57", 8, "#758183"))
    p.append(T(570, 1004, "3:14", 8, "#758183", anchor="end"))

    # shortcut tiles
    icons = ["globe", "mail", "note", "folder", "code", "calendar", "compass", "terminal"]
    for idx, name in enumerate(icons):
        col, row = idx % 4, idx // 4
        cx = 673 + col * 98
        cy = 910 + row * 75
        p.append(f'<rect x="{cx - 25}" y="{cy - 25}" width="50" height="50" rx="14" '
                 f'fill="#ffffff04" stroke="#ffffff08"/>')
        p.append(dock_icon(name, cx, cy, "#8b9698"))

    # weather
    p.append(cloud(1108, 946))
    p.append(T(1172, 938, "71°F", 30, "#f0f3f1", weight=300))
    p.append('<g transform="translate(1262 915)">'
             '<path d="M0 0 C5 0 7 3.5 7 7 V18 C9.8 19.6 11 22 11 24.5 C11 28.5 8 31 0 31 '
             'C-8 31 -11 28.5 -11 24.5 C-11 22 -9.8 19.6 -7 18 V7 C-7 3.5 -5 0 0 0 Z" '
             'fill="none" stroke="#a98a5c" stroke-width="1.5"/>'
             '<circle cx="0" cy="24.5" r="4.5" fill="#d9b56b" opacity="0.85"/>'
             '<path d="M0 11 V22" stroke="#d9b56b" stroke-width="2" stroke-linecap="round"/></g>')
    p.append(T(1172, 968, "Broken Clouds", 16.5, "#d7e1dc"))
    p.append(T(1172, 990, "It's cloudy, sort of gloomy", 9.2, "#929c9d"))
    p.append(T(1172, 1008, "HUM 62%   ·   WIND 7 MPH", 7.8, "#707b7c", ls=0.6))

    # activity rings
    p.append(ring(1560, 912, 37, 7, 0.68, "#c98a4a"))
    p.append(ring(1517, 986, 23, 5.5, 0.55, "#a488bf"))
    p.append(ring(1603, 986, 23, 5.5, 0.8, "#a7b06a"))
    p.append('<g transform="translate(1551 903)" fill="#d9c6a8" opacity="0.75">'
             '<rect x="0" y="8" width="2.6" height="6" rx="1.2"/>'
             '<rect x="5" y="3" width="2.6" height="11" rx="1.2"/>'
             '<rect x="10" y="6" width="2.6" height="8" rx="1.2"/></g>')
    p.append('</g>')
    p.append('<rect x="208" y="852" width="1504" height="196" rx="16" fill="none" stroke="#ffffff12"/>')
    return "\n".join(p)


# --------------------------------------------------------------------- build

def build():
    svg = [
        '<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'viewBox="0 0 {W} {H}" preserveAspectRatio="xMidYMid meet" '
        f'shape-rendering="geometricPrecision" text-rendering="geometricPrecision">',
        '<title>Nightfall Dashboard — starry night vector wallpaper</title>',
        '<desc>A dark-slate star field with a translucent monospace dashboard, '
        'service cards, a music artists panel and a bottom widget dock.</desc>',
        defs(),
        background(),
        main_panel(),
        artists_panel(),
        dock(),
        '<rect width="1920" height="1080" filter="url(#grain)" opacity="0.38"/>',
        '</svg>',
    ]
    text = "\n".join(svg)
    OUT.write_text(text, encoding="utf-8")
    print(f"wrote {OUT} ({OUT.stat().st_size / 1024:.1f} KiB)")


if __name__ == "__main__":
    build()
