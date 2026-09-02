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
| **A28-part1** | **done (not pushed)** | Capability-id honesty — **ALIASED, not renamed**. R `22cb5cd`/`90adf27`/`d5df60b`; no Julia commits. `validation_status()` gains `capability_label`; the `(opt-in)` id stays because **three dated records cite it verbatim**. Also fixed a self-contradiction in the multivariate `claim_boundary`. Checks: test PASS 2348 / FAIL 0, `check()` 0/0/0. Decision `docs/dev-log/decisions.md` (2026-09-02); check-log `check-log.d/2026-09-02-h2-a28-capability-id-alias.md`. `public_covered_count` 5. **A28 remainder open:** doc-38 §H.3 gate-decision record + `k >= 3` / `diagonal` fence-enforcement audit. |
| **0.6 inventory** | **written (scratch)** | `~/local-scratch/h2-060-evidence-inventory.md` — every MV recovery/comparator gate in both lanes with path, SHA, status. **Headline: the C8 confirm (16 cells x 500 seeds, 14/16 pass, DRAC job `47925486`) is banked in both lanes' `recovery-checkpoints/` but absent from BOTH lanes' `capability-status.md` and `validation-debt-register.md`, which still cite W1 (50 seeds, 5/8).** Recommends a new compute-free first arc **A25a** (register reconciliation) ahead of A25. No Totoro/DRAC runs. |

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
