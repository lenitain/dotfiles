import math

# ============================================================
# Toilet (马桶) generator — reverse-engineered from
#   wrfm_assests/toilet.wrfm  (182 vertices, 193 edges, no groups)
#
# Anatomy (Y-up; the bowl faces +Z, the tank sits at -Z / top):
#   tank  : two stacked boxes (0-7, 8-15) + flush button octagon
#           (16-23) + side flush lever (24-29)
#   bowl  : "D"-shaped rings — rim outer (30-46) & rim inner (47-63),
#           the hole (64-76), mid (89-101), bottom (102-114) and
#           throat (127-137) rings; front posts (77-84), wishbone
#           legs (115-126), hanging throat points (138-139),
#           bowl-to-tank posts (85-88)
#   base  : pedestal rings (140-156, 157-173) + leg posts (174-181)
#
# Every "D" ring is a half-ellipse arc
#     x = a*cos(alpha),  z = z_back + b*sin(alpha),
#     alpha = 180*(k+1)/(n+1)   (k = 0 .. n-1)
# plus a flat back edge at z = z_back between the two corners.
# The a/b values below match the original's 3-decimal rounding
# exactly (they are within ~1e-4 of the nominal a=W, b=front-z_back).
# ============================================================

verts = []      # list of (x, y, z)
edges = []      # list of (i, j)

def add(x, y, z):
    idx = len(verts)
    verts.append((x, y, z))
    return idx

def edge(a, b):
    edges.append((a, b))

def box8(cx, cy, cz, sx, sy, sz):
    """8 corners of an axis-aligned box in the toilet's corner order.
    z is the toilet front(+)/back(-) axis."""
    x0, x1 = cx - sx / 2, cx + sx / 2
    y0, y1 = cy - sy / 2, cy + sy / 2
    z0, z1 = cz - sz / 2, cz + sz / 2
    return [add(x0, y0, z0), add(x1, y0, z0), add(x0, y1, z0),
            add(x0, y0, z1), add(x1, y0, z1), add(x0, y1, z1),
            add(x1, y1, z0), add(x1, y1, z1)]

def box_edges(b):
    for a, c in [(0, 1), (0, 2), (0, 3), (1, 4), (1, 6), (2, 5),
                 (2, 6), (3, 4), (3, 5), (4, 7), (5, 7), (6, 7)]:
        edge(b[a], b[c])

def ring(y, W, z_back, front, n, a, b):
    """D-shaped ring: flat back edge + front half-ellipse arc.
    Returns (backL, backR, arc) where arc[0] is the right shoulder
    (alpha smallest) and arc[-1] the left shoulder."""
    backL = add(-W, y, z_back)
    backR = add(W, y, z_back)
    arc = []
    for k in range(1, n + 1):
        alpha = math.radians(180.0 * k / (n + 1))
        arc.append(add(a * math.cos(alpha), y, z_back + b * math.sin(alpha)))
    edge(backL, backR)          # flat back
    edge(backL, arc[0])         # back corner -> right shoulder
    edge(arc[-1], backR)        # left shoulder -> back corner
    for k in range(n - 1):
        edge(arc[k], arc[k + 1])
    return backL, backR, arc

def ring_pt(y, a, b, z_back, alpha_deg):
    """A standalone point ON the same ellipse as ring() at a given angle."""
    al = math.radians(alpha_deg)
    return add(a * math.cos(al), y, z_back + b * math.sin(al))

# ring nominal parameters: (W, z_back, front, n_arc, a, b)
RIM  = (0.34, -0.18, 0.300, 15, 0.34005, 0.48009)   # rim outer & inner
HOLE = (0.20, -0.18, 0.120, 11, 0.19980, 0.30010)   # bowl opening
MID  = (0.30, -0.18, 0.250, 11, 0.30010, 0.42980)   # mid bowl ring
BOT  = (0.23, -0.18, 0.150, 11, 0.22985, 0.32997)   # bowl bottom ring
THRT = (0.16, -0.18, 0.070,  9, 0.15978, 0.25002)   # throat (S-trap) ring
BASE = (0.28, -0.40, 0.220, 15, 0.28019, 0.62004)   # pedestal rings

# =================== vertices (file order) ===================
# 1. tank (0-7)
tank = box8(0.0, 0.88, -0.30, 0.52, 0.40, 0.24)
box_edges(tank)

# 2. tank lid (8-15)
lid = box8(0.0, 1.11, -0.30, 0.58, 0.06, 0.29)
box_edges(lid)

# 3. flush button, octagon (16-23)
btn = []
for k in range(8):
    th = math.radians(45.0 * k)
    btn.append(add(0.05 * math.cos(th), 1.15, -0.30 + 0.05 * math.sin(th)))
for k in range(8):
    edge(btn[k], btn[(k + 1) % 8])

# 4. flush lever, right side (24-29)
lv = [add(0.260, 0.96, -0.300),   # on the tank wall
      add(0.380, 0.96, -0.300),
      add(0.410, 0.96, -0.300),   # tip
      add(0.380, 0.96, -0.270),
      add(0.350, 0.96, -0.300),
      add(0.380, 0.96, -0.330)]
edge(lv[0], lv[1])                       # arm out of the tank
edge(lv[2], lv[3]); edge(lv[2], lv[5])   # tip diamond
edge(lv[3], lv[4]); edge(lv[4], lv[5])

# 5. rim outer (30-46)
W, zb, fr, n, a, b = RIM
rim_out = ring(0.56, W, zb, fr, n, a, b)

# 6. rim inner (47-63)
rim_in = ring(0.62, W, zb, fr, n, a, b)

# 7. bowl opening (64-76)
W, zb, fr, n, a, b = HOLE
hole = ring(0.62, W, zb, fr, n, a, b)

# 8. front posts on the seat rim (77-84)
for al in (30.0, 60.0, 120.0, 150.0):
    lo = ring_pt(0.56, RIM[4], RIM[5], RIM[1], al)
    hi = ring_pt(0.62, RIM[4], RIM[5], RIM[1], al)
    edge(lo, hi)

# 9. bowl -> tank posts (85-88)
for sx in (-1.0, 1.0):
    lo = add(0.12 * sx, 0.62, -0.18)
    hi = add(0.12 * sx, 0.68, -0.18)
    edge(lo, hi)

# 10. mid bowl ring (89-101)
W, zb, fr, n, a, b = MID
mid = ring(0.46, W, zb, fr, n, a, b)

# 11. bowl bottom ring (102-114)
W, zb, fr, n, a, b = BOT
bot = ring(0.30, W, zb, fr, n, a, b)

# 12. wishbone legs: rim -> mid -> bowl bottom (115-126)
leg_angles = (36.0, 72.0, 108.0, 144.0)
wish_mid = []
for al in leg_angles:
    t = ring_pt(0.56, RIM[4], RIM[5], RIM[1], al)   # on rim outer
    m = ring_pt(0.46, MID[4], MID[5], MID[1], al)    # on mid ring
    wish_mid.append(m)
    edge(t, m)
wish_bot = []
for al in leg_angles:
    b = ring_pt(0.30, BOT[4], BOT[5], BOT[1], al)    # on bowl bottom
    wish_bot.append(b)
    edge(wish_mid[len(wish_bot) - 1], b)

# 13. throat ring (127-137)
W, zb, fr, n, a, b = THRT
throat = ring(0.42, W, zb, fr, n, a, b)

# 14. hanging throat points (138-139)
hang = [ring_pt(0.42, THRT[4], THRT[5], THRT[1], 45.0),
        ring_pt(0.42, THRT[4], THRT[5], THRT[1], 135.0)]

# 15. pedestal bottom ring (140-156)
W, zb, fr, n, a, b = BASE
base_lo = ring(0.02, W, zb, fr, n, a, b)

# 16. pedestal top ring (157-173)
base_hi = ring(0.10, W, zb, fr, n, a, b)

# 17. pedestal legs (174-181)
ped_hi = []
for (x, z) in [(0.227, -0.036), (0.086, 0.190),
               (-0.086, 0.190), (-0.227, -0.036)]:
    lo = add(x, 0.02, z)
    hi = add(x, 0.10, z)
    ped_hi.append(hi)
    edge(lo, hi)

# =================== vertical connections ===================
# seat band: rim outer <-> rim inner
edge(rim_out[0], rim_in[0])          # 30-47 back-left
edge(rim_out[1], rim_in[1])          # 31-48 back-right
edge(rim_out[2][7], rim_in[2][7])    # 39-56 front centre
# bowl back spine: rim -> mid -> bottom -> pedestal top
edge(rim_out[0], mid[0])             # 30-89
edge(rim_out[1], mid[1])             # 31-90
edge(mid[0], bot[0])                 # 89-102
edge(mid[1], bot[1])                 # 90-103
edge(bot[0], base_hi[0])             # 102-157
edge(bot[1], base_hi[1])             # 103-158
# hole -> throat
edge(hole[0], throat[0])             # 64-127
edge(hole[1], throat[1])             # 65-128
edge(hole[2][5], throat[2][4])       # 71-133 front centres
edge(hole[2][2], hang[0])            # 68-138
edge(hole[2][8], hang[1])            # 74-139
# pedestal band
edge(base_lo[0], base_hi[0])         # 140-157
edge(base_lo[1], base_hi[1])         # 141-158
# bowl bottom -> pedestal top legs
for i in range(4):
    edge(wish_bot[i], ped_hi[i])     # 123-175, 124-177, 125-179, 126-181

# ---------------- sanity checks ----------------
assert len(verts) == 182, len(verts)
assert len(edges) == 193, len(edges)

deg = [0] * len(verts)
for (i, j) in edges:
    deg[i] += 1
    deg[j] += 1
print(f"vertices={len(verts)} edges={len(edges)} "
      f"min_degree={min(deg)} max_degree={max(deg)}")

# ---------------- write (edges sorted -> matches original order) ----------------
out = "/home/lenitain/.models/wrfm-demo/wrfm_assests/toilet.wrfm"
lines = ["wrfm 1", f"vertices {len(verts)}   edges {len(edges)}", "",
         "# naviga model: toilet"]
for (x, y, z) in verts:
    lines.append(f"v {x:.3f} {y:.3f} {z:.3f}")
for (i, j) in sorted((min(a, b), max(a, b)) for (a, b) in edges):
    lines.append(f"e {i} {j}")
with open(out, "w") as f:
    f.write("\n".join(lines) + "\n")
print("wrote", out)
