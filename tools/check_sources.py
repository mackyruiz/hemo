#!/usr/bin/env python3
"""Verify every entry in data/sources.json still resolves and mentions its keyword.

For each source: GET the url (following redirects), require HTTP 200 and that the
entry's `keyword` appears (case-insensitive) in the page text. Prints `ok <id>` or
`ERROR <id>: <reason>` and exits 1 if any entry fails. Optional arguments restrict the
run to the given source ids.

PubMed Central article pages sit behind a bot challenge for scripts, so those are
checked through the NCBI E-utilities full-text endpoint instead (same article).
Run manually; CI never hits external sites.
"""
import html
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request

UA = "HemoShift/1.0 (educational game; contact via repo)"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PMC_RE = re.compile(r"^https://(?:pmc\.ncbi\.nlm\.nih\.gov/articles|www\.ncbi\.nlm\.nih\.gov/pmc/articles)/PMC(\d+)")
EFETCH = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pmc&rettype=xml&id=%s"

_last_request = 0.0


def http_get(url):
    """GET with >=1 s spacing and 5/10/20 s backoff on HTTP 429 and on PubMed's
    intermittent 203 throttle responses. Retries once with a browser-shaped UA when a
    CDN bot filter (OSHA, some CDC paths) rejects the plain UA with 403. Returns
    (status, body)."""
    status, body = _get(url, UA)
    if status == 403:
        status, body = _get(url, "Mozilla/5.0 (X11; Linux x86_64) " + UA)
    return status, body


def _get(url, user_agent):
    global _last_request
    delays = [5, 10, 20]
    for attempt in range(len(delays) + 1):
        wait = 1.0 - (time.monotonic() - _last_request)
        if wait > 0:
            time.sleep(wait)
        _last_request = time.monotonic()
        req = urllib.request.Request(url, headers={"User-Agent": user_agent, "Accept": "text/html,application/xml;q=0.9,*/*;q=0.8"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                charset = r.headers.get_content_charset() or "utf-8"
                if r.status == 203 and attempt < len(delays):
                    time.sleep(delays[attempt])
                    continue
                return r.status, r.read().decode(charset, errors="replace")
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < len(delays):
                time.sleep(delays[attempt])
                continue
            return e.code, ""
    return 429, ""


def page_text(body):
    text = re.sub(r"(?is)<(script|style)\b.*?</\1>", " ", body)
    text = re.sub(r"(?s)<[^>]+>", " ", text)
    return re.sub(r"\s+", " ", html.unescape(text))


def check(source_id, entry):
    url = entry["url"]
    fetch_url = url
    match = PMC_RE.match(url)
    if match:
        fetch_url = EFETCH % match.group(1)
    try:
        status, body = http_get(fetch_url)
    except (urllib.error.URLError, TimeoutError, OSError) as e:
        return "request failed: %s" % e
    if status != 200:
        return "HTTP %d for %s" % (status, fetch_url)
    keyword = entry["keyword"].lower()
    if keyword not in body.lower() and keyword not in page_text(body).lower():
        return "keyword %r not found in %s" % (entry["keyword"], fetch_url)
    return None


def main():
    with open(os.path.join(ROOT, "data", "sources.json"), encoding="utf-8") as f:
        sources = json.load(f)["sources"]
    failures = 0
    wanted = sys.argv[1:] or sorted(sources)
    for source_id in wanted:
        if source_id not in sources:
            print("ERROR %s: not in data/sources.json" % source_id, flush=True)
            failures += 1
            continue
        problem = check(source_id, sources[source_id])
        if problem:
            failures += 1
            print("ERROR %s: %s" % (source_id, problem), flush=True)
        else:
            print("ok %s" % source_id, flush=True)
    print("%d sources, %d errors" % (len(wanted), failures))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
