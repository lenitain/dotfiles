"""
gen_anvil.py — 铁砧 (Anvil) wireframe model generator.

Anvil structure (Y-up):
  - base  : wide bottom plate
  - body  : tapered waist
  - face  : top work surface
  - horn  : tapered horn (elliptical cross-section)
  - holes : hardy + pritchel holes
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wrfm_utils import WrfmModel


def _ellipse_yz(model, x, yc, ry, rz, n):
    """Closed n-gon ellipse in the YZ plane at x."""
    pts = []
    for k in range(n):
        t = 2 * math.pi * k / n
        pts.append(model.add(x, yc + ry * math.sin(t), rz * math.cos(t)))
    model.cycle(pts)
    return pts


def _hubbed_circle(model, cx, cy, cz, r, n):
    """n-gon ring + centre vertex with radial spokes."""
    pts = []
    for k in range(n):
        t = 2 * math.pi * k / n
        pts.append(model.add(cx + r * math.cos(t), cy, cz + r * math.sin(t)))
    center = model.add(cx, cy, cz)
    model.cycle(pts)
    for p in pts:
        model.edge(center, p)
    return pts, center


def generate_anvil():
    model = WrfmModel()

    # =================== base ===================
    model.begin_group("base")
    base_bot = model.box8(0, 0.3, 0, 2.60, 0.6, 1.10)
    base_top = model.box8(0, 0.6, 0, 2.60, 0.6, 1.10)
    model.box_edges(base_bot)
    model.box_edges(base_top)
    model.connect_ring(base_bot, base_top)
    model.end_group()

    # =================== body ===================
    model.begin_group("body")
    b0 = model.box8(0, 0.6, 0, 2.00, 0.84, 0.84)
    b1 = model.box8(0, 1.0, 0, 1.70, 0.72, 0.72)
    b2 = model.box8(0, 1.5, 0, 1.40, 0.60, 0.60)
    for b in (b0, b1, b2):
        model.box_edges(b)
    model.connect_ring(b0, b1)
    model.connect_ring(b1, b2)
    model.connect_ring(base_top, b0)
    model.end_group()

    # =================== face ===================
    model.begin_group("face")
    face_bot = model.box8(-0.15, 1.5, 0, 2.00, 0.40, 0.60)
    face_top = model.box8(-0.15, 1.7, 0, 2.00, 0.40, 0.60)
    model.box_edges(face_bot)
    model.box_edges(face_top)
    model.connect_ring(face_bot, face_top)
    model.connect_ring(b2, face_bot)
    model.end_group()

    # =================== horn ===================
    model.begin_group("horn")
    N = 8
    h0 = _ellipse_yz(model, 1.10, 1.62, 0.10,  0.24,  N)
    h1 = _ellipse_yz(model, 1.60, 1.73, 0.075, 0.15,  N)
    h2 = _ellipse_yz(model, 2.10, 1.80, 0.055, 0.085, N)
    h3 = _ellipse_yz(model, 2.50, 1.85, 0.035, 0.045, N)
    tip = model.add(2.75, 1.90, 0.0)
    model.connect_ring(h0, h1)
    model.connect_ring(h1, h2)
    model.connect_ring(h2, h3)
    for k in range(N):
        model.edge(h3[k], tip)
    # Anchor horn root to the work face corners.
    model.edge(face_top[2], h0[1])
    model.edge(face_top[1], h0[3])
    model.edge(face_bot[2], h0[7])
    model.edge(face_bot[1], h0[5])
    model.end_group()

    # =================== holes ===================
    model.begin_group("holes")
    _hubbed_circle(model, -0.90, 1.70, 0.0, 0.09, 8)
    _hubbed_circle(model, -0.25, 1.70, 0.0, 0.05, 8)
    model.end_group()

    # =================== write ===================
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "wrfm_assests", "anvil.wrfm")
    model.write(out, comment="naviga model: anvil")


if __name__ == "__main__":
    generate_anvil()

