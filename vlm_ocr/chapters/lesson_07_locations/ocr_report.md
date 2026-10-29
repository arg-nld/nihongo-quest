# Gemini VLM Extraction Report

- Generated (UTC): 2026-10-22T05:48:49+00:00
- Pages in manifest: 18
- Pages OK: 18
- Pages empty: 0 -> []
- Pages errored: 0 -> []
- Total recognized characters: 12,319
- Total recognized lines: 592

## Output files

- Manifest: `ocr_manifest.csv`
- Errors: `ocr_errors.csv`
- Text: `pages/page_NNNN.txt`
- Per-page details (incl. raw model response): `pages/page_NNNN.json`

## How to review

1. Spot-check pages against the source images in `img/`.
2. The book mixes romaji with small inline kana (`Wataし`, `Ha い,`).
   Confirm the kana survived - that is the metric this pipeline exists for.
3. Compare against `docs/paddle_ocr_test/` for the same page number.
4. `raw_batch_response` in each JSON holds the model's unedited reply for the
   whole batch, so a mis-split can be re-parsed without a new API call.

## Re-run

```powershell
python scripts/ocr_book_gemini.py --redo 47,48
python scripts/ocr_book_gemini.py --report-only
```
