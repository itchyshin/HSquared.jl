# Arcs — H² twin Block 1 (A01–A23)

Status: `todo` · `doing` · `done` · `paused` · `blocked`  
Batch barriers: B0–B9 (ultra-plan §6).

| Arc | Batch | Name | Status | Gate? |
|-----|-------|------|--------|-------|
| A01 | B0 | Lane extraction — worktrees | done | — |
| A02 | B0 | v07 fog / base decision | done | — |
| A03 | B0 | Claim-surface sweep | done | — |
| A04 | B1 | Enumerate 5 covered rows (F2) | done | B1 |
| A05 | B1 | R↔Julia parity table (F3) | done | B1 |
| A06 | B1 | Test/runtime baseline | done | B1 + Totoro full suite `73a4db0b` |
| A07 | B2 | S5 tail-scale REML gate q=25k | done | **PASS** Totoro ~44m; receipt `h2-a07-s5-receipt.md` |
| A08 | B2 | CAP-EXHAUSTED ≤4/48 threshold (F4) | done | Q2 fixed pre-run |
| A09 | B2 | G10 S1/S2/S3 dossiers (no sign) | doing | dossiers updated post-S5; **owner sign** |
| A10 | B3 | BLUPF90 wire or document (F5) | done | R `2cc13d2` — doc path |
| A11 | B3 | Comparator harness 7 targets | done | Julia — integrity + digests + cross-lane parity; `Pkg.test()` 37/37; receipt `h2-a11-comparator-harness-receipt.md` |
| A12 | B3 | sommer/ASReml R fixtures | done | R `2d52a48` + Julia `cce9a961`; receipt `h2-a12-fixtures-receipt.md` |
| A13 | B3 | Real-data 3-tier manifest | doing | R `02d0a31` + Julia `374b79aa`; **Darwin review pending** (draft only; do not flip signed) |
| A14 | B4 | Bridge payload v2 contract | done | R `7193e9ad` phase 1; receipt `h2-b4-a14-receipt.md` |
| A15 | B4 | engine=julia smoke + F8 | done | R `07399a9` — receipt `h2-b4-a15-a16-receipt.md` |
| A16 | B4 | Bridge parity test → CI | done | R `3dbf486` phase 1 Tier 0 contracts |
| A17 | B5 | Docs IA rebuild both sites | done | R phases 1–3 `9ac11d1`; Julia sidebar regrouped in A18 |
| A18 | B5 | CI/deploy hygiene + status gen | done | R pkgdown split+hide; JL Documenter main-push + generated status table; **post-merge deploy unverified (no push)** |
| A19 | B6 | Julia General registry (F7) | doing | checklist + hygiene (Aqua/TagBot/CITATION); **ASK** before register / 0.5.0 bump |
| A20 | B6 | hsquared 0.5.0 CRAN local gate | doing | prep + skip migration wave1+leftovers; optional allowlist + Version/win-builder remain; `h2-a20-skip-migration-addendum.md` |
| A21 | B7 | Estimand + claim ceiling panel | done | Opus ceiling; panel `h2-a21-estimand-claim-panel-2026-09-02.md`; verdict was **HOLD WITH CONDITIONS** — **C1/C2/C3 now LANDED** (R `1a00045`), so A21 re-verdict is **PROCEED (owner push)**; receipt `h2-a21-fix-receipt.md` |
| A22 | B8 | unlazy reverify + Melissa reconcile | done | Melissa; audit `h2-block1-completion-audit-2026-09-02.md`; owner packet `h2-owner-decision-packet-2026-09-02.md` |
| A23 | B9 | D-43 completion panel | done | Option B **ADOPTED** — decision `docs/dev-log/decisions/2026-09-02-block1-check-log-substitution.md`; A21 receipt + A23 panel are the after-task records; standard after-task required from A24+ |

## Preview outside Block 1 numbering (not armed Block 2)

| Arc | Status | Note |
|-----|--------|------|
| **A24-preview** | **done (not pushed)** | MV-4 claim-surface honesty — R `8ed0837`/`14f5a7b`/`a13595d`; Julia `a7852138` (this GOAL reframe). Default-reachable / claim still `partial`; `public_covered_count` 5. Residual `(opt-in)` key → A28. Receipt `~/local-scratch/h2-a24-mv4-doc-honesty-receipt.md`. |
| **A28-part1** | **done (not pushed)** | Capability-id honesty — **ALIASED, not renamed**. R `22cb5cd`/`90adf27`/`d5df60b`; no Julia commits. `validation_status()` gains `capability_label`; the `(opt-in)` id stays because **three dated records cite it verbatim**. Also fixed a self-contradiction in the multivariate `claim_boundary`. Checks: test PASS 2348 / FAIL 0, `check()` 0/0/0. Decision `docs/dev-log/decisions.md` (2026-09-02); check-log `check-log.d/2026-09-02-h2-a28-capability-id-alias.md`. `public_covered_count` 5. |
| **A28-remainder** | **done (not pushed)** | Doc-38 §H.3 discharged by MV-1; `k≥3` / `diagonal` fences pinned on claim surfaces + contract tests. R `e822db3`. Check-log `check-log.d/2026-09-02-h2-a28-fence-enforcement.md`. No covered flip. |
| **0.6 inventory** | **written (scratch)** | `~/local-scratch/h2-060-evidence-inventory.md` — every MV recovery/comparator gate in both lanes with path, SHA, status. Headline finding (C8 banked but uncited) discharged by **A25a**. A26b + A28 remainder recorded. |
| **A25a** | **done (not pushed)** | C8 register reconcile (compute-free cite). Julia `11f54d9e` + R `0c0ae4a`. DRAC `47925486`: 16×500, 500/500 conv, **14/16 pass** (fails `rg_090_rec1`/`rg_095_rec1` only); W1 retained as triage. Fence: Julia `V4-MV-REML` **covered**, R multivariate **partial**, `public_covered_count` **5** — all unchanged. Scratch LOOP `~/local-scratch/h2-a25a-LOOP.md`; briefing §13. |
| **A25-rose (mislabeled)** | **done (not pushed)** | **A29-shaped** claim-surface audit landed under the A25 label. R `469ab94` + Julia `b24f7f88`. Verdict CLEAR-WITH-CHANGES. **True spine A25 = MV-5 disposition remains OPEN.** Report `~/local-scratch/h2-a25-rose-mv-audit-2026-09-02.md`. |
| **A25-grace (docregen)** | **done (not pushed)** | Regenerated `docs/src/validation-status.md` so C8 (`47925486`, 14/16) appears on the published page; CI now asserts claim_boundary prose sync (not ids only). Check-log `check-log.d/2026-09-02-h2-a25-grace-validation-status-regen.md`. Closes inventory T2 / Rose F3. |
| **A25 (true)** | **OPEN — owner** | **MV-5 disposition** (run / supersede / keep frozen). Draft only: `~/local-scratch/h2-a25-mv5-disposition-draft.md`. **Do not run** Totoro/DRAC. |
| **A26b** | **done (not pushed)** | MV-1 sommer Suggests: `hs_require_suggests` — **loud fail under `NOT_CRAN=true`**, CRAN skip intact. R `d59d98e`. Check-log `check-log.d/2026-09-02-h2-a26b-sommer-loud-skip.md`. |
| **A26** | **done (not pushed)** | R↔engine element-wise k=2 multivariate parity. R `0ec917f`/`37843d8`/`74ba7d6`/`806f7a7`. Margins: start-matched **1.7e-14** vs 1e-8; bridge `I₂` start **2.0e-5** vs 5e-4; pedigree-permutation **1.7e-14** vs 1e-6. Live 44 PASS; CRAN 6 PASS / 2 SKIP. Fence held: R multivariate **partial**, `public_covered_count` **5**. Receipt `~/local-scratch/h2-a26-receipt.md`; briefing §17. |
| **A26-grace** | **done (not pushed)** | JuliaCall 0.17.6 NA-matrix segfault workaround. R `becfa5b`. Root: `julia_assign` of NA → Julia `Missing`; `julia_eval(isnan)` segfaults. Fix: R-side `hs_y_matrix_for_julia` NA→NaN before assign; safe Int count eval. Live multivariate FAIL 0 / SKIP 0; A26 parity still 44 PASS; CRAN path intact. Check-log `check-log.d/2026-09-02-h2-a26-juliacall-na-segfault.md`. |
| **A27** | **prep DONE (not pushed); SIGN PENDING** | Darwin MV-6 sign pack + criterion-3 citation. Sheet `~/local-scratch/h2-a27-darwin-mv-sign-sheet.md` — **signature blank; do not treat as signed**. Quantity Darwin is asked to sign: genetic covariance `G0` / genetic correlation `r_g` for k=2 unstructured, **not** per-trait h² alone. Criterion-3 needed no new citation — the R canon pins already exist and are now **mirrored into the Julia canon** (`docs/design/04-validation-canon.md`, Julia `7a2361b9`) so the lanes cannot drift on symbol meaning. Noether boundary written into that mirror: Julia's `r_g`/`h²_k` hold **by construction** in `fit_multivariate_reml`, and no Julia assertion pins `heritability(fit) ≈ diag(G0)./(diag(G0).+diag(R0))` — the gating identity tests are R-lane (MV-3). **That last boundary is now CLOSED — see A27-noether below.** Fence held: `V4-MV-REML` covered, R multivariate **partial**, `public_covered_count` **5**. LOOP `~/local-scratch/h2-a27-LOOP.md`; briefing §18. |
| **A27-noether** | **done (not pushed)** | Julia identity pin — closes A27's recorded Noether boundary. Julia `7ab28d36`. New testset *Phase 4 derived-estimand identities on the REML fit path* (**69 assertions**) pins `heritability(fit) ≈ diag(G0)./(diag(G0).+diag(R0))` (extractor **and** stored field, per trait) and `r_g`/`r_e ≈ D⁻¹ C D⁻¹` on the **estimated** path — previously pinned only on the supplied-covariance `multivariate_mme` path — across `:unstructured`, `:diagonal`, `:lowrank`, `t = 1` and a near-boundary two-`NaN` fit, at `rtol = 1e-12` (measured error: h² exactly `0.0`, `r_g` ≤ `1.1e-16`). Reference maps written out in canon notation, **not** via `genetic_correlation` (which would be circular). 5 anti-vacuity assertions show the identities discriminate (`G0` off-diagonal `0.552` ≠ 0; distinct h² `0.851`/`0.558`; reversed reference rejected; h² invariant to zeroing the genetic covariance while `r_g` is not). `04-validation-canon.md` corrected — its "no Julia assertion" sentence was false. Suite **144 testsets / 4322 assertions / 0 fail** (was 143/4252). No new fixture, no RNG. **Self-consistency, NOT external-comparator evidence.** Fence held: `V4-MV-REML` covered, R multivariate **partial**, `public_covered_count` **5**. Check-log `check-log.d/2026-09-02-h2-a27-noether-identity-pin.md`. |
| **A32 (S6)** | **predeclared, FROZEN-NOT-RUN (not pushed)** | S6 ASReml comparator design frozen: Julia `990e33c6` (pre-declaration + skeleton) + `34dedc0a` (check-log). **One document, two independently gated legs** — Leg E estimand agreement at tail scale (closes debt item (2)); Leg W wall-clock ladder (closes **no** debt). Agreement gates timing per cell: a cell that fails agreement yields **no** timing number. Seven-cell grid indexed on `(q, fill, class)`, not `n`. Caps, cold-start seeds (`202696xx`/`202697xx`), and a **toolchain assertion** (the S5 lesson — it recorded its interpreter without asserting it) all frozen. Skeleton `sim/phase_s6_asreml_wallclock_ladder.jl` refuses to run without ASReml and has no HSquared-only fallback; only its dry-run and refusal path were exercised. **Three prerequisites OPEN, two measured:** P1 no licensed ASReml-R host (owner, A33); P2 the ASReml scaffold exists only on the foreign codex lane and must be **ported**; P3 `fit_eigen_reml` is **absent from `src/` on this branch**, so the spine's three-fitter grid is not executable here as written. **No run, no compute, no speed claim** — the honest answer stays *cannot say*. `public_covered_count` **5**; `V1-MATFREE-REML` **experimental**. LOOP `~/local-scratch/h2-s6-LOOP.md`; briefing §24. |
| **Owner asks (open)** | **OPEN** | (1) Bridge start values: keep shipped `I₂` vs adopt engine `0.5·phenotypic-variance` default (measured cost of identity ≈ 2e-5 on G0). (2) **DP-1** push — still gated; nothing CI-verified. (3) **A33** — is there a licensed ASReml-R on a host we can drive? A **NO** is a legitimate outcome that parks the S6 wall-clock ladder without parking its design. Bundle with the existing S6/S7/D1 asks. (4) **A25 MV-5 disposition** — recommended default now **SUPERSEDE**, see `~/local-scratch/h2-a25-mv5-disposition-draft.md`. |

## Batch status

| Batch | Status | Barrier lenses |
|-------|--------|----------------|
| B0 | done | Shannon, Rose — receipt `h2-twin-b0-receipt.md` |
| B1 | done | Fisher, Rose — barrier `~/local-scratch/h2-twin-b1-barrier.md` PROCEED |
| B2 | **partial** | Gauss, Fisher, Ada — A07/A08 done; A09 dossiers refreshed; G10 sign owner |
| B3 | **partial** | Curie, Mrode, Jason, Darwin — barrier **PROCEED WITH CONDITIONS** (`h2-b3-barrier-packet.md`); **C2 closed in note form** (pass 3: sire boundary documented, harness verdict kept at `gap`, mirror-vs-permanent decision left to the owner); **still not done — Darwin A13 sign (C1)** |
| B4 | **done** | Hopper, Boole, Emmy, Fisher — barrier **PROCEED** `~/local-scratch/h2-b4-barrier.md` |
| B5 | **partial** | Grace, Karpinski, Pat, Darwin, Florence — A17+A18 done; barrier packet **PROCEED WITH CONDITIONS** (`h2-b5-barrier-packet.md`); C1 post-merge deploy open; C2 Pat script drafted (`h2-b5-pat-reader-walk.md`) not walked |
| B6 | **partial** | Grace, Rose — A19 hygiene landed (Aqua green); A20 live-Julia skips exhausted; register + Version ASK |
| B7 | **done** | Fisher (Opus A21) — panel `~/local-scratch/h2-a21-estimand-claim-panel-2026-09-02.md`; verdict was **HOLD WITH CONDITIONS**: C1 `rr(t, k = 2)` does not parse (register + `model-status.Rmd`), C2 `heritability()` does not return h²(t) (`rr_heritability()` does) — both prose-only, pre-existing on `origin/main`, no flip needed; C4–C9 post-push. **All three pre-push conditions LANDED** by Boole on the R lane, commit `1a00045` (**not pushed**): C1 + C2 fixed on the two named surfaces **plus a third found by grep** (`R/formula-status.R`, printed to users by `formula_status()`); C3 taken as a message-only RR branch on `heritability()` naming `rr_heritability()`. Guarded by 2 scoped contract tests, one proven to fail when the defect is reintroduced. `check()` **0e/0w/0n**, `test()` 2336 pass / 0 fail. No covered flip, no row add, `public_covered_count` stays 5. **A21 re-verdict: PROCEED (owner push).** Receipt `~/local-scratch/h2-a21-fix-receipt.md` |
| B8 | **done** | Melissa → A22 done; audit + owner packet filed |
| B9 | **done** | A23 done; D-43 closed by Option B decision `2026-09-02-block1-check-log-substitution.md` |

| A24 | MV prep | MV-4 claim-surface honesty | done | R commits; not pushed |
| A25 | MV prep | Rose DESCRIPTION / MV claim audit | done | MV-5 disposition still owner |
| A25a | MV prep | C8 register reconcile cite | done | banked evidence only |
| A26 | MV prep | R↔engine element-wise parity | done | discharged locally; **not CI-backed** |
| A26b | MV prep | sommer Suggests loud-skip | done | `hs_require_suggests` |
| A27 | MV prep | Darwin sign pack + Noether identity | doing | identity pinned; **Darwin ink blank** |
| A28 | MV prep | capability-id alias + fences | done | §H.3 discharged |
| A29 | MV prep | Rose pre-flip + no-anchor follow-up | done | gate item 2 **MET**; flip still blocked |
| A30 | MV prep | DoD backfill + DP-10 loud guard (Grace) | done | criterion 9 MET for A24–A29 cluster; DP-10 owner decision still open |

