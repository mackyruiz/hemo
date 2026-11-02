# hemo
This is a gamified learning app for Hematology. 

Disclaimer: I am no where near a medical professional but i know how to use AI to vibecode stuff.

## What it is

**HemoShift** is a browser-only, on-device-save hematology lab-shift learning game.

HemoShift helps MLT students and interns review hematology for the certification exam required for California MLT licensure. CDPH Laboratory Field Services accepts the ASCP BOC MLT (U.S. version) and AAB MLT certification exams. Content follows the ASCP BOC MLT content guideline for Hematology (physiology, disease states, laboratory testing, hemostasis).

Not affiliated with or endorsed by ASCP, AAB, or CDPH. For study only; not medical advice. Reference ranges vary between laboratories.

Content alignment: ASCP BOC MLT Examination Content Guideline, revised September 25, 2025. The game includes physiology, RBC/WBC/platelet disorders, laboratory testing, hemostasis, and QC. Board Sim is a 50-item, 75-minute adaptive practice exam, not the actual certification exam or an official pass predictor. AI-authored educational content needs review by an MLS/educator before public promotion.

## Play

<https://mackyruiz.github.io/hemo/>

Install on phone: Safari Share → Add to Home Screen / Chrome menu → Install app.

Career shifts unlock benches as you gain XP; Practice makes every bench available. Cell Atlas combines illustrations with credited photomicrographs. Progress stays in this browser's local storage; clearing site data removes it. Private browsing or blocked storage can prevent persistence. There are no accounts, server-side saves, or native Android/iOS builds.

## Develop

Use **Godot 4.7.2-stable**, GDScript, and the Compatibility renderer. Download the Linux editor and export templates from the [Godot 4.7.2 release](https://github.com/godotengine/godot/releases/tag/4.7.2-stable). Put the executable on `PATH` as `godot`; extract the contents of the archive's `templates/` directory into `~/.local/share/godot/export_templates/4.7.2.stable/`.

GUT 9.7.1 is vendored in `addons/gut/`, including its license.

```sh
godot --version
godot --headless --import
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit
```

Open `project.godot` in the editor to run interactively. Pure logic is in `scripts/core/`; screens and benches are code-built Controls. `scenes/main.tscn` is the only application scene. Saves use `user://save.json` (IndexedDB-backed in web builds).

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
| `data/questions/<topic>.json` | Array of questions: `id`, `topic`, `subtopic`, `difficulty` (1–3), `kind` (`theoretical` or `procedural`), `stem`, `image` (null or morphology id), `choices` (4 distinct strings), `answer` (0–3), `explanation`. |
| `data/morphology.json` | Object keyed by morphology id: `name`, `category` (`rbc`, `inclusion`, `organism`, `wbc`, `plt`, `stain`), `features`, `associations` (at least 2), `confusers` (at least 3 other ids), `art`. |
| `data/photos.json` | Generated array: `id`, `morph`, `file`, `crop` (normalized x/y/width/height), `source_title`, `source_url`, `author`, `license`, `license_url`. Do not hand-edit. |
| `data/cases_cbc.json` | Array: `id`, `topic`, `subtopic`, `difficulty`, `sex`, adult `age`, `vignette`, `cbc`, `spurious`, `smear` (morphology ids), `steps` (2–4 question-shaped steps). |
| `data/cases_coag.json` | Array: `id`, `topic`, `subtopic`, `difficulty`, `sex`, adult `age`, `vignette`, `results`, `steps` (2–4). Results: `PT`, `INR`, `APTT`, `FIB`, `DDIMER`, `TT`, `PLT`, `MIX_PT`, `MIX_APTT`. Null means not performed; mixing results are `corrected` or `not_corrected`. |
| `data/reference_ranges.json` | Object keyed by test: `{low, high, unit}` or sex-specific `{M:{low,high}, F:{low,high}, unit}`. |
| `data/diff_profiles.json` | Array: `id`, `label`, `tier`, `wbc:[low,high]`, `nrbc:[low,high]`, `pct` (class → percentage, total 100). |

Topic ids are `phys`, `rbc`, `wbc`, `plt`, `lab`, `hemo`, `qc`. Allowed subtopics are enumerated in `ContentValidator`. Question ids use `<topic>-NNNN`; case ids use `cbc-NNN` or `coag-NNN`. Steps contain `stem`, `choices`, `answer`, and `explanation`.

Art descriptors use `kind: rbc|wbc|platelet|field`. RBC descriptors specify `shape`, relative `size`, `color`, `pallor`, optional `inclusions` and `nucleus`. WBC descriptors specify `size`, `cytoplasm`, `nucleus` (shape, lobes, color, N:C ratio `nc`, chromatin, nucleoli), optional `granules` and `features`. Platelets specify `size`, `color`, and granules. Fields specify `arrangement`. `CellArt` renders these deterministically from an injected seed.

The validator checks bank minimums and difficulty shares, topic/subtopic and morphology references, four-choice answers, CBC index arithmetic unless deliberately spurious, coagulation result consistency, differential totals, and photo paths. Write original questions with one best answer, explanatory feedback, and U.S. laboratory units; do not copy commercial question banks.

## Photo credits

`tools/fetch_commons.py` generates `data/photos.json` from `tools/photo_manifest.json`. Source titles, authors, and licenses are shown in-app under Settings → Credits. Downloaded images are committed; CI never calls Commons.

```sh
python3 tools/fetch_commons.py
```

The pipeline requests 640-pixel Wikimedia Commons thumbnails, checks its license allow-list, and preserves source/license links. After changing the manifest, inspect every downloaded image and adjust normalized crops so the named finding is clear.

The API is requested at width 640; Commons may return a larger standard-size thumbnail bucket or a smaller original. The fetcher removes marketing `utm_*` parameters from image URLs to avoid observed CDN HTTP 429 responses, without changing the image resource or resolution. Existing committed images are reused after refreshing license metadata; changing a source title invalidates that cache. Delete the corresponding asset to refresh a revised image under the same source title. Cropped displays are identified in credit lines.

The release contains 300 questions (41 image-based), 30 CBC cases, 20 coagulation cases, all 51 explicitly enumerated morphology findings, and 47 curated photos. Two candidate photos were removed after visual inspection: gross-slide agglutination and an image without a clear bite cell; those findings remain illustrated.

DejaVu Sans is bundled so correctness symbols, mathematical notation and keypad glyphs render consistently in web builds. Its Bitstream Vera license and notices are in `assets/fonts/LICENSE.txt` and displayed in-app under Credits.
