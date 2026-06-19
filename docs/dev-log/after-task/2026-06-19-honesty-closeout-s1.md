# After-task — Honesty closeout S1 (#47 rows + #38 doc + #44 V6-LAPLACE row)

Date: 2026-06-19. Lane: Julia engine. Slice: BT2/BT3 programme, S1 (first slice of
the relaunch). Lenses: Rose (lead), Noether, Fisher, Hopper.

## Context

The R lane filed a prioritized joint critical path (issue #61) and asked, as the
three highest-leverage / lowest-effort items, for honest-status edits — not new
math — that unblock waiting R surfaces. I verified each against `main` (`2a3eed5`)
before accepting, then closed all three in one PR.

## What was done

1. **#47 closeout** — `src/validation_status.jl` V4-MV-REML and V4-FA rows no longer
   list covariance SEs/LRTs as *missing*. The SE/LRT functions shipped in PR #59 and
   the two design registers were updated then; the in-code `validation_status()`
   diagnostic was the third surface that drifted. The edit is precise: V4-MV-REML
   (unstructured) gains both SEs and the LRT in evidence; V4-FA (structured) gains
   only the LRT, with structured SEs kept honestly absent because the
   `multivariate_covariance_standard_errors` guard (`src/multivariate.jl:927-928`)
   rejects structured fits (rotation-nonidentified loadings).
2. **#44 blocker-first** — added a consolidated **V6-LAPLACE (partial)** row to
   `validation_status()` so the R honesty gate has a citation before the
   `MarginalMethod` refactor (S4). It mirrors the existing register rows and records
   only earned evidence (Gaussian→`sparse_reml_loglik` exact; per-family score/weight
   vs finite differences; `fit_laplace_reml`/`NonGaussianFit`), with the bridge,
   dispatch, single-trial Bernoulli bias, and external-comparator gaps in `missing`.
3. **#38** — harmonized the retired "ratio ~0.99 on a 250-animal simulation" AI-REML
   claim at `docs/design/03-engine-contract.md:455` to the committed "~8% vs an
   independent finite-difference REML Hessian" wording (`V1-HERIT-CI`). The
   `validation_status()` evidence was already cleaned of this on 2026-06-13; the doc
   line was the leftover.

## Evidence

- `Pkg.test()` → passed (exit 0); suite **1822 → 1837** (+15 assertions). RED proof
  recorded first (all five new assertions failed against unedited source).
- `docs/make.jl` → exit 0 (no docstring/API change; design-doc + status-data only).
- Registers were grep-checked for residual stale SE/LRT-missing claims: none — only
  `validation_status.jl` had drifted.

## Cross-lane

Reply + start-list posted to issue #61. On merge I will comment there so the R lane's
honesty gate for #47 (thin LRT extractor + softened SE disclaimer) and #44 (Laplace
family citation) formally clears. The underlying SE/LRT engine functions are already
on `main` (PR #59), so the R lane can draft against them in parallel now.

## Status discipline

No capability moved to covered. No new engine behavior, no R bridge/payload change.
Pure honest-status reconciliation — it removes drift and cannot overclaim by
construction.

## Live Phase Snapshot delta

Suite **1837** (1822 from #59 + 15 S1 assertions). AGENTS.md Live Phase Snapshot
refreshed to 1837 + the S1 note (standing GLLVM.jl-pattern DoD). BT2/BT3 programme
relaunched, S1 done, S2 (#43 PEV/reliability into `result_payload`) next.

## Next

S2: promote PEV/reliability into the standard `result_payload(AnimalModelFit)` via
`:selinv` (#43, 2b) — the lowest-delta bridge win; flips hsquared#21.
