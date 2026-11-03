#!/usr/bin/env python3
"""Dev-only marker inspection tool: render manifest crops with their markers.

    python3 tools/preview_markers.py [id ...]

Reads tools/photo_manifest.json, limits the run to the given ids when any are
passed, and writes build/marker_preview/<id>.png for each entry. Prints
"skip <id>: no image" for entries whose asset is missing, and
"ok <id> -> build/marker_preview/<id>.png" per render. Exits 1 with
"pip install pillow" when Pillow is not importable.

Geometry mirrors PhotoView._draw() in scripts/ui/photo_view.gd: the crop region
is scaled to 320 px tall (scale = 320 / crop_height_px). Each marker's ring
is an ellipse of radius r * width * scale, drawn as a black outline of width 5 then yellow
#FFD400 of width 3. The arrow tries the four diagonals (-1, -1), (1, -1),
(-1, 1), (1, 1) with u = diagonal / sqrt(2), tip = center + u * (ring_r + 4),
tail = tip + u * 36, and uses the first diagonal whose tail falls inside the
region canvas, else the last. The shaft is a black line of width 6 then
yellow width 3; the head is the triangle [tip, tip + rot(-u, 2.6) * 12,
tip + rot(-u, -2.6) * 12] filled yellow with a black outline. Marker centers
are (cx * width, cy * height) in full-image pixels, converted to canvas
coordinates relative to the crop origin.
"""
import json
import math
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "photo_manifest.json")
PHOTO_DIR = os.path.join(ROOT, "assets", "photos")
OUT_DIR = os.path.join(ROOT, "build", "marker_preview")

PREVIEW_HEIGHT = 320.0
RING = (255, 212, 0)  # #FFD400
OUTLINE = (0, 0, 0)
ARROW_GAP = 4.0
ARROW_LEN = 36.0
HEAD_LEN = 12.0
HEAD_ANGLE = 2.6
DIAGONALS = [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)]

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("pip install pillow", file=sys.stderr)
    sys.exit(1)


def unit(v):
    n = math.hypot(v[0], v[1])
    return (v[0] / n, v[1] / n)


def rotate(v, angle):
    cos = math.cos(angle)
    sin = math.sin(angle)
    return (v[0] * cos - v[1] * sin, v[0] * sin + v[1] * cos)


def render(entry):
    ident = entry["id"]
    path = None
    for ext in (".jpg", ".png"):
        candidate = os.path.join(PHOTO_DIR, ident + ext)
        if os.path.isfile(candidate):
            path = candidate
            break
    if path is None:
        print("skip %s: no image" % ident)
        return

    image = Image.open(path).convert("RGB")
    width, height = image.size
    crop = entry.get("crop") or [0.0, 0.0, 1.0, 1.0]
    origin = (crop[0] * width, crop[1] * height)
    region = (crop[2] * width, crop[3] * height)
    scale = PREVIEW_HEIGHT / region[1]
    canvas = image.crop((int(round(origin[0])), int(round(origin[1])),
                         int(round(origin[0] + region[0])),
                         int(round(origin[1] + region[1])))).resize(
        (int(round(region[0] * scale)), int(round(region[1] * scale))))
    # Draw at 2x so centered strokes and the 1.5 px head outline match PhotoView.
    raster_scale = 2
    overlay = Image.new("RGBA", (canvas.width * raster_scale, canvas.height * raster_scale))
    draw = ImageDraw.Draw(overlay)

    for marker in entry.get("markers", []):
        cx, cy, r = marker
        center = ((cx * width - origin[0]) * scale,
                  (cy * height - origin[1]) * scale)
        ring = r * width * scale
        def point(p):
            return (p[0] * raster_scale, p[1] * raster_scale)

        for color, stroke in ((OUTLINE, 5), (RING, 3)):
            outer = ring + stroke * 0.5
            bbox = (*point((center[0] - outer, center[1] - outer)),
                    *point((center[0] + outer, center[1] + outer)))
            draw.ellipse(bbox, outline=color, width=stroke * raster_scale)

        chosen = None
        for diagonal in DIAGONALS:
            u = unit(diagonal)
            tip = (center[0] + u[0] * (ring + ARROW_GAP),
                   center[1] + u[1] * (ring + ARROW_GAP))
            tail = (tip[0] + u[0] * ARROW_LEN, tip[1] + u[1] * ARROW_LEN)
            if 0 <= tail[0] < region[0] * scale and 0 <= tail[1] < region[1] * scale:
                chosen = (u, tip, tail)
                break
        if chosen is None:
            u = unit(DIAGONALS[-1])
            tip = (center[0] + u[0] * (ring + ARROW_GAP),
                   center[1] + u[1] * (ring + ARROW_GAP))
            tail = (tip[0] + u[0] * ARROW_LEN, tip[1] + u[1] * ARROW_LEN)
            chosen = (u, tip, tail)
        u, tip, tail = chosen

        draw.line((point(tail), point(tip)), fill=OUTLINE, width=6 * raster_scale)
        draw.line((point(tail), point(tip)), fill=RING, width=3 * raster_scale)

        back = (-u[0], -u[1])
        head = [tip,
                (tip[0] + rotate(back, HEAD_ANGLE)[0] * HEAD_LEN,
                 tip[1] + rotate(back, HEAD_ANGLE)[1] * HEAD_LEN),
                (tip[0] + rotate(back, -HEAD_ANGLE)[0] * HEAD_LEN,
                 tip[1] + rotate(back, -HEAD_ANGLE)[1] * HEAD_LEN)]
        head = [point(p) for p in head]
        draw.polygon(head, fill=RING)
        draw.line(head + [head[0]], fill=OUTLINE, width=int(1.5 * raster_scale))

    overlay = overlay.resize(canvas.size, Image.Resampling.LANCZOS)
    canvas.paste(overlay, (0, 0), overlay)

    out = "build/marker_preview/%s.png" % ident
    canvas.save(os.path.join(OUT_DIR, ident + ".png"))
    print("ok %s -> %s" % (ident, out))


def main(argv):
    with open(MANIFEST, encoding="utf-8") as f:
        manifest = json.load(f)
    ids = set(argv)
    os.makedirs(OUT_DIR, exist_ok=True)
    for entry in manifest:
        if ids and entry["id"] not in ids:
            continue
        render(entry)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
