#!/usr/bin/env python3
"""Portrait cuts of landscape wallpapers for rotated screens.

    crop_portrait.py SRC_DIR OUT_DIR WIDTH HEIGHT

For every image in SRC_DIR without a cut in OUT_DIR yet, slides a
WIDTH:HEIGHT window across it, keeps the window with the most detail
(edge energy, lightly biased toward the center) and saves it as
OUT_DIR/<name>.jpg at WIDTH x HEIGHT. Prints nothing; safe to re-run.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

EXTS = {".jpg", ".jpeg", ".png", ".webp"}


def best_x(img, cw):
    # Work on a small grayscale copy; only the column profile matters
    scale = 320 / img.width
    small = img.convert("L").resize((320, max(1, int(img.height * scale))))
    edges = np.asarray(small.filter(ImageFilter.FIND_EDGES), dtype=np.float32)
    cols = edges.sum(axis=0)
    w = max(1, int(cw * scale))
    if w >= len(cols):
        return 0
    sums = np.convolve(cols, np.ones(w), mode="valid")
    centers = np.arange(len(sums)) + w / 2
    bias = 1 - 0.35 * np.abs(centers - len(cols) / 2) / (len(cols) / 2)
    return int(np.argmax(sums * bias) / scale)


def main():
    src, out = Path(sys.argv[1]).expanduser(), Path(sys.argv[2]).expanduser()
    tw, th = int(sys.argv[3]), int(sys.argv[4])
    out.mkdir(parents=True, exist_ok=True)
    wanted = set()
    for f in sorted(src.iterdir()):
        if f.suffix.lower() not in EXTS:
            continue
        dst = out / (f.stem + ".jpg")
        wanted.add(dst.name)
        if dst.exists():
            continue
        img = Image.open(f).convert("RGB")
        cw = min(img.width, round(img.height * tw / th))
        x = best_x(img, cw)
        img.crop((x, 0, x + cw, img.height)).resize((tw, th), Image.LANCZOS).save(dst, quality=90)
    # Drop cuts whose source is gone
    for f in out.iterdir():
        if f.name not in wanted:
            f.unlink()


if __name__ == "__main__":
    main()
