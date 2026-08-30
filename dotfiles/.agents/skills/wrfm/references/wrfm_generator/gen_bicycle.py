"""
gen_bicycle.py — Bicycle wireframe model generator.

Bicycle structure (Y-up, facing +Z):
  - wheels     : rear + front (rims, hubs, every-other-spoke)
  - frame      : diamond frame
  - fork       : crown + two legs
  - handlebar  : stem + bar
  - saddle     : saddle + post
  - drivetrain : chainring + cranks + pedals
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from wrfm_utils import WrfmModel


def _wheel(model, cx, cy, r, half_w, n):
    """Rim front/back + hub axle + every-other-spoke; returns (hub_f, hub_b)."""
    rim_f = model.ring(cx, cy,  half_w, r, n)
    rim_b = model.ring(cx, cy, -half_w, r, n)
    model.connect_ring(rim_f, rim_b)
    hub_f = model.add(cx, cy,  half_w)
    hub_b = model.add(cx, cy, -half_w)
    model.edge(hub_f, hub_b)
    for i in range(0, n, 2):
        model.edge(hub_f, rim_f[i])
        model.edge(hub_b, rim_b[i])
    return hub_f, hub_b


def _pedal(model, cx, cy, cz0, cz1):
    """Pedal rectangle and its 4 vertex indices."""
    a = model.add(cx,      cy, cz0)
    b = model.add(cx,      cy, cz1)
    c = model.add(cx+0.04, cy, cz1)
    d = model.add(cx+0.04, cy, cz0)
    model.cycle([a, b, c, d])
    return a, b, c, d


def generate_bicycle():
    model = WrfmModel()

    R = 0.35   # wheel radius
    TW = 0.04  # wheel half-width (z offset)
    N = 12     # rim segments
    M = 6      # chainring segments

    # =================== wheels ===================
    model.begin_group("wheels")
    rear_f, rear_b = _wheel(model, 0.00, 0.35, R, TW, N)
    front_f, front_b = _wheel(model, 1.10, 0.35, R, TW, N)
    model.end_group()

    # =================== frame ===================
    model.begin_group("frame")
    r_hub  = model.add(0.00, 0.35, 0.0)
    bb     = model.add(0.55, 0.34, 0.0)
    stt    = model.add(0.44, 0.86, 0.0)
    ht_top = model.add(0.99, 0.96, 0.0)
    ht_bot = model.add(0.96, 0.78, 0.0)

    # Diamond: seat-tube (stt) connects BB to the saddle post; head-tube
    # (ht_top -> ht_bot) holds the fork and stem. The top/seat/down tubes
    # are closed by the rear-hub bridge.
    for a, b in [(stt, ht_top), (bb, ht_bot), (bb, stt), (bb, r_hub),
                 (stt, r_hub), (ht_top, ht_bot), (r_hub, rear_f), (r_hub, rear_b)]:
        model.edge(a, b)
    model.end_group()

    # =================== fork ===================
    model.begin_group("fork")
    crown_l = model.add(0.96, 0.78, -0.05)
    crown_r = model.add(0.96, 0.78,  0.05)
    model.edge(crown_l, crown_r)
    for p in (crown_l, crown_r):
        model.edge(p, ht_bot)
    model.edge(crown_l, front_b)
    model.edge(crown_r, front_f)
    model.end_group()

    # =================== handlebar ===================
    model.begin_group("handlebar")
    bar_lt = model.add(0.99, 1.09,  -0.30)
    bar_rt = model.add(0.99, 1.09,   0.30)
    bar_lb = model.add(0.99, 1.00,  -0.30)
    bar_rb = model.add(0.99, 1.00,   0.30)
    stem_top = model.add(0.99, 1.045, 0.0)

    bar = [bar_lt, bar_rt, bar_rb, bar_lb]
    model.cycle(bar)
    for p in bar:
        model.edge(stem_top, p)
    model.edge(ht_top, stem_top)
    # Diagonal from the head tube top to one bar end so the head tube
    # stays attached even after a render hides the stem.
    model.edge(bar_rt, ht_top)
    model.end_group()

    # =================== saddle ===================
    model.begin_group("saddle")
    s_bl = model.add(0.22, 0.95, -0.09)
    s_br = model.add(0.22, 0.95,  0.09)
    s_nl = model.add(0.52, 0.97, -0.04)
    s_nr = model.add(0.52, 0.97,  0.04)
    sp_top = model.add(0.37, 0.93, 0.0)

    saddle = [s_bl, s_br, s_nr, s_nl]
    model.cycle(saddle)
    for p in saddle:
        model.edge(sp_top, p)
    model.edge(stt, sp_top)
    # Diagonal from the seat tube to the saddle rear so the saddle stays
    # attached when the seat-post is hidden.
    model.edge(s_bl, stt)
    model.end_group()

    # =================== drivetrain ===================
    model.begin_group("drivetrain")
    cr = model.ring(0.55, 0.34, 0.0, 0.09, M)
    for i in range(M):
        model.edge(cr[i], bb)

    crank1 = model.add(0.62, 0.26,  0.05)
    crank2 = model.add(0.48, 0.42, -0.05)
    model.edge(bb, crank1)
    model.edge(bb, crank2)
    # Anchor the cranks to opposite chainring vertices so the ring stays
    # attached through any view.
    model.edge(crank1, cr[0])
    model.edge(crank2, cr[M // 2])

    p1 = _pedal(model, 0.60, 0.26,  0.09,  0.17)
    p2 = _pedal(model, 0.46, 0.42, -0.09, -0.17)
    for pt in p1:
        model.edge(crank1, pt)
    for pt in p2:
        model.edge(crank2, pt)
    model.end_group()

    # =================== write ===================
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "wrfm_assests", "bicycle.wrfm")
    model.write(out, comment="naviga model: bicycle")


if __name__ == "__main__":
    generate_bicycle()
