# After-task — v0.6 ordered-categorical probit (ordinal) family kernel (T1) — 2026-06-30

## Task goal

Build the pure-Julia CORE of the v0.6 T1 ordinal-threshold arc (calving ease): the ordered-categorical
probit Laplace family kernel, `OrderedProbitResponse`. EXPERIMENTAL/`partial` (the established
non-Gaussian-family pattern) — NOT a covered claim. Autonomous slice while the maintainer was away
("keep working"), on a NEW branch off `main`, staged for review — NOT merged. Deliberately excludes the
maintainer-gated decisions (the same-estimand comparator, the recovery gate, the covered claim) and the
larger follow-ups (joint cutpoint estimation, fit/resolver + R wiring).

## Active lenses and spawned agents

- **Perspectives (inline):** Gauss/Noether (kernel numerics + log-concavity/observed-info choice),
  Curie/Fisher (the deterministic oracle design), Falconer (ordinal = calving-ease framing).
- **Rose** (`rose-systems-auditor`) — the mandatory audit → **PROMOTE-WITH-CHANGES**: verified no
  overclaim (count 48→49, covered unchanged, not exported/wired, three surfaces agree), the
  observed-information math (exact to 4.2e-8), the reduction gate discriminates a wrong weight, honest
  fences, and clean hygiene (7 files, no foreign files). One required fix applied: the struct docstring
  still described the abandoned Fisher weight → corrected to OBSERVED information (comment-only).

## Live phase snapshot

- **As of 2026-06-30 (v0.6 T1 ordinal family kernel authored, experimental/partial; Claude solo,
  autonomous; branch `feat/2026-06-30-v06-ordinal-family` off `main` @ `c2b5babc`, PR pending review).**
  `OrderedProbitResponse(thresholds)` (internal) generalizes `BernoulliProbitResponse` to K ordered
  categories with K-1 SUPPLIED cutpoints; exact log-concave kernels (observed-information weight),
  validated by the `K=2, θ=[0]`→probit reduction (loglik/score/weight exact), 3-category kernel gates
  (probs=1, zero-mean score, score=central-FD, weight=−second-FD>0), and an end-to-end marginal
  reduction (Δ ~1e-16). `validation_status()` 48→**49** (one new `partial` row); **public-covered
  FITTING = 1 UNCHANGED**; covered count UNCHANGED. SUPPLIED thresholds only, Laplace-only, internal,
  not wired to R, not a covered claim. **NEXT (maintainer): the same-estimand comparator decision
  (`ordinal::clmm`, NOT glmmTMB) + joint cutpoint estimation + a recovery gate → a covered path.**

## Files changed (this slice)

- `src/nongaussian.jl` — `OrderedProbitResponse` struct + kernels (`_fam_loglik/_fam_score/_fam_weight`)
  + `_ordered_interval_prob`/`_norm_cdf`(±∞)/`_ord_bounds`/`_ord_pdf` + `_check_counts`.
- `test/runtests.jl` — the T1 testset + count guard 48→49 + a V6-ORDINAL row-content check.
- `src/validation_status.jl`, `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`
  — the V6-ORDINAL `partial` row (three surfaces in agreement).
- `docs/dev-log/check-log.d/…` + this after-task.

## What changed

A new internal non-Gaussian family kernel — the ordinal generalization of the binary probit. The
estimator/marginal machinery is unchanged (the family is consumed by the existing `laplace_marginal_loglik`
via the `ResponseFamily` object interface). No public surface, no R twin, no covered claim.

## Checks run and exact outcomes

- Kernel smoke: reduction exact; probs=1; E[score]=0; score=dℓ; weight=−d²ℓ>0; end-to-end Δ=8.9e-16;
  guards throw.
- `julia --project=. -e 'using Pkg; Pkg.test()'` → PASS at count **49**.
- `julia --project=docs docs/make.jl` → exit 0.

## Public claim audit

`public-covered fitting = 1` UNCHANGED. `validation_status()` 48→49 (a new `partial` row, covered count
unchanged). No export, no default change, no R twin change, no covered claim. The V6-ORDINAL row and its
capability-status / debt-register mirrors all say INTERNAL / not-covered / SUPPLIED-thresholds-only.

## Tests of the tests

The reduction oracle (K=2, θ=[0] → BernoulliProbit) is exact and independent of the ordinal code path
(it compares against the already-validated probit kernels). The finite-difference gates validate score
and observed weight against the loglik directly (no shared derivation). The end-to-end gate exercises the
family through the real `laplace_marginal_loglik`, not just the isolated kernels. The zero-mean-score and
probs-sum-to-1 invariants are model-independent checks. A deliberate first-run bug (the family was a
6-tuple where `validation_status()` rows are 7-tuples) was caught by the suite's `validation_status()`
constructor and fixed (owed/missing split from claim-boundary).

## Coordination notes

Julia-engine-lane, solo, autonomous. Independent of the v0.4 branch/PR #211 (separate branch off `main`).
The comparator decision (`ordinal::clmm` vs the roadmap's glmmTMB — glmmTMB does NOT do cumulative-link
ordinal) is surfaced for the maintainer; it does not block this kernel slice.

## What did not go smoothly

Two things, both caught and fixed: (1) `_norm_cdf(-Inf)` routed the erfc continued-fraction to infinity
→ NaN; fixed with a ±∞ short-circuit. (2) the first weight choice was Fisher information (beta-binomial
convention), which does NOT reduce to the binary probit's observed-information weight — switched to
observed information (valid because ordered probit is log-concave), giving the exact reduction. (3) the
7-tuple row-arity bug above.

## Known limitations

SUPPLIED thresholds only (no joint cutpoint estimation); Laplace-only (no VA); internal (not exported,
not in the `:symbol` resolver, not wired to `fit_laplace_reml` or R); moderate-range (a deep-tail
underflow category needs a log-space loglik follow-up); no observation-scale h²; no external comparator;
no recovery gate; NOT a covered claim; public-covered fitting = 1 unchanged.

## Next actions

1. Real **Rose** audit on the diff (claim-vs-evidence; the `partial`/internal fences; count 48→49).
2. `docs/make.jl` + `Pkg.test` confirmed green → push the branch, open a PR staged for **maintainer
   review** (this is new engine capability, experimental; the maintainer decides whether/when to take it
   toward covered — comparator + cutpoint estimation + recovery gate).
3. Do NOT merge; do NOT claim covered.
