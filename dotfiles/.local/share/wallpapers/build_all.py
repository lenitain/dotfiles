#!/usr/bin/env python3
"""Build the sky wallpaper SVG.

The sky generator is independent and runs in its own process. Add more
independent jobs to JOBS if other wallpapers are enabled later.
"""

from __future__ import annotations

import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
JOBS = (
    ("sky", "build_starry_sky.py", "starry-night-sky.svg"),
)


def main() -> int:
    failures: list[str] = []
    print("Building the sky wallpaper.\n")
    for name, script_name, output_name in JOBS:
        script = ROOT / script_name
        output = ROOT / output_name
        print(f"[{name}] running {script_name} ...")
        started = time.perf_counter()
        result = subprocess.run([sys.executable, str(script)], cwd=ROOT)
        elapsed = time.perf_counter() - started
        if result.returncode != 0:
            print(f"[{name}] failed (exit {result.returncode})\n", file=sys.stderr)
            failures.append(name)
            continue
        if not output.is_file():
            print(f"[{name}] finished but {output_name} is missing\n", file=sys.stderr)
            failures.append(name)
            continue
        size = output.stat().st_size / 1024
        print(f"[{name}] wrote {output_name} ({size:.1f} KiB) in {elapsed:.2f}s\n")

    if failures:
        print("Build failed: " + ", ".join(failures), file=sys.stderr)
        return 1
    print("Done. The sky SVG is up to date.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
