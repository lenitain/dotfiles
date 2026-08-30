"""
wrfm_utils.py — 通用线框模型生成工具库
提供统一的基础函数，用于生成.wrfm格式的线框模型文件。
"""
import math
import os


class WrfmModel:
    """线框模型容器，管理顶点、边和组信息"""

    def __init__(self):
        self.verts = []      # list of (x, y, z)
        self.edges = []      # list of (i, j)
        self.groups = []     # list of (name, start_idx, count)
        self._group_start = None

    def add(self, x, y, z):
        """添加顶点，返回索引"""
        idx = len(self.verts)
        self.verts.append((x, y, z))
        return idx

    def edge(self, a, b):
        """添加边"""
        if a != b:
            self.edges.append((a, b))

    def cycle(self, idxs):
        """将顶点列表连接成闭合多边形"""
        n = len(idxs)
        for k in range(n):
            self.edge(idxs[k], idxs[(k + 1) % n])

    def begin_group(self, name):
        """开始一个新组"""
        self.end_group()
        self._group_start = (name, len(self.verts))

    def end_group(self):
        """结束当前组"""
        if self._group_start is not None:
            name, start = self._group_start
            count = len(self.verts) - start
            self.groups.append((name, start, count))
            self._group_start = None

    def ring(self, cx, cy, cz, r, n, start_deg=0.0):
        """在 XY 平面创建正 n 边形环"""
        idxs = []
        for k in range(n):
            a = math.radians(start_deg + 360.0 * k / n)
            idxs.append(self.add(cx + r * math.cos(a), cy + r * math.sin(a), cz))
        self.cycle(idxs)
        return idxs

    def ellipse_xy(self, cx, cy, cz, rx, ry, n, start_deg=0.0):
        """XY 平面椭圆环"""
        idxs = []
        for k in range(n):
            a = math.radians(start_deg + 360.0 * k / n)
            idxs.append(self.add(cx + rx * math.cos(a), cy + ry * math.sin(a), cz))
        self.cycle(idxs)
        return idxs

    def connect_ring(self, r1, r2):
        """连接两个等长环的对应顶点"""
        for a, b in zip(r1, r2):
            self.edge(a, b)

    def box8(self, cx, cy, cz, sx, sy, sz):
        """轴对齐长方体的 8 个角点；0..3 在 z=z0（背面），4..7 在 z=z1（正面）"""
        x0, x1 = cx - sx / 2, cx + sx / 2
        y0, y1 = cy - sy / 2, cy + sy / 2
        z0, z1 = cz - sz / 2, cz + sz / 2
        return [
            self.add(x0, y0, z0), self.add(x1, y0, z0), self.add(x1, y1, z0), self.add(x0, y1, z0),
            self.add(x0, y0, z1), self.add(x1, y0, z1), self.add(x1, y1, z1), self.add(x0, y1, z1),
        ]

    def box_edges(self, b):
        """为 box8 索引列表添加 12 条边"""
        for a, c in [(0,1),(1,2),(2,3),(3,0),(4,5),(5,6),(6,7),(7,4),(0,4),(1,5),(2,6),(3,7)]:
            self.edge(b[a], b[c])

    _cycle = cycle

    def sanity_check(self):
        """检查模型的健康度（最小/最大度数）"""
        deg = [0] * len(self.verts)
        for (i, j) in self.edges:
            deg[i] += 1
            deg[j] += 1
        low = [i for i, d in enumerate(deg) if d < 2]
        if low:
            print(f"WARNING: degree<2 vertices: {low}")
        mins = min((d for d in deg if d), default=0)
        maxs = max(deg) if deg else 0
        return len(self.verts), len(self.edges), mins, maxs

    def write(self, path, comment=None):
        """写入.wrfm文件"""
        self.end_group()  # 关闭最后一个组

        # 去除重复边
        seen = set()
        unique_edges = []
        for i, j in self.edges:
            key = (min(i, j), max(i, j))
            if key not in seen:
                seen.add(key)
                unique_edges.append((i, j))
        self.edges = unique_edges

        lines = ["wrfm 1"]
        lines.append(f"vertices {len(self.verts)}   edges {len(self.edges)}")
        lines.append("")
        
        if comment:
            lines.append(f"# {comment}")
            lines.append("")
        
        for name, start, cnt in self.groups:
            lines.append(f"group {name}")
            for x, y, z in self.verts[start:start + cnt]:
                lines.append(f"v {x:.3f} {y:.3f} {z:.3f}")
            lines.append("")
        
        for i, j in self.edges:
            lines.append(f"e {i} {j}")
        
        with open(path, "w") as f:
            f.write("\n".join(lines) + "\n")
        
        v, e, min_deg, max_deg = self.sanity_check()
        print(f"wrote {path}: {v} vertices, {e} edges, degrees=[{min_deg}, {max_deg}]")


# =================== 通用数学函数 ===================

def rot_x(p, deg):
    """绕X轴旋转点p"""
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    x, y, z = p
    return (x, y * c - z * s, y * s + z * c)

def rot_y(p, deg):
    """绕Y轴旋转点p"""
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    x, y, z = p
    return (x * c + z * s, y, -x * s + z * c)

def rot_z(p, deg):
    """绕Z轴旋转点p"""
    a = math.radians(deg)
    c, s = math.cos(a), math.sin(a)
    x, y, z = p
    return (x * c - y * s, x * s + y * c, z)

def vadd(a, b):
    """向量加法"""
    return (a[0] + b[0], a[1] + b[1], a[2] + b[2])

def vsub(a, b):
    """向量减法"""
    return (a[0] - b[0], a[1] - b[1], a[2] - b[2])

def vdot(a, b):
    """向量点积"""
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]

def vlen(a):
    """向量长度"""
    return math.sqrt(vdot(a, a))

def vnorm(a):
    """向量归一化"""
    l = vlen(a)
    return (a[0] / l, a[1] / l, a[2] / l) if l > 1e-12 else (0.0, 1.0, 0.0)

def vcross(a, b):
    """向量叉积"""
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])
