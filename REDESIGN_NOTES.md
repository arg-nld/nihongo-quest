# Visual Redesign Notes

This pass refreshes the visual layer while retaining the existing Flutter/Riverpod curriculum and progression systems.

## What changed

- **Shared design system:** cleaner forest-green and warm-neutral palette, more consistent typography, rounded surfaces, calmer outlines, and clearer primary/secondary actions.
- **Home screen:** clearer next-lesson hierarchy, compact progress/stat elements, and a more readable daily goal.
- **Exercise UI:** cleaner multiple-choice tiles and answer-state transitions with letter markers instead of decorative emoji. Fill-in-the-blank exercises now render as shuffled multiple-choice options while retaining accepted-answer validation.
- **Adventure map:** a continuous, vertically composed Candy Crush-style route through all 17 chapter environments. Each region is an independent portrait-native (720×1280) transparent SVG vignette. Flutter paints one shared terrain canvas and one continuous winding path, with chapter-specific scenery fading into neighboring terrain rather than appearing as cards or separately stacked maps. Artwork keeps its 9:16 aspect ratio and is never stretched or rotated.
- **Boss battle:** the Frost Shrine Guardian is now an original Canvas-drawn sprite rather than a bitmap. Its idle bob, hit recoil, attack, victory, and defeat motions use Flutter animations; its question timer is frame-driven for a smooth progress bar. Match/dropdown exercises are expanded into individual multiple-choice questions.
- **Navigation and responsive layout:** adaptive bottom navigation on phones and a NavigationRail on wider screens, max-width content on large displays, fade/slide transitions between pages, and a short lesson debrief before each stage.
- **Adventure Shop:** repeatable one-battle Heart Elixirs, permanent timer upgrades (+2 seconds per rank, up to four ranks), and permanent damage upgrades (+2 damage per rank, up to five ranks). Inventory and upgrade ranks are saved with player progress.
- **Accuracy gates and stage preservation:** the original category grouping and stage split rules are retained. Short levels receive related reinforcement questions until they have at least five distinct questions; reinforcement questions may recur across different stages but do not repeat within the same stage. This fixes the three-question 80% scoring problem without merging away map stops.

## Run and verify

With Flutter SDK 3.13.5 or compatible stable tooling installed, run from this directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The source was checked for balanced Dart delimiters and curriculum JSON validity in the editing environment. A Flutter compile, analyzer run, device preview, and automated Flutter tests were **not** run because the Flutter/Dart SDK is not installed in that environment.
