#!/usr/bin/env python3
"""wrfm-compare.py — look at TWO models side by side with the SAME camera.

Usage:
  wrfm-compare.py a.wrfm b.wrfm out.png                  # front view of both
  wrfm-compare.py a.wrfm b.wrfm out.png --views iso      # any camera
  wrfm-compare.py a.wrfm b.wrfm out.png --views front --yaw 45

Everything after <out.png> is passed straight to `wrfm render`, so both sides
get identical framing by construction — hand-built montages drift apart.

Why this exists: `wrfm diff` is authoritative for WHAT changed (vertices /
edges / bounds / group membership), but its density grid is normalized per
model, so a pure scale change reads as "0/128 cells changed". Numbers plus
one honest picture is the comparison; neither alone is.

Depends on: `wrfm` CLI, ImageMagick. Missing either stops with exit 2 —
this skill never installs software; report it to the user.
"""

from __future__ import annotations

import json
import os
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wrfmlib as L  # noqa: E402

USAGE = ("usage: wrfm-compare.py <a.wrfm> <b.wrfm> <out.png> "
         "[--force] [render args...]")


def parse(argv):
    if argv and argv[0] in ("-h", "--help"):
        print(USAGE)
        raise SystemExit(0)
    if len(argv) < 3:
        print(USAGE, file=sys.stderr)
        raise SystemExit(2)
    a, b, out = argv[0], argv[1], argv[2]
    force = False
    render_args = []
    for arg in argv[3:]:
        if arg == "--force":
            force = True
        elif arg in ("-h", "--help"):
            print(USAGE)
            raise SystemExit(0)
        else:
            render_args.append(arg)
    # Default to one view each: 2 models x 6 views is a wall of thumbnails.
    if not render_args:
        render_args = ["--views", "front"]
    return a, b, out, force, render_args


def _count(value):
    """diff JSON mixes shapes: edges.added is a list, vertices.added an int."""
    if isinstance(value, list):
        return len(value)
    if isinstance(value, (int, float)):
        return int(value)
    return 0


def diff_summary(a, b):
    """One compact line from `wrfm diff --format json` (full detail: that cmd)."""
    data = json.loads(L.run([L.wrfm(), "diff", a, b, "--format", "json"]).stdout)
    vertices = data.get("vertices", {})
    edges = data.get("edges", {})
    bounds = data.get("bounds", {})
    bounds_same = (bounds.get("a_min") == bounds.get("b_min")
                   and bounds.get("a_max") == bounds.get("b_max"))
    moved = vertices.get("moved_count")
    if moved is None:
        moved = _count(vertices.get("moved"))
    return ("  diff: vertices +{0}/-{1} (moved {2}) · edges +{3}/-{4} · "
            "bounds {5}").format(
                _count(vertices.get("added")),
                _count(vertices.get("removed")),
                moved,
                _count(edges.get("added")),
                _count(edges.get("removed")),
                "unchanged" if bounds_same else "CHANGED")


def main(argv):
    a, b, out, force, render_args = parse(argv)

    L.wrfm()
    L.magick()
    for path in (a, b):
        if not os.path.exists(path):
            L.die("no such model: {0}".format(path))
    if os.path.exists(out) and not force:
        L.die("{0} already exists — refusing to overwrite so an older "
              "comparison cannot pass for this one. Use a new filename, or "
              "pass --force.".format(out))

    tmp = tempfile.mkdtemp(prefix="wrfm-compare-")
    try:
        paths, idents = [], []
        for index, model in enumerate((a, b)):
            sid = L.shot_id(model)
            label, ident = L.frame(model, render_args, sid)
            path = os.path.join(tmp, "{0}.png".format(index))
            L.text_to_png(label, path)
            paths.append(path)
            idents.append((model, ident, sid))
        size = L.montage(paths, out)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    print("wrfm-compare: wrote {0} ({1} bytes)  [{2}]".format(
        out, size, " ".join(render_args)))
    for model, ident, sid in idents:
        L.report_identity(os.path.basename(model) + ": ", ident, sid)
    print(diff_summary(a, b))
    print("  VERIFY: read {0} — each half must show its own name=/vertices= "
          "and shot=. Mismatch = stale image; do not trust it.".format(out))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
