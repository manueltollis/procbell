"""
Composes anims/dix-*.tga into a single 1024x2048 spritesheet for ProcBell.

Frames are sorted numerically by the trailing index, resized to 128x128 with
bilinear filtering, and pasted into an 8-col x 16-row grid (128 cells, fits
the 100 source frames). Output is uncompressed 32-bit TGA at the addon root.

Re-run this whenever the source frames change.
"""
from __future__ import annotations

import glob
import os
import re
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_GLOB = os.path.join(ROOT, "anims", "dix-*.tga")
DST = os.path.join(ROOT, "anim.tga")

CELL = 128
COLS = 8
ROWS = 16


def frame_index(path: str) -> int:
    m = re.search(r"dix-(\d+)\.tga$", path)
    if not m:
        raise ValueError(f"unrecognized filename: {path}")
    return int(m.group(1))


def main() -> int:
    files = sorted(glob.glob(SRC_GLOB), key=frame_index)
    if not files:
        print(f"no source frames found at {SRC_GLOB}", file=sys.stderr)
        return 1
    if len(files) > COLS * ROWS:
        print(
            f"too many frames ({len(files)}) for {COLS}x{ROWS} grid",
            file=sys.stderr,
        )
        return 1

    sheet = Image.new("RGBA", (COLS * CELL, ROWS * CELL), (0, 0, 0, 0))
    for i, path in enumerate(files):
        frame = Image.open(path).convert("RGBA").resize((CELL, CELL), Image.LANCZOS)
        col, row = i % COLS, i // COLS
        sheet.paste(frame, (col * CELL, row * CELL), frame)

    sheet.save(DST, format="TGA")
    print(f"wrote {DST} ({sheet.size[0]}x{sheet.size[1]}, {len(files)} frames)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
