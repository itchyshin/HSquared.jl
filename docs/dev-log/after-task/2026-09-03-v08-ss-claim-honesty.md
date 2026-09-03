# After-task — 0.8 SS claim-surface honesty (no flip)

Date: 2026-09-03. Lane: Julia engine (`HSquared.jl`). Branch:
`cursor/08-ss-honesty-20260903`. Type: honesty rewrite (no campaign, no
flip).

```
PLATFORM: cursor | LANE: cursor/08-ss-honesty-20260903
OTHER LANES: Codex DRAFT #137/#274 cite-only · Dropbox FOREIGN ·
             R #164 cite-only (broad catch-up, not this slice)
Active lenses: Rose (this honesty) · Ada/Shannon fence
Spawned subagents: none
Current lane: Julia SS claim-surface honesty only
```

## Goal

Remove the stale `V2-SSHINV` field-7 clause that still said “no
external-comparator” after #295 AGHmatrix construction AGREE and
hsquared #167 Hinv-cell R↔engine parity landed. Name that evidence as
**existing**. Do not flip field-4. Do not claim n≫6 recovery is
external-comparator-complete. Do not claim 0.8.0.

## What landed

- `src/validation_status.jl` `V2-SSHINV` fields 5–7 (field-4 stays
  **partial**).
- `docs/src/validation-status.md` missing-column sync.
- `docs/design/capability-status.md` Single-step row.
- `docs/design/validation-debt-register.md` `V2-SSHINV`.
- Board one-liner + this report + matching `check-log.d` entry.

## Public claim audit

Allowed: “ordinary-default Hinv construction has AGHmatrix::Hmatrix
AGREE (#295) and Hinv-cell R↔engine parity (#167); n≫6 recovery is
known-truth H-scale σ²a / σ²e; `V2-SSHINV` stays partial; count stays
7.”
Blocked: covered flip; covered single-step prediction; n≫6 as
external-comparator-complete REML/fit; 0.8.0; 1.0 / CRAN; count 8.

## Checks this slice

Honesty rewrite of status text. Local pin: `public_covered_count` **7**,
`Project.toml` **0.7.0**, `V2-SSHINV` field-4 **partial**. Full
`Pkg.test()` / Documenter deferred to CI (status-string change only).

## Tests of the tests

Did not re-run AGHmatrix n=6 or n=240. Re-read banked numbers:
`max|Hinv Δ| = 4.24e-12` (`0b03d67e`); 48/48 (`0533e9da`).

## Coordination notes

Lease on the named status files. Twin R slice
`cursor/08-ss-honesty-r-20260903` rewrites the matching capability
sentence. Independent of R #164.

## Known limitations

preGSf90 / BLUPF90 fit parity still absent. Mrode Ch.11 H/H⁻¹ still
absent. Metafounder `H^Γ` / APY / non-default knobs still owed. h²
stays reported-not-gated.

## Next

Fresh SS Rose packet on the post-merge tip. FA already CLEAN, waiting
owner `G10 FA`. No flip runner.
