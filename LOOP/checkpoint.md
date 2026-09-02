GOAL: see LOOP/GOAL.md.   STATE: **Block 1 — B3 barrier PROCEED WITH CONDITIONS (batch still partial); B5 same; A20 skip migration advanced.**

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
- **A20 skip migration (R)** `26bc005` — 33 live-Julia gates → `hs_skip_live_julia()` (bridge,
  single-step, plot-parity, genomic, SNP-BLUP, MV live); scoped tests FAIL 0 / PASS 333.
  Addendum: `~/local-scratch/h2-a20-skip-migration-addendum.md`.

BATCH PARTIAL:
- **B2** — A09 G10 dossiers updated; **owner sign** (S3: S5 PASS, S6/S4/S7 open)
- **B3** — A10/A11/A12 done; A13 **impl** done; barrier **PROCEED WITH CONDITIONS**
  (`~/local-scratch/h2-b3-barrier-packet.md`); **not done** — Darwin sign (C1) + sire Julia-only (C2)
- **B5** — A17 + A18 done; barrier **PROCEED WITH CONDITIONS**
  (`~/local-scratch/h2-b5-barrier-packet.md`); C1 post-merge Pages/Documenter open;
  C2 Pat script drafted `~/local-scratch/h2-b5-pat-reader-walk.md` (**not walked/signed**)
- **B6** — A19 checklist; **A20** still **doing** — listed live suites migrated; other bare
  `skip_on_cran` suites + Version/win-builder/submit remain

PROCESS (lessons):
- **Launch receipt required** before any Totoro gate >30m — prevents triple-run collision (Ada pass 1).
- **`devtools::test()` green is NOT `check()` green.** Source-tree tests that read `.Rbuildignore`d
  paths (`docs/`) pass under `test()` and fail under `check()`. Guard them (pass 2, A13/A16).
- **Hand-maintained Documenter status tables drift.** A18 generator recovered missing rows
  (e.g. `V1-SIRE-FIT`) that the old table omitted.
- **Bare `skip_on_cran` ≠ CRAN-safe for JuliaCall.** Ligges-class hang risk → `hs_skip_live_julia()`.

ARC NEXT (one owner each):
- **A13 Darwin review** — draft answers in `~/local-scratch/h2-a13-darwin-review-draft.md`; **sign still pending**
- **A20 remaining** — other live-suite skip migration; optional testthat.R filter; Version 0.5.0;
  win-builder; submit only after Julia General
- **B5 C1/C2** — owner push → first green Pages/Documenter; human Pat walk of drafted script
- **B3 C2** — sire_model R mirror **or** Julia-only boundary note

GATED (owner):
- G10 S1/S2/S3 sign · push (R ahead ~16, Julia ahead ~28, **CI unverified**) · A19 register
- **Add `validation_status()` rows for RR k=2 + direct–maternal?** Both are `covered` in
  `docs/design/capability-status.md` but absent from the exported R table, so the generated limits page
  cannot card them. Public-claim-surface change → Boole (naming) + Rose (audit).
- **README merge conflict** with `origin/codex/2026-07-13-v07-performance-localization` (5 commits,
  same paragraphs, narrows genomic GREML to a held branch-only candidate). Not imported. D-87/D-88.
- **`sire_model_fitted_target` not mirrored to R** — mirror + freeze, or record it as Julia-only.
- **Open question:** pin Julia version in frozen S5 gate pre-run? (records but doesn't assert today)

TRUTH: B3 barrier `~/local-scratch/h2-b3-barrier-packet.md` · B5 `~/local-scratch/h2-b5-barrier-packet.md` · A20 addendum `~/local-scratch/h2-a20-skip-migration-addendum.md` · A18 `~/local-scratch/h2-a18-launch-receipt.md`

RESUME: LOOP/GOAL.md → this file → arcs.md. **No S5 re-run.**
