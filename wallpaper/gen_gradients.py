#!/usr/bin/env python3
"""Prism's own abstract wallpapers: soft mesh gradients with a refracted
light band and film grain. Deterministic per palette, so re-running gives
the same images.

    gen_gradients.py OUT_DIR
writes OUT_DIR/landscape/prism-<name>.png (2560x1600)
   and OUT_DIR/portrait/prism-<name>.png  (1440x2560)
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

# name: (background, blob colors...)
PALETTES = {
    "dusk":    ("#0d1024", "#3b2a6b", "#c2577a", "#f29f73", "#1f3c88"),
    "aurora":  ("#050f14", "#0f5c5a", "#1d8a72", "#5fd3a0", "#203a7a"),
    "ember":   ("#140806", "#5c1a12", "#c2410c", "#f59e0b", "#3b0f2e"),
    "lagoon":  ("#04131f", "#0b4f6c", "#01baef", "#20bf9f", "#0a2342"),
    "orchid":  ("#120a1c", "#5b2a86", "#9a48d0", "#f0a6ca", "#2b1a4f"),
    "slate":   ("#0b0d10", "#2a2f37", "#4b5563", "#9ca3af", "#1b1f25"),
    "sand":    ("#efe6da", "#e8c9a0", "#d99a6c", "#b6c7c9", "#f6efe6"),
    "mist":    ("#e8edf2", "#b7c9e2", "#c9b8e8", "#f2d0c4", "#dfe8f0"),
    "moss":    ("#0a0f0a", "#22402a", "#5a7d3a", "#c5b358", "#13261b"),
    "cobalt":  ("#03050f", "#0b1d5c", "#2f4bd8", "#7aa2ff", "#160c3a"),
    "rose":    ("#1a0b10", "#6b1f3a", "#d4537e", "#ffb3a7", "#2d1030"),
    "glacier": ("#dfe9ee", "#9cc3d5", "#6e8fb8", "#e9f1f4", "#b9d4dc"),
}

SIZES = {"landscape": (2560, 1600), "portrait": (1440, 2560)}


def hex_rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255


def render(name, colors, w, h, seed):
    rng = np.random.default_rng(seed)
    # Work at quarter size; everything here is smooth anyway
    sw, sh = w // 4, h // 4
    ys, xs = np.mgrid[0:sh, 0:sw].astype(np.float32)
    xs /= max(sw, sh)
    ys /= max(sw, sh)

    bg = hex_rgb(colors[0])
    img = np.broadcast_to(bg, (sh, sw, 3)).copy()
    # Paint soft color fields over the background; "over" blending keeps each
    # field's hue instead of averaging everything into mud
    for c in colors[1:]:
        for _ in range(2):
            cx, cy = rng.uniform(-0.1, sw / max(sw, sh) + 0.1), rng.uniform(-0.1, sh / max(sw, sh) + 0.1)
            r = rng.uniform(0.13, 0.30)
            a = 0.85 * np.exp(-((xs - cx) ** 2 + (ys - cy) ** 2) / (2 * r * r))[..., None]
            img = img * (1 - a) + hex_rgb(c) * a

    # Gentle vignette toward the background color
    vx, vy = xs / (sw / max(sw, sh)) - 0.5, ys / (sh / max(sw, sh)) - 0.5
    v = np.clip((vx ** 2 + vy ** 2) * 1.1, 0, 0.45)[..., None]
    img = img * (1 - v) + bg * v

    # Refracted light band: a soft diagonal streak split into RGB offsets
    ang = rng.uniform(-0.9, -0.5)
    off = rng.uniform(-0.15, 0.15)
    mx, my = sw / max(sw, sh) / 2, sh / max(sw, sh) / 2      # image center
    d = (xs - mx) * np.cos(ang) + (ys - my) * np.sin(ang) - off
    light = 0.9 if bg.mean() < 0.5 else 0.5
    for ch, shift in enumerate((-0.012, 0.0, 0.012)):
        band = np.exp(-((d + shift) ** 2) / (2 * 0.025 ** 2))
        img[..., ch] += band * 0.07 * light

    small = Image.fromarray((np.clip(img, 0, 1) * 255).astype(np.uint8))
    big = np.asarray(small.resize((w, h), Image.BICUBIC), dtype=np.float32)

    # Film grain hides banding in the dark gradients
    grain = np.random.default_rng(seed + 1).normal(0, 2.2, (h, w, 1)).astype(np.float32)
    return Image.fromarray(np.clip(big + grain, 0, 255).astype(np.uint8))


def main():
    out = Path(sys.argv[1]).expanduser()
    for i, (name, colors) in enumerate(PALETTES.items()):
        for kind, (w, h) in SIZES.items():
            d = out / kind
            d.mkdir(parents=True, exist_ok=True)
            render(name, colors, w, h, seed=1000 + i * 7 + (kind == "portrait")).save(d / f"prism-{name}.png")
            print(d / f"prism-{name}.png")


if __name__ == "__main__":
    main()
