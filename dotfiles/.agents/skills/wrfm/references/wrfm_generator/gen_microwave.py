"""
gen_microwave.py — 微波炉 (Microwave) wireframe model generator.

Microwave structure (Y-up, front face +Z):
  - cabinet : main box
  - door    : hinged door (left half of the front)
  - window  : glass window inset in the door
  - handle  : vertical door pull
  - panel   : control panel (right of the door)
  - vent    : top vents
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wrfm_utils import WrfmModel


def rect(model, pts):
    model.cycle(pts)


def generate_microwave():
    model = WrfmModel()

    # =================== cabinet ===================
    model.begin_group("cabinet")
    cab = model.box8(0, 1.75, 0, 6.0, 3.5, 4.5)
    model.box_edges(cab)
    # Front (+z) corners, in the original layout (bl, br, tr, tl).
    fbl, fbr, ftr, ftl = cab[4], cab[5], cab[6], cab[7]
    model.end_group()

    # =================== door ===================
    model.begin_group("door")
    door_split_lo = model.add(0.9, 0.0, 2.25)
    door_split_hi = model.add(0.9, 3.5, 2.25)
    model.edge(fbl, door_split_lo); model.edge(door_split_lo, fbr)
    model.edge(ftl, door_split_hi); model.edge(door_split_hi, ftr)

    door = [
        model.add(-2.9, 0.1, 2.25),
        model.add(0.9, 0.1, 2.25),
        model.add(0.9, 3.4, 2.25),
        model.add(-2.9, 3.4, 2.25),
    ]
    rect(model, door)

    slot_lo = model.add(-2.9, 1.2, 2.25)
    slot_hi = model.add(-2.9, 2.3, 2.25)
    model.edge(door[0], slot_lo); model.edge(slot_lo, slot_hi); model.edge(slot_hi, door[3])

    for a, b in zip(door, (fbl, door_split_lo, door_split_hi, ftl)):
        model.edge(a, b)
    model.end_group()

    # =================== window ===================
    model.begin_group("window")
    window = [
        model.add(-2.65, 0.35, 2.28),
        model.add(0.65, 0.35, 2.28),
        model.add(0.65, 3.15, 2.28),
        model.add(-2.65, 3.15, 2.28),
    ]
    rect(model, window)
    for w, d in zip(window, door):
        model.edge(w, d)
    model.end_group()

    # =================== handle ===================
    model.begin_group("handle")
    handle = [
        model.add(-3.15, 1.2, 2.5),
        model.add(-2.80, 1.2, 2.5),
        model.add(-2.80, 2.3, 2.5),
        model.add(-3.15, 2.3, 2.5),
    ]
    rect(model, handle)
    model.edge(handle[0], slot_lo); model.edge(handle[1], slot_lo)
    model.edge(handle[3], slot_hi); model.edge(handle[2], slot_hi)
    model.end_group()

    # =================== panel ===================
    model.begin_group("panel")
    # Top divider between door and panel.
    panel_div = model.add(2.0, 3.5, 2.25)
    model.edge(door_split_hi, panel_div); model.edge(panel_div, ftr)

    # Display screen rectangle.
    screen = [
        model.add(1.2, 2.7, 2.28),
        model.add(2.8, 2.7, 2.28),
        model.add(2.8, 3.3, 2.28),
        model.add(1.2, 3.3, 2.28),
    ]
    rect(model, screen)
    model.edge(screen[2], panel_div); model.edge(screen[3], panel_div)

    # Knob base stations along the front edge.
    base = [
        model.add(0.9, 2.55, 2.25),
        model.add(1.5, 2.55, 2.25),
        model.add(2.1, 2.55, 2.25),
        model.add(2.7, 2.55, 2.25),
        model.add(3.0, 2.55, 2.25),
    ]
    # Bridge from door edge to first knob station.
    model.edge(door[1], base[0]); model.edge(base[0], door[2])
    for a, b in zip(base, base[1:]):
        model.edge(a, b)
    model.edge(fbr, base[4]); model.edge(base[4], ftr)
    model.edge(screen[0], base[1])  # screen bottom-left -> first knob base
    model.edge(screen[1], base[3])  # screen bottom-right -> button base

    # Two cylindrical knobs (each centred on its base station).
    for knob_anchor in base[1:3]:
        x = model.verts[knob_anchor][0]
        ring_lo = model.ring(x, 2.55, 2.25, 0.17, 8)
        ring_hi = model.ring(x, 2.55, 2.33, 0.17, 8, 22.5)
        model.connect_ring(ring_lo, ring_hi)
        model.edge(ring_lo[6], knob_anchor)

    # Display button (small star).
    bx = model.verts[base[3]][0]
    b_lo = model.ring(bx, 2.55, 2.32, 0.13, 6, 30)
    b_ctr = model.add(bx, 2.55, 2.32)
    for p in b_lo:
        model.edge(b_ctr, p)
    model.edge(b_ctr, base[3])
    model.end_group()

    # =================== vent ===================
    model.begin_group("vent")
    back_left = model.add(0.5, 3.5, -2.25)
    front_right = model.add(2.5, 3.5, 2.25)
    model.edge(cab[3], back_left); model.edge(back_left, cab[2])
    model.edge(ftl, front_right); model.edge(front_right, ftr)

    slots = []
    for k in range(3):
        z0 = -1.5 + k * 0.6
        slots.append([
            model.add(0.5, 3.5, z0),
            model.add(2.5, 3.5, z0),
            model.add(2.5, 3.5, z0 + 0.35),
            model.add(0.5, 3.5, z0 + 0.35),
        ])

    for s in slots:
        rect(model, s)
    for a, b in zip(slots, slots[1:]):
        for p, q in zip(a, b):
            model.edge(p, q)

    model.edge(slots[0][0], back_left)
    model.edge(slots[2][2], front_right)
    model.end_group()

    # =================== write ===================
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "wrfm_assests", "microwave.wrfm")
    model.write(out, comment="naviga model: microwave")


if __name__ == "__main__":
    generate_microwave()
