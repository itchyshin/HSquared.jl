GOAL: see LOOP/GOAL.md.   STATE: **Block 1 — B3/B5 proceed-with-conditions; A20 live-Julia skips exhausted; A19 hygiene landed (no Registrator); Rose pre-public scrub CLEAR-WITH-CHANGES (no false claim); its higher pre-push item JL-1 is now CLOSED (`69280b70`, `V1-MATFREE-REML` ledger home; nothing promoted, `public_covered_count` still 5), leaving the `Co-authored-by` trailer as the one pre-push owner ASK — see GATED.**

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
- **A20 skip migration (R)** wave1 `26bc005` (33) + leftovers (26 + 2 missing gates) —
  live-Julia bare `skip_on_cran` exhausted except intentional non-Julia legs; scoped leftovers
  FAIL 0 / PASS 704. Addendum: `~/local-scratch/h2-a20-skip-migration-addendum.md`.
- **A19 hygiene (Julia)** — `test_aqua.jl` + TagBot.yml + `CITATION.cff` + extras compat;
  Aqua **10/10**; removed undefined export `fit_eigen_reml`. **No** Registrator / **no** 0.5.0 bump.

BATCH PARTIAL:
- **B2** — A09 G10 dossiers updated; **owner sign** (S3: S5 PASS, S6/S4/S7 open)
- **B3** — A10/A11/A12 done; A13 **impl** done; barrier **PROCEED WITH CONDITIONS**
  (`~/local-scratch/h2-b3-barrier-packet.md`); **not done** — Darwin sign (C1) + sire Julia-only (C2)
- **B5** — A17 + A18 done; barrier **PROCEED WITH CONDITIONS**
  (`~/local-scratch/h2-b5-barrier-packet.md`); C1 post-merge Pages/Documenter open;
  C2 Pat script drafted `~/local-scratch/h2-b5-pat-reader-walk.md` (**not walked/signed**)
- **B6** — A19 hygiene green locally; A20 skips done; Version/win-builder/submit + Registrator remain

PROCESS (lessons):
- **Launch receipt required** before any Totoro gate >30m — prevents triple-run collision (Ada pass 1).
- **`devtools::test()` green is NOT `check()` green.** Source-tree tests that read `.Rbuildignore`d
  paths (`docs/`) pass under `test()` and fail under `check()`. Guard them (pass 2, A13/A16).
- **Hand-maintained Documenter status tables drift.** A18 generator recovered missing rows
  (e.g. `V1-SIRE-FIT`) that the old table omitted.
- **Bare `skip_on_cran` ≠ CRAN-safe for JuliaCall.** Ligges-class hang risk → `hs_skip_live_julia()`.

ARC NEXT (one owner each):
- **A13 Darwin review** — draft answers in `~/local-scratch/h2-a13-darwin-review-draft.md`; **sign still pending**
- **A20 remaining** — optional testthat.R allowlist; Version 0.5.0; win-builder; submit after Julia General
- **A19 remaining** — DOCUMENTER_KEY verify; Documenter install honesty; owner OK → 0.5.0 + Registrator
- **B5 C1/C2** — owner push → first green Pages/Documenter; human Pat walk of drafted script
- **B3 C2** — sire_model R mirror **or** Julia-only boundary note

GATED (owner):
- G10 S1/S2/S3 sign · push (R ahead 18 `765b209`, Julia ahead 33 — head is this LOOP commit, ledger home `69280b70` — **neither pushed → CI
  unverified**) · A19 register · Version bump
- ~~**`V1-MATFREE-REML` row does not exist**~~ **CLOSED 2026-09-01, `69280b70`** (Rose JL-1). It was a
  **port gap**, not a missing id: the row already existed on the v0.7 lineage (`33ab68f6`), and A07's
  `f261165e` ported `fit_matrix_free_reml` (body byte-identical) without the rows that came with it.
  Rows now ported to `src/validation_status.jl`, `docs/design/capability-status.md`, and
  `docs/design/validation-debt-register.md` at `partial`/`experimental` — **nothing promoted**: rows
  55→56, partial 38→39, covered 13 unchanged, `public_covered_count` **5** unchanged (verified from the
  regenerated cache). The v0.7 wording was NOT copied verbatim — its in-CI testset and `:auto` fence
  tests were never ported, so the new row says so. Fence verified to hold **structurally** instead:
  `_auto_reml_route` absent, `fit_animal_model` rejects `:matrix_free`/`:matrix_free_reml`/`:auto`.
  Full suite green. Record: `check-log.d/2026-09-01-h2-twin-matfree-ledger-home.md`.
  **Still owed:** port the v0.7 fence tests so the fence is pinned, not merely true.
- **`Co-authored-by: Cursor` trailer — MEASURED, and wider than the scrub reported: Julia 31/33 AND
  R 18/18, i.e. 49 of 51 commits across both repos.** The scrub counted only the Julia lane ("29/30"),
  so the R lane's full sweep is new information; a rewrite is a two-repo job, not one. Against the
  `CLAUDE.md` no-trailer convention. **Auto-injected by the Cursor commit path** — no git hook and no
  `commit.template` (both checked, both empty) — so it cannot be avoided by wording messages
  differently from this surface. Owner's choice is genuinely accept-or-rewrite; the rewrite stays an
  ASK. Cheaper before push than after.
- **Add `validation_status()` rows for RR k=2 + direct–maternal?** Both are `covered` in
  `docs/design/capability-status.md` but absent from the exported R table, so the generated limits page
  cannot card them. Public-claim-surface change → Boole (naming) + Rose (audit).
- **README merge conflict** with `origin/codex/2026-07-13-v07-performance-localization` (5 commits,
  same paragraphs, narrows genomic GREML to a held branch-only candidate). Not imported. D-87/D-88.
- **`sire_model_fitted_target` not mirrored to R** — mirror + freeze, or record it as Julia-only.
- **Open question:** pin Julia version in frozen S5 gate pre-run? (records but doesn't assert today)

TRUTH: B3 barrier `~/local-scratch/h2-b3-barrier-packet.md` · B5 `~/local-scratch/h2-b5-barrier-packet.md` · A20 addendum `~/local-scratch/h2-a20-skip-migration-addendum.md` · A18 `~/local-scratch/h2-a18-launch-receipt.md` · Rose pre-public scrub **CLEAR-WITH-CHANGES** `~/local-scratch/h2-rose-prepublic-scrub-2026-09-01.md` · briefing `~/local-scratch/h2-morning-briefing-2026-09-02.md`

RESUME: LOOP/GOAL.md → this file → arcs.md. **No S5 re-run.**
