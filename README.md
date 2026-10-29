# Nihongo Quest

A local-first, Android-first Flutter RPG for learning Japanese with
*Japanese From Zero! 1* as the curriculum spine. No ads, no payments, no
energy timers, no backend, no accounts — your progress lives on your device.

## Run it

Prerequisites: Flutter SDK 3.x (channel stable), Android SDK for device
builds. Verify with `flutter doctor`.

```bash
flutter pub get
flutter run                 # pick an attached device/emulator
```

Other useful commands:

```bash
flutter analyze             # static analysis
flutter test                # unit + content tests
flutter build apk           # release APK (Android)
flutter run -d chrome       # run the web version locally
flutter build web           # build the browser version
```

## Project structure

```
assets/curriculum/        Built JSON content (one file per section + index)
assets/artwork/           17 portrait region SVGs, 17 landscape arena SVGs, and 17 boss SVGs
lib/
  main.dart               App bootstrap (loads SharedPreferences, seeds providers)
  models/                 Curriculum + progress models (immutable, JSON round-trip)
  core/                   AnswerChecker, Rewards (anti-farm rules), content rules
  data/                   CurriculumRepository (asset loader), ProgressRepository
  providers/              Riverpod providers + ProgressController (all game state)
  ui/                     Screens: home, world map, review, shop, profile, lesson debrief/player,
                          exercise widgets, vocab collection, SVG-art boss battles
tools/content_builder/    Content pipeline: author Python dict modules, build JSON
test/                     Unit + curriculum completeness tests
vlm_ocr/chapters/         OCR of Japanese From Zero! 1 (the content source)
docs/curriculum_inventory.md   Page-coverage audit + integration status
```

## The content pipeline (how to add or edit lessons)

Curriculum content is authored as Python dict-literal modules in
`tools/content_builder/` (one `LESSON = {...}` per file) because the source
text contains both straight quotes and Japanese characters; the builder then
emits validated JSON into `assets/curriculum/`.

```bash
# build one section
python -I tools/content_builder/build.py lesson_02
# build everything
python -I tools/content_builder/build.py
```

The builder validates every section: exercise types and their required
fields, `answerIndex` bounds, `___` in fill_blank prompts, unique exercise IDs
across the whole curriculum, `vocabId` cross-references, and — for scored
quizzes — that only `verified: true` items appear. A section that fails
validation is never written, so malformed content cannot crash the app.

To add a lesson: copy an existing `tools/content_builder/lesson_NN.py`, edit
the `LESSON` dict (vocab, grammar, exercises, quiz — every item carries an
`id`, `source` page attribution, and `verified` flag), add the section id to
`SECTIONS` in `build.py` if it is new, rebuild, and run `flutter test`
(`test/content_test.dart` enforces completeness).

## Curriculum

Sections follow the book exactly: Pre-Lessons A–D, Lessons 1–13, plus a
Reference section built from the back matter. See
`docs/curriculum_inventory.md` for the page-coverage audit, which parts are
source-derived vs. authored glue, and known OCR gaps.

The Reference Library is browsable from the start: it is a phrasebook and
glossary companion, not a lesson — nothing in it is scored, scheduled for
review, or required to unlock anything.

The Adventure Map displays every category-based level (for example, Writing
Systems, Pronunciation, Word Meanings, and Sentence Building) as its own mini
stop along one winding route. The first stage of an unlocked unit opens first;
each later stop unlocks after the previous stage is cleared. Regular levels have
no timer or lives; answer each question once and reach 80% accuracy to unlock
the next node. A mixed Mastery Review comes before the unit's final Boss Battle.
Every stage opens with a short tutor debrief, vocabulary review, and examples
of the question styles. Regular levels keep the original map structure and each contains at least five distinct questions. Short levels add related reinforcement questions; these may recur across stages, but never repeat inside a single stage, so an 80% pass gate is meaningful without removing map stops. Fill-in-the-blank questions are
multiple choice, and boss match questions become one multiple-choice question
per pair. Defeating the boss completes the unit and unlocks the next curriculum
section.

The responsive Adventure Shop sells repeatable Heart Elixirs (+1 heart for one
boss attempt), permanent Time Crystals (+2 seconds per question per rank, up to
four ranks), and Power Runes (+2 damage per correct answer per rank, up to five
ranks). Each learning unit has its own region illustration and SVG boss character;
combat effects, character motion, and the question timer remain animated in Flutter.
Inventory and upgrades are saved with player progress. See `ARTWORK_README.md` for
the editable SVG asset system, chapter mapping, and maintenance workflow.

The Home screen's **Cumulative Review** is a separate optional exam mixed from
previously completed lessons. It pays review-style rewards only and gates
nothing; passing it once grants the "Cumulative Challenger" achievement.

## How progress and spaced repetition work

- **Rewards (anti-farm).** An exercise pays full XP/coins only the first time
  you answer it correctly; replays pay a token amount (1/5 XP). Unit-completion
  rewards pay once per section; legacy quiz bonuses remain one-time. Reviewing pays —
  reviewing is the point.
- **SRS.** Each vocab item tracks attempts/correct/streak. Correct recall
  schedules the next review at 1, 3, 7, 14, 30, then 90 days (constant
  `ReviewState.intervals`); a miss resets the streak and schedules a 4-hour
  retry. Mastery tiers: `new` (untouched), `learning` (streak 0),
  `familiar` (streak 1–2), `mastered` (streak ≥ 3 with ≥ 60% accuracy).
  One lucky guess never masters an item.
- **Unlocks.** Sections unlock sequentially when the previous section's
  final Boss Battle is defeated. The legacy quiz-based completion route remains
  supported for saved progress and direct test routes.
- **Level path.** Stage completion IDs are stored alongside the existing local
  progress document. Older saves without stage IDs remain readable.
- **Daily quest.** One review quest per calendar day; completing it again the
  same day grants nothing.
- **Persistence.** The whole progress document is one JSON blob under the
  versioned key `nihongo_quest_progress_v1`. A corrupted save starts fresh
  rather than crashing. Swap storage backends by implementing
  `ProgressRepository` — nothing else changes.

## Settings

Profile → Settings: show/hide romaji, immediate feedback vs. exam-style
delayed feedback (quiz answers are graded when you submit), daily review goal.

## Known limitations

- No audio assets exist yet, so there is no sound; the data model already
  carries the fields audio would need.
- The JLPT N5 workbook files were not present in the project, so nothing from
  them is integrated (documented in `docs/curriculum_inventory.md`).
- Content derived from OCR: a small number of picture-based book activities
  are omitted (no images in the OCR archive); ambiguous OCR readings are
  skipped or marked `verified: false` and excluded from scored quizzes.
- `shared_preferences` keeps progress on-device only — uninstalling the app
  clears progress (no cloud backup by design).
