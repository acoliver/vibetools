# Retained OpenCodeReview session excerpts

Only minimal corroborating metadata is retained. Full JSONL histories may contain unrelated repository content and were not copied.

## S1 — local PR-2462 finding corroboration

- Original path (home normalized): `$HOME/.opencodereview/sessions/Users-acoliver-projects-llxprt-branch-1-llxprt-code/216fc204-dbc1-4ac7-9bb7-307a7f4fb579.jsonl`
- SHA-256: `d57f86800dbacaf0cdd6faa8c8ca1467545d4b9b1b356fa0386c71f1eed93470`
- Observed mtime/size: `2026-07-12T11:28:18Z` / `2,598,416` bytes
- Extraction: exact-phrase search for “server name or URL contains a null character”; no unrelated JSONL events retained.
- Provenance: phrase match ties the session to L1's first finding. It does not establish the reviewed Git SHA/range or config equivalence.

## S2 — unrelated llxprt prefix in the composite mounted log

- Original path (home normalized): `$HOME/.opencodereview/sessions/Volumes-XS1000-acoliver-projects-llxprt-branch-9-llxprt-code/cac77643-9472-4aaa-8415-fc73ec875a3f.jsonl`
- SHA-256: `12fe5090e10a4da73156305ffbe7573693905698b06ed028ec144075a7d0ce0c`
- Observed mtime/size: `2026-07-12T14:18:08Z` / `1,697,290` bytes
- Extraction: exact-phrase search for “The removed 'Message Queuing' tests”; no unrelated events retained.
- Provenance: corroborates that the JSON prefix in the mounted Jefe `ocr_review.log` came from a separate llxprt-code session. That prefix was excluded from L3.

## S3 — Jefe mounted-log text corroboration

- Original path (home normalized): `$HOME/.opencodereview/sessions/Volumes-XS1000-acoliver-projects-jefe-branch-1/82ba0c9f-73e4-419a-9ec4-17b404c214bb.jsonl`
- SHA-256: `214bd782f011b21e12fa22c1693c7c934b8725b90317482781235eaade2b5348`
- Observed mtime/size: `2026-07-12T14:18:05Z` / `18,400,390` bytes
- Extraction: exact-phrase search for “After switching repositories, this test previously asserted”; no unrelated events retained.
- Provenance: phrase match ties the Jefe text portion of L3 to an OCR session. It does not establish that L3 is the exact CI run posted to PR #236.

## Reproduction

```sh
rg -l -F 'server name or URL contains a null character' "$HOME/.opencodereview/sessions"
rg -l -F "The removed 'Message Queuing' tests covered critical behavioral guarantees" "$HOME/.opencodereview/sessions"
rg -l -F 'After switching repositories, this test previously asserted' "$HOME/.opencodereview/sessions"
shasum -a 256 PATH
```
