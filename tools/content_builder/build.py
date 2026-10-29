#!/usr/bin/env python3
"""Content builder: converts lesson content Python modules into JSON assets.

Why Python modules? File-writing tools treat files whose entire content parses
as JSON as structured data, so lesson content is authored as Python dict
literals (LESSON = {...}) and this script emits the JSON the app loads.

Usage:
  python -I tools/content_builder/build.py            # build all
  python -I tools/content_builder/build.py pre_a      # build one section
  python -I tools/content_builder/build.py --list     # list sections
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONTENT_DIR = Path(__file__).resolve().parent
ASSET_DIR = ROOT / "assets" / "curriculum"

# Section id -> module file (one LESSON dict per module)
SECTIONS = [
    "pre_a", "pre_b", "pre_c", "pre_d",
    "lesson_01", "lesson_02", "lesson_03", "lesson_04", "lesson_05",
    "lesson_06", "lesson_07", "lesson_08", "lesson_09", "lesson_10",
    "lesson_11", "lesson_12", "lesson_13",
    "reference",
]

KNOWN_TYPES = {"multiple_choice", "fill_blank", "word_order", "match",
               "translation", "flashcard"}


def load_module(name):
    import importlib.util
    path = CONTENT_DIR / f"{name}.py"
    if not path.exists():
        return None
    spec = importlib.util.spec_from_file_location(f"content_{name}", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.LESSON


def validate(name, data, all_ids):
    problems = []
    if data.get("sectionId") != name:
        problems.append(f"sectionId {data.get('sectionId')!r} != file name {name!r}")

    vocab_ids = set()
    vocab_by_id = {}
    for v in data.get("vocab", []):
        if not v.get("id") or not v.get("japanese") or not v.get("english"):
            problems.append(f"vocab missing id/japanese/english: {v!r}")
        if not v.get("source"):
            problems.append(f"vocab {v.get('id', '<missing id>')}: missing source page provenance")
        if v.get("id") in vocab_ids:
            problems.append(f"duplicate vocab id {v['id']}")
        vocab_ids.add(v.get("id"))
        vocab_by_id[v.get("id")] = v

    seen = set()
    for kind in ("exercises", "quiz"):
        for ex in data.get(kind, []):
            eid = ex.get("id", "<missing id>")
            if eid in seen:
                problems.append(f"duplicate exercise id {eid}")
            seen.add(eid)
            if eid in all_ids:
                problems.append(f"exercise id {eid} already used in another section")
            if ex.get("type") not in KNOWN_TYPES:
                problems.append(f"{eid}: unknown type {ex.get('type')!r}")
            if not ex.get("prompt") and ex.get("type") != "flashcard":
                problems.append(f"{eid}: empty prompt")
            if not ex.get("source"):
                problems.append(f"{eid}: missing source page provenance")
            t = ex.get("type")
            if t in ("multiple_choice",) or (t == "translation" and ex.get("direction") == "ja_to_en"):
                ch = ex.get("choices", [])
                ai = ex.get("answerIndex")
                if len(ch) < 2:
                    problems.append(f"{eid}: needs >=2 choices")
                if ai is None or not (0 <= ai < len(ch)):
                    problems.append(f"{eid}: answerIndex {ai} out of range")
            if t == "translation":
                if ex.get("direction") not in ("ja_to_en", "en_to_ja"):
                    problems.append(f"{eid}: bad direction")
                if ex.get("direction") == "en_to_ja" and not ex.get("accepted"):
                    problems.append(f"{eid}: en_to_ja needs accepted")
            if t == "fill_blank":
                if not ex.get("accepted"):
                    problems.append(f"{eid}: fill_blank needs accepted")
                if "___" not in (ex.get("prompt") or ""):
                    problems.append(f"{eid}: fill_blank prompt needs ___")
            if t == "word_order" and len(ex.get("tokens", [])) < 2:
                problems.append(f"{eid}: word_order needs >=2 tokens")
            if t == "match":
                pairs = ex.get("pairs", [])
                if len(pairs) < 2:
                    problems.append(f"{eid}: match needs >=2 pairs")
                rights = [p.get("right") for p in pairs]
                if len(set(rights)) != len(rights):
                    problems.append(f"{eid}: duplicate right values")
            if not ex.get("verified", False) and kind == "quiz":
                problems.append(f"{eid}: unverified exercise in quiz")
            vid = ex.get("vocabId")
            if vid and vid not in vocab_ids:
                problems.append(f"{eid}: vocabId {vid!r} not in this lesson's vocab")
            elif kind == "quiz" and vid and not vocab_by_id[vid].get("verified", True):
                problems.append(f"{eid}: quiz references unverified vocab {vid!r}")
    if name.startswith("lesson_") and not data.get("quiz"):
        problems.append("lesson has no quiz")
    if name == "reference" and (data.get("exercises") or data.get("quiz")):
        problems.append("reference must be browse-only; scored exercises and quizzes are forbidden")
    return problems


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    listing = "--list" in sys.argv
    if listing:
        print("\n".join(SECTIONS))
        return 0
    targets = args or SECTIONS

    ASSET_DIR.mkdir(parents=True, exist_ok=True)
    all_ids = set()
    # Pre-scan all sections for global ID uniqueness.
    loaded = {}
    missing = []
    for name in SECTIONS:
        data = load_module(name)
        if data is None:
            missing.append(name)
            continue
        loaded[name] = data
        for kind in ("exercises", "quiz"):
            for ex in data.get(kind, []):
                eid = ex.get("id")
                if eid:
                    if eid in all_ids:
                        print(f"GLOBAL DUPLICATE exercise id: {eid}")
                        return 1
                    all_ids.add(eid)

    # Every section in SECTIONS is required: curriculum.json points at its
    # asset, so a missing module would leave a dangling index entry. Fail
    # loudly instead of reporting success while silently skipping it.
    if missing:
        print("ERROR: missing required section modules (registered in SECTIONS):")
        for name in missing:
            print(f"   - tools/content_builder/{name}.py")
        return 1

    failures = 0
    for name in targets:
        data = loaded.get(name) or load_module(name)
        if data is None:
            if name in SECTIONS:
                print(f"[FAIL] {name}: module file disappeared during build")
            else:
                print(f"[FAIL] {name}: not a registered section (see SECTIONS / --list)")
            failures += 1
            continue
        own_ids = {ex.get("id") for kind in ("exercises", "quiz") for ex in data.get(kind, []) if ex.get("id")}
        problems = validate(name, data, all_ids - own_ids)
        if problems:
            failures += 1
            print(f"[FAIL] {name}:")
            for p in problems:
                print(f"   - {p}")
            continue
        out = ASSET_DIR / f"{name}.json"
        out.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding="utf-8")
        n_ex = len(data.get("exercises", []))
        n_q = len(data.get("quiz", []))
        n_v = len(data.get("vocab", []))
        print(f"[ok] {name}: {n_v} vocab, {n_ex} exercises, {n_q} quiz -> {out.name}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
