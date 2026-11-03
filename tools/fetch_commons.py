#!/usr/bin/env python3
"""Fetch CC-licensed photomicrographs from Wikimedia Commons per tools/photo_manifest.json.

Writes assets/photos/<id>.<ext> and data/photos.json. Python 3 stdlib only.
Marker triples are copied through to data/photos.json.
Exit code 1 if any entry was rejected or failed.
Existing downloaded/committed images are reused after live metadata and license
checks, unless the prior photos.json source_title changed. Crop-only changes
reuse the image. Delete an image file to refresh same-source image revisions.
Image GETs omit Commons' utm_* tracking parameters, which can cause spurious
CDN HTTP 429 responses.
"""
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MANIFEST = os.path.join(ROOT, "tools", "photo_manifest.json")
OUT_JSON = os.path.join(ROOT, "data", "photos.json")
OUT_DIR = os.path.join(ROOT, "assets", "photos")
API = "https://commons.wikimedia.org/w/api.php"
UA = "HemoShift/1.0 (educational game; contact via repo)"

ALLOWED = [
    re.compile(r"^CC0(\s|$)", re.I),
    re.compile(r"^Public domain$", re.I),
    re.compile(r"^CC BY (2\.0|2\.5|3\.0|4\.0)$", re.I),
    re.compile(r"^CC BY-SA (2\.0|2\.5|3\.0|4\.0)$", re.I),
    re.compile(r"^Apache License 2\.0$", re.I),
]

_last_call = 0.0


def http_get(url):
    """GET with >=1 s spacing and 429 backoff (5/10/20 s)."""
    global _last_call
    delays = [5, 10, 20]
    attempt = 0
    while True:
        wait = 1.05 - (time.time() - _last_call)
        if wait > 0:
            time.sleep(wait)
        _last_call = time.time()
        req = urllib.request.Request(url, headers={
            "User-Agent": UA,
            "Accept": "image/avif,image/webp,image/apng,image/svg+xml,image/*;q=0.8,*/*;q=0.5",
            "Referer": "https://commons.wikimedia.org/",
        })
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < len(delays):
                time.sleep(delays[attempt])
                attempt += 1
                continue
            raise


def license_ok(name):
    return any(p.match(name.strip()) for p in ALLOWED)


def strip_tags(s):
    return html.unescape(re.sub(r"<[^>]+>", "", s)).strip()


def author_name(artist_html):
    """Author credit only: Commons Artist fields can embed profile/consent boilerplate."""
    text = strip_tags(artist_html).split("\n", 1)[0]
    text = re.sub(r"\s+Author info\b.*$", "", text)
    return re.sub(r"\s+", " ", text).strip()


def markers_ok(entry):
    """Marker triples must be 1-3 normalized [cx, cy, r] values."""
    markers = entry.get("markers")
    if not isinstance(markers, list) or not 1 <= len(markers) <= 3:
        return False
    for marker in markers:
        if not isinstance(marker, list) or len(marker) != 3:
            return False
        cx, cy, r = marker
        if not all(isinstance(v, (int, float)) for v in marker):
            return False
        if not 0 <= cx <= 1 or not 0 <= cy <= 1 or not 0 < r <= 0.5:
            return False
    return True


def main():
    with open(MANIFEST, encoding="utf-8") as f:
        manifest = json.load(f)
    previous_sources = {}
    if os.path.isfile(OUT_JSON):
        try:
            with open(OUT_JSON, encoding="utf-8") as f:
                previous = json.load(f)
        except (OSError, ValueError):
            previous = []
        for photo in previous:
            if isinstance(photo, dict) and "id" in photo:
                previous_sources[photo["id"]] = photo.get("source_title")
    os.makedirs(OUT_DIR, exist_ok=True)
    photos = []
    failed = False
    for e in manifest:
        ident = e["id"]
        title = "File:" + e["commons"]
        if not markers_ok(e):
            print("ERROR %s: markers must be 1-3 [cx, cy, r] entries with 0<=cx,cy<=1 and 0<r<=0.5" % ident, file=sys.stderr)
            failed = True
            continue
        q = urllib.parse.urlencode({
            "action": "query", "format": "json", "titles": title,
            "prop": "imageinfo", "iiprop": "url|extmetadata", "iiurlwidth": 640,
        })
        try:
            data = json.loads(http_get(API + "?" + q))
            page = next(iter(data["query"]["pages"].values()))
            info = page["imageinfo"][0]
        except Exception as ex:  # noqa: BLE001
            print("ERROR %s: lookup failed for %s (%s)" % (ident, title, ex), file=sys.stderr)
            failed = True
            continue
        meta = info.get("extmetadata", {})
        lic = meta.get("LicenseShortName", {}).get("value", "")
        if not license_ok(lic):
            print("ERROR %s: license %r not allowed (%s)" % (ident, lic, title), file=sys.stderr)
            failed = True
            continue
        thumb = info.get("thumburl") or info["url"]
        # Commons appends analytics parameters that some image edges reject.
        # Remove only tracking parameters; preserve the exact image path/size.
        parts = urllib.parse.urlsplit(thumb)
        query = urllib.parse.urlencode([
            (k, v) for k, v in urllib.parse.parse_qsl(parts.query, keep_blank_values=True)
            if not k.startswith("utm_")
        ])
        thumb = urllib.parse.urlunsplit(parts._replace(query=query))
        ext = os.path.splitext(urllib.parse.urlparse(thumb).path)[1].lower() or ".jpg"
        fname = ident + ext
        path = os.path.join(OUT_DIR, fname)
        source_matches = ident not in previous_sources or previous_sources[ident] == title
        if not os.path.isfile(path) or not source_matches:
            try:
                blob = http_get(thumb)
            except Exception as ex:  # noqa: BLE001
                print("ERROR %s: download failed (%s)" % (ident, ex), file=sys.stderr)
                failed = True
                continue
            with open(path, "wb") as f:
                f.write(blob)
        photos.append({
            "id": ident,
            "morph": e["morph"],
            "file": "res://assets/photos/" + fname,
            "crop": e.get("crop", [0, 0, 1, 1]),
            "markers": e["markers"],
            "source_title": title,
            "source_url": info.get("descriptionurl", ""),
            "author": author_name(meta.get("Artist", {}).get("value", "")) or "Unknown",
            "license": lic,
            "license_url": meta.get("LicenseUrl", {}).get("value", ""),
        })
        print("ok %s (%s)" % (ident, lic))
    photos.sort(key=lambda p: p["id"])
    with open(OUT_JSON, "w", encoding="utf-8") as f:
        json.dump(photos, f, ensure_ascii=False, indent=1)
        f.write("\n")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
