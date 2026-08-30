"""
gen_washing_machine.py — 洗衣机 (Washing Machine) wireframe model generator.

Washer structure (Y-up, front face +Z):
  - cabinet : main box
  - plinth  : skirt at the bottom
  - belt    : horizontal belt ring at y = 4.35 (carries drawer/panel)
  - door    : round porthole with spokes
  - drawer  : detergent drawer
  - panel   : control panel with display + knobs
  - handle  : door pull
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wrfm_utils import WrfmModel


def _spoked_wheel(model, cx, cy, cz, nouter, ninner, r_outer, r_inner,
                  offset_deg=22.5, inner_lift=0.08, hub_lift=0.16):
    """Round porthole: outer ring on the panel surface, inner ring stepped out
    by inner_lift, hub stepped out further by hub_lift, with radial spokes."""
    outer = model.ring(cx, cy, cz, r_outer, nouter)
    inner = model.ring(cx, cy, cz + inner_lift, r_inner, ninner, offset_deg)
    hub = model.add(cx, cy, cz + hub_lift)
    for k in range(nouter):
        model.edge(outer[k], inner[k // (nouter // ninner)])
    for k in range(ninner):
        model.edge(inner[k], hub)
    return outer, inner, hub


def _add_knob(model, cx, cy, cz, r):
    ring_verts = model.ring(cx, cy, cz, r, 8)
    center = model.add(cx, cy, cz)
    for v in ring_verts:
        model.edge(center, v)
    return ring_verts, center


def generate_washing_machine():
    model = WrfmModel()

    # =================== cabinet ===================
    model.begin_group("cabinet")
    cab = model.box8(0, 2.5, 0, 4.0, 5.0, 3.0)
    model.box_edges(cab)
    # Front (+z) face corners, ordered like the original.
    fbl, fbr, ftr, ftl = cab[4], cab[5], cab[6], cab[7]
    bbl, bbr, btr, btl = cab[0], cab[1], cab[2], cab[3]

    # Plinth (skirt) below the cabinet.
    plinth = [
        model.add(-2, -0.4, 1.5),
        model.add(2, -0.4, 1.5),
        model.add(2, -0.4, -1.5),
        model.add(-2, -0.4, -1.5),
    ]
    for a, b in zip(plinth, plinth[1:] + [plinth[0]]):
        model.edge(a, b)
    model.edge(fbl, plinth[0])
    model.edge(fbr, plinth[1])
    model.edge(bbr, plinth[2])
    model.edge(bbl, plinth[3])

    # Belt ring at y = 4.35 carries the drawer and the panel.
    belt = [
        model.add(-2, 4.35, 1.5),
        model.add(2, 4.35, 1.5),
        model.add(2, 4.35, -1.5),
        model.add(-2, 4.35, -1.5),
    ]
    for a, b in [(belt[1], belt[2]), (belt[2], belt[3]), (belt[3], belt[0])]:
        model.edge(a, b)
    model.edge(ftl, belt[0])
    model.edge(ftr, belt[1])
    model.edge(btr, belt[2])
    model.edge(btl, belt[3])
    model.end_group()

    # =================== door ===================
    model.begin_group("door")
    door_outer, door_inner, _ = _spoked_wheel(
        model, cx=0.0, cy=2.0, cz=1.5, nouter=16, ninner=8,
        r_outer=1.5, r_inner=0.85,
    )
    model.end_group()

    # =================== drawer ===================
    model.begin_group("drawer")
    drawer = [
        model.add(-1.6, 2.9, 1.5),
        model.add(-0.9, 2.9, 1.5),
        model.add(-0.9, 3.4, 1.5),
        model.add(-1.6, 3.4, 1.5),
    ]
    model.cycle(drawer)

    bd0 = model.add(-1.6, 4.35, 1.5)
    bd1 = model.add(-0.9, 4.35, 1.5)
    model.edge(drawer[3], bd0)
    model.edge(drawer[2], bd1)
    model.edge(belt[0], bd0)
    model.edge(bd0, bd1)
    model.edge(bd1, belt[1])

    model.edge(drawer[0], door_outer[7])
    model.edge(drawer[1], door_outer[6])
    model.end_group()

    # =================== panel ===================
    model.begin_group("panel")
    t0 = model.add(1.05, 5, 1.5)
    t1 = model.add(0.45, 5, 1.5)
    model.edge(ftr, t0); model.edge(t0, t1); model.edge(t1, ftl)

    s0 = model.add(1.05, 4.35, 1.5)
    s1 = model.add(0.45, 4.35, 1.5)
    model.edge(bd1, s1); model.edge(s1, s0); model.edge(s0, belt[1])

    display = [
        model.add(0.45, 4.55, 1.5),
        model.add(1.05, 4.55, 1.5),
        model.add(1.05, 4.90, 1.5),
        model.add(0.45, 4.90, 1.5),
    ]
    model.cycle(display)
    model.edge(display[0], s1)
    model.edge(display[1], s0)
    model.edge(display[2], t0)
    model.edge(display[3], t1)

    k1, _ = _add_knob(model, 1.35, 4.70, 1.5, 0.13)
    k2, _ = _add_knob(model, 1.75, 4.70, 1.5, 0.13)

    bx1 = model.add(1.35, 4.35, 1.5)
    bx2 = model.add(1.75, 4.35, 1.5)
    model.edge(s0, bx1); model.edge(bx1, bx2); model.edge(bx2, belt[1])
    model.edge(k1[6], bx1)
    model.edge(k2[6], bx2)
    model.end_group()

    # =================== handle ===================
    model.begin_group("handle")
    h_ring = model.ring(1.70, 2.30, 1.5, 0.18, 8)
    h_ctr = model.add(1.70, 2.30, 1.5)
    for v in h_ring:
        model.edge(h_ctr, v)
    model.edge(h_ring[5], door_outer[0])
    model.end_group()

    # =================== write ===================
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "wrfm_assests", "washing_machine.wrfm")
    model.write(out, comment="naviga model: washing_machine")


if __name__ == "__main__":
    generate_washing_machine()
