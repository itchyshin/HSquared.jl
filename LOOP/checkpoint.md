GOAL: see LOOP/GOAL.md.   STATE: **Block 1 — B2/B4 milestones; B3 all-impl-done; B5 A17+A18 landed (local).**

ARCS DONE (verified):
- A01–A06 (B1) — A06 **Totoro close-out** `73a4db0b` (4053 assertions, 0 fail)
- **A07/A08 (B2)** — S5 **PASS** q=25k; adjudication `~/local-scratch/h2-a07-s5-run-adjudication.md`; **do not re-run**
- A10, **A11**, A12 (B3); A14–A16 + B4 barrier PROCEED (R)
- A15 re-verified live R `6a9fa07`
- **A11 (Julia)** — harness now does fixture integrity + SHA-256 digests + cross-lane byte parity
  vs the R lane freeze (**6 agree, 0 drift, 1 not mirrored**); `Pkg.test()` 37/37, full suite green
- **A17 phase 3 (R)** `9ac11d1` — capability ledger GENERATED from `validation_status()` with a
  drift guard; README validate-first + D-41 badge/callout; reference index split
- **R CMD check GREEN** `e7ca2fd` — 5 A13/A16 test failures were tarball-path failures that
  `devtools::test()` could never see; 1 ERROR → **0 errors, 0 warnings, 1 NOTE** (`.git`, worktree artifact)
- **A18 (BOTH)** — R pkgdown build/deploy split + hide internals; Julia Documenter `push: main`,
  `warnonly = [:missing_docs]`, job-shaped sidebar, generated validation-status table (55 rows).
  Receipts: `~/local-scratch/h2-a18-launch-receipt.md`; check-log.d shards both lanes.

BATCH PARTIAL:
- **B2** — A09 G10 dossiers updated; **owner sign** (S3: S5 PASS, S6/S4/S7 open)
- **B3** — A10/A11/A12 done; **A13** manifest R `02d0a31` + Julia `374b79aa`; **Darwin review pending** = only open item
- **B5** — A17 + A18 **implementation done locally**; Pat/Darwin/Florence reader pass + first
  post-merge Pages/Documenter deploy still open (no push this pass)
- **B6 prep** — A19 checklist

PROCESS (lessons):
- **Launch receipt required** before any Totoro gate >30m — prevents triple-run collision (Ada pass 1).
- **`devtools::test()` green is NOT `check()` green.** Source-tree tests that read `.Rbuildignore`d
  paths (`docs/`) pass under `test()` and fail under `check()`. Guard them (pass 2, A13/A16).
- **Hand-maintained Documenter status tables drift.** A18 generator recovered missing rows
  (e.g. `V1-SIRE-FIT`) that the old table omitted.

ARC NEXT (one owner each):
- **A13 Darwin review** — 8-item checklist in manifest stub (gryphon h², Wilson citation, teaching vs field)
- **A20** — hsquared 0.5.0 CRAN local gate (`cran-comments.md`, `hs_skip_live_julia()`, `inst/CITATION`, `.git` NOTE)
- **B5 barrier** — Pat + Darwin + Florence on reader IA; Grace/Karpinski on first green CI deploy after push

GATED (owner):
- G10 S1/S2/S3 sign · push (R ahead ~14, Julia ahead ~27 after A18, **CI unverified**) · A19 register
- **Add `validation_status()` rows for RR k=2 + direct–maternal?** Both are `covered` in
  `docs/design/capability-status.md` but absent from the exported R table, so the generated limits page
  cannot card them. Public-claim-surface change → Boole (naming) + Rose (audit).
- **README merge conflict** with `origin/codex/2026-07-13-v07-performance-localization` (5 commits,
  same paragraphs, narrows genomic GREML to a held branch-only candidate). Not imported. D-87/D-88.
- **`sire_model_fitted_target` not mirrored to R** — mirror + freeze, or record it as Julia-only.
- **Open question:** pin Julia version in frozen S5 gate pre-run? (records but doesn't assert today)

TRUTH: Ada pass 2 `~/local-scratch/h2-overnight-pass2-receipt.md` · A18
`~/local-scratch/h2-a18-launch-receipt.md` · pass 1 `~/local-scratch/h2-ada-overnight-pass-1-receipt.md`

RESUME: LOOP/GOAL.md → this file → arcs.md. **No S5 re-run.**
