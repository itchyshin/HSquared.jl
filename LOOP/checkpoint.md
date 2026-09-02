GOAL: see LOOP/GOAL.md.   STATE: **Block 1 — B3/B5 proceed-with-conditions; A20 live-Julia skips exhausted; A19 hygiene landed (no Registrator); Rose pre-public scrub CLEAR-WITH-CHANGES (no false claim). Pass 3 (2026-09-01 late) cleared the scrub's *after-push* residue while push itself stays gated: the matrix-free fence is now PINNED IN CI (the "owed pin" from JL-1), B3 C2 is closed as a DOCUMENTED Julia-only sire boundary, and the Julia README's JL-2/JL-3 understatements are corrected. **Rose re-scrubbed all three pass-3 surfaces (2026-09-02): CLEAR-WITH-CHANGES, no false claim, no patch — and re-ran every one of pass 3's check claims rather than accepting them (all reproduced exactly).** Nothing promoted anywhere — rows 56, covered 13, `public_covered_count` 5, unchanged. The `Co-authored-by` trailer remains the one pre-push owner ASK — **recount it, do not read a ratio here** (command in GATED; the commit that records a count also increments it).**

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
- **PASS 3 — matrix-free fence PINNED (Julia)** `713edcf7`. New testset `V1-MATFREE-REML opt-in fence`,
  20 deterministic assertions: `fit_animal_model` refuses `:matrix_free`/`:matrix_free_reml`/
  `:matrix_free_mc_em_reml`/`:auto` (Symbol **and** String); the accepted target surface is pinned
  CLOSED at 4 canonical targets so a silent *widening* also goes red; `_auto_reml_route` asserted
  ABSENT; and no `src/` module beyond definition/export/ledger names the fitter, so wiring a call in
  fails loudly. **The v0.7 fence tests could NOT be ported** — v0.7 *accepted* `target = :matrix_free`,
  so its assertions are false here and porting would have re-widened the surface; the debt is
  discharged in this branch's API shape and the testset says so. **SCOPE — the wide claim is FALSE:**
  `fit_multi_effect(:auto)` is a *different* estimator (`V3-NEFFECT-MATFREE-FIT`) and DOES route
  matrix-free, so "`:auto` never selects matrix-free" holds only for the animal-model target router.
  No stochastic assertion added to CI (one EM step, tags only) — the 2026-08-04 RNG-fragility lesson
  is not re-broken. Four surfaces that said "no test pins that" updated + status page regenerated.
  Record: `check-log.d/2026-09-01-h2-twin-matfree-fence-pin.md`.
- **PASS 3 — sire Julia-only boundary DOCUMENTED (both lanes) → B3 C2 closed in note form.**
  Julia `9fb1cf85` · R `c05ddab`.
  R lane: new `docs/dev-log/comparator-runs/2026-09-01-sire-julia-only-boundary.md` + TOML boundary.
  Julia lane: `comparator/README.md` subsection, a `boundary_note` field carried into
  `manifest.json`, matching TOML text. **`gap` verdict KEPT and `--strict` still fails** — documenting
  a boundary is not discharging a debt. Measured on the way: `test-mrode-sire-anchor.R` is a
  *supplied-variance* anchor and therefore NOT this mirror, which is easy to misread from file names.
- **PASS 3 — Julia README understatement fixed (Rose JL-2/JL-3)** `9fb1cf85`. Premise verified first
  (`V5-MARKER-THRESHOLD` really is `covered`; the three `genome_wide_*` functions really are
  exported). Genome-wide calibration no longer listed flatly as planned: one paragraph states the
  covered scope (fixed-effect single-marker, exact per-dataset add-one rule, **type-I control only**,
  n∈300–2000 / m∈100–10000, 0.0542/0.0504 at α=0.05, PLINK 1.9 leg) and, at equal length, the
  fenced-out set. `pedigree_inverse`'s "not yet connected to a fitted animal model" replaced.
  Two drafting errors caught before commit: `fit_ai_reml` is covered but **not** the default target,
  and the throwing `hsquared()` is this package's placeholder, not the R twin's.
  Record: `check-log.d/2026-09-01-h2-twin-sire-boundary-and-readme-honesty.md`.

BATCH PARTIAL:
- **B2** — A09 G10 dossiers updated; **owner sign** (S3: S5 PASS, S6/S4/S7 open)
- **B3** — A10/A11/A12 done; A13 **impl** done; barrier **PROCEED WITH CONDITIONS**
  (`~/local-scratch/h2-b3-barrier-packet.md`); **C2 CLOSED in note form (pass 3)** — sire boundary
  documented; **still not done — Darwin sign (C1)**, so B3 stays partial regardless
- **B5** — A17 + A18 done; barrier **PROCEED WITH CONDITIONS**
  (`~/local-scratch/h2-b5-barrier-packet.md`); C1 post-merge Pages/Documenter open;
  C2 Pat script drafted `~/local-scratch/h2-b5-pat-reader-walk.md` (**not walked/signed**)
- **B6** — A19 hygiene green locally; A20 skips done; Version/win-builder/submit + Registrator remain

A21 CONDITIONS CLOSED (2026-09-02, R lane, Boole):
- A21's **HOLD WITH CONDITIONS** is discharged. The two verified false public statements
  (`rr(t, k = 2)`, which the parser refuses; and crediting `heritability()` with the h²(t)
  curve, which `rr_heritability()` actually returns) are gone from every claim surface —
  including a **third** surface the panel did not list, `R/formula-status.R`, which
  `formula_status()` prints to users. C3 was taken as a message-only RR branch on
  `heritability()` that names `rr_heritability()` instead of the generic "planned v0.1
  contract" miss, following the existing `hs_block_multivariate_response_scale()` precedent.
- R commit `1a00045` — **NOT pushed**; branch 20 ahead of `origin/main`.
  `check()` **0e/0w/0n** (better than the panel's 0e/0w/1N); `test()` 2336 pass / 0 fail / 70
  pre-existing skips. Receipt `~/local-scratch/h2-a21-fix-receipt.md`; shard
  `check-log.d/2026-09-02-h2-a21-rr-grammar-and-accessor-honesty.md` (R lane).
- **Releasable surface is now closer to PROCEED; the remaining gate is the owner's push
  decision (DP-1), which was never an agent condition.** Still held: no covered flip, no
  `validation_status()` row for RR k=2 / direct-maternal, `public_covered_count` stays 5.
- **Deferred deliberately:** C4 (`make_dm_fit` sets `r_am = -0.4` while its own components
  imply `-0.4714`) — a fixture defect, not a false public claim, and fixing it means
  choosing which value is canonical, so it is an owner call for post-0.5. C5–C9 post-push.

PROCESS (lessons):
- **Launch receipt required** before any Totoro gate >30m — prevents triple-run collision (Ada pass 1).
- **`air format .` is not a safe blanket command here.** It rewrites pre-air manual alignment
  across ~22 files, including the direct-maternal block A21 §1.1 signed off as correct.
  Format the files the slice touches, verify the slice's own new lines are clean, and revert
  the rest — a prose-honesty commit must not become a package-wide diff (A21 C1–C3).
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
- ~~**B3 C2** — sire_model R mirror **or** Julia-only boundary note~~ **note COMMITTED (pass 3)**;
  the mirror-vs-permanent decision moves to GATED (ask `#sire-mirror`)
- **A24-preview DONE (not pushed)** — MV-4 claim-surface honesty: R `8ed0837`/`14f5a7b`/`a13595d`;
  Julia GOAL reframe `a7852138`. Multivariate default-reachable / claim still `partial`;
  `public_covered_count` 5. Residual `validation_status()` key `(opt-in)` → **A28** (do not rename).
  Receipt `~/local-scratch/h2-a24-mv4-doc-honesty-receipt.md`.
- **A28-part1 DONE (not pushed)** — the `(opt-in)` key is **ALIASED, not renamed**: R
  `22cb5cd`/`90adf27`/`d5df60b`, no Julia commits. `validation_status()` gains `capability_label`;
  the id stays because **three dated records cite it verbatim**. `public_covered_count` 5.
- **A28-remainder DONE (not pushed)** — doc-38 §H.3 discharged by MV-1; `k≥3` parseable-but-
  experimental and `diagonal` experimental fences pinned on `validation_status()` /
  `formula_status()` + contract tests. R `e822db3`. No covered flip.
- **A26b DONE (not pushed)** — MV-1 Suggests harden: `hs_require_suggests("sommer")` fails
  loudly under `NOT_CRAN=true`; CRAN still skips. R `d59d98e`. Helper unit tests + multivariate
  suite green (2 expected live-Julia skips).
- **A25a DONE (not pushed)** — C8 register reconcile (compute-free cite only). Julia tip
  `11f54d9e` + R `0c0ae4a`. Banked confirm now cited on claim surfaces: DRAC `47925486`,
  16 cells × 500 seeds, 500/500 convergence every cell, **14/16 pass** (fails only
  `rg_090_rec1`, `rg_095_rec1`); W1 (8×50, 5/8) retained as triage. **Fence verified / unchanged:**
  Julia `V4-MV-REML` **covered**; R multivariate **partial**; `public_covered_count` **5**.
  No covered flip, no Totoro/DRAC, no push. Scratch: `~/local-scratch/h2-a25a-LOOP.md`;
  briefing §13–§14.
- **LABEL COLLISION (read before trusting "A25 done")** — The Rose multivariate claim-surface
  audit was **A29-shaped work mislabeled A25** (R `469ab94`, Julia `b24f7f88`). Spine
  **A25 = MV-5 disposition remains OPEN**. Disposition draft (options only, no run):
  `~/local-scratch/h2-a25-mv5-disposition-draft.md`.
- **A25-grace DONE (not pushed)** — Regenerated `docs/src/validation-status.md` from live
  `validation_status()` so the Documenter page cites C8 (`47925486`, **14/16**) alongside W1;
  CI now requires claim_boundary prose sync (Rose F3 / inventory T2 closed). Check-log
  `check-log.d/2026-09-02-h2-a25-grace-validation-status-regen.md`. Launch:
  `~/local-scratch/h2-a25-docregen-launch.md`.
- **A26 DONE (not pushed)** — R↔engine element-wise k=2 multivariate parity. R
  `0ec917f`/`37843d8`/`74ba7d6`/`806f7a7`. Declared-before / measured-after margins:
  start-matched **1.7e-14** (tol 1e-8); bridge `I₂` start **2.0e-5** (tol 5e-4);
  pedigree-permutation **1.7e-14** (tol 1e-6). Live 44 PASS / 0 FAIL; CRAN 6 PASS / 2 SKIP.
  **Fence held:** R multivariate **partial**; Julia `V4-MV-REML` covered; `public_covered_count` **5**.
  Receipt `~/local-scratch/h2-a26-receipt.md`; briefing §17; scratch LOOP `~/local-scratch/h2-a26-LOOP.md`.
- **A26-grace DONE (not pushed)** — JuliaCall 0.17.6 NA-matrix segfault workaround (pre-existing;
  blocked whole-suite live runs). R `becfa5b`. Root cause: R `NA_real_` → Julia `Missing`;
  `julia_eval(sum(isnan.(…)))` segfaults in Rcpp precious-preserve. Workaround: explicit
  `hs_y_matrix_for_julia` NA→NaN before assign + safe Int count. Live `test-multivariate.R`
  FAIL 0 / SKIP 0; A26 parity still green; CRAN path unchanged. Check-log
  `check-log.d/2026-09-02-h2-a26-juliacall-na-segfault.md`.
- **Owner asks (open, do not quietly fix)** — (1) Bridge multivariate start: shipped `I₂` vs
  engine `0.5·phenotypic-variance` (identity costs ~2e-5 on G0, inside tol). (2) **DP-1** push.
- **Post-0.5 spine (do NOT arm Block 2)** — MV-4 routing already merged; remaining 0.6 work is
  evidence assembly. Outline: `~/local-scratch/h2-post-050-spine-mv4-s6.md` (**scratch,
  not a plan of record**); gate-level inventory with SHAs:
  `~/local-scratch/h2-060-evidence-inventory.md` (C8-uncited + A26b silent-skip + A26 parity
  findings discharged; T2 page-staleness closed by A25-grace; JuliaCall segfault closed by A26-grace).
  `LOOP/GOAL.md` still gates everything behind the Block 1 release gate.
  **Next:** true A25 (MV-5 disposition) · A27 Darwin · A29 Rose · A30 G10 · DP-1.

GATED (owner):
- G10 S1/S2/S3 sign · push (after pass 3: **R last content commit `c05ddab`, Julia `d3d92952`** — for
  live ahead counts run `git rev-list --count origin/main..HEAD` rather than trusting a number here,
  because a ledger commit that records the count also increments it —
  pass-3 commits `713edcf7`, `9fb1cf85`, `b597f811`, `d3d92952` — **neither pushed → CI still
  unverified, and every local check in this campaign remains local**) · A19 register · Version bump
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
  ~~**Still owed:** port the v0.7 fence tests so the fence is pinned, not merely true.~~
  **PIN DONE 2026-09-01 (pass 3)** — but NOT by porting; the v0.7 tests assert an API this branch
  does not have. See the pass-3 entry above. Still owed on the row: the v0.7 in-CI **numeric** gates,
  S6, S4, S7, and **S3 (G10) UNSIGNED**.
- **`Co-authored-by: Cursor` trailer — MEASURED, and wider than the scrub reported: Julia 31/33 AND
  R 18/18, i.e. 49 of 51 commits across both repos.** The scrub counted only the Julia lane ("29/30"),
  so the R lane's full sweep is new information; a rewrite is a two-repo job, not one. Against the
  `CLAUDE.md` no-trailer convention. **Auto-injected by the Cursor commit path** — no git hook and no
  `commit.template` (both checked, both empty) — so it cannot be avoided by wording messages
  differently from this surface. Owner's choice is genuinely accept-or-rewrite; the rewrite stays an
  ASK. Cheaper before push than after. **After pass 3: R 19/19, and every Julia campaign commit but
  2.** Recount with `git log origin/main..HEAD --format='%(trailers:key=Co-authored-by,valueonly)' |
  grep -c Cursor` rather than quoting a frozen ratio — pass 3 alone moved it three times.
- **Add `validation_status()` rows for RR k=2 + direct–maternal?** Both are `covered` in
  `docs/design/capability-status.md` but absent from the exported R table, so the generated limits page
  cannot card them. Public-claim-surface change → Boole (naming) + Rose (audit).
- **README merge conflict** with `origin/codex/2026-07-13-v07-performance-localization` (5 commits,
  same paragraphs, narrows genomic GREML to a held branch-only candidate). Not imported. D-87/D-88.
- **`sire_model_fitted_target` — boundary now DOCUMENTED (pass 3), decision still yours (ask
  `#sire-mirror`).** The gap is no longer silent: note committed in the R lane, both TOMLs and the
  comparator README point at it, and `manifest.json` carries a `boundary_note`. What is NOT decided is
  whether to (a) mirror + freeze the fixture or (b) make the Julia-only boundary permanent — the note
  argues both sides and settles neither. Harness still reports `gap`; `--strict` still fails; the
  same-estimand REML sire comparator is untouched by either choice.
- **Open question:** pin Julia version in frozen S5 gate pre-run? (records but doesn't assert today)

TRUTH: B3 barrier `~/local-scratch/h2-b3-barrier-packet.md` · B5 `~/local-scratch/h2-b5-barrier-packet.md` · A20 addendum `~/local-scratch/h2-a20-skip-migration-addendum.md` · A18 `~/local-scratch/h2-a18-launch-receipt.md` · Rose pre-public scrub **CLEAR-WITH-CHANGES** `~/local-scratch/h2-rose-prepublic-scrub-2026-09-01.md` · Rose pass-3 re-scrub **CLEAR-WITH-CHANGES** `~/local-scratch/h2-rose-rescrub-pass3-2026-09-02.md` · briefing (§7 is the current section) `~/local-scratch/h2-morning-briefing-2026-09-02.md` · pass-3 receipt `~/local-scratch/h2-overnight-pass3-launch-receipt.md` · post-0.5 spine stub (NOT authorized work) `~/local-scratch/h2-post-050-spine-mv4-s6.md`

~~PASS 3 CAVEAT: the new Julia README paragraph is a claim surface Rose has not read; a re-scrub is
owed before push.~~ **RE-SCRUB DONE 2026-09-02 — CLEAR-WITH-CHANGES**, no false claim, no patch
needed (`~/local-scratch/h2-rose-rescrub-pass3-2026-09-02.md`). All three pass-3 surfaces clear: the
README genome-wide paragraph is a clause-by-clause transcription of `V5-MARKER-THRESHOLD` (every
figure, all five fenced-out items); the fence testset's scope is honest and narrower than the tidy
untruth; the sire boundary does **not** repeat JL-1's dangling pointer — the cited R note exists and
every factual claim in it verified (`r_mirror = false`, zero bytes frozen, 9 fixture files,
`V1-SIRE-FIT` still `partial`, no R fixtures invented). Rose **re-ran** all five of pass 3's check
claims rather than accepting them: suite 143/4252/0 exact match, fence testset 20/20 in-suite,
harness exit 0 (6 agree / 0 drift / 1 not mirrored), `--strict` **exit 1**, rows 56 / covered 13 /
partial 39 live; committed `manifest.json` reproduces byte-identically. THREE NEW LOW findings, none
a false claim, all post-push one-liners: **JL-6** two design points sit beside a design range in the
README (0.0542/0.0504 are the #207 REBUILD gate at (500,2000)+(1000,2000), not the whole n/m range —
inherited from the ledger's own compression); **JL-7** `public_covered_count` is set as code but is
not callable in either lane (authority is `docs/design/06-public-claims-register.md`); **JL-8** the
fence test's `src/` scan is non-recursive — exactly equivalent today (`src/` is flat, 24 files) but
it would under-cover its own wording if a `src/` subdirectory is ever added. Carried forward OPEN:
JL-2 partial (implemented-list omissions beyond genome-wide untouched), JL-4, JL-5, R-1, R-2, R-3.

RESUME: LOOP/GOAL.md → this file → arcs.md. **No S5 re-run.**
