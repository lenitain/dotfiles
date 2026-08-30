#!/usr/bin/env python3
"""smoke.py — end-to-end verification of the wrfm skill's environment.

Checks, in order:
  A. dependencies (wrfm CLI incl. `wrfm format`, ImageMagick, a
     braille-capable font) — ALL missing tools are reported at once, then it
     stops. It never installs anything: installing is the USER's decision.
  B. every reference sample is checkable and not `broken`
  C. the image pipeline produces a non-blank PNG
  D. the anti-stale guards work: a second shot at the same path is refused,
     and the identity stamped into the render matches `wrfm info`

Exit: 0 all good · 1 something failed · 2 required tool(s) missing.
"""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import wrfmlib as L  # noqa: E402

SAMPLES = os.path.join(os.path.dirname(HERE), "references", "wrfm_assets")
SHOT = os.path.join(HERE, "wrfm-shot.py")

_failures = []


def step(title):
    print("== {0} ==".format(title))


def fail(message):
    _failures.append(message)
    print("  FAIL: {0}".format(message))


def ok(message):
    print("  {0}".format(message))


def check_dependencies():
    step("A. dependencies")
    missing = []
    if shutil.which("wrfm") is None:
        missing.append("wrfm CLI (the wrfm-cli crate from the wireforge repo)")
    else:
        probe = subprocess.run(["wrfm", "format"], stdout=subprocess.DEVNULL,
                               stderr=subprocess.PIPE,
                               encoding="utf-8", errors="replace")
        if probe.returncode != 0:
            missing.append("wrfm CLI is present but stale — `wrfm format` "
                           "failed: rebuild the wrfm-cli crate")
    if shutil.which("magick") is None:
        missing.append("ImageMagick (`magick`)")
    font = None
    if not missing:
        font = L.pick_font()
        if font == "Monospace":
            print("  note: no font with known braille (U+2800) coverage found "
                  "— a blank render would mean a bad font; checked below.")
    if missing:
        print("MISSING (all of them):", file=sys.stderr)
        for item in missing:
            print("  - {0}".format(item), file=sys.stderr)
        print("This skill NEVER installs software. Stop and tell the user "
              "what is missing; they install it themselves.",
              file=sys.stderr)
        raise SystemExit(2)
    ok("wrfm CLI ok · ImageMagick ok · font: {0}".format(font))
    return font


_samples_dir = None


def samples_dir():
    """Sample directory, resolved once."""
    global _samples_dir
    if _samples_dir is not None:
        return _samples_dir
    if os.path.isdir(SAMPLES):
        _samples_dir = SAMPLES
    else:
        fail("no references/ sample directory found")
        _samples_dir = False
    return _samples_dir or None


def check_samples():
    step("B. reference samples (broken fails; warn is allowed)")
    directory = samples_dir()
    if not directory:
        return
    names = sorted(f for f in os.listdir(directory) if f.endswith(".wrfm"))
    if not names:
        fail("sample directory is empty")
        return
    for name in names:
        path = os.path.join(directory, name)
        cp = subprocess.run(["wrfm", "check", path], stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, encoding="utf-8",
                            errors="replace")
        verdict = re.match(r"(ok|warn|broken):", cp.stdout)
        word = verdict.group(1) if verdict else "unreadable"
        # NOTE: the CLI's unified exit codes are 0=ok · 1=warn · 2=broken ·
        # 3=no result. The verdict WORD still decides (it is on stdout, is
        # what carries the problem list, and keeps this working against a
        # not-yet-updated binary); returncode 2 (broken) is now a second,
        # independent trigger so the exit code alone can also judge health.
        if cp.returncode == 2 or word == "broken" or not verdict:
            fail("{0}: {1}".format(name, word))
        else:
            ok("{0}: {1}".format(name, word))


def run_shot(model, out, *args):
    return subprocess.run([sys.executable, SHOT, model, out, *args],
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                          encoding="utf-8", errors="replace")


def check_pipeline(workdir):
    step("C. image pipeline (non-blank PNG)")
    sample = os.path.join(directory_or_die(), "anvil.wrfm")
    shots = [("six.png", []), ("front.png", ["--views", "front"])]
    for name, args in shots:
        out = os.path.join(workdir, name)
        cp = run_shot(sample, out, *args)
        if cp.returncode != 0:
            fail("{0}: {1}".format(name, cp.stderr.strip() or "no output"))
            continue
        if not os.path.exists(out) or os.path.getsize(out) == 0:
            fail("{0} is empty".format(name))
            continue
        mean = L.brightness(out)
        if not (0.001 < mean < 0.999):
            fail("{0} looks blank (mean={1}) — font can't draw braille?".format(
                name, mean))
        else:
            ok("{0}: {1} bytes, mean={2:.4f}".format(name, os.path.getsize(out),
                                                     mean))


def directory_or_die():
    directory = samples_dir()
    if not directory:
        raise SystemExit(1)
    return directory


def check_guards(workdir):
    step("D. anti-stale guards")
    sample = os.path.join(directory_or_die(), "anvil.wrfm")
    out = os.path.join(workdir, "guard.png")

    first = run_shot(sample, out, "--views", "front")
    if first.returncode != 0:
        fail("first shot failed: {0}".format(first.stderr.strip()))
        return
    second = run_shot(sample, out, "--views", "front")
    if second.returncode != 2:
        fail("overwrite was NOT refused (exit {0})".format(second.returncode))
    else:
        ok("second shot to the same path refused (exit 2)")

    stamp = re.search(r"^\s*shot=(\S+)", first.stdout, re.M)
    ident = re.search(r"shot=\S+\s+name=(\S+)\s+vertices=(\d+)\s+edges=(\d+)",
                      first.stdout)
    if not stamp or not ident:
        fail("stdout report carries no shot id / identity line")
        return

    render = L.render(sample, ["--views", "front"])
    header = L.header(render)
    info = L.info(sample)
    mismatched = [key for key in ("name", "vertices", "edges")
                  if str(header[key]) != str(info[key])]
    if mismatched:
        for key in mismatched:
            fail("watermark lies: render says {0}={1}, wrfm info says {2}"
                 .format(key, header[key], info[key]))
    else:
        ok("watermark (name/vertices/edges) matches `wrfm info`")

    label, _ = L.frame(sample, ["--views", "front"], stamp.group(1))
    if label.startswith("# shot=" + stamp.group(1)):
        ok("render stamped {0} — the PNG can be matched to this run"
           .format(label.splitlines()[0].lstrip("# ")))
    else:
        fail("render text carries no shot stamp")


def main():
    print("wrfm skill smoke test (Python {0})".format(
        ".".join(str(v) for v in sys.version_info[:3])))
    check_dependencies()
    check_samples()
    workdir = tempfile.mkdtemp(prefix="wrfm-smoke-")
    try:
        check_pipeline(workdir)
        check_guards(workdir)
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    print("NOTE: the visual check (a human or a multimodal model reads the "
          "PNGs and confirms the anvil is visible) is the operator's step.")
    if _failures:
        print("SMOKE FAILED ({0} problem(s))".format(len(_failures)))
        return 1
    print("SMOKE OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
