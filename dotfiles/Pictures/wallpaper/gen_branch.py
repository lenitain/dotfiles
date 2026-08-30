#!/usr/bin/env python3
"""branch.svg — 145 round-capped strokes on a cream field.  Standalone generator.

Run it, get the artwork.  No input image and no third-party packages:

    python3 gen_branch.py [OUTPUT_SVG]          (default: branch.svg)

The drawing is generative stroke art: straight lines fanning out from roots along
a horizontal axis, above and below it, longest near the middle.  What this script
carries is that recovered geometry - the STROKES table below, one (x1, y1, x2, y2)
per line - so the output is exact and reproducible on any machine with Python 3.

derive_strokes.py is the process script behind the table: it re-traces the
geometry out of a rendered raster (needs numpy + OpenCV) and rewrites
segments.json.  Only run that to work from a different source image or resolution.
"""
import argparse
import os
import shutil
import subprocess

VIEWPORT = (2880, 1800)
INK = "#3B3734"
BACKGROUND = "#F4F1EA"
STROKE_WIDTH = 5.35
CAP = "round"

# x1, y1, x2, y2 in SVG user units; the +0.5 registration against the source
# raster is already folded in (Cairo centres a pixel at index+0.5)
STROKES = (
    (1454.76, 328.56, 1601.89, 1007.74),
    (1489.74, 338.44, 1613.52, 1007.52),
    (1425.99, 362.76, 1589.39, 1007.67),
    (1326.78, 409.58, 1565.01, 1007.5),
    (1532.89, 371.84, 1626.12, 1008.01),
    (1397.25, 426.64, 1576.46, 1007.24),
    (1246.54, 1010.89, 1723.44, 1327.64),
    (1294.99, 509.43, 1553.04, 1007.56),
    (1260.28, 540.56, 1541.34, 1007.5),
    (1589.76, 503.19, 1637.6, 1007.89),
    (1193.11, 635.47, 1498.96, 1008),
    (1228.04, 631.65, 1513.32, 1007.68),
    (1179.28, 656.8, 1484.82, 1008),
    (1267.26, 625.64, 1527.42, 1007.43),
    (1962.24, 1009.84, 1986.18, 1466.59),
    (1178.29, 692.59, 1469.73, 1007.4),
    (962.88, 1008.78, 962.88, 579.33),
    (1974.02, 1009.8, 2016.35, 1425.09),
    (2045.89, 1010.6, 2207.18, 1393.66),
    (979.64, 1008.95, 979.64, 596.65),
    (1916.57, 810.03, 2274.25, 1007.35),
    (2032.59, 1010.63, 2178.94, 1390.55),
    (1950.99, 1009.94, 1963.71, 1410.23),
    (1986.24, 1010.03, 2051.52, 1403.91),
    (2020.81, 1010.26, 2148.54, 1383.75),
    (1939.81, 1009.95, 1945.06, 1391.22),
    (946.13, 1008.73, 946.1, 621.17),
    (1895.94, 852.64, 2248.2, 1008),
    (1892.32, 1381.9, 1907.48, 1009.79),
    (2058.08, 1010.31, 2205.56, 1338.31),
    (930.88, 1008.67, 930.88, 649.55),
    (1998.02, 1010.03, 2082.44, 1356.15),
    (1848.67, 1356.28, 1883.53, 1010.03),
    (1983.23, 820.37, 2288.74, 1008),
    (2071.81, 1010.59, 2217.06, 1316.48),
    (1929.36, 1344.07, 1929.36, 1009.93),
    (1200.01, 1010.73, 1473.15, 1197.71),
    (1913.96, 838.78, 2262.6, 1008.35),
    (1223.55, 1011.02, 1493.34, 1194.04),
    (1872.01, 1329.58, 1895.24, 1009.92),
    (993.39, 1009.19, 1009.14, 692.39),
    (1632.26, 694.16, 1649.53, 1008.1),
    (1837.32, 1317.86, 1871.89, 1010.09),
    (2111.75, 1010.63, 2259.17, 1278.34),
    (1177.02, 1009.73, 1428.79, 1184.37),
    (2085.48, 1010.4, 2217.1, 1283.8),
    (2009.12, 1009.92, 2093.51, 1294.12),
    (789.06, 1010.48, 943.72, 1260.66),
    (774.84, 1010.4, 927.69, 1260.51),
    (2119.19, 808.45, 2323.45, 1007.92),
    (1260.09, 808.36, 1455.17, 1007.82),
    (2098.72, 1010.6, 2227.02, 1258.49),
    (2124.34, 1010.54, 2266.56, 1250.71),
    (1698.35, 1008.07, 1700.98, 727.77),
    (1009.2, 1008.67, 1030.07, 735.35),
    (804.94, 1010.84, 946.68, 1240.79),
    (2080.31, 854.92, 2300.91, 1007.54),
    (2113.57, 840.71, 2313.27, 1007.81),
    (1936.23, 892.58, 2233.48, 1008.43),
    (2166.24, 821.59, 2333.15, 1007.71),
    (1830.9, 1259.52, 1860.32, 1010.08),
    (1661.72, 1008.05, 1654.4, 757.56),
    (1261.54, 835.08, 1441.84, 1008.24),
    (1912.65, 1254.64, 1918.97, 1009.77),
    (1673.12, 778.83, 1673.12, 1007.9),
    (820.14, 1010.11, 933.77, 1195.13),
    (1722.45, 1007.87, 1728.29, 801.87),
    (1027.02, 1009.41, 1055.88, 815.58),
    (1686.54, 821, 1685.85, 1008.07),
    (2241.17, 867.62, 2344.5, 1007.13),
    (1268.5, 1010.56, 1415.25, 1103.85),
    (2028.02, 945.5, 2217.12, 1008.28),
    (1734.06, 1008.03, 1741.96, 836.01),
    (1062.3, 1008.27, 1124.98, 858.36),
    (1710.87, 1008.11, 1713.71, 849.38),
    (1758.47, 1007.69, 1770.22, 853.64),
    (1043.47, 1008.8, 1084.02, 869.57),
    (1079, 1008.24, 1145.37, 885.06),
    (835.62, 1010.21, 905.23, 1124.89),
    (1830.36, 1134.92, 1848.55, 1010.04),
    (556.4, 1008.42, 619.98, 902.51),
    (1093.12, 1008.27, 1164.74, 913.17),
    (541.97, 1008.87, 601.57, 907.66),
    (1154.55, 1010.09, 1250.76, 1077.78),
    (915.88, 893.34, 915.88, 1008.69),
    (1770.27, 1008.6, 1781.31, 895.34),
    (760.86, 1010.2, 816.6, 1106.43),
    (746.97, 1009.94, 800.87, 1106.36),
    (2134.86, 1009.84, 2196.8, 1100.21),
    (570.46, 1009.17, 625.86, 917.56),
    (527.71, 1008.8, 578.76, 915.47),
    (1111.29, 1008.63, 1185.96, 933.62),
    (584.77, 1008.4, 641.15, 919.85),
    (610.27, 1008.65, 677.1, 929.14),
    (1746.47, 1007.83, 1752.28, 905.22),
    (901.13, 1009.07, 901.11, 907),
    (512.56, 1008.11, 554.57, 923.53),
    (1359.28, 944.7, 1425.65, 1008.52),
    (596.97, 1008.19, 652.38, 933.81),
    (497.38, 1008.22, 532.02, 927.31),
    (734.05, 1009.89, 774.05, 1084.53),
    (1782.39, 1008.14, 1797.44, 926.52),
    (483.05, 1007.92, 510.97, 932.41),
    (627.01, 1008.56, 682.64, 949.38),
    (2148.11, 1010.56, 2196.61, 1072.75),
    (2060.31, 975.22, 2198.89, 1007.85),
    (2321.47, 940.95, 2356.59, 1007.42),
    (1290.89, 1009.67, 1352.76, 1047.04),
    (1132.78, 1008.08, 1197.78, 957.1),
    (1793.94, 1007.98, 1816.64, 942.9),
    (887.36, 1008.62, 887.36, 939.25),
    (468.33, 1008.06, 490.36, 945.82),
    (2159.63, 1009.85, 2201.99, 1055.56),
    (1364.35, 966.18, 1408.34, 1008.48),
    (664.5, 1008.96, 707.47, 970.88),
    (644.56, 1008.65, 685.28, 970.51),
    (2173.08, 1010.2, 2206.4, 1043.53),
    (681.62, 1008.77, 726.5, 973.66),
    (456.23, 1008.52, 469.46, 963.91),
    (2403.88, 1054.83, 2403.89, 1009.68),
    (875.13, 958.21, 875.1, 1008.59),
    (1806.38, 1008.11, 1833.31, 975.49),
    (2185.71, 1009.93, 2213.95, 1030.98),
    (1317.44, 1010.39, 1351.08, 1033.16),
    (1830.58, 1047.55, 1837.29, 1009.93),
    (443.44, 1008.5, 452.15, 972.83),
    (1337.73, 1009.97, 1365.46, 1029.8),
    (2415.64, 1035.85, 2415.64, 1009.7),
    (1372.95, 992.89, 1390.6, 1008.53),
    (2359.84, 985.89, 2368.48, 1007.58),
    (430.15, 1007.91, 434.54, 988.1),
    (2392.11, 1009.73, 2392.12, 1028.55),
    (2450.88, 1007.56, 2450.88, 989.35),
    (1822.56, 1008.12, 1835.62, 999.29),
    (1352.99, 1009.76, 1365.25, 1018.59),
    (1363.47, 999.76, 1373.65, 1008.24),
    (863.13, 1008.75, 863.11, 981.67),
    (2439.65, 1007.36, 2439.64, 995.92),
    (418.24, 1007.53, 419.68, 996.63),
    (2376.65, 996.8, 2380.32, 1007.66),
    (701.93, 1008.32, 738.91, 980.4),
    (720.41, 1008.26, 741.03, 994.98),
    (2462.81, 999.62, 2462.88, 1007.44),
    (850.57, 995.41, 850.64, 1008.47),
    (2427.35, 1012.94, 2427.39, 1009.59),
)

SVGO_CONFIG = (
    'export default {plugins: [{name: "preset-default", params: {overrides: '
    "{convertShapeToPath: false, convertPathData: {floatPrecision: 2}}}}]};\n"
)


def render(doc):
    """The SVG document for a stroke set: strokes plus optional overrides."""
    w, h = doc.get("viewBox", VIEWPORT)
    off = doc.get("offset", 0.0)
    line = '    <line x1="{}" y1="{}" x2="{}" y2="{}"/>'
    body = "\n".join(line.format(*("%.2f" % (v + off) for v in s)) for s in doc["strokes"])
    head = ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {0} {1}" width="{0}" height="{1}">\n'
            .format(w, h))
    return "".join((
        head,
        '  <title>{} — vectorised line art</title>\n'.format(doc.get("name", "branch")),
        '  <rect width="{}" height="{}" fill="{}"/>\n'.format(w, h, doc.get("background", BACKGROUND)),
        '  <g stroke="{}" stroke-width="{}" stroke-linecap="{}" fill="none">\n'.format(
            doc.get("ink", INK), doc.get("stroke-width", STROKE_WIDTH), CAP),
        body,
        "\n  </g>\n</svg>\n",
    ))


def optimise(path):
    """Compact in place when svgo exists, keeping one <line> per stroke: folding
    them into a compound path would shrink the file more but destroy the
    per-stroke editability.  Without svgo the output is simply a little larger."""
    svgo = shutil.which("svgo")
    if not svgo:
        return
    cfg = "/tmp/_branch-svgo.mjs"
    open(cfg, "w").write(SVGO_CONFIG)
    subprocess.run([svgo, path, "-o", path, "--config=" + cfg], check=False, capture_output=True)


def write(doc, path):
    open(path, "w").write(render(doc))
    optimise(path)
    return path


def normalise_colour(c, default):
    """Accept #RGB, #RRGGBB, RGB, RRGGBB, any case; return #RRGGBB or default if empty."""
    if not c:
        return default
    c = c.strip().lstrip("#").upper()
    if len(c) == 3:
        c = "".join(ch * 2 for ch in c)
    if len(c) != 6 or not all(ch in "0123456789ABCDEF" for ch in c):
        raise ValueError("invalid colour: %r" % c)
    return "#" + c


def main():
    ap = argparse.ArgumentParser(description="Write branch.svg from the recovered stroke geometry.")
    ap.add_argument("svg", nargs="?", default="branch.svg")
    ap.add_argument("--ink", "-i", default=None, help="stroke colour (e.g. 3B3734, #a1b2c3, F00)")
    ap.add_argument("--bg", "-b", default=None, help="background colour (e.g. F4F1EA, #fff)")
    ap.add_argument("--no-minify", action="store_true", help="skip svgo even when it is installed")
    a = ap.parse_args()
    ink = normalise_colour(a.ink, INK)
    bg = normalise_colour(a.bg, BACKGROUND)
    open(a.svg, "w").write(render({"strokes": STROKES, "ink": ink, "background": bg}))
    if not a.no_minify:
        optimise(a.svg)
    print("%s: %d strokes -> %s (%d bytes) [ink=%s bg=%s]"
          % (os.path.basename(__file__), len(STROKES), a.svg, os.path.getsize(a.svg), ink, bg))


if __name__ == "__main__":
    main()
