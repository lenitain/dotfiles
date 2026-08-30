#!/usr/bin/env python3
"""wrfm-shot.py — turn a .wrfm model into a PNG a multimodal model can SEE.

Usage:
  wrfm-shot.py <model.wrfm> <out.png>                  # all six standard views, one 2x3 montage
  wrfm-shot.py <model.wrfm> <out.png> --views front    # one view, large canvas
  wrfm-shot.py <model.wrfm> <out.png> --group head     # one group only (auto-fits the part)
  wrfm-shot.py <model.wrfm> <out.png> --yaw 30 --pitch 20   # any camera wrfm render accepts

Everything after <out.png> is passed straight to `wrfm render` — framing
(dist / fit / region / pan / pitch / yaw) belongs to the CLI, never to this
script.

Two guards against the failure mode that costs the most time (an image channel
that quietly returns an OLDER image than the file just written):

  1. it refuses to overwrite an existing PNG, so every shot gets a fresh name
     and no stale file can be mistaken for the new one;
  2. it stamps '# shot=<id>' into the image and prints the same id plus the
     model's name/vertices/edges on stdout — read the PNG and check them
     against this output. Mismatch = stale image, do not trust it.

Depends on: `wrfm` CLI on PATH, ImageMagick (`magick`). Missing either is a
hard stop (exit 2): this skill never installs software — report it to the user.
"""

from __future__ import annotations

import os
import shutil
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import wrfmlib as L  # noqa: E402

USAGE = "usage: wrfm-shot.py <model.wrfm> <out.png> [--force] [render args...]"


def parse(argv):
    if argv and argv[0] in ("-h", "--help"):
        print(USAGE)
        raise SystemExit(0)
    if len(argv) < 2:
        print(USAGE, file=sys.stderr)
        raise SystemExit(2)
    model, out = argv[0], argv[1]
    force = False
    render_args = []
    for arg in argv[2:]:
        if arg == "--force":
            force = True
        elif arg in ("-h", "--help"):
            print(USAGE)
            raise SystemExit(0)
        else:
            render_args.append(arg)
    return model, out, force, render_args


def main(argv):
    model, out, force, render_args = parse(argv)

    L.wrfm()      # exit 2 + "MISSING: wrfm ..." if absent
    L.magick()    # same for ImageMagick

    if not os.path.exists(model):
        L.die("no such model: {0}".format(model))
    if os.path.exists(out) and not force:
        L.die(
            "{0} already exists — shot refused so a fresh file cannot be "
            "confused with a cached one. Use a NEW filename (recommended), or "
            "pass --force to overwrite deliberately.".format(out))

    sid = L.shot_id(model)
    tmp = tempfile.mkdtemp(prefix="wrfm-shot-")
    try:
        # Explicit render args -> ONE frame; otherwise the six standard views.
        if render_args:
            label, ident = L.frame(model, render_args, sid)
            size = L.text_to_png(label, out)
            print("wrfm-shot: wrote {0} ({1} bytes)  [single frame]".format(
                out, size))
        else:
            paths = []
            for index, view in enumerate(L.DEFAULT_VIEWS):
                label, ident = L.frame(model, ["--views", view], sid)
                path = os.path.join(tmp, "{0}.png".format(index))
                L.text_to_png(label, path)
                paths.append(path)
            size = L.montage(paths, out)
            print("wrfm-shot: wrote {0} ({1} bytes)  [six views: {2}]".format(
                out, size, ",".join(L.DEFAULT_VIEWS)))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)

    L.report_identity("", ident, sid)
    L.verify_note(out, ident, sid)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
