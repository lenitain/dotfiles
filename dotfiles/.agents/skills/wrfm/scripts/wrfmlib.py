"""Shared helpers for the wrfm skill's scripts.

Pure standard library: no third-party imports, no pip installs, ever.

HARD RULE — never install. These scripts look up every external program with
shutil.which(); if one is missing they print what is missing and exit 2. They
NEVER run an installer, package manager, or download. Reporting a missing tool
to the user is the agent's job, not the script's.

Contract (of these scripts — stable, so scripts and pipes stay predictable):
    stdout = report / data
    stderr = diagnostics
    exit   = 0 ok · 1 produced with an issue · 2 no result

The wrfm CLI itself uses FOUR tiers (wireforge side, unified 2026-10):
    0 = ok · 1 = warn · 2 = broken · 3 = no result / could not run
A CLI exit 3 is fatal to a pipe (see run()); 1 and 2 are verdicts the caller
must parse from stdout — never from the exit code alone.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import time

# Rendering look (dark canvas, light strokes — readable on any terminal bg).
BG = "#0d1117"
FG = "#9cdcfe"
POINTSIZE = 16  # 120 braille cols * ~9.8px/char -> ~1180px wide per view
DEFAULT_VIEWS = ("front", "back", "left", "right", "top", "bottom")

# The skill scripts' OWN exit codes (the contract in the module docstring).
NO_RESULT = 2
HAD_ISSUE = 1

# The wrfm CLI's exit codes — four tiers (wireforge side unified these):
#   0 = ok · 1 = warn · 2 = broken · 3 = no result / could not run
# Only 3 is fatal when consuming CLI output in a pipe; 1 and 2 are verdicts
# (e.g. `wrfm check` prints "warn:" / "broken:" on stdout) for the caller to
# parse. NOTE: this differs from the scripts' own NO_RESULT = 2 above.
CLI_NO_RESULT = 3

_MISSING = (
    "MISSING: {name}\n"
    "This skill never installs software. Stop here and tell the user what is "
    "missing and how THEY can install it (never install it yourself)."
)


# --------------------------------------------------------------------------
# external tools
# --------------------------------------------------------------------------

def die(message, code=NO_RESULT):
    """Report a fatal problem on stderr and stop."""
    print(message, file=sys.stderr)
    raise SystemExit(code)


def tool(name):
    """Absolute path of *name*, or exit 2 with the never-install report."""
    path = shutil.which(name)
    if not path:
        die(_MISSING.format(name=name))
    return path


def run(cmd, *, stdin=None):
    """Run *cmd*; return CompletedProcess with stdout captured as UTF-8 text.

    stderr is echoed back out (the wrfm CLI puts its health report there), and
    an exit 3 from the CLI means no result was produced — that is fatal here
    (CLI tiers: 0=ok · 1=warn · 2=broken · 3=no result; only 3 is fatal, a
    warn/broken verdict belongs to the caller).
    Text is forced to UTF-8 so braille survives on Windows code pages.
    """
    cp = subprocess.run(
        list(cmd), input=stdin, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        encoding="utf-8", errors="replace",
    )
    if cp.stderr:
        sys.stderr.write(cp.stderr)
    if cp.returncode == CLI_NO_RESULT:
        die("{0} produced no result (CLI exit 3).".format(cmd[0] if cmd else "command"))
    return cp


def wrfm():
    return tool("wrfm")


def magick():
    return tool("magick")


# --------------------------------------------------------------------------
# rendering
# --------------------------------------------------------------------------

def render(model, render_args):
    """Render *model* with the skill's standard canvas; return the text."""
    cmd = [wrfm(), "render", str(model), "--format", "braille",
           "--width", "120", "--height", "60"]
    cmd += list(render_args)
    return run(cmd).stdout


_HEADER = re.compile(
    # [ \t] only: \s would let the pattern run past the end of this line and
    # swallow '[view=...]' into the bounds group.
    r"#\s*name=(?P<name>\S+)[ \t]+version=(?P<version>\S+)[ \t]+"
    r"vertices=(?P<vertices>\d+)[ \t]+edges=(?P<edges>\d+)"
    r"(?:[ \t]+bounds=(?P<bounds>\S+[ \t]+\S+))?"
)


def header(render_text):
    """The identity line wrfm prints above every render — the image watermark.

    Returns {'name': str, 'vertices': str, 'edges': str, 'bounds': str|None}.
    This is what makes a rendered PNG verifiable: whatever the agent reads in
    the image must match the file it just generated.
    """
    match = _HEADER.search(render_text)
    if not match:
        die("render produced no '# name=... vertices=... edges=...' header — "
            "cannot verify the image; treat the image channel as broken.")
    return match.groupdict()


def info(model):
    """`wrfm info` JSON for *model* (name / vertices / edges / bounds)."""
    return json.loads(run([wrfm(), "info", str(model)]).stdout)


def shot_id(model):
    """Unique id for ONE shot: wall clock + pid + hash of the model bytes.

    It is printed to stdout AND stamped into the PNG, so the agent can prove
    the image it is looking at came from this run — not from an older file
    with the same name (the failure mode that wastes an hour when it slips).
    """
    digest = hashlib.sha1()
    with open(model, "rb") as handle:
        for chunk in iter(lambda: handle.read(65536), b""):
            digest.update(chunk)
    return "{0}-{1:x}-{2}".format(time.strftime("%H%M%S"), os.getpid(),
                                 digest.hexdigest()[:8])


def frame(model, render_args, sid):
    """One frame: render *model*, stamp it, return (label_text, identity).

    The '# shot=...' stamp is prepended to the render text that gets
    rasterized, so the PNG carries proof of which run produced it. Framing
    (dist / region / fit) is left entirely to the wrfm CLI.
    """
    text = render(model, render_args)
    ident = header(text)
    return "# shot={0}\n{1}".format(sid, text), ident


# --------------------------------------------------------------------------
# text -> PNG
# --------------------------------------------------------------------------

def pick_font():
    """A font that can actually draw braille (U+2800), else a safe default.

    A font without the braille block renders a 'successful' blank image, so
    this is checked in order: fontconfig (exact coverage query) first, then
    ImageMagick's own font list (Windows has no fc-list).
    """
    fc_list = shutil.which("fc-list")
    if fc_list:
        cp = subprocess.run(
            [fc_list, ":charset=2800", r"--format=%{family}\n"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            encoding="utf-8", errors="replace",
        )
        families = set()
        for line in cp.stdout.splitlines():
            for family in line.split(","):
                family = family.strip().lower().replace(" ", "-")
                if family:
                    families.add(family)
        for wanted in ("adwaita-mono", "dejavu-sans", "dejavu-serif"):
            if wanted in families:
                return wanted
    fonts = subprocess.run([magick(), "-list", "font"],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                           encoding="utf-8", errors="replace").stdout
    for wanted in ("DejaVu-Sans-Mono", "Monospace"):
        if wanted.lower() in fonts.lower():
            return wanted
    return "Monospace"


def text_to_png(text, out_path):
    """Rasterize *text* (render output + our shot stamp) into *out_path*.

    `-depth 8 -type TrueColor`: ImageMagick otherwise writes 16-bit PNGs that
    some viewers and downstream tools refuse to read.
    """
    cmd = [magick(), "-background", BG, "-fill", FG, "-font", pick_font(),
           "-pointsize", str(POINTSIZE), "label:@-",
           "-depth", "8", "-type", "TrueColor", str(out_path)]
    cp = subprocess.run(cmd, input=text, encoding="utf-8", errors="replace",
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if cp.returncode != 0 or not os.path.exists(out_path):
        die("ImageMagick failed to write {0}:\n{1}".format(out_path, cp.stderr))
    return os.path.getsize(out_path)


def montage(png_paths, out_path):
    """Tile PNGs side by side (2 columns) into *out_path*.

    No `-label` captions: every tile already carries its own '# shot=' /
    'name=' / '[view=...]' header inside the image, which the reader must
    verify anyway (and `-label` reserved space without drawing text here).
    """
    cmd = [magick(), "montage"] + [str(p) for p in png_paths]
    cmd += ["-tile", "2x", "-geometry", "+6+6", "-background", BG,
            str(out_path)]
    cp = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                        encoding="utf-8", errors="replace")
    if cp.returncode != 0 or not os.path.exists(out_path):
        die("ImageMagick montage failed:\n{0}".format(cp.stderr))
    return os.path.getsize(out_path)


def brightness(path):
    """Mean brightness of a PNG (0 = blank/black, 1 = white) as a float."""
    cp = subprocess.run([magick(), str(path), "-colorspace", "gray",
                         "-format", "%[fx:mean]", "info:"],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                        encoding="utf-8", errors="replace")
    try:
        return float(cp.stdout.strip())
    except ValueError:
        die("could not measure {0}: {1}".format(path, cp.stderr))


# --------------------------------------------------------------------------
# reporting
# --------------------------------------------------------------------------

def report_identity(tag, ident, sid):
    """The line the agent compares against what it reads inside the PNG."""
    line = "  shot={0}  name={1}  vertices={2}  edges={3}".format(
        sid, ident.get("name"), ident.get("vertices"), ident.get("edges"))
    print("{0}{1}".format(tag, line))
    return line


def verify_note(path, ident, sid):
    print("  VERIFY: read {0} — its header must show name={1} vertices={2} "
          "shot={3}. Anything else means the image channel returned a stale "
          "image: do not trust it (see SKILL.md: image-channel integrity)."
          .format(path, ident.get("name"), ident.get("vertices"), sid))
