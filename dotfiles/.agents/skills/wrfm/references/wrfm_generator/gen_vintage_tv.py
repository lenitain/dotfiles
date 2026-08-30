"""
gen_vintage_tv.py — 复古电视 (Vintage TV) wireframe model generator.

Vintage TV structure (Y-up, front face +Z):
  - cabinet : main wood-look box
  - screen  : CRT bulge (bezel + tube)
  - grille  : speaker grille on the right of the screen
  - knobs   : two knobs + a small button below the screen
  - legs    : four short tapered legs
  - antenna : box base + two rod antennas with rabbit-ear tips
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wrfm_utils import WrfmModel


def rounded_rect(model, cx, cy, z, wx, wy, r, nside=2, ncorner=3):
    """Closed rounded rectangle polygon. Returns (idxs, corner_idx) where
    corner_idx maps a label to the corresponding global vertex index.

    Path goes counter-clockwise starting from the bottom-left of the bottom
    side. The 8 labelled vertices are the four side-arc junctions
    (one per side) plus the four arc-side junctions (one per corner):
      bl, br, tr, tr2, tl, tl2, bl2, bl3
    """
    pts2d = []
    labels = {}

    def push(x, y, label=None):
        idx = model.add(x, y, z)
        pts2d.append(idx)
        if label is not None:
            labels[label] = idx

    # Bottom side: bl -> (nside internal) -> br.
    push(cx - wx + r, cy - wy, "bl")
    for k in range(1, nside + 1):
        t = k / (nside + 1)
        push(cx - wx + r + (2 * wx - 2 * r) * t, cy - wy)
    push(cx + wx - r, cy - wy, "br")
    # BR corner arc (270 -> 360) -> tr.
    for k in range(1, ncorner + 1):
        a = math.radians(270 + 90 * k / (ncorner + 1))
        push(cx + wx - r + r * math.cos(a), cy - wy + r + r * math.sin(a))
    push(cx + wx, cy - wy + r, "tr")
    # Right side -> tr2. The middle point (when nside is odd) is labelled
    # "rm" so callers can anchor a face subdivision there.
    for k in range(1, nside + 1):
        t = k / (nside + 1)
        mid_label = "rm" if nside % 2 == 1 and k == (nside + 1) // 2 else None
        push(cx + wx, cy - wy + r + (2 * wy - 2 * r) * t, mid_label)
    push(cx + wx, cy + wy - r, "tr2")
    # TR corner arc (0 -> 90) -> tl.
    for k in range(1, ncorner + 1):
        a = math.radians(0 + 90 * k / (ncorner + 1))
        push(cx + wx - r + r * math.cos(a), cy + wy - r + r * math.sin(a))
    push(cx + wx - r, cy + wy, "tl")
    # Top side (right -> left) -> tl2.
    for k in range(1, nside + 1):
        t = k / (nside + 1)
        push(cx + wx - r - (2 * wx - 2 * r) * t, cy + wy)
    push(cx - wx + r, cy + wy, "tl2")
    # TL corner arc (90 -> 180) -> bl2.
    for k in range(1, ncorner + 1):
        a = math.radians(90 + 90 * k / (ncorner + 1))
        push(cx - wx + r + r * math.cos(a), cy + wy - r + r * math.sin(a))
    push(cx - wx, cy + wy - r, "bl2")
    # Left side (top -> bottom) -> bl3. The middle point is labelled "lm".
    for k in range(1, nside + 1):
        t = k / (nside + 1)
        mid_label = "lm" if nside % 2 == 1 and k == (nside + 1) // 2 else None
        push(cx - wx, cy + wy - r - (2 * wy - 2 * r) * t, mid_label)
    push(cx - wx, cy - wy + r, "bl3")
    # BL corner arc (180 -> 270) closes the polygon.
    for k in range(1, ncorner + 1):
        a = math.radians(180 + 90 * k / (ncorner + 1))
        push(cx - wx + r + r * math.cos(a), cy - wy + r + r * math.sin(a))

    model.cycle(pts2d)
    return pts2d, labels


def generate_vintage_tv():
    model = WrfmModel()

    # =================== cabinet ===================
    model.begin_group("cabinet")
    cab = model.box8(0, 2.3, 0.1, 6.0, 4.6, 3.8)  # x[-3,3], y[0,4.6], z[-1.8,2.0]
    model.box_edges(cab)
    fbl, fbr, ftr, ftl = cab[4], cab[5], cab[6], cab[7]
    bbl, bbr, btr, btl = cab[0], cab[1], cab[2], cab[3]

    # Front subdivs (extra vertices along the front face edges, used to
    # anchor the screen, grille, knobs and legs).
    fb_x = [-2.55, -1.75, -1.0, 0.2, 1.3, 1.75, 2.55]
    fb = [model.add(x, 0.0, 2.0) for x in fb_x]
    model.edge(fbl, fb[0])
    for a, b in zip(fb, fb[1:]):
        model.edge(a, b)
    model.edge(fb[-1], fbr)
    fbx = dict(zip(fb_x, fb))

    model.edge(fb[3], bbl); model.edge(fb[3], bbr)
    model.edge(fb[1], bbl); model.edge(fb[5], bbr)

    ft_x = [-1.75, -0.45, 0.45, 1.75]
    ft = [model.add(x, 4.6, 2.0) for x in ft_x]
    model.edge(ftl, ft[0])
    for a, b in zip(ft, ft[1:]):
        model.edge(a, b)
    model.edge(ft[-1], ftr)
    ftx = dict(zip(ft_x, ft))
    model.edge(ft[1], btl); model.edge(ft[2], btr); model.edge(ft[0], btl)

    fl_y = [1.4, 2.25, 3.1]
    fl = [model.add(-3.0, y, 2.0) for y in fl_y]
    model.edge(fbl, fl[0])
    for a, b in zip(fl, fl[1:]):
        model.edge(a, b)
    model.edge(fl[-1], ftl)
    model.edge(fl[1], bbl); model.edge(fl[1], btl); model.edge(fl[2], btl)

    fr_y = [1.0, 2.25, 3.5]
    fr = [model.add(3.0, y, 2.0) for y in fr_y]
    model.edge(fbr, fr[0])
    for a, b in zip(fr, fr[1:]):
        model.edge(a, b)
    model.edge(fr[-1], ftr)

    bb_x = [-2.55, 2.55]
    bb = [model.add(x, 0.0, -1.8) for x in bb_x]
    model.edge(bbl, bb[0])
    model.edge(bb[0], bb[1])
    model.edge(bb[1], bbr)
    bbx = dict(zip(bb_x, bb))

    bt_x = [-0.45, 0.45]
    bt = [model.add(x, 4.6, -1.8) for x in bt_x]
    model.edge(btl, bt[0])
    model.edge(bt[0], bt[1])
    model.edge(bt[1], btr)

    # Extra cross-cabinet structural lines that make the cabinet read as a
    # solid box rather than a flat frame.
    model.edge(fbl, bt[1])
    model.edge(fbl, ftx[1.75])
    model.edge(bbl, fr[0])
    model.end_group()

    # =================== screen ===================
    model.begin_group("screen")
    rim_f, rim_f_c = rounded_rect(model, 0.0, 2.25, 2.30, 2.35, 1.45, 0.6, nside=3, ncorner=3)
    rim_b, rim_b_c = rounded_rect(model, 0.0, 2.25, 2.18, 2.35, 1.45, 0.6, nside=3, ncorner=3)
    for a, b in zip(rim_f, rim_b):
        model.edge(a, b)

    tub_f, tub_f_c = rounded_rect(model, 0.0, 2.25, 2.06, 2.10, 1.20, 0.45, nside=3, ncorner=3)
    tub_b, tub_b_c = rounded_rect(model, 0.0, 2.25, 1.92, 2.10, 1.20, 0.45, nside=3, ncorner=3)
    for a, b in zip(tub_f, tub_b):
        model.edge(a, b)

    # Bezel back -> cabinet front. The bezel back side midpoints ("lm", "rm")
    # are used as anchors for the face subdivisions fl[1] / fr[1].
    model.edge(rim_b_c["bl3"], fl[0])
    model.edge(rim_b_c["lm"], fl[1])
    model.edge(rim_b_c["bl2"], fl[2])
    model.edge(rim_b_c["tr"], fr[0])
    model.edge(rim_b_c["rm"], fr[1])
    model.edge(rim_b_c["tr2"], fr[2])
    model.edge(rim_b_c["bl"], fbx[-1.75])
    model.edge(rim_b_c["br"], fbx[1.75])
    model.edge(rim_b_c["tl2"], ftx[-1.75])
    model.edge(rim_b_c["tl"], ftx[1.75])

    # Tube face -> bezel back.
    model.edge(tub_f_c["bl"], rim_b_c["bl3"])
    model.edge(tub_f_c["br"], rim_b_c["br"])
    model.end_group()

    # =================== grille ===================
    model.begin_group("grille")
    gz = 2.1
    gx0, gx1 = 2.45, 2.95
    gy0, gy1 = 1.0, 3.5
    g_bl = model.add(gx0, gy0, gz)
    g_lm = model.add(gx0, 2.25, gz)
    g_tl = model.add(gx0, gy1, gz)
    g_br = model.add(gx1, gy0, gz)
    g_rm = model.add(gx1, 2.25, gz)
    g_tr = model.add(gx1, gy1, gz)
    model.edge(g_bl, g_lm); model.edge(g_lm, g_tl)
    model.edge(g_br, g_rm); model.edge(g_rm, g_tr)

    div_x = [2.6, 2.7, 2.8]
    g_bot = [model.add(x, gy0, gz) for x in div_x]
    g_top = [model.add(x, gy1, gz) for x in div_x]
    model.edge(g_bl, g_bot[0])
    for a, b in zip(g_bot, g_bot[1:]):
        model.edge(a, b)
    model.edge(g_bot[-1], g_br)
    model.edge(g_tr, g_top[-1])
    for i in range(len(g_top) - 1, 0, -1):
        model.edge(g_top[i], g_top[i - 1])
    model.edge(g_top[0], g_tl)
    for b, t in zip(g_bot, g_top):
        model.edge(b, t)
    model.edge(g_lm, g_bot[0])

    model.edge(g_br, fr[0]); model.edge(g_rm, fr[1]); model.edge(g_tr, fr[2])
    model.edge(g_bl, fbx[2.55]); model.edge(g_tl, ftx[1.75])
    model.end_group()

    # =================== knobs ===================
    model.begin_group("knobs")
    def knob(cx, r):
        ring_lo = model.ring(cx, 0.35, 2.03, r, 6)
        ring_hi = model.ring(cx, 0.35, 2.13, r, 6, 30.0)
        model.connect_ring(ring_lo, ring_hi)
        model.edge(ring_lo[4], fbx[cx])
        model.edge(ring_lo[5], fbx[cx])

    knob(-1.0, 0.18)
    knob(0.2, 0.18)

    # Small star button.
    b_ring = model.ring(1.3, 0.35, 2.12, 0.11, 5, 90.0)
    b_ctr = model.add(1.3, 0.35, 2.12)
    for p in b_ring:
        model.edge(b_ctr, p)
    model.edge(b_ctr, fbx[1.3])
    model.end_group()

    # =================== legs ===================
    model.begin_group("legs")
    def leg(cx, cz, th, bh):
        top = [model.add(cx - th, 0.0, cz - th),
               model.add(cx + th, 0.0, cz - th),
               model.add(cx + th, 0.0, cz + th),
               model.add(cx - th, 0.0, cz + th)]
        bot = [model.add(cx - bh, -0.5, cz - bh),
               model.add(cx + bh, -0.5, cz - bh),
               model.add(cx + bh, -0.5, cz + bh),
               model.add(cx - bh, -0.5, cz + bh)]
        model.cycle(top)
        model.cycle(bot)
        for k in range(4):
            model.edge(top[k], bot[k])
        return top

    fl_top = leg(-2.55, 1.3, 0.32, 0.24)
    fr_top = leg(2.55, 1.3, 0.32, 0.24)
    bl_top = leg(-2.55, -1.15, 0.32, 0.24)
    br_top = leg(2.55, -1.15, 0.32, 0.24)
    for v in fl_top + bl_top:
        model.edge(v, fbx[-2.55] if v in fl_top else bbx[-2.55])
    for v in fr_top + br_top:
        model.edge(v, fbx[2.55] if v in fr_top else bbx[2.55])
    model.end_group()

    # =================== antenna ===================
    model.begin_group("antenna")
    ab = model.box8(0.0, 4.675, 0.0, 0.9, 0.15, 0.9)
    model.box_edges(ab)
    model.edge(ab[4], ftx[-0.45]); model.edge(ab[5], ftx[0.45])
    model.edge(ab[0], bt[0]); model.edge(ab[1], bt[1])

    def rod(anchor, mid_pt, tip_pt, mid_r=0.08, tip_r=0.12):
        mid = model.add(*mid_pt)
        tip = model.add(*tip_pt)
        model.edge(anchor, mid)
        model.edge(mid, tip)

        def tip_loop(center, cidx, radius):
            pts = []
            for k in range(4):
                ang = math.radians(45 + 90 * k)
                pts.append(model.add(center[0] + radius * math.cos(ang),
                                     center[1],
                                     center[2] + radius * math.sin(ang)))
            model.cycle(pts)
            for p in pts:
                model.edge(cidx, p)

        tip_loop(tip_pt, tip, tip_r)
        tip_loop(mid_pt, mid, mid_r)

    rod(ab[7], (-1.2, 6.1, 0.3), (-2.0, 7.5, 0.2))
    rod(ab[6], (1.2, 6.1, 0.3), (2.0, 7.5, 0.2))
    model.end_group()

    # =================== write ===================
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "wrfm_assests", "vintage_tv.wrfm")
    model.write(out, comment="naviga model: vintage_tv")


if __name__ == "__main__":
    generate_vintage_tv()
