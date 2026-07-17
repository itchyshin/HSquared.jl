# Retry-7 D0F campaign — PRE-REGISTRATION (PRE-0)

**Committed BEFORE any official RNG draw.** The git commit that adds this file is the
pre-declaration stamp for the Retry-7 D0F 576-fit campaign. No phenotype has been drawn.
Authorization: the user expressly authorized the phenotype-generation + campaign arc on
2026-07-17. This document is outcome-neutral and fixes the predicates in advance so no
threshold can be relaxed post-hoc.

Bound heads: Julia `976814393043d3a4af5ce343d8ac4b05c43eac41`; R `9f7ed27263b19a486a595f81b1c0b1a8b94702f6`
(route-repair `b8096e5` confirmed ancestor; aborts loud on wrong route, `preseal.R:1704`).
Canonical sealed root: `retry7-preseal-9f7ed27-97681439-c/d0f` (bootstrap index 720000 rows,
manifest sha `f53967b5…`). Plan: `docs/dev-log/2026-07-17-retry7-campaign-arc-ultraplan.md`.

## 1. Seed-space isolation (declared disjoint)

- **Phenotype** seed base `2042000000`; **bootstrap** seed base `2043000000` (already sealed).
- Declared **disjoint from every retired root's space**: recovery-v3 (2032/2033, 2034/2035),
  Retry-4 (2036/2037), Retry-5 (2038/2039), Retry-6 (2040/2041), offset-7101 (7101:7148).
- Any collision with a retired space voids the run.

## 2. Pre-seed GREEN-GATE (all must pass BEFORE C1 draws a phenotype)

PRE-1 route-repair present in bound R head (**GREEN**, verified 2026-07-17) · PRE-2 R adjudicator
tail tests extended to 576-cardinality multi-route incl. boundary_lower/upper/interior/
interior_rescued/unsuccessful rows, byte-identical receipt survives validate-final (Mac/R lane) ·
PRE-3 receipt-boundary regressions: tag-conservation property + logical-FALSE-vs-text-`'false'` +
wrong-route rejection · PRE-4 Julia bootstrap-variance summarize on the real 720000-row index into
the R triple-compare (Totoro) · PRE-5 toolchain/env freeze + preflight re-PASS. **The phenotype
draw is forbidden until PRE-1…PRE-5 are green.**

## 3. Acceptance predicates (pre-declared; outcome-NEUTRAL)

A D0F receipt is **COMPLETE** iff ALL hold:
- `attempt_max_diff` AND `summary_max_diff` finite and ≤ `1e-10` (official R vs base-R vs Julia).
- Boundary component-ratio identity ≤ `1e-12` (Retry-4 one-ULP guard); engine-declared
  `boundary.numerical_ratio` preserved, component ratio compared separately.
- Every `julia_profile_replay` row admitted under its own route (never rebound to
  `ordinary_auto_genomic`); weighted route-lineage conserved.
- Receipt is create-once, byte-identical primary+sidecar, and **survives its own
  `validate-final` re-derivation**; self-hashed `adjudication_key` verifies.
- 5 bound review receipts (fisher, noether, hopper, grace, rose) present; schema
  `v07-genomic-recovery-v3-adjudication-2`.

**The deliverable is an adjudicated receipt that re-derives byte-identical, WHATEVER the verdict.**
PASS is not presupposed.

## 4. Admissible outcomes (NOT contract breaches)

- `boundary_lower` / `boundary_upper` and **genuine non-convergence** are ADMISSIBLE fit statuses.
  A real boundary or non-converged phenotype must not be misread mid-stream as a tail death.
- `PRECISION_BLOCKER` (a cell exceeding the frozen fit cap) is an **admissible negative outcome**
  to be banked, not hidden.

## 5. What a D0F PASS MEANS — and does NOT license

- **Means:** a three-implementation reproducibility/parity verdict (official R vs base-R vs Julia
  ≤1e-10) plus a bootstrap-variance characterization (10000 reps, denominator 576) of the point
  estimates. It **only OPENS** D1 (recovery) and D2 (comparator), which have never opened.
- **Does NOT license:** any bias / calibration / coverage / recovery claim; moving
  `public_covered_count` off **5**; activating / merging / releasing the `ordinary_auto_genomic`
  route; "covering" genomic REML beyond the supplied-`Ginv` estimator; or discharging V2-GRM /
  V2-GINV (they stay `partial` — base-R recompute reconstructs the estimator's *fits*, not the
  G/Ginv construction).

## 6. Negative-outcome protocol (base-rate branch — 6/6 prior tail deaths)

On any tail failure or PRECISION_BLOCKER: bank the negative in the capability-status row + the
validation-debt register, **retire the root AND both disjoint seed spaces** (no repair-in-place,
no salvage), record the exact defect for the next preregistered contract, and make **no**
activation / coverage / discharge claim. A completed-but-unadjudicated corpus is diagnostic and
moves no count.

## 7. Lane + point of no return

Live execution (phenotype draw, fits, base-R recompute, adjudication, receipt) is the R/Julia +
Totoro toolchain — the R twin (`hsquared`) owns markers/phenotypes/official fits/base-R
recompute/adjudication; `HSquared.jl` replays only. The **phenotype draw (C1) is the point of no
return** under the root-forfeit rule and stays LAST, after the green-gate. Compute: Totoro,
`OPENBLAS_NUM_THREADS=1`, JULIA threads=1, ≤90-96 workers, resume via complete-prefix only,
bootstrap immutable.
