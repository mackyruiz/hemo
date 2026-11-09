# hemo
This is a gamified learning app for the MLT certification exam, built around hematology lab shifts.

Disclaimer: I am no where near a medical professional but i know how to use AI to vibecode stuff.

## What it is

**HemoShift** is a browser-only, on-device-save lab-shift learning game for MLT certification exam prep.

HemoShift helps MLT students and interns review every content area of the certification exam required for California MLT licensure: hematology, blood banking, chemistry, microbiology, urinalysis and body fluids, immunology, and laboratory operations including safety. CDPH Laboratory Field Services accepts the ASCP BOC MLT (U.S. version) and AAB MLT certification exams. Content follows the ASCP BOC MLT examination content guideline (revised June 9, 2026).

Not affiliated with or endorsed by ASCP, AAB, or CDPH. For study only; not medical advice. Reference ranges vary between laboratories.

Content alignment: ASCP BOC MLT Examination Content Guideline, revised June 9, 2026. The game covers hematology (physiology, RBC/WBC/platelet disorders, laboratory testing, hemostasis), blood banking, urinalysis and body fluids, chemistry, immunology, microbiology, and laboratory operations (QC and safety). Board Sim is a 100-item, 150-minute adaptive practice exam weighted like the exam's content areas, not the actual certification exam or an official pass predictor. AI-authored educational content needs review by an MLS/educator before public promotion.

## Play

<https://mackyruiz.github.io/hemo/>

Install on phone: Safari Share → Add to Home Screen / Chrome menu → Install app.

Career shifts unlock benches as you gain XP; Practice makes every bench available. Cell Atlas, flashcards and every bench show credited photomicrographs with a ring-and-arrow marker on the finding in question. Progress stays in this browser's local storage; clearing site data removes it. Private browsing or blocked storage can prevent persistence. There are no accounts, server-side saves, or native Android/iOS builds.

The home-screen footer links to dated version history (Git revisions, newest first) and the [GitHub project](https://github.com/mackyruiz/hemo) through the GitHub icon. Update `scripts/screens/version_history.gd` when publishing a new milestone.

## Develop

Use **Godot 4.7.2-stable**, GDScript, and the Compatibility renderer. Download the Linux editor and export templates from the [Godot 4.7.2 release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable). Put the executable on `PATH` as `godot`; extract the contents of the archive's `templates/` directory into `~/.local/share/godot/export_templates/4.7.2.stable/`.

GUT 9.7.1 is vendored in `addons/gut/`, including its license.

```sh
godot --version
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit
```

Open `project.godot` in the editor to run interactively. Pure logic is in `scripts/core/`; screens and benches are code-built Controls. `scenes/main.tscn` is the only application scene. Saves use `user://save.json` (IndexedDB-backed in web builds).

Debug mode unlocks every bench so all content is reachable without earning XP. It is off unless you ask for it: start the game with `godot --path . -- --unlock-all`, or export with a preset carrying the `unlock_all` custom feature. While it is on, `Progress.level()` reports the maximum level and the hub shows a DEBUG banner; XP is still earned and saved, so the real level returns the moment the flag is off. Release builds have neither the argument nor the feature. A local `Web Debug` export preset (`custom_features="unlock_all"`, `export_path="build/web-debug/index.html"`, PWA off so its service worker cannot cache over the production build) is a convenience for browser testing and is not part of the repository.

## Build locally

```sh
godot --headless --import
mkdir -p build/web
godot --headless --export-release "Web" build/web/index.html
python3 -m http.server 8060 -d build/web
```

Open <http://localhost:8060/>. Web export is single-threaded; GitHub Pages needs no custom COOP/COEP headers. PWA installation on a hosted site requires HTTPS (localhost is allowed for development).

## Publish

Pushing to `main` runs `.github/workflows/build.yml`, which tests, exports, checks that `index.pck` is at most 20 MiB, and deploys to GitHub Pages. Pull requests run the build without deployment. Pages must use **GitHub Actions** as its source.

## Content

Run the test command above; `test_content.gd` validates all content using the same loader as the application.

JSON files:

| File | Shape / fields |
| --- | --- |
| `data/questions/<topic>.json` | Array of questions: `id`, `topic`, `subtopic`, `difficulty` (1–3), `kind` (`theoretical` or `procedural`), `stem`, `image` (null or morphology id), `choices` (4 distinct strings), `answer` (0–3), `explanation`, `source` (id in `data/sources.json`). |
| `data/morphology.json` | Object keyed by morphology id: `name`, `category` (`rbc`, `inclusion`, `organism`, `wbc`, `plt`, `stain`), `features`, `associations` (at least 2), `confusers` (at least 3 other ids), `art`, `source`. |
| `data/photos.json` | Generated array: `id`, `morph`, `file`, `crop` (normalized x/y/width/height), `markers` (1-3 normalized `[cx, cy, r]`), `source_title`, `source_url`, `author`, `license`, `license_url`. Do not hand-edit. |
| `data/cases_cbc.json` | Array: `id`, `topic`, `subtopic`, `difficulty`, `sex`, adult `age`, `vignette`, `cbc`, `spurious`, `smear` (morphology ids), `steps` (2–4 question-shaped steps), `source` (a step may carry its own `source` override). |
| `data/cases_coag.json` | Array: `id`, `topic`, `subtopic`, `difficulty`, `sex`, adult `age`, `vignette`, `results`, `steps` (2–4), `source` (steps may override). Results: `PT`, `INR`, `APTT`, `FIB`, `DDIMER`, `TT`, `PLT`, `MIX_PT`, `MIX_APTT`. Null means not performed; mixing results are `corrected` or `not_corrected`. |
| `data/reference_ranges.json` | Object keyed by test: `{low, high, unit}` or sex-specific `{M:{low,high}, F:{low,high}, unit}`. |
| `data/diff_profiles.json` | Array: `id`, `label`, `tier`, `wbc:[low,high]`, `nrbc:[low,high]`, `pct` (class → percentage, total 100). |
| `data/sources.json` | Object: `sources` (id `^[a-z0-9-]+$` → `{title, publisher, url, keyword}`) and `generated` (keys `drill:<type>`, `chem:<type>`, `qc:westgard`, `coag:cascade`, `diff:<profile id>`, `micro:identification`, `ua:interpretation`, `bb:abo_rh`, `immuno:hepatitis_b`, `safety:waste` → source id, for content built at runtime). |

Topic ids, display names and exam content areas live in `scripts/core/topics.gd` (`Topics`): `phys`, `rbc`, `wbc`, `plt`, `lab`, `hemo` (hematology), `bb` (blood banking), `ua` (urinalysis & body fluids), `chem`, `immuno`, `micro`, and `qc` plus `safety` (lab operations). Allowed subtopics are enumerated in `ContentValidator`. Question ids use `<topic>-NNNN`; case ids use `cbc-NNN` or `coag-NNN`. Steps contain `stem`, `choices`, `answer`, and `explanation`.

Art descriptors use `kind: rbc|wbc|platelet|field`. RBC descriptors specify `shape`, relative `size`, `color`, `pallor`, optional `inclusions` and `nucleus`. WBC descriptors specify `size`, `cytoplasm`, `nucleus` (shape, lobes, color, N:C ratio `nc`, chromatin, nucleoli), optional `granules` and `features`. Platelets specify `size`, `color`, and granules. Fields specify `arrangement`. `CellArt` renders these deterministically from an injected seed.

The validator checks bank minimums and difficulty shares, topic/subtopic and morphology references, four-choice answers, CBC index arithmetic unless deliberately spurious, coagulation result consistency, differential totals, and photo paths. Write original questions with one best answer, explanatory feedback, and U.S. laboratory units; do not copy commercial question banks.

## Sources and hints

After answering, the feedback area shows a "Read more" button that opens the item's source page in a new tab. `ContentValidator` requires every question, case, morphology entity and generated-content key to resolve to a source whose URL is `https` on an allow-listed host (`nih.gov` and subdomains, `medlineplus.gov`, `cdc.gov`, `cancer.gov`, `who.int`, `fda.gov`, `osha.gov`, `hematology.org`) and rejects unused sources. Add a host to `SOURCE_HOSTS` in `content_validator.gd` to widen the list. `www.ncbi.nlm.nih.gov/books` (StatPearls) is bot-challenged and cannot be verified by script, so it is not used.

```sh
python3 tools/check_sources.py
```

The checker GETs every registry URL and requires HTTP 200 and the entry's `keyword` in the page (PubMed Central articles are checked through NCBI E-utilities). It is run manually; CI never calls external sites.

The Hint button, offered on questions with at least three choices during shifts and practice (not in Board Sim), leaves the correct answer plus one wrong choice: two wrong choices are removed from four, or one from three. Hints are unlimited and carry no XP, Leitner or accuracy penalty (`Hint.eliminate`).

## Photo credits

`tools/fetch_commons.py` generates `data/photos.json` from `tools/photo_manifest.json`. Source titles, authors, and licenses are shown in-app under Settings → Credits. Downloaded images are committed; CI never calls Commons.

```sh
python3 tools/fetch_commons.py
```

The pipeline requests 640-pixel Wikimedia Commons thumbnails, checks its license allow-list, and preserves source/license links. Every manifest entry needs `markers`: 1-3 `[cx, cy, r]` entries normalized to the full image (`cx` by width, `cy` by height, `r` by width) that the app draws as a ring and arrow; marker centers must lie inside the optional `crop`. After changing the manifest, inspect every downloaded image with `python3 tools/preview_markers.py [id ...]` (writes `build/marker_preview/<id>.png`) and adjust crops and markers so the named finding is clear.

The API is requested at width 640; Commons may return a larger standard-size thumbnail bucket or a smaller original. The fetcher removes marketing `utm_*` parameters from image URLs to avoid observed CDN HTTP 429 responses, without changing the image resource or resolution. Existing committed images are reused after refreshing license metadata; changing a source title invalidates that cache. Delete the corresponding asset to refresh a revised image under the same source title. Cropped displays are identified in credit lines.

The release contains 570 questions (38 image-based), 130 glossary terms, 30 CBC cases, 20 coagulation cases, all 51 explicitly enumerated morphology findings, and 51 curated photos covering 47 findings. Bite cell, Cabot ring, Heinz body and promyelocyte have no acceptable photo; they appear in the Atlas as text only and their questions carry no image. Drawn cells remain only in the Lab Floor microscope and home-tile art.

DejaVu Sans is bundled so correctness symbols, mathematical notation and keypad glyphs render consistently in web builds. Its Bitstream Vera license and notices are in `assets/fonts/LICENSE.txt` and displayed in-app under Credits.
