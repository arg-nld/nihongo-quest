# Nihongo Quest SVG Artwork

The chapter artwork is stored as editable SVG source. The app renders these files directly through `flutter_svg`; it does not require PNG/JPEG exports, downloaded textures, or external image references.

## Asset layout

- `assets/artwork/regions/01.svg`–`17.svg`: independent portrait-native environmental vignettes with a `0 0 720 1280` viewBox and transparent backgrounds. Their composition is designed vertically; these are not rotated or stretched horizontal illustrations and they do not contain a full-map screenshot.
- `assets/artwork/arenas/01.svg`–`17.svg`: 16:9 chapter environments with a `0 0 1280 720` viewBox, retained specifically for boss-battle backdrops.
- `assets/artwork/bosses/01.svg`–`17.svg`: independent boss character illustrations with a `0 0 1024 1024` viewBox and a transparent background.
- `lib/ui/artwork_catalog.dart`: the canonical section-to-map-vignette, arena, and boss mapping.
- `tools/generate_vertical_regions.py`: generates the 17 720×1280 portrait vignettes. Run `python tools/generate_vertical_regions.py` to regenerate the map environmental art.
- `tools/generate_artwork.py`: regenerates the portrait map vignettes, the separate 16:9 arena art, and the 17 boss SVGs. Run `python tools/generate_artwork.py` from the project root to regenerate all 51 SVGs.

SVG files are intentionally self-contained and use paths, shapes, gradients, opacity, and clipping. Do not add embedded raster images or external references. Prefer SVG features supported by `flutter_svg` and the Flutter rendering path; validate any new feature in the app rather than relying only on browser rendering.

## Chapter mapping

| Asset number | Curriculum section ID | Region | Boss |
|---:|---|---|---|
| 01 | `pre_a` | Echo Village | Yamabiko |
| 02 | `pre_b` | Counting Creek | Soroban Golem |
| 03 | `pre_c` | Greeting Bridge | Tanuki Gatekeeper |
| 04 | `pre_d` | Crossroads Station | Kitsune Stationmaster |
| 05 | `lesson_01` | Hiragana Plains | Kakashi Scribe |
| 06 | `lesson_02` | Topic Terraces | Daruma of Wa |
| 07 | `lesson_03` | Umbrella Lane | Karakasa Collector |
| 08 | `lesson_04` | Koi Pond Hills | Nishikigoi Dragon |
| 09 | `lesson_05` | Sakura Hill | Konohana Spirit |
| 10 | `lesson_06` | Treasure Peak | Gold Oni |
| 11 | `lesson_07` | Kodama Grove | Kodama Elder |
| 12 | `lesson_08` | Maple Memory Trail | Nue of Yesterday |
| 13 | `lesson_09` | Moonlit Garden | Tsuki Usagi |
| 14 | `lesson_10` | Festival Street | Oni Shopkeeper |
| 15 | `lesson_11` | Counter Cove | Giant Tako |
| 16 | `lesson_12` | Verb Volcano | Magma Ryu |
| 17 | `lesson_13` | Time Temple | Tokei Karakuri |

The Reference Library is intentionally not assigned a boss. Asset numbers follow the learning order: Pre-Lessons A–D followed by Lessons 1–13.

## Integration notes

`MapScreen` is a single vertically connected world. The first learning stage sits near the bottom and the later stages climb upward, following a winding trail in the style of a Candy Crush map; the viewport opens at the first stage and retains its pan position when the widget rebuilds. Each chapter's biome tint spans the whole section, and adjacent sections share the same blended color at their boundary to avoid hard horizontal seams. Each region SVG is a true 9:16 portrait composition. Its aspect ratio is kept intact; a small, centered horizontal overscan may be clipped by the map viewport, never stretched or rotated. The scene fades at its edges into the shared terrain, while the route and interactive nodes remain Flutter-painted layers. The route is painted above the terrain and region art so it remains one continuous trail across the chapter transitions. Route nodes still own navigation, unlock state, and progress behavior.

The boss battle screen uses the separate corresponding landscape arena SVG as its backdrop and the matching boss SVG as its animated character; the existing Canvas painter is retained only for combat effects such as impact rings, attack slashes, motes, and victory/defeat reactions.

To replace artwork, edit the relevant SVG directly or update its design in `tools/generate_artwork.py`, regenerate, and inspect the resulting SVG and its in-app scale. Keep each chapter as a separate file and preserve the numbered filenames unless you also update `ChapterArtwork` and its tests. Check the chapter mapping against `assets/curriculum/curriculum.json` before changing section IDs.

## Validation

From the project root, run:

```bash
python tools/generate_artwork.py
flutter pub get
flutter analyze
flutter test
```

The generators validate XML structure, the 17 portrait region files, 17 landscape arena files, 17 boss files, and that the SVGs have no `<image>` element or external asset URLs. `test/vertical_artwork_test.dart` additionally checks the portrait viewBox in the asset bundle. Flutter analysis and tests must be run with the project's supported Flutter SDK.
